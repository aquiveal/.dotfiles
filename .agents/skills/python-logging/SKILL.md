---
name: python-logging
description: Provides specialized context, rules, and tools for implementing, configuring, and debugging python-logging. Use this skill whenever modifying python-logging configurations or adding related functionality.
---
# python-logging

## File Tree

```text
python-logging/
├── assets
├── modules
│   └── python-logging (See AST Map below)
├── references
├── scripts
└── SKILL.md
```

### AST Map: `modules/python-logging`

```python
src\python_logging\__init__.py:
⋮
│__version__ = "26.6.5"
│
⋮
│__all__ = [
│    "__version__",
│    "LoggingSettings",
│    "StdoutFormat",
│    "add_otel_context",
│    "config",
│    "get_console_renderer_format",
│    "get_logger",
│    "get_rich_format",
│    "get_windmill_traceparent",
⋮

src\python_logging\config.py:
⋮
│def generate_traceparent() -> str:
⋮
│def resolve_traceparent() -> str:
⋮
│class StdoutFormat(str, Enum):
⋮
│class LoggingSettings(BaseSettings):
│    """Configuration for the python-logging package."""
│
⋮
│    @computed_field
│    @property
│    def trace_id(self) -> str:
⋮
│    @computed_field
│    @property
│    def span_id(self) -> str:
⋮
│settings = LoggingSettings()

src\python_logging\integrations\__init__.py:
⋮
│__all__ = [
│    "get_windmill_traceparent",
│    "windmill",
⋮

src\python_logging\integrations\windmill.py:
⋮
│def get_windmill_traceparent() -> Optional[str]:
⋮

src\python_logging\main.py:
⋮
│get_logger = structlog.get_logger
│
⋮
│def setup_logging(settings: Optional[LoggingSettings] = None) -> None:
⋮

src\python_logging\service.py:
⋮
│def remove_otel_context(
│    logger: logging.Logger, method_name: str, event_dict: Dict[str, Any]
⋮
│def get_console_renderer_format() -> Tuple[List[Any], List[logging.Handler]]:
⋮
│def get_rich_format() -> Tuple[List[Any], List[logging.Handler]]:
⋮
│def add_otel_context(
│    logger: logging.Logger, method_name: str, event_dict: Dict[str, Any]
⋮
│def setup_otel_provider() -> Optional[LoggerProvider]:
⋮

tests\unit\python_logging\integrations\test_windmill.py:
⋮
│@mock.patch.dict(
│    os.environ,
│    {"WM_TRACEPARENT": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"},
│    clear=True,
│)
│def test_get_windmill_traceparent_valid():
⋮
│@mock.patch.dict(os.environ, {}, clear=True)
│def test_get_windmill_traceparent_missing():
⋮

tests\unit\python_logging\test_config.py:
⋮
│def test_default_settings():
⋮
│@mock.patch.dict(
│    os.environ,
│    {
│        "LOG_LEVEL": "DEBUG",
│        "STDOUT_FORMAT": "rich",
│        "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
│        "TRACEPARENT": "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
│    },
│    clear=True,
│)
│def test_settings_from_env():
⋮
│@mock.patch.dict(
│    os.environ,
│    {
│        "WM_TRACEPARENT": "00-windmilltraceid1234567890123456-windmillspanid12-01",
│    },
│    clear=True,
│)
│def test_settings_from_windmill_env():
⋮
│@mock.patch.dict(
│    os.environ,
│    {
│        "TRACEPARENT": "00-envtraceid1234567890123456789012-envspanid1234567-01",
│        "WM_TRACEPARENT": "00-windmilltraceid1234567890123456-windmillspanid12-01",
│    },
│    clear=True,
│)
│def test_settings_precedence_env_over_windmill():
⋮

tests\unit\python_logging\test_service.py:
⋮
│def test_add_otel_context_with_active_span():
⋮
│@mock.patch("python_logging.service.settings")
│def test_add_otel_context_fallback_to_settings(mock_settings):
⋮
│@mock.patch("python_logging.service.settings")
│def test_setup_otel_provider_no_endpoint(mock_settings):
⋮
│@mock.patch("python_logging.service.settings")
│def test_setup_otel_provider_with_endpoint(mock_settings):
⋮
│def test_remove_otel_context():
⋮
```
