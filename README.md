# Datadog Agent Upgrade Automation

Automated, cross-platform scripts for upgrading the Datadog Agent across a fleet of **Linux** and **Windows** servers. The API key is retrieved at runtime from **AWS Systems Manager Parameter Store**, so no secrets are stored in the repository.

---

## Scripts

| Script | Platform | Method |
|--------|----------|--------|
| `dd-upgrade.sh` | Linux (SUSE, Amazon Linux) | Datadog's official `install_script.sh` via curl |
| `dd-upgrade.ps1` | Windows (x64) | Downloads the latest MSI from Datadog's S3 bucket and runs a silent `msiexec` install |

---

