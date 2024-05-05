import * as child_process from "child_process";
import * as linebyline from "linebyline";
import * as vs from "vscode";
import {
  integer
} from "vscode-languageclient/node";

let diagnosticCollection: vs.DiagnosticCollection;

export async function activate(context: vs.ExtensionContext) {
  console.info("Activated Martinaise extension!");

  diagnosticCollection = vs.languages.createDiagnosticCollection("martinaise");
  context.subscriptions.push(diagnosticCollection);

  vs.window.onDidChangeVisibleTextEditors(() => update());
  vs.workspace.onDidChangeTextDocument((_: vs.TextDocumentChangeEvent) => update());
  // vs.workspace.onDidCloseTextDocument((document) => {
  //   // hints.delete(document.uri.toString());
  // });

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

  // context.subscriptions.push(new ServerStatusService(client));
  // context.subscriptions.push(new HintsDecorations(client));
}
export function deactivate(): Thenable<void> | undefined {
  return undefined;
}

function update() {
  console.log("Updating");
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;

    check(uri).then(errors => {
      console.info("Displaying errors: " + errors);
      diagnosticCollection.clear();
      let diagnosticMap: Map<string, vs.Diagnostic[]> = new Map();
      for (const error of errors) {
        console.info("Error: " + JSON.stringify(error));
        if (error.source.file != uri) continue;
        let range = new vs.Range(
          editor.document.positionAt(error.source.start),
          editor.document.positionAt(error.source.end),
        );
        let diagnostics = diagnosticMap.get(error.source.file) ?? [];
        diagnostics.push(new vs.Diagnostic(range, `${error.title}\n${error.description}`, vs.DiagnosticSeverity.Error));
        diagnosticMap.set(error.source.file, diagnostics);
      }
      diagnosticMap.forEach((diags, file) => {
        diagnosticCollection.set(vs.Uri.parse(file), diags);
      });
    });

    // type Item = vs.DecorationOptions & {
    //   renderOptions: { after: { contentText: string } };
    // };
    // const decorations: Item[] = [];
    // for (const hint of hints) {
    //   const position = this.client.protocol2CodeConverter.asPosition(
    //     hint.position,
    //   );
    //   decorations.push({
    //     range: new vs.Range(new vs.Position(1, 1), new vs.Position(1, 3)),
    //     renderOptions: { after: { contentText: "Test hint" } },
    //   });
    // }
    // editor.setDecorations(this.decorationType, decorations);
  }
}

function workspaceFolder(): string | undefined {
  let folders = vs.workspace.workspaceFolders;
  if (!folders) return undefined;
  let folder = folders[0];
  if (!folder) return undefined;
  return folder.uri.toString();
}

/// Returns the source code of the given URI. Prefers the content of open text
/// documents, even if they're not saved yet. If none exists, asks the file
/// system.
async function readSource(uri: vs.Uri): Promise<string | null> {
  for (const doc of vs.workspace.textDocuments)
    if (doc.uri.toString() == uri.toString()) return doc.getText(); else console.log("URIs don't match: " + doc.uri + " and " + uri);
  try {
    const bytes = await vs.workspace.fs.readFile(uri);
    return new TextDecoder("utf8").decode(bytes);
  } catch (e) {
    return null;
  }
}

// function streamToString(stream: stream.Readable): stream.Readable<string> {
//   const chunks: any[] = [];
//   return new Promise((resolve, reject) => {
//     stream.on('data', (chunk) => {
//       chunks.push(Buffer.from(chunk)))
//     },
//     stream.on('error', (err) => reject(err));
//     stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
//   });
// }
async function check(path: string): Promise<MartinaiseError[]> {
  let soilBinary = "/home/marcel/projects/soil/soil-asm";
  let martinaiseCompiler = "/home/marcel/projects/martinaise/martinaise.soil";

  console.info(`Spawning ${soilBinary} with ${path}`);
  let soil = child_process.spawn(soilBinary, [martinaiseCompiler, "analyze", path]);
  soil.on("error", (error) => console.error(`Failed to spawn: ${error}`));
  linebyline(soil.stderr).on("line", async function (line: string) {
    console.log(line);
  });

  let diagnostics: MartinaiseError[] = [];
  linebyline(soil.stdout).on('line', async function (line: string) {
    console.info("Line: " + line);
    const message = JSON.parse(line);
    if (message.type == "read_file") {
      const uri = vs.Uri.parse(message.path);
      const content = await readSource(uri);
      // console.info("Read file: " + content);
      if (content) {
        soil.stdin.write(JSON.stringify({ type: "read_file", success: true, content: content }));
        soil.stdin.write("\n");
      } else {
        soil.stdin.write(JSON.stringify({ type: "read_file", success: false }));
      }
    }
    if (message.type == "error") {
      diagnostics.push(message as MartinaiseError);
    }
  });

  const exitCode = await new Promise((resolve) => soil.on("close", (exitCode) => resolve(exitCode)));
  console.info(`Martinaise exited with ${exitCode}.`);

  return diagnostics;
}
type MartinaiseError = {
  source: {
    file: string,
    start: integer,
    end: integer,
  },
  title: string,
  description: string,
  context: string[],
};

class MartinaiseCodeLensProvider implements vs.CodeLensProvider {
  public provideCodeLenses(_: vs.TextDocument, __: vs.CancellationToken): vs.CodeLens[] {
    var command: vs.Command = {
      title: "Fuzz",
      command: "fuzz",
      tooltip: "tooltip",
      arguments: [],
    };
    return [
      new vs.CodeLens(new vs.Range(new vs.Position(1, 1), new vs.Position(1, 3)), command)
    ];
  }

  public resolveCodeLens?(codeLens: vs.CodeLens, _: vs.CancellationToken): vs.CodeLens {
    return codeLens;
  }
}

class MartinaiseCodeActionsProvider implements vs.CodeActionProvider {
  provideCodeActions(_: vs.TextDocument, __: vs.Range | vs.Selection, ___: vs.CodeActionContext, ____: vs.CancellationToken): vs.ProviderResult<(vs.Command | vs.CodeAction)[]> {
    var command: vs.Command = {
      title: "Fuzz",
      command: "fuzz",
      tooltip: "tooltip",
      arguments: [],
    };
    return [
      command
    ];
  }
  resolveCodeAction?(codeAction: vs.CodeAction, _: vs.CancellationToken): vs.ProviderResult<vs.CodeAction> {
    return codeAction;
  }
}
