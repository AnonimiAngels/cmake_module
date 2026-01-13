#!/usr/bin/env python3

import sys
import os
import subprocess
import json
from pathlib import Path

import blake3


CACHE_DIR = Path(os.environ.get("CLANG_TIDY_CACHE_DIR", Path.home() / ".clang_tidy_cache"))


def get_clang_tidy_version(clang_tidy_bin):
	result = subprocess.run(
		[clang_tidy_bin, "--version"],
		capture_output=True,
		text=True
	)
	return result.stdout.strip()


def parse_compile_commands(build_path, source_file):
	compile_commands_path = Path(build_path) / "compile_commands.json"
	if not compile_commands_path.exists():
		return None

	with open(compile_commands_path, "r") as file:
		commands = json.load(file)

	source_resolved = Path(source_file).resolve()
	for entry in commands:
		entry_file = Path(entry.get("directory", ".")) / entry.get("file", "")
		if entry_file.resolve() == source_resolved:
			return entry

	return None


def get_preprocessor_output(entry, source_file):
	if entry is None:
		with open(source_file, "rb") as file:
			return file.read()

	command = entry.get("command", "") or " ".join(entry.get("arguments", []))
	if not command:
		with open(source_file, "rb") as file:
			return file.read()

	parts = command.split() if isinstance(command, str) else command
	compiler = parts[0] if parts else "g++"

	preprocess_args = [compiler, "-E", "-P"]
	skip_next = False

	for part in parts[1:]:
		if skip_next:
			skip_next = False
			continue
		if part in ["-c", "-o"]:
			skip_next = True
			continue
		if part.startswith("-o"):
			continue
		if part == source_file or part.endswith(Path(source_file).name):
			continue
		preprocess_args.append(part)

	preprocess_args.append(str(source_file))

	result = subprocess.run(
		preprocess_args,
		capture_output=True,
		cwd=entry.get("directory", ".")
	)

	if result.returncode != 0:
		with open(source_file, "rb") as file:
			return file.read()

	return result.stdout


def find_clang_tidy_config(source_file, config_file=None):
	if config_file is not None:
		config_path = Path(config_file)
		if config_path.exists():
			with open(config_path, "rb") as file:
				return file.read()
		return b""

	current = Path(source_file).resolve().parent

	while current != current.parent:
		config_path = current / ".clang-tidy"
		if config_path.exists():
			with open(config_path, "rb") as file:
				return file.read()
		current = current.parent

	return b""


def compute_hash(clang_tidy_bin, source_file, build_path, config_file, extra_args):
	hasher = blake3.blake3()

	hasher.update(get_clang_tidy_version(clang_tidy_bin).encode())

	entry = parse_compile_commands(build_path, source_file) if build_path else None
	preprocessed = get_preprocessor_output(entry, source_file)
	hasher.update(preprocessed)

	config = find_clang_tidy_config(source_file, config_file)
	hasher.update(config)

	for arg in extra_args:
		hasher.update(arg.encode())

	return hasher.hexdigest()


def parse_args(args):
	source_file = None
	build_path = None
	config_file = None
	extra_args = []
	idx = 0

	while idx < len(args):
		arg = args[idx]

		if arg == "-p" and idx + 1 < len(args):
			build_path = args[idx + 1]
			extra_args.extend([arg, args[idx + 1]])
			idx += 2
			continue

		if arg.startswith("-p="):
			build_path = arg[3:]
			extra_args.append(arg)
			idx += 1
			continue

		if arg.startswith("--config-file="):
			config_file = arg[14:]
			extra_args.append(arg)
			idx += 1
			continue

		if arg.startswith("-"):
			extra_args.append(arg)
			idx += 1
			continue

		if source_file is None and Path(arg).exists():
			source_file = arg

		extra_args.append(arg)
		idx += 1

	return source_file, build_path, config_file, extra_args


def get_cache_path(hash_value):
	CACHE_DIR.mkdir(parents=True, exist_ok=True)
	subdir = CACHE_DIR / hash_value[:2]
	subdir.mkdir(exist_ok=True)
	return subdir / hash_value


def run_clang_tidy(clang_tidy_bin, args):
	result = subprocess.run(
		[clang_tidy_bin] + args,
		capture_output=True,
		text=True
	)
	return result


def main():
	if len(sys.argv) < 3:
		print(f"Usage: {sys.argv[0]} <clang-tidy-binary> [clang-tidy args...]", file=sys.stderr)
		return 1

	clang_tidy_bin = sys.argv[1]
	args = sys.argv[2:]
	source_file, build_path, config_file, extra_args = parse_args(args)

	if source_file is None:
		result = run_clang_tidy(clang_tidy_bin, args)
		print(result.stdout, end="")
		print(result.stderr, end="", file=sys.stderr)
		return result.returncode

	hash_value = compute_hash(clang_tidy_bin, source_file, build_path, config_file, extra_args)
	cache_path = get_cache_path(hash_value)

	if cache_path.exists():
		with open(cache_path, "r") as file:
			cached = json.load(file)
		print(cached.get("stdout", ""), end="")
		print(cached.get("stderr", ""), end="", file=sys.stderr)
		return cached.get("returncode", 0)

	result = run_clang_tidy(clang_tidy_bin, args)

	if result.returncode == 0 or (result.returncode != 0 and result.stdout):
		cache_data = {
			"stdout": result.stdout,
			"stderr": result.stderr,
			"returncode": result.returncode
		}
		with open(cache_path, "w") as file:
			json.dump(cache_data, file)

	print(result.stdout, end="")
	print(result.stderr, end="", file=sys.stderr)
	return result.returncode


if __name__ == "__main__":
	sys.exit(main())