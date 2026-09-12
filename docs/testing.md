# Testing

The chart has no runtime of its own, so testing it means rendering it and applying the result to a cluster carrying the ArgoCD CRDs.

## Rendering locally

```shell
helm template appsets charts/applicationset --namespace argocd --values values.yaml
```

`helm template` catches the `required` failures, a malformed values file and any token the chart itself mis-renders. It does not catch a token the ApplicationSet controller will not supply, because the `{{ .branch_slug }}` style tokens pass through Helm untouched and are expanded later by the controller.

```shell
helm lint charts/applicationset --values charts/applicationset/values-example.yaml
```

## Checking the rendered output

Two things are worth reading in the output before applying it: the generator block, and the `Application` source.

```shell
helm template appsets charts/applicationset \
  --namespace argocd \
  --values charts/applicationset/values-example.yaml \
  | grep -A 12 'pullRequest:'
```

A source rendering `kustomize` where a Helm chart was intended means `values` or `parameters` is missing from the entry. [Repositories](repositories.md#source-shapes) covers the selection.

## Default values render nothing

Both `repos` lists are empty by default, so the chart defaults produce no objects at all. CI asserts it, since a default that rendered an `ApplicationSet` would have an install adopt repositories nobody asked for.

```shell
test -z "$(helm template appsets charts/applicationset --namespace argocd)"
```

## Continuous integration

`charts.yml` runs on every pull request touching `charts/**`, and on merge to `main`.

| Job | Trigger | Behaviour |
|-----|---------|-----------|
| Chart lint | Pull request | `ct lint` against the default branch, plus a dependency review |
| Kind test | Pull request | Installs the ArgoCD CRDs in a Kind cluster and applies the rendered chart |
| CodeQL and Trivy | Both | Configuration scanning, with the results uploaded to the security tab |
| Chart release | Merge to `main` | `chart-releaser` publishes the packaged chart to GitHub Pages |

The Kind job applies the ArgoCD CRDs with a server-side apply, waits for them to reach `Established`, then applies the chart rendered from `values-example.yaml`. Server-side apply returns before the CRDs are established, so the wait retries rather than failing on the absent `.status.conditions`.

The release job copies the repository's Markdown files into `charts/applicationset/` before packaging, so the chart bundle carries the README, the licence and the contribution guide.

## In-cluster check

The same steps run locally against any cluster.

```shell
kubectl create namespace argocd
kubectl apply --server-side -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable -n argocd
kubectl wait --for=condition=Established --timeout=60s \
  crd/applications.argoproj.io crd/applicationsets.argoproj.io crd/appprojects.argoproj.io

helm template appsets charts/applicationset \
  --namespace argocd \
  --values charts/applicationset/values-example.yaml \
  | kubectl apply --server-side --force-conflicts -n argocd -f -

kubectl get applicationsets -A -o wide
kubectl get applications -A -o wide
```

The CRDs alone are enough to validate the objects. Without the controllers running, no `Application` appears under the `ApplicationSet`, so an empty application list is the expected result of this check rather than a failure.

## Pre-commit

```shell
pre-commit install
pre-commit run --all-files
```

The hooks cover trailing whitespace, line endings, merge conflict markers, large files, and secret detection through `detect-private-key`, `detect-aws-credentials` and `gitleaks`.

## Building this site

The sources are in [`docs/`](https://github.com/saidsef/argocd-applicationsets-services/tree/main/docs) and the navigation is in `mkdocs.yml`.

```shell
podman run --rm -v .:/docs docker.io/squidfunk/mkdocs-material:9 build
podman run --rm -p 8000:8000 -v .:/docs docker.io/squidfunk/mkdocs-material:9
```

`build` renders the site into `site/`, which is ignored by git. The second command serves it on `http://localhost:8000` with live reload. `strict: true` in `mkdocs.yml` turns a broken internal link into a build failure, so a page added to `docs/` has to be added to the navigation as well.
