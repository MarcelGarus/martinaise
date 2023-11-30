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
  } kind;
} mar_Bool;

// StdoutWriter
typedef struct {
} mar_StdoutWriter;

/// Function declarations

/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* dump[StdoutWriter](Bool, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(mar_Bool arg0, mar_StdoutWriter arg1);
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* add(I64, I64) */ mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* print[Bool](Bool) */ mar_Nothing mar_print_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* or(Bool, Bool) */ mar_Bool mar_or_po_Bool_c_Bool_pc_(mar_Bool arg0, mar_Bool arg1);
/* to_U8(I64) */ mar_U8 mar_to__U8_po_I64_pc_(mar_I64 arg0);
/* println[Bool](Bool) */ mar_Nothing mar_println_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0);
/* print[U8](U8) */ mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* write(StdoutWriter, U8) */ mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1);

/// Function definitions

// dump[StdoutWriter](U8, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1) {
  expr_0:
  mar_U8 _0 = arg0;
  expr_1:
  mar_StdoutWriter _1 = arg1;
  expr_2:
  mar_I64 _2;
  _2.value = 100;
  expr_3:
  mar_U8 _3 = mar_to__U8_po_I64_pc_(_2);
  expr_4:
  mar_U8 _4 = mar_divide_po_U8_c_U8_pc_(_0, _3);
  expr_5:
  mar_I64 _5;
  _5.value = 10;
  expr_6:
  mar_U8 _6 = mar_to__U8_po_I64_pc_(_5);
  expr_7:
  mar_U8 _7 = mar_modulo_po_U8_c_U8_pc_(_4, _6);
  expr_8:
  mar_I64 _8;
  _8.value = 48;
  expr_9:
  mar_U8 _9 = mar_to__U8_po_I64_pc_(_8);
  expr_10:
  mar_U8 _10 = mar_add_po_U8_c_U8_pc_(_7, _9);
  expr_11:
  mar_Nothing _11 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _10);
  expr_12:
  mar_I64 _12;
  _12.value = 10;
  expr_13:
  mar_U8 _13 = mar_to__U8_po_I64_pc_(_12);
  expr_14:
  mar_U8 _14 = mar_divide_po_U8_c_U8_pc_(_0, _13);
  expr_15:
  mar_I64 _15;
  _15.value = 10;
  expr_16:
  mar_U8 _16 = mar_to__U8_po_I64_pc_(_15);
  expr_17:
  mar_U8 _17 = mar_modulo_po_U8_c_U8_pc_(_14, _16);
  expr_18:
  mar_I64 _18;
  _18.value = 48;
  expr_19:
  mar_U8 _19 = mar_to__U8_po_I64_pc_(_18);
  expr_20:
  mar_U8 _20 = mar_add_po_U8_c_U8_pc_(_17, _19);
  expr_21:
  mar_Nothing _21 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _20);
  expr_22:
  mar_I64 _22;
  _22.value = 10;
  expr_23:
  mar_U8 _23 = mar_to__U8_po_I64_pc_(_22);
  expr_24:
  mar_U8 _24 = mar_modulo_po_U8_c_U8_pc_(_0, _23);
  expr_25:
  mar_I64 _25;
  _25.value = 48;
  expr_26:
  mar_U8 _26 = mar_to__U8_po_I64_pc_(_25);
  expr_27:
  mar_U8 _27 = mar_add_po_U8_c_U8_pc_(_24, _26);
  expr_28:
  mar_Nothing _28 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _27);
  expr_29:  return _28;
}

// divide(I64, I64)
mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// multiply(I64, I64)
mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value * arg1.value;
  return i;
}

// dump[StdoutWriter](Bool, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(mar_Bool arg0, mar_StdoutWriter arg1) {
  expr_0:
  mar_Bool _0 = arg0;
  expr_1:
  mar_StdoutWriter _1 = arg1;
  expr_2:
  if (_0.kind == mar_true) {
    goto expr_4;
  }
  expr_3:
  goto expr_17;
  expr_4:
  mar_I64 _4;
  _4.value = 116;
  expr_5:
  mar_U8 _5 = mar_to__U8_po_I64_pc_(_4);
  expr_6:
  mar_Nothing _6 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _5);
  expr_7:
  mar_I64 _7;
  _7.value = 114;
  expr_8:
  mar_U8 _8 = mar_to__U8_po_I64_pc_(_7);
  expr_9:
  mar_Nothing _9 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _8);
  expr_10:
  mar_I64 _10;
  _10.value = 117;
  expr_11:
  mar_U8 _11 = mar_to__U8_po_I64_pc_(_10);
  expr_12:
  mar_Nothing _12 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _11);
  expr_13:
  mar_I64 _13;
  _13.value = 101;
  expr_14:
  mar_U8 _14 = mar_to__U8_po_I64_pc_(_13);
  expr_15:
  mar_Nothing _15 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _14);
  expr_16:
  goto expr_33;
  expr_17:
  mar_I64 _17;
  _17.value = 102;
  expr_18:
  mar_U8 _18 = mar_to__U8_po_I64_pc_(_17);
  expr_19:
  mar_Nothing _19 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _18);
  expr_20:
  mar_I64 _20;
  _20.value = 97;
  expr_21:
  mar_U8 _21 = mar_to__U8_po_I64_pc_(_20);
  expr_22:
  mar_Nothing _22 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _21);
  expr_23:
  mar_I64 _23;
  _23.value = 108;
  expr_24:
  mar_U8 _24 = mar_to__U8_po_I64_pc_(_23);
  expr_25:
  mar_Nothing _25 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _24);
  expr_26:
  mar_I64 _26;
  _26.value = 115;
  expr_27:
  mar_U8 _27 = mar_to__U8_po_I64_pc_(_26);
  expr_28:
  mar_Nothing _28 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _27);
  expr_29:
  mar_I64 _29;
  _29.value = 101;
  expr_30:
  mar_U8 _30 = mar_to__U8_po_I64_pc_(_29);
  expr_31:
  mar_Nothing _31 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _30);
  expr_32:
  goto expr_33;
  expr_33:}

// add(U8, U8)
mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// modulo(I64, I64)
mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// divide(U8, U8)
mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// add(I64, I64)
mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1) {
  mar_I64 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// print[Bool](Bool)
mar_Nothing mar_print_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0) {
  expr_0:
  mar_Bool _0 = arg0;
  expr_1:
  mar_StdoutWriter _1;
  expr_2:
  mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_Bool_c_StdoutWriter_pc_(_0, _1);
  expr_3:  return _2;
}

// modulo(U8, U8)
mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0:
  mar_Bool _0;
  _0.kind = mar_false;
  expr_1:
  mar_Bool _1;
  _1.kind = mar_true;
  expr_2:
  mar_Bool _2 = mar_or_po_Bool_c_Bool_pc_(_0, _1);
  expr_3:
  mar_Nothing _3 = mar_println_bo_Bool_bc__po_Bool_pc_(_2);
  expr_4:
  mar_I64 _4;
  _4.value = 72;
  expr_5:
  mar_U8 _5 = mar_to__U8_po_I64_pc_(_4);
  expr_6:
  mar_Nothing _6 = mar_print_bo_U8_bc__po_U8_pc_(_5);
  expr_7:
  mar_I64 _7;
  _7.value = 3;
  expr_8:
  mar_I64 _8;
  _8.value = 4;
  expr_9:
  mar_I64 _9 = mar_add_po_I64_c_I64_pc_(_7, _8);
  expr_10:
  mar_I64 _10;
  _10.value = 4;
  expr_11:
  mar_I64 _11;
  _11.value = 2;
  expr_12:
  mar_I64 _12 = mar_divide_po_I64_c_I64_pc_(_10, _11);
  expr_13:
  mar_I64 _13 = mar_multiply_po_I64_c_I64_pc_(_9, _12);
  expr_14:
  mar_I64 _14;
  _14.value = 10;
  expr_15:
  mar_I64 _15 = mar_modulo_po_I64_c_I64_pc_(_13, _14);
  expr_16:
  return _15;
  mar_Never _16;
  expr_17:}

// or(Bool, Bool)
mar_Bool mar_or_po_Bool_c_Bool_pc_(mar_Bool arg0, mar_Bool arg1) {
  expr_0:
  mar_Bool _0 = arg0;
  expr_1:
  mar_Bool _1 = arg1;
  expr_2:
  if (_0.kind == mar_true) {
    goto expr_4;
  }
  expr_3:
  goto expr_7;
  expr_4:
  mar_Bool _4;
  _4.kind = mar_true;
  expr_5:
  return _4;
  mar_Never _5;
  expr_6:
  goto expr_7;
  expr_7:
  return _1;
  mar_Never _7;
  expr_8:}

// to_U8(I64)
mar_U8 mar_to__U8_po_I64_pc_(mar_I64 arg0) {
  mar_U8 i;
  i.value = arg0.value;
  return i;
}

// println[Bool](Bool)
mar_Nothing mar_println_bo_Bool_bc__po_Bool_pc_(mar_Bool arg0) {
  expr_0:
  mar_Bool _0 = arg0;
  expr_1:
  mar_Nothing _1 = mar_print_bo_Bool_bc__po_Bool_pc_(_0);
  expr_2:
  mar_StdoutWriter _2;
  expr_3:
  mar_I64 _3;
  _3.value = 10;
  expr_4:
  mar_U8 _4 = mar_to__U8_po_I64_pc_(_3);
  expr_5:
  mar_Nothing _5 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _4);
  expr_6:  return _5;
}

// print[U8](U8)
mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0:
  mar_U8 _0 = arg0;
  expr_1:
  mar_StdoutWriter _1;
  expr_2:
  mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_0, _1);
  expr_3:  return _2;
}

// write(StdoutWriter, U8)
mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1) {
  expr_0:
  mar_StdoutWriter _0 = arg0;
  expr_1:
  mar_U8 _1 = arg1;
  expr_2:
  mar_Nothing _2 = mar_print__to__stdout_po_U8_pc_(_1);
  expr_3:  return _2;
}

// actual main function
int main() {
  return mar_main_po__pc_().value;
}
