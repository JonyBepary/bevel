{{- define "bevel-storageclass.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bevel-storageclass.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Namespace $name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bevel-storageclass.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "provisioner" -}}
{{- if eq .Values.global.cluster.provider "aws" -}}
provisioner: kubernetes.io/aws-ebs
{{- else if eq .Values.global.cluster.provider "gcp" -}}
provisioner: pd.csi.storage.gke.io
{{- else if eq .Values.global.cluster.provider "minikube" -}}
provisioner: k8s.io/minikube-hostpath
{{- else if eq .Values.global.cluster.provider "azure" -}}
provisioner: disk.csi.azure.com
{{- end -}}
{{- end -}}
