# @dev https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
# @dev https://toolkit.abdk.consulting/math#convert-number

from starkware.cairo.common.math import (
    assert_not_zero, assert_le, signed_div_rem, abs_value, assert_lt, split_felt)
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.pow import pow
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.Uint256 import (
    Uint256, uint256_le, uint256_shr, uint256_unsigned_div_rem, uint256_add, uint256_lt,
    uint256_shl)
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
        pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : Uint256) -> (res_128 : felt):
    alloc_locals
    let r = 1

    %{ print(ids.x.low) %}
    %{ print(ids.x.high) %}

    let (is_x_le_128) = uint256_le(Uint256(0, 1), x)
    let (x_2) = uint256_shr(x, Uint256(is_x_le_128 * 128, 0))
    let r_2 = (r * 2 ** 64 * is_x_le_128) + (r * (1 - is_x_le_128))

    let (is_x_le_128_2) = uint256_le(Uint256(2 ** 64, 0), x_2)
    let (x_3) = uint256_shr(x_2, Uint256(is_x_le_128_2 * 64, 0))
    let r_3 = (r_2 * 2 ** 32 * is_x_le_128_2) + (r_2 * (1 - is_x_le_128_2))

    let (is_x_le_128_3) = uint256_le(Uint256(2 ** 32, 0), x_3)
    let (x_4) = uint256_shr(x_3, Uint256(is_x_le_128_3 * 32, 0))
    let r_4 = (r_3 * 2 ** 16 * is_x_le_128_3) + (r_3 * (1 - is_x_le_128_3))

    let (is_x_le_128_4) = uint256_le(Uint256(2 ** 16, 0), x_4)
    let (x_5) = uint256_shr(x_4, Uint256(is_x_le_128_4 * 16, 0))
    let r_5 = (r_4 * 2 ** 8 * is_x_le_128_4) + (r_4 * (1 - is_x_le_128_4))

    let (is_x_le_128_5) = uint256_le(Uint256(2 ** 8, 0), x_5)
    let (x_6) = uint256_shr(x_5, Uint256(is_x_le_128_5 * 8, 0))
    let r_6 = (r_5 * 2 ** 4 * is_x_le_128_5) + (r_5 * (1 - is_x_le_128_5))

    let (is_x_le_128_6) = uint256_le(Uint256(2 ** 4, 0), x_6)
    let (x_7) = uint256_shr(x_6, Uint256(is_x_le_128_6 * 4, 0))
    let r_7 = (r_6 * 2 ** 2 * is_x_le_128_6) + (r_6 * (1 - is_x_le_128_6))

    let (is_x_le_128_7) = uint256_le(Uint256(2 ** 2, 0), x_7)
    let (x_8) = uint256_shr(x_7, Uint256(is_x_le_128_7 * 2, 0))
    let r_8 = (r_7 * 2 * is_x_le_128_7) + (r_7 * (1 - is_x_le_128_7))

    let uint_one = Uint256(1, 0)

    %{ print(ids.r_8) %}

    let (high, low) = split_felt(r_8)
    let r_uint256 = Uint256(low, high)

    let (q_1, rem) = uint256_unsigned_div_rem(x, r_uint256)
    let (sum_1, carry) = uint256_add(r_uint256, q_1)
    %{ print(ids.carry) %}

    %{ print(ids.sum_1.low) %}
    %{ print(ids.sum_1.high) %}

    %{ print("r_uint256") %}
    %{ print(ids.r_uint256.low) %}
    %{ print(ids.r_uint256.high) %}

    %{ print("q_1") %}
    %{ print(ids.q_1.low) %}
    %{ print(ids.q_1.high) %}

    let (r_9) = uint256_shr(sum_1, uint_one)

    %{ print("r_9") %}
    %{ print(ids.r_9.low) %}
    %{ print(ids.r_9.high) %}

    let (q_2, _) = uint256_unsigned_div_rem(x, r_9)
    let (sum_2, carry) = uint256_add(r_9, q_2)
    let (r_10) = uint256_shr(sum_2, uint_one)

    let (q_3, _) = uint256_unsigned_div_rem(x, r_10)
    let (sum_3, carry) = uint256_add(r_10, q_3)
    let (r_11) = uint256_shr(sum_3, uint_one)

    let (q_4, _) = uint256_unsigned_div_rem(x, r_11)
    let (sum_4, carry) = uint256_add(r_11, q_4)
    let (r_12) = uint256_shr(sum_4, uint_one)

    let (q_5, _) = uint256_unsigned_div_rem(x, r_12)
    let (sum_5, carry) = uint256_add(r_12, q_5)
    let (r_13) = uint256_shr(sum_5, uint_one)

    let (q_6, _) = uint256_unsigned_div_rem(x, r_13)
    let (sum_6, carry) = uint256_add(r_13, q_6)
    let (r_14) = uint256_shr(sum_6, uint_one)

    let (q_7, _) = uint256_unsigned_div_rem(x, r_14)
    let (sum_7, carry) = uint256_add(r_14, q_7)
    let (r_15) = uint256_shr(q_7, uint_one)

    let (q_8, _) = uint256_unsigned_div_rem(x, r_15)
    let (sum_8, carry) = uint256_add(r_15, q_8)
    let (r_16) = uint256_shr(q_8, uint_one)

    let (r_alt, _) = uint256_unsigned_div_rem(x, r_16)

    let (r_16_le_r_alt) = uint256_lt(r_16, r_alt)

    %{ print(ids.r_16.low) %}
    %{ print(ids.r_16.high) %}

    %{ print(ids.r_alt.low) %}
    %{ print(ids.r_alt.high) %}

    if r_16_le_r_alt == 1:
        return (r_16.low)
    else:
        return (r_alt.low)
    end
end

func fixed_64_64_sqrt{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : felt) -> (res : felt):
    let (is_x_nonzero) = is_not_zero(x)

    if is_x_nonzero == 0:
        return (0)
    end

    # should check x is 64.64

    let (x_uint) = uint256_shl(Uint256(x, 0), Uint256(64, 0))
    %{ print(ids.x_uint.low) %}
    %{ print(ids.x_uint.high) %}
    let (res) = fixed_64_64_sqrt_u(x_uint)

    return (res)
end
