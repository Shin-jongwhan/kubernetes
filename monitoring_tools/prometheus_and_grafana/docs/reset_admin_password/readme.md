### 260122
# admin 비번 reset 방법
### -n : namespace
### prometheus-stack-grafana-56f68bbd95-2wkjd : 실행된 pod 명
```
kubectl exec -n monitoring -it prometheus-stack-grafana-56f68bbd95-2wkjd -- grafana-cli admin reset-admin-password 'password'
```
