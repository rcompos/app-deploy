## Summary

This Python script copies secrets from a source vault path to destination vault path. This automates populating secrets from a central place to site specific vault paths. configuration is defined in `config.yaml` file. The script performs the following key tasks:

- Loads the configuration from `config.yaml`, which includes `base_path`, a list of `secrets`, and `destination_sites`.
- Validates the presence of required fields and logs errors if any are missing.

- Uses vault CLI to do the following with current login context (using your shell environment, including any VAULT_TOKEN, VAULT_ADDR, etc.). 
  
  - Retrieve secret data from source paths.
  - Check if the secret already exists at the destination path.
  - Optionally override existing secrets based on the `override` flag in the configuration.
  - Copies secrets from the source Vault path to the destination path.

- The destination path is dynamically formatted by combining `base_path`, the `site`, and the `namespace` from the configuration. It flattens the source path by replacing `/` with `-` .  For a secret source path `basepath/ngc/registry-nke-imagepull`, the destination path will be formatted as `basepath/sites/<site>/<namespace>/ngc-registry-nke-imagepull`. This ensures a standardized naming convention for secrets across different environments.

### Prereqs
- [vault-cli](https://gitlab-master.nvidia.com/kaizen/services/vault/docs/-/tree/main/vault-agent#installing-on-mac-os)
- NKE engineers should join the DL - [nkek8s_admin](https://dlrequest/GroupID/Groups/Properties?identity=M2IzYTQxMDExODIwNDc1NTgwZTZlMjU5ZWFiNDM5NmJ8Z3JvdXA=) to read/write secrets at the path `secrets/groups/nkek8s/*`

### Run
- Login to vault to set the token before running the script
  ```
  export VAULT_ADDR=https://prod.vault.nvidia.com VAULT_NAMESPACE=ngc
  vault login -method=oidc -path=oidc role=ngc
  ``` 
- Run the script
  ```
  python3 -m venv .venv
  source .venv/bin/activate
  pip3 install -r requirements.txt
  python3 vault-copy.py
  ```
- Config explained
  ```
  # base_path for secrets in vault
  base_path: "/secrets/groups/nkek8s"  
  secrets:
    - namespace: "kubernetes-replicator" # namespace in cluster where a secret will be created. we setup vault policies based on namespace. hence, we expect to secrets be stored at these paths
      source: "ngc/registry-nke-imagepull" # source_path to copy the secret from (excluding the base_path)
      override: true # decides whether secrets should be overriden if already exists at destination, 
  # list of destinations sites. vault paths for the provided sites will be populated with the script
  destination_sites: 
    - nke-site-forge-az24
  ```