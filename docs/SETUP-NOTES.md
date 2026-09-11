# Setup Notes

## Windows

This lab assumes IIS is installed and WinRM is already configured on the target. Your current Windows lab uses port 5985 for WinRM HTTP.

The pipeline's site listens on port 8085 so it does not have to replace the default IIS site.

Allow TCP 8085 in the Windows firewall only if you want to test the health endpoint from outside the server. The remote PowerShell health test uses localhost, so external 8085 access is not required for the pipeline itself.

## Kubernetes

Create the namespace if Harness is not managing it via a manifest:

```bash
kubectl create namespace harness-multi-infra-lab
```

Attach these manifests to the Harness Kubernetes service:

```text
/k8s/deployment.yaml
/k8s/service.yaml
```

If your Harness manifest setup does not permit service-variable expressions exactly as shown, replace the image and readiness port with Harness values-file expressions using the pattern your existing service uses.

## Linux

The sample uses `python3 -m http.server`; install Python 3 on the lab host. Configure an SSH PDC infrastructure and credential in Harness.
