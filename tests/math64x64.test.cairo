%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.math64x64 import (
    from_int, to_int, fixed_64_64_add, fixed_64_64_sub, fixed_64_64_div, fixed_64_64_abs,
    fixed_64_64_neg, fixed_64_64_exp, binary_exponent)

from contracts.constants import FELT_MAX

func test_binary_exponent{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (res) = binary_exponent(1)

    assert res = 4

    return ()
end

func main{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    test_binary_exponent()
    return ()
end
