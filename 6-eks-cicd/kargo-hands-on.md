# kargo hands-on

- https://docs.kargo.io/quickstart

자주 사용하는 로컬 환경 k8s 툴에서 바로 실습 환경 세팅하는 스크립트를 제공하고 있다.
- 여기서는 k3d를 사용한다. (전체 삭제 / 다시 생성이 용이하기 때문)

```bash
# Kargo Docs에서 제공하는 설치 스크립트 다운로드
❯ wget https://raw.githubusercontent.com/akuity/kargo/main/hack/quickstart/k3d.sh

# 파일 이름 변경 (내용 한번 확인하기 위함)
❯ mv k3d.sh k3d-install.sh && chmod +x k3d-install.sh

# 실행해서 실습 환경 설치
❯ ./k3d-install.sh 
+ argo_cd_chart_version=9.4.3
+ argo_rollouts_chart_version=2.40.6
+ cert_manager_chart_version=1.19.3
+ k3d cluster create kargo-quickstart --no-lb --k3s-arg --disable=traefik@server:0 -p 31080-31082:31080-31082@servers:0:direct -p 32080-32082:32080-32082@servers:0:direct --wait
INFO[0000] Prep: Network                                
INFO[0000] Created network 'k3d-kargo-quickstart'       
INFO[0000] Created image volume k3d-kargo-quickstart-images 
INFO[0000] Starting new tools node...                   
INFO[0001] Creating node 'k3d-kargo-quickstart-server-0' 
INFO[0003] Pulling image 'ghcr.io/k3d-io/k3d-tools:5.8.3' 
INFO[0003] Pulling image 'docker.io/rancher/k3s:v1.31.5-k3s1' 
INFO[0005] Starting node 'k3d-kargo-quickstart-tools'   
INFO[0017] Using the k3d-tools node to gather environment information 
INFO[0017] HostIP: using network gateway 192.168.107.1 address 
INFO[0017] Starting cluster 'kargo-quickstart'          
INFO[0017] Starting servers...                          
INFO[0017] Starting node 'k3d-kargo-quickstart-server-0' 
INFO[0020] All agents already running.                  
INFO[0020] All helpers already running.                 
INFO[0020] Injecting records for hostAliases (incl. host.k3d.internal) and for 1 network members into CoreDNS configmap... 
INFO[0022] Cluster 'kargo-quickstart' created successfully! 
INFO[0022] You can now use it like this:                
kubectl cluster-info
+ helm install cert-manager cert-manager --repo https://charts.jetstack.io --version 1.19.3 --namespace cert-manager --create-namespace --set crds.enabled=true --wait
NAME: cert-manager
LAST DEPLOYED: Sun Apr 26 16:00:45 2026
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
⚠️  WARNING: New default private key rotation policy for Certificate resources.
The default private key rotation policy for Certificate resources was
changed to `Always` in cert-manager >= v1.18.0.
Learn more in the [1.18 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.18).

cert-manager v1.19.3 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/
+ helm install argocd argo-cd --repo https://argoproj.github.io/argo-helm --version 9.4.3 --namespace argocd --create-namespace --set 'configs.secret.argocdServerAdminPassword=$2a$10$5vm8wXaSdbuff0m9l21JdevzXBzJFPCi8sy6OOnpZMAG.fOXL7jvO' --set dex.enabled=false --set notifications.enabled=false --set server.service.type=NodePort --set server.service.nodePortHttp=31080 --set 'server.extraArgs={--insecure}' --set server.extensions.enabled=true --set 'server.extensions.extensionList[0].name=argo-rollouts' --set 'server.extensions.extensionList[0].env[0].name=EXTENSION_URL' --set 'server.extensions.extensionList[0].env[0].value=https://github.com/argoproj-labs/rollout-extension/releases/download/v0.3.7/extension.tar' --wait
NAME: argocd
LAST DEPLOYED: Sun Apr 26 16:01:21 2026
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)
+ helm install argo-rollouts argo-rollouts --repo https://argoproj.github.io/argo-helm --version 2.40.6 --create-namespace --namespace argo-rollouts --wait
NAME: argo-rollouts
LAST DEPLOYED: Sun Apr 26 16:02:01 2026
NAMESPACE: argo-rollouts
STATUS: deployed
REVISION: 1
TEST SUITE: None
+ helm install kargo oci://ghcr.io/akuity/kargo-charts/kargo --namespace kargo --create-namespace --set api.service.type=NodePort --set api.service.nodePort=31081 --set api.tls.enabled=false --set 'api.adminAccount.passwordHash=$2a$10$Zrhhie4vLz5ygtVSaif6o.qN36jgs6vjtMBdM6yrU1FOeiAAMMxOm' --set api.adminAccount.tokenSigningKey=iwishtowashmyirishwristwatch --set externalWebhooksServer.service.type=NodePort --set externalWebhooksServer.service.nodePort=31082 --set externalWebhooksServer.tls.enabled=false --wait
Pulled: ghcr.io/akuity/kargo-charts/kargo:1.10.2
Digest: sha256:392e25bc85c51287c7cd37a4a26b15552dc7d07b3bbb6509a53875c77ab5ab8c
W0426 16:02:33.716874   33929 warnings.go:70] spec.privateKey.rotationPolicy: In cert-manager >= v1.18.0, the default value changed from `Never` to `Always`.
NAME: kargo
LAST DEPLOYED: Sun Apr 26 16:02:31 2026
NAMESPACE: kargo
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
.----------------------------------------------------------------------------------.
|     _                            _                    _          _ _             |
|    | | ____ _ _ __ __ _  ___    | |__  _   _     __ _| | ___   _(_) |_ _   _     |
|    | |/ / _` | '__/ _` |/ _ \   | '_ \| | | |   / _` | |/ / | | | | __| | | |    |
|    |   < (_| | | | (_| | (_) |  | |_) | |_| |  | (_| |   <| |_| | | |_| |_| |    |
|    |_|\_\__,_|_|  \__, |\___/   |_.__/ \__, |   \__,_|_|\_\\__,_|_|\__|\__, |    |
|                   |___/                |___/                           |___/     |
'----------------------------------------------------------------------------------'

Ready to get started?

⚙️  You've configured Kargo's API server with a Service of type NodePort.

   The Kargo API server is reachable on port 31081 of any reachable node in
   your Kubernetes cluster.

   If a node in a local cluster were addressable as localhost, the Kargo API
   server would be reachable at:

      http://localhost:31081

🖥️  To access Kargo's web-based UI, navigate to the address above.

⬇️  The latest version of the Kargo CLI can be downloaded from:

      https://github.com/akuity/kargo/releases/latest

🛠️  To log in using the Kargo CLI:

      kargo login http://localhost:31081 --admin

⚙️  You've configured Kargo's external webhooks server with a Service of type
   NodePort.

   The Kargo external webhooks server is reachable on port 31082 of
   any reachable node in your Kubernetes cluster.

   If a node in a local cluster were addressable as localhost, the Kargo
   external webhooks server would be reachable at:

      http://localhost:31082

📚  Kargo documentation can be found at:

      https://docs.kargo.io

🙂  Happy promoting!
```

설치하면 ArgoCD / Kargo는 각각 아래로 들어갈 수 있다.
- ArgoCD
  - URL: http://localhost:31080
  - Username: admin
  - Password: admin

Kargo
- URL: http://localhost:31081
- Password: admin

이어서 데모 실습을 위해 미리 제공되는 배포 Manifest 예제가 구성된 [Repo](https://github.com/akuity/kargo-demo)를 Fork하여 사용하라고 한다.
하지만 여기서는 위 Repo 내용을 그대로 가져와 [./kargo-demo](./kargo-demo/) 안에 넣어두었음.

또한, 해당 Repo에 대한 Personal Access Token이 필요하다.
- Kargo가 환경별 변경 사항을 Manifest Repo에 Push하기 때문. 원하는 Repo에 대한 Write 권한이 필요하다.
- Personal Access Token 발급 과정/내용은 생략함.

이어서 환경변수로 설정하자.
```bash
export GITOPS_REPO_URL=https://github.com/<your-github-username>/<your-target-repository>
export GITHUB_USERNAME=<your-github-username>
export GITHUB_PAT=<your-personal-access-token>
```

ArgoCD AppSet을 배포하자.
```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: kargo-demo
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - stage: test
      - stage: uat
      - stage: prod
  template:
    metadata:
      name: kargo-demo-{{stage}}
      annotations:
        kargo.akuity.io/authorized-stage: kargo-demo:{{stage}}
    spec:
      project: default
      source:
        repoURL: ${GITOPS_REPO_URL}
        targetRevision: stage/{{stage}}
        path: .
      destination:
        server: https://kubernetes.default.svc
        namespace: kargo-demo-{{stage}}
      syncPolicy:
        syncOptions:
        - CreateNamespace=true
EOF
```