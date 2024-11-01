`Kube_recon` is just a repository that group multiple scripts (mostly bash) to perform recon and post exploitation on Kubernetes clusters.

# Tools description
- `can-i_checker.sh`: Enumerate all permissions of the current logged in account. It will output 2 files (RESULTS, SUCCESS).
- `find_exposed_services.sh`: Enumerate exposed services of a cluster, from the internal point of view.
- `kube_dump.sh`: Dump all resources of a clusters locally. This can be used to perform review of the configurations offline.
- `logs_dump.sh`: Find secrets within containers' logs.
- `oc_secret_finder.sh`: Find secrets within namespaces' resources.
- `secrets_dump.sh`: Dump secrets from each namespaces, useful when cluster admin privilege is reached.
