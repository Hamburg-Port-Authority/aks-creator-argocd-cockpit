apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: external-dns

resources:
  - helm-chart.yaml