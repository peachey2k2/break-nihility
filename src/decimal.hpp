#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/variant/vector4i.hpp"

#include <cstdint>
#include <limits>
#include <optional>

using namespace godot;

// We use Vector4i for the underlying data. This is due to
// Godot not having a way to define custom variants. This struct
// essentially automates the bitcasting for this purpose
//
// related proposal: https://github.com/godotengine/godot-proposals/issues/11797
typedef union {
	struct {
		double mantissa;
		int64_t exponent;
	};
	Vector4i raw;
} DecimalData;


class Decimal : public Object {

	GDCLASS(Decimal, Object)

protected:
	static auto _bind_methods() -> void;

// unions are dumb on android so...
#ifdef __ANDROID__
	#define DECIMAL_DECL_CONST inline
#else
	#define DECIMAL_DECL_CONST constexpr const
#endif

private:
	static DECIMAL_DECL_CONST auto DECIMAL_ZERO = DecimalData { 0.0, 0 };
	static DECIMAL_DECL_CONST auto DECIMAL_ZERO_NEG = DecimalData { -0.0, 0 };

	static DECIMAL_DECL_CONST auto DECIMAL_ONE = DecimalData { 1.0, 0 };
	static DECIMAL_DECL_CONST auto DECIMAL_ONE_NEG = DecimalData { -1.0, 0 };

	static DECIMAL_DECL_CONST auto DECIMAL_INF = DecimalData {
		std::numeric_limits<double>::infinity(), 0
	};

	static DECIMAL_DECL_CONST auto DECIMAL_INF_NEG = DecimalData {
		-std::numeric_limits<double>::infinity(), 0
	};

	static DECIMAL_DECL_CONST auto DECIMAL_NAN = DecimalData {
		std::numeric_limits<double>::signaling_NaN(), 0
	};


public:
	static auto from_parts(const double layer, const int64_t exponent) -> Vector4i;
	static auto from_parts_normalize(const double layer, const int64_t exponent) -> Vector4i;
	static auto from_float(double num) -> Vector4i;

	static auto get_mantissa(const Vector4i decimal) -> double;
	static auto set_mantissa(const Vector4i decimal, double v) -> Vector4i;

	static auto get_exponent(const Vector4i decimal) -> int64_t;
	static auto set_exponent(const Vector4i decimal, int64_t v) -> Vector4i;

	Decimal();
	~Decimal() = default;

	static auto into_float(const Vector4i decimal) -> double;
	static auto to_string(const Vector4i decimal) -> String;
	static auto to_exponential(const Vector4i decimal, const int64_t places = -1) -> String;

	static auto normalize(const Vector4i decimal) -> Vector4i;
	static auto is_finite(const Vector4i decimal) -> bool;

	static auto abs(const Vector4i decimal) -> Vector4i;
	static auto neg(const Vector4i decimal) -> Vector4i;
	static auto sign(const Vector4i decimal) -> int64_t;

	static auto add(const Vector4i n1, const Vector4i n2) -> Vector4i;
	static auto add_num(const Vector4i n1, const double n2) -> Vector4i;

	static auto sub(const Vector4i n1, const Vector4i n2) -> Vector4i;
	static auto sub_num(const Vector4i n1, const double n2) -> Vector4i;

	static auto mul(const Vector4i n1, const Vector4i n2) -> Vector4i;
	static auto mul_num(const Vector4i n1, const double n2) -> Vector4i;

	static auto div(const Vector4i n1, const Vector4i n2) -> Vector4i;
	static auto div_num(const Vector4i n1, const double n2) -> Vector4i;

	static auto recip(const Vector4i decimal) -> Vector4i;

	static auto cmp(const Vector4i n1, const Vector4i n2) -> int64_t;
	static auto lt(const Vector4i n1, const Vector4i n2) -> bool;
	static auto le(const Vector4i n1, const Vector4i n2) -> bool;
	static auto gt(const Vector4i n1, const Vector4i n2) -> bool;
	static auto ge(const Vector4i n1, const Vector4i n2) -> bool;
	static auto eq(const Vector4i n1, const Vector4i n2) -> bool;
	static auto ne(const Vector4i n1, const Vector4i n2) -> bool;

	static auto min(const Vector4i n1, const Vector4i n2) -> Vector4i;
	static auto max(const Vector4i n1, const Vector4i n2) -> Vector4i;

	static auto floor(const Vector4i decimal) -> Vector4i;
	static auto ceil(const Vector4i decimal) -> Vector4i;
	static auto trunc(const Vector4i decimal) -> Vector4i;

	static auto clamp(const Vector4i x, const Vector4i lo, const Vector4i hi) -> Vector4i;

	static auto eq_tolerance_abs(const Vector4i n1, const Vector4i n2, const Vector4i epsilon) -> bool;
	static auto eq_tolerance_rel(const Vector4i n1, const Vector4i n2, const Vector4i epsilon) -> bool;

	static auto log10(const Vector4i decimal) -> double;
	static auto abs_log10(const Vector4i decimal) -> double;
	static auto log10_prot(const Vector4i decimal) -> double;

	static auto log2(const Vector4i decimal) -> double;

	static auto log(const Vector4i decimal, const double base) -> double;
	static auto ln(const Vector4i decimal) -> double;

	static auto pow10_num(const double exp) -> Vector4i;

	// static auto pow(const Vector4i base, const Vector4i exp) -> Vector4i;
	static auto pow_num(const Vector4i base, const double exp) -> Vector4i;

	static auto sqrt(const Vector4i base) -> Vector4i;
	static auto cbrt(const Vector4i base) -> Vector4i;

	static auto dp(const Vector4i decimal) -> int64_t;

	static auto afford_geometric_series(
		const Vector4i res_available,
		const Vector4i price_start,
		const Vector4i price_ratio,
		const int64_t current_owned
	) -> int64_t;

	static auto sum_geometric_series (
		const int64_t num_items,
		const Vector4i price_start,
		const Vector4i price_ratio,
		const int64_t current_owned
	) -> Vector4i;

	static auto afford_arithmetic_series(
		const Vector4i res_available,
		const Vector4i price_start,
		const Vector4i price_add,
		const Vector4i current_owned
	) -> Vector4i;

	static auto sum_arithmetic_series(
		const Vector4i num_items,
		const Vector4i price_start,
		const Vector4i price_add,
		const Vector4i current_owned
	) -> Vector4i;

	static auto efficiency_of_purchase(
		const Vector4i cost,
		const Vector4i current_rps,
		const Vector4i delta_rps
	) -> Vector4i;
};

