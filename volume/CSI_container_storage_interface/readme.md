### 250716
# CSI (Container Storage Interface)
### 쿠버네티스에서 외부 스토리지를 연결해서 Pod에 자동으로 붙여주는 표준 인터페이스
### CSI를 구성하려면 먼저 ceph 등 스토리지를 구성해야 한다. 
### CSI는 "스토리지 드라이버"일 뿐이고, 실제 데이터를 저장할 **스토리지 시스템(Ceph 등)**이 먼저 준비되어 있어야 한다.
### ✅ CSI랑 스토리지는 한 세트로 생각하면 된다.
### <br/>

### 왜 CSI가 필요할까?
#### 쿠버네티스에서는 Pod가 데이터를 저장하려면 **스토리지가 자동으로 연결(PersistentVolume)**되어야 한다.
#### 이때 다양한 스토리지 종류(예: Ceph, NFS, iSCSI, Amazon EBS 등)를 일관된 방법으로 붙일 수 있도록 도와주는 게 CSI 이다.
### <br/>

### 구성 요소
| 구성 요소                                | 설명                                                      |
| ------------------------------------ | ------------------------------------------------------- |
| **Storage Provider Plugin (Driver)** | 실제 스토리지를 붙이는 드라이버 (예: Ceph CSI, NFS CSI, AWS EBS CSI 등) |
| **Kubernetes**                       | CSI를 통해 외부 스토리지를 요청하고 연결해 줌                             |
| **Pod / PVC / PV**                   | Pod에서 PVC를 만들면, CSI를 통해 PV가 자동으로 연결됨                    |

### <br/>

### 정리
- CSI는 스토리지를 쿠버네티스에서 표준 방식으로 연결하는 시스템
- CephFS, NFS, MinIO 등과 Kubernetes를 연동할 때 반드시 필요
- PVC → PV → CSI Driver → 외부 스토리지로 연결되는 구조
### <br/>

### CSI 구성을 위한 순서
#### 1. 스토리지 시스템 먼저 구축
#### 먼저 실제 데이터를 저장할 백엔드 스토리지를 구성해야 한다.
#### 예시:
- Ceph → OSD, MON, MGR, MDS 구성 필요
- NFS → NFS 서버 먼저 띄움
- Longhorn → 노드별 디스크를 활용해 설치
- MinIO → 오브젝트 저장소 구성 (단, CSI와는 조금 다름)
#### <br/>

#### 2. Kubernetes에 CSI 드라이버 설치
#### 스토리지를 쿠버네티스에서 인식할 수 있도록 CSI 드라이버(Operator 등)를 설치
#### 예시:
- rook-ceph (Ceph CSI 설치 포함)
- nfs-subdir-external-provisioner (NFS용 CSI)
- longhorn (UI와 함께 설치됨)
#### <br/>

#### 3. StorageClass 정의
#### CSI가 스토리지를 자동으로 붙여줄 수 있도록 클래스 정의
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cephfs-sc
provisioner: rook-ceph.cephfs.csi.ceph.com
parameters:
  ...
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: Immediate
```
#### <br/>

#### 4. PVC(PersistentVolumeClaim)로 사용 요청
#### Pod에서 PVC를 통해 스토리지를 요청하면 CSI가 자동으로 붙여줌
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: cephfs-sc
```
#### <br/>

#### 5. pod에 마운트
```yaml
volumeMounts:
  - name: ceph-volume
    mountPath: /mnt/data
volumes:
  - name: ceph-volume
    persistentVolumeClaim:
      claimName: ceph-pvc
```
#### <br/>

#### CSI 구성 요약
| 단계                | 설명                    |
| ----------------- | --------------------- |
| ① 스토리지 구성         | Ceph, NFS 등 실제 저장소 준비 |
| ② CSI 설치          | 쿠버네티스에 CSI 드라이버 배포    |
| ③ StorageClass 생성 | CSI와 연결된 클래스 등록       |
| ④ PVC 생성          | Pod에서 사용할 스토리지 요청     |
| ⑤ Pod에 마운트        | PVC를 Pod에 연결하여 사용     |

### <br/><br/>

## 참고 블로그
#### https://velog.io/@manarc/Kubernetes-CSI-Longhorn#%EC%95%84%ED%82%A4%ED%85%8D%EC%B2%98-%EC%BB%B4%ED%8F%AC%EB%84%8C%ED%8A%B8
