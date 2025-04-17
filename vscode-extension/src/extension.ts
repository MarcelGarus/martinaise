/* eslint-disable @typescript-eslint/no-non-null-assertion */
/* eslint-disable @typescript-eslint/no-confusing-void-expression */
import * as vs from "vscode";
import { schedule } from "./async_queue";
import "./code_action";
import { registerCodeActionsProvider } from "./code_action";
import * as communication from "./communication";

let diagnosticCollection: vs.DiagnosticCollection;
let exampleDecoration: vs.TextEditorDecorationType;
let panicDecoration: vs.TextEditorDecorationType;

let fuzzingEnabled = false;

export function activate(context: vs.ExtensionContext) {
  console.info("Activated Martinaise extension!");

  diagnosticCollection = vs.languages.createDiagnosticCollection("martinaise");
  context.subscriptions.push(diagnosticCollection);

  context.subscriptions.push(
    vs.commands.registerCommand("martinaise.toggle-fuzzing", async () => {
      fuzzingEnabled = !fuzzingEnabled;
      await vs.window.showInformationMessage(
        fuzzingEnabled ? "Fuzzing turned on." : "Fuzzing turned off.",
      );
    }),
  );

  panicDecoration = vs.window.createTextEditorDecorationType({
    after: {
      color: new vs.ThemeColor(`martinaise.panic.foreground`),
      backgroundColor: new vs.ThemeColor(`martinaise.panic.background`),
      margin: "0 0 0 16px",
    },
    rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
  });
  exampleDecoration = vs.window.createTextEditorDecorationType({
    after: {
      color: new vs.ThemeColor(`martinaise.example.foreground`),
      backgroundColor: new vs.ThemeColor(`martinaise.example.background`),
      margin: "0 0 0 16px",
    },
    rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
  });

  vs.window.onDidChangeVisibleTextEditors(onDidChangeVisibleTextEditors);
  vs.workspace.onDidChangeTextDocument(onDidChangeTextDocument);
  vs.window.onDidChangeTextEditorVisibleRanges(onDidChangeVisibleRanges);

  context.subscriptions.push(
    vs.commands.registerCommand("martinaise.fuzz", fuzzToPosition),
  );
  context.subscriptions.push(registerCodeActionsProvider());
}
export function deactivate() {
  // TODO: What to do here?
}

// Updates can be triggered very frequently (on every keystroke or scroll), but
// they can take long – for example, when editing the Martinaise compiler
// itself, simply analyzing the files takes some time. Fuzzing also takes a lot
// of time. Thus, here we make sure that only one action runs at a time.

// We try to offer tiers of tooling:
// - First, analyze the file contents to show errors.
// - Then, fuzzing functions.

type Path = string;
type Timestamp = number;

const pendingAnalyses = new Map<Path, Timestamp>();
const analyses = new Map<Path, Analysis>();
interface Analysis {
  functions: communication.FunctionDefinition[];
  errors: communication.Error[];
}

const pendingFuzzing = new Map<Path, Map<communication.Signature, Timestamp>>();
const examples = new Map<
  Path,
  Map<communication.Signature, communication.FunctionExamples>
>();

function onDidChangeVisibleTextEditors(editors: readonly vs.TextEditor[]) {
  const visiblePaths = new Set<Path>();
  for (const editor of editors)
    visiblePaths.add(editor.document.uri.toString());

  for (const path of visiblePaths) scheduleAnalysis(path);
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function onDidChangeTextDocument(_: vs.TextDocumentChangeEvent) {
  // Editing a file might invalidate other files that depend on it. So, we
  // reanalyse all files whenever one changes.
  for (const editor of vs.window.visibleTextEditors)
    scheduleAnalysis(editor.document.uri.toString());
}

function scheduleAnalysis(path: Path) {
  if (!path.endsWith(".mar")) return;
  const scheduled = performance.now();
  pendingAnalyses.set(path, scheduled);
  void schedule(async () => {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    if (pendingAnalyses.has(path) && pendingAnalyses.get(path)! > scheduled)
      return;

    const analysis = await communication.analyze(path);
    const errorsFromThisFile = [];
    for (const error of analysis.errors) {
      if (error.src.file == path) errorsFromThisFile.push(error);
    }
    analyses.set(path, {
      functions: analysis.functions,
      errors: errorsFromThisFile,
    });
    updateErrorDiagnostics();
  });
}

function onDidChangeVisibleRanges(
  event: vs.TextEditorVisibleRangesChangeEvent,
) {
  if (event.textEditor.document.languageId != "martinaise") return;
  const path = event.textEditor.document.uri.toString();

  let start = 999999; // TODO
  let end = 0;
  for (const range of event.visibleRanges) {
    start = min(start, range.start.line);
    end = max(end, range.end.line + 1);
  }

  void schedule(async () => {
    console.log(`Fuzzing lines from ${start} to ${end} of ${path}`);

    const functionsInFile = analyses.get(path)?.functions ?? [];
    const visibleFunctions = functionsInFile.filter(
      (fun) => fun.src.end.line >= start && fun.src.start.line <= end,
    );
    for (const fun of visibleFunctions)
      scheduleFuzzingOfFunction(path, fun.signature);

    await new Promise((resolve) => resolve(undefined));
  });
}
const min = (a: number, b: number) => (a < b ? a : b);
const max = (a: number, b: number) => (a > b ? a : b);

function scheduleFuzzingOfFunction(path: Path, signature: string) {
  const scheduled = performance.now();
  if (!pendingFuzzing.has(path)) pendingFuzzing.set(path, new Map());
  pendingFuzzing.get(path)!.set(signature, scheduled);
  void schedule(async () => {
    if (pendingAnalyses.get(path)! > scheduled) return;
    if (pendingFuzzing.get(path)!.get(signature)! > scheduled) return;

    console.log(`Fuzzing ${signature}`);

    await communication.fuzz(path, signature, (newExamples) => {
      let visible = false;
      for (const e of vs.window.visibleTextEditors)
        if (e.document.uri.toString() == path) visible = true;
      if (!visible) return; // No longer visible.

      console.log(
        `Found ${newExamples.calls.length} examples for ${signature}`,
      );

      if (!examples.has(path)) examples.set(path, new Map());

      const fileExamples = examples.get(path);
      if (!fileExamples) throw Error("unreachable");
      fileExamples.set(signature, newExamples);
      updateFuzzingExamples(path);
    });
  });
}

async function fuzzToPosition(
  document: vs.TextDocument,
  position: vs.Position,
) {
  const path = document.uri.toString();
  if (!path.endsWith(".mar")) return;
  console.log(`Fuzzing ${path} ${JSON.stringify(position)}`);
  if (fuzzingEnabled) fuzzingEnabled = false;

  await communication.fuzzToPosition(document, position, (newExamples) => {
    if (!examples.has(path)) examples.set(path, new Map());

    const fileExamples = examples.get(path);
    if (!fileExamples) throw Error("unreachable");
    fileExamples.set(newExamples.fun_signature, newExamples);
    updateFuzzingExamples(path);
  });
}

// Updating

function updateErrorDiagnostics() {
  diagnosticCollection.clear();
  const diagnosticMap = new Map<string, vs.Diagnostic[]>();
  for (const analysis of analyses.values())
    for (const error of analysis.errors) {
      console.info(`Error: ${JSON.stringify(error)}`);

      const range = new vs.Range(
        new vs.Position(error.src.start.line, error.src.start.column),
        new vs.Position(error.src.end.line, error.src.end.column),
      );
      const diagnostics = diagnosticMap.get(error.src.file) ?? [];
      diagnostics.push(
        new vs.Diagnostic(
          range,
          `${error.title}\n${error.description}`,
          vs.DiagnosticSeverity.Error,
        ),
      );
      diagnosticMap.set(error.src.file, diagnostics);
    }
  diagnosticMap.forEach((diags, file) =>
    diagnosticCollection.set(vs.Uri.parse(file), diags),
  );
}

function updateFuzzingExamples(path: Path) {
  let editor: vs.TextEditor | null = null;
  for (const e of vs.window.visibleTextEditors)
    if (e.document.uri.toString() == path) editor = e;
  if (!editor) return;

  const exampleDecorations: vs.DecorationOptions[] = [];
  const panicDecorations: vs.DecorationOptions[] = [];

  const examplesOfFile = examples.get(path);
  if (!examplesOfFile) return;
  for (const examplesOfFun of examplesOfFile.values()) {
    for (const call of examplesOfFun.calls) {
      console.info(`Example call: ${JSON.stringify(call)}`);
      const position = new vs.Position(examplesOfFun.fun_start_line, 80);
      let text = call.inputs.join(", ");
      if (call.result.status == "returned") text += ` -> ${call.result.value}`;
      if (call.result.status == "panicked") text += ` panics`;
      const collection =
        call.result.status == "returned"
          ? exampleDecorations
          : panicDecorations;
      collection.push({
        range: new vs.Range(position, position),
        renderOptions: { after: { contentText: text } },
      });
    }
  }
  editor.setDecorations(panicDecoration, panicDecorations);
  editor.setDecorations(exampleDecoration, exampleDecorations);
}
