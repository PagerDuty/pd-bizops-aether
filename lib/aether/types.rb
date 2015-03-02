require 'date'

module Aether
  module SFTypes
    MAX_CHARACTERVARYING_SIZE = 65535

    class SFDouble
      attr_reader :precision, :scale

      def initialize(precision:, scale:)
        @precision = precision
        @scale = scale
      end

      def to_rs_type
        ::Aether::RSTypes::Numeric.new(precision: precision, scale: scale)
      end
    end

    class Id
      def to_rs_type
        ::Aether::RSTypes::CharacterVarying.new(max_length: 18)
      end
    end

    class Int
      def to_rs_type
        ::Aether::RSTypes::Bigint.new
      end
    end

    class Boolean
      def to_rs_type
        ::Aether::RSTypes::Boolean.new
      end
    end

    class SFTime
      def to_rs_type
        # redshift doesn't have a time field so use a string
        # example format: '00:00:00.000Z'
        ::Aether::RSTypes::CharacterVarying.new(max_length: 13)
      end
    end

    class SFString
      attr_reader :max_length

      def initialize(max_length:)
        # prevent max_length going over redshift's max column size
        @max_length = [MAX_CHARACTERVARYING_SIZE, max_length].min
      end

      def to_rs_type
        ::Aether::RSTypes::CharacterVarying.new(max_length: max_length)
      end
    end

    class SFDatetime
      def to_rs_type
        ::Aether::RSTypes::Timestamp.new
      end
    end

    class Reference < Id
    end

    class Currency < SFDouble
    end

    class SFDate
      def to_rs_type
        ::Aether::RSTypes::RSDate.new
      end
    end

    class Any < SFString
    end

    class Email < SFString
    end

    class Percent < SFDouble
    end

    class Phone < SFString
    end

    class Picklist < SFString
    end

    class Combobox < SFString
    end

    class Multipicklist < SFString
    end

    class Textarea < SFString
    end

    class Encryptedstring < SFString
    end

    class Url < SFString
    end
  end

  module RSTypes
    class Numeric
      attr_reader :precision, :scale

      def initialize(precision:, scale:)
        @precision = precision
        @scale = scale
      end

      def to_rs_schema(field_name:)
        "#{field_name} numeric(#{precision}, #{scale})"
      end

      def transform_from_salesforce(value)
        value
      end
    end

    class Bigint
      def to_rs_schema(field_name:)
        "#{field_name} bigint"
      end

      def transform_from_salesforce(value)
        if value.nil?
          nil
        else
          value.to_i
        end
      end
    end

    class CharacterVarying
      attr_reader :max_length

      def initialize(max_length:)
        @max_length = max_length
      end

      def to_rs_schema(field_name:)
        "#{field_name} character varying(#{max_length})"
      end

      def transform_from_salesforce(value)
        value
      end
    end

    class Boolean
      def to_rs_schema(field_name:)
        "#{field_name} boolean"
      end

      def transform_from_salesforce(value)
        value
      end
    end

    class RSDate
      def to_rs_schema(field_name:)
        "#{field_name} date"
      end

      def transform_from_salesforce(value)
        value
      end
    end

    class Timestamp
      def to_rs_schema(field_name:)
        "#{field_name} timestamp without time zone"
      end

      def transform_from_salesforce(value)
        if value.empty?
          nil
        else
          DateTime.parse(value).strftime('%Y-%m-%d %H:%M:%S.%6N')
        end
      end
    end
  end
end
