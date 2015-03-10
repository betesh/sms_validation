module SmsValidation
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end

  class Configuration
    ON_MESSAGE_TOO_LONG_OPTIONS = [:truncate, :raise_error, :split]
    LOG_LEVEL_OPTIONS = [:fatal, :error, :warn, :info, :debug]

    attr_reader :logger, :log_level, :on_message_too_long
    def initialize
      @logger = Rails.logger if defined?(::Rails.logger)
      @log_level = :debug
      @on_message_too_long = :raise_error
    end

    def on_message_too_long=(action)
      raise ArgumentError, "SmsValidation.configuration.on_message_too_long must be included in: #{options_string(ON_MESSAGE_TOO_LONG_OPTIONS)}.  It cannot be \"#{action}\"" unless ON_MESSAGE_TOO_LONG_OPTIONS.include?(action)
      @on_message_too_long = action
    end

    def log_at(level)
      validate_logger(@logger, level)
      @log_level = level
    end

    def logger=(_logger)
      validate_logger(_logger, @log_level)
      @logger = _logger
    end

    private
      def validate_logger(_logger, level)
        raise ArgumentError, "SmsValidation.configuration.log_at argument must be included in: #{options_string(LOG_LEVEL_OPTIONS)}.  It cannot be \"#{level}\"" unless LOG_LEVEL_OPTIONS.include?(level)
        raise ArgumentError, "SmsValidation.configuration.logger must respond to \"#{level}\"" if _logger && !_logger.respond_to?(level)
      end

      def options_string(array)
        "[:#{array.join(", :")}]"
      end
  end
end
