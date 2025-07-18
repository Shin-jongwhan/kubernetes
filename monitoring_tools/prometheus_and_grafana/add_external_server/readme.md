### 250718
# 외부 서버 모니터링 추가하기
### 나중에 정리 예정
### 구조로 보면 이렇다.
```
[ 외부 리눅스 서버 1 ] ← node_exporter →  
                             ↑
[ 외부 리눅스 서버 2 ] ← node_exporter →  Prometheus  ← Grafana
                             ↑
             (모든 메트릭 수집 대상)
```
