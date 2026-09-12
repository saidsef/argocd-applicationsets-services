# Configuration

Values fall into four groups: the release identity, `globals`, the per-provider blocks and the `repos` lists. This page covers the first three. [Repositories](repositories.md) covers `repos`.

The rendered defaults are also published in the [chart README](https://github.com/saidsef/argocd-applicationsets-services/blob/main/charts/applicationset/README.md), generated from the annotations in `values.yaml`.

## Release identity

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `name` | string | `pr-reviews` | Suffix on every `ApplicationSet` and `Application` name, and the `AppProject` name |
| `namespace` | string | `argocd` | Namespace the `ApplicationSet` objects are created in, with any `.` replaced by `-` |

`namespace` has to be the namespace the ApplicationSet controller watches, which for a default ArgoCD install is `argocd`.

## Globals

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `globals.server` | string | `https://kubernetes.default.svc` | Destination cluster. `all` fans each preview out to every registered cluster |
| `globals.deployToNamespace` | string | `previews` | Namespace previews deploy into |
| `globals.label` | string | `preview` | Label a request must carry, used when the provider block sets none |
| `globals.requeueAfterSeconds` | int | `500` | SCM API polling interval |
| `globals.revisionHistoryLimit` | int | `2` | How many old revisions each `Application` retains |
| `globals.retry` | object | `{limit: 5, backoff: {duration: 10s}}` | Failed sync retry, passed to the `Application` sync policy |
| `globals.preserveResourcesOnDeletion` | bool | `false` | Keep an `Application`'s resources when the `Application` is deleted |
| `globals.goTemplateOptions` | list | `[missingkey=error]` | Go template options for the controller |
| `globals.syncOptions` | list | see below | Sync options applied to every `Application` |
| `globals.annotations` | object | Slack notification subscriptions | Annotations applied to every `Application` |

The default sync options are `ApplyOutOfSyncOnly=true`, `CreateNamespace=true`, `PruneLast=true`, `PrunePropagationPolicy=foreground`, `RespectIgnoreDifferences=true` and `Validate=false`. Setting the key replaces the list rather than adding to it.

`globals.annotations` carries the ArgoCD Slack notification subscriptions for deletion, deployment, degraded health, failed sync and running sync. The annotations only do anything where [argocd-notifications](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/) is installed and has a `slack` service configured.

!!! warning "missingkey=error is strict by design"
    `goTemplateOptions: [missingkey=error]` fails rendering on any token the generator did not supply, rather than substituting an empty string. A typo in a token name therefore stops the `ApplicationSet` from producing anything, which is visible in the controller logs. Requires ArgoCD >= v2.8.0.

### Overrides outside globals

Two globals are read through a `coalesce`, so a top-level key of the same name wins where it is set.

| Global | Top-level override |
|--------|--------------------|
| `globals.server` | `server` |
| `globals.requeueAfterSeconds` | `requeueAfterSeconds` |

Neither override is present in `values.yaml`. Set one only to keep an older values file working; new configuration belongs under `globals`.

## GitHub

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `github.owner` | string | `''` | Organisation or user. Required once `repos.github` is populated |
| `github.api` | string | `https://api.github.com` | API address, changed for GitHub Enterprise |
| `github.label` | string | `preview` | Single label filter |
| `github.labels` | list | unset | Multiple label filter. A request must carry every one, and this overrides `github.label` |
| `github.path` | string | `deployment` | Default source path inside the repository |
| `github.secretName` | string | `''` | Secret holding a personal access token |
| `github.secretKey` | string | `''` | Key within that secret |
| `github.appSecretName` | string | `''` | Secret holding GitHub App credentials |

`tokenRef` renders only when both `secretName` and `secretKey` are set. With neither, the generator calls the API unauthenticated, which works for public repositories against a shared rate limit. [Deployment](deployment.md#api-credentials) covers creating the secret.

## GitLab

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `gitlab.group` | string | `''` | Group. Required once `repos.gitlab` is populated |
| `gitlab.api` | string | `https://gitlab.com` | API address, changed for a self-hosted instance |
| `gitlab.label` | string | `preview` | Single label filter |
| `gitlab.labels` | list | unset | Multiple label filter, overriding `gitlab.label` |
| `gitlab.pullRequestState` | string | `opened` | State filter, one of `""`, `opened`, `closed`, `merged` or `locked` |
| `gitlab.insecure` | bool | `false` | Skip GitLab TLS certificate validation |
| `gitlab.caRef` | object | `{}` | ConfigMap holding the CA bundle for a self-signed certificate |
| `gitlab.path` | string | `deployment` | Default source path inside the repository |
| `gitlab.secretName` | string | `''` | Secret holding a personal or group access token |
| `gitlab.secretKey` | string | `''` | Key within that secret |

`gitlab.group` is required even where every entry sets its own numeric `project`, because the source `repoURL` and the merge request link are built from the group.

For a self-signed certificate, prefer `caRef` over `insecure`. The ConfigMap has to exist in the ArgoCD namespace.

```yaml
gitlab:
  api: https://gitlab.example.com
  group: 'platform'
  caRef:
    configMapName: argocd-tls-certs-cm
    key: gitlab-ca
```

### Label precedence

The same resolution runs for both providers.

| Configuration | Filter applied |
|---------------|----------------|
| `labels` set | Every label in the list, and `label` is ignored |
| `labels` unset, `<provider>.label` set | That single label |
| Both unset | `globals.label` |
| All three unset | Rendering fails, since a label is required |

The `app.kubernetes.io/part-of` annotation on a Kustomize source takes the resolved single label, so it reads `preview` under the defaults.

## Project

`project.enabled` is `false` by default, which leaves every preview in the `default` ArgoCD project.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `project.enabled` | bool | `false` | Render the `AppProject` and point the Applications at it |
| `project.destinations` | list | `[]` | Permitted destinations. Derived from the preview namespaces when empty |
| `project.sourceRepos` | list | `['*']` | Permitted source repositories |
| `project.clusterResourceWhitelist` | list | all groups and kinds | Cluster-scoped resources the project may create |
| `project.clusterResourceBlacklist` | list | `CustomResourceDefinition` | Cluster-scoped resources it may not |
| `project.namespaceResourceWhitelist` | list | all groups and kinds | Namespaced resources the project may create |
| `project.namespaceResourceBlacklist` | list | `argoproj.io/AppProject` | Namespaced resources it may not |
| `project.permitOnlyProjectScopedClusters` | bool | `false` | Restrict destinations to clusters scoped to the project |
| `project.destinationServiceAccounts` | list | `[]` | Service accounts ArgoCD impersonates when syncing |
| `project.orphanedResources` | object | `{warn: false}` | Orphaned resource monitoring |
| `project.roles` | list | `[]` | Project roles |
| `project.syncWindows` | list | `[]` | Sync windows |

The defaults permit a preview to create anything except a `CustomResourceDefinition` or another `AppProject`. Narrow the whitelists where previews run alongside other workloads on a shared cluster.

The derivation behind `project.destinations` is covered in [Architecture](architecture.md#appproject).
