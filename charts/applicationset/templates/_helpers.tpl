{{/*
Copyright (c) 2018 Said Sef
*/}}

{{- define "chart.namespace" -}}
{{- default .Values.namespace | replace "." "-" }}
{{- end }}

{{- define "chart.server" -}}
{{- coalesce .Values.server .Values.globals.server }}
{{- end }}

{{- define "chart.refresh" -}}
{{- coalesce .Values.requeueAfterSeconds .Values.globals.requeueAfterSeconds -}}
{{- end }}

{{- define "chart.retryBackoffDuration" -}}
{{- coalesce .Values.retryBackoffDuration .Values.globals.retryBackoffDuration -}}
{{- end }}

{{/*
GitHub pull request generator body (emitted from column 0; the caller places it
with `- {{ include ... | nindent N | trim }}` so it reads standalone or nested
inside a matrix generator). Expected dict keys: github, globals, repo, refresh.
*/}}
{{- define "chart.githubGenerator" -}}
{{- $github := .github -}}
{{- $globals := .globals -}}
{{- $repo := .repo -}}
{{- $refresh := .refresh -}}
pullRequest:
  github:
    api: {{ $github.api }}
    owner: {{ required "A valid repo organization / owner is required" $github.owner }}
    repo: {{ required "A valid repo name is required" $repo.name }}
    {{- $labels := $github.labels }}
    {{- if not $labels }}{{- $labels = list (required "A valid label(s) for PRs is required" (coalesce $github.label $globals.label)) }}{{- end }}
    labels:
    {{- range $l := $labels }}
    - {{ $l }}
    {{- end }}
    {{- if and ($github.secretName) ($github.secretKey) }}
    tokenRef:
      secretName: {{ $github.secretName }}
      key: {{ $github.secretKey }}
    {{- end }}
    {{- if $github.appSecretName }}
    appSecretName: {{ $github.appSecretName }}
    {{- end }}
  requeueAfterSeconds: {{ $refresh | default 500 }}
{{- end -}}

{{/*
GitLab merge request generator body. Expected dict keys: gitlab, globals, repo, refresh.
*/}}
{{- define "chart.gitlabGenerator" -}}
{{- $gitlab := .gitlab -}}
{{- $globals := .globals -}}
{{- $repo := .repo -}}
{{- $refresh := .refresh -}}
pullRequest:
  gitlab:
    api: {{ $gitlab.api }}
    project: {{ coalesce $repo.project $gitlab.group |  required "A valid repo project / group ID is required" | squote}}
    pullRequestState: {{ $gitlab.pullRequestState | default "opened" | squote }}
    {{- $labels := $gitlab.labels }}
    {{- if not $labels }}{{- $labels = list (required "A valid label(s) for PRs is required" (coalesce $gitlab.label $globals.label)) }}{{- end }}
    labels:
    {{- range $l := $labels }}
    - {{ $l }}
    {{- end }}
    {{- if and ($gitlab.secretName) ($gitlab.secretKey) }}
    tokenRef:
      secretName: {{ $gitlab.secretName }}
      key: {{ $gitlab.secretKey }}
    {{- end }}
    {{- if $gitlab.insecure }}
    insecure: true
    {{- end }}
    {{- with $gitlab.caRef }}
    caRef:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  requeueAfterSeconds: {{ $refresh | default 500 }}
{{- end -}}

{{/*
Shared ArgoCD Application template body for the GitHub PR and GitLab MR
ApplicationSets. The two generators are ~90% identical; the provider-specific
values are pre-computed by each caller and passed via a dict so this template
stays platform-agnostic and there is a single source of truth for the payload.

Expected dict keys:
  repo                  the per-repo entry ($repo)
  globals               .Values.globals (revisionHistoryLimit/annotations/syncOptions/deployToNamespace)
  server                squoted ArgoCD server (include "chart.server")
  retryBackoffDuration  sync retry backoff
  project               pre-computed AppProject name or "default"
  repoURL               pre-computed source repoURL
  label                 pre-computed part-of label
  path                  provider default source path
  nameFormat            pre-computed Application metadata.name
  externalLink          pre-computed external-link annotation value
  infoKey               "pull_request" or "merge_request"
*/}}
{{- define "chart.applicationTemplate" -}}
{{- $dqf := "{{" -}}
{{- $dqb := "}}" -}}
{{- $branch := "{{ .branch }}" | squote -}}
{{- $branchSlug := "{{ .branch_slug }}" | squote -}}
{{- $headShortSha := "{{ .head_short_sha }}" | squote -}}
{{- $repo := .repo -}}
{{- $globals := .globals -}}
{{- $server := .server -}}
{{- $retryBackoffDuration := .retryBackoffDuration }}
  template:
    metadata:
      {{- /* server=all fans out over a clusters x pullRequest matrix; without the
             cluster name the Application name collides across clusters and only one
             is created. nameNormalized is the RFC-1123 safe cluster name. */}}
      name: {{ .nameFormat }}{{ if eq $server "all" }}-{{ $dqf }} .nameNormalized {{ $dqb }}{{ end }}
      labels:
        app.kubernetes.io/name: {{ $repo.name }}
        app.kubernetes.io/branch: {{ trunc 63 $branchSlug | trimSuffix "-" }}
        app.kubernetes.io/created-by: 'applicationset'
      annotations:
        argocd.argoproj.io/head: {{ $headShortSha }}
        link.argocd.argoproj.io/external-link: '{{ .externalLink }}'
        {{- with $globals.annotations }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      revisionHistoryLimit: {{ $globals.revisionHistoryLimit }}
      source:
        repoURL: {{ .repoURL }}
        {{- if and $repo $repo.parameters }}
        helm:
          parameters:
            {{ toJson $repo.parameters | indent 0 }}
        chart: {{ or $repo.chart $repo.name }}
        targetRevision: {{ or $repo.targetRevision ">= 0" | quote }}
        {{- else if and $repo $repo.values }}
        helm:
          values: |
            {{ toJson $repo.values | indent 0 }}
        {{- if and $repo $repo.chart }}
        chart: {{ or $repo.chart $repo.name }}
        {{- else if and $repo $repo.path }}
        path: {{ $repo.path }}
        {{- end }}
        targetRevision: {{ or $repo.targetRevision $branch $headShortSha "HEAD" }}
        {{- else }}
        targetRevision: {{ or $repo.targetRevision $branch $headShortSha "HEAD" }}
        kustomize:
          namespace: {{ coalesce $repo.namespace $globals.deployToNamespace (printf "mr-%s .branch_slug %s-%s .number %s" $dqf $dqb $dqf $dqb) | quote }}
          commonAnnotations:
            app.kubernetes.io/instance: '{{ $repo.name }}'
            app.kubernetes.io/part-of: {{ .label }}
            argocd.argoproj.io/head_short_sha: '{{ $dqf }} .head_short_sha {{ $dqb }}'
          {{- range $i, $r := $repo.images }}
          {{- if eq $i 0 }}
          images:
          {{- end }}
          - {{ $r | indent 0 | squote }}
          {{- end }}
        path: {{ coalesce $repo.path .path }}
        {{- end }}
      project: {{ .project }}
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
        managedNamespaceMetadata:
          labels:
            app.kubernetes.io/created-by: {{ $repo.name }}
        syncOptions:
        {{- range $s := $globals.syncOptions }}
          - {{ $s }}
        {{- end }}
        retry:
          backoff:
            duration: {{ $retryBackoffDuration }}
      destination:
        {{- if eq $server "all" }}
        server: '{{ $dqf }} .server {{ $dqb }}'
        {{- else }}
        server: {{ $server | squote }}
        {{- end }}
        namespace: {{ coalesce $repo.namespace $globals.deployToNamespace (printf "mr-%s .branch_slug %s-%s .number %s" $dqf $dqb $dqf $dqb) | quote }}
      info:
        - name: author
          value: '{{ $dqf }} .author {{ $dqb }}'
        - name: branch
          value: '{{ $dqf }} .branch {{ $dqb }}'
        - name: target_branch
          value: '{{ $dqf }} .target_branch_slug {{ $dqb }}'
        - name: branch_slug
          value: '{{ $dqf }} .branch_slug {{ $dqb }}'
        - name: head_short_sha
          value: '{{ $dqf }} .head_short_sha {{ $dqb }}'
        - name: {{ .infoKey }}
          value: '{{ $dqf }} .number {{ $dqb }}'
{{- end -}}
