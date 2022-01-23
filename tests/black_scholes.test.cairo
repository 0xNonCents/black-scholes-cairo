%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.Uint256 import Uint256
from contracts.hints import bitwise_shift_right
from contracts.constants import FELT_MAX
from contracts.black_scholes import std_normal
from contracts.math64x64 import from_int
func test_std_normal{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (neg_one) = from_int(1)
    let (res_neg_one) = std_normal(neg_one)

    assert res_neg_one = 1

    let zero = 0
    let (res_zero) = std_normal(zero)

    assert res_zero = 7359186146747302452

    return ()
end

func main{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals

    test_std_normal()
    %{ print("======== ") %}

    return ()
end
