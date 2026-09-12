# argocd-applicationsets-services

![Version: 0.23.0](https://img.shields.io/badge/Version-0.23.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.23.0](https://img.shields.io/badge/AppVersion-0.23.0-informational?style=flat-square)

A Helm chart for ArgoCD ApplicationSets, a declarative, GitOps continuous delivery tool for Kubernetes

**Homepage:** <https://github.com/saidsef/argocd-applicationsets-services>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| saidsef |  | <https://saidsef.github.io/argocd-applicationsets-services> |

## Source Code

* <https://github.com/saidsef/argocd-applicationsets-services.git>

## Requirements

Kubernetes: `>= 1.31`

ArgoCD ApplicationSet controller: `>= v2.5.0` for `goTemplate` (dot-prefixed tokens such as
`{{ .branch_slug }}`), `>= v2.8.0` for `goTemplateOptions`. This chart enables both from `0.20.0`,
so tokens written in the pre-`0.20.0` fasttemplate form (`{{branch_slug}}`) will fail to render.

## Values

`repos.github` and `repos.gitlab` are both empty by default, and each provider renders only
when its list is populated - declaring one never pulls in the other. Populating `repos.github`
requires `github.owner`; populating `repos.gitlab` requires `gitlab.group`. See
[values-example.yaml](./values-example.yaml) for worked examples of every supported source shape.

Each populated provider also requires a credential, and rendering fails without one. GitHub takes
`secretName` with `secretKey`, or `appSecretName`; GitLab takes `secretName` with `secretKey`. An
anonymous GitHub caller gets 60 requests an hour per IP, which one ApplicationSet polling every 500
seconds spends at 7.2 an hour, and a private repository returns no pull requests rather than an
authentication error.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| github | object | `{"api":"https://api.github.com","appSecretName":"","label":"preview","owner":"","path":"deployment","secretKey":"","secretName":""}` | GitHub repo configuration parameters |
| github.appSecretName | string | `""` | Secret holding GitHub App credentials, an alternative to `secretName` and `secretKey`. |
| github.owner | string | `""` | GitHub organisation / owner. Required when `repos.github` is populated. |
| github.secretKey | string | `""` | Key within `secretName`. Required with `secretName`, unless `appSecretName` is set. |
| github.secretName | string | `""` | Secret holding a GitHub token. Required with `secretKey`, unless `appSecretName` is set. |
| gitlab | object | `{"api":"https://gitlab.com","caRef":{},"group":"","insecure":false,"label":"preview","path":"deployment","pullRequestState":"opened","secretKey":"","secretName":""}` | GitLab repo configuration parameters |
| gitlab.caRef | object | `{}` | ConfigMap holding trusted CA certs for self-signed GitLab TLS (leave empty to disable) |
| gitlab.group | string | `""` | GitLab group. Required when `repos.gitlab` is populated. |
| gitlab.insecure | bool | `false` | Skip validating the GitLab TLS certificate (useful for self-signed certificates) |
| gitlab.pullRequestState | string | `"opened"` | MR state filter, one of: "", opened, closed, merged or locked |
| gitlab.secretKey | string | `""` | Key within `secretName`. Required with `secretName`. |
| gitlab.secretName | string | `""` | Secret holding a GitLab token. Required with `secretKey`. |
| globals | object | `{"annotations":{"notifications.argoproj.io/subscribe.on-deleted.slack":"argocd","notifications.argoproj.io/subscribe.on-deployed.slack":"argocd","notifications.argoproj.io/subscribe.on-health-degraded.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-failed.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-running.slack":"argocd"},"deployToNamespace":"previews","goTemplateOptions":["missingkey=error"],"label":"preview","preserveResourcesOnDeletion":false,"requeueAfterSeconds":500,"retry":{"backoff":{"duration":"10s"},"limit":5},"revisionHistoryLimit":2,"server":"https://kubernetes.default.svc","syncOptions":["ApplyOutOfSyncOnly=true","CreateNamespace=true","PruneLast=true","PrunePropagationPolicy=foreground","RespectIgnoreDifferences=true","Validate=false"]}` | Global default variables |
| globals.annotations | object | `{"notifications.argoproj.io/subscribe.on-deleted.slack":"argocd","notifications.argoproj.io/subscribe.on-deployed.slack":"argocd","notifications.argoproj.io/subscribe.on-health-degraded.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-failed.slack":"argocd","notifications.argoproj.io/subscribe.on-sync-running.slack":"argocd"}` | applications annotations @schema-pattern: ^[a-zA-Z0-9_-]+$ |
| globals.deployToNamespace | string | `"previews"` | Kubernetes namespace to deploy previews |
| globals.goTemplateOptions | list | `["missingkey=error"]` | Go template options for the ApplicationSet controller. 'missingkey=error' fails rendering on any unresolved template key. Requires ArgoCD >= v2.8.0. |
| globals.label | string | `"preview"` | GitHub label to filter PRs that you want to target |
| globals.preserveResourcesOnDeletion | bool | `false` | Preserve an Application's child resources when the parent Application is deleted |
| globals.requeueAfterSeconds | int | `500` | GitHub polling rate (seconds) |
| globals.retry | object | `{"backoff":{"duration":"10s"},"limit":5}` | Failed sync retry, passed through to the Application syncPolicy. A limit of 0 performs no retries. |
| globals.revisionHistoryLimit | int | `2` | How many old objects should be retained |
| globals.server | string | `"https://kubernetes.default.svc"` | ArgoCD server address. Use 'all' to deploy each preview to every registered cluster (renders a matrix of the cluster generator and the pull request generator) |
| globals.syncOptions | list | `["ApplyOutOfSyncOnly=true","CreateNamespace=true","PruneLast=true","PrunePropagationPolicy=foreground","RespectIgnoreDifferences=true","Validate=false"]` | syncOptions how it syncs the desired state in the target cluster |
| name | string | `"pr-reviews"` | ApplicationSet name |
| namespace | string | `"argocd"` | ArgoCD controller Namespace deployed |
| project | object | `{"clusterResourceBlacklist":[{"group":"apiextensions.k8s.io","kind":"CustomResourceDefinition"}],"clusterResourceWhitelist":[{"group":"*","kind":"*"}],"destinationServiceAccounts":[],"destinations":[],"enabled":false,"namespaceResourceBlacklist":[{"group":"argoproj.io","kind":"AppProject"}],"namespaceResourceWhitelist":[{"group":"*","kind":"*"}],"orphanedResources":{"warn":false},"permitOnlyProjectScopedClusters":false,"roles":[],"sourceRepos":["*"],"syncWindows":[]}` | ArgoCD Project parameters |
| project.destinationServiceAccounts | list | `[]` | No destination service accounts by default |
| project.destinations | list | `[]` | Destinations the project permits. Derived from `globals.deployToNamespace` and any per-repo `namespace` when left empty. |
| project.namespaceResourceBlacklist | list | `[{"group":"argoproj.io","kind":"AppProject"}]` | Allow all namespaced-scoped resources to be created, except for AppProject |
| project.sourceRepos | list | `["*"]` | Allow from all repositories |
| repos | object | `{"github":[],"gitlab":[]}` | List of repo names and override images for preview environment. Both providers are empty by default; each renders only when you populate it, so declaring one never pulls in the other. Generator tokens are Go template, so they need the leading dot - '{{ .branch_slug }}', not '{{branch_slug}}'. Requires ArgoCD >= v2.5.0. Worked examples: values-example.yaml See: <https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/> |
| repos.github | list | `[]` | GitHub repos to build previews for. Requires `github.owner`. |
| repos.gitlab | list | `[]` | GitLab repos to build previews for. Requires `gitlab.group`. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
