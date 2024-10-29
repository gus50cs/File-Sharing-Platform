#!/bin/bash

file="connect_data.sh"

# New organization to add
new_org="org4"

# Read the current value of ORGS from the file
current_orgs=$(grep "^export ORGS=" "$file")

if [ -n "$current_orgs" ]; then
  # Extract the existing ORGS value without single quotes
  existing_orgs=$(echo "$current_orgs" | sed -e "s/^export ORGS=//" -e "s/'//g")
  
  # Append the new organization
  updated_orgs="$existing_orgs $new_org"
  
  # Replace the ORGS line in the file with the updated value in the desired format
  sed -i "s/^export ORGS=.*$/export ORGS='$updated_orgs'/" "$file"
fi 


# New organization to add
new_peer="ws"

# Read the current value of ORGS from the file
current_peers=$(grep "^export PEERS=" "$file")

if [ -n "$current_peers" ]; then
  # Extract the existing ORGS value without single quotes
  existing_peers=$(echo "$current_peers" | sed -e "s/^export PEERS=//" -e "s/'//g")
  
  # Append the new organization
  updated_peers="$existing_peers $new_peer"
  
  # Replace the ORGS line in the file with the updated value in the desired format
  sed -i "s/^export PEERS=.*$/export PEERS='$updated_peers'/" "$file"
fi

# New organization to add
new_port="4012"

# Read the current value of ORGS from the file
current_ports=$(grep "^export PORTS=" "$file")

if [ -n "$current_ports" ]; then
  # Extract the existing ORGS value without single quotes
  existing_ports=$(echo "$current_ports" | sed -e "s/^export PORTS=//" -e "s/'//g")
  
  # Append the new organization
  updated_ports="$existing_ports $new_port"
  
  # Replace the ORGS line in the file with the updated value in the desired format
  sed -i "s/^export PORTS=.*$/export PORTS='$updated_ports'/" "$file"
fi
