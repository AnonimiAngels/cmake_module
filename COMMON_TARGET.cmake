include(CheckCXXCompilerFlag)

function(try_set_flag P_PROJECT_NAME P_FLAG)
	string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" FLAG_VAR_NAME "${P_FLAG}")
	string(TOUPPER "${FLAG_VAR_NAME}" FLAG_VAR_NAME)
	set(CACHE_VAR_NAME "CXX_SUPPORTS_${FLAG_VAR_NAME}")

	if (NOT DEFINED ${CACHE_VAR_NAME})
		check_cxx_compiler_flag("${P_FLAG}" ${CACHE_VAR_NAME})
	endif()

	if(${CACHE_VAR_NAME})
		target_compile_options(${P_PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${P_FLAG}>)
	endif()
endfunction(try_set_flag)

function(try_set_flag_with_test P_PROJECT_NAME P_FLAG P_TEST_FLAG)
	string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" FLAG_VAR_NAME "${P_FLAG}")
	string(TOUPPER "${FLAG_VAR_NAME}" FLAG_VAR_NAME)
	set(CACHE_VAR_NAME "CXX_SUPPORTS_${FLAG_VAR_NAME}")

	if (NOT DEFINED ${CACHE_VAR_NAME})
		check_cxx_compiler_flag("${P_TEST_FLAG}" ${CACHE_VAR_NAME})
	endif()

	if(${CACHE_VAR_NAME})
		target_compile_options(${P_PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${P_FLAG}>)
	endif()
endfunction(try_set_flag_with_test)


function(common_compile_opts P_PROJECT_NAME)
	# Disable runtime type information for smaller binaries and faster code
	try_set_flag(${P_PROJECT_NAME} "-fno-rtti")
	# Disable C++ exceptions (aligned with no-exception policy)
	try_set_flag(${P_PROJECT_NAME} "-fno-exceptions")

	if(CMAKE_BUILD_TYPE STREQUAL "Debug")
		# Detect memory errors like buffer overflows and use-after-free
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=address")
		# Detect undefined behavior like null pointer dereferences
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=undefined")
		# Detect memory leaks
		try_set_flag(${P_PROJECT_NAME} "-fsanitize=leak")
		# Keep frame pointers for better stack traces in error reports
		try_set_flag(${P_PROJECT_NAME} "-fno-omit-frame-pointer")
		# Include debug symbols
		try_set_flag(${P_PROJECT_NAME} "-g")

		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=address)
		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=undefined)
		target_link_options(${P_PROJECT_NAME} PRIVATE -fsanitize=leak)
	endif()

	# Base warning set (works on both GCC and Clang)
	# Enable most common warnings about questionable constructs
	try_set_flag(${P_PROJECT_NAME} "-Wall")
	# Enable additional warnings not covered by -Wall
	try_set_flag(${P_PROJECT_NAME} "-Wextra")
	# Enforce strict ISO C++ compliance
	try_set_flag(${P_PROJECT_NAME} "-Wpedantic")
	# Treat all warnings as errors to enforce clean code
	try_set_flag(${P_PROJECT_NAME} "-Werror")

	# Shadowing and virtual functions
	# Warn when local variable shadows another variable, parameter, or member
	try_set_flag(${P_PROJECT_NAME} "-Wshadow")
	# Warn about non-virtual destructors in classes with virtual functions
	try_set_flag(${P_PROJECT_NAME} "-Wnon-virtual-dtor")
	# Warn when function hides overloaded virtual function from base class
	try_set_flag(${P_PROJECT_NAME} "-Woverloaded-virtual")

	# Type conversions and casts
	# Warn about C-style casts (prefer static_cast, etc.)
	try_set_flag(${P_PROJECT_NAME} "-Wold-style-cast")
	# Warn about casts that increase alignment requirements
	try_set_flag(${P_PROJECT_NAME} "-Wcast-align")
	# Warn about casts that remove const or volatile qualifiers
	try_set_flag(${P_PROJECT_NAME} "-Wcast-qual")
	# Warn about implicit type conversions that may alter value
	try_set_flag(${P_PROJECT_NAME} "-Wconversion")
	# Warn about implicit conversions between signed and unsigned
	try_set_flag(${P_PROJECT_NAME} "-Wsign-conversion")
	# Warn about implicit float conversions that may alter value
	try_set_flag(${P_PROJECT_NAME} "-Wfloat-conversion")
	# Warn about implicit promotion from float to double
	try_set_flag(${P_PROJECT_NAME} "-Wdouble-promotion")

	# Uninitialized variables
	# Warn about variables used before being initialized
	try_set_flag(${P_PROJECT_NAME} "-Wuninitialized")
	# Warn about variables initialized with themselves
	try_set_flag(${P_PROJECT_NAME} "-Winit-self")

	# Unused code detection
	# Warn about anything declared but not used
	try_set_flag(${P_PROJECT_NAME} "-Wunused")
	# Warn about unused function parameters
	try_set_flag(${P_PROJECT_NAME} "-Wunused-parameter")
	# Warn about unused variables
	try_set_flag(${P_PROJECT_NAME} "-Wunused-variable")
	# Warn about static functions declared but not defined
	try_set_flag(${P_PROJECT_NAME} "-Wunused-function")
	# Warn when return value of function marked [[nodiscard]] is ignored
	try_set_flag(${P_PROJECT_NAME} "-Wunused-result")
	# Warn about variables that are set but never used
	try_set_flag(${P_PROJECT_NAME} "-Wunused-but-set-variable")
	# Warn about lambda captures that are never used
	try_set_flag(${P_PROJECT_NAME} "-Wunused-lambda-capture")
	# Warn about unused private class members
	try_set_flag(${P_PROJECT_NAME} "-Wunused-private-field")

	# Logic errors
	# Warn about self-comparisons like (x == x)
	try_set_flag(${P_PROJECT_NAME} "-Wtautological-compare")
	# Warn about suspicious uses of logical operators (GCC)
	try_set_flag(${P_PROJECT_NAME} "-Wlogical-op")
	# Warn about implicit conversions of NULL to non-pointer types
	try_set_flag(${P_PROJECT_NAME} "-Wnull-conversion")

	# Pointer and null safety
	# Warn about dereferencing null pointers detected at compile time
	try_set_flag(${P_PROJECT_NAME} "-Wnull-dereference")
	# Warn about suspicious pointer arithmetic operations
	try_set_flag(${P_PROJECT_NAME} "-Wpointer-arith")

	# Format string security (CRITICAL for security)
	# Enable additional format string checking
	try_set_flag(${P_PROJECT_NAME} "-Wformat=2")
	# Warn about format strings that are not literals and may be exploited
	try_set_flag(${P_PROJECT_NAME} "-Wformat-security")
	# Warn when format string is not a string literal
	try_set_flag(${P_PROJECT_NAME} "-Wformat-nonliteral")

	# Memory and array safety
	# Warn about out-of-bounds array subscripts
	try_set_flag(${P_PROJECT_NAME} "-Warray-bounds")
	# Warn about attempts to modify string literals
	try_set_flag(${P_PROJECT_NAME} "-Wwrite-strings")
	# Warn about use of alloca (stack allocation)
	try_set_flag(${P_PROJECT_NAME} "-Walloca")
	# Warn about variable-length arrays (non-standard in C++)
	try_set_flag(${P_PROJECT_NAME} "-Wvla")

	# Redundant code
	# Warn about multiple declarations of the same entity
	try_set_flag(${P_PROJECT_NAME} "-Wredundant-decls")
	# Warn when member initializers are not in declaration order
	try_set_flag(${P_PROJECT_NAME} "-Wreorder")

	# Switch statement completeness
	# Warn when switch on enum doesn't handle all values
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-enum")
	# Warn when switch statement has no default case
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-default")

	# Modern C++ best practices
	# Suggest adding override keyword to virtual function overrides
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-override")

	# Missing declarations
	# Warn about missing function declarations
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-declarations")
	# Warn about missing include directories
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-include-dirs")

	# Dangerous constructs
	# Warn about undefined macros used in #if directives
	try_set_flag(${P_PROJECT_NAME} "-Wundef")

	# Performance hints
	# Warn when inline functions cannot be inlined
	try_set_flag(${P_PROJECT_NAME} "-Winline")

	# Float conversion warnings
	# Warn about implicit int to float conversions
	try_set_flag(${P_PROJECT_NAME} "-Wimplicit-int-float-conversion")
	# Warn about implicit float conversions (Clang)
	try_set_flag(${P_PROJECT_NAME} "-Wimplicit-float-conversion")

	# Thread safety (Clang-only, highly recommended for concurrent code)
	# Enable Clang thread safety analysis
	try_set_flag(${P_PROJECT_NAME} "-Wthread-safety")
	# Enable beta thread safety checks
	try_set_flag(${P_PROJECT_NAME} "-Wthread-safety-beta")

	# Additional Clang security warnings
	# Warn about pointer arithmetic on arrays
	try_set_flag(${P_PROJECT_NAME} "-Warray-bounds-pointer-arithmetic")
	# Warn about assigning non-enum values to enum types
	try_set_flag(${P_PROJECT_NAME} "-Wassign-enum")
	# Warn about variables that may be uninitialized on some paths
	try_set_flag(${P_PROJECT_NAME} "-Wconditional-uninitialized")
	# Warn about suspicious loop conditions
	try_set_flag(${P_PROJECT_NAME} "-Wloop-analysis")
	# Warn about left shift of negative value
	try_set_flag(${P_PROJECT_NAME} "-Wshift-sign-overflow")
	# Warn about implicit conversions from 64-bit to 32-bit integers
	try_set_flag(${P_PROJECT_NAME} "-Wshorten-64-to-32")
	# Warn about tautological comparisons with constants
	try_set_flag(${P_PROJECT_NAME} "-Wtautological-constant-in-range-compare")
	# Warn about suspicious uses of comma operator
	try_set_flag(${P_PROJECT_NAME} "-Wcomma")
	# Warn about misleading indentation that suggests different control flow
	try_set_flag(${P_PROJECT_NAME} "-Wmisleading-indentation")

	# C++26 specific (Clang 20+)
	# Warn about array comparisons that decay to pointer comparisons
	try_set_flag(${P_PROJECT_NAME} "-Warray-compare")

	# Logic errors
	# Warn about suspicious uses of logical operators (GCC)
	try_set_flag(${P_PROJECT_NAME} "-Wlogical-op")
	# Warn about duplicated conditions in if-else chains
	try_set_flag(${P_PROJECT_NAME} "-Wduplicated-cond")
	# Warn about identical branches in if-else statements
	try_set_flag(${P_PROJECT_NAME} "-Wduplicated-branches")

	# Type safety
	# Warn about casts that have no effect
	try_set_flag(${P_PROJECT_NAME} "-Wuseless-cast")

	# Memory safety (GCC-enhanced)
	# Enhanced array bounds checking (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Warray-bounds=2")
	# Disable strict-overflow warnings (prone to false positives)
	try_set_flag(${P_PROJECT_NAME} "-Wno-strict-overflow")
	# Warn about buffer overflow in sprintf/snprintf (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wformat-overflow=2")
	# Warn about output truncation in snprintf (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wformat-truncation=2")
	# Warn about buffer overflow in string operations (level 4)
	try_set_flag(${P_PROJECT_NAME} "-Wstringop-overflow=4")
	# Warn about format string sign mismatches
	try_set_flag(${P_PROJECT_NAME} "-Wformat-signedness")
	# Strict cast alignment checking
	try_set_flag(${P_PROJECT_NAME} "-Wcast-align=strict")
	# Warn about arithmetic conversions
	try_set_flag(${P_PROJECT_NAME} "-Warith-conversion")
	# Warn about shift operations that may overflow (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wshift-overflow=2")
	# Warn about switch fallthrough (level 3)
	try_set_flag(${P_PROJECT_NAME} "-Wimplicit-fallthrough=3")
	# Warn about trampolines (nested functions)
	try_set_flag(${P_PROJECT_NAME} "-Wtrampolines")

	# Modern C++ (GCC-specific)
	# Suggest marking types as final when beneficial
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-types")
	# Suggest marking methods as final when beneficial
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-methods")
	# Warn about non-null sentinel in variadic functions
	try_set_flag(${P_PROJECT_NAME} "-Wstrict-null-sentinel")

	# Performance hints (GCC-specific)
	# Suggest marking functions as pure attribute
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=pure")
	# Suggest marking functions as const attribute
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=const")
	# Suggest marking functions as noreturn attribute
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=noreturn")
	# Suggest marking functions with format attribute
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=format")
	# Suggest marking rarely-called functions as cold
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=cold")
	# Suggest marking functions that return fresh memory as malloc
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-attribute=malloc")
	# Suggest marking types as final when beneficial (duplicate)
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-types")
	# Suggest marking methods as final when beneficial (duplicate)
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-final-methods")
	# Suggest adding override keyword to virtual function overrides (duplicate)
	try_set_flag(${P_PROJECT_NAME} "-Wsuggest-override")

	# ========================================
	# ADDITIONAL ROBUSTNESS & SECURITY WARNINGS
	# ========================================

	# Null pointer and memory safety
	# Warn when using 0 instead of nullptr for null pointer constant
	try_set_flag(${P_PROJECT_NAME} "-Wzero-as-null-pointer-constant")
	# Warn about deleting objects with non-virtual destructor via base pointer
	try_set_flag(${P_PROJECT_NAME} "-Wdelete-non-virtual-dtor")
	# Warn about deleting pointer to incomplete type (undefined behavior)
	try_set_flag(${P_PROJECT_NAME} "-Wdelete-incomplete")
	# Warn about returning address of local variable or temporary
	try_set_flag(${P_PROJECT_NAME} "-Wreturn-local-addr")
	# Warn about freeing object not allocated on heap
	try_set_flag(${P_PROJECT_NAME} "-Wfree-nonheap-object")
	# Warn about suspicious memset usage with wrong element size
	try_set_flag(${P_PROJECT_NAME} "-Wmemset-elt-size")
	# Warn about memset with swapped arguments
	try_set_flag(${P_PROJECT_NAME} "-Wmemset-transposed-args")
	# Warn about sizeof on pointer when sizeof on array is expected
	try_set_flag(${P_PROJECT_NAME} "-Wsizeof-pointer-memaccess")
	# Warn about sizeof on array function parameter (decays to pointer)
	try_set_flag(${P_PROJECT_NAME} "-Wsizeof-array-argument")
	# Warn about suspicious pointer division by sizeof
	try_set_flag(${P_PROJECT_NAME} "-Wsizeof-pointer-div")
	# Warn about suspicious array division (likely programming error)
	try_set_flag(${P_PROJECT_NAME} "-Wsizeof-array-div")
	# Warn about placement new with insufficient storage (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wplacement-new=2")
	# Warn about allocating zero bytes
	try_set_flag(${P_PROJECT_NAME} "-Walloc-zero")
	# Warn about suspicious class member access (GCC 8+)
	try_set_flag(${P_PROJECT_NAME} "-Wclass-memaccess")

	# Uninitialized and undefined behavior
	# Warn about variables that may be uninitialized
	try_set_flag(${P_PROJECT_NAME} "-Wmaybe-uninitialized")
	# Warn about conditionally uninitialized variables
	try_set_flag(${P_PROJECT_NAME} "-Wconditional-uninitialized")
	# Warn about uninitialized const references
	try_set_flag(${P_PROJECT_NAME} "-Wuninitialized-const-reference")
	# Warn about undefined behavior in reinterpret_cast
	try_set_flag(${P_PROJECT_NAME} "-Wundefined-reinterpret-cast")
	# Warn about undefined function templates
	try_set_flag(${P_PROJECT_NAME} "-Wundefined-func-template")

	# Move semantics and modern C++ practices
	# Warn about moves that prevent copy elision
	try_set_flag(${P_PROJECT_NAME} "-Wpessimizing-move")
	# Warn about redundant std::move on return values
	try_set_flag(${P_PROJECT_NAME} "-Wredundant-move")
	# Warn about problematic move operations
	try_set_flag(${P_PROJECT_NAME} "-Wmove")
	# Warn about self-assignment (x = x)
	try_set_flag(${P_PROJECT_NAME} "-Wself-assign")
	# Warn about self-move (x = std::move(x))
	try_set_flag(${P_PROJECT_NAME} "-Wself-move")
	# Warn about deprecated implicit copy with user-declared copy/move/dtor
	try_set_flag(${P_PROJECT_NAME} "-Wdeprecated-copy")
	# Warn about deprecated copy with user-declared destructor
	try_set_flag(${P_PROJECT_NAME} "-Wdeprecated-copy-dtor")
	# Warn about virtual move assignment that hides base class version
	try_set_flag(${P_PROJECT_NAME} "-Wvirtual-move-assign")

	# Type safety and conversions
	# Warn about narrowing conversions in list initialization
	try_set_flag(${P_PROJECT_NAME} "-Wnarrowing")
	# Warn about comparisons between signed and unsigned integers
	try_set_flag(${P_PROJECT_NAME} "-Wsign-compare")
	# Warn about promotion of unsigned to signed in overload resolution
	try_set_flag(${P_PROJECT_NAME} "-Wsign-promo")
	# Warn about comparisons between different enum types
	try_set_flag(${P_PROJECT_NAME} "-Wenum-compare")
	# Warn about implicit conversions between different enum types
	try_set_flag(${P_PROJECT_NAME} "-Wenum-conversion")
	# Warn about implicit conversions between pointers and integers
	try_set_flag(${P_PROJECT_NAME} "-Wint-conversion")
	# Warn about implicit string to bool or number conversions
	try_set_flag(${P_PROJECT_NAME} "-Wstring-conversion")
	# Warn about implicit NULL conversions
	try_set_flag(${P_PROJECT_NAME} "-Wconversion-null")
	# Warn about comparisons always true/false due to limited range
	try_set_flag(${P_PROJECT_NAME} "-Wtype-limits")

	# Control flow and logic
	# Warn about code that will never be executed
	try_set_flag(${P_PROJECT_NAME} "-Wunreachable-code")
	# Warn about unreachable break statements
	try_set_flag(${P_PROJECT_NAME} "-Wunreachable-code-break")
	# Warn about unreachable return statements
	try_set_flag(${P_PROJECT_NAME} "-Wunreachable-code-return")
	# Warn about infinite recursion
	try_set_flag(${P_PROJECT_NAME} "-Winfinite-recursion")
	# Warn about ambiguous else branches
	try_set_flag(${P_PROJECT_NAME} "-Wdangling-else")
	# Warn about empty body in if/else/for/while statements
	try_set_flag(${P_PROJECT_NAME} "-Wempty-body")
	# Warn about suspicious switch on bool
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-bool")
	# Warn about switch cases outside enum range
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-outside-range")
	# Warn about unreachable code in switch statements
	try_set_flag(${P_PROJECT_NAME} "-Wswitch-unreachable")

	# Enhanced shadowing detection
	# Warn about all forms of shadowing (most comprehensive)
	try_set_flag(${P_PROJECT_NAME} "-Wshadow-all")
	# Warn about local variables shadowing other locals
	try_set_flag(${P_PROJECT_NAME} "-Wshadow=local")
	# Warn about shadowing with compatible types
	try_set_flag(${P_PROJECT_NAME} "-Wshadow=compatible-local")

	# Atomics and threading
	# Warn about implicit sequential consistency in atomics
	try_set_flag(${P_PROJECT_NAME} "-Watomic-implicit-seq-cst")
	# Warn about invalid memory ordering models
	try_set_flag(${P_PROJECT_NAME} "-Winvalid-memory-model")
	# Warn about __sync_fetch_and_nand usage
	try_set_flag(${P_PROJECT_NAME} "-Wsync-nand")

	# Deprecated and obsolete features
	# Warn about usage of deprecated features
	try_set_flag(${P_PROJECT_NAME} "-Wdeprecated")
	# Warn about deprecated declarations
	try_set_flag(${P_PROJECT_NAME} "-Wdeprecated-declarations")
	# Warn about deprecated Objective-C implementations
	try_set_flag(${P_PROJECT_NAME} "-Wdeprecated-implementations")
	# Warn about use of 'register' storage class specifier
	try_set_flag(${P_PROJECT_NAME} "-Wregister")
	# Warn about dynamic exception specifications (deprecated in C++11)
	try_set_flag(${P_PROJECT_NAME} "-Wdynamic-exception-spec")

	# Code quality and style
	# Warn about extra semicolons
	try_set_flag(${P_PROJECT_NAME} "-Wextra-semi")
	# Warn about semicolons before method body
	try_set_flag(${P_PROJECT_NAME} "-Wsemicolon-before-method-body")
	# Warn about redundant class/struct/union tags
	try_set_flag(${P_PROJECT_NAME} "-Wredundant-tags")
	# Warn about mismatched struct/class tags in declarations
	try_set_flag(${P_PROJECT_NAME} "-Wmismatched-tags")
	# Warn about suspicious range-based for loops
	try_set_flag(${P_PROJECT_NAME} "-Wrange-loop-analysis")
	# Warn about idiomatic parentheses usage
	try_set_flag(${P_PROJECT_NAME} "-Widiomatic-parentheses")
	# Warn about missing or confusing parentheses
	try_set_flag(${P_PROJECT_NAME} "-Wparentheses")
	# Warn about missing braces in aggregate initialization
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-braces")
	# Warn about missing newline at end of file
	try_set_flag(${P_PROJECT_NAME} "-Wnewline-eof")

	# Missing components
	# Warn about missing field initializers in structs/classes
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-field-initializers")
	# Warn about functions that could be marked [[noreturn]]
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-noreturn")
	# Warn about functions without prototypes
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-prototypes")
	# Warn about variables without declarations
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-variable-declarations")
	# Warn about methods without explicit return type
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-method-return-type")
	# Warn about missing function attributes
	try_set_flag(${P_PROJECT_NAME} "-Wmissing-attributes")

	# Unused code (additional)
	# Warn about unused comparison results
	try_set_flag(${P_PROJECT_NAME} "-Wunused-comparison")
	# Warn about unused const variables (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wunused-const-variable=2")
	# Warn about unused exception parameters in catch blocks
	try_set_flag(${P_PROJECT_NAME} "-Wunused-exception-parameter")
	# Warn about unused labels
	try_set_flag(${P_PROJECT_NAME} "-Wunused-label")
	# Warn about unused local typedef declarations
	try_set_flag(${P_PROJECT_NAME} "-Wunused-local-typedef")
	# Warn about unused macros
	try_set_flag(${P_PROJECT_NAME} "-Wunused-macros")
	# Warn about unused private member functions
	try_set_flag(${P_PROJECT_NAME} "-Wunused-member-function")
	# Warn about unused template declarations
	try_set_flag(${P_PROJECT_NAME} "-Wunused-template")
	# Warn about unused expression values
	try_set_flag(${P_PROJECT_NAME} "-Wunused-value")
	# Warn about parameters that are set but never used
	try_set_flag(${P_PROJECT_NAME} "-Wunused-but-set-parameter")
	# Warn about used symbols marked as unused
	try_set_flag(${P_PROJECT_NAME} "-Wused-but-marked-unused")
	# Warn about unneeded internal declarations
	try_set_flag(${P_PROJECT_NAME} "-Wunneeded-internal-declaration")
	# Warn about unneeded member functions
	try_set_flag(${P_PROJECT_NAME} "-Wunneeded-member-function")

	# Documentation and code clarity
	# Warn about Doxygen documentation issues
	try_set_flag(${P_PROJECT_NAME} "-Wdocumentation")
	# Enable pedantic documentation warnings
	try_set_flag(${P_PROJECT_NAME} "-Wdocumentation-pedantic")

	# Overflow and arithmetic safety
	# Warn about compile-time detected integer overflow
	try_set_flag(${P_PROJECT_NAME} "-Woverflow")
	# Warn about division by zero
	try_set_flag(${P_PROJECT_NAME} "-Wdiv-by-zero")
	# Warn about left shift of negative values
	try_set_flag(${P_PROJECT_NAME} "-Wshift-negative-value")
	# Warn about undefined order of evaluation
	try_set_flag(${P_PROJECT_NAME} "-Wsequence-point")
	# Warn about loop optimizations that assume no overflow
	try_set_flag(${P_PROJECT_NAME} "-Waggressive-loop-optimizations")

	# String and buffer operations
	# Warn about string operations that may truncate output
	try_set_flag(${P_PROJECT_NAME} "-Wstringop-truncation")
	# Warn about suspicious string comparisons
	try_set_flag(${P_PROJECT_NAME} "-Wstring-compare")
	# Warn about string literals longer than ISO C++ allows
	try_set_flag(${P_PROJECT_NAME} "-Woverlength-strings")

	# OOP and inheritance
	# Warn about classes with private constructors and no friends
	try_set_flag(${P_PROJECT_NAME} "-Wctor-dtor-privacy")
	# Warn about virtual inheritance (can be expensive)
	try_set_flag(${P_PROJECT_NAME} "-Wvirtual-inheritance")
	# Warn about multiple inheritance (can be complex)
	try_set_flag(${P_PROJECT_NAME} "-Wmultiple-inheritance")
	# Warn about missing destructor override declarations
	try_set_flag(${P_PROJECT_NAME} "-Winconsistent-missing-destructor-override")
	# Warn about method signature mismatches
	try_set_flag(${P_PROJECT_NAME} "-Wmethod-signatures")
	# Warn about method signature mismatches in superclass
	try_set_flag(${P_PROJECT_NAME} "-Wsuper-class-method-mismatch")
	# Warn about non-template friends in templates
	try_set_flag(${P_PROJECT_NAME} "-Wnon-template-friend")

	# Attributes and qualifiers
	# Warn about attributes in wrong places or being ignored
	try_set_flag(${P_PROJECT_NAME} "-Wignored-attributes")
	# Warn about ignored type qualifiers (const, volatile)
	try_set_flag(${P_PROJECT_NAME} "-Wignored-qualifiers")
	# Warn about attribute usage issues
	try_set_flag(${P_PROJECT_NAME} "-Wattributes")
	# Warn about attribute alias misuse (level 2)
	try_set_flag(${P_PROJECT_NAME} "-Wattribute-alias=2")
	# Warn about noexcept specification issues
	try_set_flag(${P_PROJECT_NAME} "-Wnoexcept")
	# Warn about noexcept type system issues
	try_set_flag(${P_PROJECT_NAME} "-Wnoexcept-type")

	# Strict aliasing and alignment
	# Warn about violations of strict aliasing rules (level 3)
	try_set_flag(${P_PROJECT_NAME} "-Wstrict-aliasing=3")
	# Warn about packed attributes that may cause alignment issues
	try_set_flag(${P_PROJECT_NAME} "-Wpacked")
	# Warn about packed bitfield compatibility issues
	try_set_flag(${P_PROJECT_NAME} "-Wpacked-bitfield-compat")
	# Warn about packed structures that are not aligned
	try_set_flag(${P_PROJECT_NAME} "-Wpacked-not-aligned")

	# Comparison and pointer operations
	# Warn about floating point equality comparisons
	try_set_flag(${P_PROJECT_NAME} "-Wfloat-equal")
	# Warn about suspicious pointer comparisons
	try_set_flag(${P_PROJECT_NAME} "-Wpointer-compare")
	# Warn about casts between incompatible function types
	try_set_flag(${P_PROJECT_NAME} "-Wbad-function-cast")

	# Build-time and preprocessor warnings
	# Warn about __DATE__ and __TIME__ usage (non-reproducible builds)
	try_set_flag(${P_PROJECT_NAME} "-Wdate-time")
	# Warn about mismatched builtin function declarations
	try_set_flag(${P_PROJECT_NAME} "-Wbuiltin-declaration-mismatch")
	# Warn about redefining builtin macros
	try_set_flag(${P_PROJECT_NAME} "-Wbuiltin-macro-redefined")
	# Warn about disabled macro expansion
	try_set_flag(${P_PROJECT_NAME} "-Wdisabled-macro-expansion")
	# Warn about trigraph sequences (??= etc.)
	try_set_flag(${P_PROJECT_NAME} "-Wtrigraphs")
	# Warn about missing endif labels
	try_set_flag(${P_PROJECT_NAME} "-Wendif-labels")
	# Warn about pragma usage issues
	try_set_flag(${P_PROJECT_NAME} "-Wpragmas")
	# Warn about invalid precompiled headers
	try_set_flag(${P_PROJECT_NAME} "-Winvalid-pch")

	# Platform and ABI
	# Warn about parameter passing ABI issues
	try_set_flag(${P_PROJECT_NAME} "-Wpsabi")
	# Warn about suspicious __builtin_frame_address usage
	try_set_flag(${P_PROJECT_NAME} "-Wframe-address")
	# Warn about non-portable system include paths
	try_set_flag(${P_PROJECT_NAME} "-Wnonportable-system-include-path")
	# Warn about One Definition Rule violations
	try_set_flag(${P_PROJECT_NAME} "-Wodr")
	# Warn about subobject linkage issues
	try_set_flag(${P_PROJECT_NAME} "-Wsubobject-linkage")

	# Miscellaneous safety
	# Warn about main function issues
	try_set_flag(${P_PROJECT_NAME} "-Wmain")
	# Warn about multi-character character constants
	try_set_flag(${P_PROJECT_NAME} "-Wmultichar")
	# Warn about variadic function argument issues
	try_set_flag(${P_PROJECT_NAME} "-Wvarargs")
	# Warn about deprecated volatile usage
	try_set_flag(${P_PROJECT_NAME} "-Wvolatile")
	# Warn about volatile register variables
	try_set_flag(${P_PROJECT_NAME} "-Wvolatile-register-var")
	# Warn about objects with automatic storage used in initializer lists
	try_set_flag(${P_PROJECT_NAME} "-Winit-list-lifetime")
	# Warn about inheriting constructors from virtual base
	try_set_flag(${P_PROJECT_NAME} "-Winherited-variadic-ctor")
	# Warn about invalid offsetof usage
	try_set_flag(${P_PROJECT_NAME} "-Winvalid-offsetof")
	# Warn about non-standard literal suffixes
	try_set_flag(${P_PROJECT_NAME} "-Wliteral-suffix")
	# Warn about Unicode normalization issues (NFC)
	try_set_flag(${P_PROJECT_NAME} "-Wnormalized=nfc")
	# Warn about missing return statements in non-void functions
	try_set_flag(${P_PROJECT_NAME} "-Wreturn-type")
	# Warn about terminate called in situations where it shouldn't
	try_set_flag(${P_PROJECT_NAME} "-Wterminate")

	# Enhanced implicit fallthrough (highest level)
	# Warn about implicit fallthrough in switch statements (level 5 - strictest)
	try_set_flag(${P_PROJECT_NAME} "-Wimplicit-fallthrough=5")

	# Catch exceptions properly
	# Warn about catching exceptions by value instead of reference (level 3)
	try_set_flag(${P_PROJECT_NAME} "-Wcatch-value=3")

	# Additional deallocation safety
	# Warn about sized deallocation issues
	try_set_flag(${P_PROJECT_NAME} "-Wsized-deallocation")

	# Duplicate detection
	# Warn about duplicate enum values
	try_set_flag(${P_PROJECT_NAME} "-Wduplicate-enum")
	# Warn about duplicate method arguments
	try_set_flag(${P_PROJECT_NAME} "-Wduplicate-method-arg")
	# Warn about duplicate method matches
	try_set_flag(${P_PROJECT_NAME} "-Wduplicate-method-match")

	# Header hygiene
	# Warn about header include issues
	try_set_flag(${P_PROJECT_NAME} "-Wheader-hygiene")

	# Old style declarations
	# Warn about old-style (K&R) function declarations
	try_set_flag(${P_PROJECT_NAME} "-Wold-style-declaration")

	# Performance-related
	# Warn about inefficient vector operations
	try_set_flag(${P_PROJECT_NAME} "-Wvector-operation-performance")
	# Warn about pointer-to-member function conversions
	try_set_flag(${P_PROJECT_NAME} "-Wpmf-conversions")
	try_set_flag(${P_PROJECT_NAME} "-Wnrvo")

	# Stack protection
	# Warn when stack protection is not effective
	try_set_flag(${P_PROJECT_NAME} "-Wstack-protector")
endfunction(common_compile_opts)

function(enable_clang_tidy)
	find_program(CLANG_TIDY_PROGRAM NAMES "clang-tidy")

	SET(CLANG_TIDY_ARGS
		"--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy"
		"--extra-arg=-Wno-unknown-warning-option" "--fix" "--quiet"
	)

	SET(CLANG_TIDY_CACHER "clang-tidy-cache")

	if(CLANG_TIDY_PROGRAM)
		SET(CMAKE_CXX_CLANG_TIDY
			"${CLANG_TIDY_CACHER}"
			"${CLANG_TIDY_PROGRAM}"
			"${CLANG_TIDY_ARGS}"

			PARENT_SCOPE
		)
	elseif(CLANG_TIDY_PROGRAM AND FALSE)
		SET(CMAKE_CXX_CLANG_TIDY
			"${CLANG_TIDY_PROGRAM}"
			"${CLANG_TIDY_ARGS}"

			PARENT_SCOPE
		)
	endif()
endfunction(enable_clang_tidy)

function(disable_clang_tidy)
	unset(CMAKE_CXX_CLANG_TIDY PARENT_SCOPE)
endfunction(disable_clang_tidy)

function(check_main_project)
	if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
		set(IS_MAIN_PROJECT TRUE PARENT_SCOPE)
	else()
		set(IS_MAIN_PROJECT FALSE PARENT_SCOPE)
	endif()
endfunction(check_main_project)