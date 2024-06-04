/* eslint-disable @typescript-eslint/no-confusing-void-expression */
import * as child_process from "child_process";
import * as linebyline from "linebyline";
import * as vs from "vscode";

let diagnosticCollection: vs.DiagnosticCollection;

export function activate(context: vs.ExtensionContext) {
  console.info("Activated Martinaise extension!");

  diagnosticCollection = vs.languages.createDiagnosticCollection("martinaise");
  context.subscriptions.push(diagnosticCollection);

  vs.window.onDidChangeVisibleTextEditors(() => onlyRunOneAtATime(update));
  vs.workspace.onDidChangeTextDocument(() => onlyRunOneAtATime(update));

  context.subscriptions.push(
    vs.languages.registerCodeActionsProvider(
      "martinaise",
      new MartinaiseCodeActionsProvider(),
    ),
  );
  context.subscriptions.push(
    vs.commands.registerCommand(
      "martinaise.fuzz",
      (document: vs.TextDocument, position: vs.Position) => {
        console.log(`Fuzzing ${document.uri} ${JSON.stringify(position)}`);
      }
    ),
  );
}
export function deactivate() {
  // TODO: What to do here?
}

class MartinaiseCodeActionsProvider implements vs.CodeActionProvider {
  provideCodeActions(
    document: vs.TextDocument, selection: vs.Range | vs.Selection
  ): vs.Command[] {
    if (!(selection instanceof vs.Selection)) return [];
    // TODO: check vs.CodeActionTriggerKind;
    return [
      {
        title:
          `What input reaches this code? ${JSON.stringify(selection.anchor)}`,
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

async function update() {
  console.log("Updating");
  const promises = [];
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;

    const checked = check(uri);
    promises.push(checked);
    checked
      .then((errors) => {
        diagnosticCollection.clear();
        const diagnosticMap = new Map<string, vs.Diagnostic[]>();
        for (const error of errors) {
          console.info("Error: " + JSON.stringify(error));
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
      .catch((error) => console.error(`An error occurred: ${error}`));
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

async function check(path: string): Promise<MartinaiseError[]> {
  const soilBinary = "/home/marcel/projects/soil/soil-asm";
  const martinaiseCompiler = "/home/marcel/projects/martinaise/martinaise.soil";

  console.info(`Spawning ${soilBinary} with ${path}`);
  const soil = child_process.spawn(soilBinary, [
    martinaiseCompiler,
    "analyze",
    path,
  ]);
  soil.on("error", (error) => {
    console.error(`Failed to spawn: ${error.name}: ${error.message}`);
  });
  linebyline(soil.stderr).on("line", (line: string) => console.log(line));

  const diagnostics: MartinaiseError[] = [];
  linebyline(soil.stdout).on("line", async function (line: string) {
    console.info("Line: " + line);
    const message = JSON.parse(line) as MartinaiseMessage;
    if (message.type == "read_file") {
      const uri = vs.Uri.parse(message.path);
      const content = await readCode(uri);
      // console.info("Read file: " + content);
      if (content) {
        soil.stdin.write(
          JSON.stringify({
            type: "read_file",
            success: true,
            content: content,
          }),
        );
        soil.stdin.write("\n");
      } else {
        soil.stdin.write(JSON.stringify({ type: "read_file", success: false }));
        soil.stdin.write("\n");
      }
    }
    if (message.type == "error") {
      diagnostics.push(message);
    }
  });

  const exitCode: number | null = await new Promise((resolve) =>
    soil.on("close", (exitCode) => resolve(exitCode)),
  );
  console.info(`Martinaise exited with ${exitCode}.`);

  return diagnostics;
}
type MartinaiseMessage = MartinaiseReadFile | MartinaiseError;
interface MartinaiseReadFile {
  type: "read_file";
  path: string;
}
interface MartinaiseError {
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
