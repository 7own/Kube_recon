#!/bin/bash
# Usages:
#     ./can-i_checker.sh namespace => Will perform enumeration of permissions on namespaces resources
#     ./can-i_checker.sh cluster   => Will perform enumeration of permissions on cluster resources
#     ./can-i_checker.sh           => Will perform both enumeration

#################
RED='\033[0;31m'
COFF='\033[0m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
##################

KUBECTL="oc"

check_cluster_permissions() {
  echo -e "$ORANGE[*] Starting to enumerate Cluster wide resources...$COFF"
  local api_rsc verb
  for api_rsc in $CLUSTER_API_RSC; do
    for verb in $VERBS; do
      kube_cmd="$KUBECTL auth can-i $verb $api_rsc"
      r="$($kube_cmd 2>/dev/null)"
      if grep -q "no" <<< "$r"; then
        echo -e "$ORANGE[CLUSTER]$COFF$RED[-]$COFF $kube_cmd || $RED $r $COFF"
        echo "[CLUSTER] $kube_cmd == $r" >> CAN-I_RESULTS.txt
      fi
      if grep -q "yes" <<< "$r"; then
        echo -e "$ORANGE[CLUSTER]$COFF$CYAN[+]$COFF $kube_cmd || $CYAN $r $COFF"
        echo "[CLUSTER] $kube_cmd == $r" >> CAN-I_RESULTS.txt
        echo "[CLUSTER] $kube_cmd == $r" >> CAN-I_SUCCESS.txt
      fi
    done
  done
}

check_namespace_permissions() {
  echo -e "$ORANGE[*] Starting to enumerate Namespace resources...$COFF"
  local project api_rsc verb
  for project in $PROJECTS; do
    for verb in $VERBS; do
      for api_rsc in $NS_API_RESOURCES; do
        kube_cmd="$KUBECTL auth can-i $verb $api_rsc -n $project"
        r="$($kube_cmd 2>/dev/null)"
        if grep -q "no" <<< "$r"; then
          echo -e "$ORANGE[NAMESPACE]$COFF$RED[-]$COFF $kube_cmd || $RED $r $COFF"
          echo "[NAMESPACE] $kube_cmd == $r" >> CAN-I_RESULTS.txt
        fi
        if grep -q "yes" <<< "$r"; then
          echo -e "$ORANGE[NAMESPACE]$COFF$CYAN[+]$COFF $kube_cmd || $CYAN $r $COFF"
          echo "[NAMESPACE] $kube_cmd == $r" >> CAN-I_RESULTS.txt
          echo "[NAMESPACE] $kube_cmd == $r" >> CAN-I_SUCCESS.txt
        fi
      done
    done
  done
}

PROJECTS=$($KUBECTL get projects -o name | cut -d '/' -f2)
VERBS="get list watch create update patch use pods/attach pods/exec pods/portforward"
NS_API_RESOURCES=$($KUBECTL api-resources | grep true | awk '{print $1}') # Namespaced resources
CLUSTER_API_RSC=$($KUBECTL api-resources | grep false | awk '{print $1}') # Non namespaced resources

# Determine which function(s) to run based on the argument $1
case $1 in
  "")
    echo -e "$ORANGE[*] Checking for both cluster and namespace permissions$COFF"
    check_cluster_permissions
    check_namespace_permissions
    ;;
  "cluster")
    echo -e "$ORANGE[*] Checking for cluster permissions only$COFF"
    check_cluster_permissions
    ;;
  "namespace")
    echo -e "$ORANGE[*] Checking for namespaces permissions only$COFF"
    check_namespace_permissions
    ;;
  *)
    echo "Invalid argument. Use 'cluster' or 'namespace' or no argument."
    ;;
esac
