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
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* equals(U64, U64) */ mar_Bool mar_equals_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* get[U8](Vec[U8], U64) */ mar_U8 mar_get_bo_U8_bc__po_Vec_bo_U8_bc__c_U64_pc_(mar_Vec_bo_U8_bc_ arg0, mar_U64 arg1);
/* identity[&[Vec[U8]]](&[Vec[U8]]) */ mar__a__bo_Vec_bo_U8_bc__bc_ mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0);
/* is_at_least(U8, U8) */ mar_Bool mar_is__at__least_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* is_equal(Ordering) */ mar_Bool mar_is__equal_po_Ordering_pc_(mar_Ordering arg0);
/* is_greater_or_equal(Ordering) */ mar_Bool mar_is__greater__or__equal_po_Ordering_pc_(mar_Ordering arg0);
/* main() */ mar_I64 mar_main_po__pc_();
/* malloc(U64) */ mar_U64 mar_malloc_po_U64_pc_(mar_U64 arg0);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* multiply(U64, U64) */ mar_U64 mar_multiply_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1);
/* print[U8](U8) */ mar_Nothing mar_print_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[U8](U8) */ mar_Nothing mar_println_bo_U8_bc__po_U8_pc_(mar_U8 arg0);
/* push[U8](&[Vec[U8]], U8) */ mar_Nothing mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(mar__a__bo_Vec_bo_U8_bc__bc_ arg0, mar_U8 arg1);
/* size_of_type[U8]() */ mar_U64 mar_size__of__type_bo_U8_bc__po__pc_();
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
  expr_12: mar_Char _12; _12.mar_value = _11;
  expr_13: mar_U8 _13 = _12.mar_value;
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
  expr_28: mar_Char _28; _28.mar_value = _27;
  expr_29: mar_U8 _29 = _28.mar_value;
  expr_30: mar_U8 _30 = mar_add_po_U8_c_U8_pc_(_26, _29);
  expr_31: mar_Nothing _31 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _30);
  expr_32: _18 = _31; mar_Nothing _32;
  expr_33: goto expr_34;
  expr_34: mar_U8 _34; _34.value = 10ULL;
  expr_35: mar_U8 _35 = mar_modulo_po_U8_c_U8_pc_(_0, _34);
  expr_36: mar_U8 _36; _36.value = 48ULL;
  expr_37: mar_Char _37; _37.mar_value = _36;
  expr_38: mar_U8 _38 = _37.mar_value;
  expr_39: mar_U8 _39 = mar_add_po_U8_c_U8_pc_(_35, _38);
  expr_40: mar_Nothing _40 = mar_write_po_StdoutWriter_c_U8_pc_(_1, _39);
  expr_41: return _40; mar_Never _41;
  expr_42: // end
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

// is_at_least(U8, U8)
mar_Bool mar_is__at__least_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  expr_0: mar_U8 _0 = arg0;
  expr_1: mar_U8 _1 = arg1;
  expr_2: mar_Ordering _2 = mar_compare__to_po_U8_c_U8_pc_(_0, _1);
  expr_3: mar_Bool _3 = mar_is__greater__or__equal_po_Ordering_pc_(_2);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// is_equal(Ordering)
mar_Bool mar_is__equal_po_Ordering_pc_(mar_Ordering arg0) {
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
  expr_18: mar_Bool _18; _18.variant = mar_false; _18.as.mar_false = _17;
  expr_19: _1 = _18; mar_Nothing _19;
  expr_20: goto expr_21;
  expr_21: return _1; mar_Never _21;
  expr_22: // end
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
  expr_21: return _1; mar_Never _21;
  expr_22: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_Vec_bo_U8_bc_ _0 = mar_vec_bo_U8_bc__po__pc_();
  expr_1: mar__a__bo_Vec_bo_U8_bc__bc_ _1; _1.pointer = &_0;
  expr_2: mar__a__bo_Vec_bo_U8_bc__bc_ _2 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_1);
  expr_3: mar_U8 _3; _3.value = 1ULL;
  expr_4: mar_Nothing _4 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_2, _3);
  expr_5: mar__a__bo_Vec_bo_U8_bc__bc_ _5; _5.pointer = &_0;
  expr_6: mar__a__bo_Vec_bo_U8_bc__bc_ _6 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_5);
  expr_7: mar_U8 _7; _7.value = 2ULL;
  expr_8: mar_Nothing _8 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_6, _7);
  expr_9: mar__a__bo_Vec_bo_U8_bc__bc_ _9; _9.pointer = &_0;
  expr_10: mar__a__bo_Vec_bo_U8_bc__bc_ _10 = mar_identity_bo__a__bo_Vec_bo_U8_bc__bc__bc__po__a__bo_Vec_bo_U8_bc__bc__pc_(_9);
  expr_11: mar_U8 _11; _11.value = 3ULL;
  expr_12: mar_Nothing _12 = mar_push_bo_U8_bc__po__a__bo_Vec_bo_U8_bc__bc__c_U8_pc_(_10, _11);
  expr_13: mar_U64 _13; _13.value = 1ULL;
  expr_14: mar_U8 _14 = mar_get_bo_U8_bc__po_Vec_bo_U8_bc__c_U64_pc_(_0, _13);
  expr_15: mar_Nothing _15 = mar_println_bo_U8_bc__po_U8_pc_(_14);
  expr_16: mar_I64 _16; _16.value = 0LL;
  expr_17: return _16; mar_Never _17;
  expr_18: mar_Never _18;
  expr_19: // end
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

// modulo(U8, U8)
mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value % arg1.value;
  return i;
}

// multiply(U64, U64)
mar_U64 mar_multiply_po_U64_c_U64_pc_(mar_U64 arg0, mar_U64 arg1) {
  mar_U64 i;
  i.value = arg0.value * arg1.value;
  return i;
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
  expr_7: if (_6.variant == mar_true) goto expr_9;
  expr_8: goto expr_19;
  expr_9: mar_U64 _9; _9.value = 8ULL;
  expr_10: mar_U64 _10 = mar_size__of__type_bo_U8_bc__po__pc_();
  expr_11: mar_U64 _11 = mar_multiply_po_U64_c_U64_pc_(_9, _10);
  expr_12: mar_U64 _12 = mar_malloc_po_U64_pc_(_11);
  expr_13: mar__a__bo_U8_bc_ _13 = mar_to__reference_bo_U8_bc__po_U64_pc_(_12);
  expr_14: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_data = _13; mar_Nothing _14;
  expr_15: mar_U64 _15; _15.value = 8ULL;
  expr_16: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_capacity = _15; mar_Nothing _16;
  expr_17: _2 = _16; mar_Nothing _17;
  expr_18: goto expr_19;
  expr_19: mar_Nothing _19;
  expr_20: mar_Vec_bo_U8_bc_ _20 = *_0.pointer;
  expr_21: mar_U64 _21 = _20.mar_capacity;
  expr_22: mar_Vec_bo_U8_bc_ _22 = *_0.pointer;
  expr_23: mar_U64 _23 = _22.mar_len;
  expr_24: mar_Bool _24 = mar_equals_po_U64_c_U64_pc_(_21, _23);
  expr_25: if (_24.variant == mar_true) goto expr_27;
  expr_26: goto expr_30;
  expr_27: mar_Nothing _27;
  expr_28: _19 = _27; mar_Nothing _28;
  expr_29: goto expr_30;
  expr_30: mar_Vec_bo_U8_bc_ _30 = *_0.pointer;
  expr_31: mar__a__bo_U8_bc_ _31 = _30.mar_data;
  expr_32: mar_Vec_bo_U8_bc_ _32 = *_0.pointer;
  expr_33: mar_U64 _33 = _32.mar_len;
  expr_34: mar__a__bo_U8_bc_ _34 = mar_add_bo_U8_bc__po__a__bo_U8_bc__c_U64_pc_(_31, _33);
  expr_35: (*((mar_U8*) _34.pointer)) = _1; mar_Nothing _35;
  expr_36: mar_Vec_bo_U8_bc_ _36 = *_0.pointer;
  expr_37: mar_U64 _37 = _36.mar_len;
  expr_38: mar_U64 _38; _38.value = 1ULL;
  expr_39: mar_U64 _39 = mar_add_po_U64_c_U64_pc_(_37, _38);
  expr_40: (*((mar_Vec_bo_U8_bc_*) _0.pointer)).mar_len = _39; mar_Nothing _40;
  expr_41: return _40; mar_Never _41;
  expr_42: // end
}

// size_of_type[U8]()
mar_U64 mar_size__of__type_bo_U8_bc__po__pc_() {
  mar_U64 size;
  size.value = (uint64_t)sizeof(mar_U8);
  return size;
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
