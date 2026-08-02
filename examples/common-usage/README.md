# Common Module Usage Example

Reference implementation for consuming the shared Terraform foundation.

This example does **not** create Azure resources.

## Usage

```bash
cd examples/common-usage
terraform init
terraform plan
```

## What It Demonstrates

- Consuming `modules/common` for tags, naming, and metadata
- Generating individual resource names via `modules/naming`
- Merging module-specific tags with the global tag set

## Expected Outputs

With default variables:

| Output | Value |
|--------|-------|
| `resource_prefix` | `cch-dev` |
| `acr_name` | `cch-dev-acr` |
| `storage_name` | Compact globally unique name with location |

See `outputs.tf` for the full output set.
