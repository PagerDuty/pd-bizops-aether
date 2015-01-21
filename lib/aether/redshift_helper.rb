module Aether
  module RedshiftHelper
    def self.recreate_schema(connection:, schema_name:)
      query = [
        "DROP SCHEMA IF EXISTS #{schema_name} CASCADE",
        "CREATE SCHEMA IF NOT EXISTS #{schema_name}"
      ].join('; ')

      connection.exec(query)
    end

    def self.swap_schemas(
      connection:,
      staging_schema:,
      target_schema:,
      swap_schema:)

      target_schema_exists = RedshiftHelper::schema_exists?(
        connection: connection,
        schema_name: target_schema
      )

      if target_schema_exists
        connection.exec("DROP SCHEMA IF EXISTS #{swap_schema} CASCADE")

        swap_query = [
          'BEGIN READ WRITE',
          "ALTER SCHEMA #{target_schema} RENAME TO #{swap_schema}",
          "ALTER SCHEMA #{staging_schema} RENAME TO #{target_schema}",
          'COMMIT'
        ].join('; ')

        connection.exec(swap_query)

        connection.exec("DROP SCHEMA #{swap_schema} CASCADE")
      else
        connection.exec(
          "ALTER SCHEMA #{staging_schema} RENAME TO #{target_schema}"
        )
      end
    end

    private

    def self.schema_exists?(connection:, schema_name:)
      query = [
        "SELECT 1 FROM information_schema.schemata",
        "WHERE schema_name = '#{schema_name}'",
        'LIMIT 1'
      ].join(' ')

      connection.exec(query).count > 0
    end
  end
end
