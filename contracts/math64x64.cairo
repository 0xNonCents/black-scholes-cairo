# @dev https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
# @dev https://toolkit.abdk.consulting/math#convert-number

from starkware.cairo.common.math import (
    assert_not_zero, assert_le, signed_div_rem, abs_value, assert_lt)
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.pow import pow
from starkware.cairo.common.bitwise import bitwise_and
from contracts.constants import (
    MIN_64_64, MAX_64_64, BITS_64, EULERS_NUM, FELT_MAX, RANGE_CHECK_BOUND)
from contracts.vector import initialize_vector, push, product_and_shift_vector
from contracts.hints import bitwise_shift_right

# @notice Converts signed 241-bit felt to a signed 64.64-bit fixed point representation. Reverts if felt is greater than 'MAX_64_64)
# @param 'value' signed 241-bit felt
# @returns the 64.64-bit fixed point number
func from_int{pedersen_ptr : HashBuiltin*, range_check_ptr}(input : felt) -> (output : felt):
    assert_le(MIN_64_64, input)
    assert_le(input, MAX_64_64)
    return (input * BITS_64)
end

# @notice Converts signed 64.64-bit fixed point number to signed 64 bit number
# @param input signed fixed point number
# @ returns the signed 64 bit rounded number
func to_int{pedersen_ptr : HashBuiltin*, range_check_ptr}(input : felt) -> (output : felt):
    let (quotient, rem) = signed_div_rem(input, BITS_64, RANGE_CHECK_BOUND / 2)
    return (quotient)
end

# @notice adds two signed 64.64-bit fixed point numbers
# @param x a 64.64-bit fixed point number
# @param y a 64.64-bit fixed point number
func fixed_64_64_add{range_check_ptr}(x : felt, y : felt) -> (output : felt):
    let res = x + y
    assert_le(MIN_64_64, res)
    assert_le(res, MAX_64_64)
    return (res)
end

# @notice subtracts signed 64.64-bit fixed point number 'x' by signed 64.64-bit fixed point number 'y'
# @param x a 64.64-bit fixed point number
# @param y a 64.64-bit fixed point number
func fixed_64_64_sub{range_check_ptr}(x : felt, y : felt) -> (output : felt):
    let res = x - y
    assert_le(MIN_64_64, res)
    assert_le(res, MAX_64_64)
    return (res)
end

# @notice divides two signed 64.64-bit fixed point numbers
func fixed_64_64_div{range_check_ptr}(x : felt, y : felt) -> (output : felt):
    assert_not_zero(y)
    let (quotient, rem) = signed_div_rem(x * BITS_64, y, BITS_64)
    assert_le(MIN_64_64, quotient)
    assert_le(quotient, MAX_64_64)
    return (quotient)
end

# @notice get the absolute value of the signed number
func fixed_64_64_abs{range_check_ptr}(input : felt) -> (output : felt):
    let (_abs) = abs_value(input)
    return (_abs)
end

func fixed_64_64_neg{range_check_ptr}(input : felt) -> (output : felt):
    assert_lt(MIN_64_64, input)
    assert_le(input, MAX_64_64)
    return (-input)
end

# TWO_ROOT_TWO
#  2**63
const TWO_ROOT_TWO = 0x16A09E667F3BCC908B2FB1366EA957D3E
const FOUR_ROOT_TWO = 0x1306FE0A31B7152DE8D5A46305C85EDEC
func binary_exponent{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        exp : felt) -> (output : felt):
    alloc_locals
    assert_lt(exp, 0x400000000000000000)
    let (is_underflow) = is_le(exp, -0x400000000000000001)

    if is_underflow == 1:
        return (0)
    end

    let (v) = initialize_vector()

    let (mask_63) = bitwise_and(exp, 2 ** 63)
    let (has_63_bit) = is_not_zero(mask_63)
    let (v2) = push(v, (TWO_ROOT_TWO * has_63_bit) + 1)

    let (mask_62) = bitwise_and(exp, 2 ** 62)
    let (has_62_bit) = is_not_zero(mask_62)
    let (v3) = push(v2, (FOUR_ROOT_TWO * has_62_bit) + 1)

    let (product) = product_and_shift_vector(v3, 0x8000000000000000)
    let (shift) = bitwise_shift_right(exp, 64)
    let (result) = bitwise_shift_right(product, 63 - shift)
    return (result)
end

# @notice calculate the natural exponent of x.
func fixed_64_64_exp{range_check_ptr}(exponent : felt) -> (output : felt):
    assert_lt(exponent, 0x400000000000000000)
    let (is_underflow) = is_le(exponent, -0x400000000000000001)

    if is_underflow == 1:
        return (0)
    end

    let (math_1, rem) = signed_div_rem(
        exponent * 0x171547652B82FE1777D0FFDA0D23A7D12, 2 ** 128, 2 ** 128)

    let (res) = pow(BITS_64 * EULERS_NUM, exponent)
    return (res)
end
