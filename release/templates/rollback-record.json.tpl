{
  "record_type": "rollback",
  "rollback_id": "{{ROLLBACK_ID}}",
  "environment": "{{ENVIRONMENT}}",
  "from_release_tag": "{{FROM_RELEASE_TAG}}",
  "to_release_tag": "{{TO_RELEASE_TAG}}",
  "reason": "{{REASON}}",
  "incident_ticket": "{{INCIDENT_TICKET}}",
  "git_commit": "{{GIT_COMMIT}}",
  "terraform_version": "{{TF_VERSION}}",
  "provider_versions": {
    "azurerm": "{{PROVIDER_AZURERM}}"
  },
  "plan_artifact": "{{PLAN_ARTIFACT}}",
  "plan_checksum_sha256": "{{PLAN_CHECKSUM}}",
  "approved_by": {{APPROVED_BY_JSON}},
  "approved_at": "{{APPROVED_AT}}",
  "rolled_back_at": "{{ROLLED_BACK_AT}}",
  "workflow_run_url": "{{WORKFLOW_RUN_URL}}"
}
