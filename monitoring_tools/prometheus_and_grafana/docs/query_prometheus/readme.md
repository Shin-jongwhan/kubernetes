### 260225
# query prometheus 정리

### 스토리지 용량 조회
```
# --- 환경 변수 설정 ---
# 실제 운영 환경에 맞춰 URL과 IP를 변경
sPROM_URL="https://your-prometheus-service.com/api/v1/query"
sNODE_ADDR="0.0.0.0:9100"  # 대상 서버 IP 및 포트
sMOUNT_PATH="/qc01|/qc02"  # 조회할 마운트 경로 (OR 조건)

# --- 실행 명령어 ---
curl -s -k -G "$sPROM_URL" --data-urlencode "query={instance=\"$sNODE_ADDR\", mountpoint=~\"$sMOUNT_PATH\"}" | jq '.data.result | group_by(.metric.mountpoint) | .[] | 
  {
    mount: .[0].metric.mountpoint,
    total_tb: ( ( (.[0].metric.mountpoint as $m | .[] | select(.metric.__name__=="node_filesystem_size_bytes") | .value[1] | tonumber) / 1024 / 1024 / 1024 / 1024 * 100 | round) / 100 ),
    used_tb: ( ( ((.[0].metric.mountpoint as $m | .[] | select(.metric.__name__=="node_filesystem_size_bytes") | .value[1] | tonumber) - (.[0].metric.mountpoint as $m | .[] | select(.metric.__name__=="node_filesystem_avail_bytes") | .value[1] | tonumber)) / 1024 / 1024 / 1024 / 1024 * 100 | round) / 100 ),
    usage_percent: (100 - ((.[0].metric.mountpoint as $m | .[] | select(.metric.__name__=="node_filesystem_avail_bytes") | .value[1] | tonumber) / (.[0].metric.mountpoint as $m | .[] | select(.metric.__name__=="node_filesystem_size_bytes") | .value[1] | tonumber) * 100) | round)
  }'

```
### <br/><br/>

