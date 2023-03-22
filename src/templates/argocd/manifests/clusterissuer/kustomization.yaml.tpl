apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
{% if argocd.security.enable %}
  - clusterissuer-dns.yaml
  - clusterissuer-http.yaml
{% endif %}
