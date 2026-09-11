# Failure Labs

Always get one completely successful `failureMode=NONE` execution before starting.

## Lab 1 — Wrong WinRM password

Change the Harness WinRM credential to a deliberately incorrect lab password.

Expected failure boundary: **authentication before remote PowerShell runs**.

Look for:

- delegate selected / task acquired
- connection attempt to Windows host
- authentication scheme (NTLM/Kerberos)
- invalid credential / incompatible authentication errors

Fix: restore the correct secret/credential and rerun.

## Lab 2 — Delegate cannot acquire task

Add a delegate selector/tag to the Windows step that no delegate has.

Expected: `No eligible delegates` / `Active eligible delegates were unable to acquire task`-style failure.

Key lesson: do not troubleshoot WinRM yet. The task never reached a delegate capable of attempting WinRM.

## Lab 3 — Delegate selected, network path broken

Temporarily point the Windows infrastructure to a non-existent lab IP (for example, an unused address in your private subnet) or block the lab path only if you know how to safely restore it.

Expected: connectivity/timeout failure rather than authentication failure.

Check from the **delegate pod/container**, not only from the Kubernetes node:

```bash
nc -vz 192.168.1.101 5985
```

For HTTPS WinRM use 5986.

## Lab 4 — Intentional Windows PowerShell failure

Run:

```text
failureMode = WINDOWS_SCRIPT_FAILURE
```

Expected: WinRM connection succeeds, remote execution begins, script exits `42`, stage rollback begins.

Key lesson: this is an application/command failure, not delegate or credential failure.

## Lab 5 — IIS deploy succeeds but health fails

Run:

```text
failureMode = WINDOWS_HEALTH_FAILURE
```

Expected: IIS configuration completes; health command hits a missing URL and fails.

Troubleshoot with:

```powershell
Get-Website
Get-WebAppPoolState HarnessTroubleshootingLabPool
Invoke-WebRequest http://localhost:8085/health.txt -UseBasicParsing
Get-ChildItem C:\inetpub\HarnessTroubleshootingLab
```

## Lab 6 — IIS application pool stopped

Run:

```text
failureMode = WINDOWS_STOP_APPPOOL
```

Expected: deployment creates the site then intentionally stops its app pool. Health should fail.

Check:

```powershell
Get-WebAppPoolState HarnessTroubleshootingLabPool
Get-Website HarnessTroubleshootingLab
```

## Lab 7 — Approval rejected

Reject the promotion approval.

Expected failure domain: pipeline governance/human gate. No Kubernetes deployment should begin.

Key lesson: distinguish approval failure from downstream infrastructure failure.

## Lab 8 — Kubernetes bad image

In `kubernetes_lab`, change `k8sImage` to something that does not exist, for example:

```text
nginx:this-tag-should-not-exist-harness-lab
```

Expected:

- manifest applies
- pods are created
- image pull fails
- rollout never reaches steady state
- Harness K8s stage fails/rolls back

Diagnose:

```bash
kubectl get pods -n harness-multi-infra-lab
kubectl describe pod -n harness-multi-infra-lab <pod>
kubectl get events -n harness-multi-infra-lab --sort-by=.lastTimestamp
```

## Lab 9 — Kubernetes readiness failure

Set service variable:

```text
readinessPort = 9999
```

Expected: container can run, but readiness probe fails and rollout does not become healthy.

Key lesson: Running != Ready.

## Lab 10 — Kubernetes connector or delegate failure

Change the infrastructure connector reference to a wrong/nonexistent test connector, or use a delegate selector with no matching delegate.

Compare this log with Lab 8. Lab 8 reaches Kubernetes and creates resources. This lab should fail before the workload is successfully manipulated.

## Lab 11 — Linux remote script failure

Run:

```text
failureMode = LINUX_SCRIPT_FAILURE
```

Expected: SSH succeeds and Bash exits `61`.

## Lab 12 — Linux health port failure

Run:

```text
failureMode = LINUX_HEALTH_FAILURE
```

Expected: deployment starts the Python HTTP server, but health checks port `65530` and fails.

## Lab 13 — Port closed vs bad credential

Practice recognizing these separately:

- closed/unreachable 5985: network/connectivity
- reachable 5985 + invalid identity: authentication
- authenticated + script exit: remote command/application
- IIS created + HTTP unhealthy: application/health

## Lab 14 — Artifact/reference failure

When you later add a real ZIP or NuGet/Artifactory artifact to the Windows service, deliberately choose a nonexistent artifact version/path.

Expected: artifact resolution/download failure occurs before or during artifact copy, depending on configuration.

## Lab 15 — Rollback itself fails

After you understand normal rollback, intentionally put a bad command in the rollback step, such as referencing a non-existent lab path.

Goal: identify the **original deployment failure** separately from the **rollback failure**. Never stop reading at the final red step.
