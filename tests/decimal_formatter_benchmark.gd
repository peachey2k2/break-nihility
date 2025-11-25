extends SceneTree

## Benchmark suite for DecimalFormatter
## Tests performance across various number ranges and formatting scenarios

var formatter: DecimalFormatter
var formatter_gd: DecimalFormatterGD

func _process(_delta: float) -> bool:
	main()
	return true

func main():
	formatter = DecimalFormatter.new()
	formatter_gd = DecimalFormatterGD.new()
	
	print_rich("[color=cyan]========================================[/color]")
	print_rich("[color=cyan]DecimalFormatter Benchmark Suite[/color]")
	print_rich("[color=cyan]========================================[/color]\n")
	
	benchmark_small_numbers()
	benchmark_medium_numbers()
	benchmark_large_numbers()
	benchmark_very_large_numbers()
	benchmark_extremely_large_numbers()
	benchmark_format_modes()
	benchmark_abbreviation_types()
	benchmark_edge_cases()
	benchmark_string_operations()
	
	print_rich("\n[color=green]All benchmarks completed![/color]")

## Benchmark small numbers (0 - 1,000)
func benchmark_small_numbers():
	print_rich("\n[color=yellow]=== Small Numbers (0 - 1,000) ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	# Test various small numbers
	var small_numbers := [
		Decimal.from_float(0),
		Decimal.from_float(1),
		Decimal.from_float(42),
		Decimal.from_float(123),
		Decimal.from_float(999),
		Decimal.from_float(1000),
		Decimal.from_float(1234.567),
	]
	
	var arg_gen := func(i: int) -> Array:
		return [small_numbers[i % small_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format (small numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format (small numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_full,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format_full (small numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_full,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format_full (small numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format_abbreviated (small numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format_abbreviated (small numbers)"
	))
	
	Benchmark.print_results(results, "Small Numbers")

## Benchmark medium numbers (1K - 1M)
func benchmark_medium_numbers():
	print_rich("\n[color=yellow]=== Medium Numbers (1K - 1M) ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var medium_numbers := [
		Decimal.from_float(1000),
		Decimal.from_float(5000),
		Decimal.from_float(12345),
		Decimal.from_float(123456),
		Decimal.from_float(999999),
		Decimal.from_float(1000000),
	]
	
	var arg_gen := func(i: int) -> Array:
		return [medium_numbers[i % medium_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format (medium numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format_abbreviated (medium numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format (medium numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format_abbreviated (medium numbers)"
	))
	
	Benchmark.print_results(results, "Medium Numbers")

## Benchmark large numbers (1M - 1B)
func benchmark_large_numbers():
	print_rich("\n[color=yellow]=== Large Numbers (1M - 1B) ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var large_numbers := [
		Decimal.from_parts(1.0, 6),   # 1M
		Decimal.from_parts(5.5, 7),   # 55M
		Decimal.from_parts(9.99, 8),   # 999M
		Decimal.from_parts(1.0, 9),   # 1B
	]
	
	var arg_gen := func(i: int) -> Array:
		return [large_numbers[i % large_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format (large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format_abbreviated (large numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format (large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_abbreviated,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format_abbreviated (large numbers)"
	))
	
	Benchmark.print_results(results, "Large Numbers")

## Benchmark very large numbers (1B - 1c)
func benchmark_very_large_numbers():
	print_rich("\n[color=yellow]=== Very Large Numbers (1B - 1c) ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var very_large_numbers := [
		Decimal.from_parts(1.0, 12),  # 1t (trillion)
		Decimal.from_parts(4.2, 15),  # 4.2q (quadrillion)
		Decimal.from_parts(7.7, 30),  # 7.7n (nonillion)
		Decimal.from_parts(9.9, 60),  # 9.9N (Novendecillion)
		Decimal.from_parts(5.5, 66),  # 5.5c (unvigintillion)
	]
	
	var arg_gen := func(i: int) -> Array:
		return [very_large_numbers[i % very_large_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		2.0,
		"DecimalFormatter.format (very large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_abbreviated,
		arg_gen,
		1000,
		2.0,
		"DecimalFormatter.format_abbreviated (very large numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		2.0,
		"DecimalFormatterGD.format (very large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_abbreviated,
		arg_gen,
		1000,
		2.0,
		"DecimalFormatterGD.format_abbreviated (very large numbers)"
	))
	
	Benchmark.print_results(results, "Very Large Numbers")

## Benchmark extremely large numbers (beyond 1c, > 10^70)
func benchmark_extremely_large_numbers():
	print_rich("\n[color=yellow]=== Extremely Large Numbers (> 10^70) ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var extremely_large_numbers := [
		Decimal.from_parts(1.0, 70),   # 10^70
		Decimal.from_parts(4.2, 75),   # 4.2 × 10^75
		Decimal.from_parts(9.9, 100),  # 9.9 × 10^100
		Decimal.from_parts(5.5, 150),  # 5.5 × 10^150
		Decimal.from_parts(7.7, 200), # 7.7 × 10^200
	]
	
	var arg_gen := func(i: int) -> Array:
		return [extremely_large_numbers[i % extremely_large_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatter.format (extremely large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_abbreviated,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatter.format_abbreviated (extremely large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_full,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatter.format_full (extremely large numbers)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatterGD.format (extremely large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_abbreviated,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatterGD.format_abbreviated (extremely large numbers)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_full,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatterGD.format_full (extremely large numbers)"
	))
	
	Benchmark.print_results(results, "Extremely Large Numbers")

## Benchmark different format modes
func benchmark_format_modes():
	print_rich("\n[color=yellow]=== Format Modes ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var test_number := Decimal.from_parts(4.2, 15)  # 4.2q
	
	# Test FULL mode
	formatter.format_mode = DecimalFormatter.FORMAT_MODE_FULL
	results.append(Benchmark.benchmark_with_args(
		formatter.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatter.format_mode FULL"
	))

	formatter_gd.format_mode = DecimalFormatterGD.FormatMode.Full
	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatterGD.format_mode FULL"
	))
	
	# Test ABBREVIATED mode
	formatter.format_mode = DecimalFormatter.FormatMode.FORMAT_MODE_ABBREVIATED
	results.append(Benchmark.benchmark_with_args(
		formatter.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatter.format_mode ABBREVIATED"
	))

	formatter_gd.format_mode = DecimalFormatterGD.FormatMode.Abbreviated
	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatterGD.format_mode ABBREVIATED"
	))
	
	# Test AUTO mode
	formatter.format_mode = DecimalFormatter.FormatMode.FORMAT_MODE_AUTO
	formatter.threshold = Decimal.from_float(1000.0)
	results.append(Benchmark.benchmark_with_args(
		formatter.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatter.format_mode AUTO (large number)"
	))

	formatter_gd.format_mode = DecimalFormatterGD.FormatMode.Auto
	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format,
		[test_number],
		1000,
		1.0,
		"DecimalFormatterGD.format_mode AUTO (large number)"
	))
	
	# Test AUTO mode with small number
	var small_number := Decimal.from_float(500.0)
	results.append(Benchmark.benchmark_with_args(
		formatter.format,
		[small_number],
		1000,
		1.0,
		"DecimalFormatter.format_mode AUTO (small number)"
	))

	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format,
		[small_number],
		1000,
		1.0,
		"DecimalFormatterGD.format_mode AUTO (small number)"
	))
	
	Benchmark.print_results(results, "DecimalFormatter.Format Modes")

## Benchmark different abbreviation types
func benchmark_abbreviation_types():
	print_rich("\n[color=yellow]=== Abbreviation Types ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var test_number := Decimal.from_parts(4.2, 15)  # 4.2q
	
	formatter.format_mode = DecimalFormatter.FormatMode.FORMAT_MODE_ABBREVIATED
	formatter_gd.format_mode = DecimalFormatterGD.FormatMode.Abbreviated
	
	# Test SHORT abbreviations
	formatter.abbreviation_type = DecimalFormatter.AbbreviationType.ABBREVIATION_TYPE_SHORT
	results.append(Benchmark.benchmark_with_args(
		formatter.format_abbreviated,
		[test_number],
		1000,
		1.0,
		"DecimalFormatter.abbreviation_type SHORT"
	))

	formatter_gd.abbreviation_type = DecimalFormatterGD.AbbreviationType.Short
	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format_abbreviated,
		[test_number],
		1000,
		1.0,
		"DecimalFormatterGD.abbreviation_type SHORT"
	))
	
	# Test LONG abbreviations
	formatter.abbreviation_type = DecimalFormatter.AbbreviationType.ABBREVIATION_TYPE_LONG
	results.append(Benchmark.benchmark_with_args(
		formatter.format_abbreviated,
		[test_number],
		1000,
		1.0,
		"DecimalFormatter.abbreviation_type LONG"
	))

	formatter_gd.abbreviation_type = DecimalFormatterGD.AbbreviationType.Long
	results.append(Benchmark.benchmark_with_args(
		formatter_gd.format_abbreviated,
		[test_number],
		1000,
		1.0,
		"DecimalFormatterGD.abbreviation_type LONG"
	))
	
	Benchmark.print_results(results, "Abbreviation Types")

## Benchmark edge cases
func benchmark_edge_cases():
	print_rich("\n[color=yellow]=== Edge Cases ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	var edge_cases := [
		Decimal.from_float(0),
		Decimal.from_float(-1),
		Decimal.from_float(0.0001),
		Decimal.from_parts(1.0, -10),  # Very small
		Decimal.from_parts(-5.5, 15),  # Negative large
	]
	
	var arg_gen := func(i: int) -> Array:
		return [edge_cases[i % edge_cases.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format (edge cases)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_full,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format_full (edge cases)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format (edge cases)"
	))
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_full,
		arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format_full (edge cases)"
	))
	
	Benchmark.print_results(results, "Edge Cases")

## Benchmark string operations (format_full_with_zeroes)
func benchmark_string_operations():
	print_rich("\n[color=yellow]=== String Operations ===[/color]")
	
	var results: Array[Benchmark.BenchResults] = []
	
	# Test format_full_with_zeroes with various sizes
	var zero_test_numbers := [
		Decimal.from_parts(4.3, 10),   # Small - should work fine
		Decimal.from_parts(4.3, 32),   # Medium - reasonable
		Decimal.from_parts(4.3, 50),   # Large - might be slow
		Decimal.from_parts(4.3, 80),   # Very large - should use scientific notation
	]
	
	var arg_gen := func(i: int) -> Array:
		return [zero_test_numbers[i % zero_test_numbers.size()]]
	
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format_full_with_zeroes,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatter.format_full_with_zeroes (various sizes)"
	))

	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format_full_with_zeroes,
		arg_gen,
		1000,
		3.0,
		"DecimalFormatterGD.format_full_with_zeroes (various sizes)"
	))
	
	# Test thousands separator performance
	var separator_test_numbers := [
		Decimal.from_float(1000),
		Decimal.from_float(1000000),
		Decimal.from_float(1234567890),
	]
	
	var sep_arg_gen := func(i: int) -> Array:
		return [separator_test_numbers[i % separator_test_numbers.size()]]
	
	formatter.format_mode = DecimalFormatter.FORMAT_MODE_FULL
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter.format,
		sep_arg_gen,
		1000,
		1.0,
		"DecimalFormatter.format with thousands separators"
	))
	
	formatter_gd.format_mode = DecimalFormatterGD.FormatMode.Full
	results.append(Benchmark.benchmark_with_arg_generator(
		formatter_gd.format,
		sep_arg_gen,
		1000,
		1.0,
		"DecimalFormatterGD.format with thousands separators"
	))
	
	Benchmark.print_results(results, "String Operations")
