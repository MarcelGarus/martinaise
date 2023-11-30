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
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* print[U8](U8) */ mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[U8](U8) */ mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
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

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_U8 _0;
  expr_1: mar_Nothing _1;
  expr_2: mar_Bool _2; _2.variant = mar_false; _2.as.mar_false = _1;
  expr_3: if (_2.variant == mar_true) goto expr_6;
  expr_4: if (_2.variant == mar_false) goto expr_10;
  expr_5: goto expr_3;
  expr_6: mar_Nothing _6 = _2.as.mar_true;
  expr_7: mar_U8 _7; _7.value = 3;
  expr_8: _0 = _7; mar_Nothing _8;
  expr_9: goto expr_14;
  expr_10: mar_Nothing _10 = _2.as.mar_false;
  expr_11: mar_U8 _11; _11.value = 4;
  expr_12: _0 = _11; mar_Nothing _12;
  expr_13: goto expr_14;
  expr_14: mar_Nothing _14 = mar_println_bo_U8_bc__po_U8_pc_(_0);
  expr_15: mar_I64 _15; _15.value = 3;
  expr_16: mar_I64 _16; _16.value = 4;
  expr_17: mar_I64 _17 = mar_add_po_I64_c_I64_pc_(_15, _16);
  expr_18: mar_I64 _18; _18.value = 4;
  expr_19: mar_I64 _19; _19.value = 2;
  expr_20: mar_I64 _20 = mar_divide_po_I64_c_I64_pc_(_18, _19);
  expr_21: mar_I64 _21 = mar_multiply_po_I64_c_I64_pc_(_17, _20);
  expr_22: mar_I64 _22; _22.value = 10;
  expr_23: mar_I64 _23 = mar_modulo_po_I64_c_I64_pc_(_21, _22);
  expr_24: return _23; mar_Never _24;
  expr_25: // end
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

// println[U8](U8)
mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_U8_bc__po_U8_pc_(_0);
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
