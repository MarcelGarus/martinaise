/* eslint-disable @typescript-eslint/no-confusing-void-expression */
import * as child_process from "child_process";
import * as linebyline from "linebyline";
import * as vs from "vscode";

let diagnosticCollection: vs.DiagnosticCollection;
let exampleDecoration: vs.TextEditorDecorationType;

export function activate(context: vs.ExtensionContext) {
  console.info("Activated Martinaise extension!");

  diagnosticCollection = vs.languages.createDiagnosticCollection("martinaise");
  context.subscriptions.push(diagnosticCollection);

  exampleDecoration = vs.window.createTextEditorDecorationType({
    after: {
      color: new vs.ThemeColor(`martinaise.example.foreground`),
      backgroundColor: new vs.ThemeColor(`martinaise.example.background`),
      margin: "0 0 0 16px",
    },
    rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
  });

  vs.window.onDidChangeVisibleTextEditors(() => onlyRunOneAtATime(update));
  vs.workspace.onDidChangeTextDocument(() => onlyRunOneAtATime(update));

  context.subscriptions.push(
    vs.languages.registerCodeActionsProvider(
      "martinaise",
      new MartinaiseCodeActionsProvider(),
    ),
  );
  context.subscriptions.push(
    vs.commands.registerCommand("martinaise.fuzz", fuzz),
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

// Updates can be triggered very frequently (on every keystroke), but they can
// take long – for example, when editing the Martinaise compiler itself, simply
// analyzing the files takes some time. Thus, here we make sure that only one
// update runs at a time.

let newestScheduled = performance.now();
let currentRun = Promise.resolve(null);

async function onlyRunOneAtATime(callback: () => Promise<void>) {
  console.log("Scheduling update");
  const myTime = performance.now();
  newestScheduled = myTime;
  await currentRun;
  if (newestScheduled != myTime) return; // a newer update exists and will run
  currentRun = new Promise(async (resolve) => {
    await callback();
    resolve(null);
  });
}

const soilBinary = "/home/marcel/projects/soil/soil-zig";
const martinaiseCompiler = "/home/marcel/projects/martinaise/martinaise.soil";

async function update() {
  console.log("Updating");
  const promises = [];
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;

    const analysis = analyze(uri);
    promises.push(analysis);
    analysis
      .then((errors) => {
        diagnosticCollection.clear();
        const diagnosticMap = new Map<string, vs.Diagnostic[]>();
        for (const error of errors) {
          console.info(`Error: ${JSON.stringify(error)}`);
          if (error.src.file != uri) continue;
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
      })
      .catch((error) => console.error(`Analyzing failed: ${error}`));
  }
  await Promise.all(promises);
}

/// Returns the source code of the given URI. Prefers the content of open text
/// documents, even if they're not saved yet. If none exists, asks the file
/// system.
async function readCode(uri: vs.Uri): Promise<string | null> {
  for (const doc of vs.workspace.textDocuments)
    if (doc.uri.toString() == uri.toString()) return doc.getText();
  try {
    const bytes = await vs.workspace.fs.readFile(uri);
    return new TextDecoder("utf8").decode(bytes);
  } catch (e) {
    return null;
  }
}

/// Communication with the Martinaise language server works using the following
/// schema.

type AnalyzeMessage = ReadFileMessage | ErrorMessage; // martinaise tooling analyze ...
type FuzzMessage = ReadFileMessage | ExampleMessage; // martinaise tooling fuzz ...
interface ReadFileMessage {
  type: "read_file";
  path: string;
}
interface ErrorMessage {
  type: "error";
  src: {
    file: string;
    start: {
      line: number;
      column: number;
    };
    end: {
      line: number;
      column: number;
    };
  };
  title: string;
  description: string;
  context: string[];
}
interface ExampleMessage {
  type: "example";
  inputs: string[];
  result: ExampleResult;
  fun_start_line: number;
  fun_name: string;
}
type ExampleResult = ExampleReturned | ExamplePanicked;
interface ExampleReturned {
  status: "returned",
  value: string;
}
interface ExamplePanicked {
  status: "panicked",
  message: string;
}

async function handleReadFileMessage(
  message: ReadFileMessage,
): Promise<string> {
  const uri = vs.Uri.parse(message.path);
  const content = await readCode(uri);
  const response = content
    ? { type: "read_file", success: true, content: content }
    : { type: "read_file", success: false };
  return `${JSON.stringify(response)}\n`;
}

async function analyze(path: string): Promise<ErrorMessage[]> {
  console.log(`Analyzing ${path}`);
  const soil = child_process.spawn(soilBinary, [
    martinaiseCompiler,
    "tooling",
    "analyze",
    path,
  ]);
  soil.on("error", (error) => {
    console.error(`Failed to spawn: ${error.name}: ${error.message}`);
  });
  linebyline(soil.stderr).on("line", (line: string) => console.log(line));

  const diagnostics: ErrorMessage[] = [];
  linebyline(soil.stdout).on("line", async function (line: string) {
    console.info("Line: " + line);
    const message = JSON.parse(line) as AnalyzeMessage;
    if (message.type == "read_file") {
      soil.stdin.write(await handleReadFileMessage(message));
    }
    if (message.type == "error") {
      diagnostics.push(message);
    }
  });

  const exitCode: number | null = await new Promise((resolve) =>
    soil.on("close", (exitCode) => resolve(exitCode)),
  );
  console.info(`martinaise analyze exited with ${exitCode}.`);

  return diagnostics;
}

async function fuzz(document: vs.TextDocument, position: vs.Position) {
  const path = document.uri.toString();
  if (!path.endsWith(".mar")) return;

  console.log(`Fuzzing ${path} ${JSON.stringify(position)}`);

  const soil = child_process.spawn(soilBinary, [
    martinaiseCompiler,
    "tooling",
    "fuzz",
    path,
    `${position.line}:${position.character}`,
  ]);
  soil.on("error", (error) => {
    console.error(`Failed to spawn: ${error.name}: ${error.message}`);
  });
  linebyline(soil.stderr).on("line", (line: string) => console.log(line));

  const examples: ExampleMessage[] = [];
  linebyline(soil.stdout).on("line", async function (line: string) {
    console.info("Line: " + line);
    const message = JSON.parse(line) as FuzzMessage;
    if (message.type == "read_file") {
      soil.stdin.write(await handleReadFileMessage(message));
    }
    if (message.type == "example") {
      examples.push(message);
    }
  });

  const exitCode: number | null = await new Promise((resolve) =>
    soil.on("close", (exitCode) => resolve(exitCode)),
  );
  console.info(`martinaise fuzz exited with ${exitCode}.`);

  let editor: vs.TextEditor | null = null;
  for (const e of vs.window.visibleTextEditors)
    if (e.document.uri.toString() == path)
      editor = e;
  if (!editor) return;

  const decorations: vs.DecorationOptions[] = [];
  for (const example of examples) {
    console.info(`Example: ${JSON.stringify(example)}`);
    const position = new vs.Position(example.fun_start_line, 80);
    let text = `${example.fun_name}(${example.inputs.join(", ")})`;
    if (example.result.status == "returned") text += ` = ${example.result.value}`;
    if (example.result.status == "panicked") text += ` = <panicked>`;
    decorations.push({
      range: new vs.Range(position, position),
      renderOptions: {
        after: { contentText: text },
      },
    });
  }
  editor.setDecorations(exampleDecoration, decorations);
}
