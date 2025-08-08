# Specification for key apps in nke-site-deploy ArgoCD app-of-apps

The following spec for the key named _apps_ for the NKE app-of-apps values files.

The following are examples of app-of-apps values files for environment nke-site-forge-azNN.

```sh
environments/prod/forge/nke-site-forge-azNN/aoa-infra/values.yaml
environments/prod/forge/nke-site-forge-azNN/aoa-nke-site/values.yaml
environments/prod/forge/nke-site-forge-azNN/aoa-observability/values.yaml
```

Application Definitions

The NKE app-of-apps values for infra, nke-site and observability have a key name _apps_ that contains a list of dictionaries. Each list entry is the configuration specification for that entries ArgoCD application.

```sh
 apps:
   - name: nginx                       # Name of the ArgoCD application (required)
     chartDir: nginx                   # Directory name where chart resides (required if chart not specified)
     chartVer: "18.2.2"                # Helm chart version-named directory, i.e. 18.2.2 for path nginx/18.2.2 (required if chart not specified)
     chart: nginx                      # Helm registry chart name (optional, required if repoURL is Helm registry)
     kustomize: true                   # Deploy Kustomize application (optional)
     repoURL: https://my-git-server.com/data/my-repo.git   # Git chart repo, Helm Registry or Kustomize repo (optional)
     targetRevision: my/branch         # Git branch (optional)
     path: path/to/my-chart            # Path under chart repo (optional, required if kustomize is true)
     fullnameOverride: nginx-poc       # Override name of app to deploy (optional)
     namespace: custom-namespace       # Namespace (optional)
     addHelmFiles: true                # Add files to Helm chart from additional source (optional)
     addHelmFilesDir: environments/nke-cloud-aws-dev/my-nginx-bitnami # Override directory of additional Helm files
     targetRevisionHelmFiles: my/rev   # Target revision for added Helm files (optional, required if addHelmFiles is true)
     valueFiles:                       # List of values file (optional list)
       - values-nke-cloud-aws-dev.yaml # Values file (optional)
       - values-my-env.yaml            # Values file (optional will be merged)
     helmValuesFile: path/values.yaml  # allows to provide non-env specifc values file override for remote charts (only applicable when chart is specified)
     finalizers:                       # Metadata finalizers (optional list)
       - resources-finalizer.argocd.argoproj.io # Example
     ignoreDifferencesMetadataLabels: true # Ignore differences (optional)
     ignoreMissingValueFiles: true     # Ignore missing values files (optional) 
     syncOptions:                      # syncPolicy syncOptions (optional list)
       - CreateNamespace=true          # Example
     automated:                        # syncPolicy automated (optional, use {} to enable automated with defaults) 
       prune: false                     # Example
       selfHeal: false                  # Example
       allowEmpty: false               # Example
     info:                             # Extra information (optional list)
       - name: 'Optional info'         # Example
         value: 'Optional value'
```