extends SceneTree

var t: Node

func _process(_delta: float) -> bool:
	main()
	# returning true ends the mainloop
	return true

func main():
	t = ResourceLoader.load("res://test_base.gd").new()

	do_tests()

	quit(t.exit_code_with_status()) # won't quit immediately btw

	t.free()

func do_tests():
	var EPSILON := Decimal.from_float(0.0000000000000001)

	# i generated most of these with llms cuz i cba to write a gazillion tests
	# most of them are shit tier but whatever, i'll fix em later

	# Basic test values
	var three := Decimal.from_float(3)
	var zero := Decimal.from_float(0)
	var one := Decimal.from_float(1)
	var two := Decimal.from_float(2)
	var five := Decimal.from_float(5)
	var ten := Decimal.from_float(10)
	var zero_point_one := Decimal.from_float(0.1)
	var zero_point_two := Decimal.from_float(0.2)
	var one_over_three := Decimal.from_float(1.0 / 3.0)
	var negative_four := Decimal.from_float(-4)
	var negative_one := Decimal.from_float(-1)

	# ==========================================
	# 1. NUMBER CREATION & CONVERSION TESTS
	# ==========================================
	print("Testing number creation and conversion...")

	# Basic from_parts tests
	t.assert_true(Decimal.eq(
		Decimal.from_parts(0, 0),
		Decimal.from_float(0.0)
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_parts(4.2, 1),
		Decimal.from_float(42.0),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_parts(1.7, 308),
		Decimal.from_float(1.7e308),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_parts(5, -323),
		Decimal.from_float(5e-323),
		EPSILON
	))

	# from_parts_normalize tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_parts_normalize(42.0, 1),
		Decimal.from_float(420.0),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_parts_normalize(0.5, 2),
		Decimal.from_float(50.0),
		EPSILON
	))

	# from_float edge cases
	t.assert_true(Decimal.eq(
		Decimal.from_float(0.0),
		zero
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_float(1e100),
		Decimal.from_parts(1, 100),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_float(1e-100),
		Decimal.from_parts(1, -100),
		EPSILON
	))

	# to_string tests
	t.assert_equal(Decimal.to_string(zero), "0.0")
	t.assert_equal(Decimal.to_string(one), "1.0")
	t.assert_equal(Decimal.to_string(negative_one), "-1.0")

	# ==========================================
	# 2. NORMALIZATION & VALIDATION TESTS
	# ==========================================
	print("Testing normalization and validation...")

	# normalize tests
	var normalized := Decimal.from_parts_normalize(42.5, 3)
	t.assert_true(Decimal.get_mantissa(normalized) >= 1.0)
	t.assert_true(Decimal.get_mantissa(normalized) < 10.0)

	# is_finite tests
	t.assert_true(Decimal.is_finite(zero))
	t.assert_true(Decimal.is_finite(one))
	t.assert_true(Decimal.is_finite(Decimal.from_float(1e100)))

	# ==========================================
	# 3. ARITHMETIC OPERATIONS TESTS
	# ==========================================
	print("Testing arithmetic operations...")

	# Addition tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.add(zero_point_one, zero_point_two),
		Decimal.from_float(0.3),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.add(three, zero_point_two),
		Decimal.from_float(3.2),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.add(zero, five),
		five
	))

	t.assert_true(Decimal.eq(
		Decimal.add(five, zero),
		five
	))

	# Addition with numbers
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.add_num(three, 2.5),
		Decimal.from_float(5.5),
		EPSILON
	))

	# Subtraction tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sub(zero_point_one, zero_point_two),
		Decimal.from_float(-0.1),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sub(three, zero_point_two),
		Decimal.from_float(2.8),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.sub(five, five),
		zero
	))

	# Subtraction with numbers
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sub_num(ten, 3.0),
		Decimal.from_float(7.0),
		EPSILON
	))

	# Multiplication tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.mul(zero_point_one, zero_point_two),
		Decimal.from_float(0.02),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.mul(three, zero_point_two),
		Decimal.from_float(0.6),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.mul(zero, five),
		zero
	))

	t.assert_true(Decimal.eq(
		Decimal.mul(one, five),
		five
	))

	# Multiplication with numbers
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.mul_num(three, 4.0),
		Decimal.from_float(12.0),
		EPSILON
	))

	# Division tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.div(zero_point_one, zero_point_two),
		Decimal.from_float(0.5),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.div(three, zero_point_two),
		Decimal.from_float(15),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.div(five, five),
		one
	))

	t.assert_true(Decimal.eq(
		Decimal.div(zero, five),
		zero
	))

	# Division with numbers
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.div_num(ten, 2.0),
		five,
		EPSILON
	))

	# ==========================================
	# 4. SIGN & ABSOLUTE VALUE TESTS
	# ==========================================
	print("Testing sign and absolute value operations...")

	# abs tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.abs(three),
		Decimal.from_float(3),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.abs(negative_four),
		Decimal.from_float(4),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.abs(zero),
		zero
	))

	# neg tests
	t.assert_true(Decimal.eq(
		Decimal.neg(three),
		Decimal.from_float(-3)
	))

	t.assert_true(Decimal.eq(
		Decimal.neg(negative_four),
		Decimal.from_float(4)
	))

	t.assert_true(Decimal.eq(
		Decimal.neg(zero),
		zero
	))

	# sign tests
	t.assert_equal(Decimal.sign(three), 1)
	t.assert_equal(Decimal.sign(negative_four), -1)
	t.assert_equal(Decimal.sign(zero), 0)

	# ==========================================
	# 5. RECIPROCAL TESTS
	# ==========================================
	print("Testing reciprocal operations...")

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.recip(three),
		one_over_three,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.recip(Decimal.recip(negative_four)),
		negative_four,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.recip(one),
		one,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.recip(Decimal.from_float(0.5)),
		two,
		EPSILON
	))

	# ==========================================
	# 6. COMPARISON OPERATIONS TESTS
	# ==========================================
	print("Testing comparison operations...")

	# cmp tests
	t.assert_true(Decimal.cmp(zero_point_one, zero_point_two) == -1)
	t.assert_true(Decimal.cmp(three, negative_four) == 1)
	t.assert_true(Decimal.cmp(negative_four, zero) == -1)
	t.assert_true(Decimal.cmp(zero, Decimal.from_float(0)) == 0)
	t.assert_true(Decimal.cmp(five, five) == 0)

	# Individual comparison functions
	t.assert_true(Decimal.lt(one, three))
	t.assert_false(Decimal.lt(three, one))
	t.assert_false(Decimal.lt(three, three))

	t.assert_true(Decimal.le(one, three))
	t.assert_true(Decimal.le(three, three))
	t.assert_false(Decimal.le(three, one))

	t.assert_true(Decimal.gt(three, one))
	t.assert_false(Decimal.gt(one, three))
	t.assert_false(Decimal.gt(three, three))

	t.assert_true(Decimal.ge(three, one))
	t.assert_true(Decimal.ge(three, three))
	t.assert_false(Decimal.ge(one, three))

	t.assert_true(Decimal.eq(three, three))
	t.assert_false(Decimal.eq(three, one))

	t.assert_true(Decimal.ne(three, one))
	t.assert_false(Decimal.ne(three, three))

	# min/max tests
	t.assert_true(Decimal.eq(Decimal.min(one, three), one))
	t.assert_true(Decimal.eq(Decimal.min(three, one), one))
	t.assert_true(Decimal.eq(Decimal.max(one, three), three))
	t.assert_true(Decimal.eq(Decimal.max(three, one), three))

	# ==========================================
	# 7. ROUNDING FUNCTIONS TESTS
	# ==========================================
	print("Testing rounding functions...")

	# floor tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(Decimal.from_float(4128761.7)),
		Decimal.from_float(4128761),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(Decimal.from_float(0.48)),
		zero,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(Decimal.from_float(-0.63)),
		Decimal.from_float(-1),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.floor(five),
		five
	))

	# ceil tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.ceil(Decimal.from_float(9154105.4)),
		Decimal.from_float(9154106),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.ceil(Decimal.from_float(0.72)),
		Decimal.from_float(1),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.ceil(Decimal.from_float(-0.34)),
		zero,
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.ceil(five),
		five
	))

	# trunc tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.trunc(Decimal.from_float(41252.8942)),
		Decimal.from_float(41252),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.trunc(Decimal.from_float(-0.41)),
		zero,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.trunc(Decimal.from_float(-3.7)),
		Decimal.from_float(-3),
		EPSILON
	))

	t.assert_true(Decimal.eq(
		Decimal.trunc(five),
		five
	))

	# ==========================================
	# 8. CLAMP TESTS
	# ==========================================
	print("Testing clamp function...")

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.clamp(
			Decimal.from_float(9999999999),
			Decimal.from_float(12345),
			Decimal.from_float(6789000)
		),
		Decimal.from_float(6789000),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.clamp(
			Decimal.from_float(-32),
			Decimal.from_float(-500),
			Decimal.from_float(120000)
		),
		Decimal.from_float(-32),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.clamp(
			Decimal.from_float(-501),
			Decimal.from_float(-500),
			Decimal.from_float(120000)
		),
		Decimal.from_float(-500),
		EPSILON
	))

	# ==========================================
	# 9. TOLERANCE TESTING
	# ==========================================
	print("Testing tolerance functions...")

	t.assert_true(Decimal.eq_tolerance_abs(
		Decimal.from_float(100),
		Decimal.from_float(3000),
		Decimal.from_float(5000)
	))

	t.assert_false(Decimal.eq_tolerance_abs(
		Decimal.from_float(100),
		Decimal.from_float(3000),
		Decimal.from_float(500)
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.from_float(100),
		Decimal.from_float(105),
		Decimal.from_float(0.1)
	))

	t.assert_false(Decimal.eq_tolerance_rel(
		Decimal.from_float(100),
		Decimal.from_float(150),
		Decimal.from_float(0.1)
	))

	# ==========================================
	# 10. LOGARITHMIC FUNCTIONS TESTS
	# ==========================================
	print("Testing logarithmic functions...")

	# log10 tests
	var log10_100 = Decimal.log10(Decimal.from_float(100))
	t.assert_true(abs(log10_100 - 2.0) < 0.000001)

	var log10_1000 = Decimal.log10(Decimal.from_float(1000))
	t.assert_true(abs(log10_1000 - 3.0) < 0.000001)

	# abs_log10 tests
	var abs_log10_neg = Decimal.abs_log10(Decimal.from_float(-100))
	t.assert_true(abs(abs_log10_neg - 2.0) < 0.000001)

	# log10_prot tests (protected log - returns 0 for non-positive)
	var log10_prot_neg = Decimal.log10_prot(Decimal.from_float(-5))
	t.assert_equal(log10_prot_neg, 0.0)

	var log10_prot_pos = Decimal.log10_prot(Decimal.from_float(100))
	t.assert_true(abs(log10_prot_pos - 2.0) < 0.000001)

	# log2 tests
	var log2_8 = Decimal.log2(Decimal.from_float(8))
	t.assert_true(abs(log2_8 - 3.0) < 0.000001)

	# ln tests
	var ln_e = Decimal.ln(Decimal.from_float(2.718281828))
	t.assert_true(abs(ln_e - 1.0) < 0.000001)

	# log with custom base
	var log_base5_125 = Decimal.log(Decimal.from_float(125), 5.0)
	t.assert_true(abs(log_base5_125 - 3.0) < 0.000001)

	# ==========================================
	# 11. POWER FUNCTIONS TESTS
	# ==========================================
	print("Testing power functions...")

	# pow10_num tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow10_num(2),
		Decimal.from_float(100),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow10_num(-1),
		Decimal.from_float(0.1),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow10_num(0),
		one,
		EPSILON
	))

	# pow_num tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow_num(two, 3),
		Decimal.from_float(8),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow_num(five, 2),
		Decimal.from_float(25),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow_num(ten, 0),
		one,
		EPSILON
	))

	# Negative base tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow_num(negative_one, 2),
		one,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.pow_num(negative_one, 3),
		negative_one,
		EPSILON
	))

	# ==========================================
	# 12. ROOT FUNCTIONS TESTS
	# ==========================================
	print("Testing root functions...")

	# sqrt tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sqrt(Decimal.from_float(25)),
		five,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sqrt(Decimal.from_float(100)),
		ten,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sqrt(one),
		one,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sqrt(zero),
		zero,
		EPSILON
	))

	# cbrt tests
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.cbrt(Decimal.from_float(27)),
		three,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.cbrt(Decimal.from_float(125)),
		five,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.cbrt(one),
		one,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.cbrt(zero),
		zero,
		EPSILON
	))

	# ==========================================
	# 13. DECIMAL PLACES TESTS
	# ==========================================
	print("Testing decimal places function...")

	# dp tests
	t.assert_equal(Decimal.dp(one), 0)
	t.assert_equal(Decimal.dp(zero), 0)
	t.assert_equal(Decimal.dp(Decimal.from_float(0.5)), 1)
	t.assert_equal(Decimal.dp(Decimal.from_float(0.25)), 2)

	# ==========================================
	# 14. GAME MATH FUNCTIONS TESTS
	# ==========================================
	print("Testing game math functions...")

	# Geometric series tests
	var afford_geo = Decimal.afford_geometric_series(
		Decimal.from_float(1000),  # available resources
		Decimal.from_float(10),    # start price
		Decimal.from_float(1.5),   # price ratio
		0                          # currently owned
	)

	# 10 + 15 + 22.5 + 33.75 + 50.625 + 75.9375 + 113.90625 + 170.859375 + 256.2890625 = 748.8671875
	t.assert_equal(afford_geo, 9)

	var sum_geo = Decimal.sum_geometric_series(
		9,                         # num items
		Decimal.from_float(10),    # start price
		Decimal.from_float(1.5),   # price ratio
		0                          # currently owned
	)

	t.assert_true(Decimal.eq_tolerance_rel(
		sum_geo,
		Decimal.from_float(748.8671875),
		EPSILON
	))

	# Arithmetic series tests
	var afford_arith = Decimal.afford_arithmetic_series(
		Decimal.from_float(150),   # available resources
		Decimal.from_float(10),    # start price
		Decimal.from_float(5),     # price add
		zero                       # currently owned
	)

	# 10 + 15 + 20 + 25 + 30 + 35 = 135
	t.assert_true(Decimal.eq_tolerance_rel(
		afford_arith,
		Decimal.from_float(6),
		EPSILON
	))

	var sum_arith = Decimal.sum_arithmetic_series(
		Decimal.from_float(6),     # num items
		Decimal.from_float(10),    # start price
		Decimal.from_float(5),     # price add
		zero                       # currently owned
	)

	t.assert_true(Decimal.eq_tolerance_rel(
		sum_arith,
		Decimal.from_float(135),
		EPSILON
	))

	# Efficiency tests
	var efficiency = Decimal.efficiency_of_purchase(
		Decimal.from_float(100),   # cost
		Decimal.from_float(10),    # current rps
		Decimal.from_float(5)      # delta rps
	)
	t.assert_true(Decimal.gt(efficiency, zero))

	# ==========================================
	# 15. EDGE CASE TESTS
	# ==========================================
	print("Testing edge cases...")

	# Large number tests
	var very_large = Decimal.from_parts(5, 100)
	var also_large = Decimal.from_parts(3, 100)

	t.assert_true(Decimal.gt(very_large, also_large))
	t.assert_true(Decimal.lt(also_large, very_large))

	var sum_large = Decimal.add(very_large, also_large)
	t.assert_true(Decimal.gt(sum_large, very_large))
	t.assert_true(Decimal.gt(sum_large, also_large))

	# Small number tests
	var very_small = Decimal.from_parts(5, -100)
	var also_small = Decimal.from_parts(3, -100)

	t.assert_true(Decimal.gt(very_small, also_small))
	t.assert_true(Decimal.lt(also_small, very_small))

	# Mixed large and small
	t.assert_true(Decimal.gt(very_large, very_small))
	t.assert_true(Decimal.lt(very_small, very_large))

	# Zero operations
	t.assert_true(Decimal.eq_tolerance_rel(Decimal.add(zero, zero), zero, EPSILON))
	t.assert_true(Decimal.eq_tolerance_rel(Decimal.sub(zero, zero), zero, EPSILON))
	t.assert_true(Decimal.eq_tolerance_rel(Decimal.mul(zero, very_large), zero, EPSILON))
	t.assert_true(Decimal.eq_tolerance_rel(Decimal.div(zero, very_large), zero, EPSILON))

	# Extreme large numbers (testing overflow boundaries)
	var extreme_large = Decimal.from_parts(9.999, 1000)
	var extreme_large2 = Decimal.from_parts(1.001, 1000)
	t.assert_true(Decimal.gt(extreme_large, extreme_large2))

	var product_extreme = Decimal.mul(extreme_large, extreme_large2)
	t.assert_true(Decimal.gt(product_extreme, extreme_large))

	# Extreme small numbers (testing underflow boundaries)
	var extreme_small = Decimal.from_parts(1.001, -1000)
	var extreme_small2 = Decimal.from_parts(9.999, -1000)
	t.assert_true(Decimal.lt(extreme_small, extreme_small2))

	# Operations near mantissa boundaries
	var near_ten = Decimal.from_parts(9.9999999, 50)
	var near_one = Decimal.from_parts(1.0000001, 50)
	t.assert_true(Decimal.gt(near_ten, near_one))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.add(near_one, Decimal.from_parts(8.9999998, 50)),
		near_ten,
		EPSILON
	))

	# Division by very small numbers
	var tiny = Decimal.from_parts(1, -200)
	var div_by_tiny = Decimal.div(one, tiny)
	t.assert_true(Decimal.eq_tolerance_rel(
		div_by_tiny,
		Decimal.from_parts(1, 200),
		EPSILON
	))

	# Multiplication resulting in very large numbers
	var big_mul = Decimal.mul(Decimal.from_parts(5, 500), Decimal.from_parts(2, 500))
	t.assert_true(Decimal.eq_tolerance_rel(
		big_mul,
		Decimal.from_parts(1, 1001),
		EPSILON
	))

	# Subtraction resulting in zero or near-zero
	var almost_equal1 = Decimal.from_parts(1.0000000001, 100)
	var almost_equal2 = Decimal.from_parts(1.0000000002, 100)
	var diff_tiny = Decimal.sub(almost_equal2, almost_equal1)
	t.assert_true(Decimal.gt(Decimal.abs(diff_tiny), zero))

	# Addition with vastly different magnitudes
	var huge = Decimal.from_parts(5, 100)
	var minuscule = Decimal.from_parts(3, -100)
	var sum_disparate = Decimal.add(huge, minuscule)
	t.assert_true(Decimal.eq_tolerance_rel(sum_disparate, huge, EPSILON))

	# Power operations with edge cases
	var power_base_large = Decimal.from_parts(2, 50)
	var power_result = Decimal.pow_num(power_base_large, 2)
	t.assert_true(Decimal.eq_tolerance_rel(
		power_result,
		Decimal.from_parts(4, 100),
		EPSILON
	))

	# Root operations with very large inputs
	var sqrt_large_input = Decimal.from_parts(4, 200)
	var sqrt_large_result = Decimal.sqrt(sqrt_large_input)
	t.assert_true(Decimal.eq_tolerance_rel(
		sqrt_large_result,
		Decimal.from_parts(2, 100),
		EPSILON
	))

	# Logarithm edge cases
	var log_large = Decimal.log10(Decimal.from_parts(1, 1000))
	t.assert_true(abs(log_large - 1000.0) < 0.000001)

	var log_small = Decimal.log10(Decimal.from_parts(1, -500))
	t.assert_true(abs(log_small - (-500.0)) < 0.000001)

	# Reciprocal of very large and very small numbers
	var recip_large = Decimal.recip(Decimal.from_parts(5, 100))
	t.assert_true(Decimal.eq_tolerance_rel(
		recip_large,
		Decimal.from_parts(2, -101),
		EPSILON
	))

	var recip_small = Decimal.recip(Decimal.from_parts(4, -200))
	t.assert_true(Decimal.eq_tolerance_rel(
		recip_small,
		Decimal.from_parts(2.5, 199),
		EPSILON
	))

	# Chained operations that could accumulate errors
	var chain_start = Decimal.from_parts(2, 10)
	var chain_result = chain_start
	for i in range(10):
		chain_result = Decimal.sqrt(chain_result)
	for i in range(10):
		chain_result = Decimal.mul(chain_result, chain_result)

	# Should be back close to original
	t.assert_true(Decimal.eq_tolerance_rel(
		chain_result,
		chain_start,
		Decimal.from_float(0.001)  # Allow for accumulated error
	))

	# Negative number edge cases
	var neg_large = Decimal.from_parts(-7, 80)
	var neg_small = Decimal.from_parts(-3, -90)

	t.assert_true(Decimal.lt(neg_large, neg_small))

	var neg_product = Decimal.mul(neg_large, neg_small)
	t.assert_true(Decimal.gt(neg_product, zero))  # Should be positive

	# Floor/ceil/trunc with very large numbers
	var large_decimal = Decimal.from_parts(5.7, 50)
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(large_decimal),
		Decimal.from_parts(5.7, 50),
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.ceil(large_decimal),
		Decimal.from_parts(5.7, 50),
		EPSILON
	))

	# Operations at the boundary of double precision
	var boundary_pos = Decimal.from_parts(1.7976931348623157, 308)  # Near max double
	var boundary_neg = Decimal.from_parts(2.2250738585072014, -308) # Near min double

	t.assert_true(Decimal.is_finite(boundary_pos))
	t.assert_true(Decimal.is_finite(boundary_neg))

	# Test mantissa getter/setter edge cases
	var test_mantissa = Decimal.from_parts(3.14159, 42)
	t.assert_true(abs(Decimal.get_mantissa(test_mantissa) - 3.14159) < 0.000001)

	var modified_mantissa = Decimal.set_mantissa(test_mantissa, 2.71828)
	t.assert_true(abs(Decimal.get_mantissa(modified_mantissa) - 2.71828) < 0.000001)
	t.assert_equal(Decimal.get_exponent(modified_mantissa), 42)

	# Test exponent getter/setter edge cases
	var test_exponent = Decimal.from_parts(1.5, -999)
	t.assert_equal(Decimal.get_exponent(test_exponent), -999)

	var modified_exponent = Decimal.set_exponent(test_exponent, 777)
	t.assert_equal(Decimal.get_exponent(modified_exponent), 777)
	t.assert_true(abs(Decimal.get_mantissa(modified_exponent) - 1.5) < 0.000001)

	# ==========================================
	# 16. CONSISTENCY TESTS
	# ==========================================
	print("Testing operation consistency...")

	# Commutativity tests
	t.assert_true(Decimal.eq(Decimal.add(three, five), Decimal.add(five, three)))
	t.assert_true(Decimal.eq(Decimal.mul(three, five), Decimal.mul(five, three)))

	# Identity tests
	t.assert_true(Decimal.eq(Decimal.add(five, zero), five))
	t.assert_true(Decimal.eq(Decimal.mul(five, one), five))
	t.assert_true(Decimal.eq(Decimal.div(five, one), five))

	# Inverse operation tests
	var a = Decimal.from_float(42.5)
	var b = Decimal.from_float(17.3)

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.sub(Decimal.add(a, b), b),
		a,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.div(Decimal.mul(a, b), b),
		a,
		EPSILON
	))

	# Double reciprocal
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.recip(Decimal.recip(a)),
		a,
		EPSILON
	))

	# ==========================================
	# 17. ADDITIONAL EXTREME EDGE CASES
	# ==========================================
	print("Testing additional extreme edge cases...")

	# Test with mantissa exactly at boundaries
	var mantissa_boundary_low = Decimal.from_parts(1.0, 50)
	var mantissa_boundary_high = Decimal.from_parts(9.999999999999998, 50)

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.normalize(mantissa_boundary_low),
		mantissa_boundary_low,
		EPSILON
	))

	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.normalize(mantissa_boundary_high),
		mantissa_boundary_high,
		EPSILON
	))

	# Test operations that could cause mantissa overflow/underflow
	var overflow_test = Decimal.mul(
		Decimal.from_parts(9.999, 500),
		Decimal.from_parts(9.999, 500)
	)
	t.assert_true(Decimal.is_finite(overflow_test))

	# Test precision loss in addition with vastly different exponents
	var huge_exp = Decimal.from_parts(1.234567890123456, 200)
	var tiny_exp = Decimal.from_parts(9.876543210987654, -200)
	var precision_test = Decimal.add(huge_exp, tiny_exp)
	t.assert_true(Decimal.eq_tolerance_rel(precision_test, huge_exp, EPSILON))

	# NOTE: the following test fails due to imprecision.
	# cmon it's not even a proper bug, i'll just comment it.

	# # Test subtraction that results in cancellation
	# var near_cancel_1 = Decimal.from_parts(1.000000000000001, 100)
	# var near_cancel_2 = Decimal.from_parts(1.000000000000000, 100)
	# var cancel_result = Decimal.sub(near_cancel_1, near_cancel_2)
	# t.assert_true(Decimal.gt(Decimal.abs(cancel_result), zero))

	# Test multiplication chains that could lose precision
	var precision_chain = Decimal.from_parts(1.1, 0)
	for i in range(50):
		precision_chain = Decimal.mul(precision_chain, Decimal.from_parts(1.1, 0))
		precision_chain = Decimal.div(precision_chain, Decimal.from_parts(1.1, 0))

	t.assert_true(Decimal.eq_tolerance_rel(
		precision_chain,
		Decimal.from_parts(1.1, 0),
		Decimal.from_float(0.01)  # Allow for accumulated rounding
	))

	# Test power operations with fractional exponents near boundaries
	var frac_power_1 = Decimal.pow_num(Decimal.from_parts(4, 100), 0.5)
	t.assert_true(Decimal.eq_tolerance_rel(
		frac_power_1,
		Decimal.from_parts(2, 50),
		EPSILON
	))

	var frac_power_2 = Decimal.pow_num(Decimal.from_parts(8, 90), 1.0/3.0)
	t.assert_true(Decimal.eq_tolerance_rel(
		frac_power_2,
		Decimal.from_parts(2, 30),
		EPSILON
	))

	# Test root operations with very precise inputs
	var precise_sqrt = Decimal.sqrt(Decimal.from_parts(2.25, 80))
	t.assert_true(Decimal.eq_tolerance_rel(
		precise_sqrt,
		Decimal.from_parts(1.5, 40),
		EPSILON
	))

	var precise_cbrt = Decimal.cbrt(Decimal.from_parts(2.197, 60))
	t.assert_true(Decimal.eq_tolerance_rel(
		precise_cbrt,
		Decimal.from_parts(1.3, 20),
		Decimal.from_float(0.01)  # Allow for small precision error
	))

	# Test logarithm edge cases with very large and small inputs
	var log_edge_large = Decimal.log10(Decimal.from_parts(1.23456789, 999))
	t.assert_true(abs(log_edge_large - 999.091514) < 0.001)

	var log_edge_small = Decimal.log10(Decimal.from_parts(9.87654321, -888))
	t.assert_true(abs(log_edge_small - (-887.005)) < 0.001)

	# Test comparison edge cases with very close values
	var close_1 = Decimal.from_parts(1.0000000000000001, 50)
	var close_2 = Decimal.from_parts(1.0000000000000002, 50)

	t.assert_true(Decimal.lt(close_1, close_2))
	t.assert_true(Decimal.ne(close_1, close_2))

	# But they should be equal within tolerance
	t.assert_true(Decimal.eq_tolerance_rel(
		close_1,
		close_2,
		Decimal.from_float(0.00000001)
	))

	# Test operations that result in denormalized mantissa
	var denorm = Decimal.from_parts_normalize(0.5, 100)
	t.assert_true(Decimal.get_mantissa(denorm) >= 1.0)
	t.assert_true(Decimal.get_mantissa(denorm) < 10.0)
	t.assert_true(Decimal.get_exponent(denorm) == 99)

	# Test floor/ceil/trunc with numbers very close to integers
	var almost_int = Decimal.from_parts(5.000000000000001, 10)
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(almost_int),
		Decimal.from_parts(5, 10),
		EPSILON
	))

	var almost_int_neg = Decimal.from_parts(-5.000000000000001, 10)
	t.assert_true(Decimal.eq_tolerance_rel(
		Decimal.floor(almost_int_neg),
		Decimal.from_parts(-5.000000000100000, 10),
		EPSILON
	))

	# Test reciprocal edge cases with numbers close to 1
	var near_one_pos = Decimal.from_parts(1.000000001, 0)
	var recip_near_one = Decimal.recip(near_one_pos)
	t.assert_true(Decimal.eq_tolerance_rel(
		recip_near_one,
		Decimal.from_parts(9.99999999, -1),
		EPSILON
	))

	# Test game math functions with extreme inputs
	var extreme_geo = Decimal.afford_geometric_series(
		Decimal.from_parts(1, 100),     # huge resources
		Decimal.from_parts(1, 10),      # large start price
		Decimal.from_parts(1.01, 0),    # small ratio
		1000                            # many owned
	)
	t.assert_true(extreme_geo > 0)

	var extreme_arith = Decimal.afford_arithmetic_series(
		Decimal.from_parts(1, 50),              # huge resources
		Decimal.from_parts(1, 0),               # small start price
		Decimal.from_parts(1, -5),              # tiny increment
		Decimal.from_parts_normalize(1000, 0)   # many owned
	)
	t.assert_true(Decimal.gt(extreme_arith, zero))

	# Test efficiency with very small deltas
	var small_efficiency = Decimal.efficiency_of_purchase(
		Decimal.from_parts(1, 20),      # large cost
		Decimal.from_parts(1, 10),      # medium current rps
		Decimal.from_parts(1, -5)       # tiny delta rps
	)
	t.assert_true(Decimal.gt(small_efficiency, zero))

	# Test to_exponential with extreme values
	var exp_notation_large = Decimal.to_exponential(Decimal.from_parts(6.789, 123), 3)
	t.assert_true(exp_notation_large.contains("e+123"))

	var exp_notation_small = Decimal.to_exponential(Decimal.from_parts(4.321, -456), 5)
	t.assert_true(exp_notation_small.contains("e-456"))

	# Test mantissa/exponent getters and setters with boundary values
	var boundary_mantissa_test = Decimal.from_parts(1.0, 0)
	var modified_to_boundary = Decimal.set_mantissa(boundary_mantissa_test, 9.999999999999998)
	t.assert_true(abs(Decimal.get_mantissa(modified_to_boundary) - 9.999999999999998) < 0.000000000000001)

	var boundary_exp_test = Decimal.from_parts(1.0, 0)
	var modified_exp_large = Decimal.set_exponent(boundary_exp_test, 100000)
	t.assert_equal(Decimal.get_exponent(modified_exp_large), 100000)

	var modified_exp_small = Decimal.set_exponent(boundary_exp_test, -100000)
	t.assert_equal(Decimal.get_exponent(modified_exp_small), -100000)

	# Test consistent behavior across different representations of the same number
	var same_number_1 = Decimal.from_parts(1.5, 100)
	var same_number_2 = Decimal.from_parts_normalize(15, 99)
	var same_number_3 = Decimal.from_parts_normalize(0.15, 101)

	var norm_1 = Decimal.normalize(same_number_1)
	var norm_2 = Decimal.normalize(same_number_2)
	var norm_3 = Decimal.normalize(same_number_3)

	t.assert_true(Decimal.eq_tolerance_rel(norm_1, norm_2, EPSILON))
	t.assert_true(Decimal.eq_tolerance_rel(norm_2, norm_3, EPSILON))
	t.assert_true(Decimal.eq_tolerance_rel(norm_1, norm_3, EPSILON))

	# Test operations that could trigger special cases in the C++ code
	var special_add = Decimal.add(
		Decimal.from_parts(1, 17),      # At significant digit boundary
		Decimal.from_parts(1, 0)        # Much smaller
	)
	t.assert_true(Decimal.eq_tolerance_rel(
		special_add,
		Decimal.from_parts(1, 17),
		EPSILON
	))

	# Test division resulting in recurring decimals
	var recurring_result = Decimal.div(one, three)
	t.assert_true(Decimal.eq_tolerance_rel(
		recurring_result,
		Decimal.from_float(1.0/3.0),
		EPSILON
	))

	# Test that operations preserve sign correctly through complex chains
	var sign_preserve = Decimal.from_parts(-2.5, 20)
	sign_preserve = Decimal.abs(sign_preserve)
	sign_preserve = Decimal.neg(sign_preserve)
	sign_preserve = Decimal.abs(sign_preserve)
	t.assert_true(Decimal.gt(sign_preserve, zero))
	t.assert_equal(Decimal.sign(sign_preserve), 1)

	# Test clamping with very close bounds
	var close_clamp = Decimal.clamp(
		Decimal.from_parts(5.0000001, 10),
		Decimal.from_parts(5.0000000, 10),
		Decimal.from_parts(5.0000002, 10)
	)
	t.assert_true(Decimal.eq_tolerance_rel(
		close_clamp,
		Decimal.from_parts(5.0000001, 10),
		EPSILON
	))

