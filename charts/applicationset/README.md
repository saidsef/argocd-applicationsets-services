# argocd-applicationsets-services

![Version: 0.16.1](https://img.shields.io/badge/Version-0.16.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.16.1](https://img.shields.io/badge/AppVersion-0.16.1-informational?style=flat-square)

A Helm chart for ArgoCD ApplicationSets, a declarative, GitOps continuous delivery tool for Kubernetes

**Homepage:** <https://github.com/saidsef/argocd-applicationsets-services>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| saidsef |  | <https://saidsef.github.io/argocd-applicationsets-services> |

## Source Code

* <https://github.com/saidsef/argocd-applicationsets-services.git>

## Requirements

Kubernetes: `>= 1.28`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| github | object | `{"api":"https://api.github.com","label":"preview","owner":"saidsef","path":"deployment","secretKey":"","secretName":""}` | GitHub repo configuration parameters |
| gitlab | object | `{"api":"https://gitlab.com","group":"saidsef","label":"preview","path":"deployment","secretKey":"","secretName":""}` | GitLab repo configuration parameters |
| globals | object | `{"annotations":{"notifications.argoproj.io/subscribe.on-deleted.slack":"argocd","notifications.argoproj.io/subscribe.on-deployed.slack":"argocd","notifications.argoproj.io/subscribe.on-health-degraded.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-failed.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-running.slack":"argocd"},"deployToNamespace":"previews","label":"preview","requeueAfterSeconds":500,"retryBackoffDuration":"10s","revisionHistoryLimit":2,"server":"https://kubernetes.default.svc","syncOptions":["ApplyOutOfSyncOnly=true","CreateNamespace=true","PruneLast=true","PrunePropagationPolicy=foreground","RespectIgnoreDifferences=true","Validate=false"]}` | Global default variables |
| globals.annotations | object | `{"notifications.argoproj.io/subscribe.on-deleted.slack":"argocd","notifications.argoproj.io/subscribe.on-deployed.slack":"argocd","notifications.argoproj.io/subscribe.on-health-degraded.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-failed.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-running.slack":"argocd"}` | applications annotations @schema-pattern: ^[a-zA-Z0-9_-]+$ |
| globals.deployToNamespace | string | `"previews"` | Kubernetes namespace to deploy previews |
| globals.label | string | `"preview"` | GitHub label to filter PRs that you want to target |
| globals.requeueAfterSeconds | int | `500` | GitHub polling rate (seconds) |
| globals.retryBackoffDuration | string | `"10s"` | The amount to back off retries of failed syncs |
| globals.revisionHistoryLimit | int | `2` | How many old objects should be retained |
| globals.server | string | `"https://kubernetes.default.svc"` | ArgoCD server address, use 'all' to use cluster generator |
| globals.syncOptions | list | `["ApplyOutOfSyncOnly=true","CreateNamespace=true","PruneLast=true","PrunePropagationPolicy=foreground","RespectIgnoreDifferences=true","Validate=false"]` | syncOptions how it syncs the desired state in the target cluster |
| name | string | `"pr-reviews"` | ApplicationSet name |
| namespace | string | `"argocd"` | ArgoCD controller Namespace deployed |
| project | object | `{"clusterResourceBlacklist":[{"group":"apiextensions.k8s.io","kind":"CustomResourceDefinition"}],"clusterResourceWhitelist":[{"group":"*","kind":"*"}],"destinations":[{"name":"*","namespace":"previews","server":"*"}],"enabled":false,"namespaceResourceBlacklist":[{"group":"argoproj.io","kind":"AppProject"}],"namespaceResourceWhitelist":[{"group":"*","kind":"*"}],"orphanedResources":{"warn":false},"permitOnlyProjectScopedClusters":false,"roles":[],"sourceRepos":["*"],"syncWindows":[]}` | ArgoCD Project parameters |
| project.destinations | list | `[{"name":"*","namespace":"previews","server":"*"}]` | Only permit applications to deploy to the previews namespace in the same cluster |
| project.namespaceResourceBlacklist | list | `[{"group":"argoproj.io","kind":"AppProject"}]` | Allow all namespaced-scoped resources to be created, except for AppProject |
| project.sourceRepos | list | `["*"]` | Allow from all repositories |
| repos | object | `{"github":[{"images":["docker.io/saidsef/node-webserver:{{branch}}"],"name":"node-webserver"},{"name":"alpine-jenkins-dockerfile","path":"deployment/preview"},{"images":["docker.io/saidsef/aws-kinesis-local:{{branch}}"],"name":"aws-kinesis-local"},{"images":["docker.io/saidsef/aws-dynamodb-local:{{branch}}"],"name":"aws-dynamodb-local"},{"name":"tika-document-to-text","path":"deployment/preview"},{"images":["docker.io/saidsef/k8s-spot-termination-notice:merge"],"name":"k8s-spot-termination-notice"},{"name":"scapy-containerised","path":"charts/scapy","values":{"image":{"tag":"{{branch}}"}}},{"chart":"reverse-geocoding","name":"faas-reverse-geocoding","parameters":[{"name":"image.tag","value":"{{branch}}"},{"name":"ingress.enabled","value":"true"},{"name":"ingress.hosts[0].host","value":"{{branch}}"}],"repoUrl":"https://saidsef.github.io/faas-reverse-geocoding"}],"gitlab":{}}` | List of repo names and override images for preview environment to dynamically pass the branch of the pull request head use '{{branch}}' variable see: https://argocd-applicationset.readthedocs.io/en/stable/Generators-Pull-Request/#template |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
