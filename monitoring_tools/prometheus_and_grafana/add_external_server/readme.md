### 250718
# 외부 서버 모니터링 추가하기
### 구조로 보면 이렇다.
```
[ 외부 리눅스 서버 1 ] ← node_exporter →  
                             ↑
[ 외부 리눅스 서버 2 ] ← node_exporter →  Prometheus  ← Grafana
                             ↑
             (모든 메트릭 수집 대상)
```
### <br/>

### external node 설정 방법
#### 여기서 설정에 2가지 방법이 있다.
- 정적으로 config에 한 번만 정의해서 그 서버를 모니터링에 추가할지
- extnertal_target.json 과 같은 파일에 모니터링 할 서버를 써서, 업데이트되면 같이 업데이트해서 동적으로 서버를 모니터링 할지
#### 이런 상황을 생각해보자.
- 어떤 서버가 더 이상 모니터링이 필요하지 않으면 삭제해야 하고, 다른 서버를 또 추가해야 하는 경우도 발생할 수 있는데 이걸 어떻게 해결할 수 있을까?
#### 이런 상황을 고려한다면 동적으로 삭제 / 추가할 수 있게 만드는 게 맞고 또한 정적으로 config에 반영하는 것보다 훨씬 좋은 선택이다.
#### 둘 다 시도를 해봤다. config 설정보다 extnertal_target.json으로 동적으로 설정하는 게 아주 약간 더 복잡하긴 하지만 가치는 충분히 있다.
### <br/>

### dynamic volume provisioner 설정
#### 먼저 나는 NFS provisioner 설정을 하였다. 각 node에서 NFS로 storage를 같이 사용할 수 있게 설정해줘야 한다.
#### * 반드시 dynamic volume을 사용해야 하는 건 아니다. hostPath로 이용해도 된다. 다만 다른 node에 pod가 띄워지지 않도록 label을 구성하여 해당 label을 가진 node에만 띄워지게 별도 설정이 필요하다. 
#### NFS provisioner 설정 내용 참고
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/volume/dynamic_volume_provisioning#nfs-%EB%8F%99%EC%A0%81-%ED%94%84%EB%A1%9C%EB%B9%84%EC%A0%80%EB%8B%9D-%EC%9D%B4%EC%9A%A9%ED%95%98%EA%B8%B0
### <br/>

### PVC 생성
#### * 참고 : dynamic volume을 사용하는 내용으로 구성하였다.
#### 설정이 끝나면 PVC를 생성하자.
#### prometheus-pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs     # NFS provisioner가 제공하는 StorageClass
  resources:
    requests:
      storage: 1Gi
```
#### <br/>

#### PVC 생성
```
kubectl apply -f prometheus-pvc.yaml
```
#### <br/>

#### PVC 확인
#### Dynamic Provisioning는 PVC가 생성되면, 연결된 StorageClass를 참고하여 Kubernetes가 PV를 자동 생성한다.
```
kubectl get pvc -n monitoring
```
#### <img width="937" height="71" alt="image" src="https://github.com/user-attachments/assets/1f1d85b7-f0fe-407c-8eed-3e23d30cc54c" />
#### <br/>

### extnertal target 파일 생성
#### 생성한 PVC 경로로 가서 extnertal_target.json을 생성하자.
#### extnertal_target.json
```json
[
  {
    "targets": ["xxx.xxx.xxx.xxx:9100"],
    "labels": {
      "env": "prod"
    }
  }
]
```
#### <img width="758" height="171" alt="image" src="https://github.com/user-attachments/assets/12dcb068-4d80-40c5-9285-b868558e4f23" />
### <br/>

### prometheus에 대한 설정을 재정의해서 helm으로 재설치해야 한다.
#### * 아래 주석처리는 config에 직접 설정하는 방법인데, 주석처리로 남겨두었다. 참고로 prometheus 버전에 따라 해당 설정에 에러가 있다. secret에 등록하는 방식으로도 해보고 configmap에 등록하는 방식으로도 해봤는데 뭔가 인식을 못 하는 에러가 있었으니 참고.
#### values.yaml
```yaml
prometheus:
  prometheusSpec:
    externalUrl: https://service.example.com/monitoring/prometheus
    routePrefix: /monitoring/prometheus
#    additionalScrapeConfigs:
#      name: prometheus-stack-kube-prom-prometheus-scrape-confg
#      key: additional-scrape-configs.yaml
    volumes:
      - name: external-targets
        persistentVolumeClaim:
          claimName: prometheus
    volumeMounts:
      - name: external-targets
        mountPath: /etc/prometheus/file_sd
```
### <br/>

### 재설치
```
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
```
### <br/>

### secret 생성
#### prometheus-additional-scrape-secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prometheus-stack-kube-prom-prometheus-scrape-config
  namespace: monitoring
stringData:
  additional-scrape-configs.yaml: |
    - job_name: "external-nodes"
      file_sd_configs:
        - files:
            - /etc/prometheus/file_sd/external_target.json
          refresh_interval: 30s

```
#### <br/>

### secret 적용
```
kubectl apply -f prometheus-additional-scrape-secret.yaml
```
### <br/>

### prometheus 패치
#### 적용하면 'prometheus.monitoring.coreos.com/prometheus-stack-kube-prom-prometheus patched' 이라는 메세지가 나옴
```
kubectl -n monitoring patch prometheus prometheus-stack-kube-prom-prometheus \
  --type='merge' \
  -p '{"spec":{"additionalScrapeConfigs":{"name":"prometheus-stack-kube-prom-prometheus-scrape-config","key":"additio
nal-scrape-configs.yaml"}}}'
```
### <br/>

### 적용 확인
```
kubectl -n monitoring get prometheus prometheus-stack-kube-prom-prometheus -o yaml | grep -A2 additionalScrapeConfigs
```
#### <img width="940" height="97" alt="image" src="https://github.com/user-attachments/assets/9dea06ea-6dd5-4b10-81a1-b32c08a2ed81" />
### <br/><br/>


### 브라우저에서 prometheus에 접속해보자.
#### status - target helth로 가서 external node가 등록된 걸 확인한다.
#### <img width="941" height="453" alt="image" src="https://github.com/user-attachments/assets/81e4ff9a-40c8-4491-b0db-f7bf92a02aec" />
### <br/>

### 다음으로 서버에서 쿼리를 날려보자.
#### 아래 쿼리는 서버가 모니터링 진행 중(up)인지 아닌지(down) 확인하는 쿼리이다.
#### -k는 https 인증 관련인데 필요 시 사용. 
```
curl -k https://service.example.com/monitoring/prometheus/api/v1/query?query=up | jq
```
#### <br/>

#### 아래처럼 up에 1이 되어 있으면 모니터링이 되고 있다는 것이다.
#### <img width="338" height="192" alt="image" src="https://github.com/user-attachments/assets/5941c9db-6fe1-432c-9fb5-8ab1883712c3" />
#### <br/>

### grafana dashboard 확인
#### 참고로 dashboard id 1860을 등록해야 한다. 아래 참고.
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/monitoring_tools/prometheus_and_grafana/grafana_dashboard
#### 이렇게 등록된 게 잘 보인다.
#### refresh를 눌러야 새롭게 반영된 서버가 보인다.
#### <img width="935" height="897" alt="image" src="https://github.com/user-attachments/assets/4985f8f4-2f3a-469a-ac71-7dc0253d9ba9" />
