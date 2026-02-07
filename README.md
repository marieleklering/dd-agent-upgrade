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
