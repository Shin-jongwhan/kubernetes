### 250715
# Data synchronication - Longhorn
### 여러 node 에 data sync 를 유지하고자 할 때 사용한다.
### 복제본이 있기 때문에 특정 node 에서 에러가 나더라도 복구할 수 있다.
### PVC를 자동 복제 + 복구를 제공하는 블록 스토리지 시스템이다.
- /data 아래에 Longhorn 전용 디렉토리 예: /data/longhorn
- 모든 노드에 동일하게 존재하면 OK (용량은 달라도 됨)
- Longhorn 설치 후 StorageClass 생성됨 (longhorn)
- PVC에서 StorageClass를 longhorn으로 지정만 하면 끝
### <br/>

### Longhorn의 복제 방식 개요
- Longhorn은 볼륨당 N개의 복제본(replica) 을 다른 노드에 분산해서 저장함 (기본값: 3개)
- 한 Pod가 PVC를 통해 해당 볼륨을 하나의 노드에 마운트 하면,
- 그 노드에 있는 엔진(engine) 이 I/O를 처리하고,
- 엔진은 동시에 다른 노드에 있는 replica들에게 블록 단위로 write를 전파함
#### ✅ Pod가 쓰는 데이터는 실시간으로 복제 노드에 반영됨
### <br/>

### 예시 시나리오
- /data/sync/important.db에 write 발생
- Longhorn 엔진이 해당 블록을 로컬 replica + 2개 remote replica에 전송
- 쓰기 성공 후만 write 성공으로 처리됨 → write-through 방식
#### 📌 Crash나 장애가 발생해도 replica가 있으므로 복구 가능
### <br/>

### ⚠️ Longhorn의 중요한 특성과 제한사항
### longhorn은 데이터를 동기화하는 거라서 각 node에서 같은 PV 를 사용할 수는 없다.
### 같은 경로와 같은 데이터지만 각 node 에 있는 데이터를 마운트하여 사용하는 것이다.
### 이렇게 말고 각 node에서 동일한 걸 사용하게 하려면 네트워크 스토리지를 이용해야 한다.
| 항목                                                               | 내용 |
| ---------------------------------------------------------------- | -- |
| Pod는 항상 하나의 노드에서만 해당 PVC를 마운트함 (ReadWriteOnce)                   |    |
| 다른 노드에서 동시에 해당 볼륨을 마운트할 수 없음                                     |    |
| 대신 해당 노드가 장애 나면, 다른 replica를 기반으로 다른 노드에서 자동 복구 가능               |    |
| 모든 replica가 동시에 마운트되는 게 아니라, **하나는 active, 나머지는 passive mirror** |    |

### <br/>
