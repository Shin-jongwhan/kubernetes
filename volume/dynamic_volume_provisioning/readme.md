### 250722
# 동적 볼륨 프로비저닝
### 참고
#### https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/
#### https://kubernetes.io/docs/concepts/storage/persistent-volumes/
#### https://kubernetes.io/docs/concepts/storage/storage-classes/
#### 
### <br/>

#### 동적 프로비저닝을 사용하면 정적(static)으로 사용하는 것보다 좀 더 편리하게 볼륨을 관리할 수 있다.
### 특징
- storage class는 정적이나 동적이나 공통으로 수동으로 만들어야 한다.
- PVC만 만들면 된다. 
- 자동으로 PV를 만든다. 수동으로 PV를 만들지 않아도 된다.
- 만약 디렉토리가 없다면 자동으로 만들어주기 때문에, host에서 만든 다음에 만들지 않아도 된다.
#### <br/>

#### 공식 docs에도 보면 동적 프로비저닝을 사용하는 이유에 대해 다음과 같이 말한다. 
#### <img width="780" height="267" alt="image" src="https://github.com/user-attachments/assets/80137a4e-0e31-4816-85fe-8d4616c39b9f" />
### <br/><br/>

## NFS 동적 프로비저닝 이용하기
#### NFS 동적 프로비저닝을 이용하면 각 node에 NFS를 mount 하지 않아도 사용할 수 있게 만들 수 있다. 
#### 각 node에 mount를 하면 hostPath로 직접 pod 생성 시 volume mount를 해서 쓸 수는 있는데, hostPath는 개발용으로 적합하다고 공식 docs에 써져 있다(아래 참고). 
#### https://github.com/Shin-jongwhan/kubernetes/tree/main/volume/hostPath_PV_PVC
#### <br/>

### NFS provisioner
#### NFS 동적 프로비저닝을 이용하려면 NFS provisioner라는 외부 provisioner가 필요하다. 공식 docs를 보자.
#### <img width="751" height="664" alt="image" src="https://github.com/user-attachments/assets/692265e8-e640-4bcc-ba14-60a6798a027d" />
#### <img width="774" height="272" alt="image" src="https://github.com/user-attachments/assets/ab5453e7-aaeb-465c-a043-3b993bd2ae6e" />
#### <br/>

#### 가장 많이 사용하는 NFS provisioner는 nfs-subdir-external-provisioner이다. 이는 공식 docs에서도 소개되어 있다. 
#### <img width="1246" height="718" alt="image" src="https://github.com/user-attachments/assets/9393ba74-b932-4c1d-952b-075a57bfc081" />
#### https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
#### <br/>

#### 공식 docs에 나온 NFS yaml 예시
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: example-nfs
provisioner: example.com/external-nfs
parameters:
  server: nfs-server.example.com
  path: /share
  readOnly: "false"
```
### <br/>

### nfs-subdir-external-provisioner 설치
```
# 참고 : 미리 storage class를 만들어두면 안 된다. 있으면 삭제
kubectl delete storageclass nfs

# repo 추가
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# 설치
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace kube-system \
  --create-namespace \
  --set nfs.server=tgf-service.ptbio.kr \
  --set nfs.path=/data/nfs \
  --set storageClass.name=nfs-dynamic \
  --set storageClass.defaultClass=true
```
#### 이런 설치 메세지가 나온다.
#### STATUS: deployed 라고 나오면 된 것이다.
#### <img width="485" height="114" alt="image" src="https://github.com/user-attachments/assets/9ef3199e-46e5-4b35-91b2-2ed7f1baa9e5" />
### <br/>

### storage class 확인
#### (default) 붙어있으면 PVC에서 storageClassName 생략해도 된다.
```
kubectl get storageclass
```
#### <img width="939" height="101" alt="image" src="https://github.com/user-attachments/assets/521f385f-fa5c-4fc7-9c8f-95b6f867fd0c" />
### <br/>

### test로 PVC를 만들어보자.
#### test-pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 1Gi
```
#### <br/>

### 적용 및 확인
### 이제 아주 간편하게 nfs를 사용할 수 있다. 
```
kubectl apply -f test-pvc.yaml
kubectl get pvc test-nfs-pvc -n default
```
#### <img width="938" height="63" alt="image" src="https://github.com/user-attachments/assets/54561a83-7e8c-4506-abe2-cf882682e75b" />
### <br/>

#### 그리고 host에서 NFS로 설정한 경로로 가서 확인해보자. 이렇게 각 PV 마다 볼륨이 생성되어 있는 것을 확인할 수 있다.
#### NFS 동적 프로비저닝 설정이 모두 완료되었다.
#### <img width="754" height="100" alt="image" src="https://github.com/user-attachments/assets/7099e748-6036-4dd8-8822-6150740ba6b1" />
### <br/>

### reclaimPolicy
#### reclaimPolicy: Retain이 default 설정인데, 이걸로 설정되어 있으면 pvc가 삭제되더라도 계속 보존해놓는다.
#### 예를 들어 아까 test로 생성한 pvc를 삭제하고 nfs 경로에서 다시 확인해보자.
```
kubectl delete -f test-pvc.yaml
```
#### <br/>

#### 그러면 이렇게 archived로 남아있을 것이다.
#### <img width="822" height="68" alt="image" src="https://github.com/user-attachments/assets/d1943d75-0f68-4fcc-aeac-752c5c5bffe3" />
### <br/>

### reclaimPolicy 유형 및 비교표
#### Retain과 Delete 2가지 형태가 있다. 
| `reclaimPolicy` 값 | PVC 삭제 시 동작                             | 데이터 유지 여부 | PV 상태        | 재사용 가능 여부               | 사용 용도                        |
| ----------------- | --------------------------------------- | --------- | ------------ | ----------------------- | ---------------------------- |
| `Retain` (보존)     | PV는 Released 상태로 남고, 데이터도 그대로 유지됨       | ✅ 유지됨     | `Released`   | ❌ 자동 재사용 안 됨 (수동 조치 필요) | 운영 환경에서 안전하게 데이터 보존할 때       |
| `Delete` (삭제)     | PV 및 실제 스토리지 리소스(예: 디렉토리)도 함께 삭제        | ❌ 삭제됨     | 없음 (PV도 삭제됨) | N/A                     | 테스트 환경, 데이터 보존 불필요할 때        |
| `Recycle` *(폐지됨)* | PV가 초기화된 후 다시 Available 상태로 변경 (rm -rf) | ❌ 초기화됨    | `Available`  | ✅ 가능                    | Kubernetes 1.11 이후 공식 지원 중단됨 |
