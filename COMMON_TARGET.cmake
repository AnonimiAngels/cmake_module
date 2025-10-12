function(common_compile_opts P_PROJECT_NAME P_SOURCES)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>)

	if(CMAKE_BUILD_TYPE STREQUAL "Debug")
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fsanitize=address>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fsanitize=undefined>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fsanitize=leak>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-omit-frame-pointer>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-g>)

		target_link_options(${P_PROJECT_NAME} PUBLIC -fsanitize=address)
		target_link_options(${P_PROJECT_NAME} PUBLIC -fsanitize=undefined)
		target_link_options(${P_PROJECT_NAME} PUBLIC -fsanitize=leak)
	endif()

	# Base warning set (works on both GCC and Clang)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wall>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wextra>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wpedantic>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Werror>)

	# Shadowing and virtual functions
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wshadow>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wnon-virtual-dtor>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Woverloaded-virtual>)

	# Type conversions and casts
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wold-style-cast>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wcast-align>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wcast-qual>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wconversion>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsign-conversion>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wfloat-conversion>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wdouble-promotion>)

	# Uninitialized variables
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wuninitialized>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Winit-self>)

	# Unused code detection
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wunused>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wunused-parameter>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wunused-variable>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wunused-function>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wunused-result>)

	# Pointer and null safety
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wnull-dereference>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wpointer-arith>)

	# Format string security (CRITICAL for security)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat=2>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat-security>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat-nonliteral>)

	# Memory and array safety
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Warray-bounds>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wwrite-strings>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Walloca>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wvla>)

	# Redundant code
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wredundant-decls>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wreorder>)

	# Switch statement completeness
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wswitch-enum>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wswitch-default>)

	# Modern C++ best practices
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-override>)

	# Missing declarations
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wmissing-declarations>)
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wmissing-include-dirs>)

	# Dangerous constructs
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wundef>)

	# Performance hints
	target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Winline>)

	# Clang-specific warnings
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		# Float conversion warnings
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wimplicit-int-float-conversion>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wimplicit-float-conversion>)

		# Thread safety (Clang-only, highly recommended for concurrent code)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wthread-safety>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wthread-safety-beta>)

		# Additional Clang security warnings
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Warray-bounds-pointer-arithmetic>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wassign-enum>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wconditional-uninitialized>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wloop-analysis>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wshift-sign-overflow>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wshorten-64-to-32>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wtautological-constant-in-range-compare>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wcomma>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wmisleading-indentation>)

		# C++26 specific (Clang 20+)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Warray-compare>)
	endif()

	# GCC-specific warnings
	if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		# Logic errors
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wlogical-op>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wduplicated-cond>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wduplicated-branches>)

		# Type safety
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wuseless-cast>)

		# Memory safety (GCC-enhanced)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Warray-bounds=2>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wstrict-overflow=4>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat-overflow=2>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat-truncation=2>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wstringop-overflow=4>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wformat-signedness>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wcast-align=strict>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Warith-conversion>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wshift-overflow=2>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wimplicit-fallthrough=3>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wtrampolines>)

		# Modern C++ (GCC-specific)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-final-types>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-final-methods>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wstrict-null-sentinel>)

		# Performance hints (GCC-specific)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-attribute=pure>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-attribute=const>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-attribute=noreturn>)
		target_compile_options(${P_PROJECT_NAME} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-attribute=format>)
	endif()

	# Apply clang-tidy if available
	find_program(CLANG_TIDY_EXE NAMES "clang-tidy")
	find_program(CLANG_APPLY_REPLACEMENTS_EXE NAMES "clang-apply-replacements")

	if(CLANG_TIDY_EXE)
		set(CLANG_TIDY_FIXES_DIR ${CMAKE_BINARY_DIR}/clang-tidy-fixes/${P_PROJECT_NAME})

		add_custom_target(clang-tidy-clean-fixes-${P_PROJECT_NAME}
			COMMAND ${CMAKE_COMMAND} -E remove_directory ${CLANG_TIDY_FIXES_DIR}
			COMMENT "Cleaning clang-tidy fixes for ${P_PROJECT_NAME}"
		)

		add_custom_target(clang-tidy-export-fixes-${P_PROJECT_NAME}
			COMMAND ${CMAKE_COMMAND} -E make_directory ${CLANG_TIDY_FIXES_DIR}
			COMMAND ${CLANG_TIDY_EXE}
				--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy
				--fix
				--fix-errors
				--quiet
				--header-filter=.*
				-p ${CMAKE_BINARY_DIR}
				--export-fixes=${CLANG_TIDY_FIXES_DIR}/fixes.yaml
				${P_SOURCES}
			COMMENT "Exporting clang-tidy fixes for ${P_PROJECT_NAME}"
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			DEPENDS clang-tidy-clean-fixes-${P_PROJECT_NAME}
		)

		if(CLANG_APPLY_REPLACEMENTS_EXE AND TRUE)
			add_custom_target(clang-tidy-apply-fixes-${P_PROJECT_NAME}
				COMMAND ${CLANG_APPLY_REPLACEMENTS_EXE}
					--format
					--style=file
					${CLANG_TIDY_FIXES_DIR}
				COMMENT "Applying clang-tidy fixes for ${P_PROJECT_NAME}"
				DEPENDS clang-tidy-export-fixes-${P_PROJECT_NAME}
			)

			add_dependencies(${P_PROJECT_NAME} clang-tidy-apply-fixes-${P_PROJECT_NAME})
		endif()
	endif()
endfunction(common_compile_opts)