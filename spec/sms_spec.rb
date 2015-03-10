require "sms_validation/sms"
require "sms_validation/log"
require "logger"

describe SmsValidation::Sms do
  let(:phone_number_length) { 10 }
  let(:phone_number) { "8" * phone_number_length }
  let(:message) { "TEXT MESSAGE FROM ME TO YOU" }
  let(:on_message_too_long) { :raise_error }

  before(:each) do
    SmsValidation.instance_variable_set("@configuration", nil)
    SmsValidation.configure do |config|
      config.log_at(:info)
      config.logger = logger
      config.on_message_too_long = on_message_too_long
    end
  end

  def it_should_not_log
    described_class::LOG_LEVEL_OPTIONS.each do |log_level|
      expect(logger).not_to receive(log_level)
    end
  end

  def it_should_log(text, options={})
    expect(logger).to receive(options[:at] || :info) do |&arg|
      expect(arg.call).to eq(text)
    end
  end

  subject { described_class.new(phone_number, message) }

  shared_examples_for :all_specs do
  describe "phone number" do
    describe "when 9 digits" do
      let(:phone_number_length) { 9 }

      it "should raise an error" do
        expect{subject}.to raise_error(described_class::InvalidPhoneNumberError, "Phone number must be ten digits")
      end
    end

    describe "when 11 digits" do
      let(:phone_number_length) { 11 }

      it "should raise an error" do
        expect{subject}.to raise_error(described_class::InvalidPhoneNumberError, "Phone number must be ten digits")
      end
    end

    describe "when it starts with a 0" do
      let(:phone_number) { "0" + "8" * (phone_number_length - 1) }

      it "should raise an error" do
        expect{subject}.to raise_error(described_class::InvalidPhoneNumberError, "Phone number cannot begin with a \"0\"")
      end
    end

    describe "when it starts with a 1" do
      let(:phone_number) { "1" + "8" * (phone_number_length - 1) }

      it "should raise an error" do
        expect{subject}.to raise_error(described_class::InvalidPhoneNumberError, "Phone number cannot begin with a \"1\"")
      end
    end

    it "should prepend a '1' and be safe from changes" do
      expected_phone_number = "1#{phone_number}"
      subject
      phone_number[1..3] = ''
      expect(subject.phone).to eq(expected_phone_number)
    end
  end

  describe "message" do
    describe "when blank" do
      let(:message) { "" }

      it "raises an error" do
        expect{subject}.to raise_error(described_class::InvalidMessageError, "Message cannot be blank")
      end
    end

    describe "when longer than 160 characters" do
      describe "when on_message_too_long = :truncate" do
        let(:on_message_too_long) { :truncate }
        let(:message) { "A"+"ABCDEFGHIJ"*16 }

        it "is truncated to the first 160 characters" do
          expect(subject.message).to eq(message[0,160])
          expect(subject.messages).to eq([message[0,160]])
        end

        it "should be safe from changing" do
          expected_message = "#{message[0,160]}"
          subject
          message[1..3] = ''
          expect(subject.message).to eq(expected_message)
          expect(subject.messages).to eq([expected_message])
        end
      end

      describe "when on_message_too_long = :raise_error" do
        let(:on_message_too_long) { :raise_error }
        let(:message) { "A"*161 }

        it "raises an error" do
          expect{subject}.to raise_error(described_class::MessageTooLongError, "Message cannot be longer than 160 characters")
        end
      end

      describe "when on_message_too_long = :split" do
        let(:on_message_too_long) { :split }

        describe "when it's an even split" do
          let(:message) { "ABCDEFGHIJ"*58 }

          it "should be split into multiple messages" do
            expect(subject.messages).to eq(["(MSG 1/4): #{message[0,145]}", "(MSG 2/4): #{message[145,145]}", "(MSG 3/4): #{message[290,145]}", "(MSG 4/4): #{message[435,145]}"])
            expect{subject.message}.to raise_error(StandardError, "This message was split because it is too long to fit into a single SMS.  Instead of #message, use #messages or change SmsValidation.configuration.on_message_too_long to something other than :split")
          end
        end

        describe "when it's not an even split" do
          let(:message) { "ABCDEFGHIJ"*32 }

          it "should be split into multiple messages" do
            expect(subject.messages).to eq(["(MSG 1/3): #{message[0,145]}", "(MSG 2/3): #{message[145,145]}", "(MSG 3/3): #{message[290..-1]}"])
            expect{subject.message}.to raise_error(StandardError, "This message was split because it is too long to fit into a single SMS.  Instead of #message, use #messages or change SmsValidation.configuration.on_message_too_long to something other than :split")
          end

          it "should be safe from changing" do
            expected_messages = ["(MSG 1/3): #{message[0,145]}", "(MSG 2/3): #{message[145,145]}", "(MSG 3/3): #{message[290..-1]}"]
            subject
            message[1..3] = ''
            expect(subject.messages).to eq(expected_messages)
          end
        end
      end
    end

    [:raise_error, :split, :truncate].each do |value|
      describe "when on_message_too_long = :#{value}" do
        let(:on_message_too_long) { value }

        it "should be safe from changing the message" do
          expected_message = "#{message}"
          subject
          message[1..3] = ''
          expect(subject.message).to eq(expected_message)
        end

        describe "when the initial message is 160 characters" do
          let(:message) { "A"*160 }

          it "does not change" do
            expect(subject.message).to eq(message)
            expect(subject.messages).to eq([message])
          end
        end
      end
    end
  end
  end

  it_behaves_like :all_specs do
    let(:logger) { ::Logger.new('/dev/null') }
  end

  it_behaves_like :all_specs do
    let(:logger) { nil }
  end
end
