func bitwise_shift_left{range_check_ptr}(value : felt, shift : felt) -> (output : felt):
    tempvar shifted : felt
    %{
        from starkware.cairo.common.math_utils import assert_integer
        assert_integer(ids.value)
        assert_integer(ids.shift)
        ids.shifted = ids.value << ids.shift
        #not working as expected
        assert ids.shifted <= 2**251 ,  f'oveflow: {ids.shifted} > 2^251 + 1.'
    %}
    return (shifted)
end

func bitwise_shift_right{range_check_ptr}(value : felt, shift : felt) -> (output : felt):
    tempvar shifted : felt
    %{
        from starkware.cairo.common.math_utils import assert_integer
        assert_integer(ids.value)
        assert_integer(ids.shift)
        ids.shifted = ids.value >> ids.shift
    %}
    return (shifted)
end
