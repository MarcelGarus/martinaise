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

/// Function declarations

/* add(I64, I64) */ mar_I64 mar_add_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* divide(I64, I64) */ mar_I64 mar_divide_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* dump[U8, StdoutWriter](Maybe[U8], StdoutWriter) */ mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Maybe_bo_U8_bc__c_StdoutWriter_pc_(mar_Maybe_bo_U8_bc_ arg0, mar_StdoutWriter arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* modulo(I64, I64) */ mar_I64 mar_modulo_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* multiply(I64, I64) */ mar_I64 mar_multiply_po_I64_c_I64_pc_(mar_I64 arg0, mar_I64 arg1);
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

// dump[StdoutWriter](U8, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U8 _2; _2.value = 100;
  expr_3: mar_U8 _3 = mar_divide_po_U8_c_U8_pc_(_0, _2);
  expr_4: mar_U8 _4; _4.value = 10;
  expr_5: mar_U8 _5 = mar_modulo_po_U8_c_U8_pc_(_3, _4);
  expr_6: mar_U8 _6; _6.value = 48;
  expr_7: mar_U8 _7 = mar_add_po_U8_c_U8_pc_(_5, _6);
  expr_8: mar_Nothing _8 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _7);
  expr_9: mar_U8 _9; _9.value = 10;
  expr_10: mar_U8 _10 = mar_divide_po_U8_c_U8_pc_(_0, _9);
  expr_11: mar_U8 _11; _11.value = 10;
  expr_12: mar_U8 _12 = mar_modulo_po_U8_c_U8_pc_(_10, _11);
  expr_13: mar_U8 _13; _13.value = 48;
  expr_14: mar_U8 _14 = mar_add_po_U8_c_U8_pc_(_12, _13);
  expr_15: mar_Nothing _15 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _14);
  expr_16: mar_U8 _16; _16.value = 10;
  expr_17: mar_U8 _17 = mar_modulo_po_U8_c_U8_pc_(_0, _16);
  expr_18: mar_U8 _18; _18.value = 48;
  expr_19: mar_U8 _19 = mar_add_po_U8_c_U8_pc_(_17, _18);
  expr_20: mar_Nothing _20 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _19);
  expr_21: // end
  return _20;
}

// dump[U8, StdoutWriter](Maybe[U8], StdoutWriter)
mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Maybe_bo_U8_bc__c_StdoutWriter_pc_(mar_Maybe_bo_U8_bc_ arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Maybe_bo_U8_bc_ _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: if (_0.variant == mar_some) goto expr_5;
  expr_3: if (_0.variant == mar_none) goto expr_20;
  expr_4: goto expr_2;
  expr_5: mar_U8 _5 = _0.as.mar_some;
  expr_6: mar_U8 _6; _6.value = 115;
  expr_7: mar_Nothing _7 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _6);
  expr_8: mar_U8 _8; _8.value = 111;
  expr_9: mar_Nothing _9 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _8);
  expr_10: mar_U8 _10; _10.value = 109;
  expr_11: mar_Nothing _11 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _10);
  expr_12: mar_U8 _12; _12.value = 101;
  expr_13: mar_Nothing _13 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _12);
  expr_14: mar_U8 _14; _14.value = 40;
  expr_15: mar_Nothing _15 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _14);
  expr_16: mar_Nothing _16 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_5, _1);
  expr_17: mar_U8 _17; _17.value = 41;
  expr_18: mar_Nothing _18 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _17);
  expr_19: goto expr_30;
  expr_20: mar_Nothing _20 = _0.as.mar_none;
  expr_21: mar_U8 _21; _21.value = 110;
  expr_22: mar_Nothing _22 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _21);
  expr_23: mar_U8 _23; _23.value = 111;
  expr_24: mar_Nothing _24 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _23);
  expr_25: mar_U8 _25; _25.value = 110;
  expr_26: mar_Nothing _26 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _25);
  expr_27: mar_U8 _27; _27.value = 101;
  expr_28: mar_Nothing _28 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _27);
  expr_29: goto expr_30;
  expr_30: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_U8 _0; _0.value = 2;
  expr_1: mar_Maybe_bo_U8_bc_ _1; _1.variant = mar_some; _1.as.mar_some = _0;
  expr_2: mar_Nothing _2 = mar_println_bo_Maybe_bo_U8_bc__bc__po_Maybe_bo_U8_bc__pc_(_1);
  expr_3: mar_I64 _3; _3.value = 0;
  expr_4: return _3; mar_Never _4;
  expr_5: mar_I64 _5; _5.value = 3;
  expr_6: mar_I64 _6; _6.value = 4;
  expr_7: mar_I64 _7 = mar_add_po_I64_c_I64_pc_(_5, _6);
  expr_8: mar_I64 _8; _8.value = 4;
  expr_9: mar_I64 _9; _9.value = 2;
  expr_10: mar_I64 _10 = mar_divide_po_I64_c_I64_pc_(_8, _9);
  expr_11: mar_I64 _11 = mar_multiply_po_I64_c_I64_pc_(_7, _10);
  expr_12: mar_I64 _12; _12.value = 10;
  expr_13: mar_I64 _13 = mar_modulo_po_I64_c_I64_pc_(_11, _12);
  expr_14: return _13; mar_Never _14;
  expr_15: // end
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
