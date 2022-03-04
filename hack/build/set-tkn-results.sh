#!/bin/bash

if ! tkn results &>/dev/null; then
   echo Command 'tkn results' is not installed
   echo https://github.com/tektoncd/results/blob/main/tools/tkn-results/README.md
fi

oc get secrets tekton-results-tls -n tekton-pipelines --template='{{index .data "tls.crt"}}' | base64 -d > ~/.config/tkn/cert.pem
if [ $? -ne 0 ]; then
   echo "Not enough permissions on the cluster"
   exit 1
fi


PORT=$(oc get service tekton-results-api-service -n tekton-pipelines -o yaml | yq '.spec.ports.[] | select(.name == "grpc") | .nodePort')
URL=$(oc whoami --show-console | sed 's|https://||')

cat > ~/.config/tkn/results.yaml <<EOF
address: $URL:$PORT
token: $(oc whoami --show-token)
ssl:
    roots_file_path: $HOME/.config/tkn/cert.pem
    server_name_override: tekton-results-api-service.tekton-pipelines.svc.cluster.local
EOF

echo If you cannot list results then you are probably missing permission, can be added by:
echo "kubectl create clusterrolebinding tekton-results-debug --clusterrole=tekton-results-readonly --user=\$(oc whoami)"
