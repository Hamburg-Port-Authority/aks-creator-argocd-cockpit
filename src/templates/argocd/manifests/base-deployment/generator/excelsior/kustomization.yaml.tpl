apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - manifests/cert-manager/namespace.yaml
  - manifests/external-dns/namespace.yaml
  - manifests/ingress-nginx/namespace.yaml

generators:
  - ../../overlay/excelsior/
