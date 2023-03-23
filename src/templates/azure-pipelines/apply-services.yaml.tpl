{% raw %}
parameters:
  - name: clusters
    type: object
    default: {}

steps:
  - ${{ each cluster in parameters.clusters }}:
      - task: Bash@3
        displayName: ${{ cluster.name }} - Start
        inputs:
          script: |
            echo "######### Start Apply Services for ${{ cluster.name }} ############"
          targetType: inline
      - task: Bash@3
        displayName: Create argocd namespace - ${{ cluster.name }}
        inputs:
          script: |
            if ! kubectl get ns argocd; then
              kubectl create namespace argocd
            fi
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: Install Argo CD (incl. CRD) - ${{ cluster.name }}
        inputs:
          script: |
            kubectl apply -k argocd/
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      #apply manifests folder
      - task: Bash@3
        displayName: Apply Argo CD Manifests - ${{ cluster.name }}
        inputs:
          script: |
            kubectl apply -k argocd/env/${{ cluster.environment }}/manifests
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: Patch Argo CD Secret - ${{ cluster.name }}
        inputs:
          script: |
            kubectl -n argocd patch secret  argocd-secret  --type='json' -p='[{"op" : "replace" ,"path" : "/data/oidc.azure.clientSecret" ,"value" : "'$AZURE_AAD_SSO_APP_SECRET'"}]'
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
          AZURE_AAD_SSO_APP_SECRET: $(AZURE_AAD_SSO_APP_SECRET)
      - task: Bash@3
        displayName: Patch Argo CD ConfigMaps - ${{ cluster.name }}
        inputs:
          script: |
            kubectl -n argocd apply -f argocd/env/${{ cluster.environment }}/oidc-azure-ad/argocd-cm.yaml
            kubectl -n argocd apply -f argocd/env/${{ cluster.environment }}/oidc-azure-ad/argocd-rbac-cm.yaml
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: Restart Argo- and Dex-Server - ${{ cluster.name }}
        inputs:
          script: |
            kubectl rollout restart deployment argocd-server -n argocd
            kubectl rollout restart deployment  argocd-dex-server -n argocd
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: Apply Helm Charts - ${{ cluster.name }}
        inputs:
          script: |
            kustomize build --enable-helm argocd/env/${{ cluster.environment }}/manifests/base-deployment/generator/excelsior/ | kubectl apply -f -
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: Apply Service Context - ${{ cluster.name }}
        inputs:
          script: |
            kubectl apply -k argocd/env/${{ cluster.environment }}/manifests/clusterissuer
          targetType: inline
        env:
          AAD_SERVICE_PRINCIPAL_CLIENT_ID: $(ARM_CLIENT_ID)
          AAD_SERVICE_PRINCIPAL_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
          KUBECONFIG: ${{ cluster.repositoryName }}/kubeconfig
      - task: Bash@3
        displayName: ${{ cluster.name }} - End
        inputs:
          script: |
            echo "######### End Apply Services for ${{ cluster.name }} ############"
          targetType: inline
{% endraw %}
