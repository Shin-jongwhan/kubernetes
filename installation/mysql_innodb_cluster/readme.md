### 250728
# MySQL innoDB cluster for kubernetes
### kubernetes에서 mysql innodb cluster를 구성하는 방법에 대해 알아보자.
### 참고
#### https://hackjsp.tistory.com/20
#### <br/>

### MySQL 공식 사이트에서 아래 과정을 따라가면 쉽게 설치 가능
#### 1. https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-installation-helm.html
#### 2. https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-innodbcluster-simple-helm.html
#### 3. https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-connecting-mysql-shell.html
### <br/>

### MySQL 공식 사이트에서 어떤 Resource Properties를 지원하는지 잘 정리해주었다. 꼭 참고하자.
#### https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-properties.html
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
- StatefulSet : master + replica pod를 관리해주는 사이드카. 
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
#### 아래 버전 중에 가장 최신을 사용하면 되는데, 해보니 버전을 굳이 명시하지 않아도 된다.
```
helm search repo mysql-operator/mysql-innodbcluster --versions
```
#### <img width="943" height="137" alt="image" src="https://github.com/user-attachments/assets/7ccf903f-bc3e-4d03-9832-73d7b6e13118" />
### <br/>

### mysql-innodbcluster 설치
#### 아래는 참고 자료로 남겨두었다. 굳이 사용할 필요는 없을 것 같다.
#### [install-mysql-innodbcluster.sh](https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/mysql_innodb_cluster/install-mysql-innodbcluster-with-ca-tls.sh)
#### <br/>

### credentials.yaml 작성
#### helm install 시 --set 옵션으로도 할 수 있는데 yaml로 관리하는 게 훨씬 용이하다.
```
credentials:
  root:
    user: "root"
    password: "mypassword"
    host: "%"

serverInstances: 3
routerInstances: 1

tls:
  useSelfSigned: true
```
#### <br/>

### 아래 명령어로 설치한다. 
```
helm install mycluster mysql-operator/mysql-innodbcluster -n service --values credentials.yaml
```
#### <br/>

### 설치 완료 메세지
#### <img width="359" height="104" alt="image" src="https://github.com/user-attachments/assets/5934231f-81a8-44da-8507-afb1088c9c8c" />
### <br/>

### 이제 pod들이 잘 떴는지 확인해보자. 
#### * 그런데 아래 스크린샷 보면 router가 아직 에러가 있어서 정상적으로 실행이 안 되고 있다. 해결 방법은 아래에 troubleshooting 파트에서 router pod 설정 관련 내용을 참고하여 해결하자.
#### 하지만 개별 mysql pod를 접속해보면 잘 접속은 된다. 여기서는 일단 여기까지만 확인하자.
```
kubectl get pods -n service
# or
kubectl get all -n service
```
#### <img width="707" height="37" alt="image" src="https://github.com/user-attachments/assets/3f8175ff-d2aa-4494-8e97-8fd81a949c3c" />
#### <img width="939" height="570" alt="image" src="https://github.com/user-attachments/assets/57a36735-d5e9-4730-9c9b-e503b60bab3a" />
### <br/>

### mysqlsh로 접속 확인
```
kubectl exec -it -n service mycluster-0 -- bash
```

#### 접속 후 pod 안에서 아래 입력 후 설정한 비밀번호로 접속
```
mysqlsh root@localhost
```

#### SQL 테스트
```
show databases;
```
#### <img width="854" height="446" alt="image" src="https://github.com/user-attachments/assets/df28a3c2-c588-4870-b461-9d8a469dc25f" />
### <br/>

### 혹시 계속 initializing 상태가 지속된다면 log를 확인해보자.
#### 트러블슈팅은 아래에 별도로 정리해두었다.
```
kubectl get innodbclusters -n service
```
### <br/><br/>


## (내부망 네트워크에 있는 다른 컴퓨터) 외부 접속 허용하기 + router 작동 확인
### 먼저 mysql cluster router가 켜져 있어야 하고(아래 router 관련 트러블슈팅 확인), nodeport를 하나 열어줘야 한다.
### single primary node는 6446 port를 이용한다.
#### mycluster-nodeport.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mycluster-nodeport
  namespace: service
  labels:
    app.kubernetes.io/instance: mysql-innodbcluster-mycluster
    app.kubernetes.io/component: mysqlrouter
spec:
  type: NodePort
  selector:
    app.kubernetes.io/component: router
  ports:
    - name: mysqlrw
      protocol: TCP
      port: 6446         # 내부 ClusterIP에서 사용하던 포트
      targetPort: 6446
      nodePort: 30161    # 외부에서 접근할 NodePort
```
#### <br/>

### 적용
```
kubectl apply -f mycluster-nodeport.yaml
```
### <br/>

### 이후에 접속 테스트를 위한 계정을 하나 만들어본다.
```
kubectl exec -it mycluster-0 -n service -c mysql -- bash

# (pod 내에서) port 접속 후 비밀번호 입력
mysql -uroot -p

# (mysql shell 내에서)
# primary node인지 확인. 0이면 primary node이다.
SELECT @@super_read_only;

# 계정 생성
CREATE USER 'test'@'%' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON *.* TO 'test'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```
### <br/>

### 외부에서 접속을 해본다.
#### port가 위에서 설정한 nodeport와 같아야 한다.
#### host에는 kubernetes node로 등록된 곳 어느 주소이든 입력해도 접속이 가능하다. 이게 가능하면 router가 잘 기능하고 있다는 증거이다.
#### <img width="500" height="383" alt="image" src="https://github.com/user-attachments/assets/58680d70-9fe2-4c60-93c2-ac28de91151a" />
### <br/><br/>


## custom mycnf
#### https://dev.mysql.com/doc/mysql-operator/en/mysql-operator-properties.html
### MySQL 공식 사이트에서 아래 하위에 사용하면 된다고 정리해주었다.
### ❗ 그런데 이걸로 따라하면 안 됨 ! 참고만 하자.
- InnoDBCluster.spec
- InnoDBCluster.spec.readReplicas\[index\]

| **Name** | **Type** | **Description**                             | **Required** |
| -------- | -------- | ------------------------------------------- | ------------ |
| mycnf    | string   | Custom configuration additions for `my.cnf` | false        |

### <br/>

### 먼저 mysql-innodbcluster를 다운로드 받아보자.
### 아래 보면 values.yaml이 있다.
#### * 버전에 따라 얼마든지 옵션 설정하는 방법은 바뀔 수 있으니 버전이 다르다면 다시 확인하자.
```
helm pull mysql-operator/mysql-innodbcluster --untar
```
#### <img width="681" height="180" alt="image" src="https://github.com/user-attachments/assets/39e26e4e-51b1-472a-aec0-14259174db79" />
### <br/>

### 열어보면 mycnf를 어떻게 사용해야 하는지 나와 있다.
#### <img width="244" height="98" alt="image" src="https://github.com/user-attachments/assets/6b17003d-c7ca-441f-ad00-aec179044924" />
### <br/>

### 위 예시로 적용해보자.
#### helm_mysql_cluster_conf.yaml
```
credentials:
  root:
    user: "root"
    password: "mypassword"
    host: "%"

serverInstances: 3
routerInstances: 1

tls:
  useSelfSigned: true

serverConfig:
  mycnf: |
    [mysqld]
    log-bin=/var/lib/mysql/mysql-bin.log
    binlog_expire_logs_seconds = 864000
    max_binlog_size = 100M
    log_bin_trust_function_creators = 1
    collation-server = utf8mb4_general_ci
    default-time-zone = "+09:00"
    max_connections = 500
    [mysqldump]
    default-character-set = utf8mb4
    [mysql]
    default-character-set = utf8mb4

```
### <br/>

### 설치하고 pod에 들어가보자.
### pod에 들어갈 때는 -c mysql로 sidecar가 아닌 pod로 접속해야 한다.
```
kubectl exec -it -n service -c mysql mycluster-0 -- bash
```
#### <br/>

### pod 안에서 99-extra.cnf를 확인해보자.
```
cat /etc/my.cnf.d/99-extra.cnf
```
#### <br/>

### 여기에 이렇게 반영이 잘 되어 있다.
```
# Additional user configurations taken from spec.mycnf in InnoDBCluster.
# Do not edit directly.
[mysqld]
log-bin=/var/lib/mysql/mysql-bin.log
binlog_expire_logs_seconds = 864000
max_binlog_size = 100M
log_bin_trust_function_creators = 1
collation-server = utf8mb4_general_ci
default-time-zone = "+09:00"
max_connections = 500
[mysqldump]
default-character-set = utf8mb4
[mysql]
default-character-set = utf8mb4
```
### <br/>

### mysql에 접속해서 확인해보자.
```
# 접속
mysql -u root -p

# 쿼리
SHOW VARIABLES LIKE 'time_zone';
```
#### <img width="342" height="123" alt="image" src="https://github.com/user-attachments/assets/299232c0-8a58-493d-97ea-43e73166d045" />
### <br/><br/>

-------------

# Troubleshooting
## connection 실패
### 이거는 helm으로 설치할 때 --set으로 하는 config (또는 yaml) 설정 문제이다.
### log 확인
```
# mysql operator
kubectl logs deploy/mysql-operator -n service
# mysql 개별 pod
kubectl logs my-mysql-innodbcluster-0 -n service
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

### 다음과 같이 수정해서 다시 설치해보자.
#### credentials.yaml
```
credentials:
  root:
    user: "root"
    password: "your_password"
    host: "%"

serverInstances: 3
routerInstances: 1

tls:
  useSelfSigned: true
```
### <br/>

### 설치
```
# uninstall
helm uninstall mycluster -n service

# install
helm install mycluster mysql-operator/mysql-innodbcluster -n service --values credentials.yaml
```

### <br/><br/>

## innodbcluster 삭제 실패
### 아래 명령어가 계속 홀드 상태일 때의 경우다.
```
kubectl delete innodbcluster my-mysql-innodbcluster -n service
```
#### <br/>

### 이 명령어를 입력하면 finalizers가 나오는데, 이걸 삭제해줘야 한다.
```
kubectl get innodbcluster my-mysql-innodbcluster -n service -o json | grep finalizers -A 2
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
kubectl get innodbcluster my-mysql-innodbcluster -n service -o json > cluster.json
# 파일에서 finalizers를 삭제한 후 적용
kubectl replace -f cluster.json
```
### <br/><br/>


## cluster 완전 제거
```
# mysql-operator 제거
helm uninstall mysql-operator -n service
helm install mysql-operator mysql-operator/mysql-operator -n service --version 2.2.5

# finalizer 제거(필요시)
kubectl patch innodbcluster my-mysql-innodbcluster -n service -p '{"metadata":{"finalizers":null}}' --type=merge

# 기존에 설치된 클러스터 제거
helm uninstall my-mysql-innodbcluster -n service
kubectl delete innodbcluster my-mysql-innodbcluster -n service
kubectl delete pod -n service my-mysql-innodbcluster-0 my-mysql-innodbcluster-1 my-mysql-innodbcluster-2

# pvc 제거
kubectl delete pvc -l app.kubernetes.io/instance=my-mysql-innodbcluster -n service

# secret 등록했다면 제거
kubectl delete secret my-mysql-innodbcluster-ca-secret -n service
kubectl delete secret my-mysql-innodbcluster-tls-secret -n service
kubectl delete secret my-mysql-innodbcluster-router-tls-secret -n service
```
## <br/><br/>

## cluster router DNS로 인한 통신 문제
### helm에서 repo를 다운로드받아서 values.yaml을 열어보면 다음과 같이 나와 있는데 좀 더 설명하자면 이렇다.
- router.podSpec는 처음 Helm 설치 시에만 반영됩니다.
- 설치 이후에는 Helm upgrade든, InnoDBCluster CR 수정이든 변경해도 적용되지 않습니다.
- 이후에 이 값을 Helm 차트나 InnoDBCluster YAML에서 변경하더라도, 기존 Router Deployment가 다시 생성되지 않습니다.
- 즉, 변경사항이 실제 Kubernetes 리소스에 반영되지 않습니다.
- MySQL Operator는 router.podSpec의 변경을 감지(watch)하지 않기 때문에, 수정해도 Operator가 이를 보고 router를 재배포하지 않습니다.
### 따라서 별도로 설정하는 게 권장되는 방법이다. 다만 이렇게 하면 helm에서 관리하는 것에서 

```
#router:
#  instances: 1
#  options:
#  - option1: value1
#  - option2: value2
#  bootstrapOptions:
#  - bootstrapOption1: value1
#  - bootstrapOption2: value2
#  certAndPKsecretName:
#  #IMPORTANT: Once podSpec is set it is carved into stone. If changed, the router deployment won't be rebuilt. podSp
ec is
#  #           respected only when during the initial build of of the Innodbcluster and its Router Deployment. Later
changes
#  #           to the podSpec, in the Chart of directly in the IC CR/object won't be regarded, as the Operator doesn'
t watch
#  #           for changes of router.podSpec.
...
```
### <br/>

### router가 어떤 이름으로 떠 있는지 확인한다.
```
kubectl get deploy -n service
```
#### <img width="474" height="68" alt="image" src="https://github.com/user-attachments/assets/73b3c6e0-d710-47bb-8967-352f37732ac2" />
### <br/>

### 해당 deploy에 대한 yaml을 추출한다.
```
kubectl get deploy mycluster-router -n service -o yaml > mycluster-router.yaml
```
### <br/>

### 해당 yaml을 열어서 다음을 추가한다.
#### 참고로 service는 namespace 이름이다.
```
spec:
  template:
    spec:
      # 아래를 추가하면 됨
      dnsPolicy: None
      dnsConfig:
        searches:
          - service.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "1"
```
### <br/>

### 적용
#### --force를 붙이면 yaml이 다르더라도 강제로 적용한다. 경우에 따라 사용한다.
```
kubectl replace -f mycluster-router.yaml --force
```
### <br/>

### pod가 잘 떴는지 확인한다.
```
kubectl get all -n service
```
#### <img width="941" height="583" alt="image" src="https://github.com/user-attachments/assets/71eb8949-201d-4c28-a6db-4c18e1ebb5ba" />
### <br/><br/>


## mycluster-router 비밀번호 오류
### 이 경우 설치 설정 구성 중에 메타데이터가 깨졌을 때 발생하는데,  router의 계정이 없거나 password가 일치하지 않는다고 나온다.
```
$ kubectl logs pod/mycluster-router-7d889fdc79-q8tkz -n tgf
[Entrypoint] MYSQL_CREATE_ROUTER_USER is 0, Router will reuse mysqlrouter-HaNPixH6lS account at runtime
[Entrypoint] Succesfully contacted mysql server at mycluster-instances.tgf.svc.cluster.local:3306. Checking for cluster state.
[Entrypoint] Succesfully contacted mysql server at mycluster-instances.tgf.svc.cluster.local. Trying to bootstrap reusing account "mysqlrouter-HaNPixH6lS".
Please enter MySQL password for mysqlrouter-HaNPixH6lS:
Error: No result returned for v2_this_instance metadata query
```
### <br/>

### 클러스터 노드들이 정상인지 확인한다.
```
kubectl exec -it -n tgf mycluster-0 -c mysql -- mysql -uroot -p -e "SELECT MEMBER_ID,MEMBER_HOST,MEMBER_PORT,MEMBER_STATE,MEMBER_ROLE,MEMBER_VERSION FROM performance_schema.replication_group_members;"

# 또는 kubectl로 cluster node 들이 running 중인지 확인
kubectl get all -n tgf
```
#### <img width="948" height="233" alt="image" src="https://github.com/user-attachments/assets/61713239-d5d2-456a-9367-181d698ed066" />
### <br/>

### 등록된 secret 확인
#### 여기서 mycluster-cluster-secret을 사용할 거다.
```
kubectl get secret -n tgf | grep -i mycluster
```
#### <img width="612" height="100" alt="image" src="https://github.com/user-attachments/assets/5159ec1d-5cbe-42f4-bbce-c6ef82c14224" />
#### <br/>

### PW 변수 설정
```
PW="$(kubectl get secret -n tgf mycluster-cluster-secret -o jsonpath='{.data.rootPassword}' | base64 -d)"
```
#### <br/>

### router 계정이 에러로 인해 없을 수도 있으므로 생성하고, 비밀번호 재설정
```
# 1) Router 계정 생성
kubectl exec -it -n tgf mycluster-0 -c mysql -- env LC_ALL=C.UTF-8 mysqlsh root@localhost --password="$PW" --js -e "c=dba.getCluster(); c.setupRouterAccount('mysqlrouter',{password:'mysqlcluster'});"

# 2) K8s 시크릿에 주입(덮어쓰기)
kubectl -n tgf create secret generic mycluster-router --from-literal=MYSQL_PASSWORD='mysqlcluster' --dry-run=client -o yaml | kubectl apply -f -

# 3) Router 재시작
kubectl rollout restart deploy/mycluster-router -n tgf

# 4) Router 로그 확인
kubectl logs -n tgf deploy/mycluster-router --tail=200
```
### <br/>

### log 확인
#### <img width="942" height="71" alt="image" src="https://github.com/user-attachments/assets/58a29ffa-702f-41a5-a8f6-ee9b6c3152c0" />
#### <img width="945" height="198" alt="image" src="https://github.com/user-attachments/assets/81a33cbb-52c6-42bd-8ce2-ae220cac1e19" />
### <br/>

### router가 켜진 후 외부에서 접속 되는지 확인한다.
#### <img width="504" height="437" alt="image" src="https://github.com/user-attachments/assets/6034c202-a9f9-4384-a09f-f991eb76320a" />

### <br/><br/>

