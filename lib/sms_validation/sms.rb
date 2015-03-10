require "sms_validation/log"

module SmsValidation
  class Sms
    class InvalidPhoneNumberError < ::ArgumentError; end
    class InvalidMessageError < ::ArgumentError; end
    class MessageTooLongError < ::ArgumentError; end

    MAX_LENGTH = 160
    MAX_SECTION_LENGTH = MAX_LENGTH - "(MSG XXX/XXX): ".size
    MESSAGE_WHEN_SPLIT_MESSAGE = "This message was split because it is too long to fit into a single SMS.  Instead of #message, use #messages or change SmsValidation.configuration.on_message_too_long to something other than :split"

    attr_reader :phone, :messages

    def initialize(phone, message)
      phone = phone.to_s
      raise InvalidPhoneNumberError, "Phone number must be ten digits" unless /\A[0-9]{10}\z/.match(phone)
      raise InvalidPhoneNumberError, "Phone number cannot begin with a \"#{phone[0]}\"" if ['0','1'].include?(phone[0].to_s)
      raise InvalidMessageError, "Message cannot be blank" if message.empty?
      SmsValidation.configuration.logger.warn { "WARNING: Some characters may be lost because the message must be broken into at least 1000 sections" } if message.size > (999 * MAX_SECTION_LENGTH)
      @messages = (message.size > MAX_LENGTH) ? SmsValidation::Sms.__send__(SmsValidation.configuration.on_message_too_long, message) : [message.dup]
      @phone = "1#{phone}"
    end

    def message
      @message ||= begin
        raise StandardError, MESSAGE_WHEN_SPLIT_MESSAGE unless 1 == messages.size
        messages.first
      end
    end

    class << self
      def raise_error(message)
        raise MessageTooLongError, "Message cannot be longer than #{MAX_LENGTH} characters"
      end

      def truncate(message)
        truncated_message = message[0,MAX_LENGTH]
        SmsValidation.log { "Truncating message due to length.  Message was: \"#{message}\" but will now be \"#{truncated_message}\"" }
        [truncated_message]
      end

      def section_counter(size)
        size / MAX_SECTION_LENGTH + ((size % MAX_SECTION_LENGTH).zero? ? 0 : 1)
      end

      def split(message)
        sections = section_counter(message.size)
        SmsValidation.log { "Splitting message into #{sections} messages due to length." }
        split_message = (sections - 1).times.collect do |i|
          first_char = i * MAX_SECTION_LENGTH
          SmsValidation.log { "Section ##{i + 1} of ##{sections} contains characters #{first_char + 1} thru #{first_char + MAX_SECTION_LENGTH} of #{message.size}" }
          "(MSG #{i+1}/#{sections}): #{message[first_char, MAX_SECTION_LENGTH]}"
        end
        first_char = (sections-1)*MAX_SECTION_LENGTH
        SmsValidation.log { "Section ##{sections} of ##{sections} contains characters #{first_char + 1} thru #{message.size} of #{message.size}" }
        split_message << "(MSG #{sections}/#{sections}): #{message[first_char..-1]}"
      end
    end
  end
end
