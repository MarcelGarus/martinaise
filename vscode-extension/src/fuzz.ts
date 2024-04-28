// Lots of this code are taken from Dart-Code:
// https://github.com/Dart-Code/Dart-Code/blob/075f71ca0336e94ebb480be35895b5b12314223b/src/extension/lsp/closing_labels_decorations.ts
// import * as vs from "vscode";
// import { LanguageClient } from "vscode-languageclient/node";

// export class HintsDecorations implements vs.Disposable {
//   private subscriptions: vs.Disposable[] = [];
//   private hints = new Map<string, Hint[]>();

//   private decorationType: vs.TextEditorDecorationType = vs.window.createTextEditorDecorationType({
//     after: {
//       color: "#ffdd00",
//       backgroundColor: "#ffdd00",
//       margin: "0 0 0 16px",
//     },
//     rangeBehavior: vs.DecorationRangeBehavior.ClosedOpen,
//   });

//   constructor(private readonly client: LanguageClient) {
//     this.subscriptions.push(
//       vs.window.onDidChangeVisibleTextEditors(() => {
//         this.update();
//       }),
//     );
//     this.subscriptions.push(
//       vs.workspace.onDidCloseTextDocument((document) => {
//         this.hints.delete(document.uri.toString());
//       }),
//     );
//     this.update();
//   }

//   private update() {
//     for (const editor of vs.window.visibleTextEditors) {
//       const uri = editor.document.uri.toString();
//       const hints = this.hints.get(uri);
//       if (hints === undefined) return;

//       type Item = vs.DecorationOptions & {
//         renderOptions: { after: { contentText: string } };
//       };
//       const decorations: Item[] = [];
//       for (const hint of hints) {
//         const position = this.client.protocol2CodeConverter.asPosition(
//           hint.position,
//         );
//         decorations.push({
//           range: new vs.Range(new vs.Position(1, 1), new vs.Position(1, 3)),
//           renderOptions: { after: { contentText: "Test hint" } },
//         });
//       }
//       editor.setDecorations(this.decorationType, decorations);
//     }
//   }

//   public dispose() {
//     for (const editor of vs.window.visibleTextEditors) {
//       editor.setDecorations(this.decorationType, []);
//     }
//     for (const subscription of this.subscriptions) {
//       subscription.dispose();
//     }
//   }
// }
