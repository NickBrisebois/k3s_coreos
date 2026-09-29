# vim: set syntax=bash:
#!/usr/bin/env bash

main() {{
  export K3S_KUBECONFIG_MODE=0o644
  export K3S_TOKEN={master_token}
  export K3S_URL={master_url}

  curl -sfL https://get.k3s.io | sh -
  return 0
}}
main
