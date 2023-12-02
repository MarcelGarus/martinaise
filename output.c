// This file is a compiler target.
#include <stdio.h>

#include <stdint.h>

#include <stdlib.h>

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

// &[U8]
typedef struct {
  mar_U8* pointer;
} mar__a__bo_U8_bc_;

// Vec[U8]
typedef struct {
  mar__a__bo_U8_bc_ mar_data;
  mar_U64 mar_len;
  mar_U64 mar_capacity;
} mar_Vec_bo_U8_bc_;

// &[Vec[U8]]
typedef struct {
  mar_Vec_bo_U8_bc_* pointer;
} mar__a__bo_Vec_bo_U8_bc__bc_;

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

// StdoutWriter
typedef struct {
} mar_StdoutWriter;

// Char
typedef struct {
  mar_U8 mar_value;
} mar_Char;

/// Function declarations

/* add(U64, U64) */ mar_U64 mar_add_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* add[U8](&[U8], U64) */ mar__a__bo_U8_bc_ mar_add_bo_U8_bc__po__a__bo_U8_bc__c_U64_pc_(mar__a__bo_U8_bc_ arg0, mar_U64 arg1);
/* compare_to(U64, U64) */ mar_Ordering mar_compare__to_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* compare_to(U8, U8) */ mar_Ordering mar_compare__to_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* digit_to_char(U8) */ mar_U8 mar_digit__to__char_po_U8_pc_(mar_U8 arg0);
/* divide(U64, U64) */ mar_U64 mar_divide_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* dump[StdoutWriter](Char, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(mar_Char arg0, mar_StdoutWriter arg1);
/* dump[StdoutWriter](U64, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1);
/* dump[StdoutWriter](U64, U64, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_U64 arg1, mar_StdoutWriter arg2);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* dump_address[StdoutWriter](U64, StdoutWriter) */ mar_Nothing mar_dump__address_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1);
/* equals(U64, U64) */ mar_Bool mar_equals_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* get[U8](Vec[U8], U64) */ mar_U8 mar_get_bo_U8_bc__po_Vec_bo_U8_bc__c_U64_pc_(mar_Vec_bo_U8_bc_ arg0, mar_U64 arg1);
/* identity[&[Vec[U8]]](&[Vec[U8]]) */ mar__a__bo_Vec_bo_U8_bc__bc_ mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0);
/* is_equal(Ordering) */ mar_Bool mar_is__equal_po_Ordering_pc_(mar_Ordering arg0);
/* is_greater(Ordering) */ mar_Bool mar_is__greater_po_Ordering_pc_(mar_Ordering arg0);
/* is_greater_than(U8, U8) */ mar_Bool mar_is__greater__than_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* is_less(Ordering) */ mar_Bool mar_is__less_po_Ordering_pc_(mar_Ordering arg0);
/* is_less_than(U64, U64) */ mar_Bool mar_is__less__than_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* main() */ mar_I64 mar_main_po__pc_();
/* malloc(U64) */ mar_U64 mar_malloc_po_U64_pc_(mar_U64 arg0);
/* modulo(U64, U64) */ mar_U64 mar_modulo_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* multiply(U64, U64) */ mar_U64 mar_multiply_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* print[Char](Char) */ mar_Nothing mar_print_bo_Char_bc__po_Char_pc_(mar_Char arg0);
/* print[U8](U8) */ mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[Char](Char) */ mar_Nothing mar_println_bo_Char_bc__po_Char_pc_(mar_Char arg0);
/* println[U8](U8) */ mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* push[U8](&[Vec[U8]], U8) */ mar_Nothing mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0, mar_U8 arg1);
/* size_of_type[U8]() */ mar_U64 mar_size__of__type_bo_U8_bc__po__pc_();
/* subtract(U8, U8) */ mar_U8 mar_subtract_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* to_U64(U8) */ mar_U64 mar_to__U64_po_U8_pc_(mar_U8 arg0);
/* to_U8(U64) */ mar_U8 mar_to__U8_po_U64_pc_(mar_U64 arg0);
/* to_address[U8](&[U8]) */ mar_U64 mar_to__address_bo_U8_bc__po__a__bo_U8_bc__pc_(mar__a__bo_U8_bc_ arg0);
/* to_reference[U8](U64) */ mar__a__bo_U8_bc_ mar_to__reference_bo_U8_bc__po_U64_pc_(mar_U64 arg0);
/* vec[U8]() */ mar_Vec_bo_U8_bc_ mar_vec_bo_U8_bc__po__pc_();
/* write(StdoutWriter, U8) */ mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1);

/// Function definitions

// add(U64, U64)
mar_U64 mar_add_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// add(U8, U8)
mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// add[U8](&[U8], U64)
mar__a__bo_U8_bc_ mar_add_bo_U8_bc__po__a__bo_U8_bc__c_U64_pc_(mar__a__bo_U8_bc_ arg0, mar_U64 arg1) {
  expr_0: mar__a__bo_U8_bc_ _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar_U64 _2 = mar_to__address_bo_U8_bc__po__a__bo_U8_bc__pc_(_0);
  expr_3: mar_U64 _3 = mar_size__of__type_bo_U8_bc__po__pc_();
  expr_4: mar_U64 _4 = mar_multiply_po_U64_c_U64_pc_(_1, _3);
  expr_5: mar_U64 _5 = mar_add_po_U64_c_U64_pc_(_2, _4);
  expr_6: mar__a__bo_U8_bc_ _6 = mar_to__reference_bo_U8_bc__po_U64_pc_(_5);
  expr_7: return _6; mar_Never _7;
  expr_8: // end
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

// digit_to_char(U8)
mar_U8 mar_digit__to__char_po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_U8 _1;
  expr_2: mar_U8 _2; _2.value = 9ULL;
  expr_3: mar_Bool _3 = mar_is__greater__than_po_U8_c_U8_pc_(_0, _2);
  expr_4: if (_3.variant == mar_true) goto expr_6; mar_Never _4;
  expr_5: goto expr_14; mar_Never _5;
  expr_6: mar_U8 _6; _6.value = 10ULL;
  expr_7: mar_U8 _7 = mar_subtract_po_U8_c_U8_pc_(_0, _6);
  expr_8: mar_U8 _8; _8.value = 97ULL;
  expr_9: mar_Char _9; _9.mar_value = _8;
  expr_10: mar_U8 _10 = _9.mar_value;
  expr_11: mar_U8 _11 = mar_add_po_U8_c_U8_pc_(_7, _10);
  expr_12: _1 = _11; mar_Nothing _12;
  expr_13: goto expr_20; mar_Never _13;
  expr_14: mar_U8 _14; _14.value = 48ULL;
  expr_15: mar_Char _15; _15.mar_value = _14;
  expr_16: mar_U8 _16 = _15.mar_value;
  expr_17: mar_U8 _17 = mar_add_po_U8_c_U8_pc_(_0, _16);
  expr_18: _1 = _17; mar_Nothing _18;
  expr_19: goto expr_20; mar_Never _19;
  expr_20: return _1; mar_Never _20;
  expr_21: // end
}

// divide(U64, U64)
mar_U64 mar_divide_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value / arg1.value;
  return i;
}

// dump[StdoutWriter](Char, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(mar_Char arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Char _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U8 _2 = _0.mar_value;
  expr_3: mar_Nothing _3 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// dump[StdoutWriter](U64, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U64 _2; _2.value = 10ULL;
  expr_3: mar_Nothing _3 = mar_dump_bo_StdoutWriter_bc__po_U64_c_U64_c_StdoutWriter_pc_(_0, _2, _1);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// dump[StdoutWriter](U64, U64, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U64_c_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_U64 arg1, mar_StdoutWriter arg2) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar_StdoutWriter _2 = arg2;
  expr_3: mar_U64 _3 = _1;  expr_4: mar_Nothing _4;
  expr_5: mar_Never _5;
  expr_6: mar_U64 _6 = mar_divide_po_U64_c_U64_pc_(_0, _3);
  expr_7: mar_Bool _7 = mar_is__less__than_po_U64_c_U64_pc_(_6, _1);
  expr_8: if (_7.variant == mar_true) goto expr_10; mar_Never _8;
  expr_9: goto expr_15; mar_Never _9;
  expr_10: mar_Nothing _10;
  expr_11: _4 = _10; mar_Nothing _11;
  expr_12: goto expr_18; mar_Never _12;
  expr_13: _5 = _12; mar_Nothing _13;
  expr_14: goto expr_15; mar_Never _14;
  expr_15: mar_U64 _15 = mar_multiply_po_U64_c_U64_pc_(_3, _1);
  expr_16: _3 = _15; mar_Nothing _16;
  expr_17: goto expr_5; mar_Never _17;
  expr_18: mar_Nothing _18;
  expr_19: mar_U64 _19 = mar_divide_po_U64_c_U64_pc_(_0, _3);
  expr_20: mar_U64 _20 = mar_modulo_po_U64_c_U64_pc_(_19, _1);
  expr_21: mar_U8 _21 = mar_to__U8_po_U64_pc_(_20);
  expr_22: mar_U8 _22 = mar_digit__to__char_po_U8_pc_(_21);
  expr_23: mar_Nothing _23 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _22);
  expr_24: mar_Never _24;
  expr_25: mar_U64 _25; _25.value = 1ULL;
  expr_26: mar_Bool _26 = mar_equals_po_U64_c_U64_pc_(_3, _25);
  expr_27: if (_26.variant == mar_true) goto expr_29; mar_Never _27;
  expr_28: goto expr_34; mar_Never _28;
  expr_29: mar_Nothing _29;
  expr_30: _18 = _29; mar_Nothing _30;
  expr_31: goto expr_37; mar_Never _31;
  expr_32: _24 = _31; mar_Nothing _32;
  expr_33: goto expr_34; mar_Never _33;
  expr_34: mar_U64 _34 = mar_divide_po_U64_c_U64_pc_(_3, _1);
  expr_35: _3 = _34; mar_Nothing _35;
  expr_36: goto expr_19; mar_Never _36;
  expr_37: return _18; mar_Never _37;
  expr_38: // end
}

// dump[StdoutWriter](U8, StdoutWriter)
mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U64 _2 = mar_to__U64_po_U8_pc_(_0);
  expr_3: mar_Nothing _3 = mar_dump_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(_2, _1);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// dump_address[StdoutWriter](U64, StdoutWriter)
mar_Nothing mar_dump__address_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(mar_U64 arg0, mar_StdoutWriter arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U64 _2; _2.value = 1152921504606846976ULL;
  expr_3: mar_U64 _3 = _2;  expr_4: mar_U8 _4; _4.value = 48ULL;
  expr_5: mar_Char _5; _5.mar_value = _4;
  expr_6: mar_Nothing _6 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_5, _1);
  expr_7: mar_U8 _7; _7.value = 120ULL;
  expr_8: mar_Char _8; _8.mar_value = _7;
  expr_9: mar_Nothing _9 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_8, _1);
  expr_10: mar_Nothing _10;
  expr_11: mar_U64 _11 = mar_divide_po_U64_c_U64_pc_(_0, _3);
  expr_12: mar_U64 _12; _12.value = 16ULL;
  expr_13: mar_U64 _13 = mar_modulo_po_U64_c_U64_pc_(_11, _12);
  expr_14: mar_U8 _14 = mar_to__U8_po_U64_pc_(_13);
  expr_15: mar_U8 _15 = mar_digit__to__char_po_U8_pc_(_14);
  expr_16: mar_Nothing _16 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _15);
  expr_17: mar_Never _17;
  expr_18: mar_U64 _18; _18.value = 1ULL;
  expr_19: mar_Bool _19 = mar_equals_po_U64_c_U64_pc_(_3, _18);
  expr_20: if (_19.variant == mar_true) goto expr_22; mar_Never _20;
  expr_21: goto expr_27; mar_Never _21;
  expr_22: mar_Nothing _22;
  expr_23: _10 = _22; mar_Nothing _23;
  expr_24: goto expr_31; mar_Never _24;
  expr_25: _17 = _24; mar_Nothing _25;
  expr_26: goto expr_27; mar_Never _26;
  expr_27: mar_U64 _27; _27.value = 16ULL;
  expr_28: mar_U64 _28 = mar_divide_po_U64_c_U64_pc_(_3, _27);
  expr_29: _3 = _28; mar_Nothing _29;
  expr_30: goto expr_11; mar_Never _30;
  expr_31: return _10; mar_Never _31;
  expr_32: // end
}

// equals(U64, U64)
mar_Bool mar_equals_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U64_c_U64_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__equal_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// get[U8](Vec[U8], U64)
mar_U8 mar_get_bo_U8_bc__po_Vec_bo_U8_bc__c_U64_pc_(mar_Vec_bo_U8_bc_ arg0, mar_U64 arg1) {
  expr_0: mar_Vec_bo_U8_bc_ _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar__a__bo_U8_bc_ _2 = _0.mar_data;
  expr_3: mar__a__bo_U8_bc_ _3 = mar_add_bo_U8_bc__po__a__bo_U8_bc__c_U64_pc_(_2, _1);
  expr_4: mar_U8 _4 = *_3.pointer;
  expr_5: return _4; mar_Never _5;
  expr_6: // end
}

// identity[&[Vec[U8]]](&[Vec[U8]])
mar__a__bo_Vec_bo_U8_bc__bc_ mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0) {
  expr_0: mar__a__bo_Vec_bo_U8_bc__bc_ _0 = arg0;
  expr_1: return _0; mar_Never _1;
  expr_2: // end
}

// is_equal(Ordering)
mar_Bool mar_is__equal_po_Ordering_pc_(mar_Ordering arg0) {
  expr_0: mar_Ordering _0 = arg0;
  expr_1: mar_Bool _1;
  expr_2: if (_0.variant == mar_less) goto expr_6; mar_Never _2;
  expr_3: if (_0.variant == mar_equal) goto expr_11; mar_Never _3;
  expr_4: if (_0.variant == mar_greater) goto expr_16; mar_Never _4;
  expr_5: goto expr_2; mar_Never _5;
  expr_6: mar_Nothing _6 = _0.as.mar_less;
  expr_7: mar_Nothing _7;
  expr_8: mar_Bool _8; _8.variant = mar_false; _8.as.mar_false = _7;
  expr_9: _1 = _8; mar_Nothing _9;
  expr_10: goto expr_21; mar_Never _10;
  expr_11: mar_Nothing _11 = _0.as.mar_equal;
  expr_12: mar_Nothing _12;
  expr_13: mar_Bool _13; _13.variant = mar_true; _13.as.mar_true = _12;
  expr_14: _1 = _13; mar_Nothing _14;
  expr_15: goto expr_21; mar_Never _15;
  expr_16: mar_Nothing _16 = _0.as.mar_greater;
  expr_17: mar_Nothing _17;
  expr_18: mar_Bool _18; _18.variant = mar_false; _18.as.mar_false = _17;
  expr_19: _1 = _18; mar_Nothing _19;
  expr_20: goto expr_21; mar_Never _20;
  expr_21: return _1; mar_Never _21;
  expr_22: // end
}

// is_greater(Ordering)
mar_Bool mar_is__greater_po_Ordering_pc_(mar_Ordering arg0) {
  expr_0: mar_Ordering _0 = arg0;
  expr_1: mar_Bool _1;
  expr_2: if (_0.variant == mar_less) goto expr_6; mar_Never _2;
  expr_3: if (_0.variant == mar_equal) goto expr_11; mar_Never _3;
  expr_4: if (_0.variant == mar_greater) goto expr_16; mar_Never _4;
  expr_5: goto expr_2; mar_Never _5;
  expr_6: mar_Nothing _6 = _0.as.mar_less;
  expr_7: mar_Nothing _7;
  expr_8: mar_Bool _8; _8.variant = mar_false; _8.as.mar_false = _7;
  expr_9: _1 = _8; mar_Nothing _9;
  expr_10: goto expr_21; mar_Never _10;
  expr_11: mar_Nothing _11 = _0.as.mar_equal;
  expr_12: mar_Nothing _12;
  expr_13: mar_Bool _13; _13.variant = mar_false; _13.as.mar_false = _12;
  expr_14: _1 = _13; mar_Nothing _14;
  expr_15: goto expr_21; mar_Never _15;
  expr_16: mar_Nothing _16 = _0.as.mar_greater;
  expr_17: mar_Nothing _17;
  expr_18: mar_Bool _18; _18.variant = mar_true; _18.as.mar_true = _17;
  expr_19: _1 = _18; mar_Nothing _19;
  expr_20: goto expr_21; mar_Never _20;
  expr_21: return _1; mar_Never _21;
  expr_22: // end
}

// is_greater_than(U8, U8)
mar_Bool mar_is__greater__than_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U8_c_U8_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__greater_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// is_less(Ordering)
mar_Bool mar_is__less_po_Ordering_pc_(mar_Ordering arg0) {
  expr_0: mar_Ordering _0 = arg0;
  expr_1: mar_Bool _1;
  expr_2: if (_0.variant == mar_less) goto expr_6; mar_Never _2;
  expr_3: if (_0.variant == mar_equal) goto expr_11; mar_Never _3;
  expr_4: if (_0.variant == mar_greater) goto expr_16; mar_Never _4;
  expr_5: goto expr_2; mar_Never _5;
  expr_6: mar_Nothing _6 = _0.as.mar_less;
  expr_7: mar_Nothing _7;
  expr_8: mar_Bool _8; _8.variant = mar_true; _8.as.mar_true = _7;
  expr_9: _1 = _8; mar_Nothing _9;
  expr_10: goto expr_21; mar_Never _10;
  expr_11: mar_Nothing _11 = _0.as.mar_equal;
  expr_12: mar_Nothing _12;
  expr_13: mar_Bool _13; _13.variant = mar_false; _13.as.mar_false = _12;
  expr_14: _1 = _13; mar_Nothing _14;
  expr_15: goto expr_21; mar_Never _15;
  expr_16: mar_Nothing _16 = _0.as.mar_greater;
  expr_17: mar_Nothing _17;
  expr_18: mar_Bool _18; _18.variant = mar_false; _18.as.mar_false = _17;
  expr_19: _1 = _18; mar_Nothing _19;
  expr_20: goto expr_21; mar_Never _20;
  expr_21: return _1; mar_Never _21;
  expr_22: // end
}

// is_less_than(U64, U64)
mar_Bool mar_is__less__than_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  expr_0: mar_U64 _0 = arg0;
  expr_1: mar_U64 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U64_c_U64_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__less_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_Vec_bo_U8_bc_ _0 = mar_vec_bo_U8_bc__po__pc_();
  expr_1: mar_Vec_bo_U8_bc_ _1 = _0;  expr_2: mar__a__bo_Vec_bo_U8_bc__bc_ _2; _2.pointer = &_1;
  expr_3: mar__a__bo_Vec_bo_U8_bc__bc_ _3 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_2);
  expr_4: mar_U8 _4; _4.value = 1ULL;
  expr_5: mar_Nothing _5 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_3, _4);
  expr_6: mar__a__bo_Vec_bo_U8_bc__bc_ _6; _6.pointer = &_1;
  expr_7: mar__a__bo_Vec_bo_U8_bc__bc_ _7 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_6);
  expr_8: mar_U8 _8; _8.value = 2ULL;
  expr_9: mar_Nothing _9 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_7, _8);
  expr_10: mar__a__bo_Vec_bo_U8_bc__bc_ _10; _10.pointer = &_1;
  expr_11: mar__a__bo_Vec_bo_U8_bc__bc_ _11 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_10);
  expr_12: mar_U8 _12; _12.value = 3ULL;
  expr_13: mar_Nothing _13 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_11, _12);
  expr_14: mar_U64 _14; _14.value = 1ULL;
  expr_15: mar_U8 _15 = mar_get_bo_U8_bc__po_Vec_bo_U8_bc__c_U64_pc_(_1, _14);
  expr_16: mar_Nothing _16 = mar_println_bo_U8_bc__po_U8_pc_(_15);
  expr_17: mar_U8 _17;
  expr_18: mar_U8 _18; _18.value = 3ULL;
  expr_19: mar_Nothing _19 = mar_println_bo_U8_bc__po_U8_pc_(_18);
  expr_20: mar_U8 _20; _20.value = 4ULL;
  expr_21: _17 = _20; mar_Nothing _21;
  expr_22: goto expr_24; mar_Never _22;
  expr_23: goto expr_18; mar_Never _23;
  expr_24: mar_U8 _24 = _17;  expr_25: mar_U64 _25 = mar_to__U64_po_U8_pc_(_24);
  expr_26: mar_U64 _26; _26.value = 2ULL;
  expr_27: mar_StdoutWriter _27;
  expr_28: mar_Nothing _28 = mar_dump_bo_StdoutWriter_bc__po_U64_c_U64_c_StdoutWriter_pc_(_25, _26, _27);
  expr_29: mar_U8 _29; _29.value = 33ULL;
  expr_30: mar_Char _30; _30.mar_value = _29;
  expr_31: mar_Nothing _31 = mar_println_bo_Char_bc__po_Char_pc_(_30);
  expr_32: mar_U64 _32; _32.value = 123456789456ULL;
  expr_33: mar_StdoutWriter _33;
  expr_34: mar_Nothing _34 = mar_dump__address_bo_StdoutWriter_bc__po_U64_c_StdoutWriter_pc_(_32, _33);
  expr_35: mar_U8 _35; _35.value = 33ULL;
  expr_36: mar_Char _36; _36.mar_value = _35;
  expr_37: mar_Nothing _37 = mar_println_bo_Char_bc__po_Char_pc_(_36);
  expr_38: mar_U64 _38; _38.value = 123456789456ULL;
  expr_39: mar_U64 _39; _39.value = 16ULL;
  expr_40: mar_StdoutWriter _40;
  expr_41: mar_Nothing _41 = mar_dump_bo_StdoutWriter_bc__po_U64_c_U64_c_StdoutWriter_pc_(_38, _39, _40);
  expr_42: mar_U8 _42; _42.value = 33ULL;
  expr_43: mar_Char _43; _43.mar_value = _42;
  expr_44: mar_Nothing _44 = mar_println_bo_Char_bc__po_Char_pc_(_43);
  expr_45: mar_I64 _45; _45.value = 0LL;
  expr_46: return _45; mar_Never _46;
  expr_47: mar_Never _47;
  expr_48: // end
}

// malloc(U64)
mar_U64 mar_malloc_po_U64_pc_(mar_U64 arg0) {
  mar_U64 address;
  address.value = (uint64_t)malloc(arg0.value);
  if (!address.value) {
    printf("OOM");
    exit(-1);
  }
  return address;
}

// modulo(U64, U64)
mar_U64 mar_modulo_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// multiply(U64, U64)
mar_U64 mar_multiply_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value * arg1.value;
  return i;
}

// print[Char](Char)
mar_Nothing mar_print_bo_Char_bc__po_Char_pc_(mar_Char arg0) {
  expr_0: mar_Char _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_Char_c_StdoutWriter_pc_(_0, _1);
  expr_3: return _2; mar_Never _3;
  expr_4: // end
}

// print[U8](U8)
mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_0, _1);
  expr_3: return _2; mar_Never _3;
  expr_4: // end
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// println[Char](Char)
mar_Nothing mar_println_bo_Char_bc__po_Char_pc_(mar_Char arg0) {
  expr_0: mar_Char _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_Char_bc__po_Char_pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10ULL;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: return _4; mar_Never _5;
  expr_6: // end
}

// println[U8](U8)
mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_U8_bc__po_U8_pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10ULL;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: return _4; mar_Never _5;
  expr_6: // end
}

// push[U8](&[Vec[U8]], U8)
mar_Nothing mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0, mar_U8 arg1) {
  expr_0: mar__a__bo_Vec_bo_U8_bc__bc_ _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Nothing _2;
  expr_3: mar_Vec_bo_U8_bc_ _3 = *_0.pointer;
  expr_4: mar_U64 _4 = _3.mar_capacity;
  expr_5: mar_U64 _5; _5.value = 0ULL;
  expr_6: mar_Bool _6 = mar_equals_po_U64_c_U64_pc_(_4, _5);
  expr_7: if (_6.variant == mar_true) goto expr_9; mar_Never _7;
  expr_8: goto expr_19; mar_Never _8;
  expr_9: mar_U64 _9; _9.value = 8ULL;
  expr_10: mar_U64 _10 = mar_size__of__type_bo_U8_bc__po__pc_();
  expr_11: mar_U64 _11 = mar_multiply_po_U64_c_U64_pc_(_9, _10);
  expr_12: mar_U64 _12 = mar_malloc_po_U64_pc_(_11);
  expr_13: mar__a__bo_U8_bc_ _13 = mar_to__reference_bo_U8_bc__po_U64_pc_(_12);
  expr_14: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_data = _13; mar_Nothing _14;
  expr_15: mar_U64 _15; _15.value = 8ULL;
  expr_16: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_capacity = _15; mar_Nothing _16;
  expr_17: _2 = _16; mar_Nothing _17;
  expr_18: goto expr_19; mar_Never _18;
  expr_19: mar_Nothing _19;
  expr_20: mar_Vec_bo_U8_bc_ _20 = *_0.pointer;
  expr_21: mar_U64 _21 = _20.mar_capacity;
  expr_22: mar_Vec_bo_U8_bc_ _22 = *_0.pointer;
  expr_23: mar_U64 _23 = _22.mar_len;
  expr_24: mar_Bool _24 = mar_equals_po_U64_c_U64_pc_(_21, _23);
  expr_25: if (_24.variant == mar_true) goto expr_27; mar_Never _25;
  expr_26: goto expr_30; mar_Never _26;
  expr_27: mar_Nothing _27;
  expr_28: _19 = _27; mar_Nothing _28;
  expr_29: goto expr_30; mar_Never _29;
  expr_30: mar_Vec_bo_U8_bc_ _30 = *_0.pointer;
  expr_31: mar__a__bo_U8_bc_ _31 = _30.mar_data;
  expr_32: mar_Vec_bo_U8_bc_ _32 = *_0.pointer;
  expr_33: mar_U64 _33 = _32.mar_len;
  expr_34: mar__a__bo_U8_bc_ _34 = mar_add_bo_U8_bc__po__a__bo_U8_bc__c_U64_pc_(_31, _33);
  expr_35: mar__a__bo_U8_bc_ _35 = _34;  expr_36: (*((mar_U8*) _35.pointer)) = _1; mar_Nothing _36;
  expr_37: mar_Vec_bo_U8_bc_ _37 = *_0.pointer;
  expr_38: mar_U64 _38 = _37.mar_len;
  expr_39: mar_U64 _39; _39.value = 1ULL;
  expr_40: mar_U64 _40 = mar_add_po_U64_c_U64_pc_(_38, _39);
  expr_41: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_len = _40; mar_Nothing _41;
  expr_42: return _41; mar_Never _42;
  expr_43: // end
}

// size_of_type[U8]()
mar_U64 mar_size__of__type_bo_U8_bc__po__pc_() {
  mar_U64 size;
  size.value = (uint64_t)sizeof(mar_U8);
  return size;
}

// subtract(U8, U8)
mar_U8 mar_subtract_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value - arg1.value;
  return i;
}

// to_U64(U8)
mar_U64 mar_to__U64_po_U8_pc_(mar_U8 arg0) {
  mar_U64 i;
  i.value = arg0.value;
  return i;
}

// to_U8(U64)
mar_U8 mar_to__U8_po_U64_pc_(mar_U64 arg0) {
  mar_U8 i;
  i.value = arg0.value;
  return i;
}

// to_address[U8](&[U8])
mar_U64 mar_to__address_bo_U8_bc__po__a__bo_U8_bc__pc_(mar__a__bo_U8_bc_ arg0) {
  mar_U64 address;
  address.value = (uint64_t)arg0.pointer;
  return address;
}

// to_reference[U8](U64)
mar__a__bo_U8_bc_ mar_to__reference_bo_U8_bc__po_U64_pc_(mar_U64 arg0) {
  mar__a__bo_U8_bc_ ref;
  ref.pointer = (mar_U8*) arg0.value;
  return ref;
}

// vec[U8]()
mar_Vec_bo_U8_bc_ mar_vec_bo_U8_bc__po__pc_() {
  expr_0: mar_U64 _0; _0.value = 0ULL;
  expr_1: mar__a__bo_U8_bc_ _1 = mar_to__reference_bo_U8_bc__po_U64_pc_(_0);
  expr_2: mar_U64 _2; _2.value = 0ULL;
  expr_3: mar_U64 _3; _3.value = 0ULL;
  expr_4: mar_Vec_bo_U8_bc_ _4; _4.mar_data = _1; _4.mar_capacity = _2; _4.mar_len = _3;
  expr_5: return _4; mar_Never _5;
  expr_6: // end
}

// write(StdoutWriter, U8)
mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1) {
  expr_0: mar_StdoutWriter _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Nothing _2 = mar_print__to__stdout_po_U8_pc_(_1);
  expr_3: return _2; mar_Never _3;
  expr_4: // end
}

// actual main function
int main() {
  return mar_main_po__pc_().value;
}
