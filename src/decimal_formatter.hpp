#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/variant/vector4i.hpp"

#include <cstdint>
#include <unordered_map>

using namespace godot;

class DecimalFormatter : public RefCounted {

	GDCLASS(DecimalFormatter, RefCounted)

protected:
	static auto _bind_methods() -> void;

public:
	enum FormatMode {
		FORMAT_MODE_FULL,           // Always show full number
		FORMAT_MODE_ABBREVIATED,    // Always show abbreviated
		FORMAT_MODE_AUTO            // Use threshold to decide
	};

	enum AbbreviationType {
		ABBREVIATION_TYPE_SHORT,  // K, M, B, etc.
		ABBREVIATION_TYPE_LONG    // Thousand, Million, Billion, etc.
	};

	DecimalFormatter();
	~DecimalFormatter() = default;

	auto format(const Vector4i decimal) -> String;
	auto format_abbreviated(const Vector4i decimal) -> String;
	auto format_full(const Vector4i decimal) -> String;
	auto format_full_with_zeroes(const Vector4i decimal, const int64_t maximum_exponent = 1000) -> String;

	auto format_number_with_separators(const double value, const int64_t precision = -1) -> String;
	auto add_thousands_separators(const String digits) -> String;

	auto get_abbreviation_for_exponent(const int64_t exponent, const bool use_long = false) -> String;
	auto get_exponent_level(const Vector4i decimal) -> int64_t;

	// Configuration properties
	auto get_format_mode() const -> int64_t { return static_cast<int64_t>(format_mode); }
	auto set_format_mode(const int64_t p_mode) -> void { format_mode = static_cast<FormatMode>(p_mode); }

	auto get_abbreviation_type() const -> int64_t { return static_cast<int64_t>(abbreviation_type); }
	auto set_abbreviation_type(const int64_t p_type) -> void { abbreviation_type = static_cast<AbbreviationType>(p_type); }

	auto get_threshold() const -> Vector4i { return threshold; }
	auto set_threshold(const Vector4i p_threshold) -> void { threshold = p_threshold; }

	auto get_digits_thousands_separator_threshold() const -> int64_t { return digits_thousands_separator_threshold; }
	auto set_digits_thousands_separator_threshold(const int64_t p_threshold) -> void { digits_thousands_separator_threshold = p_threshold; }

	auto get_decimal_places() const -> int64_t { return decimal_places; }
	auto set_decimal_places(const int64_t p_places) -> void { decimal_places = p_places; }

	auto get_thousands_separator() const -> String { return thousands_separator; }
	auto set_thousands_separator(const String p_separator) -> void { thousands_separator = p_separator; }

	auto get_decimal_separator() const -> String { return decimal_separator; }
	auto set_decimal_separator(const String p_separator) -> void { decimal_separator = p_separator; }

	auto get_show_abbreviation_space() const -> bool { return show_abbreviation_space; }
	auto set_show_abbreviation_space(const bool p_show) -> void { show_abbreviation_space = p_show; }

	auto configure(
		const int64_t mode = FORMAT_MODE_AUTO,
		const int64_t abbrev_type = ABBREVIATION_TYPE_SHORT,
		const Vector4i threshold_value = Vector4i(),
		const int64_t decimals = 2,
		const String thousands_sep = ",",
		const String decimal_sep = ".",
		const bool show_space = true
	) -> void;

private:
	static const std::unordered_map<int64_t, std::pair<String, String>> ABBREVIATIONS;

	auto format_number_with_separators_impl(const double value, const int64_t precision) -> String;

	FormatMode format_mode = FORMAT_MODE_AUTO;
	AbbreviationType abbreviation_type = ABBREVIATION_TYPE_SHORT;
	Vector4i threshold;
	int64_t digits_thousands_separator_threshold = 3;
	int64_t decimal_places = 1;
	String thousands_separator = ",";
	String decimal_separator = ".";
	bool show_abbreviation_space = false;
};

