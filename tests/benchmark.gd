## Namespace for some benchmarking utilities
##
## A set of functions for benchmarking, comparing and visualizing the performance of a group of
## functions in effective ways. You can use static arguments for the functions, or even generate
## the arguments on the fly.
##
## [codeblock]
## var adder := func basic_addition(a: int, b: int):
##     return a + b
## 
## var arg_generator := func(i: int):
##     # You'll usually want to use seeded randomness so that all
##     # benchmarks use the same numbers and stay more fair.
##     var a: = rand_from_seed(i)[0]
##     var b: = rand_from_seed(i + 10000000)[0]
##     return [a, b]
## 
## var bench := Benchmark.benchmark_with_arg_generator(adder, arg_generator)
## Benchmark.print_results([bench])
## [/codeblock]
## When running this, the output will look like this:
## [codeblock lang=text]
## Benchmark results:
##  1. basic_addition   1.91 µs ± 3.14 µs   1.00 µs … 22.00 µs   100 runs
## [/codeblock]

class_name Benchmark extends Object

func _init() -> void:
	push_error("the `Benchmark` class isn't meant to be instantiated.")
	free()

class BenchResults:
	var label: StringName   ## The label used to identify the results in the output
	var run_count: int      ## Specifies how many runs were done
	var total_time: float   ## Sum of the lengths of all runs
	
	var mean: float        ## Average length of all runs
	var stddev: float      ## Standard derivation of all runs
	var min_len: float     ## Length of the fastest run
	var max_len: float     ## Length of the slowest run
	
	func _calculate_standard_deviation(times: PackedFloat64Array) -> void:
		var variance := 0.0
		for t in times:
			variance += (t - mean) * (t - mean)
		variance /= times.size()
		
		self.stddev = sqrt(variance)

	func _calculate_min(times: PackedFloat64Array) -> void:
		var x := INF
		for t in times: x = min(x, t)
		self.min_len = x

	func _calculate_max(times: PackedFloat64Array) -> void:
		var x := -INF
		for t in times: x = max(x, t)
		self.max_len = x

	func _init(label_: StringName, times_: PackedFloat64Array, total_time_: float) -> void:
		self.label = label_
		self.run_count = times_.size()
		self.total_time = total_time_
		
		self.mean = total_time_ / times_.size()
		_calculate_standard_deviation(times_)
		_calculate_min(times_)
		_calculate_max(times_)

## Takes a [param function] and calls it [param count_cap] times or until [param time_cap] seconds
## pass, whichever happens first. Function always takes the same arguments from [param args], which
## should hold an array of the arguments.[br][br]
## [param custom_label] can be used to modify the label that appears next to the results. If
## unsupplied, the function name is used instead.
static func benchmark_with_args(
	function: Callable,  # func(<args>) -> ...
	args: Array, # func(call_index: int) -> [<args>]
	count_cap: int = 100,
	time_cap: float = INF,
	custom_label: String = "",
	warmup_count: int = 0,
) -> BenchResults:
	var arg_generator := func(_i: int) -> Array:
		return args
	
	return benchmark_with_arg_generator(function, arg_generator, count_cap, time_cap, custom_label, warmup_count)

## Takes a [param function] and calls it [param count_cap] times or until [param time_cap] seconds
## pass, whichever happens first. Arguments are supplied from the result of [param generator],
## which should be a callable that takes the run index ([int]) as an argument, and returns an
## array of arguments to be supplied to [param function] [br][br]
## [param custom_label] can be used to modify the label that appears next to the results. If
## unsupplied, the function name is used instead.
static func benchmark_with_arg_generator(
	function: Callable,  # func(<args>) -> ...
	generator: Callable, # func(call_index: int) -> [<args>]
	count_cap: int = 100,
	time_cap: float = INF,
	custom_label: String = "",
	warmup_count: int = 0,
) -> BenchResults:
	var times := PackedFloat64Array()
	times.resize(count_cap)
	
	var elapsed_total := 0
	
	for i in warmup_count:
		var args: Array = generator.call(i)
		function.bindv(args).call()
	
	var i: int = 0
	while i < count_cap:
		var args: Array = generator.call(i)
		
		var ts_before_call := Time.get_ticks_usec()
		function.bindv(args).call()
		
		var elapsed := Time.get_ticks_usec() - ts_before_call
		times[i] = float(elapsed) / 1_000_000.0
		
		elapsed_total += elapsed
		
		i += 1
		if elapsed_total > time_cap:
			times.resize(i)
			break
	
	var ret := BenchResults.new(
		String(function.get_method()) if custom_label.is_empty() else custom_label,
		times,
		float(elapsed_total) / 1e6
		#float(Time.get_ticks_usec() - start_time) / 1e6
	)
	
	return ret

## Prints the results of one or more benchmarks, supplied within an array.
static func print_results(
	bench_results: Array[BenchResults],
	label: String = "",
	sort: bool = true
) -> void:
	var results: Array[BenchResults] = bench_results.duplicate()
	
	var longest_name_len: int = 0
	for r in results:
		longest_name_len = max(longest_name_len, r.label.length())
	
	if sort:
		results.sort_custom(func(a: BenchResults, b: BenchResults):
			return a.mean < b.mean
		)
	
	if label.is_empty():
		print_rich("[color=orange]Benchmark results:[/color]")
	else:
		print_rich("[color=orange]Benchmark results for \"%s\":[/color]" % label)

	# mfw no destructuring pattern matching syntax
	var up := _decide_unit_and_padding(results)
	var unit: _TimeUnit = up[0]
	var padding: int = up[1]
	
	for i in results.size():
		var res := results[i]
		var res_label := res.label
		
		var strfy = _secs_to_str.bind(unit, padding)
		
		print_rich(
			"[b]", ("%2d. %s" % [i+1, res_label]).rpad(longest_name_len + 4 + 3), "[/b]",
			"[color=green][b]", strfy.call(res.mean), "[/b] ± ", strfy.call(res.stddev), "[/color]",
			"   ",
			"[b][color=cyan]", strfy.call(res.min_len), "[/color] … [color=purple]", strfy.call(res.max_len), "[/color][/b]",
			"   ",
			"%d runs" % res.run_count,
		)

enum _TimeUnit {
	SEC = 0,
	MSEC = 1,
	USEC = 2
}

static func _decide_unit_and_padding(results: Array[BenchResults]) -> Array:
	var max_val: float = -INF
	for res in results:
		max_val = max(max_val, res.mean, res.stddev, res.min_len, res.max_len)
	
	var n: float = log(max_val) / log(10) + 6.0
	
	var unit: _TimeUnit
	if   n < 3: unit = _TimeUnit.USEC
	elif n < 6: unit = _TimeUnit.MSEC
	else      : unit = _TimeUnit.SEC

	var padding := (int(n-1) % 3) + 7
	return [unit, padding]

static func _secs_to_str(time: float, unit: _TimeUnit, padding: int) -> String:
	match unit:
		_TimeUnit.SEC:  return ("%3.2f s"  % (time)).lpad(padding)
		_TimeUnit.MSEC: return ("%3.1f ms" % (time * 1e3)).lpad(padding)
		_TimeUnit.USEC: return ("%3.1f µs" % (time * 1e6)).lpad(padding)
	return "" # unreachable
