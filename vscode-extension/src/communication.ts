import * as child_process from "child_process";
import * as linebyline from "linebyline";
import * as vs from "vscode";

// TODO: don't hardcode
const soilBinary = "/home/marcel/projects/soil-zig/soil-zig";
const martinaiseCompiler = "/home/marcel/projects/martinaise/martinaise.soil";

/// Communication with the Martinaise language server works using the following
/// schema.

interface ReadFileMessage {
  type: "read_file";
  path: string;
}
interface Src {
  file: string;
  start: {
    line: number;
    column: number;
  };
  end: {
    line: number;
    column: number;
  };
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

async function runSoil<T>(
  args: string[],
  callback: (message: T) => void,
): Promise<void> {
  const soil = child_process.spawn(soilBinary, args);
  soil.on("error", (error) => {
    console.error(`Failed to spawn: ${error.name}: ${error.message}`);
  });
  linebyline(soil.stderr).on("line", (line: string) => {
    // console.log(line);
  });
  linebyline(soil.stdout).on("line", async function (line: string) {
    console.info("Line: " + line);
    const message = JSON.parse(line) as { type: string };
    if (message.type == "read_file") {
      soil.stdin.write(await handleReadFileMessage(message as ReadFileMessage));
    } else {
      callback(message as T);
    }
  });
  await new Promise((resolve) => {
    soil.on("close", (exitCode) => {
      console.info(`martinaise analyze exited with ${exitCode}.`);
      resolve(undefined);
    });
  });
}

// Analyzing files.

export interface FunctionDefinition {
  src: Src;
  signature: string;
  fuzzable: boolean;
}
interface FunctionsMessage {
  type: "functions";
  functions: FunctionDefinition[];
}
interface ErrorMessage {
  type: "error";
  src: Src;
  title: string;
  description: string;
  context: string[];
}
export interface Error {
  src: Src;
  title: string;
  description: string;
  context: string[];
}

interface AnalysisReport {
  functions: FunctionDefinition[];
  errors: Error[];
}
export async function analyze(path: string): Promise<AnalysisReport> {
  console.log(`Analyzing ${path}`);

  const errors: Error[] = [];
  let functions: FunctionDefinition[] = [];

  await runSoil<FunctionsMessage | ErrorMessage>(
    [martinaiseCompiler, "tooling", "analyze", path],
    (message) => {
      if (message.type == "functions") {
        functions = message.functions;
      }
      if (message.type == "error") {
        errors.push(message);
      }
    },
  );

  return { functions: functions, errors: errors };
}

// Fuzzing code.

export type Signature = string;
interface ExampleMessage {
  type: "example_calls";
  fun_start_line: number;
  fun_signature: Signature;
  fun_name: string;
  calls: ExampleCall[];
}
export interface ExampleCall {
  inputs: string[];
  result: ExampleResult;
}
export type ExampleResult = ExampleReturned | ExamplePanicked;
export interface ExampleReturned {
  status: "returned";
  value: string;
}
export interface ExamplePanicked {
  status: "panicked";
  message: string;
}
export interface FunctionExamples {
  fun_start_line: number;
  fun_signature: Signature;
  fun_name: string;
  calls: ExampleCall[];
}

export async function fuzz(
  uri: vs.Uri,
  signature: string,
  newCalls: (examples: FunctionExamples) => void,
) {
  const path = uri.toString();
  if (!path.endsWith(".mar")) return;
  console.log(`Fuzzing ${signature}`);

  await runSoil<ExampleMessage>(
    [martinaiseCompiler, "tooling", "fuzz", signature],
    (message) => {
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
      if (message.type != "example_calls") throw new Error("unknown message");
      newCalls(message);
    },
  );
}

export async function fuzzToPosition(
  document: vs.TextDocument,
  position: vs.Position,
  newCalls: (examples: FunctionExamples) => void,
) {
  const path = document.uri.toString();
  if (!path.endsWith(".mar")) return;
  console.log(`Fuzzing ${path} ${JSON.stringify(position)}`);

  await runSoil<ExampleMessage>(
    [
      martinaiseCompiler,
      "tooling",
      "fuzz",
      path,
      `${position.line}:${position.character}`,
    ],
    (message) => {
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
      if (message.type != "example_calls") throw new Error("unknown message");
      newCalls(message);
    },
  );
}
