# Harness Complex Multi-Infrastructure Troubleshooting Lab

This repo is a deliberately breakable Harness CD lab. It is designed for learning how to troubleshoot a realistic pipeline that crosses three infrastructure types:

1. Windows Server / IIS over WinRM
2. Kubernetes Direct
3. Linux / PDC over SSH

The goal is not only to make the pipeline green. The goal is to learn **where to look when it turns red**.

## Architecture

```text
Git / Harness Pipeline
        |
        v
[Stage 1] Preflight / change inputs
        |
        v
[Stage 2] Windows IIS DEV (WinRM / PDC)
        |  - remote PowerShell
        |  - IIS app pool + site
        |  - health check
        |  - rollback
        v
[Stage 3] Approval gate
        |
        v
[Stage 4] Kubernetes TEST (Kubernetes Direct)
        |  - rolling deployment
        |  - readiness/steady state
        |  - rollback
        v
[Stage 5] Linux DR (SSH / PDC)
           - remote Bash
           - health check
           - rollback
```

## Designed for your lab

Suggested Harness project identifier: `Windows_patern_examples`.

Suggested Windows target: your IIS server at `192.168.1.101` using the WinRM PDC infrastructure you are already building.

For Kubernetes, point the sample infrastructure at your existing local cluster/connector and use a lab namespace such as `harness-multi-infra-lab`.

For Linux, you can use a Linux VM or a lab node that you can safely reach over SSH. Do **not** run the Linux mutation exercises directly on an important production/control-plane host.

## Repo contents

```text
.harness/
  pipeline-complex.yml
  service-windows.yml
  service-k8s.yml
  service-linux.yml
  environment-dev.yml
  environment-test.yml
  environment-dr.yml
  infra-windows-pdc.yml
  infra-k8s.yml
  infra-linux-pdc.yml
windows/
  Deploy-IIS.ps1
  Health-IIS.ps1
  Rollback-IIS.ps1
k8s/
  deployment.yaml
  service.yaml
  values.yaml
linux/
  deploy.sh
  health.sh
  rollback.sh
docs/
  FAILURE-LABS.md
  TROUBLESHOOTING-CHECKLIST.md
```

## Important: replace these identifiers first

Search the repo for `REPLACE_ME` and update:

- Harness project identifier if different
- WinRM credential reference
- Windows PDC connector or hosts
- Kubernetes connector
- Linux PDC connector / SSH credential
- Git connector if you attach manifests from Git

No passwords are stored in this repo. Keep usernames/passwords/tokens in Harness Secrets and reference them from connectors/credentials.

## Recommended build order

### 1. Make Windows green first

Create/import:

- `.harness/service-windows.yml`
- `.harness/environment-dev.yml`
- `.harness/infra-windows-pdc.yml`

Then build a WinRM Deploy stage and use the PowerShell from `windows/Deploy-IIS.ps1` in a **Command** step executed on the target host.

Use `windows/Health-IIS.ps1` as the next command unit/step.

### 2. Make Kubernetes green

Create/import:

- `.harness/service-k8s.yml`
- `.harness/environment-test.yml`
- `.harness/infra-k8s.yml`

Point the Kubernetes manifest in the Harness service to the `k8s/` directory in this Git repo. Use a `K8sRollingDeploy` step and a `K8sRollingRollback` rollback step.

### 3. Add Linux/SSH

Create/import:

- `.harness/service-linux.yml`
- `.harness/environment-dr.yml`
- `.harness/infra-linux-pdc.yml`

Use the shell files under `linux/` as the basis of your SSH Command step.

### 4. Add approval and failure strategy

Place an approval between the Windows and Kubernetes stages. Configure the deployment stages with **All Errors -> Stage Rollback**.

### 5. Break it on purpose

Run with `failureMode=NONE`. Once all stages are green, use the exercises in `docs/FAILURE-LABS.md`.

## Failure modes built into the application scripts

The scripts accept a failure mode so you can practice deterministic failures without randomly damaging the environment.

Windows:

- `NONE`
- `WINDOWS_SCRIPT_FAILURE`
- `WINDOWS_HEALTH_FAILURE`
- `WINDOWS_STOP_APPPOOL`

Kubernetes:

- `NONE`
- `K8S_BAD_IMAGE`
- `K8S_BAD_READINESS`

Linux:

- `NONE`
- `LINUX_SCRIPT_FAILURE`
- `LINUX_HEALTH_FAILURE`

Infrastructure failures such as bad WinRM credentials, wrong delegate selector, bad connector, closed port, DNS failure, bad artifact reference, and approval rejection are intentionally configured manually in Harness. That makes you learn how the **Harness execution log differs from an application-script failure**.

## What to learn from every failure

For each failed run, answer these five questions before changing anything:

1. Which stage failed?
2. Did Harness reach a delegate?
3. Did the delegate reach the target infrastructure?
4. Did authentication succeed?
5. If remote execution started, which exact command/app health condition failed?

That sequence prevents changing PowerShell when the real problem is the delegate, or changing credentials when the real problem is IIS.

## Suggested pipeline variables

Create these at pipeline scope:

| Variable | Example | Purpose |
|---|---|---|
| `failureMode` | `NONE` | Select the intentional failure |
| `releaseVersion` | `v1` | Displayed by each sample workload |
| `windowsHealthUrl` | `http://192.168.1.101:8085/health.txt` | IIS health endpoint |
| `k8sNamespace` | `harness-multi-infra-lab` | K8s namespace |
| `linuxPort` | `8086` | Linux sample service port |

## First lab run

Use:

```text
failureMode = NONE
releaseVersion = v1
```

Expected result:

- Windows site returns `OK - Windows IIS - v1`
- Kubernetes rollout reaches steady state
- Linux service health check returns HTTP 200
- Pipeline completes successfully

Then start with Failure Lab 1.
