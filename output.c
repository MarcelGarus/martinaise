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

// Char
typedef struct {
  mar_U8 value;
} mar_Char;

/// Function declarations

/* add(I64, I64) */ mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* dump[StdoutWriter](Bool, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(mar_Bool arg0, mar_StdoutWriter arg1);
/* dump[StdoutWriter](Char, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(mar_Char arg0, mar_StdoutWriter arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* print[Bool](Bool) */ mar_Nothing mar_print_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[Bool](Bool) */ mar_Nothing mar_println_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0);
/* write(StdoutWriter, U8) */ mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1);

/// Function definitions

// add(I64, I64)
mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// divide(I64, I64)
mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// dump[StdoutWriter](Bool, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(mar_Bool arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Bool _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: if (_0.variant == mar_true) goto expr_4;
  expr_3: goto expr_17;
  expr_4: mar_U8 _4; _4.value = 116;
  expr_5: mar_Char _5; _5.value = _4;
  expr_6: mar_Nothing _6 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_5, _1);
  expr_7: mar_U8 _7; _7.value = 114;
  expr_8: mar_Char _8; _8.value = _7;
  expr_9: mar_Nothing _9 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_8, _1);
  expr_10: mar_U8 _10; _10.value = 117;
  expr_11: mar_Char _11; _11.value = _10;
  expr_12: mar_Nothing _12 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_11, _1);
  expr_13: mar_U8 _13; _13.value = 101;
  expr_14: mar_Char _14; _14.value = _13;
  expr_15: mar_Nothing _15 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_14, _1);
  expr_16: goto expr_33;
  expr_17: mar_U8 _17; _17.value = 102;
  expr_18: mar_Char _18; _18.value = _17;
  expr_19: mar_Nothing _19 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_18, _1);
  expr_20: mar_U8 _20; _20.value = 97;
  expr_21: mar_Char _21; _21.value = _20;
  expr_22: mar_Nothing _22 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_21, _1);
  expr_23: mar_U8 _23; _23.value = 108;
  expr_24: mar_Char _24; _24.value = _23;
  expr_25: mar_Nothing _25 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_24, _1);
  expr_26: mar_U8 _26; _26.value = 115;
  expr_27: mar_Char _27; _27.value = _26;
  expr_28: mar_Nothing _28 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_27, _1);
  expr_29: mar_U8 _29; _29.value = 101;
  expr_30: mar_Char _30; _30.value = _29;
  expr_31: mar_Nothing _31 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_30, _1);
  expr_32: goto expr_33;
  expr_33: // end
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

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_Nothing _0;
  expr_1: mar_Bool _1; _1.variant = mar_true; _1.as.mar_true = _0;
  expr_2: if (_1.variant == mar_true) goto expr_5;
  expr_3: if (_1.variant == mar_false) goto expr_8;
  expr_4: goto expr_2;
  expr_5: mar_Nothing _5 = _1.as.mar_true;
  expr_6: mar_U8 _6; _6.value = 3;
  expr_7: goto expr_11;
  expr_8: mar_Nothing _8 = _1.as.mar_false;
  expr_9: mar_U8 _9; _9.value = 4;
  expr_10: goto expr_11;
  expr_11: mar_Nothing _11 = mar_println_bo_Bool_bc__po_Bool_pc_(_1);
  expr_12: mar_I64 _12; _12.value = 3;
  expr_13: mar_I64 _13; _13.value = 4;
  expr_14: mar_I64 _14 = mar_add_po_I64_c_I64_pc_(_12, _13);
  expr_15: mar_I64 _15; _15.value = 4;
  expr_16: mar_I64 _16; _16.value = 2;
  expr_17: mar_I64 _17 = mar_divide_po_I64_c_I64_pc_(_15, _16);
  expr_18: mar_I64 _18 = mar_multiply_po_I64_c_I64_pc_(_14, _17);
  expr_19: mar_I64 _19; _19.value = 10;
  expr_20: mar_I64 _20 = mar_modulo_po_I64_c_I64_pc_(_18, _19);
  expr_21: return _20; mar_Never _21;
  expr_22: // end
}

// modulo(I64, I64)
mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// multiply(I64, I64)
mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value * arg1.value;
  return i;
}

// print[Bool](Bool)
mar_Nothing mar_print_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0) {
  expr_0: mar_Bool _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(_0, _1);
  expr_3: // end
  return _2;
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// println[Bool](Bool)
mar_Nothing mar_println_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0) {
  expr_0: mar_Bool _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_Bool_bc__po_Bool_pc_(_0);
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
