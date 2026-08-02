{
  "audit_version": "1.0",
  "timestamp": "{{TIMESTAMP}}",
  "event_type": "{{EVENT_TYPE}}",
  "actor": "{{ACTOR}}",
  "environment": "{{ENVIRONMENT}}",
  "git_ref": "{{GIT_REF}}",
  "git_commit": "{{GIT_COMMIT}}",
  "release_tag": "{{RELEASE_TAG}}",
  "terraform_version": "{{TF_VERSION}}",
  "provider_versions": {{PROVIDER_VERSIONS_JSON}},
  "artifact": {
    "name": "{{ARTIFACT_NAME}}",
    "checksum_sha256": "{{ARTIFACT_CHECKSUM}}"
  },
  "approvers": {{APPROVERS_JSON}},
  "workflow": {
    "name": "{{WORKFLOW_NAME}}",
    "run_id": "{{WORKFLOW_RUN_ID}}",
    "url": "{{WORKFLOW_RUN_URL}}"
  },
  "metadata": {{METADATA_JSON}}
}
