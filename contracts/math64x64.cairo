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
from contracts.hints import bitwise_shift_right, bitwise_shift_left

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

# @notice adds two signed 64.64-bit fixed point numbers
# @param x a 64.64-bit fixed point number
# @param y a 64.64-bit fixed point number
func fixed_64_64_mul{range_check_ptr}(x : felt, y : felt) -> (output : felt):
    let res = x * y
    let (quotient, rem) = signed_div_rem(res, 64, BITS_64)
    assert_le(MIN_64_64, quotient)
    assert_le(quotient, MAX_64_64)
    return (quotient)
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
const TWO_ROOT_TWO = 0x16A09E667F3BCC908
const FOUR_ROOT_TWO = 0x1306FE0A31B7152DE
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
    return (product * 2)
end

# @notice calculate the natural exponent of x (e^x)
func fixed_64_64_exp{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        exponent : felt) -> (output : felt):
    assert_lt(exponent, 0x400000000000000000)
    let (is_underflow) = is_le(exponent, -0x400000000000000001)

    if is_underflow == 1:
        return (0)
    end

    let (math_1) = bitwise_shift_right(exponent * 0x171547652B82FE177, 64)
    %{ print(ids.math_1) %}
    let (res) = binary_exponent(math_1)
    return (res * 2)
end

func fixed_64_64_log_2{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : felt) -> (res : felt):
    alloc_locals
    let (not_zero) = is_not_zero(x)
    assert not_zero = 1

    let msb = 0

    let (is_greater_64) = is_le(0x10000000000000000, x)
    let (x_2) = bitwise_shift_right(x, is_greater_64 * 64)
    let msb_2 = msb + is_greater_64 * 64

    let (is_greater_64_2) = is_le(0x100000000, x_2)
    let (x_3) = bitwise_shift_right(x_2, is_greater_64_2 * 32)
    let msb_3 = msb_2 + is_greater_64_2 * 32

    let (is_greater_64_3) = is_le(0x10000, x_3)
    let (x_4) = bitwise_shift_right(x_3, is_greater_64_3 * 16)
    let msb_4 = msb_3 + is_greater_64_3 * 16

    let (is_greater_64_4) = is_le(0x100, x_4)
    let (x_5) = bitwise_shift_right(x_4, is_greater_64_4 * 8)
    let msb_5 = msb_4 + is_greater_64_4 * 8

    let (is_greater_64_5) = is_le(0x10, x_5)
    let (x_6) = bitwise_shift_right(x_5, is_greater_64_5 * 4)
    let msb_6 = msb_5 + is_greater_64_5 * 4

    let (is_greater_64_6) = is_le(0x4, x_6)
    let (x_7) = bitwise_shift_right(x_6, is_greater_64_6 * 2)
    let msb_7 = msb_6 + is_greater_64_6 * 2

    let (is_greater_64_7) = is_le(0x2, x_7)
    let (x_8) = bitwise_shift_right(x_7, is_greater_64_7 * 1)
    let msb_8 = msb_7 + is_greater_64_7 * 1

    let result = (msb_8 - 64) * 2 ** 64

    let (ux) = bitwise_shift_left(x, 127 - msb_8)

    let (log_2) = foo_shift(ux / 2 ** 64, 0x8000000000000000, result)

    return (log_2)
end

# I seriously don't know what this does. Please help
func foo_shift{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        ux : felt, bit : felt, res : felt) -> (res : felt):
    let (is_bit_nonzero) = is_not_zero(bit)
    if is_bit_nonzero == 0:
        return (res)
    end
    let ux_1 = ux * ux
    let (b) = bitwise_shift_right(ux_1, 127)
    let (ux_2) = bitwise_shift_right(ux_1, 63 + b)
    let result = (bit * b) + res
    let (shifted) = bitwise_shift_right(bit, 1)
    let (updated_res) = foo_shift(ux_2, shifted, result)

    return (updated_res)
end

func fixed_64_64_ln{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : felt) -> (res : felt):
    let (is_x_nonzero) = is_not_zero(x)

    if is_x_nonzero == 0:
        return (0)
    end

    let (log_2) = fixed_64_64_log_2(x)
    let (ln) = bitwise_shift_right(log_2 * 0xB17217F7D1CF79AB, 64)
    return (ln)
end

func fixed_64_64_sqrt_u{
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(x : felt) -> (
        res : felt):
    alloc_locals
    let r = 1

    let (is_x_le_128) = is_le(2 ** 128, x)
    let (x_2) = bitwise_shift_right(x, is_x_le_128 * 128)
    let r_2 = (r * 2 ** 64 * is_x_le_128) + (r * (1 - is_x_le_128))

    let (is_x_le_128_2) = is_le(2 ** 64, x_2)
    let (x_3) = bitwise_shift_right(x_2, is_x_le_128_2 * 64)
    let r_3 = (r_2 * 2 ** 32 * is_x_le_128_2) + (r_2 * (1 - is_x_le_128_2))

    let (is_x_le_128_3) = is_le(2 ** 32, x_3)
    let (x_4) = bitwise_shift_right(x_3, is_x_le_128_3 * 32)
    let r_4 = (r_3 * 2 ** 16 * is_x_le_128_3) + (r_3 * (1 - is_x_le_128_3))

    let (is_x_le_128_4) = is_le(2 ** 16, x_4)
    let (x_5) = bitwise_shift_right(x_4, is_x_le_128_4 * 16)
    let r_5 = (r_4 * 2 ** 8 * is_x_le_128_4) + (r_4 * (1 - is_x_le_128_4))

    let (is_x_le_128_5) = is_le(2 ** 8, x_5)
    let (x_6) = bitwise_shift_right(x_5, is_x_le_128_5 * 8)
    let r_6 = (r_5 * 2 ** 4 * is_x_le_128_5) + (r_5 * (1 - is_x_le_128_5))

    let (is_x_le_128_6) = is_le(2 ** 4, x_6)
    let (x_7) = bitwise_shift_right(x_6, is_x_le_128_6 * 4)
    let r_7 = (r_6 * 2 ** 2 * is_x_le_128_6) + (r_6 * (1 - is_x_le_128_6))

    let (is_x_le_128_7) = is_le(2 ** 2, x_7)
    let (x_8) = bitwise_shift_right(x_7, is_x_le_128_7 * 2)
    let r_8 = (r_7 * 2 * is_x_le_128_7) + (r_7 * (1 - is_x_le_128_7))

    let q_1 = (r_8 + x) / r_8
    let (r_9) = bitwise_shift_right(q_1, 1)

    let (q_2) = fixed_64_64_div(r_9 + x, r_9)
    let (r_10) = bitwise_shift_right(q_2, 1)

    let (q_3) = fixed_64_64_div(r_10 + x, r_10)
    let (r_11) = bitwise_shift_right(q_3, 1)

    let (q_4) = fixed_64_64_div(r_11 + x, r_11)
    let (r_12) = bitwise_shift_right(q_4, 1)

    let (q_5) = fixed_64_64_div(r_12 + x, r_12)
    let (r_13) = bitwise_shift_right(q_5, 1)

    let (q_6) = fixed_64_64_div(r_13 + x, r_13)
    let (r_14) = bitwise_shift_right(q_6, 1)

    let (q_7) = fixed_64_64_div(r_14 + x, r_14)
    let (r_15) = bitwise_shift_right(q_7, 1)

    let (r_alt) = fixed_64_64_div(x, r_15)

    let (is_r_alt_larger) = is_le(r_15, r_alt + 1)
    if is_r_alt_larger == 1:
        return (r_15)
    else:
        return (r_alt)
    end
end

func fixed_64_64_sqrt{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : felt) -> (res : felt):
    let (is_x_nonzero) = is_not_zero(x)

    if is_x_nonzero == 0:
        return (0)
    end

    let (res) = fixed_64_64_sqrt_u(x * 2 ** 64)

    return (res)
end
