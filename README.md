# ArgoCD Applications

Helm charts and ArgoCD configuration for deploying applications to a Kubernetes cluster. Bootstrap all app-of-apps and applications in-cluster with the ArgoCD command-line interface.

## Overview 

This repo contains Helm charts and environmental configuration for the purpose of deploying applications in a Kubernetes cluster.

* Environmental configurations, such as ___nke-cloud-aws-prod___ and ___nke-site-forge-az00___, are located under the ___environments___ directory.
* Directories at root-level contain Helm charts or Kustomize directories with a kustomization.yaml (with the exception of the ___environments___, and ___scripts___ directories).
* Directory names with the prefix ___aoa-___ are ArgoCD application-of-applications (app-of-apps) Helm charts.

Externally-sourced Helm charts are stored in the nvcr.io Helm chart registry and are deployed with values overrides.

https://helm.ngc.nvidia.com/j7sbcjl3qgta

An ArgoCD _application-of-applications_ (_app-of-apps_) Helm chart defines a set of applications to be deployed (i.e. application Helm charts or Kustomize directories).

The app-of-apps Helm charts contain an app-generator (scripts/app-generator) that renders the child app ArgoCD Application manifests.

## Install ArgoCD

To install ArgoCD in-cluster and maintain infrastructure-as-code, follow the readme for installing the ArgoCD service in the _scripts/install-argocd_ directory.

https://gitlab-master.nvidia.com/nke/nke-site-deploy/-/tree/main/scripts/install-argocd

This is a Kustomize-based approach for bootstrapping ArgoCD.

## App-of-Apps

By convention, the scripts expect all Helm charts starting with __aoa-__ to be ArgoCD app-of-apps.  The name of the ArgoCD project and associated app-of-apps will be the same.

The app-of-apps pattern can be used to deploy a set of applications.

https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/

An app-of-apps have a directory structure like so. Each app-of-apps is in a directory named after the chart version. This supports multiple versions and multiple deployment environments.

```sh
aoa-infra
└── 0.1.0   # version from Chart.yaml
    ├── Chart.yaml
    ├── README.md
    └── templates
        └── app.yaml -> ../../scripts/app-generator/v1/templates/app.yaml
```

The values file and ArgoCD Application manifest for the app-of-apps Helm chart is stored in the directory _environments_ under an environment directory, such as _nke-site-forge-az00_.

```sh
environments/prod/forge/nke-site-forge-az00/aoa-infra
├── application.yaml
└── values.yaml
```

The environment specific files under have the following purpose:

| File             | Description                               |
|----------------- | ----------------------------------------- |
| application.yaml | ArgoCD Application YAML                   |
| values.yaml      | ArgoCD App-of-apps Helm Chart values file |
| app-project.yaml | ArgoCD AppProject YAML (optional)         |

Note: The optional _app-project.yaml_ file allows for RBAC specifications.

The template file _app.yaml_ acts as an application generator by ranging over the _apps_ key in _values.yaml_.

------------------------------

## Deploy Environment

Specify the environment to target when using the deploymnent scripts.
Set the environmental variable __DEPLOY_ENV__ to the name of the environment to deploy to. The variable may be exported or specified along with each command invocation (recommended).

The deployment environments are located under the directory _environments_.

### Directory Structure for Enviroments

```sh
environments
├── non-prod
│   └── forge
│       ├── nke-site-forge-az24
│       ...
│       └── nke-site-forge-az60-dev
└── prod
    └── forge
        ├── nke-site-forge-az01
        ├── nke-site-forge-az02
        ...
        ├── nke-site-forge-az60
        └── nke-site-forge-az61
```

### Enviroment Directory

Example directory structure of deployment environment _nke-site-forge-az00_.

```sh
environments/
└── prod/
    └── forge/
        ├── nke-site-forge-az01/
        │   ├── aoa-infra/
        │   ├── aoa-nke-site/
        │   ├── aoa-observability/
        │   ├── values-cert-manager.yaml
        │   ├── values-cloud-workflow-engine.yaml
        │   ├── values-cloudnative-pg.yaml
        │   ├── values-cnpg-cloud.yaml
        │   ├── values-cnpg-site.yaml
        │   ├── values-cnpg-temporal.yaml
        │   ├── values-forge-workflow-engine.yaml
        │   ├── values-kube-prometheus-stack.yaml
        │   ├── values-kubernetes-replicator.yaml
        │   ├── values-kubetrust-verifier.yaml
        │   ├── values-nke-external-secrets.yaml
        │   ├── values-nke-storage.yaml
        │   ├── values-nvault-k8s.yaml
        │   ├── values-site-workflow-engine.yaml
        │   ├── values-skyhook-operator.yaml
        │   └── values-temporal.yaml
```

## Applications to Deploy

In an app-of-apps Helm chart values file (i.e. _environments/prod/forge/nke-site-forge-az00/aoa-infra/values.yaml_), the applications are specified by including them as values of the key ___apps___.

### App-of-app Values Specification

The values.yaml file for the app-of-apps supports the following yaml fields.

```yaml
# App-of-apps app values specification

apps:
  - name: nginx                       # Name of the ArgoCD application (required)
    chartDir: nginx                   # Directory name where chart resides (required if chart not specified)
    chartVer: "18.2.2"                # Helm chart version-named directory, i.e. 18.2.2 for path nginx/18.2.2 (required if chart not specified)
    chart: nginx                      # Helm registry chart name (optional, required if repoURL is Helm registry)
    kustomize: true                   # Deploy Kustomize application (optional)
    repoURL: https://my-git-server.com/data/my-repo.git   # Git chart repo, Helm Registry or Kustomize repo (optional)
    targetRevision: my/branch         # Git target revision (optional) (For Helm, this refers to the chart version.)
    path: path/to/my-chart            # Path under chart repo (optional, required if kustomize is true)
    fullnameOverride: nginx-poc       # Override name of app to deploy (optional)
    namespace: custom-namespace       # Namespace (optional)
    addHelmFiles: true                # Add files to Helm chart from additional source (optional)
    addHelmFilesDir: environments/prod/forge/nke-cloud-aws-dev/my-nginx-bitnami # Override directory of additional Helm files (optional if addHelmFiles)
    targetRevisionHelmFiles: my/rev   # Target revision for added Helm files (optional, required if addHelmFiles is true)
    valueFiles:                       # List of values file (optional list)
      - values-nke-cloud-aws-dev.yaml # Values file (optional)
      - values-my-env.yaml            # Values file (optional will be merged)
    finalizers:                       # Metadata finalizers (optional list)
      - resources-finalizer.argocd.argoproj.io # Example
    ignoreDifferencesMetadataLabels: true # Ignore differences (optional)
    ignoreMissingValueFiles: true     # Ignore missing values files (optional) 
    syncOptions:                      # syncPolicy syncOptions (optional list)
      - CreateNamespace=true          # Example
    automated:                        # syncPolicy automated (optional)
      prune: true                     # Example
      selfHeal: true                  # Example
      allowEmpty: false               # Example
    info:                             # Extra information (optional list)
      - name: 'Optional info'         # Example
        value: 'Optional value'
```

### Example values files for app-of-apps

In this example, the app-of-apps _aoa-demo_ includes the following applications.

* argocd
* nginx-bitnami
* nginx-demo
* metrics-server

The following is an example _values.yaml_ for the app-of-apps _aoa-demo_.

```yaml
spec:
  name: aoa-demo
  env: nke-site-forge-az00
  project: default
  destination:
    server: https://kubernetes.default.svc
    namePrefix: ""
  source:
    repoURL: https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
    targetRevision: main
  ignoreDifferencesMetadataLabels: true
  ignoreMissingValueFiles: true
  syncPolicy:
    automated: {}
    syncOptions:
      - CreateNamespace=true

apps:
  - name: argocd # Kustomize with kustomization.yaml expected at path
    repoURL: https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
    path: install-argocd/overlays/prod/nke-site-forge-prod
    kustomize: true
  - name: nginx-bitnami # Remote Helm Registry with files merged from additional source
    repoURL: https://charts.bitnami.com/bitnami
    targetRevision: "18.2.2"
    chart: nginx
    addHelmFiles: true # Default is files from environments/prod/forge/nke-cloud-aws-dev/nginx-bitnami
    targetRevisionHelmFiles: nke-123/my-feature-branch
    addHelmFilesDir: environments/prod/forge/nke-site-forge-az00/my-nginx-bitnami
  - name: nginx-demo # Remote Helm Registry
    repoURL: https://charts.bitnami.com/bitnami
    targetRevision: "18.2.2"
    chart: nginx
  - name: metrics-server # Helm chart in-repo
    chartDir: metrics-server
    chartVer: "0.7.1"
```

> [NOTE]
> Every application in the app-of-apps apps list must have a values files at _environments/prod/forge/nke-site-forge-azNN_ with name _values-<app_name>.yaml_. If this values file does not exist, then the application deployment will fail.

### Example ArgoCD app-of-apps application.yaml

The following is an example ArgoCD Application manifest for the app-of-apps _aoa-demo_. Note the valueFiles field corresponding to the _values.yaml_ above.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aoa-demo
  namespace: argocd
spec:
  project: default
  destination:
    namespace: argocd
    server:  https://kubernetes.default.svc
  sources:
    # Helm chart
    - repoURL: https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
      targetRevision: main
      path: aoa-demo/v1
      helm:
        valueFiles:
        - $values/environments/prod/forge/nke-site-forge-az00/aoa-demo/values.yaml
    # Values files
    - repoURL: https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
      targetRevision: main
      ref: values

  syncPolicy:
    automated: {}
    syncOptions:
    - CreateNamespace=true
```

> [NOTE]
> When the app-of-apps is deployed, the specified ArgoCD Application manifests will be created by the app generator _scripts/app-generator/v1/templates/app.yaml_, which ranges over list under _apps_.

Run the following to render the app-of-apps Helm chart as Kubernetes manifests for each child app. Substitute the app-of-apps name for _aos-infra_ and the actual environment name for _nke-site-forge-az00_.

```sh
helm template aoa-infra/v1 -f environments/prod/forge/nke-site-forge-az00/aoa-infra/values.yaml
```

## App-of-Apps Configuration

Follow these steps to deploy an app-of-apps Helm chart with ArgoCD in the environment of choice.

__Requirement:__ Access to Kubernetes cluster kubeconfig.


<!---
### Create Projects

Create ArgoCD project. Supply the name of the app-of-apps Helm chart as argument.  Sustitute the actual ArgoCD project name for \<app-of-apps\>.

```sh
DEPLOY_ENV=nke-infra-dev ./argocd-proj-create.sh <proj-my-apps>
```
-->

### Create directory for new environment

Create environmental directories. Specify app-of-apps environment name. Substitute the actual environment name for _nke-myfunction-mysite-dev_.

```sh
./create-app-of-apps-env.sh nke-site-forge-dev
```

Further modifications are needed, such as creating configuration for each environment and specifying the applications to be deployed.

Add enviroments as directories under the app-of-apps env dirctory.
For each environment added, 

* Update application.yaml with path to the values.yaml for the app-of-apps
* Edit values.yaml and define the name of the values file to be used in the applications. Under the key _apps:_ specify the applications (Helm charts) to be deployed and the ArgoCD configurations.

### Modify Existing App-of-Apps or Child Applications

To make changes to an existing ArgoCD app-of-app or child ArgoCD application.

#### Update NKE Helm chart config globally

To update an NKE Helm chart configuration across all environments, the default _values.yaml_ can be modified.

> [NOTE]
> This does not apply to externally sourced Helm charts. For maintainability, these charts should be left unmodified when pushed to the nvcr.io Helm registry. Values overrides can be supplied to the deployment.

This applies to the following NKE maintained Helm charts: 
* cloud-workflow-engine
* forge-workflow-engine
* site-workflow-engine
* nke-configmaps

> [!NOTE]
> If Helm chart values.yaml are modified, the chart will need to be repackaged and pushed to the Helm registry.

#### Update Helm chart config per environment

Updates to Helm charts in individual environments can be made by updating the configuration in the directories under _environments_, such as _nke-site-forge-az05_.


### Validate App-of-Apps

Produce a template of the ArgoCD app-of-apps Helm chart. Supply an argument to create applications for specified app-of-app only. Validate the resulting Argocd Kubernetes manifests for correctness.

```sh
helm template ../aoa-myapps/v1 -f environments/prod/forge/nke-site-forge-az00/aoa-myapps/values.yaml
```

## App-of-Apps Deployment

### ArgoCD CLI Login

Login to ArgoCD server with appropriate privileges. Substitute your server host URL, username and password.

Forward the argocd service port.

```sh
kubectl -n argocd port-forward service/argocd-server 8443:443
```

Get ArgoCD password.

```sh
ARGOCD_PW=`argocd admin initial-password -n argocd | head -1`; echo $ARGOCD_PW
```

Login to argocd service.

```sh
argocd login localhost:8443 --username admin --password $ARGOCD_PW --insecure --grpc-web
```

### ArgoCD Connect to Git Repository

Use the UI or CLI to create repositories in ArgoCD if they don't already exist.  This only needs to be done once. The ArgoCD repositories hold the URL and credentials for Git repos.

#### CLI

Run command to create Kubernetes secret for ArgoCD to connect to the source code repository. Substitute actual Gitlab access token for _my-gitlab-readonly-token_.

```sh
argocd repo add https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git --username nke-read-only --password my-gitlab-readonly-token
```

#### UI

From the web UI, connect to the Git repo for your deployments.

```
Manage your repositories, projects, settings (gears icon) > Repositories > Connect to your git repo using any of the allowed methods.
```


Ensure current working directory is the _scripts_ directory.

Create ArgoCD app-of-apps. Supply an argument to create applications for specified app-of-app only.

```sh
DEPLOY_ENV=nke-myfunction-mysite-dev ./argocd-app-of-apps-create.sh aoa-myapps
```

### Sync App-of-Apps

Sync all ArgoCD app-of-apps. Supply an argument to sync applications for specified app-of-app only.

```sh
DEPLOY_ENV=nke-myfunction-mysite-dev ./argocd-app-of-apps-sync.sh aoa-myapps
```

### Sync Applications

Sync all ArgoCD applications in an app-of-apps.  Supply app-of-app name as part of the argument to deploy applications for specified ArgoCD app-of-app.

```sh
argocd app sync -l app.kubernetes.io/instance=aoa-myapps
```

The applications within the app-of-apps will all now be individually synced, which will deploy the application Helm chart with the proper values for the environment.

All app-of-apps Helm charts and application Helm charts are managed within ArgoCD as Applications. The ArgoCD Applications all exist in a flat structure.

Congratulations! You have successfully deployed the app-of-apps Helm chart and by extension, all the application Helm charts as well.

---
## Upstream repo references

### aoa-infra
- vault - https://gitlab-master.nvidia.com/nvault/k8s/nvault-k8s-helm
- kubernetes-replicator - https://github.com/mittwald/kubernetes-replicator
- <TODO: add others>

---
# Appendix

### Create New App-of-Apps Helm Chart

To create a new ArgoCD app-of-apps Helm chart, run the script to generate a new chart from template. Skip this step if modifying an existing chart.

> [NOTE] Creating a new app-of-apps Helm chart is rarely needed, but may be useful for development and future deployment needs.

Change to the _scripts_ directory.

```sh
cd scripts
```

Create new app-of-apps Helm chart. Specify the name of the app-of-apps as the sole argument.  Sustitute the actual ArgoCD app-of-app name for _aos-myapps_.  Recommend the name included prefix _aoa-_.

```sh
./create-app-of-apps-chart.sh aoa-myapps
```