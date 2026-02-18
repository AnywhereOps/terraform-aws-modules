# TODO: 

- [ ] **RDS Security Group Missing Egress Rules** (`main.tf:71-75`)
  - Relies on AWS default allow-all egress
  - Fix: Add explicit egress rules

- [ ] **Dangerous Default: skip_final_snapshot** (`variables.tf:74`)
  - Default `true` = data loss on destroy
  - Fix: Default to `false`

- [ ] **Dangerous Default: apply_immediately** (`variables.tf:35`)
  - Default `true` = unplanned downtime
  - Fix: Default to `false`

- [ ] **Empty CloudWatch Logs Exports** (`variables.tf:68`)
  - Default `[]` = no logs captured
  - Fix: Default to `["error", "slowquery"]`

- [ ] **Unused cpu_credits_max Map** (`main.tf:27-38`)
  - Defined but never used anywhere
  - Fix: Remove or implement in alarms (could pass to your new alarms module?)

- [ ] **Replica Count No Validation** (`main.tf:49-52`)
  - If `replicas > 16`, silently creates only 16
  - Fix: Add validation block

- [ ] **Inconsistent Subnet Config**
  - `vpc_config.networking.subnets` vs `rds_config.subnets`
  - Fix: Consolidate to single location

- [ ] **No Environment Variable Validation** (`variables.tf:10`)
  - Accepts any string
  - Fix: Add validation for allowed values

- [ ] **Redis Subnets Type Mismatch** (`variables.tf:133, 156`)
  - Type says `list(string)` but default is `null`
  - Fix: Align type and default


- [ ] **No KMS Key Configuration**
  - Uses AWS-managed keys
  - Fix: Add customer-managed KMS key option

- [ ] **No Redis Persistence Config**
  - No RDB/AOF explicitly configured
  - Fix: Add persistence parameters if needed

- [] **Check if upgrading Aurora Module made the Cloudwatch module redundant and can be done direct thru aws**

- [] **Check if upgrading Aurora Module made the snapshot cleaner module redundant and can be done direct thru aws**
