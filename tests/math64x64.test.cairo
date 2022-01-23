%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.math64x64 import (
    from_int, to_int, fixed_64_64_add, fixed_64_64_sub, fixed_64_64_div, fixed_64_64_abs,
    fixed_64_64_neg, fixed_64_64_exp, binary_exponent, fixed_64_64_log_2, fixed_64_64_sqrt,
    fixed_64_64_sqrt_u)
from contracts.hints import bitwise_shift_right
from contracts.constants import FELT_MAX
from starkware.cairo.common.Uint256 import Uint256
# 13043817825332782212

func test_binary_exponent{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (zero) = from_int(0)
    let (res_zero) = binary_exponent(zero)

    assert res_zero = 0x10000000000000000

    let (one) = from_int(1)
    let exp = one / 2
    let (res) = binary_exponent(exp)

    assert res = 0x16a09e667f3bcc908

    return ()
end

func binary_exponent_proof_half{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (one) = from_int(1)
    let exp = one / 2
    let product = 0x8000000000000000 * 0x16A09E667F3BCC908
    let (shifted) = bitwise_shift_right(product, 64)

    assert shifted * 2 = 0x16a09e667f3bcc908
    return ()
end

func binary_exponent_proof_three_fourths{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (one) = from_int(1)
    let exp = one / 2 + one / 4

    let product = 0x8000000000000000 * 0x16A09E667F3BCC908
    let (shifted) = bitwise_shift_right(product, 64)

    let product_2 = shifted * 0x1306FE0A31B7152DE
    let (shifted_2) = bitwise_shift_right(product_2, 64)

    assert shifted_2 * 2 = 31023601929370129894
    return ()
end

func test_natural_exponent{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals

    let (zero) = from_int(0)
    let (res_exp_zero) = fixed_64_64_exp(zero)
    assert res_exp_zero = 18446744073709551616

    let (one) = from_int(1)
    let (res) = fixed_64_64_exp(one)

    # # 2.378414230005442133429 matches output of solidity counterpart with limited fraction exponents,
    # however we should add the other fractional exponents to get the mathematically correct answers
    assert res = 0x260dfc14636e2a5bc

    let (neg_one) = from_int(-1)
    let (half_res) = fixed_64_64_exp(neg_one)

    # # 2.378414230005442133429 matches output of solidity counterpart with limited fraction exponents,
    # however we should add the other fractional exponents to get the mathematically correct answers
    assert half_res = 0x260dfc14636e2a5bd

    return ()
end

func test_log_2{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (two) = from_int(2)
    let (res) = fixed_64_64_log_2(two)

    assert res = 18446744073709551616

    let (one_hundred) = from_int(100)
    let (res_2) = fixed_64_64_log_2(one_hundred)

    assert res_2 = 122557514795305424882

    return ()
end

func test_sqrt{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let uint_int = Uint256(0, 2)
    let (res_fast) = fixed_64_64_sqrt_u(uint_int)

    assert res_fast = 26087635650665564424

    let (nine) = from_int(9)
    let (res) = fixed_64_64_sqrt(nine)

    assert res = 55340232221128654848

    return ()
end

func main{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals

    test_binary_exponent()
    %{ print("======== ") %}
    test_sqrt()
    %{ print("======== ") %}
    test_log_2()
    %{ print("======== ") %}
    test_natural_exponent()

    %{ print("======== ") %}
    binary_exponent_proof_half()
    %{ print("======== ") %}
    binary_exponent_proof_three_fourths()

    return ()
end
