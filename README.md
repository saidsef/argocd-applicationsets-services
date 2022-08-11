# ArgoCD ApplicationSet Services [![Chart](https://github.com/saidsef/argocd-applicationsets-services/actions/workflows/charts.yml/badge.svg)](#deployment)

[ApplicationSets](https://argocd-applicationset.readthedocs.io/en/stable/) interact with ArgoCD by creating, updating, managing, and deleting ArgoCD Applications. The ApplicationSets job is to make sure that the ArgoCD Application remains consistent with the declared ApplicationSet resource. ApplicationSets can be thought of as sort of an “Application factory”. It takes an ApplicationSet and outputs one or more ArgoCD Applications.

This helm chart implements Pull Request generator of ApplicationSet, it uses API of an SCMaaS provider (eg GitHub) to automatically discover open pull requests within an repository via **label**. This fits well with the style of building a test environment when you create a pull request.

## Prerequisite

Services that should already be installed and/or running.

- Kubernetes Cluster
- ArgoCD
- ArgoCD ApplicationSet Controller

## Deployment

### HELM

```shell
helm repo add applicationsets-services https://saidsef.github.io/argocd-applicationsets-services/
helm repo update
helm upgrade --install pr-services applicationsets-services/argocd-applicationsets-services --namespace argocd
```

## Source

Our latest and greatest source of `argocd-applicationsets-services` can be found on [GitHub](#deployment). Fork us!

## Contributing

We would :heart: you to contribute by making a [pull request](https://github.com/saidsef/argocd-applicationsets-services/pulls).

Please read the official [Contribution Guide](./CONTRIBUTING.md) for more information on how you can contribute.
