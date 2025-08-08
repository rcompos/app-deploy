# NKE Local Development

Provision a local development environment for development and testing of the NKE applications and deployment mechanisms.

## Description

Deploy local development environment for development and testing of NKE applications as well as the Helm charts and ArgoCD applications.

## Requirements

The follow are requirements by architecture.

### Darwin (MacOS)
* Homebrew 
* Docker

### Linux
* Docker

### Docker Desktop

The Docker Desktop must be configured to enable a file sharing.

These directories (and their subdirectories) can be bind mounted into Docker containers.  Synchronized file shares will be made available to containers using synchronized caches of host filesystem contents.

```sh
From the Docker Desktop, select the gear icon (settings) in upper right.
From the left side menu, select Resources > File sharing
Select Create share > Select a directory > Open
```

## Usage

The go-task tool is used to automate the deployment of local dev env.

### Install task

#### Darwin (MacOS)

```sh
brew update && brew install go-task
task version
```

#### Ubuntu Linux on arm64

Install go-task

```sh
apt update && apt install -y curl
curl -LO https://github.com/go-task/task/releases/download/v3.42.1/task_linux_arm64.deb
dpkg -i task_linux_arm64.deb
task --version
```

#### Other Linux

Refer to the documentation for your Linux OS and architecture to install go-task.

https://taskfile.dev/installation/


### List tasks

List all tasks in the Taskfile.

```sh
 $ task -l
task: Available tasks for this project:
* create-cluster:                Create local kind cluster
* create-secrets:                Create secrets
* delete-cluster:                Delete local kind cluster
* deploy-apps:                   Deploy apps
* install-argocd:                Install ArgoCD
* kubeconfig:                    Show command to export KUBECONFIG envvar
* list-cluster:                  List kind clusters
* setup-darwin:                  Setup dependencies on Darwin
* setup-linux:                   Setup dependencies on Linux
* show-kind-configuration:       Show kind cluster configuration
```

### Populate secrets

Copy _argo-repo-creds-template.yaml_ to _argo-repo-creds.yaml_.

```sh
Update the values for the following environmental variables. Substitute the actual value or define the envvar.
GITLAB_NKE_SITE_DEPLOY_TOKEN
GITLAB_NKE_CLOUD_DEPLOY_TOKEN
HELM_NGC_NKE_TOKEN
HELM_NGC_NVIDIAN_TOKEN
```

Copy _cnpg-bootstrap-secrets-templates.yaml_ to _cnpg-bootstrap-secrets.yaml_.

```sh
Update the values for the following environmental variables. Substitute the actual value or define the envvar.
CNPG_SITE_POSTGRES_PASSWORD
CNPG_CLOUD_POSTGRES_PASSWORD
CNPG_TEMPORAL_POSTGRES_PASSWORD
CNPG_SITE_PASSWORD
CNPG_CLOUD_PASSWORD
CNPG_TEMPORAL_PASSWORD
```

### Setup dependencies

#### Darwin (MacOS arm64)

Install dependencies.

```sh
task darwin
```

#### Linux (Ubuntu arm64)

Install dependencies.

```sh
task linux
```

### Create Kubernetes Cluster

Run all tasks to create a cluster and deploy applications.

The following tasks will be run.

* Create Kind Kubernetes cluster  
* Create bootstrap secrets
* Install ArgoCD
* Deploy app-of-apps

```sh
task create-cluster create-secrets install-argocd deploy-apps
```

### Run ad-hoc tasks

The individual tasks may be run ad-hoc. Example use cases include creation of an empty cluster or only create the app-of-apps and not sync the child apps.

#### Create Kind cluster

Optional: Edit file _.env_ and set environment variable CLUSTER_NAME to the desired Kubernetes cluster name. Otherwise the default value _localdev_ will be used.

```sh
Edit file .env and set the cluster name:
CLUSTER_NAME=my-cluster-name
```

Create local Kind cluster.

```sh
task create-cluster
```

#### Create secrets

Create secrets.

```sh
task create-secrets
```

#### Install ArgoCD

Install ArgoCD.

```sh
task install-argocd
```

#### Deploy ArgoCD Apps

Deploy applications.

```sh
task deploy-apps
```

### Delete cluster

When done the cluster may be deleted.

```sh
task delete-cluster
```


