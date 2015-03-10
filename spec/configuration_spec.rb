require "sms_validation/configuration"
require "sms_validation/log"
require "logger"

describe SmsValidation::Configuration do
  before(:each) do
    SmsValidation.instance_variable_set("@configuration", nil)
  end

  describe "logger" do
    let(:logger) { ::Logger.new('/dev/null') }

    def it_should_not_log
      text = "Some info"
      described_class::LOG_LEVEL_OPTIONS.each do |log_level|
        expect(logger).not_to receive(log_level)
      end
      expect{SmsValidation.log { text } }.to_not raise_error
    end

    def it_should_log_at(log_level)
      text = "Some info"
      expect(logger).to receive(log_level) do |&arg|
        expect(arg.call).to eq(text)
      end
      expect{SmsValidation.log { text } }.to_not raise_error
    end

    def when_the_logger_is_configured
      SmsValidation.configuration.logger = logger
    end

    [:fatal, :error, :warn, :info, :debug].each do |log_level|
      describe "can log at #{log_level}" do
        let(:log_level) { log_level }
        it "should allow log level ':#{log_level}'" do
          SmsValidation.configuration.log_at(log_level)
          when_the_logger_is_configured
          it_should_log_at(log_level)
        end
      end
    end

    it "should default to log level debug" do
      when_the_logger_is_configured
      it_should_log_at(:debug)
    end

    it "should default to Rails.logger when Rails.logger is defined" do
      stub_const("Rails", double)
      allow(Rails).to receive(:logger).and_return(logger)
      it_should_log_at(:debug)
    end

    it "should not attempt to default to Rails.logger when Rails is defined but Rails.logger is defined" do
      stub_const("Rails", double)
      it_should_not_log
    end

    it "can be nil" do
      SmsValidation.configuration.logger = nil
      it_should_not_log
    end

    it "should not allow log level news and should remain in a valid state" do
      expect{SmsValidation.configuration.log_at(:news)}.to raise_error(ArgumentError, "SmsValidation.configuration.log_at argument must be included in: [:fatal, :error, :warn, :info, :debug].  It cannot be \"news\"")
      SmsValidation.configuration.logger = logger
      it_should_log_at(:debug)
    end

    it "should not allow log level that the logger does not respond_to when the logger is created before log level is set and should remain in a valid state" do
      SmsValidation.configuration.logger = logger
      allow(logger).to receive(:respond_to?).with(:warn).and_return(false)
      expect{SmsValidation.configuration.log_at(:warn)}.to raise_error(ArgumentError, "SmsValidation.configuration.logger must respond to \"warn\"")
      it_should_log_at(:debug)
    end

    it "should not allow log level that the logger does not respond_to when the logger is created after log level is set and should remain in a valid state" do
      allow(logger).to receive(:respond_to?).with(:warn).and_return(false)
      SmsValidation.configuration.log_at(:warn)
      expect{SmsValidation.configuration.logger = logger}.to raise_error(ArgumentError, "SmsValidation.configuration.logger must respond to \"warn\"")
      it_should_not_log
    end
  end

  describe "on_message_too_long" do
    it "should default to :raise_error" do
      expect(SmsValidation.configuration.on_message_too_long).to eq(:raise_error)
    end

    [:raise_error, :split, :truncate].each do |value|
      describe value.to_s do
        let(:value) { value }
        it "should be an allowed value" do
          expect{SmsValidation.configuration.on_message_too_long = value}.to_not raise_error
          expect(SmsValidation.configuration.on_message_too_long).to eq(value)
        end

        it "should not allow other values and should remain in a valid state" do
          SmsValidation.configuration.on_message_too_long = value
          expect{SmsValidation.configuration.on_message_too_long = :do_nothing}.to raise_error(ArgumentError, "SmsValidation.configuration.on_message_too_long must be included in: [:truncate, :raise_error, :split].  It cannot be \"do_nothing\"")
          expect(SmsValidation.configuration.on_message_too_long).to eq(value)
        end
      end
    end
  end

  it "can yield" do
    SmsValidation.configure do |config|
      config.on_message_too_long = :split
    end
    expect(SmsValidation.configuration.on_message_too_long).to eq(:split)
  end
end
