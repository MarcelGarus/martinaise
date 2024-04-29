import * as child_process from "child_process";
import { readFile } from "fs/promises";
import * as stream from "stream";
import * as vs from "vscode";
import {
  StreamInfo,
  integer
} from "vscode-languageclient/node";

export async function activate(context: vs.ExtensionContext) {
  console.info("Activated Martinaise extension!");
  loadCompiler();

  diagnosticCollection = vs.languages.createDiagnosticCollection("martinaise");
  context.subscriptions.push(diagnosticCollection);

  vs.window.onDidChangeVisibleTextEditors(() => {
    update();
  });
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

// The Soil binary that is the compiler. It's only loaded once at the beginning
// instead of every time we want to execute the compiler.
let compiler: Buffer | null = null;
async function loadCompiler() {
  console.info("Loading compiler");
  compiler = await readFile(`/home/marcel/projects/martinaise/martinaise.soil`);
  console.log(`Loaded compiler (${compiler.byteLength} bytes)`);
}

let diagnosticCollection: vs.DiagnosticCollection;

function update() {
  for (const editor of vs.window.visibleTextEditors) {
    const uri = editor.document.uri.toString();
    if (!uri.endsWith(".mar")) continue;

    check(uri).then(errors => {
      diagnosticCollection.clear();
      let diagnosticMap: Map<string, vs.Diagnostic[]> = new Map();
      errors.forEach(error => {
        let canonicalFile = vs.Uri.file(`${error.source.file}.mar`).toString();
        let range = new vs.Range(1, 1, 1, 3);
        let diagnostics = diagnosticMap.get(canonicalFile) ?? [];
        diagnostics.push(new vs.Diagnostic(range, error.title, vs.DiagnosticSeverity.Error));
        diagnosticMap.set(canonicalFile, diagnostics);
      });
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
function streamToString(stream: stream.Readable): Promise<string> {
  const chunks: any[] = [];
  return new Promise((resolve, reject) => {
    stream.on('data', (chunk) => chunks.push(Buffer.from(chunk)));
    stream.on('error', (err) => reject(err));
    stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
  });
}
async function check(path: string): Promise<MartinaiseError[]> {
  // return [];
  
  console.info("Spawning /home/marcel/projects/soil/soil-asm");
  // const ls = child_process.spawn("ls", ["-lh", "/usr"]);
  // ls.stdout.on("data", (data) => {
  //   console.log(`ls stdout: ${data}`);
  // });

  let soil = child_process.spawn(
    "/home/marcel/projects/soil/soil-asm",
    ["soil", path],
    {
      // "-json", "soil", path
      // cwd: workspaceFolder(),
      // shell: true,
    },
  );
  soil.on("error", (data) => console.error(`Spawning soil failed: ${data}`));
  soil.stdin.write(compiler);
  soil.stdout.on("data", (data) => {
    console.log(`soil stdout: ${data}`);
  });
  soil.stderr.on("data", (data) => {
    console.log(`soil stderr: ${data}`);
  });
  // console.log("Spawned");
  // let compiler = await readFile(`${workspaceFolder()}/martinaise.soil`)
  // console.log("Writing compiler");
  // soil.stdin.write(compiler);
  // console.log("Closing stdin");
  // soil.stdin.destroy();

  // console.log("Waiting for exit");
  // await new Promise((resolve) => process.on("exit", () => resolve(null)));
  // let exitCode = process.exitCode;
  // console.info("Martinaise exited with " + exitCode);
  // let output = await streamToString(process.stderr);
  // console.info(output);

  // let diagnostics = output.split("\n").map((line) => JSON.parse(line));
  // console.error(diagnostics);
  return [];
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

// The following code is taken (and slightly modified) from https://github.com/Dart-Code/Dart-Code
function spawnServer(): Promise<StreamInfo> {
  const process = safeSpawn();
  console.info(`PID: ${process.pid}`);

  let reader = process.stdout;
  let writer = process.stdin;

  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (enableLogging) {
    reader = process.stdout.pipe(new LoggingTransform("<=="));
    writer = new LoggingTransform("==>");
    writer.pipe(process.stdin);
  }

  process.stderr.on("data", (data) => {
    console.error(String(data));
  });

  process.addListener("close", (exitCode) => {
    if (exitCode === 101) {
      console.error("LSP server was closed with a panic.");
    } else {
      console.error(`LSP server was closed with code ${exitCode}.`);
    }
  });
  process.addListener("disconnect", () => {
    console.error("LSP server disconnected.");
  });
  process.addListener("error", (event) => {
    console.error(`LSP server had an error: ${event.toString()}`);
  });
  process.addListener("exit", (exitCode) => {
    if (exitCode === 101) {
      console.error("LSP server panicked.");
    } else {
      console.error(`LSP server exited with exit code ${exitCode}.`);
    }
  });
  process.addListener("message", () => {
    console.error("LSP server sent a message.");
  });

  return Promise.resolve({ reader, writer });
}

type SpawnedProcess = child_process.ChildProcess & {
  stdin: stream.Writable;
  stdout: stream.Readable;
  stderr: stream.Readable;
};
function safeSpawn(): SpawnedProcess {
  const configuration = vs.workspace.getConfiguration("candy");

  let command: [string, string[]] = ["candy", ["lsp"]];
  const languageServerCommand = configuration.get<string>(
    "languageServerCommand",
  );
  if (languageServerCommand && languageServerCommand.trim().length !== 0) {
    const parts = languageServerCommand.split(" ");
    command = [parts[0], parts.slice(1)];
  }

  return child_process.spawn(command[0], command[1], {
    cwd: vs.workspace.rootPath,
    env: { ...process.env, RUST_BACKTRACE: "FULL" },
    shell: true,
  }) as SpawnedProcess;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
class LoggingTransform extends stream.Transform {
  constructor(
    private readonly prefix: string,
    opts?: stream.TransformOptions,
  ) {
    super(opts);
  }
  public _transform(
    chunk: unknown,
    encoding: BufferEncoding,
    callback: () => void,
  ): void {
    const value = (chunk as Buffer).toString();
    const toLog = value
      .split("\r\n")
      .filter(
        (line) => line.trim().startsWith("{") || line.trim().startsWith("#"),
      )
      .join("\r\n");
    if (toLog.length > 0) {
      console.info(`${this.prefix} ${toLog}`);
    }

    this.push(Buffer.from(value, "utf8"), encoding);
    callback();
  }
}
