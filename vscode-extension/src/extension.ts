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
    vs.languages.registerCodeLensProvider(
      "martinaise",
      new MartinaiseCodeLensProvider(),
    ),
  );
  context.subscriptions.push(
    vs.languages.registerCodeActionsProvider(
      "martinaise",
      new MartinaiseCodeActionsProvider(),
    ),
  );
}
export function deactivate(): Thenable<void> | undefined {
  return undefined;
}

// Updates can be triggered very frequently (on every keystroke), but they can
// take long – for example, when editing the Martinaise compiler itself, simply
// analyzing the files takes some time. Thus, here we make sure that only one
// update runs at a time.

var newestScheduled = performance.now();
var currentRun = Promise.resolve(null);

async function onlyRunOneAtATime(callback: () => Promise<void>) {
  console.log("Scheduling update");
  var myTime = performance.now();
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
  let promises = [];
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;

    const checked = check(uri);
    promises.push(checked);
    checked.then((errors) => {
      diagnosticCollection.clear();
      const diagnosticMap = new Map<string, vs.Diagnostic[]>();
      for (const error of errors) {
        console.info("Error: " + JSON.stringify(error));
        if (error.source.file != uri) continue;
        const range = new vs.Range(
          editor.document.positionAt(error.source.start),
          editor.document.positionAt(error.source.end),
        );
        const diagnostics = diagnosticMap.get(error.source.file) ?? [];
        diagnostics.push(
          new vs.Diagnostic(
            range,
            `${error.title}\n${error.description}`,
            vs.DiagnosticSeverity.Error,
          ),
        );
        diagnosticMap.set(error.source.file, diagnostics);
      }
      diagnosticMap.forEach((diags, file) =>
        diagnosticCollection.set(vs.Uri.parse(file), diags),
      );
    });
  }
  await Promise.all(promises);
}

/// Returns the source code of the given URI. Prefers the content of open text
/// documents, even if they're not saved yet. If none exists, asks the file
/// system.
async function readSource(uri: vs.Uri): Promise<string | null> {
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
      const content = await readSource(uri);
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
  source: {
    file: string;
    start: number;
    end: number;
  };
  title: string;
  description: string;
  context: string[];
}

class MartinaiseCodeLensProvider implements vs.CodeLensProvider {
  public provideCodeLenses(): vs.CodeLens[] {
    const command: vs.Command = {
      title: "Fuzz",
      command: "fuzz",
      tooltip: "tooltip",
      arguments: [],
    };
    return [
      new vs.CodeLens(
        new vs.Range(new vs.Position(1, 1), new vs.Position(1, 3)),
        command,
      ),
    ];
  }

  public resolveCodeLens?(codeLens: vs.CodeLens): vs.CodeLens {
    return codeLens;
  }
}

class MartinaiseCodeActionsProvider implements vs.CodeActionProvider {
  provideCodeActions(): vs.ProviderResult<(vs.Command | vs.CodeAction)[]> {
    const command: vs.Command = {
      title: "Fuzz",
      command: "fuzz",
      tooltip: "tooltip",
      arguments: [],
    };
    return [command];
  }
  resolveCodeAction?(
    codeAction: vs.CodeAction,
  ): vs.ProviderResult<vs.CodeAction> {
    return codeAction;
  }
}
