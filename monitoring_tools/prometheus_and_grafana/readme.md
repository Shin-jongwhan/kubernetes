### 250718
# Server resource monitoring - prometheus + grafana
### 내가 설치할 것들의 목록인데, helm으로 설치하면 패키지로 같이 설치해준다.
### kubernetes에서만 사용하는 건 아니고, 서버 모니터링 툴이라서 그냥 로컬에서 설치해도 된다.
| 구성 요소                   | 설명                                       |
| ----------------------- | ---------------------------------------- |
| **Prometheus**          | 메트릭 수집 및 저장                              |
| **Grafana**             | 메트릭 시각화 대시보드                             |
| **Alertmanager**        | 경고(알림) 규칙 처리 및 슬랙/이메일 발송                 |
| **Node Exporter**       | 각 노드의 CPU, 메모리, 디스크 등의 메트릭 수집            |
| **Kube State Metrics**  | Kubernetes 리소스 상태 (Pod, Deployment 등) 수집 |
| **Prometheus Operator** | Prometheus CRD 기반 설치/운영 관리               |

### <br/>

### helm으로 설치하면 간단하다.
```
# repo 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# namespace 만들기
kubectl create namespace monitoring

# 설치
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```
### <br/>

### 관리자 초기 비번 출력
#### id : admin
#### pw : prom-operator
```
kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
# prom-operator 출력됨
```
### <br/>

### 이제 secret과 ingress를 설정해보자. 이거는 사용자의 설정에 따라 자유롭게 한다.
#### 1. secret 생성
```
ubectl create secret tls [secret_name] --cert=xxx.crt --key=xxx.key -n monitoring
```
#### <br/>

#### 2. ingress 설정
#### 먼저 ingress nginx가 세팅이 되어 있어야 한다.
#### 아래 참고
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/ingress/ingress_nginx
#### 나는 하나의 도메인에서 prefix로 구분하여 접속하게끔 만들었다. 아예 도메인을 새로 파도 된다. 내 세팅의 yaml 예시이다.
##### grafana-ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: example-namespace
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: example-service.example.com
      http:
        paths:
          - path: /monitoring/grafana(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: prometheus-stack-grafana
                port:
                  number: 3000
  tls:
    - hosts:
        - example-service.example.com
      secretName: example-tls

```
#### 이후 적용
```
kubectl apply -f grafana-ingress.yaml
```
#### <br/>

#### 3. deployment, service 설정 변경
#### 도메인 주소 + prefix이기 때문에 이 설정으로 하고, 내부망 접속 허용을 위해 nodeport로 변경한다.
##### grafana-pod.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-stack-grafana
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: grafana
    app.kubernetes.io/instance: prometheus-stack
  ports:
    - name: http
      protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30162
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-stack-grafana
  namespace: monitoring
spec:
  template:
    spec:
      containers:
        - name: grafana
          env:
            - name: GF_SERVER_ROOT_URL
              value: "%(protocol)s://%(domain)s/monitoring/grafana"

```
#### 설정 변경 적용
```
kubectl apply -f grafana-pod.yaml
```
### <br/>

### 이제 세팅은 끝났고 접속해보자.
#### <img width="741" height="747" alt="image" src="https://github.com/user-attachments/assets/8a6eaee7-ea24-4fd5-b683-64c0860a2a59" />
### <br/>

### 접속하면 이게 기본 화면이다.
#### <img width="1909" height="938" alt="image" src="https://github.com/user-attachments/assets/3d691e46-4c73-4925-9b0a-5bb099f13352" />
### <br/>

### 이제 여기서 dashboard를 커스터마이징할 수 있는데, 아래 페이지를 참고하자. 다른 template들도 많다.
#### https://grafana.com/solutions/kubernetes/?pg=dashboards&plcmt=featured-dashboard-1
