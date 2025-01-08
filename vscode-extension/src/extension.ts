/* eslint-disable @typescript-eslint/no-confusing-void-expression */
import * as vs from "vscode";
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

  exampleDecoration = vs.window.createTextEditorDecorationType({
    after: {
      color: new vs.ThemeColor(`martinaise.example.foreground`),
      backgroundColor: new vs.ThemeColor(`martinaise.example.background`),
      margin: "0 0 0 16px",
    },
    rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
  });
  panicDecoration = vs.window.createTextEditorDecorationType({
    after: {
      color: new vs.ThemeColor(`martinaise.panic.foreground`),
      backgroundColor: new vs.ThemeColor(`martinaise.panic.background`),
      margin: "0 0 0 16px",
    },
    rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
  });

  vs.window.onDidChangeVisibleTextEditors(() => onlyRunOneAtATime(update));
  vs.workspace.onDidChangeTextDocument(() => onlyRunOneAtATime(update));

  vs.window.onDidChangeTextEditorVisibleRanges(async (event) => {
    if (event.textEditor.document.languageId != "martinaise") return;
    await handleVisibleRanges(
      event.textEditor.document.uri,
      event.visibleRanges,
    );
  });

  context.subscriptions.push(
    vs.languages.registerCodeActionsProvider(
      "martinaise",
      new MartinaiseCodeActionsProvider(),
    ),
  );
  context.subscriptions.push(
    vs.commands.registerCommand("martinaise.fuzz", fuzzToPosition),
  );
}
export function deactivate() {
  // TODO: What to do here?
}

class MartinaiseCodeActionsProvider implements vs.CodeActionProvider {
  provideCodeActions(
    document: vs.TextDocument,
    selection: vs.Range | vs.Selection,
  ): vs.Command[] {
    if (!(selection instanceof vs.Selection)) return [];
    // TODO: check vs.CodeActionTriggerKind;
    return [
      {
        title: `What input reaches this code?`,
        command: "martinaise.fuzz",
        arguments: [document, selection.start],
      },
    ];
  }
}

// Updates can be triggered very frequently (on every keystroke or scroll), but
// they can take long – for example, when editing the Martinaise compiler
// itself, simply analyzing the files takes some time. Thus, here we make sure
// that only one update runs at a time.

let newestScheduled = performance.now();
let currentRun: Promise<void> = Promise.resolve(undefined);

async function onlyRunOneAtATime(callback: () => Promise<void>) {
  console.log("Scheduling update");
  const myTime = performance.now();
  newestScheduled = myTime;
  await currentRun;
  if (newestScheduled != myTime) return; // a newer update exists and will run
  currentRun = callback();
}

type Path = string;

// Analyzing files.

const functions = new Map<Path, communication.FunctionDefinition[]>();
const errors = new Map<Path, communication.Error[]>();

async function update() {
  console.log("Updating");
  const promises = [];
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;
    const path = uri.toString();

    const analysis = communication.analyze(uri);
    promises.push(analysis);
    analysis
      .then((analysis) => {
        functions.set(path, analysis.functions);
        errors.set(path, analysis.errors);
        updateErrorDiagnostics();
      })
      .catch((error) => console.error(`Analyzing failed: ${error}`));
  }
  await Promise.all(promises);
}

function updateErrorDiagnostics() {
  diagnosticCollection.clear();
  const diagnosticMap = new Map<string, vs.Diagnostic[]>();
  for (const fileErrors of errors.values()) {
    for (const error of fileErrors) {
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
  }
  diagnosticMap.forEach((diags, file) =>
    diagnosticCollection.set(vs.Uri.parse(file), diags),
  );
}

// Fuzzing functions.

const examples = new Map<
  Path,
  Map<communication.Signature, communication.FunctionExamples>
>();

async function fuzz(uri: vs.Uri, signature: string) {
  const path = uri.toString();
  if (!path.endsWith(".mar")) return;

  console.log(`Fuzzing ${signature}`);

  await communication.fuzz(uri, signature, (new_examples) => {
    let editor: vs.TextEditor | null = null;
    for (const e of vs.window.visibleTextEditors)
      if (e.document.uri.toString() == path) editor = e;
    if (!editor) return;

    if (!examples.has(path))
      examples.set(
        path,
        new Map<communication.Signature, communication.FunctionExamples>(),
      );

    const fileExamples = examples.get(path);
    if (!fileExamples) throw Error("unreachable");
    fileExamples.set(signature, new_examples);
    updateFuzzingExamples(path);
  });
}

async function fuzzToPosition(
  document: vs.TextDocument,
  position: vs.Position,
) {
  const path = document.uri.toString();
  if (!path.endsWith(".mar")) return;
  console.log(`Fuzzing ${path} ${JSON.stringify(position)}`);

  await communication.fuzzToPosition(document, position, (new_examples) => {
    if (!examples.has(path))
      examples.set(
        path,
        new Map<communication.Signature, communication.FunctionExamples>(),
      );

    const fileExamples = examples.get(path);
    if (!fileExamples) throw Error("unreachable");
    fileExamples.set(new_examples.fun_signature, new_examples);
    updateFuzzingExamples(path);
  });
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
      let text = `${examplesOfFun.fun_name}(${call.inputs.join(", ")})`;
      if (call.result.status == "returned") text += ` = ${call.result.value}`;
      if (call.result.status == "panicked") text += ` panicked`;
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
  editor.setDecorations(exampleDecoration, exampleDecorations);
  editor.setDecorations(panicDecoration, panicDecorations);
}

async function handleVisibleRanges(uri: vs.Uri, ranges: readonly vs.Range[]) {
  let start = 999999; // TODO
  let end = 0;
  for (const range of ranges) {
    start = min(start, range.start.line);
    end = max(end, range.end.line + 1);
  }
  await new Promise((resolve) => resolve(2));
  console.log(`Fuzzing lines from ${start} to ${end} of ${uri.toString()}`);

  const functions_in_file = functions.get(uri.toString()) ?? [];
  for (const fun of functions_in_file) {
    if (fun.src.end.line < start) continue;
    if (fun.src.start.line > end) continue;
    console.log(`Fuzzing ${fun.signature}`);
  }
  // console.log(`Visible ranges:`);
  // for (const range of ranges) {
  //   console.log(
  //     `${range.start.line}:${range.start.character} – ${range.end.line}:${range.end.character}`,
  //   );
  // }
}
function min(a: number, b: number): number {
  return a < b ? a : b;
}
function max(a: number, b: number): number {
  return a > b ? a : b;
}
