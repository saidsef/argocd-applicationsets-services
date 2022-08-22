# argocd-applicationsets-services

![Version: 0.2.1](https://img.shields.io/badge/Version-0.2.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.2.1](https://img.shields.io/badge/AppVersion-0.2.1-informational?style=flat-square)

A HELM Chart for ArgoCD ApplicationSets for Kubernetes

**Homepage:** <https://github.com/saidsef/argocd-applicationsets-services>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Said Sef | <saidsef@gmail.com> | <https://saidsef.co.uk> |

## Source Code

* <https://github.com/saidsef/argocd-applicationsets-services.git>

## Requirements

Kubernetes: `>= 1.23`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| helm | object | `{"enabled":false}` | TODO: Implement |
| kustomize | object | `{"enabled":true}` | Should kustomize be enabled |
| label | string | `"preview"` | GitHub label to filter PRs that you want to target |
| name | string | `"pr-review"` | ApplicationSet name |
| namespace | string | `"argocd"` | Namespace of ArgoCD controller is deployed |
| owner | string | `"saidsef"` | GitHub repo Organization / username |
| path | string | `"deployment"` | Repository path where deployment files are located |
| repos | list | `[{"images":["docker.io/saidsef/node-webserver:{{branch}}"],"name":"node-webserver"},{"name":"alpine-jenkins-dockerfile","path":"deployment/preview"},{"images":["docker.io/saidsef/aws-kinesis-local:{{branch}}"],"name":"aws-kinesis-local"},{"images":["docker.io/saidsef/aws-dynamodb-local:{{branch}}"],"name":"aws-dynamodb-local"},{"name":"tika-document-to-text","path":"deployment/preview"}]` | List of repo names and override images for preview environment to dynamically pass the branch of the pull request head use '{{branch}}' variable see: https://argocd-applicationset.readthedocs.io/en/stable/Generators-Pull-Request/#template |
| requeueAfterSeconds | int | `300` | GitHub polling rate (seconds) |
| secretKey | string | `""` |  |
| secretName | string | `""` | GitHub secrets to use for API polling |
| server | string | `"https://kubernetes.default.svc"` | ArgoCD server address |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)