class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, coerce_value, datetime_coerce_class)
      super(validator, coerce_value)
      @datetime_coerce_class = datetime_coerce_class
    end

    def coerce_and_validate(value, schema, **_keyword_args)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(String)

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      value, err = pattern_validate(value, schema)
      return [nil, err] if err

      unless @datetime_coerce_class.nil?
        value, err = coerce_date_time(value, schema)
        return [nil, err] if err
      end

      value, err = validate_max_min_length(value, schema)
      return [nil, err] if err

      value, err = validate_email_format(value, schema)
      return [nil, err] if err

      value, err = validate_uuid_format(value, schema)
      return [nil, err] if err

      value, err = validate_date_format(value, schema)
      return [nil, err] if err

      [value, nil]
    end

    private

      # @param [OpenAPIParser::Schemas::Schema] schema
      def coerce_date_time(value, schema)
        return parse_date_time(value, schema) if schema.format == 'date-time'

        [value, nil]
      end

      def parse_date_time(value, schema)
        begin
          return @datetime_coerce_class.parse(value), nil
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid date/
        end

        OpenAPIParser::ValidateError.build_error_result(value, schema)
      end

      # @param [OpenAPIParser::Schemas::Schema] schema
      def pattern_validate(value, schema)
        # pattern support string only so put this
        return [value, nil] unless schema.pattern
        return [value, nil] if value =~ /#{schema.pattern}/

        [nil, OpenAPIParser::InvalidPattern.new(value, schema.pattern, schema.object_reference, schema.example)]
      end

      def validate_max_min_length(value, schema)
        return [nil, OpenAPIParser::MoreThanMaxLength.new(value, schema.object_reference)] if schema.maxLength && value.size > schema.maxLength
        return [nil, OpenAPIParser::LessThanMinLength.new(value, schema.object_reference)] if schema.minLength && value.size < schema.minLength

        [value, nil]
      end

      def validate_email_format(value, schema)
        return [value, nil] unless schema.format == 'email'

        # match? method is good performance.
        # So when we drop ruby 2.3 support we use match? method because this method add ruby 2.4
        #return [value, nil] if value.match?(URI::MailTo::EMAIL_REGEXP)
        return [value, nil] if value.match(URI::MailTo::EMAIL_REGEXP)

        return [nil, OpenAPIParser::InvalidEmailFormat.new(value, schema.object_reference)]
      end

      def validate_uuid_format(value, schema)
        return [value, nil] unless schema.format == 'uuid'

        return [value, nil] if value.match(/[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/)

        return [nil, OpenAPIParser::InvalidUUIDFormat.new(value, schema.object_reference)]
      end

      def validate_date_format(value, schema)
        return [value, nil] unless schema.format == 'date'

        begin
          Date.iso8601(value)
        rescue ArgumentError
          return [nil, OpenAPIParser::InvalidDateFormat.new(value, schema.object_reference)]
        end

        return [value, nil]
      end
  end
end
