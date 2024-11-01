#!/usr/bin/env bash

set -e
TOOL=oc
alias kubectl=$TOOL;

if [ $# -eq 0 ]
  then
    read -p "No Kube context supplied, are you sure you want kubectl somethings ?" yn
    case $yn in
        [Yy]* ) echo "doing with no specific context";;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no."; exit;;
    esac
  CONTEXT=""
  CONTEXT_DIR="default"
else
  CONTEXT="--context $1"
  CONTEXT_DIR="$1"
fi

if [[ $TOOL == "oc" ]] ; then
    NAMESPACES=$(kubectl ${CONTEXT} get -o json projects|jq '.items[].metadata.name'|sed "s/\"//g")
else
    NAMESPACES=$(kubectl ${CONTEXT} get -o json namespaces|jq '.items[].metadata.name'|sed "s/\"//g")
fi

CLUSTER_RESOURCES="projects clusterroles clusterrolebindings nodes pv psp csr ns resourcequotas crd"
NS_RESOURCES="configmap secret pods endpoints daemonset deployment roles jobs cronjobs rolebindings serviceaccount replicaset ingress statefulset service hpa pvc netpol limitranges podtemplates"
CRD=$(kubectl ${CONTEXT} get -o json crd|jq '.items[].metadata.name'|sed "s/\"//g")

for resource in ${CLUSTER_RESOURCES};do
  rsrcs=$(kubectl ${CONTEXT} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
  for r in ${rsrcs};do
    echo "$resource" "$r"
    dir="${CONTEXT_DIR}/CLUSTER_RESOURCE/${resource}"
    mkdir -p "${dir}"
    kubectl ${CONTEXT} get -o yaml ${resource} ${r} > "${dir}/${r}.yaml"
  done
done

for ns in ${NAMESPACES};do
  for resource in ${NS_RESOURCES};do
    rsrcs=$(kubectl ${CONTEXT} -n ${ns} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
    for r in ${rsrcs};do
      echo "$ns $resource $r"
      dir="${CONTEXT_DIR}/${ns}/${resource}"
      mkdir -p "${dir}"
      kubectl ${CONTEXT} -n ${ns} get -o yaml ${resource} ${r} > "${dir}/${r}.yaml"
      dir_per_rsrc="${CONTEXT_DIR}/PER_RSRC/${resource}"
      mkdir -p "${dir_per_rsrc}"
      cp "${dir}/${r}.yaml" "${dir_per_rsrc}/${ns}_${r}.yaml" || echo bad
    done
  done
done


for crd in ${CRD};do
  echo "${crd}"
  dir="${CONTEXT_DIR}/CRUD_RSRC/${crd}"
  mkdir -p "${dir}"
  kubectl ${CONTEXT} get "${crd}" > "${dir}"/crd_nooption.txt
  kubectl ${CONTEXT} get "${crd}" --all-namespaces > "${dir}"/crd_all_ns.txt

  INST1=$(kubectl ${CONTEXT} get "${crd}" -o json|jq '.items[].metadata.name' -r)
  INST2=$(kubectl ${CONTEXT} get "${crd}" --all-namespaces -o json|jq '.items[].metadata|.name,.namespace' -r)

  for r in ${INST1};do
    echo "CRD ${r}"
    dirbis="${dir}/global"
    mkdir -p "${dirbis}"
    kubectl ${CONTEXT} get -o yaml "${crd}" "${r}" > "${dirbis}/${r}.yaml"
  done

  while IFS='|' read -r name ns
  do
    echo "CRD ${name} (ns ${ns})"
    dirbis="${dir}/per_ns/${ns}"
    mkdir -p "${dirbis}"
    kubectl ${CONTEXT} get -o yaml ${crd} ${name} -n "${ns}" > "${dirbis}/${name}.yaml"
  done < <(kubectl get "${crd}"  --all-namespaces -o json | jq '.items[].metadata|.name+"|"+.namespace' -r)
done
