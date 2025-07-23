### 250710
# TLS secret
### secret은 namespace 별로 관리되는 것이기 때문에 같은 cert를 쓰더라도 각각 만들어줘야 한다.
```
kubectl create secret tls dashboard-tls \
  --cert=./tls.crt \
  --key=./tls.key \
  -n tgf-django-dev
```
### <br/>

### 만약 기존에 쓰던 TLS secret이 있다면 아래와 같이 복사할 수 있다.
#### ex)
```
kubectl get secret dashboard-tls -n kubernetes-dashboard -o yaml \
| sed 's/namespace: kubernetes-dashboard/namespace: tgf-django-dev/' \
| kubectl apply -f -
```
### <br/>

### secret 조회
```
kubectl get secret dashboard-tls -n tgf-django-dev
```
#### ![image](https://github.com/user-attachments/assets/4bbc5cfe-fbe7-43db-8e79-62566e5e96c5)
