class_name DecimalFormatter
extends RefCounted

## A formatter class for Decimal numbers that supports abbreviations, names, and various formatting options.
##
## Usage example:
## [codeblock]
## var formatter = DecimalFormatter.new()
## var number = Decimal.from_float(1234567.89)
## 
## # Format with abbreviation
## formatter.abbreviation_type = DecimalFormatter.AbbreviationType.SHORT
## print(formatter.format(number))  # "1.23 M"
## 
## # Format with full number
## formatter.format_mode = DecimalFormatter.FormatMode.FULL
## print(formatter.format(number))  # "1,234,567.89"
## 
## # Get full number with all zeroes
## var big_number = Decimal.from_parts(4.3, 32)
## print(formatter.format_full_with_zeroes(big_number))  # "430000000000000000000000000000000"
## [/codeblock]

# Formatting configuration
enum FormatMode {
	Full,           # Always show full number
	Abbreviated,    # Always show abbreviated
	Auto            # Use threshold to decide
}

# Abbreviation type
enum AbbreviationType {
	Short,  # K, M, B, etc.
	Long    # Thousand, Million, Billion, etc.
}

# Mapping of exponents to abbreviations and names
# Key: exponent (power of 10), Value: [abbreviation, name]
const Abbreviations := {
	3: ["K", "Thousand"],
	6: ["M", "Million"],
	9: ["B", "Billion"],
	12: ["t", "trillion"],
	15: ["q", "quadrillion"],
	18: ["Q", "Quintillion"],
	21: ["s", "sextillion"],
	24: ["S", "Septillion"],
	27: ["o", "octillion"],
	30: ["n", "nonillion"],
	33: ["d", "decillion"],
	36: ["U", "Undecillion"],
	39: ["D", "Duodecillion"],
	42: ["T", "Tredecillion"],
	45: ["Qt", "quattuordecillion"],
	48: ["Qd", "Quinquadecillion"],
	51: ["Sd", "Sexdecillion"],
	54: ["St", "Septendecillion"],
	57: ["O", "Octodecillion"],
	60: ["N", "Novendecillion"],
	63: ["v", "vigintillion"],
	66: ["c", "unvigintillion"]
}

# Configuration properties
var format_mode: FormatMode = FormatMode.Auto
var abbreviation_type: AbbreviationType = AbbreviationType.Short
var threshold: Vector4i = Decimal.from_float(1000.0) 
## If the number of digits is greater than this, use thousands separators
var digits_thousands_separator_threshold: int = 3
## Number of decimal places for abbreviated format
var decimal_places: int = 1
var thousands_separator: String = ","
var decimal_separator: String = "."
## Space between number and abbreviation
var show_abbreviation_space: bool = false


## Format a Decimal number according to the current configuration
func format(decimal: Vector4i) -> String:
	match format_mode:
		FormatMode.Full:
			return format_full(decimal)
		FormatMode.Abbreviated:
			return format_abbreviated(decimal)
		FormatMode.Auto:
			if Decimal.le(decimal, threshold):
				return format_full(decimal)
			else:
				return format_abbreviated(decimal)
	return ""


## Format number with abbreviation or name
func format_abbreviated(decimal: Vector4i) -> String:
	if not Decimal.is_finite(decimal):
		return Decimal.to_string(decimal)
	
	# If exponent field >= 69, definitely beyond 999c
	# (since mantissa is in [1, 10), actual exponent level >= exponent field)
	var decimal_exponent := Decimal.get_exponent(decimal)
	if decimal_exponent >= 69:
		return Decimal.to_exponential(decimal, decimal_places)
	
	# For finding the right abbreviation, we need the actual exponent level
	# If exponent is >= 66, we know it's "c" or beyond
	# Only compute log10 if we need to find which abbreviation to use
	var exponent_level := 0
	var abbrev_key := 0
	
	if decimal_exponent >= 66:
		# Already at or beyond "c", check if we need scientific notation
		# If mantissa is large enough, exponent_level could be 69+
		var mantissa = abs(Decimal.get_mantissa(decimal))
		if mantissa >= 9.0 and decimal_exponent >= 68:
			# Could be >= 69, use scientific notation
			return Decimal.to_exponential(decimal, decimal_places)
		# Otherwise use "c"
		abbrev_key = 66

	else:
		# Need to find the right abbreviation - compute log10 only when necessary
		var log10_value := Decimal.log10(decimal)
		exponent_level = int(floor(log10_value))
		
		# Find the appropriate abbreviation
		for key in Abbreviations.keys():
			if key <= exponent_level:
				abbrev_key = key
			else:
				break
	
	# If no abbreviation found (number too small), format as full
	if abbrev_key == 0 or abbrev_key < 3:
		# Number is too small, format as full
		return format_full(decimal)
	
	# Calculate the value in the abbreviation's units
	# Divide the decimal by 10^abbrev_key to get the value in those units
	var divisor := Decimal.pow10_num(abbrev_key)
	var value_in_units_decimal := Decimal.div(decimal, divisor)
	var value_in_units := Decimal.into_float(value_in_units_decimal)
	
	# Format the mantissa with decimal places
	var formatted_value := format_number_with_separators(value_in_units, decimal_places)
	
	# Get abbreviation or name
	var abbrev_text := ""
	match abbreviation_type:
		AbbreviationType.Short:
			abbrev_text = Abbreviations[abbrev_key][0]
		AbbreviationType.Long:
			abbrev_text = Abbreviations[abbrev_key][1]
	
	# Combine
	var separator := " " if show_abbreviation_space else ""
	return formatted_value + separator + abbrev_text


## Format number as full string with separators
func format_full(decimal: Vector4i) -> String:
	if not Decimal.is_finite(decimal):
		return Decimal.to_string(decimal)
	
	# Fast check using exponent first
	var exponent := Decimal.get_exponent(decimal)
	
	# If exponent is very large, use scientific notation immediately 
	if exponent > 15:
		return Decimal.to_exponential(decimal, decimal_places)
	
	# For small numbers, check if we can safely convert to float
	# If exponent <= 15 and mantissa is reasonable, we can use into_float
	var mantissa = abs(Decimal.get_mantissa(decimal))
	if exponent <= 15 and mantissa < 1e16:
		var float_value := Decimal.into_float(decimal)
		return format_number_with_separators(float_value, -1)  # -1 means use default precision
	else:
		# For edge cases, use exponential notation
		return Decimal.to_exponential(decimal, decimal_places)


## Get the full number as a string with all zeroes (e.g., 43^32 -> string with all zeros). If the exponent is greater than the [maximum_exponent], use scientific notation.
func format_full_with_zeroes(decimal: Vector4i, maximum_exponent: int = 1000) -> String:
	if not Decimal.is_finite(decimal):
		return Decimal.to_string(decimal)
	
	var mantissa := Decimal.get_mantissa(decimal)
	var exponent := Decimal.get_exponent(decimal)
	
	# For very large numbers, use scientific notation
	if exponent > maximum_exponent:
		return Decimal.to_exponential(decimal, decimal_places)
	
	# Handle zero
	if mantissa == 0.0:
		return "0"
	
	# Get the sign
	var is_negative := mantissa < 0.0
	var abs_mantissa = abs(mantissa)
	
	# Convert mantissa to string to get all significant digits
	# Use high precision to avoid losing digits
	var mantissa_str := ("%.15f" % abs_mantissa)
	
	# Remove trailing zeros after decimal point
	mantissa_str = mantissa_str.rstrip("0")
	# Remove decimal point if no fractional part remains
	if mantissa_str.ends_with("."):
		mantissa_str = mantissa_str.rstrip(".")
	
	# Split into integer and fractional parts
	var parts := mantissa_str.split(".")
	var integer_part := parts[0]
	var fractional_part := parts[1] if parts.size() > 1 else ""
	
	# Count digits in mantissa (integer + fractional)
	# var _total_mantissa_digits := integer_part.length() + fractional_part.length()
	
	# Calculate where the decimal point should be in the final result
	var decimal_position := integer_part.length() + exponent
	
	# Build the full number string
	var full_digits := integer_part + fractional_part
	
	# If exponent is negative, we need decimal point with leading zeros
	if decimal_position <= 0:
		# All digits come after the decimal point
		var leading_zeros_needed = abs(decimal_position)

		# Build zeros more efficiently for large counts
		var zeros_str := ""
		if leading_zeros_needed > 0:
			if leading_zeros_needed > maximum_exponent:
				return Decimal.to_exponential(decimal, decimal_places)
			zeros_str = "0".repeat(leading_zeros_needed)

		var result := "0" + decimal_separator + zeros_str + full_digits
		return ("-" if is_negative else "") + result

	elif decimal_position >= full_digits.length():
		# All digits are before decimal point, need trailing zeros
		var trailing_zeros_needed := decimal_position - full_digits.length()
		if trailing_zeros_needed > maximum_exponent:
			return Decimal.to_exponential(decimal, decimal_places)

		var zeros_str := "0".repeat(trailing_zeros_needed)
		var result := full_digits + zeros_str

		# Add thousands separators
		result = add_thousands_separators(result)
		return ("-" if is_negative else "") + result

	else:
		# Decimal point is in the middle of the digits
		var before_decimal := full_digits.substr(0, decimal_position)
		var after_decimal := full_digits.substr(decimal_position)

		# Add thousands separators to integer part
		var formatted_before := add_thousands_separators(before_decimal)
		var result := formatted_before + decimal_separator + after_decimal
		return ("-" if is_negative else "") + result


## Format a number with decimal and thousands separators
func format_number_with_separators(value: float, precision: int = -1) -> String:
	var is_negative := value < 0.0
	var abs_value = abs(value)
	
	# Format the number
	var formatted := ""
	if precision < 0:
		# Use default formatting (remove trailing zeros)
		formatted = str(abs_value)
		# Remove trailing zeros after decimal point
		if "." in formatted:
			formatted = formatted.rstrip("0").rstrip(".")
	else:
		# Format with specific precision
		formatted = ("%.*f" % [precision, abs_value])
		# When precision is specified, preserve trailing zeros to show exact decimal places
		# Only remove the decimal point if there are no decimal digits
		if formatted.ends_with("."):
			formatted = formatted.rstrip(".")
	
	# Split into integer and decimal parts
	var parts := formatted.split(".")
	var integer_part := parts[0]
	var decimal_part := parts[1] if parts.size() > 1 else ""
	
	# Add thousands separators to integer part
	integer_part = add_thousands_separators(integer_part)
	
	# Combine
	var result := integer_part
	if decimal_part != "":
		result += decimal_separator + decimal_part
	
	return ("-" if is_negative else "") + result


## Add thousands separators to a string of digits
func add_thousands_separators(digits: String) -> String:
	if digits.length() <= digits_thousands_separator_threshold:
		return digits
	
	# Build result by calculating positions
	var result := ""
	
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += thousands_separator
		result += digits[i]
	
	return result


## Get abbreviation for a given exponent
func get_abbreviation_for_exponent(exponent: int, use_long: bool = false) -> String:
	if exponent in Abbreviations:
		return Abbreviations[exponent][1 if use_long else 0]
	return ""

## Get the exponent level for a given Decimal
func get_exponent_level(decimal: Vector4i) -> int:
	if not Decimal.is_finite(decimal):
		return 0
	
	var log10_value := Decimal.log10(decimal)
	return int(floor(log10_value))


## Configure the formatter
func configure(
	mode: FormatMode = FormatMode.Auto,
	abbrev_type: AbbreviationType = AbbreviationType.Short,
	threshold_value: Vector4i = Decimal.from_float(1000.0),
	decimals: int = 2,
	thousands_sep: String = ",",
	decimal_sep: String = ".",
	show_space: bool = true
) -> void:
	format_mode = mode
	abbreviation_type = abbrev_type
	threshold = threshold_value
	decimal_places = decimals
	thousands_separator = thousands_sep
	decimal_separator = decimal_sep
	show_abbreviation_space = show_space
