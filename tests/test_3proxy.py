import os
import sys
import json
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
import importlib.util

# Dynamically load the module because it starts with a number ('3proxy.py')
script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "autostart", "3proxy.py"))
spec = importlib.util.spec_from_file_location("proxy_mod", script_path)
proxy_mod = importlib.util.module_from_spec(spec)
sys.modules["proxy_mod"] = proxy_mod
spec.loader.exec_module(proxy_mod)


def test_parse_args_defaults(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["3proxy.py"])
    args = proxy_mod.parse_args()
    assert args.install_dir == Path(r"C:\Program Files\3proxy")
    assert args.socks_port == 41080
    assert args.http_port == 43128
    assert args.username == "haproxy"


def test_parse_args_overrides(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["3proxy.py", "--socks-port", "1080", "--username", "testuser"])
    args = proxy_mod.parse_args()
    assert args.socks_port == 1080
    assert args.username == "testuser"


@patch("proxy_mod.ctypes")
def test_is_admin_true(mock_ctypes):
    mock_ctypes.windll.shell32.IsUserAnAdmin.return_value = 1
    assert proxy_mod.is_admin() is True


@patch("proxy_mod.ctypes")
def test_is_admin_false(mock_ctypes):
    mock_ctypes.windll.shell32.IsUserAnAdmin.return_value = 0
    assert proxy_mod.is_admin() is False


@patch("proxy_mod.ctypes")
def test_is_admin_exception(mock_ctypes):
    mock_ctypes.windll.shell32.IsUserAnAdmin.side_effect = Exception("No ctypes")
    assert proxy_mod.is_admin() is False


@patch("proxy_mod.urllib.request.urlopen")
def test_fetch_latest_release_success(mock_urlopen):
    mock_response = MagicMock()
    mock_data = {
        "tag_name": "0.9.4",
        "assets": [
            {"name": "3proxy-0.9.4-x86.zip", "browser_download_url": "http://example.com/x86.zip"},
            {"name": "3proxy-0.9.4-x64.zip", "browser_download_url": "http://example.com/x64.zip"}
        ]
    }
    mock_response.read.return_value = json.dumps(mock_data).encode("utf-8")
    mock_response.__enter__.return_value = mock_response
    mock_urlopen.return_value = mock_response
    
    tag, url = proxy_mod.fetch_latest_release()
    assert tag == "0.9.4"
    assert url == "http://example.com/x64.zip"


@patch("proxy_mod.urllib.request.urlopen")
def test_fetch_latest_release_no_x64(mock_urlopen):
    mock_response = MagicMock()
    mock_data = {
        "tag_name": "0.9.4",
        "assets": [
            {"name": "3proxy-0.9.4-x86.zip", "browser_download_url": "http://example.com/x86.zip"}
        ]
    }
    mock_response.read.return_value = json.dumps(mock_data).encode("utf-8")
    mock_response.__enter__.return_value = mock_response
    mock_urlopen.return_value = mock_response
    
    with pytest.raises(ValueError, match="Could not find an x64 .zip asset"):
        proxy_mod.fetch_latest_release()


@patch("proxy_mod.subprocess.run")
@patch("proxy_mod.time.sleep")
def test_register_and_start_service(mock_sleep, mock_subprocess_run):
    def side_effect(*args, **kwargs):
        mock_res = MagicMock()
        mock_res.returncode = 0
        return mock_res
    
    mock_subprocess_run.side_effect = side_effect

    install_dir = Path(r"C:\Program Files\3proxy")
    proxy_mod.register_and_start_service(install_dir)

    # Verify the commands executed: Stop-Service, --remove, --install, Start-Service
    assert mock_subprocess_run.call_count == 4
    
    # Check Stop-Service
    stop_svc_call = mock_subprocess_run.call_args_list[0]
    assert "Stop-Service -Name 3proxy" in stop_svc_call[0][0][2]
    
    # Check --remove
    remove_call = mock_subprocess_run.call_args_list[1]
    assert remove_call[0][0] == [str(install_dir / "3proxy.exe"), "--remove"]
    
    # Check --install
    install_call = mock_subprocess_run.call_args_list[2]
    assert install_call[0][0] == [str(install_dir / "3proxy.exe"), "--install", str(install_dir / "3proxy.cfg")]
    
    # Check Start-Service
    start_svc_call = mock_subprocess_run.call_args_list[3]
    assert start_svc_call[0][0][2] == "Start-Service -Name 3proxy"
