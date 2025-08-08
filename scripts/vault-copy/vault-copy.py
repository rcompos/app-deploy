import subprocess
import json
import sys
import logging
import yaml
import os
import re


logging.basicConfig(level=logging.INFO, stream=sys.stdout)

# Constants for config file paths
CONFIG_FILE_PATH = 'config.yaml'

# mask args in cmd 
def mask_all_key_value_args(command):
    # If command is a list, join it into a string for processing
    if isinstance(command, list):
        command_str = ' '.join(command)
    else:
        command_str = command

    # Replace all key=value patterns with key=***
    masked_command = re.sub(r'(\S+)=([^\s]+)', r'\1=***', command_str)
    return masked_command

# Vault CLI Command execution
def run_vault_cli(command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        logging.debug(f"Command execution failed with error: {e.stderr}")
        # raise error with the masked msg
        raise RuntimeError(f"Failed to execute cmd: [{mask_all_key_value_args(e.cmd)}]\n Error: {e.stderr}") from None

# Read secret from Vault using the given path
def read_secret(path):
    command = ['vault', 'kv', 'get', '-format=json', f"{path}"]
    output = run_vault_cli(command)
    secret = json.loads(output)
    return secret.get('data', {}).get('data', {})

# Check if a secret exists at the specified path
def secret_exists(path):
    command = ["vault", "kv", "get", "-format=json", f"{path}"]
    try:
        result = run_vault_cli(command)
        secret_data = json.loads(result)
        return 'data' in secret_data and 'data' in secret_data['data']
    except RuntimeError as e:
        # Check if the error message contains '404' (secret not found)
        if '404' in str(e):
            logging.debug(f"Secret doesn't exist (404 error) at {path} . Continuing...")
            return False
        else:
            logging.error(f"Unexpected error when checking secret at {path}: {e}")
            raise  # Re-raise the exception for non-404 errors

# Write secret data to the destination Vault path
def write_secret(path, secret_data):
    command = ['vault', 'kv', 'put', f"{path}"] + [f"{key}={value}" for key, value in secret_data.items()]
    run_vault_cli(command)

# Copy secret from source to destination, overriding if necessary
def copy_secret(source, destination, should_override):
    logging.info(f"Copying secret from {source} to {destination}")

    # Read the secret data from the source
    secret_data = read_secret(source)
    
    # Check if the secret exists at the destination and decide whether to override
    if secret_exists(destination):
        if not should_override:
            logging.info(f"Secret already exists at {destination}, skipping.")
            return
        logging.warning(f"Secret already exists at {destination}, it will be overridden.")

    write_secret(destination, secret_data)
    logging.info(f"Secret copied successfully from {source} --> {destination}")

# Format destination path by flattening the source path
def get_destination_path(site, secret, base_path):
    namespace = secret["namespace"]
    source_path = secret["source"]

    flattened_source_path = "-".join(source_path.split("/"))
    destination_path = f"{base_path}/sites/{site}/{namespace}/{flattened_source_path}"
    logging.debug(f"Formatted destination path: {destination_path}")

    return destination_path

# Load configuration from a YAML file
def load_config():
    try:
        with open(CONFIG_FILE_PATH, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        logging.error(f"Config file '{CONFIG_FILE_PATH}' not found.")
        sys.exit(1)
    except yaml.YAMLError as e:
        logging.error(f"Error parsing '{CONFIG_FILE_PATH}': {e}")
        sys.exit(1)

def main():
    # Load and validate config
    config = load_config()
    base_path = config.get('base_path', "")
    secrets = config.get('secrets', [])
    sites = config.get('destination_sites', [])

    # Validate required config values
    if not base_path:
        logging.error("'base_path' must be specified in config file and cannot be empty.")
        sys.exit(1)
    if not sites:
        logging.error("No 'destination_sites' specified in config file.")
        sys.exit(1)
    if not secrets:
        logging.error("No 'secrets' specified in config file.")
        sys.exit(1)

    # Process each site and secret
    for site in sites:
        print(f"\n===== Site - {site} =====")
        for secret in secrets:
            print(f"\n")
            source_path = secret.get('source', "")
            namespace = secret.get('namespace', "")
            should_override = secret.get('override', False)

            # Validate secret configuration
            if not source_path or not namespace:
                logging.error(f"Missing 'source' or 'namespace' in secret configuration: {secret}")
                continue

            # Prepare source and destination paths
            full_source_path = f"{base_path}/{source_path}"
            destination_path = get_destination_path(site, secret, base_path)

            # Copy the secret
            copy_secret(full_source_path, destination_path, should_override)

if __name__ == "__main__":
    main()
