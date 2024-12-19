### 241219
# kubernetes
### k8s라고 줄여서 부르기도 하는데 중간에 8글자라서 k8s라고 부른다고...
### 쿠버네티스는 컨테이너 오케스트레이션 오픈소스 프레임워크(플랫폼)이다.
### 컨테이너들에 대해 자동으로, 그리고 대규모로 관리, 확장, 배포해준다.
#### ![image](https://github.com/user-attachments/assets/ebc8b0b6-946d-46ea-9dc5-fe3cd115af20)
### <br/><br/>

## 잡담
### 컨테이너 개수가 많아지고 여러 서버를 관리하려다보니 힘들어서 고려하고 있다.
### 서비스가 엄청 크지 않기 때문에 쿠버네티스를 적용하기에 애매해서 적용은 안 했는데 작더라도 관리를 위해 적용하면 좋겠다 생각했다.
### <br/><br/><br/>


## 컨테이너 관리, orchastration tool
### 쿠버네티스는 매우 유명하고 유용한 툴이다 !
### 아주 다양한 기능들이 있다.
- autoscaling
- load balancing
- health check 및 복
- server cluster 관리 (multi node kubernetes cluster)
- Ingress : proxy server, 로드 밸런싱. HPA와 같이 사용하면 트래픽 처리에 대해 오토스케일링이 된다.
- HPA (horizontal pod autoscaler) : 오토스케일링
- 클라우드 연동
- rolling update : 컨테이너에 포함된 앱이 업데이트되면 점진적으로 최신 버전으로 이관되게 하는 기능
- 스토리지 오케스트레이션 : 로컬 스토리지, 클라우드 스토리지, 네트워크 스토리지 등 다양한 스토리지 솔루션과 연동
- 배포와 롤백 : 문제가 발생할 경우 이전 버전으로 롤백
### <br/><br/>

