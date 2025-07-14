### 250715
# volume 유형 - hostPath, PV (persistance volume), PVC (persistance volume claim)
### <br/><br/>

## hostPath
### Pod가 노드의 로컬 디렉토리를 직접 마운트해서 사용하는 방식.
### 별도의 PV/PVC 없이 Pod 안에서 바로 설정 가능.
### <br/>

### 예시
```yaml
volumes:
  - name: my-volume
    hostPath:
      path: /data/mysql
      type: DirectoryOrCreate
```
### <br/>

### 특징
| 항목        | 설명                         |
| --------- | -------------------------- |
| 접근 방식     | 노드 디렉토리를 직접 사용             |
| 장점        | 간단하고 빠르며 설정 쉬움             |
| 단점        | Pod가 다른 노드로 이동 시 데이터 접근 불가 |
| 사용 예      | 로컬 테스트, static 파일, 로컬 DB 등 |
| 운영 환경 적합성 | ❌ 비추천 (데이터 유실/확장성 문제)      |

### <br/>

## PV (PersistentVolume)
### 정의
- 클러스터 관리자가 미리 정의하는 **스토리지 자원**.
- 다양한 백엔드(NFS, AWS EBS, hostPath 등)를 사용할 수 있음.
- **PVC에 의해 연결**될 수 있음.
### <br/>

### 예시
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/mysql
```
### <br/>

### 특징
| 항목            | 설명                         |
| ------------- | -------------------------- |
| 생성 주체         | 클러스터 관리자 또는 동적 프로비저너       |
| 백엔드 종류        | hostPath, NFS, Ceph, EBS 등 |
| 재사용성          | PVC가 삭제되지 않으면 재사용 가능       |
| ReclaimPolicy | Retain, Delete, Recycle    |
| 운영 환경 적합성     | ✅ 적합 (단, hostPath는 예외)     |

### <br/><br/>

## PVC (PersistentVolumeClaim)

### 정의
- 사용자가 필요한 스토리지 용량, 접근 모드를 명시해서 요청하는 객체.
- Kubernetes가 적절한 PV를 찾아 연결시킴.

### 예시
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
### <br/>

### 특징

| 항목        | 설명                                        |
| --------- | ----------------------------------------- |
| 생성 주체     | 사용자 또는 Deployment 내부 volumeClaimTemplates |
| 용도        | 스토리지 요청용                                  |
| 바인딩 대상    | 조건이 일치하는 PV                               |
| 동적 프로비저닝  | StorageClass가 설정된 경우 자동 생성 가능             |
| 운영 환경 적합성 | ✅ 매우 적합                                   |

### <br/><br/>

## 관계도 요약

```
[ PVC (사용자 요청) ] ───(바인딩)───> [ PV (스토리지 제공자) ] ──> [ 실제 스토리지 (NFS, hostPath 등) ]
```

* `hostPath`: 단독으로 사용 가능 (PVC 없이)
* `PV`: PVC가 요청한 조건에 맞춰 실제 스토리지를 제공
* `PVC`: Pod가 요청하는 스토리지의 인터페이스

### <br/><br/>

## 비교표

| 항목      | hostPath   | PV                   | PVC            |
| ------- | ---------- | -------------------- | -------------- |
| 역할      | 로컬 디스크 마운트 | 스토리지 제공자             | 사용자 요청자        |
| 위치      | Pod 정의 내부  | 독립 리소스               | 독립 리소스         |
| 스토리지 유형 | 노드 로컬      | hostPath, NFS, EBS 등 | PV에 연결됨        |
| 마이그레이션  | ❌ 안 됨      | 백엔드 따라 다름            | PV와 연동 시 이동 가능 |
| 사용 용도   | 간단한 테스트용   | 영구적이고 재사용 가능한 스토리지   | 스토리지 요구 명세화    |

### <br/><br/>

## EBS는 local storage 인데 어떻게 PV 가 될 수 있나?
### EBS는 로컬 볼륨이 맞다(물리적으로).
### EBS는 특정 AZ(Availability Zone) 에 물리적으로 존재하는 block-level storage 이다.
### 특정 EC2 인스턴스에 attach 할 수 있고, 동시에 여러 인스턴스에서 사용할 수는 없다.
### 즉, EBS는 “AZ 내 단일 노드 전용 디스크”처럼 동작한다.
### <br/>


