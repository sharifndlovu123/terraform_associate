# Must Knows

## HashiCorp products

| Product | Purpose |
|---------|---------|
| Terraform | Provision infrastructure from declarative config |
| Vault | Secrets and encryption |
| Consul | Service discovery / networking |
| Nomad | Workload orchestration |
| Packer | Build machine images |
| Vagrant | Dev environments |
| Boundary | Secure remote access |
| Waypoint | App build/deploy |

**HCL** is the shared config language toolkit. Used by Terraform (`.tf`), Packer (`.pkr.hcl`), Vault policies (no extension), Consul/Boundary/Waypoint (`.hcl`), Nomad (`.nomad`).
Sentinel does **not** use HCL (its own language).

## Packer in one page

Packer builds a **machine image** once, before deploy: immutable infrastructure, every VM in the fleet identical, faster deploys, and package problems found at build time. It is a tool you run (by hand or on a build server), not a service.

Flow: commit -> CI/CD triggers the Packer build -> provisioners (Ansible, Chef, shell...) configure it -> image stored (AWS: EC2 AMIs) -> Terraform references the image -> provisions infrastructure.

Template parts (HCL, `.pkr.hcl`): `source` (where and what kind of image), `build` (which sources, plus **provisioners** that configure the machine), **post-processors** (run after the image exists: upload, repackage). Terraform references the finished image with a data source (`data "aws_ami"` with `most_recent`, `name_regex`, `owners`).

```bash
packer init .      # install plugins
packer validate .
packer build .
```

Runnable files: [`examples/10-packer`](../examples/10-packer).

## Terraform lifecycle

`write -> init -> plan -> apply -> destroy`

## Architecture

```
Terraform Core --RPC--> Plugins (providers, provisioners) --Go--> Client library --HTTP(S)--> Target APIs
```

- **Terraform Core**: reads config and state, builds the dependency graph, plans changes
- **Plugins**: providers and provisioners; Core talks to them over RPC
- **Client library**: Go SDK the plugin uses to call the API
- **Target APIs**: AWS, Azure, GCP, GitHub, etc., reached over HTTP(S)

## Gotchas

- Providers are distributed separately from Terraform; `terraform init` downloads them
- Everything published to the public Terraform Registry is public-facing
