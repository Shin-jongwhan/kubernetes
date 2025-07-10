### 250710
## Kubernetes ingress
#### https://kubernetes.io/docs/concepts/services-networking/ingress/
#### ![image](https://github.com/user-attachments/assets/eafd787a-eee4-40f4-9b17-1263b10c94a5)
### <br/>

### 프록시 서버 + 로드 밸런싱
### 직접 연결되는 pod (Nginx Ingress Controller Pod)로는 nginx가 있다(다른 거 써도 됨). 
### 이 pod는 service로 트래픽을 분배한다. 그리고 service는 쿠버네티스가 로드 밸런싱한다.
### <br/><br/><br/>


## workflow
### 1. 클라이언트 요청
#### 클라이언트가 도메인이나 IP를 통해 요청을 보냄 (예: https://example.com).
### <br/>

### 2. 쿠버네티스 -> Nginx Ingress Controller Pod로 전달
#### 요청은 Ingress 리소스에 따라 Nginx Ingress Controller Pod로 전달.
#### 여기서 Ingress는 트래픽의 "입구" 역할을 하고, Nginx는 이를 처리하는 컨트롤러임.
### <br/>

### 3. Nginx Ingress Controller -> Kubernetes Service로 전달
#### Nginx는 요청을 처리하고, Ingress 규칙에 따라 요청을 Kubernetes Service로 전달.
### <br/>

### 4. Kubernetes Service -> Pod로 전달 (로드밸런싱)
### <br/>

### 5. Kubernetes Service는 요청을 관리하며, Endpoints를 통해 요청을 해당 Pod(컨테이너)로 분배.
#### 여기서 쿠버네티스의 로드밸런싱이 작동하여 Pod 간 부하를 분산 처리.
#### Pod(컨테이너)에서 데이터 처리 및 반환
### <br/>

### 6. 요청을 받은 Pod가 데이터를 처리하고 응답 생성.
#### 이 응답은 다시 Service로 전달.
#### Service -> Nginx Ingress Controller로 반환
#### Service가 응답을 Nginx Ingress Controller로 보냄.
### <br/>

### 7. Nginx Ingress Controller -> 클라이언트로 반환.
#### Nginx Ingress Controller가 응답을 클라이언트로 반환.
### <br/><br/>

## 재시작
### 만약 ingress에 변경사항이 있다면 재시작을 해줘야 한다.
#### * 참고로 특정 namespace의 ingress에서 yaml을 변경하여 다시 적용하는 거면 그냥 kubectl apply 하면 자동으로 변경 사항이 적용된다.
```
kubectl delete pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```
### <br/>

### 그 다음 ingress가 재시작되었는지 확인한다.
```
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o wide
```
#### ![image](https://github.com/user-attachments/assets/a409fb02-e33c-40bb-a26a-441aed48f850)
