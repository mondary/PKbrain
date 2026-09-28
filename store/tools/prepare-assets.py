"""Extract only the wallpaper from the supplied reference, never its product UI."""
import base64
import re
import sys
from pathlib import Path

reference = Path(sys.argv[1]).read_text()
match = re.search(r'class="hero-bg".*?<img[^>]+src="data:image/jpeg;base64,([^"]+)"', reference, re.S)
assert match, "Hero wallpaper not found in the supplied reference"
Path(sys.argv[2]).write_bytes(base64.b64decode(match.group(1)))
