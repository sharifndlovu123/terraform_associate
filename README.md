# Terraform Associate

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

## Credit

These notes come from studying the ExamPro Terraform Associate course (hosted on the freeCodeCamp YouTube channel). Everything here is paraphrased in my own words with my own example code; none of it is a copy of the course material. For the real thing, including their cheat sheets, practice exams and flash cards, go to [exampro.co/terraform](https://www.exampro.co/terraform).

## Conventions

- Keep each note short and scannable: bullets, tables, code blocks.
- Anything worth remembering for the exam but easy to forget goes under a `Gotchas` heading.
- Put working code in `examples/` and link to it from the notes rather than pasting long listings.
