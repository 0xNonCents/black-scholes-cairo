from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import signed_div_rem
from contracts.math64x64 import fixed_64_64_neg, fixed_64_64_mul, fixed_64_64_exp, fixed_64_64_div
from contracts.constants import MAX_64_64, SQRT_TWOPI
from contracts.hints import bitwise_shift_right
func std_normal{pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        x : felt) -> (res : felt):
    let (ratio) = bitwise_shift_right(x, 1)
    %{ print(ids.ratio) %}
    let (x_neg) = fixed_64_64_neg(x)
    %{ print(ids.x_neg) %}
    let (mul_res) = fixed_64_64_mul(x_neg, ratio)
    %{ print(ids.mul_res) %}
    let (exp_res) = fixed_64_64_exp(mul_res)
    %{ print(ids.exp_res) %}
    let (div_sqrt_pi_res) = fixed_64_64_div(exp_res, SQRT_TWOPI)
    %{ print(ids.div_sqrt_pi_res) %}
    return (div_sqrt_pi_res)
end
