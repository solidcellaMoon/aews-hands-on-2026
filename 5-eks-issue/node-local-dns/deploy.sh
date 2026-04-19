# 설치
helm dependency update .

helm upgrade --install node-local-dns . \
  -n kube-system \
  -f ./values.yaml

kubectl -n kube-system rollout status ds/node-local-dns
kubectl -n kube-system get po -l app.kubernetes.io/name=node-local-dns -o wide

# 삭제
#helm uninstall node-local-dns -n kube-system