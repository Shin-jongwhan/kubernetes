### 251110
# mysql innodb cluster 백업 및 복구 방법
### 아래 링크를 참고한다.
- https://github.com/Shin-jongwhan/mysql_and_sql/tree/main/mysql/how_to_dump
### <br/>

### 다음의 명령어로 덤프 sql을 만든다.
#### 아래 덤프 명령어는 mysql system 관련한 데이터베이스는 모두 제외시키고, 운영되는 데이터베이스들만 가져오도록 하는 덤프 명령어다.
#### system 관련 db도 모두 가져오면 cluster 정보가 깨져서 복구가 안 될 수 있다(대체로 안 됨).
#### * 여기는 user에 대한 정보는 없다. 원활하게 복구하려면 주기적으로 계정 정보 / 생성에 대한 쿼리는 만들어놓자. 그리고 미리 새 cluster에 적용해놓는다.
```
export MYSQL_PWD='root'; \
DBLIST=$(mysql -h 127.0.0.1 -P 3306 -uroot -Nse "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','performance_schema','information_schema','sys')"); \
mysqldump -h 127.0.0.1 -P 3306 -uroot \
  --single-transaction --routines --events --triggers \
  --set-gtid-purged=OFF --default-character-set=utf8mb4 \
  --databases $DBLIST > "all_databases_$(date +%y%m%d%H%M).sql"; \
unset MYSQL_PWD
```
### <br/>

### 그리고나서 가장 쉬운 방법은 GUI 프로그램을 이용하는 방법이다.
#### 자동 복구 워크플로우를 만드려면 좀 더 연구를 해봐야 한다. 그렇지만 굳이 그렇게까지 할 필요는 없을 듯 하다.
### 아래 링크 참고
- https://github.com/Shin-jongwhan/mysql_and_sql/tree/main/mysql/how_to_dump#heidisql-%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%98%EB%8A%94-%EB%B0%A9%EB%B2%95%EA%B0%80%EC%9E%A5-%EA%B0%84%ED%8E%B8%ED%95%A8
