# ------------------------------------------------------------------------------
# Monitor Alerts Module — Locals
# ------------------------------------------------------------------------------

locals {
  metric_alerts = {
    for alert in var.metric_alerts : alert.key => alert
  }
}
