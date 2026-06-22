# /// script
# dependencies = [
#   "python-logging @ git+https://github.com/aurumorinc/python-logging.git"
# ]
# ///

import os
import sys
import json
import time
import zipfile
import shutil
import urllib.request
import urllib.error
import subprocess
import ctypes
import argparse
from pathlib import Path
from typing import Tuple

from python_logging.main import setup_logging, get_logger

setup_logging()
logger = get_logger(__name__)

DEFAULT_INSTALL_DIR = Path(r"C:\Program Files\3proxy")
DEFAULT_SOCKS_PORT = 41080
DEFAULT_HTTP_PORT = 43128
DEFAULT_USERNAME = "haproxy"
DEFAULT_PASSWORD = "Elsewhere-Repeater6-Celibacy"


def is_admin() -> bool:
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="3proxy Setup & Auto-Start Script")
    parser.add_argument("--install-dir", type=Path, default=DEFAULT_INSTALL_DIR, help="Installation directory")
    parser.add_argument("--socks-port", type=int, default=DEFAULT_SOCKS_PORT, help="SOCKS5 proxy port")
    parser.add_argument("--http-port", type=int, default=DEFAULT_HTTP_PORT, help="HTTP proxy port")
    parser.add_argument("--username", type=str, default=DEFAULT_USERNAME, help="Proxy username")
    parser.add_argument("--password", type=str, default=DEFAULT_PASSWORD, help="Proxy password")
    return parser.parse_args()


def setup_directories_and_defender(install_dir: Path) -> None:
    logger.info("Setting up directories and Windows Defender exclusions", install_dir=str(install_dir))
    install_dir.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            ["powershell", "-Command", f"Add-MpPreference -ExclusionPath '{install_dir}'"],
            check=True, text=True, capture_output=True
        )
    except subprocess.CalledProcessError as e:
        logger.error("Failed to add Defender exclusion", error=e.stderr or e.stdout)
        raise


def fetch_latest_release() -> Tuple[str, str]:
    logger.info("Fetching latest release from GitHub API")
    req = urllib.request.Request("https://api.github.com/repos/3proxy/3proxy/releases/latest")
    req.add_header("User-Agent", "3proxy-installer-script")
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            tag_name = data.get("tag_name")
            if not tag_name:
                raise ValueError("Invalid JSON response: missing tag_name")
                
            assets = data.get("assets", [])
            for asset in assets:
                if "x64" in asset.get("name", "").lower() and asset.get("name", "").endswith(".zip"):
                    return tag_name, asset.get("browser_download_url")
                    
            raise ValueError("Could not find an x64 .zip asset in the latest release")
    except urllib.error.URLError as e:
        logger.error("Network failure during API fetch", error=str(e))
        raise


def check_idempotency(install_dir: Path, tag_name: str) -> bool:
    release_txt = install_dir / "release.txt"
    if release_txt.exists():
        with open(release_txt, "r", encoding="utf-8") as f:
            if f.read().strip() == tag_name and (install_dir / "3proxy.exe").exists():
                return True
    return False


def stop_service() -> None:
    logger.info("Stopping 3proxy service if it exists")
    subprocess.run(
        ["powershell", "-Command", "Stop-Service -Name 3proxy -Force -ErrorAction SilentlyContinue"],
        capture_output=True
    )
    time.sleep(2)


def download_and_extract(url: str, install_dir: Path, tag_name: str) -> None:
    logger.info("Downloading latest release", url=url)
    import tempfile
    
    temp_zip = Path(tempfile.gettempdir()) / "3proxy.zip"
    temp_extract = Path(tempfile.gettempdir()) / "3proxy_extract"
    
    try:
        req = urllib.request.Request(url)
        req.add_header("User-Agent", "3proxy-installer-script")
        with urllib.request.urlopen(req) as response, open(temp_zip, "wb") as f:
            f.write(response.read())
            
        logger.info("Extracting archive")
        with zipfile.ZipFile(temp_zip, "r") as z:
            z.extractall(temp_extract)
            
        logger.info("Locating and copying 3proxy.exe")
        bin_dir = None
        for root, dirs, files in os.walk(temp_extract):
            if "3proxy.exe" in files:
                bin_dir = Path(root)
                break
                
        if not bin_dir:
            raise FileNotFoundError("3proxy.exe not found in downloaded archive")
            
        for item in bin_dir.iterdir():
            if item.is_file():
                shutil.copy2(item, install_dir)
                
        with open(install_dir / "release.txt", "w", encoding="utf-8") as f:
            f.write(tag_name)
            
    finally:
        if temp_zip.exists():
            temp_zip.unlink()
        if temp_extract.exists():
            shutil.rmtree(temp_extract, ignore_errors=True)


def generate_config(install_dir: Path, args: argparse.Namespace) -> None:
    logger.info("Generating 3proxy.cfg")
    cfg_content = f"""nserver 1.1.1.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60

users {args.username}:CL:{args.password}

service

# SOCKS5 proxy
auth strong
flush
allow {args.username}
socks -p{args.socks_port}

# HTTP proxy
auth strong
flush
allow {args.username}
proxy -p{args.http_port}
"""
    with open(install_dir / "3proxy.cfg", "w", encoding="utf-8") as f:
        f.write(cfg_content)


def configure_firewall(http_port: int, socks_port: int) -> None:
    logger.info("Configuring Windows Firewall")
    rules = [
        {"name": "3proxy HTTP", "port": http_port},
        {"name": "3proxy SOCKS", "port": socks_port}
    ]
    
    for rule in rules:
        try:
            subprocess.run(
                f'netsh advfirewall firewall delete rule name="{rule["name"]}"',
                shell=True, capture_output=True
            )
            subprocess.run(
                f'netsh advfirewall firewall add rule name="{rule["name"]}" dir=in action=allow protocol=TCP localport={rule["port"]}',
                shell=True, check=True, text=True, capture_output=True
            )
        except subprocess.CalledProcessError as e:
            logger.error("Failed to configure firewall", rule=rule["name"], error=e.stderr or e.stdout)
            raise


def register_and_start_service(install_dir: Path) -> None:
    logger.info("Registering and starting 3proxy service")
    exe_path = str(install_dir / "3proxy.exe")
    cfg_path = str(install_dir / "3proxy.cfg")
    
    logger.info("Stopping existing service (if any)")
    subprocess.run(["powershell", "-Command", "Stop-Service -Name 3proxy -Force -ErrorAction SilentlyContinue"], capture_output=True)
    
    logger.info("Removing existing service (if any) using native 3proxy executable")
    subprocess.run([exe_path, "--remove"], capture_output=True)
    time.sleep(1)
    
    logger.info("Installing service using native 3proxy executable")
    try:
        subprocess.run([exe_path, "--install", cfg_path], check=True, text=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        logger.error("Failed to install service via native executable", error=e.stderr or e.stdout)
        raise
        
    start_cmd = "Start-Service -Name 3proxy"
    try:
        subprocess.run(["powershell", "-Command", start_cmd], check=True, text=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        logger.error("Failed to start service", error=e.stderr or e.stdout)
        raise


def test_proxy(http_port: int, username: str, password: str) -> None:
    logger.info("Testing local HTTP proxy connection")
    time.sleep(3)
    try:
        res = subprocess.run(
            ["curl.exe", "-s", "-x", f"http://{username}:{password}@127.0.0.1:{http_port}", "https://github.com"],
            capture_output=True, text=True
        )
        if res.returncode == 0:
            logger.info("[PASS] Proxy test successful")
        else:
            logger.error("[FAIL] Proxy test failed", returncode=res.returncode, stderr=res.stderr)
    except FileNotFoundError:
        logger.error("[FAIL] curl.exe not found on the system to run test")
    except Exception as e:
        logger.error("[FAIL] Exception during proxy test", error=str(e))


def main() -> None:
    args = parse_args()

    if not is_admin():
        logger.info("Not running as Administrator. Requesting elevation...")
        script_path = os.path.abspath(sys.argv[0])
        cmd_args = f'"{script_path}" {" ".join(sys.argv[1:])}'
        
        ret = ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, cmd_args, None, 1)
        if ret <= 32:
            logger.error("Failed to elevate privileges", error_code=ret)
            sys.exit(1)
        sys.exit(0)

    try:
        setup_directories_and_defender(args.install_dir)
        
        tag_name, download_url = fetch_latest_release()
        
        if check_idempotency(args.install_dir, tag_name):
            logger.info("Already up to date. Updating config and firewall only.")
        else:
            stop_service()
            download_and_extract(download_url, args.install_dir, tag_name)
            
        generate_config(args.install_dir, args)
        configure_firewall(args.http_port, args.socks_port)
        register_and_start_service(args.install_dir)
        test_proxy(args.http_port, args.username, args.password)
        
    except Exception as e:
        logger.exception("Installation failed")
        input("Press Enter to close...")
        sys.exit(1)
        
    input("Press Enter to close...")


if __name__ == "__main__":
    main()