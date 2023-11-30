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

// Maybe[U8]
typedef struct {
  enum {
    mar_some,
    mar_none,
  } variant;
  union {
    mar_U8 mar_some;
    mar_Nothing mar_none;
  } as;
} mar_Maybe_bo_U8_bc_;

// StdoutWriter
typedef struct {
} mar_StdoutWriter;

// Char
typedef struct {
  mar_U8 value;
} mar_Char;

/// Function declarations

/* add(I64, I64) */ mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](Char, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(mar_Char arg0, mar_StdoutWriter arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* dump[U8, StdoutWriter](Maybe[U8], StdoutWriter) */ mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Maybe_bo_U8_bc__c_StdoutWriter_pc_(mar_Maybe_bo_U8_bc_ arg0, mar_StdoutWriter arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* print[Char](Char) */ mar_Nothing mar_print_bo_Char_bc__po_Char_pc_(mar_Char arg0);
/* print[Maybe[U8]](Maybe[U8]) */ mar_Nothing mar_print_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(mar_Maybe_bo_U8_bc_ arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[Maybe[U8]](Maybe[U8]) */ mar_Nothing mar_println_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(mar_Maybe_bo_U8_bc_ arg0);
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

// divide(I64, I64)
mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// divide(U8, U8)
mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// dump[StdoutWriter](Char, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(mar_Char arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Char _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U8 _2 = _0.value;
  expr_3: mar_Nothing _3 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _2);
  expr_4: // end
  return _3;
}

// dump[StdoutWriter](U8, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U8 _2; _2.value = 100;
  expr_3: mar_U8 _3 = mar_divide_po_U8_c_U8_pc_(_0, _2);
  expr_4: mar_U8 _4; _4.value = 10;
  expr_5: mar_U8 _5 = mar_modulo_po_U8_c_U8_pc_(_3, _4);
  expr_6: mar_U8 _6; _6.value = 48;
  expr_7: mar_Char _7; _7.value = _6;
  expr_8: mar_U8 _8 = _7.value;
  expr_9: mar_U8 _9 = mar_add_po_U8_c_U8_pc_(_5, _8);
  expr_10: mar_Nothing _10 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _9);
  expr_11: mar_U8 _11; _11.value = 10;
  expr_12: mar_U8 _12 = mar_divide_po_U8_c_U8_pc_(_0, _11);
  expr_13: mar_U8 _13; _13.value = 10;
  expr_14: mar_U8 _14 = mar_modulo_po_U8_c_U8_pc_(_12, _13);
  expr_15: mar_U8 _15; _15.value = 48;
  expr_16: mar_Char _16; _16.value = _15;
  expr_17: mar_U8 _17 = _16.value;
  expr_18: mar_U8 _18 = mar_add_po_U8_c_U8_pc_(_14, _17);
  expr_19: mar_Nothing _19 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _18);
  expr_20: mar_U8 _20; _20.value = 10;
  expr_21: mar_U8 _21 = mar_modulo_po_U8_c_U8_pc_(_0, _20);
  expr_22: mar_U8 _22; _22.value = 48;
  expr_23: mar_Char _23; _23.value = _22;
  expr_24: mar_U8 _24 = _23.value;
  expr_25: mar_U8 _25 = mar_add_po_U8_c_U8_pc_(_21, _24);
  expr_26: mar_Nothing _26 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _25);
  expr_27: // end
  return _26;
}

// dump[U8, StdoutWriter](Maybe[U8], StdoutWriter)
mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Maybe_bo_U8_bc__c_StdoutWriter_pc_(mar_Maybe_bo_U8_bc_ arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Maybe_bo_U8_bc_ _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: if (_0.variant == mar_some) goto expr_5;
  expr_3: if (_0.variant == mar_none) goto expr_26;
  expr_4: goto expr_2;
  expr_5: mar_U8 _5 = _0.as.mar_some;
  expr_6: mar_U8 _6; _6.value = 115;
  expr_7: mar_Char _7; _7.value = _6;
  expr_8: mar_Nothing _8 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_7, _1);
  expr_9: mar_U8 _9; _9.value = 111;
  expr_10: mar_Char _10; _10.value = _9;
  expr_11: mar_Nothing _11 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_10, _1);
  expr_12: mar_U8 _12; _12.value = 109;
  expr_13: mar_Char _13; _13.value = _12;
  expr_14: mar_Nothing _14 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_13, _1);
  expr_15: mar_U8 _15; _15.value = 101;
  expr_16: mar_Char _16; _16.value = _15;
  expr_17: mar_Nothing _17 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_16, _1);
  expr_18: mar_U8 _18; _18.value = 40;
  expr_19: mar_Char _19; _19.value = _18;
  expr_20: mar_Nothing _20 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_19, _1);
  expr_21: mar_Nothing _21 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_5, _1);
  expr_22: mar_U8 _22; _22.value = 41;
  expr_23: mar_Char _23; _23.value = _22;
  expr_24: mar_Nothing _24 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_23, _1);
  expr_25: goto expr_40;
  expr_26: mar_Nothing _26 = _0.as.mar_none;
  expr_27: mar_U8 _27; _27.value = 110;
  expr_28: mar_Char _28; _28.value = _27;
  expr_29: mar_Nothing _29 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_28, _1);
  expr_30: mar_U8 _30; _30.value = 111;
  expr_31: mar_Char _31; _31.value = _30;
  expr_32: mar_Nothing _32 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_31, _1);
  expr_33: mar_U8 _33; _33.value = 110;
  expr_34: mar_Char _34; _34.value = _33;
  expr_35: mar_Nothing _35 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_34, _1);
  expr_36: mar_U8 _36; _36.value = 101;
  expr_37: mar_Char _37; _37.value = _36;
  expr_38: mar_Nothing _38 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_37, _1);
  expr_39: goto expr_40;
  expr_40: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_U8 _0; _0.value = 2;
  expr_1: mar_Maybe_bo_U8_bc_ _1; _1.variant = mar_some; _1.as.mar_some = _0;
  expr_2: mar_Nothing _2 = mar_println_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(_1);
  expr_3: mar_U8 _3; _3.value = 72;
  expr_4: mar_Char _4; _4.value = _3;
  expr_5: mar_Nothing _5 = mar_print_bo_Char_bc__po_Char_pc_(_4);
  expr_6: mar_U8 _6; _6.value = 101;
  expr_7: mar_Char _7; _7.value = _6;
  expr_8: mar_Nothing _8 = mar_print_bo_Char_bc__po_Char_pc_(_7);
  expr_9: mar_U8 _9; _9.value = 108;
  expr_10: mar_Char _10; _10.value = _9;
  expr_11: mar_Nothing _11 = mar_print_bo_Char_bc__po_Char_pc_(_10);
  expr_12: mar_U8 _12; _12.value = 108;
  expr_13: mar_Char _13; _13.value = _12;
  expr_14: mar_Nothing _14 = mar_print_bo_Char_bc__po_Char_pc_(_13);
  expr_15: mar_U8 _15; _15.value = 111;
  expr_16: mar_Char _16; _16.value = _15;
  expr_17: mar_Nothing _17 = mar_print_bo_Char_bc__po_Char_pc_(_16);
  expr_18: mar_U8 _18; _18.value = 44;
  expr_19: mar_Char _19; _19.value = _18;
  expr_20: mar_Nothing _20 = mar_print_bo_Char_bc__po_Char_pc_(_19);
  expr_21: mar_U8 _21; _21.value = 32;
  expr_22: mar_Char _22; _22.value = _21;
  expr_23: mar_Nothing _23 = mar_print_bo_Char_bc__po_Char_pc_(_22);
  expr_24: mar_U8 _24; _24.value = 119;
  expr_25: mar_Char _25; _25.value = _24;
  expr_26: mar_Nothing _26 = mar_print_bo_Char_bc__po_Char_pc_(_25);
  expr_27: mar_U8 _27; _27.value = 111;
  expr_28: mar_Char _28; _28.value = _27;
  expr_29: mar_Nothing _29 = mar_print_bo_Char_bc__po_Char_pc_(_28);
  expr_30: mar_U8 _30; _30.value = 114;
  expr_31: mar_Char _31; _31.value = _30;
  expr_32: mar_Nothing _32 = mar_print_bo_Char_bc__po_Char_pc_(_31);
  expr_33: mar_U8 _33; _33.value = 108;
  expr_34: mar_Char _34; _34.value = _33;
  expr_35: mar_Nothing _35 = mar_print_bo_Char_bc__po_Char_pc_(_34);
  expr_36: mar_U8 _36; _36.value = 100;
  expr_37: mar_Char _37; _37.value = _36;
  expr_38: mar_Nothing _38 = mar_print_bo_Char_bc__po_Char_pc_(_37);
  expr_39: mar_U8 _39; _39.value = 33;
  expr_40: mar_Char _40; _40.value = _39;
  expr_41: mar_Nothing _41 = mar_print_bo_Char_bc__po_Char_pc_(_40);
  expr_42: mar_U8 _42; _42.value = 10;
  expr_43: mar_Char _43; _43.value = _42;
  expr_44: mar_Nothing _44 = mar_print_bo_Char_bc__po_Char_pc_(_43);
  expr_45: mar_I64 _45; _45.value = 3;
  expr_46: mar_I64 _46; _46.value = 4;
  expr_47: mar_I64 _47 = mar_add_po_I64_c_I64_pc_(_45, _46);
  expr_48: mar_I64 _48; _48.value = 4;
  expr_49: mar_I64 _49; _49.value = 2;
  expr_50: mar_I64 _50 = mar_divide_po_I64_c_I64_pc_(_48, _49);
  expr_51: mar_I64 _51 = mar_multiply_po_I64_c_I64_pc_(_47, _50);
  expr_52: mar_I64 _52; _52.value = 10;
  expr_53: mar_I64 _53 = mar_modulo_po_I64_c_I64_pc_(_51, _52);
  expr_54: return _53; mar_Never _54;
  expr_55: // end
}

// modulo(I64, I64)
mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
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

// print[Char](Char)
mar_Nothing mar_print_bo_Char_bc__po_Char_pc_(mar_Char arg0) {
  expr_0: mar_Char _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_0, _1);
  expr_3: // end
  return _2;
}

// print[Maybe[U8]](Maybe[U8])
mar_Nothing mar_print_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(mar_Maybe_bo_U8_bc_ arg0) {
  expr_0: mar_Maybe_bo_U8_bc_ _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_U8_c_StdoutWriter_bc__po_Maybe_bo_U8_bc__c_StdoutWriter_pc_(_0, _1);
  expr_3: // end
  return _2;
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// println[Maybe[U8]](Maybe[U8])
mar_Nothing mar_println_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(mar_Maybe_bo_U8_bc_ arg0) {
  expr_0: mar_Maybe_bo_U8_bc_ _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: // end
  return _4;
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
