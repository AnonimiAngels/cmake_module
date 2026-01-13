#!/usr/bin/env python3

import sys
import subprocess
import json
import atexit
from pathlib import Path


CONFIG_PATH = Path.home() / ".config/clang_tidy_cacher/config.json"

DEFAULTS = {
	"max_cache_size": 16 * 1024 * 1024 * 1024,
	"cache_dir": str(Path.home() / ".clang_tidy_cache"),
	"cleanup_threshold": 0.9,
	"cleanup_target": 0.7,
	"cleanup_interval": 100,
}

STATS_DEFAULTS = {
	"hits": 0,
	"misses": 0,
	"invocations_since_cleanup": 0,
}

VERSION_CACHE = {}
COMPILE_COMMANDS_CACHE = {}


class configurator:

	_instance = None

	def __new__(cls):
		if cls._instance is None:
			cls._instance = super().__new__(cls)
			cls._instance._config = None
			cls._instance._dirty = False
			cls._instance._load()
			atexit.register(cls._instance._save)
		return cls._instance

	def _load(self):
		if CONFIG_PATH.exists():
			with open(CONFIG_PATH, "rb") as file:
				self._config = json.load(file)
		else:
			self._config = {}

		if "stats" not in self._config:
			self._config["stats"] = STATS_DEFAULTS.copy()

	def _save(self):
		if not self._dirty:
			return

		CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
		tmp_path = CONFIG_PATH.with_suffix(".tmp")

		with open(tmp_path, "w") as file:
			json.dump(self._config, file)

		tmp_path.rename(CONFIG_PATH)
		self._dirty = False

	def get(self, key):
		return self._config.get(key, DEFAULTS.get(key))

	def set(self, key, value):
		self._config[key] = value
		self._dirty = True

	def get_stat(self, key):
		return self._config["stats"].get(key, STATS_DEFAULTS.get(key, 0))

	def inc_stat(self, key, amount=1):
		self._config["stats"][key] = self.get_stat(key) + amount
		self._dirty = True

	def set_stat(self, key, value):
		self._config["stats"][key] = value
		self._dirty = True

	def flush(self):
		self._save()

	@property
	def cache_dir(self):
		return Path(self.get("cache_dir"))


def get_clang_tidy_version(clang_tidy_bin):
	if clang_tidy_bin in VERSION_CACHE:
		return VERSION_CACHE[clang_tidy_bin]

	result = subprocess.run(
		[clang_tidy_bin, "--version"],
		capture_output=True,
		text=True
	)
	version = result.stdout.strip()
	VERSION_CACHE[clang_tidy_bin] = version
	return version


def get_compile_commands_index(build_path):
	if build_path in COMPILE_COMMANDS_CACHE:
		return COMPILE_COMMANDS_CACHE[build_path]

	compile_commands_path = Path(build_path) / "compile_commands.json"
	if not compile_commands_path.exists():
		COMPILE_COMMANDS_CACHE[build_path] = None
		return None

	with open(compile_commands_path, "rb") as file:
		commands = json.load(file)

	index = {}
	for entry in commands:
		entry_file = Path(entry.get("directory", ".")) / entry.get("file", "")
		index[str(entry_file.resolve())] = entry

	COMPILE_COMMANDS_CACHE[build_path] = index
	return index


def get_preprocessor_output(entry, source_file):
	if entry is None:
		with open(source_file, "rb") as file:
			return file.read()

	command = entry.get("command") or entry.get("arguments")
	if not command:
		with open(source_file, "rb") as file:
			return file.read()

	if isinstance(command, str):
		parts = command.split()
	else:
		parts = list(command)

	compiler = parts[0] if parts else "g++"
	source_name = Path(source_file).name

	preprocess_args = [compiler, "-E", "-P"]
	skip_next = False

	for part in parts[1:]:
		if skip_next:
			skip_next = False
			continue
		if part in ("-c", "-o"):
			skip_next = True
			continue
		if part.startswith("-o"):
			continue
		if part == source_file or part.endswith(source_name):
			continue
		preprocess_args.append(part)

	preprocess_args.append(source_file)

	result = subprocess.run(
		preprocess_args,
		capture_output=True,
		cwd=entry.get("directory", ".")
	)

	if result.returncode != 0:
		with open(source_file, "rb") as file:
			return file.read()

	return result.stdout


def find_clang_tidy_config(source_path, config_file=None):
	if config_file is not None:
		config_path = Path(config_file)
		if config_path.exists():
			with open(config_path, "rb") as file:
				return file.read()
		return b""

	current = source_path.parent

	while current != current.parent:
		config_path = current / ".clang-tidy"
		if config_path.exists():
			with open(config_path, "rb") as file:
				return file.read()
		current = current.parent

	return b""


def compute_hash(clang_tidy_bin, source_file, build_path, config_file, extra_args):
	import blake3

	hasher = blake3.blake3()

	hasher.update(get_clang_tidy_version(clang_tidy_bin).encode())

	if build_path:
		index = get_compile_commands_index(build_path)
		entry = index.get(source_file) if index else None
	else:
		entry = None

	preprocessed = get_preprocessor_output(entry, source_file)
	hasher.update(preprocessed)

	source_path = Path(source_file)
	config = find_clang_tidy_config(source_path, config_file)
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
	args_len = len(args)

	while idx < args_len:
		arg = args[idx]

		if arg == "-p" and idx + 1 < args_len:
			build_path = args[idx + 1]
			extra_args.append(arg)
			extra_args.append(build_path)
			idx += 2
			continue

		if arg[:3] == "-p=":
			build_path = arg[3:]
			extra_args.append(arg)
			idx += 1
			continue

		if arg[:14] == "--config-file=":
			config_file = arg[14:]
			extra_args.append(arg)
			idx += 1
			continue

		if arg[0] == "-":
			extra_args.append(arg)
			idx += 1
			continue

		if source_file is None:
			path = Path(arg)
			if path.exists():
				source_file = str(path.resolve())

		extra_args.append(arg)
		idx += 1

	return source_file, build_path, config_file, extra_args


def get_cache_path(cache_dir, hash_value):
	subdir = cache_dir / hash_value[:2]
	subdir.mkdir(parents=True, exist_ok=True)
	return subdir / hash_value


def run_clang_tidy(clang_tidy_bin, args):
	return subprocess.run(
		[clang_tidy_bin] + args,
		capture_output=True,
		text=True
	)


def get_cache_size(cache_dir):
	if not cache_dir.exists():
		return 0

	total = 0
	for subdir in cache_dir.iterdir():
		if subdir.is_dir():
			for file in subdir.iterdir():
				if file.is_file():
					total += file.stat().st_size

	return total


def cleanup_cache(cfg):
	cache_dir = cfg.cache_dir
	if not cache_dir.exists():
		return

	max_size = cfg.get("max_cache_size")
	threshold = max_size * cfg.get("cleanup_threshold")

	files = []
	total_size = 0

	for subdir in cache_dir.iterdir():
		if subdir.is_dir():
			for file in subdir.iterdir():
				if file.is_file():
					stat = file.stat()
					files.append((file, stat.st_mtime, stat.st_size))
					total_size += stat.st_size

	if total_size <= threshold:
		cfg.set_stat("invocations_since_cleanup", 0)
		return

	target_size = int(max_size * cfg.get("cleanup_target"))
	files.sort(key=lambda x: x[1])

	for file, _, size in files:
		if total_size <= target_size:
			break
		file.unlink(missing_ok=True)
		total_size -= size

	cfg.set_stat("invocations_since_cleanup", 0)


def print_stats(cfg):
	print(f"Cache directory: {cfg.cache_dir}")
	print(f"Max cache size: {cfg.get('max_cache_size') / (1024**3):.2f} GB")
	print(f"Hits: {cfg.get_stat('hits')}")
	print(f"Misses: {cfg.get_stat('misses')}")

	total = cfg.get_stat("hits") + cfg.get_stat("misses")
	if total > 0:
		hit_rate = cfg.get_stat("hits") / total * 100
		print(f"Hit rate: {hit_rate:.1f}%")

	if cfg.cache_dir.exists():
		size = get_cache_size(cfg.cache_dir)
		count = 0
		for subdir in cfg.cache_dir.iterdir():
			if subdir.is_dir():
				count += sum(1 for f in subdir.iterdir() if f.is_file())
		print(f"Current size: {size / (1024**2):.2f} MB")
		print(f"Cached entries: {count}")


def handle_cli():
	if len(sys.argv) < 2:
		return False

	cmd = sys.argv[1]

	if cmd == "--stats":
		print_stats(configurator())
		return True

	if cmd == "--clear":
		cfg = configurator()
		if cfg.cache_dir.exists():
			for subdir in cfg.cache_dir.iterdir():
				if subdir.is_dir():
					for file in subdir.iterdir():
						if file.is_file():
							file.unlink()
					subdir.rmdir()
			print("Cache cleared")
		cfg.set_stat("hits", 0)
		cfg.set_stat("misses", 0)
		return True

	if cmd == "--config":
		cfg = configurator()

		if len(sys.argv) < 3:
			print(f"Config file: {CONFIG_PATH}")
			print(json.dumps(cfg._config, indent=2))
			return True

		if len(sys.argv) == 3:
			print(cfg.get(sys.argv[2]))
			return True

		if len(sys.argv) == 4:
			key = sys.argv[2]
			value = sys.argv[3]

			if value.isdigit():
				value = int(value)
			elif value.replace(".", "", 1).isdigit():
				value = float(value)

			cfg.set(key, value)
			print(f"{key} = {value}")
			return True

	if cmd == "--help":
		print(f"Usage: {sys.argv[0]} <clang-tidy-binary> [clang-tidy args...]")
		print()
		print("Commands:")
		print("  --stats          Show cache statistics")
		print("  --clear          Clear cache and reset stats")
		print("  --config         Show all config")
		print("  --config <key>   Get config value")
		print("  --config <key> <value>  Set config value")
		print()
		print("Config keys:")
		print("  max_cache_size   Max cache size in bytes (default: 16GB)")
		print("  cache_dir        Cache directory path")
		print("  cleanup_threshold  Start cleanup at this ratio (default: 0.9)")
		print("  cleanup_target   Target ratio after cleanup (default: 0.7)")
		print("  cleanup_interval Check cleanup every N misses (default: 100)")
		return True

	return False


def main():
	if handle_cli():
		return 0

	if len(sys.argv) < 3:
		print(f"Usage: {sys.argv[0]} <clang-tidy-binary> [clang-tidy args...]", file=sys.stderr)
		print(f"       {sys.argv[0]} --help", file=sys.stderr)
		return 1

	cfg = configurator()
	clang_tidy_bin = sys.argv[1]
	args = sys.argv[2:]

	source_file, build_path, config_file, extra_args = parse_args(args)

	if source_file is None:
		result = run_clang_tidy(clang_tidy_bin, args)
		print(result.stdout, end="")
		print(result.stderr, end="", file=sys.stderr)
		return result.returncode

	hash_value = compute_hash(clang_tidy_bin, source_file, build_path, config_file, extra_args)
	cache_dir = cfg.cache_dir
	cache_dir.mkdir(parents=True, exist_ok=True)
	cache_path = get_cache_path(cache_dir, hash_value)

	if cache_path.exists():
		with open(cache_path, "rb") as file:
			cached = json.load(file)
		print(cached.get("stdout", ""), end="")
		print(cached.get("stderr", ""), end="", file=sys.stderr)
		cfg.inc_stat("hits")
		return cached.get("returncode", 0)

	cfg.inc_stat("misses")
	result = run_clang_tidy(clang_tidy_bin, args)

	if result.returncode == 0 or result.stdout:
		cache_data = {
			"stdout": result.stdout,
			"stderr": result.stderr,
			"returncode": result.returncode
		}
		with open(cache_path, "w") as file:
			json.dump(cache_data, file)

	cfg.inc_stat("invocations_since_cleanup")

	if cfg.get_stat("invocations_since_cleanup") >= cfg.get("cleanup_interval"):
		cleanup_cache(cfg)

	print(result.stdout, end="")
	print(result.stderr, end="", file=sys.stderr)
	return result.returncode


if __name__ == "__main__":
	sys.exit(main())