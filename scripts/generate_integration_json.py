import os
import json
from datetime import datetime

# --- Config ---
BLOCK_LIST = {".github", "boilerplate", "LICENSE", "README.md"}
BASE_REPO_URL = "https://github.com/runZeroInc/runzero-custom-integrations/blob/main"

integration_details = []

for entry in os.listdir("."):
    if entry in BLOCK_LIST or not os.path.isdir(entry):
        continue

    folder_path = os.path.join(".", entry)
    readme_path = os.path.join(folder_path, "README.md")
    config_path = os.path.join(folder_path, "config.json")
    integration_file = None

    # Look for the first .star file
    for f in os.listdir(folder_path):
        if f.endswith(".star"):
            integration_file = f
            break

    # Skip if required files are missing
    if not (os.path.isfile(readme_path) and integration_file):
        continue

    # Default name is the folder name
    friendly_name = entry
    type = "inbound"

    # Override with config.json if available
    if os.path.isfile(config_path):
        try:
            with open(config_path) as cf:
                config = json.load(cf)
                if "name" in config:
                    friendly_name = config["name"]
                if "type" in config:
                    type = config.get("type", "inbound")
        except Exception as e:
            print(f"⚠️  Failed to read config.json in {entry}: {e}")

    integration_details.append(
        {
            "name": friendly_name,
            "type": type,
            "readme": f"{BASE_REPO_URL}/{entry}/README.md",
            "integration": f"{BASE_REPO_URL}/{entry}/{integration_file}",
        }
    )

output = {
    "lastUpdated": datetime.utcnow().isoformat() + "Z",
    "totalIntegrations": len(integration_details),
    "integrationDetails": integration_details,
}

with open("integrations.json", "w") as f:
    json.dump(output, f, indent=2)

print("✅ integrations.json created.")
