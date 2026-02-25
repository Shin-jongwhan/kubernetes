### 260225
# node_exporter 쿼리
### 외부 서버에 서비스로 떠 있는 node_exporter에 쿼리를 하여 스토리지 부하를 조회하는 방법
```
# 스토리지 서버 node_exporter에 직접 쿼리하여 스토리지 부하 조회
# read, write 처리량만 조회
sTarget="qcstorage01.ptbio.kr:9100"
sDev="sda"

watch -n 1 "
  # 1. 원본 데이터 가져오기
  sMetrics=\$(curl -s http://$sTarget/metrics)

  # 2. 읽기/쓰기 바이트 값만 정밀하게 추출
  nRead=\$(echo \"\$sMetrics\" | grep \"node_disk_read_bytes_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nWrite=\$(echo \"\$sMetrics\" | grep \"node_disk_written_bytes_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')

  # 3. 파일에 임시 저장하여 이전 값과 비교 (계산 오차 방지)
  if [ -f /tmp/io_prev ]; then
    read pR pW < /tmp/io_prev
    # 현재 값에서 이전 값을 뺀 뒤 MB 단위로 변환
    nDiffR=\$(echo \"(\$nRead - \$pR) / 1024 / 1024\" | bc -l)
    nDiffW=\$(echo \"(\$nWrite - \$pW) / 1024 / 1024\" | bc -l)

    echo \"--- Storage I/O Real-time ($sDev) ---\"
    printf \"READ  : %10.2f MB/s\n\" \"\$nDiffR\"
    printf \"WRITE : %10.2f MB/s\n\" \"\$nDiffW\"
  else
    echo \"초기 데이터를 수집 중입니다... (1초만 기다려주세요)\"
  fi

  # 4. 현재 값을 다음 계산을 위해 저장
  echo \"\$nRead \$nWrite\" > /tmp/io_prev
"
```
### <br/>

```
# --- 변수 ---
sTARGET_HOST="your-storage-host.com:9100" # 스토리지 서버 주소
sDEV_NAME="sda"                           # 모니터링할 디스크 장치명

watch -n 1 "
  # 1. 원본 데이터 수집
  sRaw=\$(curl -s http://$sTARGET_HOST/metrics)
  
  # 2. 데이터 추출 (지수 표기법 방지를 위해 awk에서 정수로 강제 변환)
  nRB=\$(echo \"\$sRaw\" | grep \"node_disk_read_bytes_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nWB=\$(echo \"\$sRaw\" | grep \"node_disk_written_bytes_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nRO=\$(echo \"\$sRaw\" | grep \"node_disk_reads_completed_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nWO=\$(echo \"\$sRaw\" | grep \"node_disk_writes_completed_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nRT=\$(echo \"\$sRaw\" | grep \"node_disk_read_time_seconds_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.3f\", \$2}')
  nWT=\$(echo \"\$sRaw\" | grep \"node_disk_write_time_seconds_total{device=\\\"$sDEV_NAME\\\"}\" | awk '{printf \"%.3f\", \$2}')

  # 3. 이전 값과 비교 연산
  if [ -f /tmp/io_state_final ]; then
    read pRB pWB pRO pWO pRT pWT < /tmp/io_state_final
    
    # Throughput (MB/s)
    fTR=\$(echo \"scale=2; (\$nRB - \$pRB) / 1024 / 1024\" | bc -l)
    fTW=\$(echo \"scale=2; (\$nWB - \$pWB) / 1024 / 1024\" | bc -l)
    
    # IOPS (ops/s)
    nIR=\$(echo \"\$nRO - \$pRO\" | bc)
    nIW=\$(echo \"\$nWO - \$pWO\" | bc)
    
    # Latency (ms) - 분모가 0인 경우 처리
    if [ \$nIR -gt 0 ]; then fLR=\$(echo \"scale=2; (\$nRT - \$pRT) / \$nIR * 1000\" | bc -l); else fLR=0; fi
    if [ \$nIW -gt 0 ]; then fLW=\$(echo \"scale=2; (\$nWT - \$pWT) / \$nIW * 1000\" | bc -l); else fLW=0; fi

    # 결과 출력
    echo \"--- Storage Comprehensive I/O Status ($sDEV_NAME) ---\"
    printf \"%-10s | %-15s | %-12s | %-10s\n\" \"TYPE\" \"Throughput\" \"IOPS\" \"Latency\"
    printf \"%-10s | %10.2f MB/s | %8d ops | %8.2f ms\n\" \"READ\" \"\$fTR\" \"\$nIR\" \"\$fLR\"
    printf \"%-10s | %10.2f MB/s | %8d ops | %8.2f ms\n\" \"WRITE\" \"\$fTW\" \"\$nIW\" \"\$fLW\"
  else
    echo \"데이터 수집 중... (1초 뒤 결과가 출력됩니다)\"
  fi
  
  # 현재 값을 다음 계산을 위해 저장
  echo \"\$nRB \$nWB \$nRO \$nWO \$nRT \$nWT\" > /tmp/io_state_final
"

```
