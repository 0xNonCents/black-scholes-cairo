%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.hints import bitwise_shift_left, bitwise_shift_right
from contracts.math64x64 import (
    from_int, to_int, fixed_64_64_add, fixed_64_64_sub, fixed_64_64_div, fixed_64_64_abs,
    fixed_64_64_neg, fixed_64_64_exp)

from contracts.constants import FELT_MAX
func test_bitshift_left{pedersen_ptr : HashBuiltin*, range_check_ptr}():
    %{ print("Should bitshift left") %}
    let (res) = bitwise_shift_left(1, 1)
    assert res = 2

    %{ print("Should prevent overflow") %}
    let (res) = bitwise_shift_left(FELT_MAX, 3)
    assert res = 0

    return ()
end

func test_bitshift_right{pedersen_ptr : HashBuiltin*, range_check_ptr}():
    %{ print("Should bitshift right") %}
    let (res) = bitwise_shift_right(2, 1)
    assert res = 1

    let (res) = bitwise_shift_right(16, 2)
    assert res = 4
    %{ print("Passed \n") %}
    %{ print("Should allow underflow truncation") %}
    let (res) = bitwise_shift_right(2, 2)
    assert res = 0
    %{ print("Passed \n") %}
    return ()
end

func main{pedersen_ptr : HashBuiltin*, range_check_ptr}():
    test_bitshift_left()
    test_bitshift_right()

    return ()
end
