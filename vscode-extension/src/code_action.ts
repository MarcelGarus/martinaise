import * as vs from "vscode";

export function registerCodeActionsProvider(): vs.Disposable {
  return vs.languages.registerCodeActionsProvider(
    "martinaise",
    new MartinaiseCodeActionsProvider(),
  );
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
