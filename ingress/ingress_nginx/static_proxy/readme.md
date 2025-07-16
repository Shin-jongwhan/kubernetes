### 250714
# Static proxy 구성
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
### hostPath 방법 (테스트 / 개발용)
#### 운영에서는 PV로 운영한다. PV 방법은 아래에서 추가로 소개한다.
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

### 그리고 크롬 등 브라우저에 주소로 입력해서 확인해보자.
```
https://service.example.com/django/dev/static/css/default.css
```
#### <img width="647" height="333" alt="image" src="https://github.com/user-attachments/assets/7f509417-7292-4831-8448-5354d3cd28e3" />

### <br/><br/>

## PV로 만드는 방법
### 다음의 3가지가 필요하다.
- storage class
- PV (persistance volume) + PVC (persistance volume claim)
- deployment + service (이건 hostPath와 동일)
### <br/>

### 먼저 나는 yaml을 이런 형식으로 정리해놓았다.
```
storage_class/
└── storageclass_local.yaml

persistance_volume/
└── pv_django_dev_static.yaml

deployment/
└── django/
    └── django-dev-static.yaml
```
### <br/>

### storageclass_local.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
### <br/>

### pv_django_dev_static.yaml
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-django-static
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/django/dev/collectstatic
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: role
              operator: In
              values:
                - service
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-django-static
  namespace: web-app
spec:
  accessModes:
    - ReadOnlyMany
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
```
### <br/>

### django-dev-static.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-static-server
  namespace: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: django-static-server
  template:
    metadata:
      labels:
        app: django-static-server
    spec:
      nodeSelector:
        role: service
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
          volumeMounts:
            - name: static-files
              mountPath: /usr/share/nginx/html/static
      volumes:
        - name: static-files
          persistentVolumeClaim:
            claimName: pvc-django-static
---
apiVersion: v1
kind: Service
metadata:
  name: django-static-server
  namespace: web-app
spec:
  selector:
    app: django-static-server
  ports:
    - port: 80
      targetPort: 80
```
### <br/>

### apply 명령어 실행
```
kubectl apply -f storage_class/storageclass_local.yaml
kubectl apply -f persistance_volume/pv_django_dev_static.yaml
kubectl apply -f deployment/django_static/django-static.yaml
```
