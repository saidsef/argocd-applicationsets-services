# argocd-applicationsets-services

`argocd-applicationsets-services` is a Helm chart that renders ArgoCD `ApplicationSet` resources built on the pull request generator. Every pull request carrying the `preview` label gets its own ArgoCD `Application`, and that `Application` deploys the branch into a preview namespace. Closing the pull request, or removing the label, deletes the `Application` and the resources it created.

The chart covers GitHub and GitLab. Both provider lists are empty by default and each renders only when its list is populated, so an install that names no repository creates nothing.

## Features

| Feature | Description |
|---------|-------------|
| GitHub pull request generator | One `ApplicationSet` per repository, filtered by label |
| GitLab merge request generator | Merge request state filter, self-signed TLS and CA bundle options |
| Kustomize sources | Per-branch image overrides through `images`, with the preview namespace applied |
| Helm sources | An in-repo chart path, or a published chart pulled from a chart repository |
| Value overrides | Inline `values` or `--set` style `parameters` per repository |
| Multi-cluster fan out | `globals.server: all` renders a matrix of the cluster and pull request generators |
| AppProject | An optional project scoped to the preview namespaces the chart derives |
| Sync policy | Automated prune and self heal, with configurable sync options and retry |
| Notifications | Slack subscription annotations applied to every generated `Application` |
| External links | Each `Application` carries a link back to its pull or merge request |

## Requirements

| Requirement | Value |
|-------------|-------|
| Kubernetes | >= 1.31 |
| ArgoCD ApplicationSet controller | >= v2.13 |
| Helm | >= v3.10 |
| SCM provider | GitHub or GitLab, reachable from the controller |
| SCM credential | A token or GitHub App secret per populated provider, required from `0.23.0` |

Branch names become Kubernetes object names, so they have to be [RFC 1123](https://www.rfc-editor.org/rfc/rfc1123) subdomains: lower case alphanumeric characters, `-` or `.`, starting and ending with an alphanumeric character.

## Quick start

```shell
helm repo add applicationsets-services https://saidsef.github.io/argocd-applicationsets-services/
helm repo update
helm upgrade --install pr-services applicationsets-services/argocd-applicationsets-services \
  --namespace argocd \
  --values values.yaml
```

```yaml
# values.yaml
github:
  owner: 'saidsef'
  secretName: 'github-pr-token'
  secretKey: 'token'

repos:
  github:
  - name: node-webserver
    images:
    - 'docker.io/saidsef/node-webserver:{{ .branch_slug }}'
```

`secretName` and `secretKey` name a secret holding a GitHub token, which the chart requires before it renders.

The chart is published to Artifact Hub as [argocd-applicationsets-services](https://artifacthub.io/packages/search?repo=argocd-applicationsets-services). [Deployment](deployment.md) covers the API tokens the generator needs, and [Configuration](usage.md) covers the full value set.

## Template tokens

Generator tokens are Go template, so they take the leading dot: `{{ .branch_slug }}`, not `{{branch_slug}}`. The chart sets `goTemplate: true` and `goTemplateOptions: [missingkey=error]`, which fails rendering on an unresolved key rather than substituting an empty string. Tokens written in the pre-`0.20.0` fasttemplate form do not render.

| Token | Value |
|-------|-------|
| `.number` | Pull or merge request number |
| `.branch` | Source branch name |
| `.branch_slug` | Source branch name, sanitised for use in an object name |
| `.target_branch_slug` | Target branch name, sanitised |
| `.head_short_sha` | Short commit SHA of the head |
| `.head_short_sha_7` | First seven characters of the head SHA |
| `.author` | Pull or merge request author |
| `.nameNormalized` | Cluster name, available only under `globals.server: all` |

The full token set is documented in the ArgoCD [pull request generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/) reference.

## Documentation

| Page | Contents |
|------|----------|
| [Architecture](architecture.md) | What the chart renders, and how a pull request becomes a deployed environment |
| [Configuration](usage.md) | Every value, its default, and the precedence between the global and per-provider keys |
| [Repositories](repositories.md) | The `repos` entries, the source shapes they select and worked examples |
| [Deployment](deployment.md) | Installing the chart, provisioning API tokens and scoping the AppProject |
| [Testing](testing.md) | Rendering the chart locally, the lint and Kind jobs, and building this site |
| [Troubleshooting](troubleshooting.md) | Symptoms, causes and fixes |

## Repository

Source code and releases: [github.com/saidsef/argocd-applicationsets-services](https://github.com/saidsef/argocd-applicationsets-services)
