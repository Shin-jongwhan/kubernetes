### 250729
# StatefulSet
### Kubernetes의 StatefulSet은 '상태'를 가지는 애플리케이션을 Kubernetes에서 안정적으로 배포하고 관리하기 위한 워크로드 API 객체
### 특히 고정된 네트워크 ID, 저장소, 순차적 배포 및 종료 순서가 중요한 경우에 사용된다.
### <br/>

### StatefulSet이 필요한 이유
#### Deployment나 ReplicaSet은 stateless(무상태) 애플리케이션을 위한 것으로 Pod를 식별할 수 없고 재시작하거나 재배포되면 이름이나 IP가 바뀔 수 있다.
#### 하지만 아래와 같은 stateful app에서는 문제가 된다.
- MySQL, MongoDB, Redis 등의 데이터베이스 클러스터
- Kafka, RabbitMQ 등의 메시지 큐 시스템
- ZooKeeper, Elasticsearch 등 분산 시스템
### <br/>

### StatefulSet의 주요 특징
| 항목                | 설명                                                  |
| ----------------- | --------------------------------------------------- |
| **고정된 Pod 이름**    | `pod-0`, `pod-1`, … 처럼 이름이 유지됨                      |
| **고정된 스토리지**      | 각 Pod는 자신만의 PersistentVolume을 가짐                    |
| **순차적 배포 및 종료**   | `pod-0`부터 순서대로 생성 및 종료됨                             |
| **재시작 순서 보장**     | 실패한 Pod는 같은 이름과 같은 스토리지로 재생성됨                       |
| **Stable DNS 제공** | `pod-0.service-name.namespace.svc.cluster.local` 형식 |

### <br/>

### Headless Service 필요
#### StatefulSet은 반드시 아래와 같이 Headless Service와 함께 사용해야 한다.
#### 주로 StatefulSet과 함께 사용되며, 각 Pod의 고유한 DNS 주소가 필요할 때 사용한다.
#### 📌 예: MySQL 클러스터, Kafka, Zookeeper, Elasticsearch, MongoDB 등
- 이런 시스템에서는 각 노드(Pod)가 자신만의 ID, 저장소, 네트워크 주소를 가져야 하며, 클러스터 내부에서 서로를 직접 참조해야 한다.
#### <br/>

### Headless Service란? 
#### DNS 이름만 제공하고, 로드밸런싱을 하지 않는 Service 이다. 일반적인 ClusterIP Service와는 동작 방식이 다르다.
#### spec.clusterIP: None으로 설정된 Kubernetes Service
- Cluster IP를 생성하지 않음
- DNS 조회 시 여러 Pod의 개별 IP를 반환함
- 클라이언트가 직접 Pod에 접근하거나, Pod의 개별 이름을 알 수 있도록 DNS에 노출
#### <br/>

### 일반 Service vs Headless Service
| 항목         | 일반 ClusterIP Service | Headless Service (`clusterIP: None`) |
| ---------- | -------------------- | ------------------------------------ |
| Cluster IP | 존재함                  | 없음                                   |
| DNS 결과     | 하나의 가상 IP            | 여러 개의 Pod IP                         |
| 로드밸런싱      | 있음                   | 없음 (클라이언트가 직접 선택)                    |
| 예시         | 프론트엔드 웹서버, REST API  | StatefulSet (DB, Kafka, etc)         |
### <br/>

### headless service yaml 예시
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-db
  labels:
    app: my-db
spec:
  clusterIP: None  # 👉 Headless 설정
  selector:
    app: my-db
  ports:
    - port: 3306
      name: mysql
```
#### <br/>

### 서비스 조회 시 이렇게 여러 pod를 반환한다.
```
$ nslookup my-db.default.svc.cluster.local
-> my-db-0.my-db.default.svc.cluster.local
-> my-db-1.my-db.default.svc.cluster.local
-> ...
```
### <br/>

### headless service DNS 접근 이후 처리
#### Headless Service의 DNS로 접속하면, 여러 개의 Pod IP가 반환되며, 실제 접속 대상은 클라이언트가 선택한다.
- Headless Service는 **로드밸런서를 제공하지 않습니다.**
- my-app.default.svc.cluster.local로 접속하면 여러 Pod의 IP 목록을 DNS가 반환합니다.
- 이후 어디로 접속할지는 클라이언트(또는 OS의 DNS Resolver)가 선택합니다.
#### <br/>

#### ❓ 그럼 curl my-app.default.svc.cluster.local은 어디로 갈까?
- → 이건 운영체제 DNS Resolver의 정책이나 애플리케이션 로직에 따라 다르다.
- 일반적인 DNS 클라이언트는 반환된 여러 IP 중 첫 번째 또는 랜덤한 IP 하나를 사용한다.
- curl, wget, Python socket, Java HttpClient 등은 보통 자동으로 하나만 선택해서 접속한다.
- 즉, **"랜덤하게 한 Pod에 접속하는 것처럼 동작"** 하지만, 정해진 로드밸런싱은 없다.

| 질문                          | 답변                                       |
| --------------------------- | ---------------------------------------- |
| Headless Service DNS로 접속하면? | 여러 Pod의 IP가 DNS 결과로 나옴                   |
| 어디에 접속되는가?                  | 클라이언트 OS가 IP 중 하나를 선택                    |
| 로드밸런싱은?                     | ❌ 없음 (클라이언트가 알아서 결정)                     |
| 언제 사용하나?                    | 각 Pod를 직접 식별하고 접속해야 할 때 (예: StatefulSet) |

### <br/>

### StatefulSet vs Deployment
| 항목         | Deployment | StatefulSet |
| ---------- | ---------- | ----------- |
| Pod 이름 고정  | ❌          | ✅           |
| Pod 순서 보장  | ❌          | ✅           |
| Pod 고유 볼륨  | ❌          | ✅           |
| DNS 주소 고정  | ❌          | ✅           |
| stateless용 | ✅          | ❌           |
| stateful용  | ❌          | ✅           |

### <br/>

### 요약
- StatefulSet은 상태를 가진 앱을 위해 설계됨.
- Pod의 순서, 이름, 볼륨이 중요한 경우 사용.
- Headless Service와 반드시 함께 사용.
- 대표적으로 DB, 메시지 큐, 분산 시스템 노드에 적합.
### <br/><br/>


## stateful, stateless
### 참고로 stateful이란 상태를 저장하고 있다는 말이다. 반대의 의미로 stateless는 상태를 저장하지 않는다는 말이다.
### '서비스의 상태를 저장하는 것이 중요하냐'에 따라 stateful, stateless가 나뉜다.
### database의 transaction도 stateful이다.
### <br/>

### 🟦 Stateless (무상태)
- 서버가 클라이언트의 이전 요청 상태를 기억하지 않음
- 각 요청은 독립적이며, 매번 완전한 정보를 포함해야 함
- 스케일 아웃(확장)에 유리하며, 복제본 간 차이가 없음
### <br/>

### Stateless 애플리케이션 예시
| 예시                     | 설명                  |
| ---------------------- | ------------------- |
| 웹 서버 (Nginx, Apache)   | 요청-응답 단순 처리         |
| 프론트엔드 앱 (React, Vue)   | 서버 상태 의존 없음         |
| REST API 서버            | 각 요청은 독립적           |
| 이미지 서버                 | 클라이언트 요청마다 독립적으로 처리 |
| 서버리스 함수 (AWS Lambda 등) | 상태를 저장하지 않음         |

## <br/>

### 🟩 Stateful (상태 있음)
- 서버가 클라이언트의 이전 상태나 세션 정보를 기억함
- 순서나 컨텍스트가 중요한 작업에 사용
- 복제 또는 재시작 시에도 동일한 저장소, 네트워크 ID 등이 필요
### <br/>

### Stateful 예시
| 예시                | 설명               |
| ----------------- | ---------------- |
| MySQL, PostgreSQL | 저장소 상태 유지 필수     |
| MongoDB, Redis    | 데이터 저장 및 클러스터 구성 |
| Kafka, RabbitMQ   | 메시지 순서 및 큐 상태 중요 |
| Zookeeper, Etcd   | 클러스터 구성 정보 저장    |
| Elasticsearch     | 노드 간 상태 동기화 필요   |

### <br/>

