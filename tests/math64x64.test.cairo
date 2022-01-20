%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.math64x64 import (
    from_int, to_int, fixed_64_64_add, fixed_64_64_sub, fixed_64_64_div, fixed_64_64_abs,
    fixed_64_64_neg, fixed_64_64_exp, binary_exponent)
from contracts.hints import bitwise_shift_right
from contracts.constants import FELT_MAX

# 13043817825332782212

func test_binary_exponent{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (res) = binary_exponent(0x4000000000000000)

    let (res_int) = to_int(res)
    assert res = 4

    return ()
end

func binary_exponent_proof_half{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (one) = from_int(1)
    let exp = one / 2
    let product = 0x8000000000000000 * 0x16A09E667F3BCC908
    let (shifted) = bitwise_shift_right(product, 32)

    let (shift) = bitwise_shift_right(exp, 64)

    let (result) = bitwise_shift_right(shifted, 31 - shift)

    assert result = 0x16a09e667f3bcc908

    %{ print(hex(ids.shifted)) %}
    %{ print("======== ") %}
    return ()
end

func binary_exponent_proof_three_fourths{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    let (one) = from_int(1)
    let exp = one / 2 + one / 4
    %{ print(hex(ids.exp)) %}
    let product = 0x8000000000000000 * 0x16A09E667F3BCC908
    let (shifted) = bitwise_shift_right(product, 64)

    %{ print(hex(ids.shifted)) %}

    let product_2 = shifted * 0x1306FE0A31B7152DE
    let (shifted_2) = bitwise_shift_right(product_2, 64)

    %{ print(hex(ids.shifted_2)) %}

    let (shift) = bitwise_shift_right(exp, 64)
    %{ print(ids.shift) %}

    let (result) = bitwise_shift_right(shifted_2, 31 - shift)
    %{ print(ids.result) %}
    return ()
end

func main{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    binary_exponent_proof_half()
    binary_exponent_proof_three_fourths()
    return ()
end

# 240615969168004511545033772477625056927
