#!/bin/bash

if ! tkn results &>/dev/null; then
   echo Command 'tkn results' is not installed
   echo https://github.com/tektoncd/results/blob/main/tools/tkn-results/README.md
fi

if [ -z "$TEKTON_RESULTS_PORT" ]; then
  TEKTON_RESULTS_PORT=$(oc get service tekton-results-api-service -n tekton-pipelines -o yaml | yq '.spec.ports.[] | select(.name == "grpc") | .nodePort')
  if [ $? -ne 0 ]; then
     echo "Not enough permissions on the cluster to get PORT of tekton results"
     echo "Node port of tekton results api can be set by TEKTON_RESULTS_PORT environment variable"
     exit 1
  fi
fi
URL=$(oc whoami --show-console | sed 's|https://||')

oc get configmap config-service-cabundle --template='{{index .data "service-ca.crt"}}' > ~/.config/tkn/cert.pem

cat > ~/.config/tkn/results.yaml <<EOF
address: $URL:$TEKTON_RESULTS_PORT
token: $(oc whoami --show-token)
ssl:
    roots_file_path: $HOME/.config/tkn/cert.pem
    server_name_override: tekton-results-api-service.tekton-pipelines.svc.cluster.local
EOF

echo If you cannot list results then you are probably missing permission, can be added by:
echo "kubectl create clusterrolebinding tekton-results-debug --clusterrole=tekton-results-readonly --user=\$(oc whoami)"
