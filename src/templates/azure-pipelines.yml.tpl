trigger: none

resources:
  pipelines:
  - pipeline: apply-argocd-cockpit # Name of the pipeline resource.
    source: terraform-cicd # The name of the pipeline referenced by this pipeline resource.


variables:
  - group: argocd-cockpit
{% raw %}
  - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
      - name: environment
        value: development
  - ${{ if startsWith(variables['Build.SourceBranch'], 'refs/tags/') }}:
      - name: environment
        value: production
{% endraw %}

pool:
  vmImage: ubuntu-latest

jobs:
  - job: deploy_kubernetes_cluster
    workspace:
      clean: all
    steps:
      - checkout: self
      {%- for cluster in clusters %}
      - template: azure-pipelines/fetch-kubeconfig.yaml
        parameters:
          clusters:
            - name: {{ cluster.name }}-{{ cluster.stage }}
              repositoryName: {{ cluster.name }}
              {% raw %}
              environment: ${{ variables.environment }}
              {% endraw %}
      - template: azure-pipelines/apply-services.yaml
        parameters:
          clusters:
            - name: {{ cluster.name }}-{{ cluster.stage }}
              repositoryName: {{ cluster.name }}
              {% raw %}
              environment: ${{ variables.environment }}
              {% endraw %}
      - template: azure-pipelines/apply-fleet-cluster.yaml
        parameters:
          clusters:
            - name: {{ cluster.name }}-{{ cluster.stage }}
              repositoryName: {{ cluster.name }}
              {% raw %}
              environment: ${{ variables.environment }}
              {% endraw %}
      {%- endfor %}
