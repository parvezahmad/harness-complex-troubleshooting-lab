# Harness Troubleshooting Checklist

Use this order every time.

## 1. Pipeline/YAML layer

- Did the pipeline compile/save?
- Are all runtime inputs resolved?
- Do service/environment/infrastructure identifiers exist in the same scope?
- Is the deployment type correct (`WinRm`, `Kubernetes`, `Ssh`)?

## 2. Delegate layer

- Was a delegate selected?
- Did a delegate acquire the task?
- Is an overly restrictive delegate selector configured?
- Is the delegate connected and healthy?

## 3. Connector / credential layer

- Can the connector validate?
- Is the secret reference correct?
- For WinRM, is the domain/username/password correct?
- NTLM/Kerberos configuration compatible?

## 4. Network layer

From the delegate runtime, verify target reachability.

Windows WinRM HTTP:

```bash
nc -vz <windows-host> 5985
```

Windows WinRM HTTPS:

```bash
nc -vz <windows-host> 5986
```

Kubernetes:

- connector test succeeds
- API server reachable
- namespace accessible

Linux SSH:

```bash
nc -vz <linux-host> 22
```

## 5. Remote execution layer

If logs say connection/authentication succeeded, stop changing connectors.

Inspect:

- exact command
- exit code
- PowerShell/Bash stderr
- filesystem permissions
- required modules/binaries

## 6. Application layer

Windows/IIS:

```powershell
Get-Website
Get-WebAppPoolState HarnessTroubleshootingLabPool
Get-NetTCPConnection -LocalPort 8085 -ErrorAction SilentlyContinue
Invoke-WebRequest http://localhost:8085/health.txt -UseBasicParsing
```

Kubernetes:

```bash
kubectl get deploy,pod,svc -n harness-multi-infra-lab
kubectl describe pod -n harness-multi-infra-lab <pod>
kubectl logs -n harness-multi-infra-lab <pod>
kubectl get events -n harness-multi-infra-lab --sort-by=.lastTimestamp
```

Linux:

```bash
ps -ef | grep '[h]ttp.server'
curl -v http://127.0.0.1:8086/health.txt
cat ~/harness-multi-infra-lab/http.log
```

## 7. Harness failure-strategy layer

- Which error triggered the strategy?
- Did the stage retry, abort, or rollback?
- Did the original step fail, or did rollback fail later?
- Was a failure ignored/marked successful?

## Fast mental model

```text
Harness YAML
   -> Delegate acquisition
      -> Connector/credential
         -> Network
            -> Remote command
               -> Application
                  -> Health verification
                     -> Rollback
```

Always find the **leftmost layer that failed** before changing configuration to the right.
