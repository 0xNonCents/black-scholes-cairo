%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.math64x64 import (
    from_int, to_int, fixed_64_64_add, fixed_64_64_sub, fixed_64_64_div, fixed_64_64_abs,
    fixed_64_64_neg, fixed_64_64_exp, binary_exponent, fixed_64_64_log_2)
from contracts.hints import bitwise_shift_right
from contracts.constants import FELT_MAX

# 13043817825332782212

func test_binary_exponent{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (one) = from_int(1)
    let exp = one / 2
    let (res) = binary_exponent(exp)

    let (res_int) = to_int(res)
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
    let (one) = from_int(1)
    let (res) = fixed_64_64_exp(one)

    # # 2.378414230005442133429 matches output of solidity counterpart with limited fraction exponents,
    # however we should add the other fractional exponents to get the mathematically correct answers
    assert res = 0x260dfc14636e2a5bd

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

func main{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    test_log_2()
    %{ print("======== ") %}
    test_natural_exponent()
    %{ print("======== ") %}
    test_binary_exponent()
    %{ print("======== ") %}
    binary_exponent_proof_half()
    %{ print("======== ") %}
    binary_exponent_proof_three_fourths()
    return ()
end
