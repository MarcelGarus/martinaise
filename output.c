// This file is a compiler target.
#include <stdio.h>

#include <stdint.h>

/// Types

// Never
typedef struct {
  // TODO: Is this needed?
} mar_Never;

// Nothing
typedef struct {
} mar_Nothing;

// I8
typedef struct {
  int8_t value;
} mar_I8;

// I16
typedef struct {
  int16_t value;
} mar_I16;

// I32
typedef struct {
  int32_t value;
} mar_I32;

// I64
typedef struct {
  int64_t value;
} mar_I64;

// U8
typedef struct {
  uint8_t value;
} mar_U8;

// U16
typedef struct {
  uint16_t value;
} mar_U16;

// U32
typedef struct {
  uint32_t value;
} mar_U32;

// U64
typedef struct {
  uint64_t value;
} mar_U64;

// Bool
typedef struct {
  enum {
    mar_true,
    mar_false,
  } variant;
  union {
    mar_Nothing mar_true;
    mar_Nothing mar_false;
  } as;
} mar_Bool;

// StdoutWriter
typedef struct {
} mar_StdoutWriter;

// Ordering
typedef struct {
  enum {
    mar_less,
    mar_equal,
    mar_greater,
  } variant;
  union {
    mar_Nothing mar_less;
    mar_Nothing mar_equal;
    mar_Nothing mar_greater;
  } as;
} mar_Ordering;

// Char
typedef struct {
  mar_U8 value;
} mar_Char;

/// Function declarations

/* add(I64, I64) */ mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* compare_to(U64, U64) */ mar_Ordering mar_compare__to_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* compare_to(U8, U8) */ mar_Ordering mar_compare__to_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(U64, U64) */ mar_U64 mar_divide_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](U64, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* is_at_least(U64, U64) */ mar_Bool mar_is__at__least_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* is_at_least(U8, U8) */ mar_Bool mar_is__at__least_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* is_greater_or_equal(Ordering) */ mar_Bool mar_is__greater__or__equal_po_Ordering_pc_(mar_Ordering arg0);
/* main() */ mar_I64 mar_main_po__pc_();
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* modulo(U64, U64) */ mar_U64 mar_modulo_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* print[U64](U64) */ mar_Nothing mar_print_bo_U64_bc__po_U64_pc_(mar_U64 arg0);
/* print[U8](U8) */ mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[U64](U64) */ mar_Nothing mar_println_bo_U64_bc__po_U64_pc_(mar_U64 arg0);
/* println[U8](U8) */ mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* to_U8(U64) */ mar_U8 mar_to__U8_po_U64_pc_(mar_U64 arg0);
/* write(StdoutWriter, U8) */ mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1);

/// Function definitions

// add(I64, I64)
mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// add(U8, U8)
mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// compare_to(U64, U64)
mar_Ordering mar_compare__to_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_Ordering ordering;
  ordering.variant = (arg0.value == arg1.value) ? mar_equal : (arg0.value > arg1.value) ? mar_greater : mar_less;
  mar_Nothing nothing;
  ordering.as.mar_equal = nothing;
  return ordering;
}

// compare_to(U8, U8)
mar_Ordering mar_compare__to_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_Ordering ordering;
  ordering.variant = (arg0.value == arg1.value) ? mar_equal : (arg0.value > arg1.value) ? mar_greater : mar_less;
  mar_Nothing nothing;
  ordering.as.mar_equal = nothing;
  return ordering;
}

// divide(I64, I64)
mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// divide(U64, U64)
mar_U64 mar_divide_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// divide(U8, U8)
mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// dump[StdoutWriter](U64, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_Nothing _2;
  expr_3: mar_U64 _3; _3.value = 10000000000000000000ULL;
  expr_4: mar_Bool _4 = mar_is__at__least_po_U64_c_U64_pc_(_0, _3);
  expr_5: if (_4.variant == mar_true) goto expr_7;
  expr_6: goto expr_19;
  expr_7: mar_U64 _7; _7.value = 10000000000000000000ULL;
  expr_8: mar_U64 _8 = mar_divide_po_U64_c_U64_pc_(_0, _7);
  expr_9: mar_U64 _9; _9.value = 10ULL;
  expr_10: mar_U64 _10 = mar_modulo_po_U64_c_U64_pc_(_8, _9);
  expr_11: mar_U8 _11 = mar_to__U8_po_U64_pc_(_10);
  expr_12: mar_U8 _12; _12.value = 48ULL;
  expr_13: mar_Char _13; _13.value = _12;
  expr_14: mar_U8 _14 = _13.value;
  expr_15: mar_U8 _15 = mar_add_po_U8_c_U8_pc_(_11, _14);
  expr_16: mar_Nothing _16 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _15);
  expr_17: _2 = _16; mar_Nothing _17;
  expr_18: goto expr_19;
  expr_19: mar_Nothing _19;
  expr_20: mar_U64 _20; _20.value = 1000000000000000000ULL;
  expr_21: mar_Bool _21 = mar_is__at__least_po_U64_c_U64_pc_(_0, _20);
  expr_22: if (_21.variant == mar_true) goto expr_24;
  expr_23: goto expr_36;
  expr_24: mar_U64 _24; _24.value = 1000000000000000000ULL;
  expr_25: mar_U64 _25 = mar_divide_po_U64_c_U64_pc_(_0, _24);
  expr_26: mar_U64 _26; _26.value = 10ULL;
  expr_27: mar_U64 _27 = mar_modulo_po_U64_c_U64_pc_(_25, _26);
  expr_28: mar_U8 _28 = mar_to__U8_po_U64_pc_(_27);
  expr_29: mar_U8 _29; _29.value = 48ULL;
  expr_30: mar_Char _30; _30.value = _29;
  expr_31: mar_U8 _31 = _30.value;
  expr_32: mar_U8 _32 = mar_add_po_U8_c_U8_pc_(_28, _31);
  expr_33: mar_Nothing _33 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _32);
  expr_34: _19 = _33; mar_Nothing _34;
  expr_35: goto expr_36;
  expr_36: mar_Nothing _36;
  expr_37: mar_U64 _37; _37.value = 100000000000000000ULL;
  expr_38: mar_Bool _38 = mar_is__at__least_po_U64_c_U64_pc_(_0, _37);
  expr_39: if (_38.variant == mar_true) goto expr_41;
  expr_40: goto expr_53;
  expr_41: mar_U64 _41; _41.value = 100000000000000000ULL;
  expr_42: mar_U64 _42 = mar_divide_po_U64_c_U64_pc_(_0, _41);
  expr_43: mar_U64 _43; _43.value = 10ULL;
  expr_44: mar_U64 _44 = mar_modulo_po_U64_c_U64_pc_(_42, _43);
  expr_45: mar_U8 _45 = mar_to__U8_po_U64_pc_(_44);
  expr_46: mar_U8 _46; _46.value = 48ULL;
  expr_47: mar_Char _47; _47.value = _46;
  expr_48: mar_U8 _48 = _47.value;
  expr_49: mar_U8 _49 = mar_add_po_U8_c_U8_pc_(_45, _48);
  expr_50: mar_Nothing _50 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _49);
  expr_51: _36 = _50; mar_Nothing _51;
  expr_52: goto expr_53;
  expr_53: mar_Nothing _53;
  expr_54: mar_U64 _54; _54.value = 10000000000000000ULL;
  expr_55: mar_Bool _55 = mar_is__at__least_po_U64_c_U64_pc_(_0, _54);
  expr_56: if (_55.variant == mar_true) goto expr_58;
  expr_57: goto expr_70;
  expr_58: mar_U64 _58; _58.value = 10000000000000000ULL;
  expr_59: mar_U64 _59 = mar_divide_po_U64_c_U64_pc_(_0, _58);
  expr_60: mar_U64 _60; _60.value = 10ULL;
  expr_61: mar_U64 _61 = mar_modulo_po_U64_c_U64_pc_(_59, _60);
  expr_62: mar_U8 _62 = mar_to__U8_po_U64_pc_(_61);
  expr_63: mar_U8 _63; _63.value = 48ULL;
  expr_64: mar_Char _64; _64.value = _63;
  expr_65: mar_U8 _65 = _64.value;
  expr_66: mar_U8 _66 = mar_add_po_U8_c_U8_pc_(_62, _65);
  expr_67: mar_Nothing _67 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _66);
  expr_68: _53 = _67; mar_Nothing _68;
  expr_69: goto expr_70;
  expr_70: mar_Nothing _70;
  expr_71: mar_U64 _71; _71.value = 1000000000000000ULL;
  expr_72: mar_Bool _72 = mar_is__at__least_po_U64_c_U64_pc_(_0, _71);
  expr_73: if (_72.variant == mar_true) goto expr_75;
  expr_74: goto expr_87;
  expr_75: mar_U64 _75; _75.value = 1000000000000000ULL;
  expr_76: mar_U64 _76 = mar_divide_po_U64_c_U64_pc_(_0, _75);
  expr_77: mar_U64 _77; _77.value = 10ULL;
  expr_78: mar_U64 _78 = mar_modulo_po_U64_c_U64_pc_(_76, _77);
  expr_79: mar_U8 _79 = mar_to__U8_po_U64_pc_(_78);
  expr_80: mar_U8 _80; _80.value = 48ULL;
  expr_81: mar_Char _81; _81.value = _80;
  expr_82: mar_U8 _82 = _81.value;
  expr_83: mar_U8 _83 = mar_add_po_U8_c_U8_pc_(_79, _82);
  expr_84: mar_Nothing _84 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _83);
  expr_85: _70 = _84; mar_Nothing _85;
  expr_86: goto expr_87;
  expr_87: mar_Nothing _87;
  expr_88: mar_U64 _88; _88.value = 100000000000000ULL;
  expr_89: mar_Bool _89 = mar_is__at__least_po_U64_c_U64_pc_(_0, _88);
  expr_90: if (_89.variant == mar_true) goto expr_92;
  expr_91: goto expr_104;
  expr_92: mar_U64 _92; _92.value = 100000000000000ULL;
  expr_93: mar_U64 _93 = mar_divide_po_U64_c_U64_pc_(_0, _92);
  expr_94: mar_U64 _94; _94.value = 10ULL;
  expr_95: mar_U64 _95 = mar_modulo_po_U64_c_U64_pc_(_93, _94);
  expr_96: mar_U8 _96 = mar_to__U8_po_U64_pc_(_95);
  expr_97: mar_U8 _97; _97.value = 48ULL;
  expr_98: mar_Char _98; _98.value = _97;
  expr_99: mar_U8 _99 = _98.value;
  expr_100: mar_U8 _100 = mar_add_po_U8_c_U8_pc_(_96, _99);
  expr_101: mar_Nothing _101 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _100);
  expr_102: _87 = _101; mar_Nothing _102;
  expr_103: goto expr_104;
  expr_104: mar_Nothing _104;
  expr_105: mar_U64 _105; _105.value = 10000000000000ULL;
  expr_106: mar_Bool _106 = mar_is__at__least_po_U64_c_U64_pc_(_0, _105);
  expr_107: if (_106.variant == mar_true) goto expr_109;
  expr_108: goto expr_121;
  expr_109: mar_U64 _109; _109.value = 10000000000000ULL;
  expr_110: mar_U64 _110 = mar_divide_po_U64_c_U64_pc_(_0, _109);
  expr_111: mar_U64 _111; _111.value = 10ULL;
  expr_112: mar_U64 _112 = mar_modulo_po_U64_c_U64_pc_(_110, _111);
  expr_113: mar_U8 _113 = mar_to__U8_po_U64_pc_(_112);
  expr_114: mar_U8 _114; _114.value = 48ULL;
  expr_115: mar_Char _115; _115.value = _114;
  expr_116: mar_U8 _116 = _115.value;
  expr_117: mar_U8 _117 = mar_add_po_U8_c_U8_pc_(_113, _116);
  expr_118: mar_Nothing _118 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _117);
  expr_119: _104 = _118; mar_Nothing _119;
  expr_120: goto expr_121;
  expr_121: mar_Nothing _121;
  expr_122: mar_U64 _122; _122.value = 1000000000000ULL;
  expr_123: mar_Bool _123 = mar_is__at__least_po_U64_c_U64_pc_(_0, _122);
  expr_124: if (_123.variant == mar_true) goto expr_126;
  expr_125: goto expr_138;
  expr_126: mar_U64 _126; _126.value = 1000000000000ULL;
  expr_127: mar_U64 _127 = mar_divide_po_U64_c_U64_pc_(_0, _126);
  expr_128: mar_U64 _128; _128.value = 10ULL;
  expr_129: mar_U64 _129 = mar_modulo_po_U64_c_U64_pc_(_127, _128);
  expr_130: mar_U8 _130 = mar_to__U8_po_U64_pc_(_129);
  expr_131: mar_U8 _131; _131.value = 48ULL;
  expr_132: mar_Char _132; _132.value = _131;
  expr_133: mar_U8 _133 = _132.value;
  expr_134: mar_U8 _134 = mar_add_po_U8_c_U8_pc_(_130, _133);
  expr_135: mar_Nothing _135 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _134);
  expr_136: _121 = _135; mar_Nothing _136;
  expr_137: goto expr_138;
  expr_138: mar_Nothing _138;
  expr_139: mar_U64 _139; _139.value = 100000000000ULL;
  expr_140: mar_Bool _140 = mar_is__at__least_po_U64_c_U64_pc_(_0, _139);
  expr_141: if (_140.variant == mar_true) goto expr_143;
  expr_142: goto expr_155;
  expr_143: mar_U64 _143; _143.value = 100000000000ULL;
  expr_144: mar_U64 _144 = mar_divide_po_U64_c_U64_pc_(_0, _143);
  expr_145: mar_U64 _145; _145.value = 10ULL;
  expr_146: mar_U64 _146 = mar_modulo_po_U64_c_U64_pc_(_144, _145);
  expr_147: mar_U8 _147 = mar_to__U8_po_U64_pc_(_146);
  expr_148: mar_U8 _148; _148.value = 48ULL;
  expr_149: mar_Char _149; _149.value = _148;
  expr_150: mar_U8 _150 = _149.value;
  expr_151: mar_U8 _151 = mar_add_po_U8_c_U8_pc_(_147, _150);
  expr_152: mar_Nothing _152 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _151);
  expr_153: _138 = _152; mar_Nothing _153;
  expr_154: goto expr_155;
  expr_155: mar_Nothing _155;
  expr_156: mar_U64 _156; _156.value = 10000000000ULL;
  expr_157: mar_Bool _157 = mar_is__at__least_po_U64_c_U64_pc_(_0, _156);
  expr_158: if (_157.variant == mar_true) goto expr_160;
  expr_159: goto expr_172;
  expr_160: mar_U64 _160; _160.value = 10000000000ULL;
  expr_161: mar_U64 _161 = mar_divide_po_U64_c_U64_pc_(_0, _160);
  expr_162: mar_U64 _162; _162.value = 10ULL;
  expr_163: mar_U64 _163 = mar_modulo_po_U64_c_U64_pc_(_161, _162);
  expr_164: mar_U8 _164 = mar_to__U8_po_U64_pc_(_163);
  expr_165: mar_U8 _165; _165.value = 48ULL;
  expr_166: mar_Char _166; _166.value = _165;
  expr_167: mar_U8 _167 = _166.value;
  expr_168: mar_U8 _168 = mar_add_po_U8_c_U8_pc_(_164, _167);
  expr_169: mar_Nothing _169 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _168);
  expr_170: _155 = _169; mar_Nothing _170;
  expr_171: goto expr_172;
  expr_172: mar_Nothing _172;
  expr_173: mar_U64 _173; _173.value = 1000000000ULL;
  expr_174: mar_Bool _174 = mar_is__at__least_po_U64_c_U64_pc_(_0, _173);
  expr_175: if (_174.variant == mar_true) goto expr_177;
  expr_176: goto expr_189;
  expr_177: mar_U64 _177; _177.value = 1000000000ULL;
  expr_178: mar_U64 _178 = mar_divide_po_U64_c_U64_pc_(_0, _177);
  expr_179: mar_U64 _179; _179.value = 10ULL;
  expr_180: mar_U64 _180 = mar_modulo_po_U64_c_U64_pc_(_178, _179);
  expr_181: mar_U8 _181 = mar_to__U8_po_U64_pc_(_180);
  expr_182: mar_U8 _182; _182.value = 48ULL;
  expr_183: mar_Char _183; _183.value = _182;
  expr_184: mar_U8 _184 = _183.value;
  expr_185: mar_U8 _185 = mar_add_po_U8_c_U8_pc_(_181, _184);
  expr_186: mar_Nothing _186 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _185);
  expr_187: _172 = _186; mar_Nothing _187;
  expr_188: goto expr_189;
  expr_189: mar_Nothing _189;
  expr_190: mar_U64 _190; _190.value = 100000000ULL;
  expr_191: mar_Bool _191 = mar_is__at__least_po_U64_c_U64_pc_(_0, _190);
  expr_192: if (_191.variant == mar_true) goto expr_194;
  expr_193: goto expr_206;
  expr_194: mar_U64 _194; _194.value = 100000000ULL;
  expr_195: mar_U64 _195 = mar_divide_po_U64_c_U64_pc_(_0, _194);
  expr_196: mar_U64 _196; _196.value = 10ULL;
  expr_197: mar_U64 _197 = mar_modulo_po_U64_c_U64_pc_(_195, _196);
  expr_198: mar_U8 _198 = mar_to__U8_po_U64_pc_(_197);
  expr_199: mar_U8 _199; _199.value = 48ULL;
  expr_200: mar_Char _200; _200.value = _199;
  expr_201: mar_U8 _201 = _200.value;
  expr_202: mar_U8 _202 = mar_add_po_U8_c_U8_pc_(_198, _201);
  expr_203: mar_Nothing _203 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _202);
  expr_204: _189 = _203; mar_Nothing _204;
  expr_205: goto expr_206;
  expr_206: mar_Nothing _206;
  expr_207: mar_U64 _207; _207.value = 10000000ULL;
  expr_208: mar_Bool _208 = mar_is__at__least_po_U64_c_U64_pc_(_0, _207);
  expr_209: if (_208.variant == mar_true) goto expr_211;
  expr_210: goto expr_223;
  expr_211: mar_U64 _211; _211.value = 10000000ULL;
  expr_212: mar_U64 _212 = mar_divide_po_U64_c_U64_pc_(_0, _211);
  expr_213: mar_U64 _213; _213.value = 10ULL;
  expr_214: mar_U64 _214 = mar_modulo_po_U64_c_U64_pc_(_212, _213);
  expr_215: mar_U8 _215 = mar_to__U8_po_U64_pc_(_214);
  expr_216: mar_U8 _216; _216.value = 48ULL;
  expr_217: mar_Char _217; _217.value = _216;
  expr_218: mar_U8 _218 = _217.value;
  expr_219: mar_U8 _219 = mar_add_po_U8_c_U8_pc_(_215, _218);
  expr_220: mar_Nothing _220 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _219);
  expr_221: _206 = _220; mar_Nothing _221;
  expr_222: goto expr_223;
  expr_223: mar_Nothing _223;
  expr_224: mar_U64 _224; _224.value = 1000000ULL;
  expr_225: mar_Bool _225 = mar_is__at__least_po_U64_c_U64_pc_(_0, _224);
  expr_226: if (_225.variant == mar_true) goto expr_228;
  expr_227: goto expr_240;
  expr_228: mar_U64 _228; _228.value = 1000000ULL;
  expr_229: mar_U64 _229 = mar_divide_po_U64_c_U64_pc_(_0, _228);
  expr_230: mar_U64 _230; _230.value = 10ULL;
  expr_231: mar_U64 _231 = mar_modulo_po_U64_c_U64_pc_(_229, _230);
  expr_232: mar_U8 _232 = mar_to__U8_po_U64_pc_(_231);
  expr_233: mar_U8 _233; _233.value = 48ULL;
  expr_234: mar_Char _234; _234.value = _233;
  expr_235: mar_U8 _235 = _234.value;
  expr_236: mar_U8 _236 = mar_add_po_U8_c_U8_pc_(_232, _235);
  expr_237: mar_Nothing _237 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _236);
  expr_238: _223 = _237; mar_Nothing _238;
  expr_239: goto expr_240;
  expr_240: mar_Nothing _240;
  expr_241: mar_U64 _241; _241.value = 100000ULL;
  expr_242: mar_Bool _242 = mar_is__at__least_po_U64_c_U64_pc_(_0, _241);
  expr_243: if (_242.variant == mar_true) goto expr_245;
  expr_244: goto expr_257;
  expr_245: mar_U64 _245; _245.value = 100000ULL;
  expr_246: mar_U64 _246 = mar_divide_po_U64_c_U64_pc_(_0, _245);
  expr_247: mar_U64 _247; _247.value = 10ULL;
  expr_248: mar_U64 _248 = mar_modulo_po_U64_c_U64_pc_(_246, _247);
  expr_249: mar_U8 _249 = mar_to__U8_po_U64_pc_(_248);
  expr_250: mar_U8 _250; _250.value = 48ULL;
  expr_251: mar_Char _251; _251.value = _250;
  expr_252: mar_U8 _252 = _251.value;
  expr_253: mar_U8 _253 = mar_add_po_U8_c_U8_pc_(_249, _252);
  expr_254: mar_Nothing _254 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _253);
  expr_255: _240 = _254; mar_Nothing _255;
  expr_256: goto expr_257;
  expr_257: mar_Nothing _257;
  expr_258: mar_U64 _258; _258.value = 10000ULL;
  expr_259: mar_Bool _259 = mar_is__at__least_po_U64_c_U64_pc_(_0, _258);
  expr_260: if (_259.variant == mar_true) goto expr_262;
  expr_261: goto expr_274;
  expr_262: mar_U64 _262; _262.value = 10000ULL;
  expr_263: mar_U64 _263 = mar_divide_po_U64_c_U64_pc_(_0, _262);
  expr_264: mar_U64 _264; _264.value = 10ULL;
  expr_265: mar_U64 _265 = mar_modulo_po_U64_c_U64_pc_(_263, _264);
  expr_266: mar_U8 _266 = mar_to__U8_po_U64_pc_(_265);
  expr_267: mar_U8 _267; _267.value = 48ULL;
  expr_268: mar_Char _268; _268.value = _267;
  expr_269: mar_U8 _269 = _268.value;
  expr_270: mar_U8 _270 = mar_add_po_U8_c_U8_pc_(_266, _269);
  expr_271: mar_Nothing _271 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _270);
  expr_272: _257 = _271; mar_Nothing _272;
  expr_273: goto expr_274;
  expr_274: mar_Nothing _274;
  expr_275: mar_U64 _275; _275.value = 1000ULL;
  expr_276: mar_Bool _276 = mar_is__at__least_po_U64_c_U64_pc_(_0, _275);
  expr_277: if (_276.variant == mar_true) goto expr_279;
  expr_278: goto expr_291;
  expr_279: mar_U64 _279; _279.value = 1000ULL;
  expr_280: mar_U64 _280 = mar_divide_po_U64_c_U64_pc_(_0, _279);
  expr_281: mar_U64 _281; _281.value = 10ULL;
  expr_282: mar_U64 _282 = mar_modulo_po_U64_c_U64_pc_(_280, _281);
  expr_283: mar_U8 _283 = mar_to__U8_po_U64_pc_(_282);
  expr_284: mar_U8 _284; _284.value = 48ULL;
  expr_285: mar_Char _285; _285.value = _284;
  expr_286: mar_U8 _286 = _285.value;
  expr_287: mar_U8 _287 = mar_add_po_U8_c_U8_pc_(_283, _286);
  expr_288: mar_Nothing _288 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _287);
  expr_289: _274 = _288; mar_Nothing _289;
  expr_290: goto expr_291;
  expr_291: mar_Nothing _291;
  expr_292: mar_U64 _292; _292.value = 100ULL;
  expr_293: mar_Bool _293 = mar_is__at__least_po_U64_c_U64_pc_(_0, _292);
  expr_294: if (_293.variant == mar_true) goto expr_296;
  expr_295: goto expr_308;
  expr_296: mar_U64 _296; _296.value = 100ULL;
  expr_297: mar_U64 _297 = mar_divide_po_U64_c_U64_pc_(_0, _296);
  expr_298: mar_U64 _298; _298.value = 10ULL;
  expr_299: mar_U64 _299 = mar_modulo_po_U64_c_U64_pc_(_297, _298);
  expr_300: mar_U8 _300 = mar_to__U8_po_U64_pc_(_299);
  expr_301: mar_U8 _301; _301.value = 48ULL;
  expr_302: mar_Char _302; _302.value = _301;
  expr_303: mar_U8 _303 = _302.value;
  expr_304: mar_U8 _304 = mar_add_po_U8_c_U8_pc_(_300, _303);
  expr_305: mar_Nothing _305 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _304);
  expr_306: _291 = _305; mar_Nothing _306;
  expr_307: goto expr_308;
  expr_308: mar_Nothing _308;
  expr_309: mar_U64 _309; _309.value = 100ULL;
  expr_310: mar_Bool _310 = mar_is__at__least_po_U64_c_U64_pc_(_0, _309);
  expr_311: if (_310.variant == mar_true) goto expr_313;
  expr_312: goto expr_325;
  expr_313: mar_U64 _313; _313.value = 100ULL;
  expr_314: mar_U64 _314 = mar_divide_po_U64_c_U64_pc_(_0, _313);
  expr_315: mar_U64 _315; _315.value = 10ULL;
  expr_316: mar_U64 _316 = mar_modulo_po_U64_c_U64_pc_(_314, _315);
  expr_317: mar_U8 _317 = mar_to__U8_po_U64_pc_(_316);
  expr_318: mar_U8 _318; _318.value = 48ULL;
  expr_319: mar_Char _319; _319.value = _318;
  expr_320: mar_U8 _320 = _319.value;
  expr_321: mar_U8 _321 = mar_add_po_U8_c_U8_pc_(_317, _320);
  expr_322: mar_Nothing _322 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _321);
  expr_323: _308 = _322; mar_Nothing _323;
  expr_324: goto expr_325;
  expr_325: mar_Nothing _325;
  expr_326: mar_U64 _326; _326.value = 10ULL;
  expr_327: mar_Bool _327 = mar_is__at__least_po_U64_c_U64_pc_(_0, _326);
  expr_328: if (_327.variant == mar_true) goto expr_330;
  expr_329: goto expr_342;
  expr_330: mar_U64 _330; _330.value = 10ULL;
  expr_331: mar_U64 _331 = mar_divide_po_U64_c_U64_pc_(_0, _330);
  expr_332: mar_U64 _332; _332.value = 10ULL;
  expr_333: mar_U64 _333 = mar_modulo_po_U64_c_U64_pc_(_331, _332);
  expr_334: mar_U8 _334 = mar_to__U8_po_U64_pc_(_333);
  expr_335: mar_U8 _335; _335.value = 48ULL;
  expr_336: mar_Char _336; _336.value = _335;
  expr_337: mar_U8 _337 = _336.value;
  expr_338: mar_U8 _338 = mar_add_po_U8_c_U8_pc_(_334, _337);
  expr_339: mar_Nothing _339 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _338);
  expr_340: _325 = _339; mar_Nothing _340;
  expr_341: goto expr_342;
  expr_342: mar_U64 _342; _342.value = 10ULL;
  expr_343: mar_U64 _343 = mar_modulo_po_U64_c_U64_pc_(_0, _342);
  expr_344: mar_U8 _344 = mar_to__U8_po_U64_pc_(_343);
  expr_345: mar_U8 _345; _345.value = 48ULL;
  expr_346: mar_Char _346; _346.value = _345;
  expr_347: mar_U8 _347 = _346.value;
  expr_348: mar_U8 _348 = mar_add_po_U8_c_U8_pc_(_344, _347);
  expr_349: mar_Nothing _349 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _348);
  expr_350: // end
  return _349;
}

// dump[StdoutWriter](U8, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_Nothing _2;
  expr_3: mar_U8 _3; _3.value = 100ULL;
  expr_4: mar_Bool _4 = mar_is__at__least_po_U8_c_U8_pc_(_0, _3);
  expr_5: if (_4.variant == mar_true) goto expr_7;
  expr_6: goto expr_18;
  expr_7: mar_U8 _7; _7.value = 100ULL;
  expr_8: mar_U8 _8 = mar_divide_po_U8_c_U8_pc_(_0, _7);
  expr_9: mar_U8 _9; _9.value = 10ULL;
  expr_10: mar_U8 _10 = mar_modulo_po_U8_c_U8_pc_(_8, _9);
  expr_11: mar_U8 _11; _11.value = 48ULL;
  expr_12: mar_Char _12; _12.value = _11;
  expr_13: mar_U8 _13 = _12.value;
  expr_14: mar_U8 _14 = mar_add_po_U8_c_U8_pc_(_10, _13);
  expr_15: mar_Nothing _15 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _14);
  expr_16: _2 = _15; mar_Nothing _16;
  expr_17: goto expr_18;
  expr_18: mar_Nothing _18;
  expr_19: mar_U8 _19; _19.value = 10ULL;
  expr_20: mar_Bool _20 = mar_is__at__least_po_U8_c_U8_pc_(_0, _19);
  expr_21: if (_20.variant == mar_true) goto expr_23;
  expr_22: goto expr_34;
  expr_23: mar_U8 _23; _23.value = 10ULL;
  expr_24: mar_U8 _24 = mar_divide_po_U8_c_U8_pc_(_0, _23);
  expr_25: mar_U8 _25; _25.value = 10ULL;
  expr_26: mar_U8 _26 = mar_modulo_po_U8_c_U8_pc_(_24, _25);
  expr_27: mar_U8 _27; _27.value = 48ULL;
  expr_28: mar_Char _28; _28.value = _27;
  expr_29: mar_U8 _29 = _28.value;
  expr_30: mar_U8 _30 = mar_add_po_U8_c_U8_pc_(_26, _29);
  expr_31: mar_Nothing _31 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _30);
  expr_32: _18 = _31; mar_Nothing _32;
  expr_33: goto expr_34;
  expr_34: mar_U8 _34; _34.value = 10ULL;
  expr_35: mar_U8 _35 = mar_modulo_po_U8_c_U8_pc_(_0, _34);
  expr_36: mar_U8 _36; _36.value = 48ULL;
  expr_37: mar_Char _37; _37.value = _36;
  expr_38: mar_U8 _38 = _37.value;
  expr_39: mar_U8 _39 = mar_add_po_U8_c_U8_pc_(_35, _38);
  expr_40: mar_Nothing _40 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _39);
  expr_41: // end
  return _40;
}

// is_at_least(U64, U64)
mar_Bool mar_is__at__least_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U64_c_U64_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__greater__or__equal_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// is_at_least(U8, U8)
mar_Bool mar_is__at__least_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U8_c_U8_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__greater__or__equal_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// is_greater_or_equal(Ordering)
mar_Bool mar_is__greater__or__equal_po_Ordering_pc_(mar_Ordering arg0) {
  expr_0: mar_Ordering _0 = arg0;
  expr_1: mar_Bool _1;
  expr_2: if (_0.variant == mar_less) goto expr_6;
  expr_3: if (_0.variant == mar_equal) goto expr_11;
  expr_4: if (_0.variant == mar_greater) goto expr_16;
  expr_5: goto expr_2;
  expr_6: mar_Nothing _6 = _0.as.mar_less;
  expr_7: mar_Nothing _7;
  expr_8: mar_Bool _8; _8.variant = mar_false; _8.as.mar_false = _7;
  expr_9: _1 = _8; mar_Nothing _9;
  expr_10: goto expr_21;
  expr_11: mar_Nothing _11 = _0.as.mar_equal;
  expr_12: mar_Nothing _12;
  expr_13: mar_Bool _13; _13.variant = mar_true; _13.as.mar_true = _12;
  expr_14: _1 = _13; mar_Nothing _14;
  expr_15: goto expr_21;
  expr_16: mar_Nothing _16 = _0.as.mar_greater;
  expr_17: mar_Nothing _17;
  expr_18: mar_Bool _18; _18.variant = mar_true; _18.as.mar_true = _17;
  expr_19: _1 = _18; mar_Nothing _19;
  expr_20: goto expr_21;
  expr_21: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_U8 _0;
  expr_1: mar_Nothing _1;
  expr_2: mar_Bool _2; _2.variant = mar_true; _2.as.mar_true = _1;
  expr_3: if (_2.variant == mar_true) goto expr_6;
  expr_4: if (_2.variant == mar_false) goto expr_10;
  expr_5: goto expr_3;
  expr_6: mar_Nothing _6 = _2.as.mar_true;
  expr_7: mar_U8 _7; _7.value = 3ULL;
  expr_8: _0 = _7; mar_Nothing _8;
  expr_9: goto expr_14;
  expr_10: mar_Nothing _10 = _2.as.mar_false;
  expr_11: mar_U8 _11; _11.value = 4ULL;
  expr_12: _0 = _11; mar_Nothing _12;
  expr_13: goto expr_14;
  expr_14: mar_Nothing _14 = mar_println_bo_U8_bc__po_U8_pc_(_0);
  expr_15: mar_U64 _15; _15.value = 18446744073709551615ULL;
  expr_16: mar_Nothing _16 = mar_println_bo_U64_bc__po_U64_pc_(_15);
  expr_17: mar_I64 _17; _17.value = 3;
  expr_18: mar_I64 _18; _18.value = 4;
  expr_19: mar_I64 _19 = mar_add_po_I64_c_I64_pc_(_17, _18);
  expr_20: mar_I64 _20; _20.value = 4;
  expr_21: mar_I64 _21; _21.value = 2;
  expr_22: mar_I64 _22 = mar_divide_po_I64_c_I64_pc_(_20, _21);
  expr_23: mar_I64 _23 = mar_multiply_po_I64_c_I64_pc_(_19, _22);
  expr_24: mar_I64 _24; _24.value = 10;
  expr_25: mar_I64 _25 = mar_modulo_po_I64_c_I64_pc_(_23, _24);
  expr_26: return _25; mar_Never _26;
  expr_27: // end
}

// modulo(I64, I64)
mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// modulo(U64, U64)
mar_U64 mar_modulo_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// modulo(U8, U8)
mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// multiply(I64, I64)
mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value * arg1.value;
  return i;
}

// print[U64](U64)
mar_Nothing mar_print_bo_U64_bc__po_U64_pc_(mar_U64 arg0) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(_0, _1);
  expr_3: // end
  return _2;
}

// print[U8](U8)
mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_0, _1);
  expr_3: // end
  return _2;
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// println[U64](U64)
mar_Nothing mar_println_bo_U64_bc__po_U64_pc_(mar_U64 arg0) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_U64_bc__po_U64_pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10ULL;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: // end
  return _4;
}

// println[U8](U8)
mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_U8_bc__po_U8_pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10ULL;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: // end
  return _4;
}

// to_U8(U64)
mar_U8 mar_to__U8_po_U64_pc_(mar_U64 arg0) {
  mar_U8 i;
  i.value = arg0.value;
  return i;
}

// write(StdoutWriter, U8)
mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1) {
  expr_0: mar_StdoutWriter _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Nothing _2 = mar_print__to__stdout_po_U8_pc_(_1);
  expr_3: // end
  return _2;
}

// actual main function
int main() {
  return mar_main_po__pc_().value;
}
