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
```
# 기존에 설치한 것이 있으면 삭제
helm uninstall my-mysql-innodbcluster -n tgf
# 재설치
helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster \
  --namespace service \
  --version 2.2.5 \
  --set credentials.root.password="mypassword" \
  --set tls.useSelfSigned=true
```
#### <br/>

### 설치 완료 메세지
#### <img width="359" height="104" alt="image" src="https://github.com/user-attachments/assets/5934231f-81a8-44da-8507-afb1088c9c8c" />
### <br/>

### 이제 pod들이 잘 떴는지 확인해보자.
```
kubectl get pods -n service
```
