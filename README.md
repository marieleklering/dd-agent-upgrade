# Datadog Agent Upgrade Automation

Automated, cross-platform scripts for upgrading the Datadog Agent across a fleet of **Linux** and **Windows** servers. The API key is retrieved at runtime from **AWS Systems Manager Parameter Store**, so no secrets are stored in the repository.

---

## Scripts

| Script | Platform | Method |
|--------|----------|--------|
| `dd-upgrade.sh` | Linux (SUSE, Amazon Linux) | Datadog's official `install_script.sh` via curl |
| `dd-upgrade.ps1` | Windows (x64) | Downloads the latest MSI from Datadog's S3 bucket and runs a silent `msiexec` install |

---


## How It Works

### Linux — `dd-upgrade.sh`

```
Retrieve API key from SSM Parameter Store
        │
        ▼
Is Datadog Agent already installed?
        │
   No ──┤──── Yes
   │         │
   │         ▼
   │    Detect platform (suse / amazon)
   │         │
   │         ▼
   │    Run Datadog install_script.sh
   │    (DD_AGENT_MAJOR_VERSION={{ version }})
   │         │
   │         ▼
   │    Compare pre/post version
   │    ├─ Same    → "Upgrade not required"
   │    └─ Changed → "Upgraded to <version>"
   │         │
   │         ▼
   │    Rotate install logs (keep last 10)
   │
   ▼
 Warn & exit
```

**Key details:**

- **API key source:** `daik-nonprod-datadog-apikey` parameter in AWS SSM (ap-southeast-2), decrypted at runtime.
- **Supported platforms:** SUSE and Amazon Linux — detected via `datadog-agent status`. Any other platform exits with an error.
- **Version placeholder:** `{{ version }}` is expected to be templated in (e.g. by Ansible, Terraform, or a CI pipeline) with the target major version (e.g. `7`).
- **Log rotation:** Renames the install log with a Unix timestamp suffix and retains only the 10 most recent log files.
- **Idempotent:** If the agent is already at the target version, no action is taken.

### Windows — `dd-upgrade.ps1`

```
Retrieve API key from SSM Parameter Store
        │
        ▼
Fetch installers.json from Datadog S3
        │
        ▼
Parse all available versions → sort descending
        │
        ▼
Download latest amd64 MSI to C:\Windows\Temp
        │
        ▼
Run silent msiexec install
(APIKEY, HOSTNAME, optional TAGS)
```

**Key details:**

- **API key source:** Same `daik-nonprod-datadog-apikey` SSM parameter, retrieved via `Get-SSMParameter`.
- **Version selection:** Always installs the **latest available version** by parsing Datadog's `installers.json` manifest and sorting semantically.
- **Silent install:** Uses `msiexec /qn` (no UI) with the API key, hostname, and optional tags passed as MSI properties.
- **Parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-APIKey` | From SSM | Datadog API key (auto-retrieved) |
| `-Location` | `C:\Windows\Temp` | Working directory for the MSI download |
| `-Hostname` | `$env:COMPUTERNAME` | Hostname reported to Datadog |
| `-Tags` | *(none)* | Optional comma-joined Datadog tags |

---

## Prerequisites

- **AWS CLI / AWS Tools for PowerShell** configured with credentials that have `ssm:GetParameter` permission for `daik-nonprod-datadog-apikey`.
- **Linux:** `curl`, `bash`, and an existing Datadog Agent installation (the script skips hosts without one).
- **Windows:** PowerShell 5.1+, internet access to `s3.amazonaws.com` and `ddagent-windows-stable`.
- The `{{ version }}` placeholder in `dd-upgrade.sh` must be rendered before execution (e.g. via Ansible `template` module or `sed`).

---

## Usage

### Linux

```bash
# Render the version placeholder and run (example with sed)
sed 's/{{ version }}/7/' dd-upgrade.sh | sudo bash

# Or via Ansible / automation tool that templates {{ version }}
```

### Windows

```powershell
# Upgrade to latest, using default SSM key and hostname
.\dd-upgrade.ps1

# With custom tags
.\dd-upgrade.ps1 -Tags "env:staging","team:platform"
```

---

## Security Notes

- API keys are never hardcoded — they are fetched from SSM Parameter Store at runtime using IAM-based access.
- The SSM parameter name (`daik-nonprod-datadog-apikey`) suggests this is a **non-production** key. Use a separate parameter for production environments.
- The MSI is downloaded over HTTPS from Datadog's official S3 bucket.
