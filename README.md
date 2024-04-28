# ArgoCD ApplicationSet Services [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](./LICENSE.md) [![Chart](https://github.com/saidsef/argocd-applicationsets-services/actions/workflows/charts.yml/badge.svg)](#deployment) [![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/argocd-applicationsets-services)](https://artifacthub.io/packages/search?repo=argocd-applicationsets-services) [![Commits](https://img.shields.io/github/commits-since/saidsef/argocd-applicationsets-services/latest.svg)](#Source)

A [Helm chart for ArgoCD ApplicationSet](./charts/applicationset/README.md) services that uses pull request generator to automatically discover open pull requests within a repository with the **label** `preview`.

## What does it do and how does it work?
[ApplicationSets](https://argocd-applicationset.readthedocs.io/en/stable/) interact with ArgoCD by creating, updating, managing, and deleting ArgoCD Applications. The job is to make sure that the ArgoCD Application remains consistent with the declared ApplicationSet resource(s). This can be thought of as sort of an “Application factory”. It takes an ApplicationSet and outputs one or more ArgoCD Applications.

This helm chart implements Pull Request generator of ApplicationSet, it uses API of an SCMaaS provider (GitHub and/or GitLab) to automatically discover open pull requests within an repository via GitHub / GitLab **labels**. This fits well with the style of building a test environment when you create a pull request.

> Branch name(s) must be [RFC 1123](https://www.rfc-editor.org/rfc/rfc1123) subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
## Prerequisite

Services that should already be installed and/or running.

- Kubernetes Cluster >= 1.28
- [ArgoCD ApplicationSet Controller](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) >= v2.5.8
- [HELM](https://helm.sh/docs/intro/install/) >= v3.9

## Deployment

> Use `repo:` in values to inject or override values in `kustomize` or `helm`
### HELM

```shell
helm repo add applicationsets-services https://saidsef.github.io/argocd-applicationsets-services/
helm repo update
helm upgrade --install pr-services applicationsets-services/argocd-applicationsets-services --namespace argocd
```

## Source

Our latest and greatest source of `argocd-applicationsets-services` can be found on [GitHub](./). Fork us!

## Contributing

We would :heart: you to contribute by making a [pull request](https://github.com/saidsef/argocd-applicationsets-services/pulls).

Please read the official [Contribution Guide](./CONTRIBUTING.md) for more information on how you can contribute.
