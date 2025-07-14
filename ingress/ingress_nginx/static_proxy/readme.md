### 250714
# Static proxy 구성
### <br/><br/>

### nginx 기본 주소는 /usr/share/nginx/html이고, 그 하위를 주소로 인식한다. 
### 나는 prefix path도 같이 쓸 것이기 때문에 이렇게 지정했다.
#### <br/>

### pathType은 2가지가 있다.
- "pathType: Prefix" : prefix path를 포함한 전체 경로를 인식
- "pathType: ImplementationSpecific" : service pod 내부에서는 url path를 prefix를 제외한 path부터 인식하게 할 때 지정.
#### django-ingress.yaml
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-dev
  namespace: django-dev
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  ingressClassName: nginx
  rules:
    - host: service.example.com
      http:
        paths:
          - path: /django/dev/static
            pathType: Prefix
            backend:
              service:
                name: django-static
                port:
                  number: 80
          - path: /django/dev
            pathType: Prefix
            backend:
              service:
                name: django-dev
                port:
                  number: 8088
  tls:
    - hosts:
        - service.example.com
      secretName: dashboard-tls
```
### <br/>

### static proxy를 위해 nginx service를 하나 만들어야 한다.
#### django-static.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-static
  namespace: django-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: django-static
  template:
    metadata:
      labels:
        app: django-static
    spec:
      nodeSelector:
        role: service  # role=service 라벨을 가진 노드에서만 실행
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
          volumeMounts:
            - name: static-dev
              mountPath: /usr/share/nginx/html/django/dev/static
            # 새로운 volume mount가 필요한 경우 아래와 같이 name을 새로 만들어서 mount
            #- name: static-publish
            #  mountPath: /usr/share/nginx/html/django/publish/static
      volumes:
        - name: static-dev
          hostPath:
            path: /data/django/dev/collectstatic
            type: Directory
        #- name: static-publish
        #  hostPath:
        #   path: /data/django/publish/collectstatic
        #   type: Directory

---

apiVersion: v1
kind: Service
metadata:
  name: django-static
  namespace: django-dev
spec:
  selector:
    app: django-static
  ports:
    - port: 80
      targetPort: 80

```
### <br/>

### kubectl로 apply 한다.
```
kubectl apply -n [namespace] -f django-ingress.yaml
kubectl apply -n [namespace] -f django-static.yaml
```
### <br/>

### pod에 직접 들어가서 확인해보자.
```
# pod name 출력
kubectl get pod -n [namespace] -o wide | grep django-static
# pod 접속
kubectl exec -it -n [namespace] [pod_name] -- /bin/bash
# 파일 검색
ls -al /usr/share/nginx/html/
```
#### <img width="612" height="115" alt="image" src="https://github.com/user-attachments/assets/1a41e4ed-e399-4967-a267-70c0497d52ae" />

### <br/>
