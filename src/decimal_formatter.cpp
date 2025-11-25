#include "decimal_formatter.hpp"
#include "decimal.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/defs.hpp"
#include "godot_cpp/core/error_macros.hpp"
#include "godot_cpp/core/math.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <vector>

using namespace godot;

// Abbreviations map: exponent -> [short, long]
const std::unordered_map<int64_t, std::pair<String, String>> DecimalFormatter::ABBREVIATIONS = {
	{3, {"K", "Thousand"}},
	{6, {"M", "Million"}},
	{9, {"B", "Billion"}},
	{12, {"t", "Trillion"}},
	{15, {"q", "Quadrillion"}},
	{18, {"Q", "Quintillion"}},
	{21, {"s", "Sextillion"}},
	{24, {"S", "Septillion"}},
	{27, {"o", "Octillion"}},
	{30, {"n", "Nonillion"}},
	{33, {"d", "Decillion"}},
	{36, {"U", "Undecillion"}},
	{39, {"D", "Duodecillion"}},
	{42, {"T", "Tredecillion"}},
	{45, {"Qt", "Quattuordecillion"}},
	{48, {"Qd", "Quinquadecillion"}},
	{51, {"Sd", "Sexdecillion"}},
	{54, {"St", "Septendecillion"}},
	{57, {"O", "Octodecillion"}},
	{60, {"N", "Novendecillion"}},
	{63, {"v", "Vigintillion"}},
	{66, {"c", "Unvigintillion"}}
};

auto DecimalFormatter::_bind_methods() -> void {
	ClassDB::bind_method(D_METHOD("format", "decimal"), &DecimalFormatter::format);
	ClassDB::bind_method(D_METHOD("format_abbreviated", "decimal"), &DecimalFormatter::format_abbreviated);
	ClassDB::bind_method(D_METHOD("format_full", "decimal"), &DecimalFormatter::format_full);
	ClassDB::bind_method(D_METHOD("format_full_with_zeroes", "decimal", "maximum_exponent"), &DecimalFormatter::format_full_with_zeroes, DEFVAL(1000));

	ClassDB::bind_method(D_METHOD("format_number_with_separators", "value", "precision"), &DecimalFormatter::format_number_with_separators, DEFVAL(-1));
	ClassDB::bind_method(D_METHOD("add_thousands_separators", "digits"), &DecimalFormatter::add_thousands_separators);

	ClassDB::bind_method(D_METHOD("get_abbreviation_for_exponent", "exponent", "use_long"), &DecimalFormatter::get_abbreviation_for_exponent, DEFVAL(false));
	ClassDB::bind_method(D_METHOD("get_exponent_level", "decimal"), &DecimalFormatter::get_exponent_level);

	// Properties
	ClassDB::bind_method(D_METHOD("get_format_mode"), &DecimalFormatter::get_format_mode);
	ClassDB::bind_method(D_METHOD("set_format_mode", "mode"), &DecimalFormatter::set_format_mode);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "format_mode", PROPERTY_HINT_ENUM, "Full,Abbreviated,Auto"), "set_format_mode", "get_format_mode");

	ClassDB::bind_method(D_METHOD("get_abbreviation_type"), &DecimalFormatter::get_abbreviation_type);
	ClassDB::bind_method(D_METHOD("set_abbreviation_type", "type"), &DecimalFormatter::set_abbreviation_type);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "abbreviation_type", PROPERTY_HINT_ENUM, "Short,Long"), "set_abbreviation_type", "get_abbreviation_type");

	ClassDB::bind_method(D_METHOD("get_threshold"), &DecimalFormatter::get_threshold);
	ClassDB::bind_method(D_METHOD("set_threshold", "threshold"), &DecimalFormatter::set_threshold);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR4I, "threshold"), "set_threshold", "get_threshold");

	ClassDB::bind_method(D_METHOD("get_digits_thousands_separator_threshold"), &DecimalFormatter::get_digits_thousands_separator_threshold);
	ClassDB::bind_method(D_METHOD("set_digits_thousands_separator_threshold", "threshold"), &DecimalFormatter::set_digits_thousands_separator_threshold);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "digits_thousands_separator_threshold"), "set_digits_thousands_separator_threshold", "get_digits_thousands_separator_threshold");

	ClassDB::bind_method(D_METHOD("get_decimal_places"), &DecimalFormatter::get_decimal_places);
	ClassDB::bind_method(D_METHOD("set_decimal_places", "places"), &DecimalFormatter::set_decimal_places);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "decimal_places"), "set_decimal_places", "get_decimal_places");

	ClassDB::bind_method(D_METHOD("get_thousands_separator"), &DecimalFormatter::get_thousands_separator);
	ClassDB::bind_method(D_METHOD("set_thousands_separator", "separator"), &DecimalFormatter::set_thousands_separator);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "thousands_separator"), "set_thousands_separator", "get_thousands_separator");

	ClassDB::bind_method(D_METHOD("get_decimal_separator"), &DecimalFormatter::get_decimal_separator);
	ClassDB::bind_method(D_METHOD("set_decimal_separator", "separator"), &DecimalFormatter::set_decimal_separator);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "decimal_separator"), "set_decimal_separator", "get_decimal_separator");

	ClassDB::bind_method(D_METHOD("get_show_abbreviation_space"), &DecimalFormatter::get_show_abbreviation_space);
	ClassDB::bind_method(D_METHOD("set_show_abbreviation_space", "show"), &DecimalFormatter::set_show_abbreviation_space);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "show_abbreviation_space"), "set_show_abbreviation_space", "get_show_abbreviation_space");

	ClassDB::bind_method(D_METHOD("configure", "mode", "abbrev_type", "threshold_value", "decimals", "thousands_sep", "decimal_sep", "show_space"),
		&DecimalFormatter::configure,
		DEFVAL(FORMAT_MODE_AUTO),
		DEFVAL(ABBREVIATION_TYPE_SHORT),
		DEFVAL(Vector4i()),
		DEFVAL(2),
		DEFVAL(","),
		DEFVAL("."),
		DEFVAL(true)
	);

	// Bind enum constants manually since GetTypeInfo is not specialized for our enum types
	ClassDB::bind_integer_constant(get_class_static(), "FormatMode", "FORMAT_MODE_FULL", static_cast<GDExtensionInt>(FORMAT_MODE_FULL));
	ClassDB::bind_integer_constant(get_class_static(), "FormatMode", "FORMAT_MODE_ABBREVIATED", static_cast<GDExtensionInt>(FORMAT_MODE_ABBREVIATED));
	ClassDB::bind_integer_constant(get_class_static(), "FormatMode", "FORMAT_MODE_AUTO", static_cast<GDExtensionInt>(FORMAT_MODE_AUTO));

	ClassDB::bind_integer_constant(get_class_static(), "AbbreviationType", "ABBREVIATION_TYPE_SHORT", static_cast<GDExtensionInt>(ABBREVIATION_TYPE_SHORT));
	ClassDB::bind_integer_constant(get_class_static(), "AbbreviationType", "ABBREVIATION_TYPE_LONG", static_cast<GDExtensionInt>(ABBREVIATION_TYPE_LONG));
}

DecimalFormatter::DecimalFormatter() {
	threshold = Decimal::from_float(1000.0);
}

auto DecimalFormatter::format(const Vector4i decimal) -> String {
	switch (format_mode) {
		case FORMAT_MODE_FULL:
			return format_full(decimal);
		case FORMAT_MODE_ABBREVIATED:
			return format_abbreviated(decimal);
		case FORMAT_MODE_AUTO:
			if (Decimal::le(decimal, threshold)) {
				return format_full(decimal);
			} else {
				return format_abbreviated(decimal);
			}
	}
	return "";
}

auto DecimalFormatter::format_abbreviated(const Vector4i decimal) -> String {
	if (!Decimal::is_finite(decimal)) {
		return Decimal::to_string(decimal);
	}

	// Fast early check: if exponent field >= 69, definitely beyond 999c
	int64_t decimal_exponent = Decimal::get_exponent(decimal);
	if (decimal_exponent >= 69) {
		return Decimal::to_exponential(decimal, decimal_places);
	}

	// For finding the right abbreviation, we need the actual exponent level
	// If exponent is >= 66, we know it's "c" or beyond
	// Only compute log10 if we need to find which abbreviation to use
	int64_t exponent_level = 0;
	int64_t abbrev_key = 0;

	if (decimal_exponent >= 66) {
		// Already at or beyond "c", check if we need scientific notation
		// If mantissa is large enough, exponent_level could be 69+
		double mantissa = std::abs(Decimal::get_mantissa(decimal));
		if (mantissa >= 9.0 && decimal_exponent >= 68) {
			// Could be >= 69, use scientific notation
			return Decimal::to_exponential(decimal, decimal_places);
		}
		// Otherwise use "c"
		abbrev_key = 66;
	} else {
		// Need to find the right abbreviation - compute log10 only when necessary
		double log10_value = Decimal::log10(decimal);
		exponent_level = static_cast<int64_t>(std::floor(log10_value));

		// Find the appropriate abbreviation (iterate in order)
		// We need to check keys in ascending order
		std::vector<int64_t> keys;
		for (const auto& pair : ABBREVIATIONS) {
			keys.push_back(pair.first);
		}
		std::sort(keys.begin(), keys.end());

		for (int64_t key : keys) {
			if (key <= exponent_level) {
				abbrev_key = key;
			} else {
				break;
			}
		}
	}

	// If no abbreviation found (number too small), format as full
	if (abbrev_key == 0 || abbrev_key < 3) {
		// Number is too small, format as full
		return format_full(decimal);
	}

	// Calculate the value in the abbreviation's units
	// Divide the decimal by 10^abbrev_key to get the value in those units
	Vector4i divisor = Decimal::pow10_num(abbrev_key);
	Vector4i value_in_units_decimal = Decimal::div(decimal, divisor);
	double value_in_units = Decimal::into_float(value_in_units_decimal);

	// Format the mantissa with decimal places
	String formatted_value = format_number_with_separators(value_in_units, decimal_places);

	// Get abbreviation or name
	String abbrev_text = "";
	if (abbreviation_type == ABBREVIATION_TYPE_SHORT) {
		abbrev_text = ABBREVIATIONS.at(abbrev_key).first;
	} else {
		abbrev_text = ABBREVIATIONS.at(abbrev_key).second;
	}

	// Combine
	String separator = show_abbreviation_space ? " " : "";
	return formatted_value + separator + abbrev_text;
}

auto DecimalFormatter::format_full(const Vector4i decimal) -> String {
	if (!Decimal::is_finite(decimal)) {
		return Decimal::to_string(decimal);
	}

	// Fast check using exponent first
	int64_t exponent = Decimal::get_exponent(decimal);

	// If exponent is very large, use scientific notation immediately (avoid expensive log10)
	if (exponent > 15) {
		return Decimal::to_exponential(decimal, decimal_places);
	}

	// For small numbers, check if we can safely convert to float
	// If exponent <= 15 and mantissa is reasonable, we can use into_float
	double mantissa = std::abs(Decimal::get_mantissa(decimal));
	if (exponent <= 15 && mantissa < 1e16) {
		double float_value = Decimal::into_float(decimal);
		return format_number_with_separators(float_value, -1);  // -1 means use default precision
	} else {
		// For edge cases, use exponential notation
		return Decimal::to_exponential(decimal, decimal_places);
	}
}

auto DecimalFormatter::format_full_with_zeroes(const Vector4i decimal, const int64_t maximum_exponent) -> String {
	if (!Decimal::is_finite(decimal)) {
		return Decimal::to_string(decimal);
	}

	double mantissa = Decimal::get_mantissa(decimal);
	int64_t exponent = Decimal::get_exponent(decimal);

	// For very large numbers, use scientific notation
	if (exponent > maximum_exponent) {
		return Decimal::to_exponential(decimal, decimal_places);
	}

	// Handle zero
	if (mantissa == 0.0) {
		return "0";
	}

	// Get the sign
	bool is_negative = mantissa < 0.0;
	double abs_mantissa = std::abs(mantissa);

	// Convert mantissa to string to get all significant digits
	// Use high precision to avoid losing digits
	char mantissa_buf[32];
	std::snprintf(mantissa_buf, sizeof(mantissa_buf), "%.15f", abs_mantissa);
	String mantissa_str = mantissa_buf;

	// Remove trailing zeros after decimal point
	mantissa_str = mantissa_str.rstrip("0");
	// Remove decimal point if no fractional part remains
	if (mantissa_str.ends_with(".")) {
		mantissa_str = mantissa_str.rstrip(".");
	}

	// Split into integer and fractional parts
	PackedStringArray parts = mantissa_str.split(".");
	String integer_part = parts.size() > 0 ? parts[0] : "";
	String fractional_part = parts.size() > 1 ? parts[1] : "";

	// Calculate where the decimal point should be in the final result
	int64_t decimal_position = integer_part.length() + exponent;

	// Build the full number string
	String full_digits = integer_part + fractional_part;

	// If exponent is negative, we need decimal point with leading zeros
	if (decimal_position <= 0) {
		// All digits come after the decimal point
		int64_t leading_zeros_needed = std::abs(decimal_position);

		// Build zeros more efficiently for large counts
		String zeros_str = "";
		if (leading_zeros_needed > 0) {
			if (leading_zeros_needed > maximum_exponent) {
				return Decimal::to_exponential(decimal, decimal_places);
			}
			zeros_str = String("0").repeat(leading_zeros_needed);
		}

		String result = "0" + decimal_separator + zeros_str + full_digits;
		return (is_negative ? "-" : "") + result;
	} else if (decimal_position >= static_cast<int64_t>(full_digits.length())) {
		// All digits are before decimal point, need trailing zeros
		int64_t trailing_zeros_needed = decimal_position - full_digits.length();
		if (trailing_zeros_needed > maximum_exponent) {
			return Decimal::to_exponential(decimal, decimal_places);
		}

		String zeros_str = String("0").repeat(trailing_zeros_needed);
		String result = full_digits + zeros_str;

		// Add thousands separators
		result = add_thousands_separators(result);
		return (is_negative ? "-" : "") + result;
	} else {
		// Decimal point is in the middle of the digits
		String before_decimal = full_digits.substr(0, decimal_position);
		String after_decimal = full_digits.substr(decimal_position);

		// Add thousands separators to integer part
		String formatted_before = add_thousands_separators(before_decimal);
		String result = formatted_before + decimal_separator + after_decimal;
		return (is_negative ? "-" : "") + result;
	}
}

auto DecimalFormatter::format_number_with_separators(const double value, const int64_t precision) -> String {
	return format_number_with_separators_impl(value, precision);
}

auto DecimalFormatter::format_number_with_separators_impl(const double value, const int64_t precision) -> String {
	bool is_negative = value < 0.0;
	double abs_value = std::abs(value);

	// Format the number
	String formatted = "";
	if (precision < 0) {
		// Use default formatting (remove trailing zeros)
		formatted = String::num(abs_value);
		// Remove trailing zeros after decimal point
		if (formatted.contains(".")) {
			formatted = formatted.rstrip("0").rstrip(".");
		}
	} else {
		// Format with specific precision
		char buf[64];
		std::snprintf(buf, sizeof(buf), "%.*f", static_cast<int>(precision), abs_value);
		formatted = buf;
		// When precision is specified, preserve trailing zeros to show exact decimal places
		// Only remove the decimal point if there are no decimal digits
		if (formatted.ends_with(".")) {
			formatted = formatted.rstrip(".");
		}
	}

	// Split into integer and decimal parts
	PackedStringArray parts = formatted.split(".");
	String integer_part = parts.size() > 0 ? parts[0] : "";
	String decimal_part = parts.size() > 1 ? parts[1] : "";

	// Add thousands separators to integer part
	integer_part = add_thousands_separators(integer_part);

	// Combine
	String result = integer_part;
	if (decimal_part.length() > 0) {
		result += decimal_separator + decimal_part;
	}

	return (is_negative ? "-" : "") + result;
}

auto DecimalFormatter::add_thousands_separators(const String digits) -> String {
	if (digits.length() <= static_cast<int64_t>(digits_thousands_separator_threshold)) {
		return digits;
	}

	// Build result by calculating positions
	String result = "";

	for (int64_t i = 0; i < digits.length(); i++) {
		if (i > 0 && (digits.length() - i) % 3 == 0) {
			result += thousands_separator;
		}
		result += digits.substr(i, 1);
	}

	return result;
}

auto DecimalFormatter::get_abbreviation_for_exponent(const int64_t exponent, const bool use_long) -> String {
	auto it = ABBREVIATIONS.find(exponent);
	if (it != ABBREVIATIONS.end()) {
		return use_long ? it->second.second : it->second.first;
	}
	return "";
}

auto DecimalFormatter::get_exponent_level(const Vector4i decimal) -> int64_t {
	if (!Decimal::is_finite(decimal)) {
		return 0;
	}

	double log10_value = Decimal::log10(decimal);
	return static_cast<int64_t>(std::floor(log10_value));
}

auto DecimalFormatter::configure(
	const int64_t mode,
	const int64_t abbrev_type,
	const Vector4i threshold_value,
	const int64_t decimals,
	const String thousands_sep,
	const String decimal_sep,
	const bool show_space
) -> void {
	format_mode = static_cast<FormatMode>(mode);
	abbreviation_type = static_cast<AbbreviationType>(abbrev_type);
	threshold = threshold_value;
	decimal_places = decimals;
	thousands_separator = thousands_sep;
	decimal_separator = decimal_sep;
	show_abbreviation_space = show_space;
}

