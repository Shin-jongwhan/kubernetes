```
#!/bin/bash

# mysql-operator 제거
helm uninstall mysql-operator -n service
helm install mysql-operator mysql-operator/mysql-operator --namespace service --version 2.2.5

# 기존에 설치된 클러스터 제거
helm uninstall my-mysql-innodbcluster -n service
kubectl delete pod -n service my-mysql-innodbcluster-0 my-mysql-innodbcluster-1 my-mysql-innodbcluster-2
kubectl delete pvc -l app.kubernetes.io/instance=my-mysql-innodbcluster -n service
kubectl delete secret my-mysql-innodbcluster-ca-secret -n service
kubectl delete secret my-mysql-innodbcluster-tls-secret -n service
kubectl delete secret my-mysql-innodbcluster-router-tls-secret -n service

# ===============================
# 설정
# ===============================
VERSION="2.2.5"
NAMESPACE="service"
CLUSTER_NAME="my-mysql-innodbcluster"
CERT_PATH="/path/to/your/certs"  # 실제 인증서 경로로 수정 필요

# secret 이름 설정
CA_SECRET="$CLUSTER_NAME-ca-secret"
TLS_SECRET="$CLUSTER_NAME-tls-secret"
ROUTER_TLS_SECRET="$CLUSTER_NAME-router-tls-secret"

# ===============================
# 네임스페이스 생성
# ===============================
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# ===============================
# 인증서 Secret 생성
# ===============================
kubectl create secret generic "$CA_SECRET" \
  --namespace="$NAMESPACE" --dry-run=client --save-config -o yaml \
  --from-file=ca.pem="$CERT_PATH/ca.pem" \
  | kubectl apply -f -

kubectl create secret tls "$TLS_SECRET" \
  --namespace="$NAMESPACE" --dry-run=client --save-config -o yaml \
  --cert="$CERT_PATH/server-cert.pem" --key="$CERT_PATH/server-key.pem" \
  | kubectl apply -f -

kubectl create secret tls "$ROUTER_TLS_SECRET" \
  --namespace="$NAMESPACE" --dry-run=client --save-config -o yaml \
  --cert="$CERT_PATH/router-cert.pem" --key="$CERT_PATH/router-key.pem" \
  | kubectl apply -f -

# ===============================
# Helm으로 InnoDB Cluster 설치
# ===============================
helm install "$CLUSTER_NAME" mysql-operator/mysql-innodbcluster \
  --namespace "$NAMESPACE" \
  --version "$VERSION" \
  --set credentials.root.password="REPLACE_WITH_STRONG_PASSWORD" \
  --set tls.useSelfSigned=false \
  --set tls.caSecretName="$CA_SECRET" \
  --set tls.serverCertAndPKsecretName="$TLS_SECRET" \
  --set tls.routerCertAndPKsecretName="$ROUTER_TLS_SECRET"
```
#### <br/>
