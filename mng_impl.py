#!/usr/bin/env python3

import argparse
import concurrent.futures
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from threading import Lock
from typing import Dict, Optional, Tuple, List


class logger:
	def __init__(self, p_output=sys.stdout):
		self.m_output = p_output
		self.m_lock = Lock()

	def log(self, p_msg: str, p_flush: bool = True) -> None:
		with self.m_lock:
			self.m_output.write(f"-- {p_msg}\n")
			if p_flush:
				self.m_output.flush()

	def info(self, p_msg: str) -> None:
		self.log(f"INFO:{p_msg}")

	def error(self, p_msg: str) -> None:
		self.log(f"ERROR:{p_msg}")

	def success(self, p_msg: str) -> None:
		self.log(f"SUCCESS:{p_msg}")

	def status(self, p_status: str, p_name: str) -> None:
		self.log(f"{p_status}:{p_name}")


g_logger = logger()


class dl_helper:
	CHUNK_SZ = 131072
	TIMEOUT = 30

	@staticmethod
	def dl_with_retry(p_url: str, p_dest: Path, p_retries: int = 3) -> bool:
		for idx_retry in range(p_retries):
			try:
				g_logger.info(f"Downloading: {p_url}")

				opener = urllib.request.build_opener()
				opener.addheaders = [
					('User-Agent', 'Pkg-Mgr/1.0'),
					('Accept-Encoding', 'gzip, deflate')
				]
				urllib.request.install_opener(opener)

				with urllib.request.urlopen(p_url, timeout=dl_helper.TIMEOUT) as resp:
					file_sz = int(resp.headers.get('Content-Length', 0))

					if file_sz > 0:
						g_logger.info(f"Size: {file_sz / 1048576:.2f} MB")

					dl_bytes = 0
					last_pct = -1

					with open(p_dest, 'wb') as f:
						while True:
							chunk = resp.read(dl_helper.CHUNK_SZ)
							if not chunk:
								break
							f.write(chunk)
							dl_bytes += len(chunk)

							if file_sz > 0:
								pct = int((dl_bytes / file_sz) * 100)
								if pct != last_pct and pct % 10 == 0:
									g_logger.info(f"Progress: {pct}%")
									last_pct = pct

				g_logger.info("Download complete")
				return True

			except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
				g_logger.error(f"Attempt {idx_retry + 1} failed: {e}")
				if idx_retry < p_retries - 1:
					wait_t = 2 ** idx_retry
					g_logger.info(f"Retry in {wait_t}s...")
					time.sleep(wait_t)
					continue
				return False

		return False


class pkg_cache:
	def __init__(self, p_cache_dir: Path):
		self.m_cache_dir = p_cache_dir
		self.m_cache_lock = Lock()
		self.m_meta_cache = {}

	def get_pkg_hash(self, p_info: dict) -> str:
		hash_data = json.dumps(p_info, sort_keys=True)
		return hashlib.sha256(hash_data.encode()).hexdigest()[:16]

	def is_valid(self, p_name: str, p_info: dict, p_pkg_dir: Path) -> bool:
		if not p_pkg_dir.exists():
			return False

		cache_file = self.m_cache_dir / p_name / "CACHE" / ".cache"
		if not cache_file.exists():
			return False

		with self.m_cache_lock:
			if p_name in self.m_meta_cache:
				cached_info = self.m_meta_cache[p_name]
			else:
				with open(cache_file, 'r') as f:
					cached_info = json.load(f)
					self.m_meta_cache[p_name] = cached_info

		return self.get_pkg_hash(cached_info) == self.get_pkg_hash(p_info)


class git_helper:
	@staticmethod
	def full_clone(p_repo: str, p_dest: Path, p_tag: Optional[str] = None) -> bool:
		g_logger.info(f"Cloning: {p_repo}")
		if p_tag:
			g_logger.info(f"Tag: {p_tag}")

		cmd = ['git', 'clone']

		if p_tag:
			cmd.extend(['--branch', p_tag])

		cmd.extend([
			'--recurse-submodules',
			'--quiet',
			'--shallow-submodules',
			'--single-branch',
			'--depth', '1',
			p_repo,
			str(p_dest)
		])

		env = os.environ.copy()
		env['GIT_HTTP_LOW_SPEED_LIMIT'] = '1000'
		env['GIT_HTTP_LOW_SPEED_TIME'] = '10'

		g_logger.info(f"Exec: {' '.join(cmd)}")
		result = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=600)

		if result.returncode == 0:
			g_logger.info("Clone success")
			return True

		g_logger.error(f"Clone failed: {result.stderr}")
		return False

	@staticmethod
	def update_full(p_dest: Path) -> bool:
		try:
			g_logger.info(f"Updating: {p_dest}")

			g_logger.info("Fetching...")
			subprocess.run(
				['git', 'fetch', '--all', '--quiet'],
				cwd=p_dest, check=True, timeout=120
			)

			g_logger.info("Resetting...")
			subprocess.run(
				['git', 'reset', '--hard', 'origin/HEAD', '--quiet'],
				cwd=p_dest, check=True, timeout=30
			)

			g_logger.info("Updating submodules...")
			subprocess.run(
				['git', 'submodule', 'update', '--init', '--recursive', '--quiet'],
				cwd=p_dest, check=False, timeout=120
			)

			g_logger.info("Update success")
			return True
		except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
			g_logger.error(f"Update failed: {e}")
			return False


class pkg_mgr:
	def __init__(self, p_cache_dir):
		self.m_cache_dir = Path(p_cache_dir)
		self.m_cache_dir.mkdir(parents=True, exist_ok=True)
		self.m_cache = pkg_cache(self.m_cache_dir)
		self.m_dl_helper = dl_helper()
		self.m_git_helper = git_helper()
		self.m_executor = concurrent.futures.ThreadPoolExecutor(max_workers=4)

	def get_cache_file(self, p_name: str) -> Path:
		cache_dir = self.m_cache_dir / p_name / "CACHE"
		cache_dir.mkdir(parents=True, exist_ok=True)
		return cache_dir / ".cache"

	def get_pkg_dir(self, p_name: str) -> Path:
		return self.m_cache_dir / p_name / p_name

	def load_cached_info(self, p_name: str) -> dict:
		cache_file = self.get_cache_file(p_name)
		if cache_file.exists():
			with open(cache_file, 'r') as f:
				return json.load(f)
		return {}

	def save_cached_info(self, p_name: str, p_info: dict) -> None:
		cache_file = self.get_cache_file(p_name)
		with open(cache_file, 'w') as f:
			json.dump(p_info, f, indent=2)

	def needs_refetch(self, p_name: str, p_new_info: dict) -> bool:
		pkg_dir = self.get_pkg_dir(p_name)
		return not self.m_cache.is_valid(p_name, p_new_info, pkg_dir)

	def clear_pkg(self, p_name: str) -> None:
		g_logger.info(f"Clearing: {p_name}")
		pkg_parent = self.m_cache_dir / p_name
		if pkg_parent.exists():
			shutil.rmtree(pkg_parent)
			if p_name in self.m_cache.m_meta_cache:
				del self.m_cache.m_meta_cache[p_name]
			g_logger.info(f"Cleared: {p_name}")
		else:
			g_logger.info(f"Not found: {p_name}")

	def clone_repo(self, p_name: str, p_repo: str, p_tag: Optional[str] = None) -> bool:
		pkg_dir = self.get_pkg_dir(p_name)
		pkg_dir.parent.mkdir(parents=True, exist_ok=True)

		g_logger.info(f"Clone start: {p_name}")
		return self.m_git_helper.full_clone(p_repo, pkg_dir, p_tag)

	def update_repo(self, p_name: str) -> bool:
		pkg_dir = self.get_pkg_dir(p_name)
		if not pkg_dir.exists():
			return False
		return self.m_git_helper.update_full(pkg_dir)

	def extract_zip(self, p_file: Path, p_pkg_dir: Path) -> None:
		g_logger.info("Extracting ZIP")
		with zipfile.ZipFile(p_file, 'r') as zip_ref:
			members = zip_ref.namelist()
			g_logger.info(f"Files: {len(members)}")
			common_pfx = os.path.commonpath(members) if members else ''

			if common_pfx and '/' in common_pfx:
				g_logger.info(f"Strip prefix: {common_pfx}")
				for idx_for, member in enumerate(members):
					if idx_for % 100 == 0 and idx_for > 0:
						g_logger.info(f"Extracted {idx_for}/{len(members)}")
					if member.startswith(common_pfx):
						target = p_pkg_dir / member[len(common_pfx)+1:]
						if member.endswith('/'):
							target.mkdir(parents=True, exist_ok=True)
						else:
							target.parent.mkdir(parents=True, exist_ok=True)
							with zip_ref.open(member) as src, open(target, 'wb') as dst:
								shutil.copyfileobj(src, dst)
			else:
				zip_ref.extractall(p_pkg_dir)

	def extract_tar(self, p_file: Path, p_pkg_dir: Path) -> None:
		g_logger.info("Extracting TAR")
		with tarfile.open(p_file, 'r:*') as tar_ref:
			members = tar_ref.getmembers()
			g_logger.info(f"Files: {len(members)}")
			common_pfx = os.path.commonpath([m.name for m in members]) if members else ''

			if common_pfx and '/' in common_pfx:
				g_logger.info(f"Strip prefix: {common_pfx}")
				for idx_for, member in enumerate(members):
					if idx_for % 100 == 0 and idx_for > 0:
						g_logger.info(f"Extracted {idx_for}/{len(members)}")
					if member.name.startswith(common_pfx):
						member.name = member.name[len(common_pfx)+1:]
						if member.name:
							tar_ref.extract(member, p_pkg_dir)
			else:
				tar_ref.extractall(p_pkg_dir)

	def dl_archive(self, p_name: str, p_url: str) -> bool:
		pkg_dir = self.get_pkg_dir(p_name)
		pkg_dir.parent.mkdir(parents=True, exist_ok=True)

		g_logger.info(f"DL archive: {p_name}")
		dl_file = self.m_cache_dir / f"{p_name}_dl"

		if not self.m_dl_helper.dl_with_retry(p_url, dl_file):
			return False

		try:
			g_logger.info(f"Extract: {p_name}")

			if p_url.endswith('.zip'):
				self.extract_zip(dl_file, pkg_dir)
			else:
				self.extract_tar(dl_file, pkg_dir)

			g_logger.info(f"Extract done: {p_name}")
			return True
		finally:
			dl_file.unlink(missing_ok=True)
			g_logger.info("Cleanup done")

	def process_pkg(self, p_args) -> bool:
		name = p_args.name
		pkg_dir = self.get_pkg_dir(name)

		g_logger.info(f"Process: {name}")

		new_info = {
			'version': p_args.version or '',
			'git_tag': p_args.git_tag or '',
			'github_repository': p_args.github_repository or '',
			'git_repository': p_args.git_repository or '',
			'url': p_args.url or ''
		}

		if p_args.version:
			g_logger.info(f"Version: {p_args.version}")
		if p_args.git_tag:
			g_logger.info(f"Tag: {p_args.git_tag}")

		g_logger.info("Check cache")
		if pkg_dir.exists() and self.needs_refetch(name, new_info):
			g_logger.status("REFETCH", name)
			self.clear_pkg(name)

		if pkg_dir.exists():
			if p_args.keep_updated and (p_args.git_repository or p_args.github_repository):
				g_logger.status("UPDATE", name)
				g_logger.info("Update existing")
				if not self.update_repo(name):
					g_logger.info("Update failed, refetch")
					self.clear_pkg(name)
				else:
					g_logger.status("EXISTS", str(pkg_dir))
					return True
			else:
				g_logger.status("CACHED", name)
				g_logger.info("Using cache")
				g_logger.status("EXISTS", str(pkg_dir))
				return True

		g_logger.info("Not cached, download")
		git_repo = ""
		if p_args.github_repository:
			git_repo = f"https://github.com/{p_args.github_repository}.git"
			g_logger.info(f"GitHub: {p_args.github_repository}")
		else:
			git_repo = p_args.git_repository or ""
			if git_repo:
				g_logger.info(f"Git: {git_repo}")

		success = False
		if git_repo:
			git_tag = p_args.git_tag or (f"v{p_args.version}" if p_args.version else None)
			success = self.clone_repo(name, git_repo, git_tag)
		elif p_args.url:
			g_logger.info(f"URL: {p_args.url}")
			success = self.dl_archive(name, p_args.url)
		else:
			g_logger.error(f"No source: {name}")
			return False

		if not success:
			return False

		g_logger.info("Save metadata")
		self.save_cached_info(name, new_info)
		g_logger.success(str(pkg_dir))
		return True

	def __del__(self):
		if hasattr(self, 'm_executor'):
			self.m_executor.shutdown(wait=False)


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('--cache-dir', required=True)
	parser.add_argument('--name', required=True)
	parser.add_argument('--version')
	parser.add_argument('--git-tag')
	parser.add_argument('--github-repository')
	parser.add_argument('--git-repository')
	parser.add_argument('--url')
	parser.add_argument('--keep-updated', action='store_true')
	parser.add_argument('--download-only', action='store_true')
	parser.add_argument('--options', nargs='*')
	parser.add_argument('--clear-cache', action='store_true')
	parser.add_argument('--clear-package')

	args = parser.parse_args()

	mgr = pkg_mgr(args.cache_dir)

	if args.clear_cache:
		if args.clear_package:
			mgr.clear_pkg(args.clear_package)
		else:
			shutil.rmtree(args.cache_dir, ignore_errors=True)
			Path(args.cache_dir).mkdir(parents=True, exist_ok=True)
		g_logger.info("CLEARED")
		return

	mgr.process_pkg(args)


if __name__ == '__main__':
	main()