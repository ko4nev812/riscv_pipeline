#------------------------------------------------------------------------------
#    LB (load byte) test
#------------------------------------------------------------------------------
# Tests:
#   1. store 0 in x1, store 1 in x2, load word from DMEM. Expect: x1 == x2
#------------------------------------------------------------------------------

#--- common part for all tests (proposal)
.eqv TEST_RESULT x31
.eqv TEST_FAIL   2
.eqv TEST_PASS   1

#------------------------------------------------------------------------------
.text
    # Test 1. store 0 in x1, store 1 in x2, load word from DMEM. Expect: x1 == x2
    addi x1, x0, 0
    addi x2, x0, 1
    lb x1, 64(x0)
    lb x2, 64(x0)
    bne x1, x2, test_fail
    j test_pass

test_pass:
    addi TEST_RESULT, x0, TEST_PASS
    jal x0, test_pass

test_fail:
    addi TEST_RESULT, x0, TEST_FAIL
    jal x0, test_fail
