extends Resource
class_name Numberclass

static var equate_tolerance: float = 1e-6 
static var before_sci_cut: int = 5
static var before_sci_cut_exponent: int = 3
static var cut_off_1E: bool = true
static var e_char: String = 'e'
static var _log_ten: float = log(10)

#region Constants

static var E: Numberclass = new(2.7182818284590451)
static var ZERO: Numberclass = new()
static var ONE: Numberclass = new(1)
static var TWO: Numberclass = new(2)

#endregion

var _mantissa: float = 0
var _exponent: float = 0

#region Creation

func _init(mantissa: float = 0, exponent: float = 0):
	_update(mantissa, exponent)
	
func _update(mantissa: float = 0, exponent: float = 0):
	if is_nan(mantissa) or is_nan(exponent) or is_inf(mantissa) or is_inf(exponent) or mantissa == 0:
		return
	
	var is_neg: bool = mantissa < 0
	if is_neg:
		mantissa = -mantissa
		
	var log = floor((log(mantissa) / _log_ten))
	mantissa /= pow(10, log)
	if is_neg:
		mantissa = -mantissa
	
	if is_nan(mantissa) or is_nan(exponent):
		mantissa = NAN
		exponent = NAN
	
	_mantissa = mantissa
	_exponent = exponent + log
	
static func from_string(text: String) -> Numberclass:
	if not text.contains('e'): return new(float(text))
	var split = text.split('e')
	assert(split.size() <= 3)
	
	if split.size() == 2: return new(float(split[0]), float(split[1]))
	else: return new(float(split[0]), (float(split[1]) if split[1] != "" else 1) * pow(10, float(split[2])))
	
#endregion
	
#region Arithmetic Operators
	
func inc() -> Numberclass: return add(ONE)
func dec() -> Numberclass: return sub(ONE)
	
func addf(num: float) -> Numberclass: return add(new(num))
func add(num: Numberclass) -> Numberclass:
	var delta: float = exponential_delta(num)
	if delta > 7: return self.max(num)
	
	var min: Numberclass = self.min(num)
	var max: Numberclass = self.max(num)
	return new(max._mantissa + min._mantissa / pow(10, delta), max._exponent)
	
func subf(num: float) -> Numberclass: return sub(new(num))
func sub(num: Numberclass) -> Numberclass:
	if equals(num): return ZERO
		
	var delta: float = exponential_delta(num)
	
	if delta > 7: return self if gt(num) else num.negate()
		
	if gt(num): return new(_mantissa - num._mantissa / pow(10, delta), _exponent)
	else: return new(_mantissa / pow(10, delta) - num._mantissa, num._exponent)
	
func mulf(num: float) -> Numberclass: return mul(new(num))
func mul(num: Numberclass) -> Numberclass:
	if equals(ZERO) or num.equals(ZERO): return ZERO
	if equals(ONE): return num
	if num.equals(ONE): return self
	return new(_mantissa * num._mantissa, _exponent + num._exponent)
	
func divf(num: float) -> Numberclass: return div(new(num))
func div(num: Numberclass) -> Numberclass:
	assert(num.not_equals(ZERO))
	if equals(ZERO): return ZERO
	if num.equals(ONE): return self
	return new(_mantissa / num._mantissa, _exponent - num._exponent)


func powf(num: float) -> Numberclass: return self.pow(new(num))
func pow(num: Numberclass) -> Numberclass:
	if equals(ONE) or num.equals(ONE) or equals(ZERO): return self
	if num.equals(ZERO): return ONE
	if _exponent == 0 and num._exponent == 0: return new(pow(_mantissa, num._mantissa))
	
	var temp_exponent = _exponent + log(_mantissa) / _log_ten
	if max(log(_exponent) / _log_ten, 0) + num._exponent < 300:
		temp_exponent *= num.get_real_mantissa()
		if temp_exponent < 1e17: return new(pow(10, fmod(temp_exponent, 1)), floorf(temp_exponent))
		else: new(_mantissa, temp_exponent)
		
	return new(_mantissa, log(temp_exponent) / _log_ten + (num._exponent + log(num._exponent) / _log_ten))
	
func root(base: int):
	var mod = fmod(_exponent, base)
	return new(pow(_mantissa * pow(10, mod), 1. / base), (_exponent - mod) / base)
	
func sqrt(): return root(2)
func cgrt(): return root(3)
func log(): return logN(E)
func logNf(base: float) -> Numberclass: return logN(new(base))
func logN(base: Numberclass): return ZERO if equals(ZERO) else log10() / base.log10()
func log2(): return logN(TWO)
func log10(): return _exponent + log(_mantissa) / _log_ten
	
#endregion
	
#region Bool Operators
	
func equalsf(num: float) -> bool: return equals(new(num))
func not_equalsf(num: float) -> bool: return not_equals(new(num))
func equals(num: Numberclass) -> bool: return _exponent == num._exponent and absf(_mantissa - num._mantissa) < equate_tolerance
func not_equals(num: Numberclass) -> bool: return not equals(num)

func lt(num: Numberclass) -> bool: return less_than(num)
func ltf(num: float) -> bool: return less_than(new(num))
func less_thanf(num: float) -> bool: return less_than(new(num))
	
func less_than(num: Numberclass) -> bool:
	var delta: float = exponential_delta(num)
	if delta < 6: return get_real_mantissa() < num.get_real_mantissa()
	else: return _exponent < num._exponent
	
func gt(num: Numberclass) -> bool: return greater_than(num)
func gtf(num: float) -> bool: return greater_than(new(num))
func greater_thanf(num: float) -> bool: return greater_than(new(num))
	
func greater_than(num: Numberclass) -> bool:
	var delta: float = exponential_delta(num)
	if delta < 6: return get_real_mantissa() > num.get_real_mantissa()
	else: return _exponent > num._exponent
	
func lte(num: Numberclass) -> bool: return less_than_or_equal_to(num)
func ltef(num: float) -> bool: return less_than_or_equal_to(new(num))
func less_than_or_equal_tof(num: float) -> bool: return less_than_or_equal_to(new(num))
func less_than_or_equal_to(num: Numberclass) -> bool: return less_than(num) or equals(num)
func gte(num: Numberclass) -> bool: return greater_than_or_equal_to(num)
func gtef(num: float) -> bool: return less_than_or_equal_to(new(num))
func greater_than_or_equal_tof(num: float) -> bool: return less_than_or_equal_to(new(num))
func greater_than_or_equal_to(num: Numberclass) -> bool: return greater_than(num) or equals(num)
	
#endregion
	
#region Misc Operators

func clone() -> Numberclass: return new(_mantissa, _exponent)
func is_nan() -> bool: return is_nan(_mantissa) or is_nan(_exponent)
func is_neg() -> bool: return _mantissa < 0
func get_real_mantissa() -> float: return 1.79e308 if _exponent > 308  else _mantissa * pow(10, _exponent)
func maxf(base: float) -> Numberclass: return self.max(new(base))
func minf(base: float) -> Numberclass: return self.min(new(base))
func max(num: Numberclass) -> Numberclass: return self if gt(num) else num
func min(num: Numberclass) -> Numberclass: return self if lt(num) else num
func negate() -> Numberclass: return Numberclass.new(-_mantissa, _exponent)
func ceiling() -> Numberclass: return Numberclass.new(ceilf(_mantissa), _exponent)
func floor() -> Numberclass: return Numberclass.new(floorf(_mantissa), _exponent)
func round() -> Numberclass: return Numberclass.new(roundf(_mantissa), _exponent)
func abs() -> Numberclass: return Numberclass.new(absf(_mantissa), _exponent)
func exponential_delta(num: Numberclass) -> float: return absf(_exponent - num._exponent)
	
func _to_string() -> String:
	if _exponent <= before_sci_cut and _exponent < 15:
		return _format_commas(get_real_mantissa())
	
	var exponent_exponent: float = floor(log(_exponent) / _log_ten)
	var exponent_mantissa: float = _exponent / pow(10, exponent_exponent)
	
	if exponent_exponent <= before_sci_cut_exponent:
		return "%s%s%s" % [_trim_decimal("%.2f" % _mantissa), e_char, _format_commas(_exponent)]
	
	if cut_off_1E and exponent_mantissa == 1:
		return "%s%s%s%s" % [_get_mantissa_if_reasonable(exponent_exponent), e_char, e_char, _format_commas(exponent_exponent)]
	return "%s%s%s%s%s" % [_get_mantissa_if_reasonable(exponent_exponent), e_char, _trim_decimal("%.2f" % exponent_mantissa), e_char, _format_commas(exponent_exponent)]
	
func _format_commas(number: float) -> String:
	if _exponent < 3: return _trim_decimal("%.3f" % number)
	
	var output: String = ""
	var num: String = "%d" % (abs(round(number)))
	var dec: String = "%.2f" % fmod(number, 1)
	
	if _mantissa < 0:
		output += '-'
	
	for i in range(0, num.length()):
		if i != 0 and i % 3 == num.length() % 3:
			output += ','
		output += num[i]
	
	if _exponent < 9:
		output += dec.substr(1)
	
	return _trim_decimal(output)
	
func _trim_decimal(str: String): return str.rstrip("0").trim_suffix('.') if str.contains('.') else str
func _get_mantissa_if_reasonable(exponent_exponent: float) -> String: return "%.2f" % _mantissa if exponent_exponent <= 15 else ""
	
#endregion
