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

### 만약 특정 node에만 설치하고자 한다면 label을 붙여야 하는데, 다음을 참고하자.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/node_label
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/create_pod
#### <br/>

#### dashboard-values.yaml 예시
#### dashboard: "true" 라는 label이 붙은 곳에만 dashboard pod가 생성될 수 있게 한다.
```
nodeSelector:
  dashboard: "true"
```
#### <br/>

#### yaml 명시하여 설치
```
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard --create-namespace \
  -f dashboard-values.yaml
```
### <br/>

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
### <br/><br/>

## ingress nginx
### ingress nginx 세팅은 아래 링크를 참고하자.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/ingress/ingress_nginx
### <br/>

### TLS secret 설정
- dashboard-tls : secret tls name. 나중에 이걸 사용해서 등록한다.
- -n ubernetes-dashboard : pod_name
- --cert, --key : 도메인 발급 시 받은 cert, key 파일. 미리 다운로드 해놓는다.
```
kubectl create secret tls dashboard-tls --cert=/data/cert/ssl/xxx.crt --key=/data/cert/ssl/xxx.key -n kubernetes-dashboard
```
### <br/>

### yaml 작성
### 아래는 https://service.example.com/kubernetes/dashboard 로 접속이 가능하게 하는 설정이다.
#### dashboard-ingress.yaml
- name: Ingress 리소스의 이름.
- namespace: 이 리소스가 속한 네임스페이스. kubernetes-dashboard 네임스페이스에 생성됨.
- nginx.ingress.kubernetes.io/backend-protocol : HTTPS로 통신함을 명시한다.
- secretName : 여기에 위에서 만든 name이 들어간다.
- nginx.ingress.kubernetes.io/rewrite-target: "/$2"
  - 요청 경로를 리라이트하여 백엔드에 전달함.
  - 예: 클라이언트가 /kubernetes/dashboard/foo로 요청 → 백엔드에는 /foo로 전달됨.
  - 여기서 정규표현식의 두 번째 캡처 그룹 (/|$)(.\*)에서 $2가 두 번째 (.\*)에 해당.
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/rewrite-target: "/$2"
spec:
  ingressClassName: nginx
  rules:
    - host: service.example.com
      http:
        paths:
          - path: /kubernetes/dashboard(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: kubernetes-dashboard-kong-proxy
                port:
                  number: 443
  tls:
    - hosts:
        - service.example.com
      secretName: dashboard-tls
```
### <br/>

### rewrite가 필요한 이유 
### 아래 yaml에 있는 항목에 대해 좀 더 알아보자.
```
nginx.ingress.kubernetes.io/rewrite-target: "/$2"
```
#### <br/>

### 접속할 때는 이렇게 접속할 것이다.
### 그런데 backend에서는 실제로 kubernetes/dashboard/foo 라는 주소는 없고, /foo 라는 주소만이 있다.
### 따라서 kubernetes/dashboard/foo -> /foo로 변경해주어야 한다. rewrite가 이 기능을 담당한다.
```
https://service.example.com/kubernetes/dashboard/foo
```
### <br/>

### 모든 설정이 완료되었다. 이제 해당 yaml을 apply 한다.
```
kubectl apply -f dashboard-ingress.yaml
```
### <br/>

### 등록 확인
### 아래와 같이 입력하면 확인은 가능한데 요약 정보만 나타난다. 
```
kubectl -n kubernetes-dashboard get ingress
```
#### <br/>

#### 출력 예시
```
NAME                CLASS   HOSTS                         ADDRESS   PORTS     AGE
dashboard-ingress   nginx   service.example.com             80, 443   17h
```
### <br/>

### 위에서 CLASS가 nginx로 되어 있는데 이건 ingress nginx를 등록한 것이 사용되는 것이다. 
### 아래에서 NAME이 사용된다.
```
kubectl get ingressclass
```
#### ![image](https://github.com/user-attachments/assets/51ffb7dd-11a8-4737-af05-795b5bb4d5c4)
### <br/>

### 상세 정보 확인
### ingress에 대한 상세한 정보를 확인하려면 아래와 같이 확인한다.
```
kubectl -n kubernetes-dashboard describe ingress dashboard-ingress
```
#### <br/>

#### 출력 예시
```
Name:             dashboard-ingress
Labels:           <none>
Namespace:        kubernetes-dashboard
Address:
Ingress Class:    nginx
Default backend:  <default>
TLS:
  dashboard-tls terminates service.example.com
Rules:
  Host                         Path  Backends
  ----                         ----  --------
  service.example.com
                               /kubernetes/dashboard(/|$)(.*)   kubernetes-dashboard-kong-proxy:443 (xxx.xxx.xxx.xxx:8443)
Annotations:                   nginx.ingress.kubernetes.io/backend-protocol: HTTPS
                               nginx.ingress.kubernetes.io/rewrite-target: /$2
Events:                        <none>
```
### <br/>

### 이제 도메인 주소로 접속해보자. 
#### ![image](https://github.com/user-attachments/assets/b705bd4d-63f3-4e67-9aef-f248a1b5b161)
### <br/><br/>

## troubleshooting - 도메인 주소를 못 찾는 경우
### 도메인 인식이 안 되는 경우가 있을 것이다.
### 이때는 도메인 주소에 A record가 등록이 되었는지 확인해야 한다. 그래야 DNS 서버에서 해당 IP 주소로 찾아서 전파할 수 있다.
### 도메인 설정 관련은 아래 링크를 참고
#### https://github.com/Shin-jongwhan/network/tree/main/publish_domain_and_ssl_cert#domain-%EA%B5%AC%EC%9E%85-%EB%B0%8F-record-%EC%84%A4%EC%A0%95
### <br/>

### 먼저 local에서 ping을 찍어보자.
#### 그러면 ping 출력에 local ip가 제대로 찍혀서 나온다.
```
ping service.example.com
```
### <br/>

### 그리고 다른 내부망 서버에서 똑같이 ping을 찍어보면 다른 ip 주소가 나올 것이다. 이거는 도메인 해석을 잘못했기 때문이다.
### 도메인 구매 사이트에 가서 A record에 내부망이라면 내부망 ip 주소로 추가하고, service.example.com으로 추가하면 된다.
#### 다른 내부망 출력 결과
```
64 bytes from 8.81.148.146.bc.googleusercontent.com (146.148.81.8): icmp_seq=1 ttl=56 time=176 ms
```
### <br/><br/>

## troubleshooting - pod 등이 안 보일 경우
### 1. 권한을 체크한다. 대부분 권한 문제이다. 
### <br/>

### 2. 상단에 namespace를 모든 네임스페이스로 봐야 전체 실행에 대한 걸 볼 수 있다.
#### <img width="1897" height="900" alt="image" src="https://github.com/user-attachments/assets/b4a428bd-d6a1-44c5-8cc1-2118fac96795" />
### <br/>

### 3. log를 확인한다.
```
kubectl -n kubernetes-dashboard logs deployment/kubernetes-dashboard-api
```
### <br/>

### 4. pod가 잘 실행 중인지 확인한다. 만약 running 상태가 아니면 rollout restart를 해본다.
```
kubectl -n kubernetes-dashboard get pods
kubectl -n kubernetes-dashboard rollout restart deployment kubernetes-dashboard-api
```
#### <img width="727" height="102" alt="image" src="https://github.com/user-attachments/assets/77096e6b-b03f-4505-9dd4-3ecb21c9276f" />
### <br/>


### <br/><br/>

