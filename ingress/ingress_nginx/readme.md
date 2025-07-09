### 250708
## ingress nginx
### nginx로 ingress를 구현하는 것이다. nginx를 사용해본 경험이 있다면 딱히 별 다른 추가적인 개념은 없다.
### 공식 github repository에서는 다음과 같은 기능을 한다고 한다.
#### ingress-nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.
#### https://github.com/kubernetes/ingress-nginx
### <br/>

## get started
#### https://kubernetes.github.io/ingress-nginx/deploy/
### 설치 및 실행
```
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```
### <br/>

### helm으로 설치된 ingress nginx의 설정값을 보려면 다음의 명령어를 사용한다.
- Helm 차트 이름: ingress-nginx
- 차트 위치(Helm repo): https://kubernetes.github.io/ingress-nginx
- 이 차트의 기본 설정 옵션들(values.yaml) 을 조회
```
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
```
### <br/>

### 8443, 80, 443 포트가 열려있는지 확인해야 한다고 한다.
### 8443 은 kubernetes 내부 클러스터 통신용 포트이다.
#### ![image](https://github.com/user-attachments/assets/42d1fba0-a0be-4958-9625-c3773468ec80)
#### <br/>

### pod 안에서 8443을 listen 하는지 확인하려면 다음과 같이 한다.
#### pod name 확인
```
kubectl get pods -n ingress-nginx
```
##### <br/>

#### 포트 listen 확인
```
kubectl -n ingress-nginx exec -it [pod_name] -- netstat -tuln | grep 8443
```
#### ![image](https://github.com/user-attachments/assets/358d91ff-7670-4cdc-82c8-ae5485506c1a)
### <br/>

### Local testing
### local에서 테스트를 해보자.
```
# Let's create a simple web server and the associated service:
kubectl create deployment demo --image=httpd --port=80
kubectl expose deployment demo

# Then create an ingress resource. The following example uses a host that maps to localhost:
kubectl create ingress demo-localhost --class=nginx \
  --rule="demo.localdev.me/*=demo:80"

# Now, forward a local port to the ingress controller:
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
```
#### <br/>

### curl로 접속 되는지 테스트
#### It works!가 찍힌다.
```
curl --resolve demo.localdev.me:8080:127.0.0.1 http://demo.localdev.me:8080
```
#### ![image](https://github.com/user-attachments/assets/14392ad6-8edd-4aca-b619-c30dfbb90a43)
### <br/>

### 참고
#### local service로만 구성하는 경우 external IP는 필요 없다. 만약 클라우드 환경이라면 자동으로 설정이 되니 혼동하지 말자.
```
kubectl get svc ingress-nginx-controller -n ingress-nginx
```
#### ![image](https://github.com/user-attachments/assets/adb4e9d0-84e8-4fae-97fd-2a11b5bbaa8f)
### <br/>

### ingress 목록 확인
```
kubectl get ingress
```
#### <br/>

#### 그러면 이렇게 나온다.
```
NAME             CLASS   HOSTS              ADDRESS   PORTS   AGE
demo-localhost   nginx   demo.localdev.me             80      17h
```
### <br/>

### dashboard에서도 확인 가능
#### ![image](https://github.com/user-attachments/assets/af3853a2-1e02-49bd-9e68-158374ed21b1)
### <br/>

### 삭제하려면 다음과 같이 하면 된다(dashboard에서도 삭제 가능).
```
kubectl delete ingress demo-localhost
kubectl delete deployment demo
kubectl delete service demo
```
### <br/>

### dashboard에서 확인할 수 있다.
#### ![image](https://github.com/user-attachments/assets/0e7570c2-2e70-4441-a33f-35c246415c59)
