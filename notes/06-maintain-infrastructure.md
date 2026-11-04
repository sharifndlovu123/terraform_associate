# Maintain Infrastructure

## Key points

- Upgrading provider and Terraform versions is maintenance too: pin what deploys (lock file), and run a nightly canary that floats to the newest allowed versions so breakage is found overnight and fixed in the morning. See [`examples/07-versions`](../examples/07-versions) and its `nightly-check.sh`

## Commands

## Gotchas
