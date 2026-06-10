extends GutTest

func before_all():
	gut.p("before_all called")

func before_each():
	gut.p("before_each called")

func after_each():
	gut.p("after_each called")

func after_all():
	gut.p("after_all called")

func test_assert_eq_letters():
	assert_eq("asdf", "asdf", "Should pass")

func test_assert_eq_number_not_equal():
	assert_eq(1, 2, "Should fail.  1 != 2")
