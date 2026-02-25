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
# qcstorage01의 sda 장치 종합 I/O 모니터링
# Throughput (처리량)	IOPS (초당 작업수)	Latency (응답시간)
sTarget="qcstorage01.ptbio.kr:9100"
sDev="sda"

watch -n 1 "
  # 1. 원본 데이터 수집
  sMetrics=\$(curl -s http://$sTarget/metrics)
  
  # 2. 각 지표별 데이터 추출 (읽기/쓰기 합산)
  nReadBytes=\$(echo \"\$sMetrics\" | grep \"node_disk_read_bytes_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nWriteBytes=\$(echo \"\$sMetrics\" | grep \"node_disk_written_bytes_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')
  
  nReadOps=\$(echo \"\$sMetrics\" | grep \"node_disk_reads_completed_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')
  nWriteOps=\$(echo \"\$sMetrics\" | grep \"node_disk_writes_completed_total{device=\\\"$sDev\\\"}\" | awk '{printf \"%.0f\", \$2}')
  
  nReadTime=\$(echo \"\$sMetrics\" | grep \"node_disk_read_time_seconds_total{device=\\\"$sDev\\\"}\" | awk '{print \$2}')
  nWriteTime=\$(echo \"\$sMetrics\" | grep \"node_disk_write_time_seconds_total{device=\\\"$sDev\\\"}\" | awk '{print \$2}')

  # 3. 이전 데이터와 비교 및 계산
  if [ -f /tmp/io_full_state ]; then
    read pRB pWB pRO pWO pRT pWT < /tmp/io_full_state
    
    # 처리량 (Throughput - MB/s)
    fThruR=\$(echo \"(\$nReadBytes - \$pRB) / 1024 / 1024\" | bc -l)
    fThruW=\$(echo \"(\$nWriteBytes - \$pWB) / 1024 / 1024\" | bc -l)
    
    # IOPS (Ops/s)
    nIopsR=\$(echo \"\$nReadOps - \$pRO\" | bc)
    nIopsW=\$(echo \"\$nWriteOps - \$pWO\" | bc)
    
    # 지연 시간 (Latency - ms) : (시간 변화량 / 작업수 변화량) * 1000
    if [ \$nIopsR -gt 0 ]; then fLatR=\$(echo \"(\$nReadTime - \$pRT) / \$nIopsR * 1000\" | bc -l); else fLatR=0; fi
    if [ \$nIopsW -gt 0 ]; then fLatW=\$(echo \"(\$nWriteTime - \$pWT) / \$nIopsW * 1000\" | bc -l); else fLatW=0; fi

    echo \"--- Storage Comprehensive I/O ($sDev) ---\"
    printf \"%-12s | %-15s | %-12s | %-12s\n\" \"TYPE\" \"Throughput\" \"IOPS\" \"Latency\"
    printf \"%-12s | %10.2f MB/s | %8d ops | %8.2f ms\n\" \"READ\" \"\$fThruR\" \"\$nIopsR\" \"\$fLatR\"
    printf \"%-12s | %10.2f MB/s | %8d ops | %8.2f ms\n\" \"WRITE\" \"\$fThruW\" \"\$nIopsW\" \"\$fLatW\"
  else
    echo \"데이터를 수집 중입니다... (1초 대기)\"
  fi
  
  # 4. 현재 상태 저장
  echo \"\$nReadBytes \$nWriteBytes \$nReadOps \$nWriteOps \$nReadTime \$nWriteTime\" > /tmp/io_full_state
"

```
