# Hyperledger Bevel on Minikube: Deployment & Configuration Report

This document records the modifications and architectural decisions made to successfully deploy a multi-organization Hyperledger Fabric network on a local Minikube cluster using Bevel.

## 1. Environment Specifications
- **Cluster:** Minikube v1.38.1 (Kubernetes v1.30.7)
- **Resources:** 12GB RAM, 4 CPUs
- **Secrets:** HashiCorp Vault (KV Secrets Engine v2 enabled at `secretsv2/`)
- **GitOps:** FluxCD (Git HTTPS Protocol)

---

## 2. Core Framework Fixes (Surgical Repairs)

### A. Ansible Variable Shadowing Fix
**File:** `platforms/shared/configuration/roles/check/k8_component/tasks/main.yaml`

**Problem:** Multiple tasks (Namespace check and ServiceAccount check) were registering results to the same `result` variable. This caused the Namespace check results to be overwritten, leading to infinite "Wait for Namespace" loops.

**Fix Snippet:**
```yaml
# Use unique register names per task
- name: Check {{ component_type }} is created (no_retry)
  k8s_info: ...
  register: namespace_result_no_retry

- name: Wait for {{ component_type }} (retry)
  k8s_info: ...
  register: namespace_result_retry

# Consolidate at the end
- name: Set final result fact
  set_fact:
    result: "{{ namespace_result_no_retry if (...) else (namespace_result_retry if (...) else ...) }}"
```

### B. Unique StorageClass Naming
**File:** `platforms/shared/charts/bevel-storageclass/templates/_helpers.tpl`

**Problem:** `StorageClass` is cluster-scoped. Bevel's default naming caused collisions when multiple organizations tried to create a class named `storage-ca`.

**Fix Snippet:**
```yaml
{{- define "bevel-storageclass.fullname" -}}
{{- printf "storage-%s-%s" .Release.Namespace .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```
*Note: In the final stabilization phase, we transitioned to the `standard` Minikube storage class to ensure maximum compatibility with host-path volume binding.*

### C. Missing Variable Scope (YAML Indentation)
**File:** `platforms/shared/configuration/roles/create/job_component/vars/main.yaml`

**Problem:** Critical variables like `bevel_alpine_version` and `fabric_tools_image` were incorrectly indented under the `charts:` dictionary, making them undefined in the global Ansible scope.

**Fix:**
```yaml
# Before:
charts:
  bevel_alpine_version: latest

# After:
bevel_alpine_version: latest
fabric_tools_image: bevel-fabric-tools
```

---

## 3. Configuration Optimizations

### Kubeconfig Portability
Updated `build/config` to use relative paths for certificates:
```yaml
clusters:
- cluster:
    certificate-authority: ca.crt  # Changed from absolute path
    server: https://192.168.49.2:8443
```

### Network Manifest (`network.yaml`)
- Added `type: orderer` and `type: peer` to organization root objects.
- Added `type: anchor` to peer objects in the `channels.participants` list.
- Configured GitOps with the `local` branch to match the active development branch.

---

## 4. Current Network State
- **Channel:** `AllChannel` created and joined by all peers.
- **Organization CAs:** Running and certificates registered in Vault.
- **Orderer/Peers:** All pods in `Running` state across namespaces.

---
**Report Generated:** May 10, 2026
