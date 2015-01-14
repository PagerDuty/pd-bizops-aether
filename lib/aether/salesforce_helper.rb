require 'aether/types'

module Aether
  module SalesforceHelper
    def self.all_sobject_names(connection:)
      valid_sobjects = connection.describe.keep_if do |sobject|
        # see for latest filters:
        # http://salesforce.stackexchange.com/questions/55604/standard-objects-limits

        # soql limits:
        # http://www.salesforce.com/us/developer/docs/soql_sosl280/Content/sforce_api_calls_soql_limits.htm

        bad_sobjects = []

        # filter ContentDocumentLink due to:
        # Implementation restriction: ContentDocumentLink requires a filter
        # by a single Id, ContentDocumentId or LinkedEntityId
        # using the equals operator
        bad_sobjects << 'ContentDocumentLink'

        # filter EmailStatus due to:
        # InvalidEntity: Entity 'EmailStatus' is not supported by the Bulk API.
        bad_sobjects << 'EmailStatus'

        # InvalidBatch : Failed to process query: INVALID_TYPE_FOR_OPERATION:
        # entity type FeedLike does not support query
        bad_sobjects << 'FeedLike'

        # InvalidBatch : Failed to process query: INVALID_TYPE_FOR_OPERATION:
        # entity type FeedTrackedChange does not support query
        bad_sobjects << 'FeedTrackedChange'

        # InvalidBatch : Failed to process query: MALFORMED_QUERY:
        # Implementation restriction. When querying the Idea Comment object,
        # you must filter using the following syntax: CommunityId =
        # [single ID], Id = [single ID], IdeaId = [single ID],
        # Id IN [list of IDs], or IdeaId IN [list of IDs]
        bad_sobjects << 'IdeaComment'

        # InvalidBatch : Failed to process query:
        # EXTERNAL_OBJECT_UNSUPPORTED_EXCEPTION:
        # Getting all PlatformAction entities is unsupported
        bad_sobjects << 'PlatformAction'

        # InvalidEntity: Entity 'QuoteTemplateRichTextData'
        # is not supported by the Bulk API.
        bad_sobjects << 'QuoteTemplateRichTextData'

        # InvalidBatch : Failed to process query: MALFORMED_QUERY:
        # Implementation restriction: When querying the Vote object, you must
        # filter using the following syntax: ParentId = [single ID],
        # Parent.Type = [single Type], Id = [single ID], or Id IN [list of ID's]
        bad_sobjects << 'Vote'

        # InvalidBatch : Failed to process query: MALFORMED_QUERY:
        # Implementation restriction: CollaborationGroupRecord requires a
        # filter by a single Id, CollaborationGroupId or RecordId using
        # the equals operator
        bad_sobjects << 'CollaborationGroupRecord'

        # We got the following error even though
        # we didn't really query it that often:
        # InvalidBatch : Failed to process query: EXTERNAL_OBJECT_EXCEPTION:
        # Search API Daily Limit Exceeded!
        bad_sobjects << 'DatacloudCompany'
        bad_sobjects << 'DatacloudContact'

        # InvalidBatch : Failed to process query: EXTERNAL_OBJECT_EXCEPTION:
        # This data is no longer available. The "DatacloudSocialHandle" table
        # in the external data source is currently unavailable.
        # Try again later or contact your administrator for help.
        bad_sobjects << 'DatacloudSocialHandle'
        bad_sobjects << 'DcSocialProfileHandle'

        # InvalidBatch : Failed to process query: UNKNOWN_EXCEPTION: An
        # unexpected error occurred. Please include this ErrorId if
        # you contact support: 369403691-29629 (-1440605423)
        bad_sobjects << 'DcSocialProfile'

        # if keyPrefix is nil, you can not query it in the bulk api
        sobject['keyPrefix'] && !bad_sobjects.include?(sobject['name'])
      end

      valid_sobject_names = valid_sobjects.map do |sobject|
        sobject['name']
      end

      valid_sobject_names
    end

    def self.field_to_type(connection:, sobject_name:)
      sobject_describe = connection.describe(sobject_name)

      # TODO for string types, we could look at the byteLength
      # for larger strings, we could truncate or split into multiple fields

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
          # TODO may need to extract 'digits' from the field type 'int'
          sf_fields[f.name] = SFTypes::Int.new
        when 'boolean'
          sf_fields[f.name] = SFTypes::Boolean.new
        when 'string'
          sf_fields[f.name] = SFTypes::SFString.new
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
          sf_fields[f.name] = SFTypes::Email.new
        when 'location'
          sf_fields[f.name] = SFTypes::Location.new
        when 'percent'
          sf_fields[f.name] = SFTypes::Percent.new(
            precision: f.precision,
            scale: f.scale)
        when 'phone'
          sf_fields[f.name] = SFTypes::Phone.new
        when 'picklist'
          sf_fields[f.name] = SFTypes::Picklist.new
        when 'multipicklist'
          sf_fields[f.name] = SFTypes::Multipicklist.new
        when 'textarea'
          sf_fields[f.name] = SFTypes::Textarea.new
        when 'encryptedstring'
          sf_fields[f.name] = SFTypes::Encryptedstring.new
        when 'url'
          sf_fields[f.name] = SFTypes::Url.new
        when 'combobox'
          sf_fields[f.name] = SFTypes::Combobox.new
        when 'base64'
          # base64 unsupported by the bulk api
          # FeatureNotEnabled : Binary field not supported
          #sf_fields[f.name] = SFTypes::SFBase64.new
        when 'anyType'
          sf_fields[f.name] = SFTypes::Any.new
        when 'time'
          sf_fields[f.name] = SFTypes::SFTime.new
        when 'address'
          # InvalidBatch : Failed to process query: FUNCTIONALITY_NOT_ENABLED:
          # Selecting compound data not supported in Bulk Query
          #sf_fields[f.name] = SFTypes::Address.new
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
