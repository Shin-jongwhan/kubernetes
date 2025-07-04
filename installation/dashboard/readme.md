### 250703
# Kubernetes dashboard
### 아래 공식 docs 참고하자.
#### https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
### <br/>

### kubectl로 설치하는 방법이 있고, helm으로 설치하는 방법이 있는데 공식 docs에서 helm을 사용하니 이걸로 하자.
### 차이는 아래와 같다.
| 항목     | `kubectl apply`    | `helm install/upgrade`            |
| ------ | ------------------ | --------------------------------- |
| 방식     | **정적인 YAML** 파일 배포 | **템플릿 기반** 리소스 생성                 |
| 목적     | 빠르게 리소스 생성/수정      | 설치/버전 관리/설정값 자동화                  |
| 사용 편의성 | 간단함                | 유연하고 확장성 좋음                       |
| 상태 관리  | 수동                 | Helm이 릴리즈 상태를 추적                  |
| 업그레이드  | YAML 수정 후 apply    | `helm upgrade`로 가능                |
| 롤백     | ❌ 직접 수동 처리         | ✅ `helm rollback` 가능              |
| 설정 변경  | YAML 직접 수정         | `--set`, `values.yaml` 등 동적 설정 가능 |
| 설치 기록  | 없음                 | 릴리즈 이력 관리함 (`helm history`)       |
### <br/>

### 혹시 kubectl로 설치했다면 아래 명령어와 같이 제거하자.
```
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```
### <br/><br/>

## helm
### Kubernetes의 패키지 관리자이다. 아래 명령어로 하면 자동으로 helm을 설치한다.
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
#### ![image](https://github.com/user-attachments/assets/b5b10ee6-23f0-4fca-af9a-b010bdb2a710)
### <br/>

### 이제 공식 docs에 나와 있는 걸로 설치해보자.
```
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```
#### <br/>

### 설치 로그
```
"kubernetes-dashboard" already exists with the same configuration, skipping
Release "kubernetes-dashboard" does not exist. Installing it now.
NAME: kubernetes-dashboard
LAST DEPLOYED: Thu Jul  3 09:18:08 2025
NAMESPACE: kubernetes-dashboard
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
*************************************************************************************************
*** PLEASE BE PATIENT: Kubernetes Dashboard may need a few minutes to get up and become ready ***
*************************************************************************************************

Congratulations! You have just installed Kubernetes Dashboard in your cluster.

To access Dashboard run:
  kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

NOTE: In case port-forward command does not work, make sure that kong service name is correct.
      Check the services in Kubernetes Dashboard namespace using:
        kubectl -n kubernetes-dashboard get svc

Dashboard will be available at:
  https://localhost:8443
```
### <br/>

### 위 로그에 나와 있지만, 아래 명령어를 사용하면 웹으로 확인할 수 있게 포트포워딩하여 만들어준다.
```
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```
### <br/>

### kubectl port-forward는 내부적으로 **socat**이라는 유틸리티를 사용해 포트를 연결한다. 
### 만약 로컬 머신에 설치되어 있지 않으면 포워딩이 실패하기 때문에 설치해준다.
```
sudo apt update
sudo apt install socat
```
### <br/>

### 그러면 https://localhost:8443에서 확인할 수 있다.
### 또는 curl로 확인한다.
```
curl -k https://localhost:8443
```
#### ![image](https://github.com/user-attachments/assets/51c5ed9c-7dbb-4d6f-bf48-00096eb8dbaa)
### <br/>

### 알아둘점, NodePort 포트 (Service nodePort)
### kubernetes는 외부와 통신 가능한 포트 range는 다음과 같다.
- 기본 범위: 30000–32767
### 만약 해당 포트들이 안 열려있으면 같은 대역 IP가 아니면 외부에서 접속이 불가능할 것이다.
#### <br/>

### 외부에 접속 가능하게 설정
- type: ClusterIP → NodePort로 변경
- nodePort: 30163으로 고정
```
kubectl patch svc kubernetes-dashboard-kong-proxy \
  -n kubernetes-dashboard \
  -p '{
    "spec": {
      "type": "NodePort",
      "ports": [{
        "port": 443,
        "targetPort": 443,
        "protocol": "TCP",
        "nodePort": 30163
      }]
    }
  }'
```
### <br/>

### 접속 확인
#### 여기서 ip는 
```
https://[ip]:30163
```
#### ![image](https://github.com/user-attachments/assets/11634efd-adb5-449d-bbe3-0c820a5bd954)
### <br/>

### bearer token 발급을 해야 접속할 수 있다.
```
# admin-user 생성
kubectl create serviceaccount admin-user -n kubernetes-dashboard

# ClusterRoleBinding 생성
# 이 권한을 주면 Dashboard에서 전체 클러스터를 볼 수 있다. (테스트/관리용 권한)
kubectl create clusterrolebinding admin-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:admin-user

# Bearer Token 발급
kubectl -n kubernetes-dashboard create token admin-user
```
### <br/>

### 대시보드에 접속하면 이렇게 보인다.
#### ![image](https://github.com/user-attachments/assets/1f57949c-1845-4322-a179-777189f3dd67)
### <br/>

### 여기서 node 접속에 대해 몇 가지 주의 사항이 있다.
- 보통은 external-ip로 접속을 시도한다.
- 만약 external-ip로 접속이 안 되면 internal-ip로 접속하면 되는데, 이 경우 외부에서는 접속이 안 되므로 NAT 설정이 되어 있어야 한다.
- 사용하는 모든 node의 port (ex) 여기서는 30163)는 개방되어야 한다.
- 아래 명령어를 실행하는 곳의 서버에서만 포트를 개방하면 접속할 수 있다. 이건 테스트 명령어이고 kubernetes에서 서비스화를 한 건 아니다.
  ```
  kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
  ```
- 서비스화 해서 프록시를 하려면 nginx가 추가적으로 필요하다. 그런데 이 경우도 모든 node에서 포트 개방이 필요하다.<br/>
  하지만 알아두어야 할 건, 서비스화 한다는 건 node를 지정할 수 있다는 거고, 해당 node에만 포트를 개방하면 된다는 거다. 즉, 모든 node에서 포트 개방이 필요 없다.
### <br/>

### 그럼 이제 다음 단계는 nginx 설정이다.
