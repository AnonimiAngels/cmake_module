include(CheckCXXCompilerFlag)
function(impl_compiler_supports_flag P_FLAG P_TEST_FLAG RESULT_VAR)
	if (NOT DEFINED ${RESULT_VAR})
		check_cxx_compiler_flag(${P_TEST_FLAG} COMPILER_SUPPORTS_FLAG)
		SET(${RESULT_VAR} ${COMPILER_SUPPORTS_FLAG} CACHE BOOL "Whether the compiler supports the flag ${P_FLAG}")
		MESSAGE(STATUS "Compiler flag check: ${P_FLAG} supported: ${${RESULT_VAR}}")
	endif()
endfunction(impl_compiler_supports_flag)

function(try_set_flag P_PROJECT_NAME P_FLAG)
	impl_compiler_supports_flag("${P_FLAG}" "${P_FLAG}" FLAG_SUPPORTED)
	if(FLAG_SUPPORTED)
		target_compile_options(${P_PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${P_FLAG}>)
	endif()
endfunction(try_set_flag)

function(try_set_flag_with_test P_PROJECT_NAME P_FLAG P_TEST_FLAG)
	impl_compiler_supports_flag("${P_FLAG}" "${P_TEST_FLAG}" FLAG_SUPPORTED)
	if(FLAG_SUPPORTED)
		target_compile_options(${P_PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${P_FLAG}>)
	endif()
endfunction(try_set_flag_with_test)


function(common_compile_opts P_PROJECT_NAME P_SOURCES)
	try_set_flag(${P_PROJECT_NAME} "-fno-rtti")
	try_set_flag(${P_PROJECT_NAME} "-fno-exceptions")
	try_set_flag_with_test(${P_PROJECT_NAME} "-ffile-prefix-map=${CMAKE_SOURCE_DIR}/=" "-ffile-prefix-map=/tmp/=")
	try_set_flag_with_test(${P_PROJECT_NAME} "-fdebug-prefix-map=${CMAKE_SOURCE_DIR}/=" "-fdebug-prefix-map=/tmp/=")

	if(CMAKE_BUILD_TYPE STREQUAL "Debug")
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=address")
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=undefined")
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=leak")
		try_set_flag(${P_PROJECT_NAME} "-fno-omit-frame-pointer")
		try_set_flag(${P_PROJECT_NAME} "-g")

		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=address)
		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=undefined)
		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=leak)
	endif()

	# Base warning set (works on both GCC and Clang)
	try_set_flag(${P_PROJECT_NAME} "-Wall")
	try_set_flag(${P_PROJECT_NAME} "-Wextra")
	try_set_flag(${P_PROJECT_NAME} "-Wpedantic")
	try_set_flag(${P_PROJECT_NAME} "-Werror")

	# Shadowing and virtual functions
	try_set_flag(${P_PROJECT_NAME} "-Wshadow")
	try_set_flag(${P_PROJECT_NAME} "-Wnon-virtual-dtor")
	try_set_flag(${P_PROJECT_NAME} "-Woverloaded-virtual")

	# Type conversions and casts
	try_set_flag(${P_PROJECT_NAME} "-Wold-style-cast")
	try_set_flag(${P_PROJECT_NAME} "-Wcast-align")
	try_set_flag(${P_PROJECT_NAME} "-Wcast-qual")
	try_set_flag(${P_PROJECT_NAME} "-Wconversion")
	try_set_flag(${P_PROJECT_NAME} "-Wsign-conversion")
	try_set_flag(${P_PROJECT_NAME} "-Wfloat-conversion")
	try_set_flag(${P_PROJECT_NAME} "-Wdouble-promotion")

	# Uninitialized variables
	try_set_flag(${P_PROJECT_NAME} "-Wuninitialized")
	try_set_flag(${P_PROJECT_NAME} "-Winit-self")

	# Unused code detection
	try_set_flag(${P_PROJECT_NAME} "-Wunused")
	try_set_flag(${P_PROJECT_NAME} "-Wunused-parameter")
	try_set_flag(${P_PROJECT_NAME} "-Wunused-variable")
	try_set_flag(${P_PROJECT_NAME} "-Wunused-function")
	try_set_flag(${P_PROJECT_NAME} "-Wunused-result")

	# Pointer and null safety
	try_set_flag(${P_PROJECT_NAME} "-Wnull-dereference")
	try_set_flag(${P_PROJECT_NAME} "-Wpointer-arith")

	# Format string security (CRITICAL for security)
	try_set_flag(${P_PROJECT_NAME} "-Wformat=2")
	try_set_flag(${P_PROJECT_NAME} "-Wformat-security")
	try_set_flag(${P_PROJECT_NAME} "-Wformat-nonliteral")

	# Memory and array safety
	try_set_flag(${P_PROJECT_NAME} "-Warray-bounds")
	try_set_flag(${P_PROJECT_NAME} "-Wwrite-strings")
	try_set_flag(${P_PROJECT_NAME} "-Walloca")
	try_set_flag(${P_PROJECT_NAME} "-Wvla")

	# Redundant code
	try_set_flag(${P_PROJECT_NAME} "-Wredundant-decls")
	try_set_flag(${P_PROJECT_NAME} "-Wreorder")

	# Switch statement completeness
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-enum")
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-default")

	# Modern C++ best practices
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-override")

	# Missing declarations
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-declarations")
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-include-dirs")

	# Dangerous constructs
	try_set_flag(${P_PROJECT_NAME} "-Wundef")

	# Performance hints
	try_set_flag(${P_PROJECT_NAME} "-Winline")

	# Clang-specific warnings
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		# Float conversion warnings
		try_set_flag(${P_PROJECT_NAME} "-Wimplicit-int-float-conversion")
		try_set_flag(${P_PROJECT_NAME} "-Wimplicit-float-conversion")

		# Thread safety (Clang-only, highly recommended for concurrent code)
		try_set_flag(${P_PROJECT_NAME} "-Wthread-safety")
		try_set_flag(${P_PROJECT_NAME} "-Wthread-safety-beta")

		# Additional Clang security warnings
		try_set_flag(${P_PROJECT_NAME} "-Warray-bounds-pointer-arithmetic")
		try_set_flag(${P_PROJECT_NAME} "-Wassign-enum")
		try_set_flag(${P_PROJECT_NAME} "-Wconditional-uninitialized")
		try_set_flag(${P_PROJECT_NAME} "-Wloop-analysis")
		try_set_flag(${P_PROJECT_NAME} "-Wshift-sign-overflow")
		try_set_flag(${P_PROJECT_NAME} "-Wshorten-64-to-32")
		try_set_flag(${P_PROJECT_NAME} "-Wtautological-constant-in-range-compare")
		try_set_flag(${P_PROJECT_NAME} "-Wcomma")
		try_set_flag(${P_PROJECT_NAME} "-Wmisleading-indentation")

		# C++26 specific (Clang 20+)
		try_set_flag(${P_PROJECT_NAME} "-Warray-compare")
	endif()

	# GCC-specific warnings
	if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		# Logic errors
		try_set_flag(${P_PROJECT_NAME} "-Wlogical-op")
		try_set_flag(${P_PROJECT_NAME} "-Wduplicated-cond")
		try_set_flag(${P_PROJECT_NAME} "-Wduplicated-branches")

		# Type safety
		try_set_flag(${P_PROJECT_NAME} "-Wuseless-cast")

		# Memory safety (GCC-enhanced)
		try_set_flag(${P_PROJECT_NAME} "-Warray-bounds=2")
		try_set_flag(${P_PROJECT_NAME} "-Wno-strict-overflow")
		try_set_flag(${P_PROJECT_NAME} "-Wformat-overflow=2")
		try_set_flag(${P_PROJECT_NAME} "-Wformat-truncation=2")
		try_set_flag(${P_PROJECT_NAME} "-Wstringop-overflow=4")
		try_set_flag(${P_PROJECT_NAME} "-Wformat-signedness")
		try_set_flag(${P_PROJECT_NAME} "-Wcast-align=strict")
		try_set_flag(${P_PROJECT_NAME} "-Warith-conversion")
		try_set_flag(${P_PROJECT_NAME} "-Wshift-overflow=2")
		try_set_flag(${P_PROJECT_NAME} "-Wimplicit-fallthrough=3")
		try_set_flag(${P_PROJECT_NAME} "-Wtrampolines")

		# Modern C++ (GCC-specific)
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-types")
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-methods")
		try_set_flag(${P_PROJECT_NAME} "-Wstrict-null-sentinel")

		# Performance hints (GCC-specific)
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=pure")
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=const")
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=noreturn")
		try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=format")
	endif()
endfunction(common_compile_opts)
