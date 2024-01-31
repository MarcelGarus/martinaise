import 'dart:io';

const reg8 = [
  //
  "ah", "al", "bh", "bl", "cl", "dl", "sil", "dil", "spl", "bpl",
  "r8b", "r9b", "r10b", "r11b", "r12b", "r13b", "r14b", "r15b",
];
const reg64 = [
  //
  "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "rsp", "rbp",
  "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15",
];

void main() async {
  // for (final offset in [0, 0x33333333])
  //   for (final dest in reg8)
  //     for (final source in reg64)
  //       await dumpInstruction("mov $dest, [$source + $offset]");

  for (final immediate in [0x11223344, 0x1122334455667788])
    for (final dest in reg64) await dumpInstruction("mov $dest, $immediate");
}

Future<void> dumpInstruction(String instruction) async {
  var output = await compileInstruction(instruction);
  print("${instruction.padRight(30)} $output");
}

Future<String> compileInstruction(String instruction) async {
  File("test.fasm").writeAsString("use64\n$instruction");
  final result = await Process.run('fasm', ["test.fasm"]);
  if (result.exitCode != 0)
    return result.stderr.toString().split("error: ")[1].trim();
  final bytes = await File("test.bin").readAsBytes();
  if (bytes.isEmpty) return "<empty>";
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(" ");
}
