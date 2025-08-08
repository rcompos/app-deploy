# Install ArgoCD

## Overview

Deploy the ArgoCD service to Kubernetes cluster using Kustomize to support multiple environmental overlays.

## Directory Structure

The deployment of ArgoCD is managed with the following directories.

| Directory | Purpose                 |
|-----------|-------------------------|
| base      | Common files            |
| overlays  | Environmental overrides |

Simplified directory structure, with prod and non-prod overlays.

```sh
install-argocd
├── README.md
├── base
│   ├── v2.13.2
│   │   ├── install.yaml
│   │   └── kustomization.yaml
│   └── v2.14.6
│       ├── install.yaml
│       └── kustomization.yaml
└── overlays
    ├── non-prod
    │   └── nke-site-forge-nonprod
    │       ├── kustomization.yaml
    │       └── overrides.yaml
    └── prod
        └── nke-site-forge-prod
            ├── latest -> v2.14.6
            ├── v2.13.2
            │   ├── kustomization.yaml
            │   └── overrides.yaml
            └── v2.14.6
                ├── kustomization.yaml
                └── overrides.yaml
```

## ArgoCD Install Manifest

This ArgoCD install file (_base/install.yaml_)was obtained with this command.

curl -O https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## Prepare new environment overlay

To prepared to deploy ArgoCD in a new environment, add a new directory under _overlays_ either _prod_ or _non-prod_. The name of the directory should describe the environment (i.e. _nke-cloud-aws-prod_ or _nke-site-aws-dev_).

The directory should contain a _kustomization.yaml_ and patch file(s) (_overrrides.yaml_).

If no changes from base are desired, then in the overlay _kustomization.yaml_ file, change the _patches:_ value to an empty list _[]_ .

```sh
patches: []
```

## Modify an existing overlay

In the overlay directory for the environment (i.e. _overlays/non-prod/nke-cloud-aws-dev_) modify or replace the patch file _overrides.yaml_. Update the _kustomization.yaml_ key _patches_ accordingly.

## Review manifest

From the top-level directory (same directory as _base_ and _overlays_) run the following to generate the kustomized ArgoCD manifest.

```sh
kustomize build overlays/prod/nke-site-forge-prod/latest
```

Review the output before proceeding.

## Apply manifest

From the top-level directory (same directory as _base_ and _overlays_) run the following to apply the ArgoCD manifest.

```sh
kubectl create ns argocd
kustomize build overlays/prod/nke-site-forge-prod/latest | kubectl -n argocd apply -f -
```