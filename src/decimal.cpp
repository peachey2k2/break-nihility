#include "decimal.hpp"
#include "godot_cpp/core/defs.hpp"
#include "godot_cpp/core/error_macros.hpp"
#include "godot_cpp/core/math.hpp"
#include "godot_cpp/variant/string.hpp"
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <godot_cpp/core/class_db.hpp>
#include <limits>
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector4i.hpp"

using namespace godot;

// Helper macro to reinterpret the cast easily
#define RCAST_DEC(_vec) \
	(*reinterpret_cast<const DecimalData*>(&_vec))

const int64_t MAX_SIGNIFICANT_DIGITS = 17;

// break_infinity.js keeps this as 9e15, and states that it could be
// set to Number.MAX_SAFE_INTEGER (~9.0072e15) - MAX_SIGNIFICANT_DIGITS
//
// since we use int64_t for exponents instead, this can be WAY higher
const int64_t EXP_LIMIT = INT64_MAX;

const int64_t MIN_DISPLAYABLE_EXP = -9;
const int64_t MAX_DISPLAYABLE_EXP = 9;

const double ROUND_TOLERANCE = 1e-10;

const int64_t DOUBLE_EXP_MIN = -324;
const int64_t DOUBLE_EXP_MAX = 308;
// We use a lookup table for powers of 10 because duh...
// Keep in mind that the lower bound of a double is ~4.9e-324 but we
// cannot include 1e-324 here, so that should be handled separately
const int64_t POW10_OFFSET = 323;
constexpr const double POW10_LOOKUP[] = {
	1e-323, 1e-322, 1e-321, 1e-320, 1e-319, 1e-318, 1e-317, 1e-316, 1e-315, 1e-314, 1e-313, 1e-312, 1e-311, 1e-310, 1e-309, 1e-308, 1e-307, 1e-306, 1e-305, 1e-304, 1e-303, 1e-302, 1e-301, 1e-300, 1e-299, 1e-298, 1e-297, 1e-296, 1e-295, 1e-294, 1e-293, 1e-292, 1e-291, 1e-290, 1e-289, 1e-288, 1e-287, 1e-286, 1e-285, 1e-284, 1e-283, 1e-282, 1e-281, 1e-280, 1e-279, 1e-278, 1e-277, 1e-276, 1e-275, 1e-274, 1e-273, 1e-272, 1e-271, 1e-270, 1e-269, 1e-268, 1e-267, 1e-266, 1e-265, 1e-264, 1e-263, 1e-262, 1e-261, 1e-260, 1e-259, 1e-258, 1e-257, 1e-256, 1e-255, 1e-254, 1e-253, 1e-252, 1e-251, 1e-250, 1e-249, 1e-248, 1e-247, 1e-246, 1e-245, 1e-244, 1e-243, 1e-242, 1e-241, 1e-240, 1e-239, 1e-238, 1e-237, 1e-236, 1e-235, 1e-234, 1e-233, 1e-232, 1e-231, 1e-230, 1e-229, 1e-228, 1e-227, 1e-226, 1e-225, 1e-224, 1e-223, 1e-222, 1e-221, 1e-220, 1e-219, 1e-218, 1e-217, 1e-216, 1e-215, 1e-214, 1e-213, 1e-212, 1e-211, 1e-210, 1e-209, 1e-208, 1e-207, 1e-206, 1e-205, 1e-204, 1e-203, 1e-202, 1e-201, 1e-200, 1e-199, 1e-198, 1e-197, 1e-196, 1e-195, 1e-194, 1e-193, 1e-192, 1e-191, 1e-190, 1e-189, 1e-188, 1e-187, 1e-186, 1e-185, 1e-184, 1e-183, 1e-182, 1e-181, 1e-180, 1e-179, 1e-178, 1e-177, 1e-176, 1e-175, 1e-174, 1e-173, 1e-172, 1e-171, 1e-170, 1e-169, 1e-168, 1e-167, 1e-166, 1e-165, 1e-164, 1e-163, 1e-162, 1e-161, 1e-160, 1e-159, 1e-158, 1e-157, 1e-156, 1e-155, 1e-154, 1e-153, 1e-152, 1e-151, 1e-150, 1e-149, 1e-148, 1e-147, 1e-146, 1e-145, 1e-144, 1e-143, 1e-142, 1e-141, 1e-140, 1e-139, 1e-138, 1e-137, 1e-136, 1e-135, 1e-134, 1e-133, 1e-132, 1e-131, 1e-130, 1e-129, 1e-128, 1e-127, 1e-126, 1e-125, 1e-124, 1e-123, 1e-122, 1e-121, 1e-120, 1e-119, 1e-118, 1e-117, 1e-116, 1e-115, 1e-114, 1e-113, 1e-112, 1e-111, 1e-110, 1e-109, 1e-108, 1e-107, 1e-106, 1e-105, 1e-104, 1e-103, 1e-102, 1e-101, 1e-100, 1e-99, 1e-98, 1e-97, 1e-96, 1e-95, 1e-94, 1e-93, 1e-92, 1e-91, 1e-90, 1e-89, 1e-88, 1e-87, 1e-86, 1e-85, 1e-84, 1e-83, 1e-82, 1e-81, 1e-80, 1e-79, 1e-78, 1e-77, 1e-76, 1e-75, 1e-74, 1e-73, 1e-72, 1e-71, 1e-70, 1e-69, 1e-68, 1e-67, 1e-66, 1e-65, 1e-64, 1e-63, 1e-62, 1e-61, 1e-60, 1e-59, 1e-58, 1e-57, 1e-56, 1e-55, 1e-54, 1e-53, 1e-52, 1e-51, 1e-50, 1e-49, 1e-48, 1e-47, 1e-46, 1e-45, 1e-44, 1e-43, 1e-42, 1e-41, 1e-40, 1e-39, 1e-38, 1e-37, 1e-36, 1e-35, 1e-34, 1e-33, 1e-32, 1e-31, 1e-30, 1e-29, 1e-28, 1e-27, 1e-26, 1e-25, 1e-24, 1e-23, 1e-22, 1e-21, 1e-20, 1e-19, 1e-18, 1e-17, 1e-16, 1e-15, 1e-14, 1e-13, 1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1,
	1,
	1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22, 1e23, 1e24, 1e25, 1e26, 1e27, 1e28, 1e29, 1e30, 1e31, 1e32, 1e33, 1e34, 1e35, 1e36, 1e37, 1e38, 1e39, 1e40, 1e41, 1e42, 1e43, 1e44, 1e45, 1e46, 1e47, 1e48, 1e49, 1e50, 1e51, 1e52, 1e53, 1e54, 1e55, 1e56, 1e57, 1e58, 1e59, 1e60, 1e61, 1e62, 1e63, 1e64, 1e65, 1e66, 1e67, 1e68, 1e69, 1e70, 1e71, 1e72, 1e73, 1e74, 1e75, 1e76, 1e77, 1e78, 1e79, 1e80, 1e81, 1e82, 1e83, 1e84, 1e85, 1e86, 1e87, 1e88, 1e89, 1e90, 1e91, 1e92, 1e93, 1e94, 1e95, 1e96, 1e97, 1e98, 1e99, 1e100, 1e101, 1e102, 1e103, 1e104, 1e105, 1e106, 1e107, 1e108, 1e109, 1e110, 1e111, 1e112, 1e113, 1e114, 1e115, 1e116, 1e117, 1e118, 1e119, 1e120, 1e121, 1e122, 1e123, 1e124, 1e125, 1e126, 1e127, 1e128, 1e129, 1e130, 1e131, 1e132, 1e133, 1e134, 1e135, 1e136, 1e137, 1e138, 1e139, 1e140, 1e141, 1e142, 1e143, 1e144, 1e145, 1e146, 1e147, 1e148, 1e149, 1e150, 1e151, 1e152, 1e153, 1e154, 1e155, 1e156, 1e157, 1e158, 1e159, 1e160, 1e161, 1e162, 1e163, 1e164, 1e165, 1e166, 1e167, 1e168, 1e169, 1e170, 1e171, 1e172, 1e173, 1e174, 1e175, 1e176, 1e177, 1e178, 1e179, 1e180, 1e181, 1e182, 1e183, 1e184, 1e185, 1e186, 1e187, 1e188, 1e189, 1e190, 1e191, 1e192, 1e193, 1e194, 1e195, 1e196, 1e197, 1e198, 1e199, 1e200, 1e201, 1e202, 1e203, 1e204, 1e205, 1e206, 1e207, 1e208, 1e209, 1e210, 1e211, 1e212, 1e213, 1e214, 1e215, 1e216, 1e217, 1e218, 1e219, 1e220, 1e221, 1e222, 1e223, 1e224, 1e225, 1e226, 1e227, 1e228, 1e229, 1e230, 1e231, 1e232, 1e233, 1e234, 1e235, 1e236, 1e237, 1e238, 1e239, 1e240, 1e241, 1e242, 1e243, 1e244, 1e245, 1e246, 1e247, 1e248, 1e249, 1e250, 1e251, 1e252, 1e253, 1e254, 1e255, 1e256, 1e257, 1e258, 1e259, 1e260, 1e261, 1e262, 1e263, 1e264, 1e265, 1e266, 1e267, 1e268, 1e269, 1e270, 1e271, 1e272, 1e273, 1e274, 1e275, 1e276, 1e277, 1e278, 1e279, 1e280, 1e281, 1e282, 1e283, 1e284, 1e285, 1e286, 1e287, 1e288, 1e289, 1e290, 1e291, 1e292, 1e293, 1e294, 1e295, 1e296, 1e297, 1e298, 1e299, 1e300, 1e301, 1e302, 1e303, 1e304, 1e305, 1e306, 1e307, 1e308
};

inline constexpr auto _10_pow(int64_t base) -> double {
	const size_t idx = base + POW10_OFFSET;
	if (unlikely(idx >= sizeof(POW10_LOOKUP) / sizeof(double))) {
		ERR_PRINT("Out of bounds access on lookup table");
		return std::numeric_limits<double>::signaling_NaN();
	}
	return POW10_LOOKUP[base + POW10_OFFSET];
}


auto Decimal::_bind_methods() -> void {
	// The docs for Vector4i specifies: "Note that the values are limited to 32 bits,
	// and unlike Vector4 this cannot be configured with an engine build option."
	//
	// This means Vector4i should always be 16 bytes in size, just like DecimalData.
	//
	// Therefore this should never ever trigger unless Godot decides to rework vectors,
	// or the user messed with the engine code in a dumb way.
	ERR_FAIL_COND_MSG(sizeof(DecimalData) != sizeof(Vector4i),
	  "Size of the inner Decimal struct doesn't match the size of a Vector4i.\n"
	  "If you're seeing this, something went very wrong."
	);

	ClassDB::bind_static_method("Decimal", D_METHOD("from_parts", "mantissa", "exponent"), &Decimal::from_parts);
	ClassDB::bind_static_method("Decimal", D_METHOD("from_parts_normalize", "mantissa", "exponent"), &Decimal::from_parts_normalize);
	ClassDB::bind_static_method("Decimal", D_METHOD("from_float", "num"), &Decimal::from_float);

	ClassDB::bind_static_method("Decimal", D_METHOD("get_mantissa", "decimal"), &Decimal::get_mantissa);
	ClassDB::bind_static_method("Decimal", D_METHOD("set_mantissa", "decimal", "v"), &Decimal::set_mantissa);

	ClassDB::bind_static_method("Decimal", D_METHOD("get_exponent", "decimal"), &Decimal::get_exponent);
	ClassDB::bind_static_method("Decimal", D_METHOD("set_exponent", "decimal", "v"), &Decimal::set_exponent);


	ClassDB::bind_static_method("Decimal", D_METHOD("into_float", "decimal"), &Decimal::into_float);
	ClassDB::bind_static_method("Decimal", D_METHOD("to_string", "decimal"), &Decimal::to_string);
	ClassDB::bind_static_method("Decimal", D_METHOD("to_exponential", "decimal", "places"), &Decimal::to_exponential);

	ClassDB::bind_static_method("Decimal", D_METHOD("normalize", "decimal"), &Decimal::normalize);
	ClassDB::bind_static_method("Decimal", D_METHOD("is_finite", "decimal"), &Decimal::is_finite);

	ClassDB::bind_static_method("Decimal", D_METHOD("abs", "decimal"), &Decimal::abs);
	ClassDB::bind_static_method("Decimal", D_METHOD("neg", "decimal"), &Decimal::neg);
	ClassDB::bind_static_method("Decimal", D_METHOD("sign", "decimal"), &Decimal::sign);

	ClassDB::bind_static_method("Decimal", D_METHOD("add", "d1", "d2"), &Decimal::add);
	ClassDB::bind_static_method("Decimal", D_METHOD("add_num", "d1", "d2"), &Decimal::add_num);

	ClassDB::bind_static_method("Decimal", D_METHOD("sub", "d1", "d2"), &Decimal::sub);
	ClassDB::bind_static_method("Decimal", D_METHOD("sub_num", "d1", "d2"), &Decimal::sub_num);

	ClassDB::bind_static_method("Decimal", D_METHOD("mul", "d1", "d2"), &Decimal::mul);
	ClassDB::bind_static_method("Decimal", D_METHOD("mul_num", "d1", "d2"), &Decimal::mul_num);

	ClassDB::bind_static_method("Decimal", D_METHOD("div", "d1", "d2"), &Decimal::div);
	ClassDB::bind_static_method("Decimal", D_METHOD("div_num", "d1", "d2"), &Decimal::div_num);

	ClassDB::bind_static_method("Decimal", D_METHOD("recip", "decimal"), &Decimal::recip);

	ClassDB::bind_static_method("Decimal", D_METHOD("cmp", "d1", "d2"), &Decimal::cmp);
	ClassDB::bind_static_method("Decimal", D_METHOD("lt", "d1", "d2"), &Decimal::lt);
	ClassDB::bind_static_method("Decimal", D_METHOD("le", "d1", "d2"), &Decimal::le);
	ClassDB::bind_static_method("Decimal", D_METHOD("gt", "d1", "d2"), &Decimal::gt);
	ClassDB::bind_static_method("Decimal", D_METHOD("ge", "d1", "d2"), &Decimal::ge);
	ClassDB::bind_static_method("Decimal", D_METHOD("eq", "d1", "d2"), &Decimal::eq);
	ClassDB::bind_static_method("Decimal", D_METHOD("ne", "d1", "d2"), &Decimal::ne);

	ClassDB::bind_static_method("Decimal", D_METHOD("min", "d1", "d2"), &Decimal::min);
	ClassDB::bind_static_method("Decimal", D_METHOD("max", "d1", "d2"), &Decimal::max);

	ClassDB::bind_static_method("Decimal", D_METHOD("floor", "decimal"), &Decimal::floor);
	ClassDB::bind_static_method("Decimal", D_METHOD("ceil", "decimal"), &Decimal::ceil);
	ClassDB::bind_static_method("Decimal", D_METHOD("trunc", "decimal"), &Decimal::trunc);

	ClassDB::bind_static_method("Decimal", D_METHOD("clamp", "x", "lo", "hi"), &Decimal::clamp);

	ClassDB::bind_static_method("Decimal", D_METHOD("eq_tolerance_abs", "d1", "d2", "epsilon"), &Decimal::eq_tolerance_abs);
	ClassDB::bind_static_method("Decimal", D_METHOD("eq_tolerance_rel", "d1", "d2", "epsilon"), &Decimal::eq_tolerance_rel);

	ClassDB::bind_static_method("Decimal", D_METHOD("log10", "decimal"), &Decimal::log10);
	ClassDB::bind_static_method("Decimal", D_METHOD("abs_log10", "decimal"), &Decimal::abs_log10);
	ClassDB::bind_static_method("Decimal", D_METHOD("log10_prot", "decimal"), &Decimal::log10_prot);

	ClassDB::bind_static_method("Decimal", D_METHOD("log2", "decimal"), &Decimal::log2);

	ClassDB::bind_static_method("Decimal", D_METHOD("log", "decimal", "base"), &Decimal::log);
	ClassDB::bind_static_method("Decimal", D_METHOD("ln", "decimal"), &Decimal::ln);

	ClassDB::bind_static_method("Decimal", D_METHOD("pow10_num", "exp"), &Decimal::pow10_num);

	// ClassDB::bind_static_method("Decimal", D_METHOD("pow", "base", "exp"), &Decimal::pow);
	ClassDB::bind_static_method("Decimal", D_METHOD("pow_num", "base", "exp"), &Decimal::pow_num);

	ClassDB::bind_static_method("Decimal", D_METHOD("sqrt", "base"), &Decimal::sqrt);
	ClassDB::bind_static_method("Decimal", D_METHOD("cbrt", "base"), &Decimal::cbrt);

	ClassDB::bind_static_method("Decimal", D_METHOD("dp", "decimal"), &Decimal::dp);

	ClassDB::bind_static_method("Decimal", D_METHOD("afford_geometric_series", "res_available", "price_start", "price_ratio", "current_owned"), &Decimal::afford_geometric_series);
	ClassDB::bind_static_method("Decimal", D_METHOD("sum_geometric_series", "num_items", "price_start", "price_ratio", "current_owned"), &Decimal::sum_geometric_series);
	ClassDB::bind_static_method("Decimal", D_METHOD("afford_arithmetic_series", "res_available", "price_start", "price_add", "current_owned"), &Decimal::afford_arithmetic_series);
	ClassDB::bind_static_method("Decimal", D_METHOD("sum_arithmetic_series", "num_items", "price_start", "price_add", "current_owned"), &Decimal::sum_arithmetic_series);
	ClassDB::bind_static_method("Decimal", D_METHOD("efficiency_of_purchase", "cost", "current_rps", "delta_rps"), &Decimal::efficiency_of_purchase);
}

auto Decimal::get_mantissa(const Vector4i decimal) -> double {
	return RCAST_DEC(decimal).mantissa;
}
auto Decimal::set_mantissa(const Vector4i decimal, const double v) -> Vector4i {
	auto dec = RCAST_DEC(decimal);
	dec.mantissa = v;
	return dec.raw;
}

auto Decimal::get_exponent(const Vector4i decimal) -> int64_t {
	return RCAST_DEC(decimal).exponent;
}
auto Decimal::set_exponent(const Vector4i decimal, const int64_t v) -> Vector4i {
	auto dec = RCAST_DEC(decimal);
	dec.exponent = v;
	return dec.raw;
}

Decimal::Decimal() {
	ERR_FAIL_MSG("The `Decimal()` constructor isn't meant to be called");
}

auto Decimal::from_parts(const double mantissa, const int64_t exponent) -> Vector4i {
	DecimalData dec = DecimalData (
		mantissa,
		exponent
	);

	if (mantissa == 0 && exponent == 0) {
		return Decimal::DECIMAL_ZERO.raw;
	}

	auto mantissa_abs = std::abs(mantissa);
	if (unlikely(mantissa_abs >= 10.0 || mantissa_abs < 1.0)) {
		WARN_PRINT(
			"Decimal.from_parts() - mantissa has to be in range [1.0, 10.0)\n"
			"called: Decimal.from_parts(" + String::num(mantissa) + ", " + String::num_int64(exponent) + ")\n"
			"Use `Decimal.from_parts_normalize()` to prevent this warning."
		);
		dec.raw = normalize(dec.raw);
	}
	return dec.raw;
}

auto Decimal::from_parts_normalize(const double mantissa, const int64_t exponent) -> Vector4i {
	if (mantissa == 0 && exponent == 0) {
		return Decimal::DECIMAL_ZERO.raw;
	}

	return normalize(DecimalData(
		mantissa,
		exponent
	).raw);
}

auto Decimal::from_float(const double num) -> Vector4i {
	// return from_parts(num, 0);
	return normalize(
		DecimalData(
			num,
			0
		).raw
	);
}

auto Decimal::into_float(const Vector4i decimal) -> double {
	const auto& dec = RCAST_DEC(decimal);
	const auto exp = dec.exponent;

	// if (exp <= DOUBLE_EXP_MAX && exp >= DOUBLE_EXP_MIN) {
	// 	return dec.mantissa * _10_pow(exp);
	// } else {
	// 	return std::nullopt;
	// }
	return dec.mantissa * _10_pow(exp);
}

auto Decimal::to_string(const Vector4i decimal) -> String {
	const auto& dec = RCAST_DEC(decimal);

	if (dec.exponent <= MAX_DISPLAYABLE_EXP && dec.exponent >= MIN_DISPLAYABLE_EXP) {
		const auto num = Decimal::into_float(decimal);

		if (std::isfinite(num)) {
			return String::num(num);
		}
	}

	return to_exponential(dec.raw);
}

// godot has String::num() which does exactly what we want except
// 1. it force-cuts at 14 digits after the dot (we do at 17)
// 2. the implementation is dumb and bloated
// https://github.com/godotengine/godot/blob/8b4b93a82e13cb1b7ea5fa28b39163a6311a0bb3/core/string/ustring.cpp#L1419
auto Decimal::to_exponential(const Vector4i decimal, const int64_t places) -> String {
	// sign, ones digit, dot and null terminator for max length
	static constexpr const uint64_t BUF_MAX = MAX_SIGNIFICANT_DIGITS + 4;

	const auto& dec = RCAST_DEC(decimal);

	const auto pl = places == -1 ?
		dp(from_parts(dec.mantissa, 0)) + 3 :
		// MAX_SIGNIFICANT_DIGITS + 3 :
		Math::clamp(places, int64_t(1), MAX_SIGNIFICANT_DIGITS) + 3;

	char buf[BUF_MAX] = {};

	// eg. +5.316
	memset(buf, '0', BUF_MAX);
	buf[0]  = dec.mantissa >= 0 ? '+' : '-';
	buf[2]  = '.';
	buf[pl] = '\0';

	if (is_finite(dec.raw) == false) return to_string(dec.raw);

	if (dec.mantissa == 0) {
		return &(buf[1]) + String("e+0");
	}

	auto x = std::abs(dec.mantissa);
	buf[1] = '0' | int(std::floor(x));

	for (int i = 3; i < pl; i++) {
		x = std::fmod(x * 10, 10);
		buf[i] = '0' | int(std::floor(x));
	}

	return
		(dec.mantissa >= 0 ? &(buf[1]) : buf) +
		String(dec.exponent >= 0 ? "e+" : "e-") +
		String::num_int64(std::abs(dec.exponent));
}

auto Decimal::normalize(const Vector4i decimal) -> Vector4i {
	const auto& dec = RCAST_DEC(decimal);

	if (dec.mantissa == 0) {
		return Decimal::DECIMAL_ZERO.raw;
	}

	const auto exp_diff = static_cast<int64_t>(std::floor(std::log10(std::abs(dec.mantissa))));

	const auto res = DecimalData(
		unlikely(exp_diff == DOUBLE_EXP_MIN) ?
			dec.mantissa * 10 / _10_pow(DOUBLE_EXP_MIN + 1) :
			dec.mantissa / _10_pow(exp_diff),
		dec.exponent + exp_diff
	);
	return res.raw;
}

auto Decimal::is_finite(const Vector4i decimal) -> bool {
	const auto& dec = RCAST_DEC(decimal);

	return std::isfinite(dec.mantissa);
}

auto Decimal::abs(const Vector4i decimal) -> Vector4i {
	auto dec = RCAST_DEC(decimal);
	dec.mantissa = Math::absd(dec.mantissa);
	return dec.raw;
}

auto Decimal::neg(const Vector4i decimal) -> Vector4i {
	auto dec = RCAST_DEC(decimal);
	dec.mantissa *= -1;
	return dec.raw;
}

auto Decimal::sign(const Vector4i decimal) -> int64_t {
	const auto& dec = RCAST_DEC(decimal);
	return dec.mantissa > 0 ?
		+1 : dec.mantissa < 0 ?
		-1 :
		+0;
}

auto Decimal::add(const Vector4i n1, const Vector4i n2) -> Vector4i {
	const auto& d1 = RCAST_DEC(n1);
	const auto& d2 = RCAST_DEC(n2);

	const auto& d_bigger  = d1.exponent > d2.exponent ? d1 : d2;
	const auto& d_smaller = d1.exponent > d2.exponent ? d2 : d1;

// if the difference in exponents in addition/subtraction is at least
// this much apart, then the smaller number will be simply discarded
// (cuz it wouldn't matter anyway thanks to floating precision)
	if (d_bigger.exponent - d_smaller.exponent >= MAX_SIGNIFICANT_DIGITS) {
		return d_bigger.raw;
	}

	// ?????????????????????
	const auto res = DecimalData (
		std::round(
			1e14 * d_bigger.mantissa +
			1e14 * d_smaller.mantissa * _10_pow(d_smaller.exponent - d_bigger.exponent)),
		d_bigger.exponent - 14
	);

	return normalize(res.raw);
}

auto Decimal::add_num(const Vector4i n1, const double n2) -> Vector4i {
	// it's simply easier to just convert
	return add(n1, from_float(n2));
}

auto Decimal::sub(const Vector4i n1, const Vector4i n2) -> Vector4i {
	return add(n1, neg(n2));
}

auto Decimal::sub_num(const Vector4i n1, const double n2) -> Vector4i {
	return sub(n1, from_float(n2));
}

auto Decimal::mul(const Vector4i n1, const Vector4i n2) -> Vector4i {
	const auto& d1 = RCAST_DEC(n1);
	const auto& d2 = RCAST_DEC(n2);

	const auto res = DecimalData(
		d1.mantissa * d2.mantissa,
		d1.exponent + d2.exponent
	);

	return normalize(res.raw);
}

auto Decimal::mul_num(const Vector4i n1, const double n2) -> Vector4i {
	const auto& d1 = RCAST_DEC(n1);

	const auto res = DecimalData(
		d1.mantissa * n2,
		d1.exponent
	);

	return normalize(res.raw);
}


auto Decimal::div(const Vector4i n1, const Vector4i n2) -> Vector4i {
	return mul(n1, recip(n2));
}

auto Decimal::div_num(const Vector4i n1, const double n2) -> Vector4i {
	// TODO: if n2 is below 1.8e-308, this could cause issues
	return mul_num(n1, 1/n2);
}


auto Decimal::recip(const Vector4i decimal) -> Vector4i {
	// decimal -> [1, 10)
	// 1/decimal -> (0.1, 1] = (1, 10] * 1e-1
	// so we don't really need to normalize.
	// Just do a check to not hit a mantissa of +10 or -10.
	const auto& dec = RCAST_DEC(decimal);

	if (likely(dec.mantissa < 1 || dec.mantissa > -1)) {
		return DecimalData(
			(1/dec.mantissa) * 10,
			-dec.exponent - 1
		).raw;
	} else {
		return DecimalData(
			(1/dec.mantissa),
			-dec.exponent
		).raw;
	}
}

auto Decimal::cmp(const Vector4i n1, const Vector4i n2) -> int64_t {
	const auto& d1 = RCAST_DEC(n1);
	const auto& d2 = RCAST_DEC(n2);

	const auto s1 = sign(n1);
	const auto s2 = sign(n2);

	if (unlikely(s1 * s2 != 1)) {
		// signs are different or at least one of them zero, so we can just compare them
		return s1 > s2 ? +1 :
		       s1 < s2 ? -1 :
		                  0;
	}

	// both have the same sign, but exponent comparison will work in reverse on negatives
	const auto flip = s1;

	return
		d1.exponent > d2.exponent ? +1 * flip :
		d1.exponent < d2.exponent ? -1 * flip :
		d1.mantissa > d2.mantissa ? +1 :
		d1.mantissa < d2.mantissa ? -1 :
		                             0;

}

auto Decimal::lt(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) < 0;
}

auto Decimal::le(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) <= 0;
}

auto Decimal::gt(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) > 0;
}

auto Decimal::ge(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) >= 0;
}

auto Decimal::eq(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) == 0;
}

auto Decimal::ne(const Vector4i n1, const Vector4i n2) -> bool {
	return cmp(n1, n2) != 0;
}


auto Decimal::min(const Vector4i n1, const Vector4i n2) -> Vector4i {
	return lt(n1, n2) ? n1 : n2;
}

auto Decimal::max(const Vector4i n1, const Vector4i n2) -> Vector4i {
	return gt(n1, n2) ? n1 : n2;
}


auto Decimal::floor(const Vector4i decimal) -> Vector4i {
	const auto& dec = RCAST_DEC(decimal);

	if (is_finite(dec.raw) == false) return dec.raw;

	if (dec.exponent < -1) {
		return sign(dec.raw) >= 0 ? DECIMAL_ZERO.raw : DECIMAL_ONE_NEG.raw;
	}

	if (dec.exponent >= MAX_SIGNIFICANT_DIGITS) return dec.raw;

	// into_float cannot fail here
	return from_float(std::floor(into_float(dec.raw)));
}

auto Decimal::ceil(const Vector4i decimal) -> Vector4i {
	const auto& dec = RCAST_DEC(decimal);

	if (is_finite(dec.raw) == false) return dec.raw;

	if (dec.exponent < -1) {
		return sign(dec.raw) >= 0 ? DECIMAL_ONE.raw : DECIMAL_ZERO.raw;
	}

	if (dec.exponent >= MAX_SIGNIFICANT_DIGITS) return dec.raw;

	return from_float(std::ceil(into_float(dec.raw)));
}

auto Decimal::trunc(const Vector4i decimal) -> Vector4i {
	const auto& dec = RCAST_DEC(decimal);

	if (is_finite(dec.raw) == false) return dec.raw;

	if (dec.exponent < 0) return DECIMAL_ZERO.raw;

	if (dec.exponent >= MAX_SIGNIFICANT_DIGITS) return dec.raw;

	return from_float(std::trunc(into_float(dec.raw)));
}


auto Decimal::clamp(const Vector4i x, const Vector4i lo, const Vector4i hi) -> Vector4i {
	ERR_FAIL_COND_V_MSG(gt(lo, hi), x, "Decimal.clamp() - `lo` cannot be greater than `hi`.");
	return min(max(x, lo), hi);
}


auto Decimal::eq_tolerance_abs(const Vector4i n1, const Vector4i n2, const Vector4i epsilon) -> bool {
	const auto diff = abs(sub(n1, n2));
	return le(diff, epsilon);
}

auto Decimal::eq_tolerance_rel(const Vector4i n1, const Vector4i n2, const Vector4i epsilon) -> bool {
	// NOTE: if epsilon is 1 or bigger, result will always return true
	const auto diff = abs(sub(n1, n2));
	const auto tol = mul(epsilon, max(abs(n1), abs(n2)));
	return le(diff, tol);
}

auto Decimal::log10(const Vector4i decimal) -> double {
	const auto& dec = RCAST_DEC(decimal);

	return dec.exponent + std::log10(dec.mantissa);
}

auto Decimal::abs_log10(const Vector4i decimal) -> double {
	const auto& dec = RCAST_DEC(decimal);

	return dec.exponent + std::log10(std::abs(dec.mantissa));
}

auto Decimal::log10_prot(const Vector4i decimal) -> double {
	const auto& dec = RCAST_DEC(decimal);

	return dec.mantissa <= 0 ? 0 : log10(dec.raw);
}

auto Decimal::log2(const Vector4i decimal) -> double {
	static constexpr const double LOG_10_2 = 3.321928094887362;

	return LOG_10_2 * log10(decimal);
}

auto Decimal::log(const Vector4i decimal, const double base) -> double {
	static constexpr const double LN_10 = 2.302585092994046;

	return (LN_10 / std::log(base)) * log10(decimal);
}

auto Decimal::ln(const Vector4i decimal) -> double {
	static constexpr const double LN_10 = 2.302585092994045;

	return LN_10 * log10(decimal);
}

auto Decimal::pow10_num(const double exp) -> Vector4i {
	const auto trunc = std::trunc(exp);

	return normalize(
		DecimalData(
			std::pow(10, exp - trunc),
			static_cast<int64_t>(trunc)
		).raw
	);
}

auto Decimal::pow_num(const Vector4i base, const double exp) -> Vector4i {
	const auto& base_dec = RCAST_DEC(base);

	const auto res = pow10_num(exp * abs_log10(base));

	if (likely(sign(base) != -1)) return res;

	// handle negative bases
	const auto parity = std::abs(std::fmod(exp, 2.0));
	if (parity == 1.0) {
		return neg(res);
	} else if (parity == 0.0) {
		return res;
	}
	return DECIMAL_NAN.raw;
}

auto Decimal::sqrt(const Vector4i decimal) -> Vector4i {
	const static double SQRT_10 = 3.1622776601683795;

	const auto& dec = RCAST_DEC(decimal);

	if (dec.mantissa < 0) return DECIMAL_NAN.raw;

	if (dec.exponent % 2 != 0) {
		// sqrt(10) * sqrt(10)
		// [1, 10) -> [1, 10)
		return DecimalData(
			std::sqrt(dec.mantissa) * SQRT_10,
			(dec.exponent - 1) / 2
		).raw;
	}

	// [1, 10) -> [1, ~3.16)
	return DecimalData(
		std::sqrt(dec.mantissa),
		dec.exponent / 2
	).raw;
;}

auto Decimal::cbrt(const Vector4i decimal) -> Vector4i {
	const static double CBRT_10 = 2.154434690031884;
	const static double CBRT_10_SQ = 4.641588833612779;

	const auto& dec = RCAST_DEC(decimal);

	switch (dec.exponent % 3) {

		case 1: case -2:
			// cbrt(10) * cbrt(10)
			// [1, 10) -> [1, ~4.64)
			return DecimalData(
				std::cbrt(dec.mantissa) * CBRT_10,
				dec.exponent / 3
			).raw;

		case 2: case -1:
			// cbrt(10) * cbrt(10)^2
			// [1, 10) -> [1, 10)
			return DecimalData(
				std::cbrt(dec.mantissa) * CBRT_10_SQ,
				dec.exponent / 3
			).raw;

		default: // 0
			// [1, 10) -> [1, ~2.15)
			return DecimalData(
				std::cbrt(dec.mantissa),
				dec.exponent / 3
		).raw;
	}
}

auto Decimal::dp(const Vector4i decimal) -> int64_t {
	const auto& dec = RCAST_DEC(decimal);

	if (is_finite(decimal) == false) return -1;
	if (dec.exponent >= MAX_SIGNIFICANT_DIGITS) return 0;

	int64_t places = -dec.exponent;
	int64_t e = 1;

	for (;;) {
		const double rem = std::round(dec.mantissa * e) / e - dec.mantissa;
		if (std::abs(rem) < ROUND_TOLERANCE) break;

		e *= 10;
		places++;
	}

	return Math::max<int64_t>(places, 0);
}

/**
 * If you're willing to spend 'resourcesAvailable' and want to buy something
 * with exponentially increasing cost each purchase (start at priceStart,
 * multiply by priceRatio, already own currentOwned), how much of it can you buy?
 * Adapted from Trimps source code.
 */
auto Decimal::afford_geometric_series (
	const Vector4i res_available,
	const Vector4i price_start,
	const Vector4i price_ratio,
	const int64_t current_owned
) -> int64_t {

	const auto relative_start = mul(price_start, pow_num(price_ratio, current_owned));

	const auto a = mul(div(res_available, relative_start), sub_num(price_ratio, 1));
	const auto b = log10(add_num(a, 1)) / log10(price_ratio);
	return static_cast<int64_t>(std::floor(b));
}

/**
 * How much resource would it cost to buy (numItems) items if you already have currentOwned,
 * the initial price is priceStart and it multiplies by priceRatio each purchase?
 */
auto Decimal::sum_geometric_series (
	const int64_t num_items,
	const Vector4i price_start,
	const Vector4i price_ratio,
	const int64_t current_owned
) -> Vector4i {

	const auto a = mul(price_start, pow_num(price_ratio, current_owned));
	const auto b = mul(a, sub(DECIMAL_ONE.raw, pow_num(price_ratio, num_items)));
	return div(b, sub(DECIMAL_ONE.raw, price_ratio));
}

/**
 * If you're willing to spend 'resourcesAvailable' and want to buy something with additively
 * increasing cost each purchase (start at priceStart, add by priceAdd, already own currentOwned),
 * how much of it can you buy?
 */
auto Decimal::afford_arithmetic_series(
	const Vector4i res_available,
	const Vector4i price_start,
	const Vector4i price_add,
	const Vector4i current_owned
) -> Vector4i {

	const auto relative_start = add(price_start, mul(price_add, current_owned));
	const auto b = sub(relative_start, div_num(price_add, 2));
	const auto b2 = pow_num(b, 2);

	const auto a = add(neg(b), sqrt(add(b2, mul_num(mul(price_add, res_available), 2))));
	return floor(div(a, price_add));
}

/**
 * How much resource would it cost to buy (numItems) items if you already have currentOwned,
 * the initial price is priceStart and it adds priceAdd each purchase?
 * Adapted from http://www.mathwords.com/a/arithmetic_series.htm
 */
auto Decimal::sum_arithmetic_series(
	const Vector4i num_items,
	const Vector4i price_start,
	const Vector4i price_add,
	const Vector4i current_owned
) -> Vector4i {

	const auto relative_start = add(price_start, mul(price_add, current_owned));

	return mul(div_num(num_items, 2), add(mul_num(relative_start, 2), mul(sub_num(num_items, 1), price_add)));
}

/**
 * When comparing two purchases that cost (resource) and increase your resource/sec by (deltaRpS),
 * the lowest efficiency score is the better one to purchase.
 * From Frozen Cookies:
 * http://cookieclicker.wikia.com/wiki/Frozen_Cookies_(JavaScript_Add-on)#Efficiency.3F_What.27s_that.3F
 */
auto Decimal::efficiency_of_purchase(
	const Vector4i cost,
	const Vector4i current_rps,
	const Vector4i delta_rps
) -> Vector4i {

	return add(div(cost, current_rps), div(cost, delta_rps));
}

