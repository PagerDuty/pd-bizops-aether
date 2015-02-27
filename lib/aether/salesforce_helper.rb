require 'aether/types'

module Aether
  module SalesforceHelper
    def self.all_sobject_names(connection:)
      connection.describe.map do |sobject|
        sobject['name']
      end
    end

    def self.field_to_type(connection:, sobject_name:)
      sobject_describe = connection.describe(sobject_name)

      sf_fields = {}
      sobject_describe.fields.each do |f|
        case f.type
        when 'double'
          sf_fields[f.name] = SFTypes::SFDouble.new(
            precision: f.precision,
            scale: f.scale)
        when 'id'
          sf_fields[f.name] = SFTypes::Id.new
        when 'int'
          sf_fields[f.name] = SFTypes::Int.new
        when 'boolean'
          sf_fields[f.name] = SFTypes::Boolean.new
        when 'string'
          sf_fields[f.name] = SFTypes::SFString.new(
            max_length: f.byteLength
          )
        when 'datetime'
          sf_fields[f.name] = SFTypes::SFDatetime.new
        when 'reference'
          sf_fields[f.name] = SFTypes::Reference.new
        when 'currency'
          sf_fields[f.name] = SFTypes::Currency.new(
            precision: f.precision,
            scale: f.scale)
        when 'date'
          sf_fields[f.name] = SFTypes::SFDate.new
        when 'email'
          sf_fields[f.name] = SFTypes::Email.new(
            max_length: f.byteLength
          )
        when 'location'
          # location unsupported by bulk api
        when 'percent'
          sf_fields[f.name] = SFTypes::Percent.new(
            precision: f.precision,
            scale: f.scale)
        when 'phone'
          sf_fields[f.name] = SFTypes::Phone.new(
            max_length: f.byteLength
          )
        when 'picklist'
          sf_fields[f.name] = SFTypes::Picklist.new(
            max_length: f.byteLength
          )
        when 'multipicklist'
          sf_fields[f.name] = SFTypes::Multipicklist.new(
            max_length: f.byteLength
          )
        when 'textarea'
          sf_fields[f.name] = SFTypes::Textarea.new(
            max_length: f.byteLength
          )
        when 'encryptedstring'
          sf_fields[f.name] = SFTypes::Encryptedstring.new(
            max_length: f.byteLength
          )
        when 'url'
          sf_fields[f.name] = SFTypes::Url.new(
            max_length: f.byteLength
          )
        when 'combobox'
          sf_fields[f.name] = SFTypes::Combobox.new(
            max_length: f.byteLength
          )
        when 'base64'
          # base64 unsupported by the bulk api
          # FeatureNotEnabled : Binary field not supported
        when 'anyType'
          sf_fields[f.name] = SFTypes::Any.new(
            max_length: f.byteLength
          )
        when 'time'
          sf_fields[f.name] = SFTypes::SFTime.new
        when 'address'
          # InvalidBatch : Failed to process query: FUNCTIONALITY_NOT_ENABLED:
          # Selecting compound data not supported in Bulk Query
        else
          raise "unknown sfdc type: '#{f.type}' on sobject: '#{sobject_name}' on field: '#{f.name}'"
        end
      end

      # sort keys so that we will always get a consistent hash
      sf_fields = sf_fields.sort { |x, y| x.first.downcase <=> y.first.downcase }

      sf_fields.to_h
    end
  end
end
