"""Exercise fresh environment generation without a database or real credentials."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

base = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="baba-env-test-") as directory:
    panel = Path(directory)
    (panel / ".env.example").write_text(
        "APP_ENVIRONMENT_ONLY=true\nAPP_DEBUG=true\nAPP_KEY=\n", encoding="utf-8"
    )
    environment = dict(os.environ, BABA_APP_URL="https://panel.example.test",
                       BABA_TIMEZONE="Asia/Kolkata", BABA_EMAIL="admin@example.test",
                       BABA_DB_PASSWORD="disposable-database-test-value")
    command = ["php", str(base / "scripts/configure-panel.php"), "environment", str(panel)]
    subprocess.run(command, env=environment, check=True, capture_output=True)
    content = (panel / ".env").read_text(encoding="utf-8")
    values = dict(line.split("=", 1) for line in content.splitlines() if "=" in line)
    assert json.loads(values["APP_ENVIRONMENT_ONLY"]) == "false", "Database-backed admin settings would be ignored"
    assert json.loads(values["APP_DEBUG"]) == "false"
    assert json.loads(values["APP_URL"]) == "https://panel.example.test"
    assert sum(line.startswith("APP_ENVIRONMENT_ONLY=") for line in content.splitlines()) == 1
    result = subprocess.run(command, env=environment, capture_output=True)
    assert result.returncode != 0, "Existing environment was not protected"
    assert (panel / ".env").read_text(encoding="utf-8") == content
print("PASS: fresh environment enables database settings, production defaults and existing-file protection.")
