### 250710
# CoreDNS
### pod 간 통신에 꽤 중요하다. 이걸 이해하지 않으면 왜 네트워킹이 안 되는지 파악하기 어려우니 DNS가 뭔지 일단 공부하자. 자세한 내용은 아래 링크 참고.
#### https://github.com/Shin-jongwhan/network/tree/main/DNS
### 서비스 이름이나 파드 이름을 IP로 변환해주는 DNS 서버
### Service, Pod 이름 → IP로 자동 변환해주는 역할을 한다.
### 내부 DNS 쿼리를 처리하여 동적으로 IP를 감지하고 연결한다.
### <br/>

### DNS 이름은 5개의 '.'으로 나뉘어져 있어 kubernetes 기본 ndots (DNS 검색 설정)은 5개이다.
- ndots : 몇 개 이상의 점(.)이 있으면 FQDN으로 간주할지 설정 (기본값: ndots:5)
### DNS 이름 형태:
#### 기본적으로 DNS 이름은 .으로 5개 나뉘고, cluster.local이 기본 서픽스이다.
```
<서비스명>.<네임스페이스>.svc.cluster.local
```
#### <br/>

#### 예시
- my-service.my-namespace.svc.cluster.local
- my-pod.my-namespace.pod.cluster.local
#### <br/>

### 각 구성요소 설명
| 구분             | 의미                      |
| -------------- | ----------------------- |
| `my-service`   | 서비스 이름                  |
| `my-namespace` | 네임스페이스                  |
| `svc`          | 서비스 종류 (`svc`: Service) |
| `cluster`      | 클러스터 도메인                |
| `local`        | 최상위 도메인                 |
