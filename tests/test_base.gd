# taken from godot-cpp/test/project/test_base.gd
# i edited the __get_stack_frame() impl to use inequality instead.
# idk why it's the other way around in the original implementation
# maybe a bug? TODO: look into that
extends Node

var test_passes := 0
var test_failures := 0

func __get_stack_frame():
	var me = get_script()
	for s in get_stack():
		if s.source != me.resource_path:
			return s
	return null

func __assert_pass():
	test_passes += 1

func __assert_fail():
	test_failures += 1
	var s = __get_stack_frame()
	if s != null:
		print_rich ("[color=red] == FAILURE: In function %s() from '%s' on line %s[/color]" % [s.function, s.source, s.line])

		var file = FileAccess.open(s.source, FileAccess.READ).get_as_text()

		var fn = ""
		var idx = s.line - 1
		var paran_balance = 0
		while true:
			var line = file.get_slice('\n', idx)
			fn += line + '\n'
			paran_balance += line.count('(') - line.count(')')
			if paran_balance <= 0: break
			idx += 1

		print(fn)
	else:
		print_rich ("[color=red] == FAILURE (run with --debug to get more information!) ==[/color]")

func assert_equal(actual, expected):
	if actual == expected:
		__assert_pass()
	else:
		__assert_fail()
		print ("    |-> Expected '%s' but got '%s'" % [expected, actual])

func assert_true(v):
	assert_equal(v, true)

func assert_false(v):
	assert_equal(v, false)

func assert_not_equal(actual, expected):
	if actual != expected:
		__assert_pass()
	else:
		__assert_fail()
		print ("    |-> Expected '%s' NOT to equal '%s'" % [expected, actual])

func exit_code_with_status() -> int:
	var success: bool = (test_failures == 0)
	print ("")
	print_rich ("[color=%s] ==== TESTS FINISHED ==== [/color]" % ("green" if success else "red"))
	print ("")
	print_rich ("   PASSES: [color=green]%s[/color]" % test_passes)
	print_rich ("   FAILURES: [color=red]%s[/color]" % test_failures)
	print ("")

	if success:
		print_rich("[color=green] ******** PASSED ******** [/color]")
	else:
		print_rich("[color=red] ******** FAILED ********[/color]")
	print("")

	return 0 if success else 1

