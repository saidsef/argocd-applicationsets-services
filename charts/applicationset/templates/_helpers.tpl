{{/*
Copyright (c) 2018 Said Sef
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Values.name .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "chart.namespace" -}}
{{- default .Values.namespace | replace "." "-" }}
{{- end }}

{{- define "chart.notificationChannel" -}}
{{- coalesce .Values.notificationChannel .Values.globals.notificationChannel }}
{{- end }}

{{- define "chart.server" -}}
{{- coalesce .Values.server .Values.globals.server | squote }}
{{- end }}

{{- define "chart.notificationChannel" -}}
{{- coalesce .Values.notificationChannel .Values.globals.notificationChannel }}
{{- end }}

{{- define "chart.server" -}}
{{- coalesce .Values.server .Values.globals.server | squote }}
{{- end }}

{{- define "chart.refresh" -}}
{{- coalesce .Values.requeueAfterSeconds .Values.globals.requeueAfterSeconds -}}
{{- end }}

{{- define "chart.retryBackoffDuration" -}}
{{- coalesce .Values.retryBackoffDuration .Values.globals.retryBackoffDuration -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "chart.globals" -}}
{{ .Values.globals }}
{{- end }}
