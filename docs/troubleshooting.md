# Troubleshooting

Problems fall on one of two sides of the boundary. Helm reports what the chart failed to render; the ApplicationSet controller reports what it failed to generate. The controller logs are the second place to look.

```shell
kubectl logs -n argocd deployment/argocd-applicationset-controller
kubectl describe applicationset -n argocd <repo>-github-pr-reviews
```

## The install renders nothing

Both `repos` lists are empty by default, so an install passing no values creates no objects. This is the intended default. Populate `repos.github` or `repos.gitlab`, and set the `github.owner` or `gitlab.group` that goes with it.

## Rendering fails with a required value

| Message | Cause |
|---------|-------|
| `A valid repo name is required` | An entry in `repos.github` or `repos.gitlab` has no `name` |
| `A valid repo organization / owner is required` | `repos.github` is populated and `github.owner` is empty |
| `A valid gitlab.group is required` | `repos.gitlab` is populated and `gitlab.group` is empty |
| `A valid label(s) for PRs is required` | `labels`, `<provider>.label` and `globals.label` are all empty |
| `A valid namespace is required` | `namespace` is empty |
| `A GitHub credential is required` | `repos.github` is populated and neither `github.secretName` with `github.secretKey` nor `github.appSecretName` is set |
| `A GitLab credential is required` | `repos.gitlab` is populated and `gitlab.secretName` with `gitlab.secretKey` is not set |

A credential message on an install that worked before points at the upgrade rather than at the values. The guard arrived in `0.23.0`, and it fails a half-configured pair too, since `secretName` without `secretKey` renders no `tokenRef`. [Deployment](deployment.md#api-credentials) covers creating the secret.

## No Application appears for a pull request

| Cause | Check | Fix |
|-------|-------|-----|
| Label missing | The labels on the request | Apply the label named by `labels`, `<provider>.label` or `globals.label` |
| Multiple labels configured | Whether the request carries every entry of `labels` | A request must carry all of them, not any of them |
| Not polled yet | Time since the request was labelled | Wait up to `globals.requeueAfterSeconds`, default 500, or configure a webhook |
| Token lacks access | Controller logs for 401 or 404 | Check the token reaches the repository, since a repository it cannot see returns 404 rather than 403 |
| Rate limited | Controller logs for 403 with a rate limit message | Raise `requeueAfterSeconds`, or move from a personal token to a GitHub App |
| Merge request state filtered | `gitlab.pullRequestState` | The default `opened` excludes closed, merged and locked requests. Set `""` to disable the filter |

## The ApplicationSet generates nothing after an upgrade

`goTemplateOptions: [missingkey=error]` fails the whole render on an unresolved token. A token written without its leading dot, `{{branch_slug}}`, is unresolved under `goTemplate: true`, which the chart sets from `0.20.0`.

Fix the tokens in `images`, `values` and `parameters` rather than removing the option. The controller logs name the key that failed.

## Only one Application appears across several clusters

`globals.server: all` appends `{{ .nameNormalized }}` to the `Application` name for exactly this reason. A single `Application` where several clusters are registered means the fan out is not active, so check that `globals.server` is the string `all` and that `server` is not set at the top level, since the top-level key wins.

## Two pull requests overwrite each other

Both deploy into the same namespace, since the namespace comes from the repository entry or `globals.deployToNamespace` rather than from the request. Any fixed object name in the manifests is then shared. Give the manifests per-branch names, or set a `namespace` carrying a `{{ .branch_slug }}` token so each request gets its own.

## The preview runs the wrong image

`images` applies to a Kustomize source alone. An entry setting `values` or `parameters` selects a Helm source, and the image overrides are dropped without a warning. Put the tag in the chart values instead.

A tag that no build published leaves the pods in `ImagePullBackOff`. The `Application` syncs and then reports degraded, so the sync status is not where this shows.

## The Application syncs but nothing is deployed

`Validate=false` and `ApplyOutOfSyncOnly=true` are both default sync options. An empty result usually means the source path holds nothing to apply, so check `path` against the branch: the provider default is `deployment`, which a repository laying its manifests out differently will not have.

## Deleting the ApplicationSet leaves resources behind

`globals.preserveResourcesOnDeletion: true` keeps an `Application`'s resources when the `Application` goes. Where it was set, the preview namespaces survive the uninstall and have to be removed by hand.

## The AppProject refuses a destination

With `project.enabled` and `project.destinations` empty, the permitted destinations are derived from `globals.deployToNamespace` and the `namespace` of each repository entry. A preview deploying anywhere else, including a namespace a Kustomize overlay sets for itself, is refused. Add the namespace to the entry, or set `project.destinations` explicitly.

The same applies to resources: `CustomResourceDefinition` and `AppProject` are blacklisted by default, so a preview shipping a CRD needs `project.clusterResourceBlacklist` changed.

## GitLab TLS errors

A self-signed certificate gives an unknown authority error in the controller logs. Mount the CA through `gitlab.caRef`, pointing it at a ConfigMap in the ArgoCD namespace. `gitlab.insecure: true` also silences the error and disables certificate validation with it.

## The external link points at the wrong host

The link is built from the provider API address. `https://api.github.com` is rewritten to `https://github.com`; any other value is used as given, so a GitHub Enterprise install pointing `github.api` at `https://github.example.com/api/v3` produces links carrying that path. Set `github.api` to the API address the generator needs, and expect the link to follow it.
