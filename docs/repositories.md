# Repositories

`repos.github` and `repos.gitlab` name the repositories previews are built for. Each entry renders one `ApplicationSet`. Both lists are empty by default, and populating one never renders the other.

```yaml
github:
  owner: 'saidsef'

repos:
  github:
  - name: node-webserver
    images:
    - 'docker.io/saidsef/node-webserver:{{ .branch_slug }}'
```

`github.owner` is required once `repos.github` is populated, and `gitlab.group` once `repos.gitlab` is. Rendering fails with a message naming the missing value rather than producing an incomplete `ApplicationSet`.

## Entry keys

| Key | Type | Applies to | Description |
|-----|------|------------|-------------|
| `name` | string | Both | Repository name. Required |
| `path` | string | Kustomize and Helm | Source path inside the repository, defaulting to `<provider>.path` |
| `images` | list | Kustomize only | Image overrides, one per line, in Kustomize `name=newName:newTag` or `name:newTag` form |
| `values` | object | Helm | Inline chart values, selecting the Helm source |
| `parameters` | list | Helm | `--set` style parameters, selecting the Helm source from a chart repository |
| `chart` | string | Helm | Chart name, defaulting to `name` |
| `repoUrl` | string | Both | Source repository or chart repository, overriding the derived address |
| `targetRevision` | string | Both | Revision to deploy, defaulting to `{{ .branch }}` |
| `namespace` | string | Both | Preview namespace, overriding `globals.deployToNamespace` |
| `project` | string or int | GitLab only | Project ID or path passed to the generator, overriding the derived `group/name` |

The derived `repoUrl` is `https://github.com/<owner>/<name>.git` for GitHub, and `<gitlab.api>/<group>/<name>.git` for GitLab.

## Source shapes

Three source shapes are available, and the keys present on the entry select between them.

### Kustomize

Neither `values` nor `parameters` is set. This is the default shape, and the only one that applies `images` and the preview namespace.

```yaml
repos:
  github:
  - name: node-webserver
    images:
    - 'docker.io/saidsef/node-webserver:{{ .branch_slug }}'
  - name: alpine-jenkins-dockerfile
    path: 'deployment/preview'
```

The `Application` gets a `kustomize` block carrying the namespace, the image overrides and three common annotations: `app.kubernetes.io/instance`, `app.kubernetes.io/part-of` and `argocd.argoproj.io/head_short_sha`. The source path is the entry's `path`, or the provider default of `deployment`.

### In-repo Helm chart

`values` is set alongside `path`. The chart is read from the pull request branch, so a chart change and an application change ship in the same preview.

```yaml
repos:
  github:
  - name: scapy-containerised
    path: 'charts/scapy'
    values:
      image:
        tag: '{{ .branch_slug }}'
```

`values` is serialised into the `Application` as a single JSON document, which YAML accepts as chart values.

### Published Helm chart

`parameters` is set alongside `repoUrl`. The chart comes from a chart repository rather than from the branch, so `targetRevision` is a chart version constraint and defaults to `>= 0`.

```yaml
repos:
  github:
  - name: faas-reverse-geocoding
    chart: 'reverse-geocoding'
    repoUrl: 'https://saidsef.github.io/faas-reverse-geocoding'
    parameters:
      - name: "image.tag"
        value: "{{ .branch_slug }}"
      - name: "ingress.enabled"
        value: "true"
      - name: "ingress.hosts[0].host"
        value: "{{ .branch_slug }}"
```

`chart` defaults to `name`, so it is needed only where the chart is named differently from the repository.

!!! warning "The shapes are exclusive"
    `parameters` wins over `values`, and either suppresses the Kustomize block. An entry setting `images` alongside `values` deploys the chart and drops the image overrides silently, so put the image tag in the chart values instead. An entry setting `values` without `chart` or `path` renders an `Application` with no source location and fails to sync.

## Per-branch images

A preview is only a preview where it runs the branch's own image. The tag has to be one the pull request build published, which makes `{{ .branch_slug }}` and `{{ .head_short_sha }}` the two useful values.

```yaml
images:
- 'docker.io/saidsef/node-webserver:{{ .branch_slug }}'   # tag per branch
- 'docker.io/saidsef/sidecar:merge'                       # same tag for every preview
```

A tag no build produced leaves the pod in `ImagePullBackOff`, and the `Application` reports as degraded rather than failing to sync.

## GitLab entries

```yaml
gitlab:
  group: 'saidsef'

repos:
  gitlab:
  # `project` overrides the derived `group/name` path for the generator
  - name: service-a
    path: 'deployment/preview'
    project: 13
    namespace: preview
    repoUrl: 'https://gitlab.com/project/service-a.git'
  # no `project`, so the generator receives `saidsef/service-b`
  - name: service-b
    path: 'deployment/preview'
```

`project` is passed to the generator alone. The source `repoURL` and the merge request link are still built from `gitlab.group` and `name`, so an entry whose project sits outside the group needs `repoUrl` set as well.

## Worked examples

[`values-example.yaml`](https://github.com/saidsef/argocd-applicationsets-services/blob/main/charts/applicationset/values-example.yaml) in the chart covers every shape above. It is not loaded by default, so pass it explicitly.

```shell
helm template appsets charts/applicationset \
  --namespace argocd \
  --values charts/applicationset/values-example.yaml
```
