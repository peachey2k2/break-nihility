extends SceneTree

func _process(_delta: float) -> bool:
	main()
	# returning true ends the mainloop
	return true


func main() -> void:
	benchmark_random_additions()
	benchmark_random_multiplications()
	benchmark_random_log10()
	benchmark_random_pow()

# we generate 2 numbers in close proximity so we don't hale all of them
# just take the short path and escape early
func benchmark_random_additions() -> void:
	var benchmarks: Array[Benchmark.BenchResults]
	
	var function := func(d1: Vector4i, d2: Vector4i):
		return Decimal.add(d1, d2)
	
	var generator := func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = e1 + (rand_from_seed(i + 300000)[0] % 50) - 25
		return [Decimal.from_parts(m1, e1), Decimal.from_parts(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "break-nihility", 10))
	
	function = func(d1: Big, d2: Big):
		return Big.add(d1, d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = e1 + (rand_from_seed(i + 300000)[0] % 50) - 25
		return [Big.new(m1, e1), Big.new(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "GodotBigNumberClass", 10))
	
	function = func(d1: Numberclass, d2: Numberclass):
		return d1.add(d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = e1 + (rand_from_seed(i + 300000)[0] % 50) - 25
		return [Numberclass.new(m1, e1), Numberclass.new(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "numberclass-gds", 10))
	
	Benchmark.print_results(benchmarks, "random additions")

func benchmark_random_multiplications() -> void:
	var benchmarks: Array[Benchmark.BenchResults]
	
	var function := func(d1: Vector4i, d2: Vector4i):
		return Decimal.mul(d1, d2)
	
	var generator := func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = rand_from_seed(i + 300000)[0]
		return [Decimal.from_parts(m1, e1), Decimal.from_parts(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "break-nihility", 10))
	
	function = func(d1: Big, d2: Big):
		return Big.times(d1, d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = rand_from_seed(i + 300000)[0]
		return [Big.new(m1, e1), Big.new(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "GodotBigNumberClass", 10))
	
	function = func(d1: Numberclass, d2: Numberclass):
		return d1.mul(d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var m2: = fmod(rand_from_seed(i + 100000)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var e2: = rand_from_seed(i + 300000)[0]
		return [Numberclass.new(m1, e1), Numberclass.new(m2, e2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "numberclass-gds", 10))
	
	Benchmark.print_results(benchmarks, "random multiplications")

func benchmark_random_log10() -> void:
	var benchmarks: Array[Benchmark.BenchResults]
	
	var function := func(d1: Vector4i):
		return Decimal.log10(d1)
	
	var generator := func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		return [Decimal.from_parts(m1, e1)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "break-nihility", 10))
	
	# the regular log10 function doesn't work on Big numbers ugh
	function = func(d1: Big):
		return d1.absLog10() 
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		return [Big.new(m1, e1)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "GodotBigNumberClass", 10))
	
	function = func(d1: Numberclass):
		return d1.log10()
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		return [Numberclass.new(m1, e1)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "numberclass-gds", 10))
	
	Benchmark.print_results(benchmarks, "random log10")

func benchmark_random_pow() -> void:
	var benchmarks: Array[Benchmark.BenchResults]
	
	var function := func(d1: Vector4i, d2: float):
		return Decimal.pow_num(d1, d2)
	
	var generator := func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var d2: = (1 / rand_from_seed(i + 300000)[0]) * 100
		return [Decimal.from_parts(m1, e1), d2]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "break-nihility", 10))
	
	function = func(d1: Big, d2: float):
		return Big.powers(d1, d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var d2: = (1 / rand_from_seed(i + 300000)[0]) * 100
		return [Big.new(m1, e1), d2]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "GodotBigNumberClass", 10))
	
	function = func(d1: Numberclass, d2: float):
		return d1.powf(d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var d2: = (1 / rand_from_seed(i + 300000)[0]) * 100
		return [Numberclass.new(m1, e1), d2]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "numberclass-gds (float)", 10))
	
	function = func(d1: Numberclass, d2: Numberclass):
		return d1.pow(d2)
	
	generator = func(i: int):
		var m1: = fmod(rand_from_seed(i)[0] / 1000000.0, 9) + 1
		var e1: = rand_from_seed(i + 200000)[0]
		var d2: = (1 / rand_from_seed(i + 300000)[0]) * 100
		# if we don't do this rn, numberclass will convert it anyway (and perform a bit worse)
		return [Numberclass.new(m1, e1), Numberclass.new(d2)]
	
	benchmarks.append(Benchmark.benchmark_with_arg_generator(function, generator, 1000, INF, "numberclass-gds (obj)", 10))
	
	Benchmark.print_results(benchmarks, "random powers")
