## RDS Configuration:
- **RDS Engine:** Aurora PostgreSQL
- **Instance Type:** Minimum size
- **Multi-Availability Zone Cluster:** Enabled
- **DB Subnet Group:** One cluster and two replicas (one read and one write)
  - Subnets:
    - public-subnet-1
    - private-subnet-1
    - private-subnet-2
- **Deletion Protection:** Enabled
- **Automatic Minor Upgrades:** Enabled
- **IAM Authentication:** Enabled
- **KMS:** Created and attached

## Network Configuration:
- **VPC Name:** my-rds-vpc
  - **Subnets:**
    - public-subnet-1
    - private-subnet-1
    - private-subnet-2

## Cluster Parameter Group:
- **Timezone:** Changed to Malaysia time zone

## Additional Features:
- **CloudWatch Log Export:** Enabled
- **Enhanced Monitoring:** Enabled
