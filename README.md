# pd-bizops-aether
salesforce data replication to redshift

# usage

```
bundle exec aether --config config.yml --secrets secrets.yml --stage development
```

# config.yml file

```
number_of_processes: 8
readonly_groups: ['x']
stages_to_apply_group_grants: ['x']
redshift:
  staging_schema_suffix: '_sfdc_tmp'
  target_schema_suffix: '_sfdc'
  swap_schema_suffix: '_sfdc_old'
s3:
  bucket: 'x'
```

# secrets.yml file

```
salesforce:
  user: 'x'
  password: 'x'
  client_id: 'x'
  client_secret: 'x'
  is_sandbox: true
redshift:
  user: 'x'
  password: 'x'
  host: 'x'
  port: 5439
  dbname: 'x'
s3:
  aws_access_key: 'x'
  aws_secret_key: 'x'
```
