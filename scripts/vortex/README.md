# Vortex

## Installation

### Prerequisites
To make use of the installation scripts, we first need to ensure that we have the necessary dependencies.

* kubectl - The Kubernetes client tool used for interacting with the Kubernetes cluster.
* jq - A lightweight and flexible command-line JSON processor
* helm - A package manager for Kubernetes.

> IMPORTANT NOTE: You need to be authenticated with the corresponding kubernetes clusterin order to use these commands

### Step 1: Install Vault with Helm chart
The first step is to install Vault by executing `install.vault.sh`, as the rest of the components are dependent on Vault.

### Step 2: Initialize and Unseal Vault
The second step is to execute the `install.sh` script, which will complete the installation.

### Problems with the installation process
In case any issues arise during the installation process, we should start from scratch. To do this, we must run the uninstall.sh command.