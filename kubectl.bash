###########################################
# kubectl aliases + bash completion setup #
# Works on Linux, macOS, WSL, Git Bash    #
###########################################

# --- Load kubectl completion ---
# kubectl must be installed and in PATH
if command -v kubectl >/dev/null 2>&1; then
    # Load completion function
    source <(kubectl completion bash)

    # Optional: Make completion case-insensitive
    bind "set completion-ignore-case on"
else
    echo "Warning: kubectl not found in PATH — skipping completion setup."
fi


###########################################
#                 ALIASES                 #
###########################################

# Base alias
alias k="kubectl"

# General commands
alias kg="kubectl get"
alias kd="kubectl describe"
alias kdel="kubectl delete"
alias ke="kubectl edit"
alias kaf="kubectl apply -f"
alias kex="kubectl exec -it"
alias kl="kubectl logs"
alias klf="kubectl logs -f"

# Pods
alias kgp="kubectl get pods"
alias kgpw="kubectl get pods -o wide"
alias kdp="kubectl describe pod"
alias kdelp="kubectl delete pod"

# Deployments
alias kgd="kubectl get deployments"
alias kdd="kubectl describe deployment"
alias kdeld="kubectl delete deployment"

# Services
alias kgs="kubectl get svc"
alias kds="kubectl describe svc"
alias kdels="kubectl delete svc"

# Nodes
alias kgn="kubectl get nodes"
alias kdn="kubectl describe node"

# Namespaces
alias kgns="kubectl get ns"
alias kdns="kubectl describe ns"
alias kcn="kubectl config set-context --current --namespace"

# Contexts
alias kgctx="kubectl config get-contexts"
alias kuc="kubectl config use-context"

# ConfigMaps & Secrets
alias kgcm="kubectl get configmap"
alias kdcm="kubectl describe configmap"
alias kdelcm="kubectl delete configmap"

alias kgsec="kubectl get secret"
alias kdsec="kubectl describe secret"
alias kdelsec="kubectl delete secret"

alias kgi="kubectl get ingress"
alias kdi="kubectl describe ingress"
alias kdeli="kubectl delete ingree"

# Convenience shortcuts
alias kaf.="kubectl apply -f ."
alias kdel.="kubectl delete -f ."

# Output formatting
alias kgy="kubectl get -o yaml"
alias kgj="kubectl get -o json"


###########################################
#   Enable completion for kubectl ALIASES #
###########################################

# kubectl defines the __start_kubectl completion function
# Only register alias completions if the function exists
if type __start_kubectl >/dev/null 2>&1; then
    complete -F __start_kubectl k
    complete -F __start_kubectl kg kgp kgpw kgd kgs kgno kgi
    complete -F __start_kubectl kd kdp kdd kds kdno kgo
    complete -F __start_kubectl kdel kdelp kdeld kdels kdeli
    complete -F __start_kubectl ke kaf kaf. kex
    complete -F __start_kubectl kl klf
    complete -F __start_kubectl kgcm kdcm kgsec kdsec
    complete -F __start_kubectl kgns kdns kcn
    complete -F __start_kubectl kgctx kuc
    complete -F __start_kubectl kgy kgj
else
    echo "Warning: __start_kubectl not found — alias completion disabled."
fi

###########################################
#   END OF FILE                           #
###########################################
 
