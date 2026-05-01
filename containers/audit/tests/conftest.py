import sys
import types

_mp = types.ModuleType("mitmproxy")
_h = types.ModuleType("mitmproxy.http")
_h.HTTPFlow = object  # type: ignore[attr-defined]
sys.modules.setdefault("mitmproxy", _mp)
sys.modules.setdefault("mitmproxy.http", _h)
