require 'csv'
require 'parallel'

require 'aether/salesforce_helper'
require 'aether/redshift_helper'
require 'aether/types'

module Aether
  def self.sync(connections:, config:, targets:)
    staging_schema = config['redshift']['staging_schema']
    RedshiftHelper::recreate_schema(
      connection: connections.redshift,
      schema_name: staging_schema
    )

    targets ||= SalesforceHelper::all_sobject_names(
      connection: connections.salesforce)

    Parallel.map(targets, in_processes: config['number_of_processes']) do |sobject_name|
      sync_sobject(
        connections: connections,
        config: config,
        sobject_name: sobject_name)
    end

    target_schema = config['redshift']['target_schema']
    swap_schema = config['redshift']['swap_schema']

    connections.reestablish_redshift
    RedshiftHelper::swap_schemas(
      connection: connections.redshift,
      staging_schema: staging_schema,
      target_schema: target_schema,
      swap_schema: swap_schema)
  end

  private

  def self.sync_sobject(connections:, config:, sobject_name:)
    sf_fields = SalesforceHelper::field_to_type(
      connection: connections.salesforce,
      sobject_name: sobject_name)

    staging_schema = config['redshift']['staging_schema']
    rs_table = sobject_name.downcase

    rs_fields = get_rs_fields(sf_fields: sf_fields)

    populate_table(
      connections: connections,
      config: config,
      target_schema: staging_schema,
      target_table: rs_table,
      sobject_name: sobject_name,
      sf_fields: sf_fields,
      rs_fields: rs_fields)
  end

  def self.populate_table(
    connections:,
    config:,
    target_schema:,
    target_table:,
    sobject_name:,
    sf_fields:,
    rs_fields:)

    # get all data

    headers = rs_fields.keys

    query = "SELECT #{sf_fields.keys.join(', ')} FROM #{sobject_name}"

    begin
      sobjects = connections.salesforce_bulk.query(sobject_name, query)
    rescue RuntimeError => e
      puts "Got exception while querying '#{query}'"
      puts e

      return
    end

    csv_contents = CSV.generate(headers: true, write_headers: true) do |csv|
      csv << headers

      sobjects[:results].each do |sobject|
        csv << sobject.map do |sobject_field, sf_type|
          sobject_value = sobject[sobject_field]
          rs_type = rs_fields[sobject_field.downcase]

          rs_type.transform_from_mysql(sobject_value)
        end
      end
    end

    # upload to s3
    # TODO use gzip or lzo compression
    bucket_name = config['s3']['bucket']
    bucket = connections.s3.buckets[bucket_name]
    object_name = config['s3']['object_prefix'] + '/' + target_table + '.csv'
    object = bucket.objects[object_name]
    object.write(csv_contents)

    # reestablish pg connection:
    # https://devcenter.heroku.com/articles/forked-pg-connections#forked-environments
    connections.reestablish_redshift

    create_staging_table(
      connection: connections.redshift,
      target_schema: target_schema,
      target_table: target_table,
      structure: rs_fields)

    aws_access_credentials =
      "'aws_access_key_id=#{connections.aws_access_key};" +
      "aws_secret_access_key=#{connections.aws_secret_key}'"

    # call copy to redshift
    copy_query = [
      "COPY #{target_schema}.#{target_table} (#{headers.join(', ')})",
      "FROM 's3://#{bucket_name}/#{object_name}'",
      'CREDENTIALS',
      aws_access_credentials,
      'CSV',
      'IGNOREHEADER 1',
      'TRUNCATECOLUMNS'
    ].join(' ')
    connections.redshift.exec(copy_query)

    # cleanup
    object.delete
  end

  def self.create_staging_table(
    connection:,
    target_schema:,
    target_table:,
    structure:)

    create_column_fragmets = structure.map do |field_name, rs_type|
      rs_type.to_rs_schema(field_name: field_name)
    end

    create_table_query = [
      "CREATE TABLE #{target_schema}.#{target_table}",
      '(',
      create_column_fragmets.join(', '),
      ')'
    ].join(' ')

    connection.exec(create_table_query)
  end

  def self.get_rs_fields(sf_fields:)
    sf_fields.reduce({}) do |acc, (field, type)|
      key = field.downcase
      value = type.to_rs_type

      acc.merge({key => value})
    end
  end
end
