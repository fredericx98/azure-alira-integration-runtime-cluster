# Azure Alira Integration Runtime Cluster

## Overview

This repository contains Terraform configurations for setting up an Azure Integration Runtime Cluster with Alira. The infrastructure includes virtual networks, subnets, network interfaces, virtual machines, and other Azure resources.

## Prerequisites

- Terraform installed on your local machine.
- Azure CLI installed and authenticated.
- An Azure subscription.

## Getting Started

1. Clone the repository:
   ```sh
   git clone https://github.com/fredericx98/azure-alira-integration-runtime-cluster.git
   cd azure-alira-integration-runtime-cluster
   ```

2. Initialize Terraform:
   ```sh
   terraform init
   ```

3. Apply the Terraform configuration:
   ```sh
   terraform apply
   ```

## Running Tests

To validate the Terraform infrastructure, follow these steps:

1. Navigate to the `test` directory:
   ```sh
   cd test
   ```

2. Initialize Terraform in the `test` directory:
   ```sh
   terraform init
   ```

3. Apply the test Terraform configuration:
   ```sh
   terraform apply
   ```

4. Verify that the test resources are created successfully.

5. Destroy the test resources after verification:
   ```sh
   terraform destroy
   ```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
