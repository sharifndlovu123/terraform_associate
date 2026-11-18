# 12 Testing

Terraform's testing ladder, bottom to top, and what covers each rung here:

| Rung | Tools | In this example |
|------|-------|-----------------|
| Static analysis (no deploy) | `terraform fmt -check`, `terraform validate`, `terraform plan`, tflint, Sentinel | commands below |
| Unit tests (one module) | `terraform test`, Terratest | `tests/main.tftest.hcl` |
| Integration tests (modules together) | Terratest, `terraform test` with several modules | not shown |
| End-to-end (persistent environment) | full environment, e.g. Gruntwork reference architecture | not shown |

```bash
terraform fmt -check
terraform init
terraform validate
terraform test            # runs tests/*.tftest.hcl, creates and destroys everything itself
terraform test -verbose
```

`terraform test` (1.6+) is the built-in alternative to Terratest: tests are written in HCL (`run` blocks with `assert`), not Go. Terratest is still what you reach for to hit the deployed thing (for example an HTTP check on a load balancer). Runs offline here.
