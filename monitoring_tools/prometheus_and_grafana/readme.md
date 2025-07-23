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
    - host: service.example.com
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
        - service.example.com
      secretName: example-tls

```
#### 이후 적용
```
kubectl apply -f grafana-ingress.yaml
```
#### <br/>

#### 3. deployment, service 설정 변경
#### 도메인 주소 + prefix이기 때문에 이 설정으로 한다. 내부망 접속이고 ingress로 접속 주소에 의해 포트포워딩이 된다.
#### 그래서 내부망 접속 허용을 위해 clusterip를 nodeport로 변경할 필요는 없다.
##### grafana-pod.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-stack-grafana
  namespace: monitoring
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: grafana
    app.kubernetes.io/instance: prometheus-stack
  ports:
    - name: http
      protocol: TCP
      port: 3000
      targetPort: 3000
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

### CLUSTER-IP 설정 확인
```
kubectl -n monitoring get svc prometheus-stack-grafana
```
#### <img width="761" height="35" alt="image" src="https://github.com/user-attachments/assets/a5199e94-14c3-498e-8bd8-b34c3b159e97" />
### <br/>

### 이제 세팅은 끝났고 접속해보자.
#### <img width="741" height="747" alt="image" src="https://github.com/user-attachments/assets/8a6eaee7-ea24-4fd5-b683-64c0860a2a59" />
### <br/>

### 접속하면 이게 기본 화면이다.
#### <img width="1909" height="938" alt="image" src="https://github.com/user-attachments/assets/3d691e46-4c73-4925-9b0a-5bb099f13352" />
### <br/><br/>

## 추가 설정 및 기능 구경하기
### 이제 여기서 dashboard를 커스터마이징할 수 있는데, 아래 페이지를 참고하자. 다른 template들도 많다.
#### https://grafana.com/solutions/kubernetes/?pg=dashboards&plcmt=featured-dashboard-1
#### <br/>

### 이런 웹페이지가 있는데, 여기서 ID를 복사하거나 json을 다운로드 받아서 등록할 수도 있다.
#### <img width="1569" height="916" alt="image" src="https://github.com/user-attachments/assets/f3a931c8-da41-4317-8482-ecb1329db4bd" />
### <br/>

### connection - data source에 가보자. prometheus 등과 잘 연결이 되었는지 확인해보자.
#### <img width="1898" height="535" alt="image" src="https://github.com/user-attachments/assets/cec2a4cb-dd5d-47ba-a7a8-265f5b5fd9b9" />
### <br/>

### 이메일로 알람 설정하는 기능
#### <img width="1902" height="605" alt="image" src="https://github.com/user-attachments/assets/76aa1fbc-2140-44bb-bf13-76924d2ffc19" />
### <br/>

### dashboard 탭에 가면 아래에 리스트가 나오는데 클릭하면 각 항목에 대한 모니터링 대시보드를 확인할 수 있다.
#### <img width="1895" height="932" alt="image" src="https://github.com/user-attachments/assets/ee618dae-4b17-404e-b7fd-5700999e15c7" />
#### <br/>

### 이게 내가 필요한 항목이었는데 이렇게 조회할 수 있다. kubernetes로 연결된 node들을 모두 조회할 수 있다.
#### <img width="1606" height="934" alt="image" src="https://github.com/user-attachments/assets/e8dda711-8bb3-4323-bc61-881108bd3b64" />

### <br/><br/>


## Prometheus 설정
### prometheus도 url prefix 설정하기
### 먼저 grafana와 같이 ingress를 설정해준다.
#### 참고 1 : 여기서는 rewrite-target가 없어야 한다. 이건 app 마다 다르기 때문에 하나씩 테스트해봐야 함.
#### 참고 2 : 여기서는 nodeport가 필요하지 않다.
#### prometheus-ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    #nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: service.example.com
      http:
        paths:
          - path: /monitoring/prometheus(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: prometheus-stack-kube-prom-prometheus
                port:
                  number: 9090
  tls:
    - hosts:
        - service.example.com
      secretName: service-tls
```
### <br/>

### prometheus config 설정
### 아래와 같이 접속 주소에 prefix를 붙여줄 수 있다.
#### current-values.yaml
```yaml
prometheus:
  prometheusSpec:
    externalUrl: https://service.example.com/monitoring/prometheus
    routePrefix: /monitoring/prometheus
```
### <br/>

### 적용 
#### 10초 정도 아주 약간 적용에 시간이 걸림
```
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f current-values.yaml
kubectl -n monitoring rollout restart statefulset prometheus-prometheus-stack-kube-prom-prometheus
```
### <br/>

### 적용 확인
```
kubectl -n monitoring get pod -l app.kubernetes.io/name=prometheus   -o jsonpath="{.items[0].spec.containers[0].args}"
```
#### <br/>

### 출력
#### 아래 보면 --web.external-url에 등록이 된 걸 확인할 수 있다.
```
["--config.file=/etc/prometheus/config_out/prometheus.env.yaml","--web.enable-lifecycle","--web.external-url=https://service.example.com/monitoring/prometheus","--web.route-prefix=/monitoring/prometheus","--storage.tsdb.retention.time=10d","--storage.tsdb.path=/prometheus","--storage.tsdb.wal-compression","--web.config.file=/etc/prometheus/web_config/web-config.yaml"]
```
### <br/>

### 웹으로 접속해보자. /monitoring/prometheus url prefix를 입력하면 자동으로 /monitoring/prometheus/query로 넘어간다.
#### <img width="947" height="480" alt="image" src="https://github.com/user-attachments/assets/9cd37f4b-58f6-42c0-9a7f-bbbe48935ccb" />
### <br/>

### 그리고 grafana에서도 prometheus 연동이 잘 되는지 test를 꼭 해보자. 
#### <img width="1902" height="939" alt="image" src="https://github.com/user-attachments/assets/96ad365d-3b51-40f2-86ef-c5679e73d731" />
### <br/>

### prometheus에 가서 status - target health로 가보자.
### 만약 포트 10257 (kube-controller-manager)가 빨간 불이라면 아래 링크에서 kube-controller-manager.yaml 설정에 대한 수정 내용을 확인하자.
#### https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/readme.md#kube-controller-manageryaml-%EC%88%98%EC%A0%95
#### <img width="918" height="240" alt="image" src="https://github.com/user-attachments/assets/cb104343-47fd-42ae-a259-504af5c354a0" />
### <br/>

### 2381 포트(etcd)가 빨간 불이라면 아래 링크에서 etcd.yaml 수정 관련 내용 확인
#### https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/readme.md#etcdyaml
#### 수정 전
#### <img width="902" height="49" alt="image" src="https://github.com/user-attachments/assets/95e2f92a-e6b7-4a3c-974b-47e46526f2ce" />
#### 수정 후
#### <img width="899" height="53" alt="image" src="https://github.com/user-attachments/assets/9127897a-eace-4635-a2ed-ac8edb7cc159" />
### <br/>

### 10249 포트(kube-proxy)가 빨간 불이라면 아래 링크에서 확인
#### https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/readme.md#kube-proxy---configmap-%EC%88%98%EC%A0%95
#### 정상 확인
#### <img width="915" height="66" alt="image" src="https://github.com/user-attachments/assets/a0d2cc7d-14de-4a70-9dc2-3753a01c2b8c" />
### <br/>

### 포트 10259 (kube-scheduler)가 빨간 불이라면 아래 링크에서 확인
#### https://github.com/Shin-jongwhan/kubernetes/blob/main/installation/readme.md#kube-scheduleryaml-%EC%88%98%EC%A0%95
#### 정상 확인
#### <img width="924" height="68" alt="image" src="https://github.com/user-attachments/assets/5dff052c-4446-4caf-bba3-9f040bc1eda5" />
### <br/>

