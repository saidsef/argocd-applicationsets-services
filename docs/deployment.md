# Deployment

The chart installs into the namespace the ApplicationSet controller watches, conventionally `argocd`. It creates `ApplicationSet` and `AppProject` objects only, so the ArgoCD install itself is a prerequisite rather than part of this chart.

## Prerequisites

| Requirement | Value |
|-------------|-------|
| Kubernetes | >= 1.31 |
| ArgoCD with the ApplicationSet controller | >= v2.13 |
| Helm | >= v3.10 |
| SCM API reachable from the controller | GitHub or GitLab |

The ApplicationSet CRDs come with ArgoCD. Where they are absent, the install fails on an unknown `ApplicationSet` kind.

## Installing

```shell
helm repo add applicationsets-services https://saidsef.github.io/argocd-applicationsets-services/
helm repo update
helm upgrade --install pr-services applicationsets-services/argocd-applicationsets-services \
  --namespace argocd \
  --values values.yaml
```

Render the objects before applying them where the values are new.

```shell
helm template pr-services applicationsets-services/argocd-applicationsets-services \
  --namespace argocd \
  --values values.yaml
```

An install that names no repository is valid and renders nothing, so the first install can be a bare one and the repositories added afterwards.

## API credentials

The generator polls the SCM API. Without credentials it polls anonymously, which reaches public repositories under a shared rate limit and no private ones. The secret lives in the same namespace as the `ApplicationSet`.

### GitHub token

A personal access token with `repo` scope, or a fine-grained token with read access to pull requests on the repositories concerned.

```shell
kubectl create secret generic github-pr-token \
  --namespace argocd \
  --from-literal=token=ghp_xxxxxxxxxxxx
```

```yaml
github:
  owner: 'saidsef'
  secretName: 'github-pr-token'
  secretKey: 'token'
```

Both keys are needed. Setting one alone renders no `tokenRef`, and the generator falls back to anonymous polling.

### GitHub App

`appSecretName` names an ArgoCD repository credentials secret holding `githubAppID`, `githubAppInstallationID` and `githubAppPrivateKey`. An App raises the rate limit and scopes access per installation rather than per user.

```yaml
github:
  owner: 'saidsef'
  appSecretName: 'github-app-repo-creds'
```

`secretName` and `secretKey` are unnecessary alongside it.

### GitLab token

A personal, group or project access token with `read_api` scope.

```shell
kubectl create secret generic gitlab-mr-token \
  --namespace argocd \
  --from-literal=token=glpat-xxxxxxxxxxxx
```

```yaml
gitlab:
  group: 'saidsef'
  secretName: 'gitlab-mr-token'
  secretKey: 'token'
```

`globals.requeueAfterSeconds` sets the polling interval, and every repository is polled on it. Lowering it across many repositories multiplies the API calls, which is what exhausts a rate limit. Prefer a [webhook](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/#webhook-configuration) for faster feedback, and leave the interval as the fallback.

## Self-hosted providers

Point the API address at the instance. GitHub Enterprise also changes the pull request link, since the chart rewrites `https://api.github.com` to `https://github.com` and passes any other address through as given.

```yaml
github:
  api: https://github.example.com/api/v3
gitlab:
  api: https://gitlab.example.com
```

For a GitLab certificate the controller does not trust, mount the CA through `gitlab.caRef` rather than disabling validation with `gitlab.insecure`. [Configuration](usage.md#gitlab) covers both.

## Scoping the project

Previews land in the `default` ArgoCD project until `project.enabled` is set. The `default` project permits everything, so a preview can create any resource on any destination the cluster allows.

```yaml
project:
  enabled: true
```

With the project enabled and `project.destinations` left empty, the destinations are derived from the preview namespaces. A preview attempting to deploy outside them is refused by ArgoCD rather than silently applied. [Configuration](usage.md#project) covers narrowing the resource whitelists.

## Multi-cluster previews

```yaml
globals:
  server: 'all'
```

Each pull request is then rendered once per cluster registered with ArgoCD, and the cluster name is appended to the `Application` name. Every registered cluster is included, so restrict the fan out with `project.destinations` where only some should receive previews.

## Upgrading

Chart versions and the changes in each are published in the [release notes](https://github.com/saidsef/argocd-applicationsets-services/releases) and in the `artifacthub.io/changes` annotation on the chart.

From `0.20.0` the chart sets `goTemplate: true` and `goTemplateOptions: [missingkey=error]`. Tokens written in the older fasttemplate form, `{{branch_slug}}`, stop the `ApplicationSet` from rendering. Add the leading dot to every token in `images`, `values` and `parameters` before upgrading.

## Uninstalling

```shell
helm uninstall pr-services --namespace argocd
```

Removing the `ApplicationSet` objects removes the `Application` objects they own, and those deletions cascade to the deployed preview resources. Set `globals.preserveResourcesOnDeletion: true` before uninstalling to keep the running previews.
