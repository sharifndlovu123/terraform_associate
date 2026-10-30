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
