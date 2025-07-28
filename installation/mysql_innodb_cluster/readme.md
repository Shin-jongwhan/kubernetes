### 250728
# MySQL innoDB cluster for kubernetes
### kubernetes에서 mysql innodb cluster를 구성하는 방법에 대해 알아보자.
### 참고
#### https://hackjsp.tistory.com/20
### <br/>

### innodb cluster architecture는 다음과 같이 생겼다.
### default는 되게 간단하다.
- router 1개 : primary + secondary에 라우팅 역할. 내부적으로 접속 요청을 읽기/쓰기 분리 라우팅을 함.
  - 쓰기 요청 → Primary
  - 읽기 요청 → Secondary
- primary (또는 master) 1개 : 주로 write를 담당(read도 가능하긴 함). 트랜잭션을 commit하면 binlog를 통해 나머지 노드로 복제됨.
- secondary (또는 replica 또는 slave) 2개 : read만 담당
- mysqlsh : 각종 언어로 명령어를 제출할 수 있도록 도와주는 툴. SQL, python, javascript 언어를 지원한다.
#### <img width="417" height="476" alt="image" src="https://github.com/user-attachments/assets/0cc9d3b7-210d-4e46-baf8-463ba830c97f" />
#### https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-innodb-cluster.html
### <br/>

### MySQL Operator for Kubernetes 
### 다음과 같은 architecture를 가지고 있다.
### 좀 복잡한 것 같은데, 기본적인 구조는 innodb cluster architecture와 같은데, 몇 가지가 추가되었을 뿐이다.
- mysqlsh에서 kubernetes에서 관리할 수 있도록 kubectl을 연결
- mysql load balancer layer 추가 : mysql router 바로 위의 layer로 load balancing을 담당한다.
- ingress layer : mysql에 실제적인 영향을 주는 layer는 아니긴 해서 참고만 해도 될 듯 하다. mysql을 비롯한 서비스의 접속 주소에 대한 프록시를 담당해준다.
#### <img width="720" height="678" alt="image" src="https://github.com/user-attachments/assets/07eab69b-778d-4e16-b275-a324d41f9893" />

### <br/><br/>

## 설치
### mysql-operator 설치
```
helm repo add mysql-operator https://mysql.github.io/mysql-operator/
helm repo update
helm install mysql-operator mysql-operator/mysql-operator --namespace service --create-namespace
```
#### <br/>

### helm으로 설치하면 이렇게 메세지가 나온다.
```
NAME: mysql-operator
LAST DEPLOYED: Mon Jul 28 13:47:53 2025
NAMESPACE: service
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Create an MySQL InnoDB Cluster by executing:
1. When using a source distribution / git clone: `helm install [cluster-name] -n [ns-name] ~/helm/mysql-innodbcluster`
2. When using the Helm repo from ArtifactHub
2.1 With self signed certificates
    export NAMESPACE="your-namespace"
    # in case the namespace doesn't exist, please pass --create-namespace
    helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster -n $NAMESPACE \
        --version 2.2.0 \
        --set credentials.root.password=">-0URS4F3P4SS" \
        --set tls.useSelfSigned=true

2.2 When you have own CA and TLS certificates
        export NAMESPACE="your-namespace"
        export CLUSTER_NAME="my-mysql-innodbcluster"
        export CA_SECRET="$CLUSTER_NAME-ca-secret"
        export TLS_SECRET="$CLUSTER_NAME-tls-secret"
        export ROUTER_TLS_SECRET="$CLUSTER_NAME-router-tls-secret"
        # Path to ca.pem, server-cert.pem, server-key.pem, router-cert.pem and router-key.pem
        export CERT_PATH="/path/to/your/ca_and_tls_certificates"

        kubectl create namespace $NAMESPACE

        kubectl create secret generic $CA_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --from-file=ca.pem=$CERT_PATH/ca.pem \
        | kubectl apply -f -

        kubectl create secret tls $TLS_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --cert=$CERT_PATH/server-cert.pem --key=$CERT_PATH/server-key.pem \
        | kubectl apply -f -

        kubectl create secret tls $ROUTER_TLS_SECRET \
            --namespace=$NAMESPACE --dry-run=client --save-config -o yaml \
            --cert=$CERT_PATH/router-cert.pem --key=$CERT_PATH/router-key.pem \
        | kubectl apply -f -

        helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster -n $NAMESPACE \
        --version 2.2.0 \
        --set credentials.root.password=">-0URS4F3P4SS" \
        --set tls.useSelfSigned=false \
        --set tls.caSecretName=$CA_SECRET \
        --set tls.serverCertAndPKsecretName=$TLS_SECRET \
        --set tls.routerCertAndPKsecretName=$ROUTER_TLS_SECRET

```
### <br/>

### mysql-innodbcluster 설치 가능한 버전 확인
#### 아래 버전 중에 가장 최신을 사용하면 된다.
```
helm search repo mysql-operator/mysql-innodbcluster --versions
```
#### <img width="943" height="137" alt="image" src="https://github.com/user-attachments/assets/7ccf903f-bc3e-4d03-9832-73d7b6e13118" />
### <br/>

### mysql-innodbcluster 설치
#### install-mysql-innodbcluster.sh
```
#!/bin/bash

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

### 설치 완료 메세지
#### <img width="359" height="104" alt="image" src="https://github.com/user-attachments/assets/5934231f-81a8-44da-8507-afb1088c9c8c" />
### <br/>

### 이제 pod들이 잘 떴는지 확인해보자.
```
kubectl get pods -n service
```
#### <img width="707" height="37" alt="image" src="https://github.com/user-attachments/assets/3f8175ff-d2aa-4494-8e97-8fd81a949c3c" />
### <br/>

### 혹시 계속 initializing 상태가 지속된다면 log를 확인해보자.
#### 트러블슈팅은 아래에 별도로 정리해두었다.
```
kubectl get innodbclusters -n tgf
```
### <br/><br/>


-------------

# Troubleshooting
## connection 실패
### 해결 못 함. 추후 해결 예정
### log 확인
```
# mysql operator
kubectl logs deploy/mysql-operator -n tgf
# mysql 개별 pod
kubectl logs my-mysql-innodbcluster-0 -n tgf
```
### <br/>

### 접속 실패 에러가 나온다.
#### 은 현재 MySQL Operator가 자동으로 생성한 사용자 계정(mysqladmin-...)을 이용해 MySQL 인스턴스에 접속을 시도했지만, 로그인에 실패했다는 것을 의미한다.
```
Traceback (most recent call last):
  File "/usr/lib/mysqlsh/python-packages/mysqloperator/controller/shellutils.py", line 93, in call
    return f(*args)
mysqlsh.DBError: MySQL Error (1045): Access denied for user 'mysqladmin-AMaQGebc9H'@'192.168.183.69' (using password: YES)

[2025-07-28 05:19:18,457] kopf.objects         [INFO    ] Error executing mysqlsh.connect_dba, retrying after 10s: MySQL Error (1045): Access denied for user 'mysqladmin-AMaQGebc9H'@'192.168.183.69' (using password: YES)
[2025-07-28 05:19:23,086] kopf.objects         [WARNING ] Patching failed with inconsistencies: (('remove', ('status', 'kopf'), {'dummy': '2025-07-28T05:19:23.062214+00:00'}, None),)
[2025-07-28 05:19:23,204] kopf.objects         [INFO    ] ignored pod event
[2025-07-28 05:19:23,204] kopf.objects         [INFO    ] Handler 'on_pod_event' succeeded.
on_pod_create: pod=my-mysql-innodbcluster-2 ContainersReady=True Ready=False gate[configured]=True
[2025-07-28 05:19:23,223] kopf.objects         [INFO    ] on_pod_create: cluster create time None
[2025-07-28 05:19:23,223] kopf.objects         [ERROR   ] Handler 'on_pod_create' failed temporarily: my-mysql-innodbcluster busy. lock_owner=my-mysql-innodbcluster-0 owner_context=n/a lock_created_at=2025-07-28T05:05:19.271456
[2025-07-28 05:19:23,246] kopf.objects         [WARNING ] Patching failed with inconsistencies: (('remove', ('status', 'kopf'), {'progress': {'on_pod_create': {'started': '2025-07-28T05:04:49.016456+00:00', 'stopped': None, 'delayed': '2025-07-28T05:19:33.223609+00:00', 'purpose': 'create', 'retries': 85, 'success': False, 'failure': False, 'message': 'my-mysql-innodbcluster busy. lock_owner=my-mysql-innodbcluster-0 owner_context=n/a lock_created_at=2025-07-28T05:05:19.271456', 'subrefs': None}}}, None),)
```
### <br/>

### MySQL Operator는 클러스터 초기화 중 내부적으로 다음 작업들을 자동으로 수행한다.
- root 계정으로 접속
- 내부 관리용 계정 mysqladmin-<랜덤> 생성
- 해당 계정으로 다시 접속하여 replication 및 group replication 구성
### <br/>

### <br/><br/>

## innodbcluster 삭제 실패
### 아래 명령어가 계속 홀드 상태일 때의 경우다.
```
kubectl delete innodbcluster my-mysql-innodbcluster -n service
```
#### <br/>

### 이 명령어를 입력하면 finalizers가 나오는데, 이걸 삭제해줘야 한다.
```
kubectl get innodbcluster my-mysql-innodbcluster -n tgf -o json | grep finalizers -A 2
```
#### <br/>

#### finalizers 항목
```
        "finalizers": [
            "mysql.oracle.com/cluster"
        ],
```
### <br/>

### 아래와 같이 적용한 후에 다시 삭제를 시도해보면 잘 된다.
```
kubectl get innodbcluster my-mysql-innodbcluster -n tgf -o json > cluster.json
# 파일에서 finalizers를 삭제한 후 적용
kubectl replace -f cluster.json
```
