# @title The beginnings of Vector in Cairo
# @author 0xNonCents
# @notice Please let me know if this will not save on gas compared to an @storage array
# @dev Please remove the driver function before using, as it is not supported on StarkNet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_nn, assert_le
from starkware.cairo.common.registers import get_fp_and_pc
from contracts.hints import bitwise_shift_right
# @member s the starting pointer of the vector
# @member e the ending pointer of the vector
# @member size the current size of the vector
struct vector:
    member s : felt*
    member e : felt*
    member size : felt
end

# @notice initializes an empty vector
func initialize_vector() -> (v : vector):
    alloc_locals
    let s : felt* = alloc()
    let e : felt* = s
    return (vector(s, e, 0))
end

# @notice Appends {value} to the (e)nd of a vector. Increment the end pointer and size by 1 (SIZE of felt).
# @param v The vector which recieves the new element
# @param value The element that is added to the end of the vector
# @return A new vector containing the added element
func push{pedersen_ptr : HashBuiltin*, range_check_ptr}(v : vector, value : felt) -> (res : vector):
    let end_ptr = v.e
    [end_ptr] = value
    let out_v : vector = vector(v.s, end_ptr + 1, v.size + 1)
    return (out_v)
end

# @notice Retrieves the element at a given {index}
# @dev Will break if index is out of vector bounds
# @param v The vector
# @param index The index to get the desired value
# @return The value of the vector at an index
func at{pedersen_ptr : HashBuiltin*, range_check_ptr}(v : vector, index : felt) -> (res : felt):
    let res = v.s[index]
    return (res)
end

# @notice performs a recursive add operation for { scalar_add }
# @dev use scalar_add for scalar additions
# @param input_v The input vector that recieves the add operation
# @param out_v The output vector from the resulting add operation
# @param index The current index of the recursion loop
# @return A vector that has recieved the addition operation
func perform_add{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        input_v : vector, out_v : vector, value : felt, index : felt) -> (res : vector):
    if index == input_v.size:
        return (out_v)
    end
    let (pushed) = push(out_v, input_v.s[index] + value)
    let (performed) = perform_add(input_v, pushed, value, index + 1)

    return (performed)
end

# @notice adds scalar {value} to the vector
# @param v Vector
# @param value
# @return a vector with the added value
func scalar_add{pedersen_ptr : HashBuiltin*, range_check_ptr}(v : vector, value : felt) -> (
        res : vector):
    let (out_v : vector) = initialize_vector()
    let (out_v) = perform_add(input_v=v, out_v=out_v, value=value, index=0)
    return (out_v)
end

# @notice performs a recursive multiplication operation for { scalar_add }
# @dev use scalar_mul for scalar multiplications
# @param input_v The input vector that recieves the add operation
# @param out_v The output vector from the resulting add operation
# @param index The current index of the recursion loop
# @return A vector that has recieved the addition operation
func perform_mul{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        input_v : vector, out_v : vector, value : felt, index : felt) -> (res : vector):
    if index == input_v.size:
        return (out_v)
    end
    let (pushed) = push(out_v, input_v.s[index] * value)
    let (performed) = perform_mul(input_v, pushed, value, index + 1)

    return (performed)
end

# @notice multiplies a vector by a scalar {value}
# @param v Vector
# @param value
# @return a vector with the added value
func scalar_mul{pedersen_ptr : HashBuiltin*, range_check_ptr}(v : vector, value : felt) -> (
        res : vector):
    let (out_v : vector) = initialize_vector()
    let (out_v) = perform_mul(input_v=v, out_v=out_v, value=value, index=0)
    return (out_v)
end

func perform_dot{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        v_1 : vector, v_2 : vector, index : felt, total : felt) -> (res : felt):
    if v_1.size == index:
        return (total)
    end
    let (performed) = perform_dot(v_1, v_2, index + 1, total + v_1.s[index] * v_2.s[index])
    return (performed)
end
# @notice performs a dot product operation on two vectors
# @param v_1 the first vector used in the operation
# @param v_2 the second vector
# @returns the dot product
func dot_product{pedersen_ptr : HashBuiltin*, range_check_ptr}(v_1 : vector, v_2 : vector) -> (
        res : felt):
    let (dot_product) = perform_dot(v_1, v_2, 0, 0)
    return (dot_product)
end

# # forbidden math below, should be in an isolated file but alas we cannot reimport builtin declarations
func perform_product_and_shift{
        bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        v : vector, result : felt, index : felt) -> (res : felt):
    if index == v.size:
        return (result)
    end

    let current = v.s[index] * result
    let (shifted) = bitwise_shift_right(current, 64)
    let (res) = perform_product_and_shift(v, shifted, index + 1)
    return (res)
end

func product_and_shift_vector{
        bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        v : vector, initial_value : felt) -> (res : felt):
    let (product) = perform_product_and_shift(v, initial_value, 0)
    return (product)
end
