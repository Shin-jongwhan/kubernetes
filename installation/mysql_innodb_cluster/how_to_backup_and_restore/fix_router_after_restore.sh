#!/usr/bin/env bash
set -euo pipefail

############################################
# MySQL Router 접속 불가(복구 후) 트러블슈팅/정리 스크립트
#
# 사용 예:
#   점검만
#   bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password'
#   메타데이터 DROP까지
#   bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password' --drop-metadata
#   Router 재시작까지
#   bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password' --restart-router
#   인스턴스 인덱스가 0 1 2가 아닐 때
#   bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password' --router-pod mycluster-router-xxxxx --idxs "0 1 2"
############################################

# ===== 기본값 =====
sNamespace="tgf"
sClusterName="mycluster"
sMysqlUser="root"
nMysqlPort="3306"
sMysqlPwd=""
sRouterPod=""
sPodIdxs="0 1 2"
bDropMetadata="NO"
bRestartRouter="NO"

function print_usage() {
  cat <<'USAGE'
Usage:
  fix_router_after_restore.sh -p '<MYSQL_ROOT_PASSWORD>' [options]

Required:
  -p, --password           MySQL root password (quote it if it has special chars)

Options:
  -n, --namespace          Kubernetes namespace (default: tgf)
  -c, --cluster            InnoDBCluster name / StatefulSet prefix (default: mycluster)
  -u, --user               MySQL user (default: root)
  --port                   MySQL port inside pod (default: 3306)
  --router-pod             Router pod name (auto-detect if omitted)
  --idxs                   Pod indices for instances (default: "0 1 2")
  --drop-metadata          Drop mysql_innodb_cluster_metadata (dangerous; use with care)
  --restart-router         Delete router pod at the end (meaningful after metadata restored)
  -h, --help               Show help

Examples:
  bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password'
  bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password' --drop-metadata
  bash fix_router_after_restore.sh -n tgf -c mycluster -p 'root_password' --restart-router
USAGE
}

# ===== 인자 파싱 =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) sNamespace="$2"; shift 2;;
    -c|--cluster) sClusterName="$2"; shift 2;;
    -u|--user) sMysqlUser="$2"; shift 2;;
    --port) nMysqlPort="$2"; shift 2;;
    -p|--password) sMysqlPwd="$2"; shift 2;;
    --router-pod) sRouterPod="$2"; shift 2;;
    --idxs) sPodIdxs="$2"; shift 2;;
    --drop-metadata) bDropMetadata="YES"; shift 1;;
    --restart-router) bRestartRouter="YES"; shift 1;;
    -h|--help) print_usage; exit 0;;
    *) echo "Unknown argument: $1"; print_usage; exit 1;;
  esac
done

if [[ -z "${sMysqlPwd}" ]]; then
  echo "ERROR: --password is required."
  print_usage
  exit 1
fi

# ===== Router pod 자동 탐색 =====
if [[ -z "${sRouterPod}" ]]; then
  sRouterPod="$(kubectl get pod -n "${sNamespace}" -o name | grep "${sClusterName}-router" | head -n 1 | sed 's|pod/||')"
fi
if [[ -z "${sRouterPod}" ]]; then
  echo "ERROR: cannot find router pod. Provide --router-pod."
  exit 1
fi

echo "===== [INFO] namespace=${sNamespace}, cluster=${sClusterName}, router_pod=${sRouterPod}, idxs='${sPodIdxs}' ====="

############################################
# 1) Router 로그로 metadata 오류 확인
############################################
echo
echo "===== [1] Router logs (metadata_cache) ====="
kubectl logs -n "${sNamespace}" "${sRouterPod}" --tail=200 | egrep -i "metadata_cache|mysql_innodb_cluster_metadata|v2_this_instance|schema_version" || true

############################################
# 2) Group Replication 상태 확인
############################################
echo
echo "===== [2] Group Replication members ====="
kubectl exec -n "${sNamespace}" "${sClusterName}-0" -c mysql -- sh -lc "export MYSQL_PWD='${sMysqlPwd}' && mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -e \"SELECT MEMBER_HOST,MEMBER_ROLE,MEMBER_STATE FROM performance_schema.replication_group_members;\" && unset MYSQL_PWD"

############################################
# 3) 각 인스턴스 server_uuid/server_id 확인
############################################
echo
echo "===== [3] server_uuid/server_id per instance ====="
for nIdx in ${sPodIdxs}; do
  echo "----- ${sClusterName}-${nIdx} -----"
  kubectl exec -n "${sNamespace}" "${sClusterName}-${nIdx}" -c mysql -- sh -lc "export MYSQL_PWD='${sMysqlPwd}' && mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -Nse \"SELECT @@hostname,@@server_uuid,@@server_id;\" && unset MYSQL_PWD"
done

############################################
# 4) 메타데이터 스키마 상태 확인
############################################
echo
echo "===== [4] metadata schema existence + v2_this_instance + instances ====="
kubectl exec -n "${sNamespace}" "${sClusterName}-0" -c mysql -- sh -lc "export MYSQL_PWD='${sMysqlPwd}' && \
mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -e \"SHOW DATABASES LIKE 'mysql_innodb_cluster_metadata%';\" && \
( mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -e \"SELECT * FROM mysql_innodb_cluster_metadata.v2_this_instance;\" || true ) && \
( mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -Nse \"SELECT COUNT(*) AS instances_cnt FROM mysql_innodb_cluster_metadata.instances;\" || true ) && \
( mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -e \"SELECT instance_name,address,mysql_server_uuid,attributes FROM mysql_innodb_cluster_metadata.instances;\" || true ) && \
unset MYSQL_PWD"

############################################
# 5) (옵션) 메타데이터 DROP
############################################
if [[ "${bDropMetadata}" == "YES" ]]; then
  echo
  echo "===== [5] DROP mysql_innodb_cluster_metadata ====="
  echo "WARNING: Router 기반 라우팅을 살리려면 이후 메타데이터 재생성이 필요합니다."
  kubectl exec -n "${sNamespace}" "${sClusterName}-0" -c mysql -- sh -lc "export MYSQL_PWD='${sMysqlPwd}' && mysql -h 127.0.0.1 -P ${nMysqlPort} -u${sMysqlUser} -e \"DROP DATABASE IF EXISTS mysql_innodb_cluster_metadata;\" && unset MYSQL_PWD"
fi

############################################
# 6) (옵션) Router 재시작
############################################
if [[ "${bRestartRouter}" == "YES" ]]; then
  echo
  echo "===== [6] Restart router pod ====="
  kubectl delete pod -n "${sNamespace}" "${sRouterPod}"
else
  echo
  echo "===== [6] Router restart command (optional) ====="
  echo "kubectl delete pod -n ${sNamespace} ${sRouterPod}"
fi

echo
echo "DONE."

