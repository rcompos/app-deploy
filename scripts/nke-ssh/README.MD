# Syncerator

Sync argocd application across multiple site controllers.

## Overview

There are three scripts involved.

* sync-runner.sh
    * Runs _expector.exp_ for all sites in the _ip_map_ associative array.
    * Accepts the following verbs (-v):
        * diff
        * get
        * history
        * list (all apps)
        * logs
        * manifests
        * sync
* expector.exp
    * Expect script that runs _syncerator.sh_
    * Supplies password at the SSH prompt
* syncerator.sh
    * Check for existing listeners on port 6445.
    * Create SSH tunnel to forward ports in background
        * When run directly, the SSH password must be typed manually within the sleep window
    * Export KUBECONFIG
    * Set ArgoCD admin password as envvar
    * CLI login to ArgoCD server
    * Kubectl port forward argocd
    * Run ArgoCD CLI command (argocd) for application with supplied verbs (default get)
    * Kill background processes

## Requirements

* MacOS
* bash 4 or later

      brew install bash
* expect

      brew install expect
* kubectl

      brew install kubernetes-cli
* argocd

      brew install argocd
* kubeconfigs

    * Must reside under ~/.kube
    * The kubeconfig file for each site are named like  _nke-site-forge-az01.kubeconfig_.
    * The _server:_ entry should define a port of _6445_.
* SSH config ~/.ssh/config
  * Site controller host entries named az01sc, az60sc, etc
  * Site contoller host Hostname set as IP address
  * Site contoller host ProxyJump specified
  * Site contoller host User defined (nke|dgxc-admin)

        Host az01sc
            Hostname 10.45.0.2
            ProxyJump az01
            User nke
  * Identity file define for all

        Host *
            IdentityFile ~/.ssh/id_ed25519

## Usage

Change to directory syncerator from repo root dir.

```sh
cd scripts/syncerator
```

## Review targeted sites

Run command to list the sites to update. Values starting with a pound sign (#) will be excluded.

```sh
grep 'ip_map\[\"' sync-runner.sh
```

## Login to Azure

Fetch token with NVINIT Azure OIDC Login

```sh
nvinit ssh
```

## Get argocd application in all targeted sites

Get argocd application details. Substitute the actual app name for _<argocd\_application\_name>_

```sh
./sync-runner.sh <argocd_application_name>
```

## Sync argocd application in all targeted sites

Sync argocd application. Substitute the actual app name for _<argocd\_application\_name>_

```sh
./sync-runner.sh -v sync <argocd_application_name>
```

Example output from updating _kubetrust-verifier_.

```sh
$ ./sync-runner.sh -v sync kubetrust-verifier
########################  AZ24  ##########################

./expector.exp az24 10.45.144.170 sync kubetrust-verifier
spawn ./syncerator.sh -n az24 -i 10.45.144.170 -v sync kubetrust-verifier
site_name: az24
ip_addr:   10.45.144.170
app_name:  kubetrust-verifier
argo_verb: sync
port_kube: 6445
port_argo: 8443

ssh -N -L 6445:10.45.144.170:6443 az24sc &
***********************************************************************
Use of this network is restricted to authorized users only.
All access attempts and activities on this network are subject to being
monitored, logged and audited.

The network operator reserves the right to consent to valid law
enforcement requests to search the network and to institute legal or
disciplinary action against any misuse of the network.
***********************************************************************
***********************************************************************
Use of this network is restricted to authorized users only.
All access attempts and activities on this network are subject to being
monitored, logged and audited.

The network operator reserves the right to consent to valid law
enforcement requests to search the network and to institute legal or
disciplinary action against any misuse of the network.
***********************************************************************
nke@10.45.144.170's password:
KUBECONFIG: /Users/rcompos/.kube/nke-site-forge-az24.kubeconfig
ARGOCD_PW: *****
kubectl -n argocd port-forward service/argocd-server 8443:443 &
Forwarding from 127.0.0.1:8443 -> 8080
Forwarding from [::1]:8443 -> 8080
argocd login localhost:8443 --username admin --password ***** --insecure
Handling connection for 8443
Handling connection for 8443
Handling connection for 8443
Handling connection for 8443
Handling connection for 8443
'admin:login' logged in successfully
Context 'localhost:8443' updated
argocd app sync kubetrust-verifier
Handling connection for 8443
Handling connection for 8443
Handling connection for 8443
Handling connection for 8443

Handling connection for 8443
Name:               argocd/kubetrust-verifier
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          kubetrust-verifier
URL:                https://localhost:8443/applications/kubetrust-verifier
Sources:
- Repo:             https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
  Target:           main
  Path:             kubetrust-verifier/0.0.12
  Helm Values:      $values/environments/nke-site-forge-az24/values-kubetrust-verifier.yaml
- Repo:             https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git
  Target:           main
  Ref:              values
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        Synced to main
Health Status:      Healthy

Operation:          Sync
Sync Revision:      86d960ede774a7d618981ee15f04441c7ea19a29, 86d960ede774a7d618981ee15f04441c7ea19a29
Phase:              Succeeded
Start:              2025-01-09 12:05:53 -0700 MST
Finished:           2025-01-09 12:05:54 -0700 MST
Duration:           1s
Message:            successfully synced (all tasks run)

GROUP                      KIND                      NAMESPACE           NAME                             STATUS   HEALTH   HOOK  MESSAGE
                           ServiceAccount            kubetrust-verifier  kubetrust-attest                 Synced                  serviceaccount/kubetrust-attest unchanged
                           ServiceAccount            kubetrust-verifier  kubetrust-admin                  Synced                  serviceaccount/kubetrust-admin unchanged
apiextensions.k8s.io       CustomResourceDefinition  kubetrust-verifier  nodes.kubetrust.nvidia.com       Running  Synced         customresourcedefinition.apiextensions.k8s.io/nodes.kubetrust.nvidia.com configured
rbac.authorization.k8s.io  ClusterRole               kubetrust-verifier  kubetrust-verifier               Running  Synced         clusterrole.rbac.authorization.k8s.io/kubetrust-verifier reconciled. clusterrole.rbac.authorization.k8s.io/kubetrust-verifier unchanged
rbac.authorization.k8s.io  ClusterRoleBinding        kubetrust-verifier  kubetrust-verifier               Running  Synced         clusterrolebinding.rbac.authorization.k8s.io/kubetrust-verifier reconciled. clusterrolebinding.rbac.authorization.k8s.io/kubetrust-verifier unchanged
rbac.authorization.k8s.io  ClusterRoleBinding        kubetrust-verifier  kubetrust-verifier-token-review  Running  Synced         clusterrolebinding.rbac.authorization.k8s.io/kubetrust-verifier-token-review reconciled. clusterrolebinding.rbac.authorization.k8s.io/kubetrust-verifier-token-review unchanged
                           Service                   kubetrust-verifier  kubetrust-verifier               Synced   Healthy        service/kubetrust-verifier unchanged
apps                       Deployment                kubetrust-verifier  kubetrust-verifier               Synced   Healthy        deployment.apps/kubetrust-verifier unchanged
apiextensions.k8s.io       CustomResourceDefinition                      nodes.kubetrust.nvidia.com       Synced
rbac.authorization.k8s.io  ClusterRole                                   kubetrust-verifier               Synced
rbac.authorization.k8s.io  ClusterRoleBinding                            kubetrust-verifier               Synced
rbac.authorization.k8s.io  ClusterRoleBinding                            kubetrust-verifier-token-review  Synced
[1]-  Running                 ssh -N -L "${port_kube}:${ip_addr}:6443" "${site_name}sc" &
[2]+  Running                 kubectl -n argocd port-forward service/argocd-server "${port_argo}:443" &
kill 24663
kill 24676
[1]-  Done                    ssh -N -L "${port_kube}:${ip_addr}:6443" "${site_name}sc"
[2]+  Terminated: 15          kubectl -n argocd port-forward service/argocd-server "${port_argo}:443"

########################  AZ24CNI  ##########################

./expector.exp az24cni 10.45.144.26 sync kubetrust-verifier
spawn ./syncerator.sh -n az24cni -i 10.45.144.26 -v sync kubetrust-verifier
site_name: az24cni
ip_addr:   10.45.144.26
app_name:  kubetrust-verifier
argo_verb: sync
port_kube: 6445
port_argo: 8443

ssh -N -L 6445:10.45.144.26:6443 az24cnisc &
***********************************************************************
Use of this network is restricted to authorized users only.
...
```