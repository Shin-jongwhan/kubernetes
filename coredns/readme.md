### 250710
# CoreDNS
### 서비스 이름이나 파드 이름을 IP로 변환해주는 DNS 서버
### Service, Pod 이름 → IP로 자동 변환해주는 역할을 한다.
### 내부 DNS 쿼리를 처리하여 동적으로 IP를 감지하고 연결한다.
### DNS 이름 형태:
- my-service.my-namespace.svc.cluster.local
- my-pod.my-namespace.pod.cluster.local
