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

// Box[U8]
typedef struct {
  mar_U8 val;
} mar_Box_bo_U8_bc_;

// Ref[Box[U8]]
typedef struct {
  mar_U64 address;
} mar_Ref_bo_Box_bo_U8_bc__bc_;

// StdoutWriter
typedef struct {
} mar_StdoutWriter;

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

// Char
typedef struct {
  mar_U8 value;
} mar_Char;

/// Function declarations

/* add(U8, U8) */ mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* compare_to(U8, U8) */ mar_Ordering mar_compare__to_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* deref[Box[U8]](Ref[Box[U8]]) */ mar_Box_bo_U8_bc_ mar_deref_bo_Box_bo_U8_bc__bc__po_Ref_bo_Box_bo_U8_bc__bc__pc_(mar_Ref_bo_Box_bo_U8_bc__bc_ arg0);
/* divide(U8, U8) */ mar_U8 mar_divide_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* dump[StdoutWriter](U8, StdoutWriter) */ mar_Nothing mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(mar_U8 arg0, mar_StdoutWriter arg1);
/* dump[U8, StdoutWriter](Box[U8], StdoutWriter) */ mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Box_bo_U8_bc__c_StdoutWriter_pc_(mar_Box_bo_U8_bc_ arg0, mar_StdoutWriter arg1);
/* follow_address[Box[U8]](U64) */ mar_Box_bo_U8_bc_ mar_follow__address_bo_Box_bo_U8_bc__bc__po_U64_pc_(mar_U64 arg0);
/* is_at_least(U8, U8) */ mar_Bool mar_is__at__least_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* is_greater_or_equal(Ordering) */ mar_Bool mar_is__greater__or__equal_po_Ordering_pc_(mar_Ordering arg0);
/* main() */ mar_I64 mar_main_po__pc_();
/* malloc(U64) */ mar_U64 mar_malloc_po_U64_pc_(mar_U64 arg0);
/* modulo(U8, U8) */ mar_U8 mar_modulo_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1);
/* new[Box[U8]](Box[U8]) */ mar_Ref_bo_Box_bo_U8_bc__bc_ mar_new_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0);
/* print[Box[U8]](Box[U8]) */ mar_Nothing mar_print_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0);
/* print_to_stdout(U8) */ mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0);
/* println[Box[U8]](Box[U8]) */ mar_Nothing mar_println_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0);
/* size_of_type[Box[U8]]() */ mar_U64 mar_size__of__type_bo_Box_bo_U8_bc__bc__po__pc_();
/* write(StdoutWriter, U8) */ mar_Nothing mar_write_po_StdoutWriter_c_U8_pc_(mar_StdoutWriter arg0, mar_U8 arg1);

/// Function definitions

// add(U8, U8)
mar_U8 mar_add_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_U8 i;
  i.value = arg0.value + arg1.value;
  return i;
}

// compare_to(U8, U8)
mar_Ordering mar_compare__to_po_U8_c_U8_pc_(mar_U8 arg0, mar_U8 arg1) {
  mar_Ordering ordering;
  ordering.variant = (arg0.value == arg1.value) ? mar_equal : (arg0.value > arg1.value) ? mar_greater : mar_less;
  mar_Nothing nothing;
  ordering.as.mar_equal = nothing;
  return ordering;
}

// deref[Box[U8]](Ref[Box[U8]])
mar_Box_bo_U8_bc_ mar_deref_bo_Box_bo_U8_bc__bc__po_Ref_bo_Box_bo_U8_bc__bc__pc_(mar_Ref_bo_Box_bo_U8_bc__bc_ arg0) {
  expr_0: mar_Ref_bo_Box_bo_U8_bc__bc_ _0 = arg0;
  expr_1: mar_U64 _1 = _0.address;
  expr_2: mar_Box_bo_U8_bc_ _2 = mar_follow__address_bo_Box_bo_U8_bc__bc__po_U64_pc_(_1);
  expr_3: return _2; mar_Never _3;
  expr_4: // end
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
  expr_41: return _40; mar_Never _41;
  expr_42: // end
}

// dump[U8, StdoutWriter](Box[U8], StdoutWriter)
mar_Nothing mar_dump_bo_U8_c_StdoutWriter_bc__po_Box_bo_U8_bc__c_StdoutWriter_pc_(mar_Box_bo_U8_bc_ arg0, mar_StdoutWriter arg1) {
  expr_0: mar_Box_bo_U8_bc_ _0 = arg0;
  expr_1: mar_StdoutWriter _1 = arg1;
  expr_2: mar_U8 _2 = _0.val;
  expr_3: mar_Nothing _3 = mar_dump_bo_StdoutWriter_bc__po_U8_c_StdoutWriter_pc_(_2, _1);
  expr_4: return _3; mar_Never _4;
  expr_5: // end
}

// follow_address[Box[U8]](U64)
mar_Box_bo_U8_bc_ mar_follow__address_bo_Box_bo_U8_bc__bc__po_U64_pc_(mar_U64 arg0) {
  mar_Box_bo_U8_bc_ object = *((mar_Box_bo_U8_bc_*) arg0.value);
  return object;
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
  expr_21: return _1; mar_Never _21;
  expr_22: // end
}

// main()
mar_I64 mar_main_po__pc_() {
  expr_0: mar_U8 _0; _0.value = 3ULL;
  expr_1: mar_Box_bo_U8_bc_ _1; _1.val = _0;
  expr_2: mar_Ref_bo_Box_bo_U8_bc__bc_ _2 = mar_new_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(_1);
  expr_3: mar_Box_bo_U8_bc_ _3 = mar_deref_bo_Box_bo_U8_bc__bc__po_Ref_bo_Box_bo_U8_bc__bc__pc_(_2);
  expr_4: mar_Nothing _4 = mar_println_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(_3);
  expr_5: mar_I64 _5; _5.value = 0;
  expr_6: return _5; mar_Never _6;
  expr_7: mar_Never _7;
  expr_8: // end
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

// new[Box[U8]](Box[U8])
mar_Ref_bo_Box_bo_U8_bc__bc_ mar_new_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0) {
  expr_0: mar_Box_bo_U8_bc_ _0 = arg0;
  expr_1: mar_U64 _1 = mar_size__of__type_bo_Box_bo_U8_bc__bc__po__pc_();
  expr_2: mar_U64 _2 = mar_malloc_po_U64_pc_(_1);
  expr_3: mar_Ref_bo_Box_bo_U8_bc__bc_ _3; _3.address = _2;
  expr_4: (*((mar_Box_bo_U8_bc_*) _3.address.value)) = _0; mar_Nothing _4;
  expr_5: return _3; mar_Never _5;
  expr_6: // end
}

// print[Box[U8]](Box[U8])
mar_Nothing mar_print_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0) {
  expr_0: mar_Box_bo_U8_bc_ _0 = arg0;
  expr_1: mar_StdoutWriter _1;
  expr_2: mar_Nothing _2 = mar_dump_bo_U8_c_StdoutWriter_bc__po_Box_bo_U8_bc__c_StdoutWriter_pc_(_0, _1);
  expr_3: return _2; mar_Never _3;
  expr_4: // end
}

// print_to_stdout(U8)
mar_Nothing mar_print__to__stdout_po_U8_pc_(mar_U8 arg0) {
  putc(arg0.value, stdout);
  mar_Nothing n;
  return n;
}

// println[Box[U8]](Box[U8])
mar_Nothing mar_println_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(mar_Box_bo_U8_bc_ arg0) {
  expr_0: mar_Box_bo_U8_bc_ _0 = arg0;
  expr_1: mar_Nothing _1 = mar_print_bo_Box_bo_U8_bc__bc__po_Box_bo_U8_bc__pc_(_0);
  expr_2: mar_StdoutWriter _2;
  expr_3: mar_U8 _3; _3.value = 10ULL;
  expr_4: mar_Nothing _4 = mar_write_po_StdoutWriter_c_U8_pc_(_2, _3);
  expr_5: return _4; mar_Never _5;
  expr_6: // end
}

// size_of_type[Box[U8]]()
mar_U64 mar_size__of__type_bo_Box_bo_U8_bc__bc__po__pc_() {
  mar_U64 size;
  size.value = (uint64_t)sizeof(mar_Box_bo_U8_bc_);
  return size;
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
