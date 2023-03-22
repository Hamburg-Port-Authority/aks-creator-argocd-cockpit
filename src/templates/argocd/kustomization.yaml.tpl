apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd
resources:
  - https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/ha/install.yaml
{% if argocd.ingress.enable %}
  - ingress.yaml
{% endif %}
