{{- define "bevel-storageclass.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bevel-storageclass.fullname" -}}
{{- printf "storage-%s-%s" .Release.Namespace .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "provisioner" -}}
provisioner: k8s.io/minikube-hostpath
{{- end -}}
