# Terraform Associate

> Code-first study notes, a cheat sheet and runnable examples for the HashiCorp Terraform Associate certification.

Personal study notes and cheat sheet from a HashiCorp Terraform Associate certification course.
Code and commands only: no conceptual or theory notes (e.g. what IaC is). Quick reference first.

## Layout

| Path | Purpose |
|------|---------|
| [`cheatsheet.md`](cheatsheet.md) | One-page quick reference: CLI commands, common HCL patterns, gotchas |
| [`notes/`](notes/) | Course notes, one file per exam objective |
| [`examples/`](examples/) | Small `.tf` configs that run as-is, no cloud account needed |

## Notes by exam objective

0. [Must knows](notes/00-must-knows.md) (HashiCorp products, lifecycle, architecture)
1. [Terraform fundamentals](notes/01-fundamentals.md) (providers, resources, state basics)
2. [Core workflow](notes/02-core-workflow.md) (`init`, `plan`, `apply`, `destroy`)
3. [Configuration](notes/03-configuration.md) (variables, outputs, functions, dependencies)
4. [Modules](notes/04-modules.md)
5. [State management](notes/05-state.md)
6. [Maintain infrastructure](notes/06-maintain-infrastructure.md) (import, drift, debugging)
7. [HCP Terraform](notes/07-hcp-terraform.md)
8. [Ecosystem tools](notes/08-ecosystem-tools.md) (Consul, Vault, Atlantis, CDKTF, Terragrunt, Terratest, testing)

## Credit

These notes come from studying the ExamPro Terraform Associate course (hosted on the freeCodeCamp YouTube channel). Everything here is paraphrased in my own words with my own example code; none of it is a copy of the course material. For the real thing, including their cheat sheets, practice exams and flash cards, go to [exampro.co/terraform](https://www.exampro.co/terraform).

The Sentinel example in [`examples/08-hcp-terraform/sentinel`](examples/08-hcp-terraform/sentinel) also follows two HashiCorp tutorials, again paraphrased with my own policy, mocks and tests:

- [Sentinel and HCP Terraform integration](https://developer.hashicorp.com/terraform/tutorials/policy/sentinel-cloud-integration)
- [Test Sentinel policies](https://developer.hashicorp.com/terraform/tutorials/policy/sentinel-testing)

The 004 update sweep (see [`SWEEP-004.md`](SWEEP-004.md)) checked the notes against HashiCorp's own material, again paraphrased:

- [Terraform Associate 004 review](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004) and the Terraform docs on [developer.hashicorp.com](https://developer.hashicorp.com/terraform) (language, CLI and HCP Terraform docs, v1.12.x pages)
- [Terraform changelogs](https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md) for the versions a feature arrived in
- [HashiCorp pricing](https://www.hashicorp.com/pricing) and the [HashiCorp blog](https://www.hashicorp.com/blog) for plans and product news
- [Inject secrets into Terraform using the Vault provider](https://developer.hashicorp.com/terraform/tutorials/secrets/secrets-vault) for [`examples/13-vault`](examples/13-vault)

## Conventions

- Keep each note short and scannable: bullets, tables, code blocks.
- Anything worth remembering for the exam but easy to forget goes under a `Gotchas` heading.
- Put working code in `examples/` and link to it from the notes rather than pasting long listings.
