# OAS

This repository is the root folder for the full OAS project.

## Workflow (hands-off)
- Run **.\update.ps1** whenever there is an update.
- The script pulls latest changes, applies new patches (if any), commits and pushes automatically.

## Structure
- patches/   : patch files delivered by the assistant (001.patch, 002.patch, ...)
- scripts/   : helper scripts
- update.ps1 : main updater (one command)
- .oas/      : local state (not committed)
