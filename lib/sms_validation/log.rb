require "sms_validation/configuration"

module SmsValidation
  class << self
    def log(*args, &block)
      configuration.logger.__send__(configuration.log_level, *args, &block) if configuration.logger
    end
  end
end
