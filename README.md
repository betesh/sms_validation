# SmsValidation

This gem does not send SMS messages.  It just makes sure the arguments are valid.

## What are valid arguments for an SMS message?

- Phone number: 10 digits, does not begin with 0 or 1
- Message: Not longer than 160 characters.

## What if my message is longer than 160 characters?

You have 3 choices:
- Truncate the message to the first 160 characters
- Split it into multiple messages
- Raise a SmsValidation::Sms::MessageTooLongError error

You can configure at any time using:

    SmsValidation.configuration.on_message_too_long = :truncate # or :split or :raise_error

It defaults to :raise_error

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sms_validation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sms_validation

## Usage

### Configuration

    SmsValidation.configure do |config|
      config.on_message_too_long = :truncate # or :split or :raise_error
      config.logger = ::Logger.new(STDOUT) # Defaults to ::Rails.logger if ::Rails.logger is defined

      # This DOES NOT change the log_level of the logger--use `config.logger.level = :debug` for that
      # This DOES determine the log level at which messages should be logged.
      # This provides a convenient way to toggle whether this gem should log without interfering with the log level of others processes sharing the logger.
      # For instance, if you're using Rails, you probably don't want to set the log_level to DEBUG, because then ActiveRecord will log every query.
      # But you may still want SmsValidation to log everything it does.
      config.log_at :info

      # OR you may want SmsValidation to log only when you're logging all other DEBUG messages.
      config.log_at :debug
    end

### Validation

    sms = SmsValidation::Sms.new(8889999999, "The quick brown fox jumps over the lazy dog")
    puts sms.phone # => 8889999999
    puts sms.message # => "The quick brown fox jumps over the lazy dog"

    sms = SmsValidation::Sms.new(889999999, "The quick brown fox jumps over the lazy dog")
    # => SmsValidation::Sms::InvalidPhoneNumberError: "Phone number must be ten digits"

    SmsValidation.configuration.on_message_too_long = :split
    sms = SmsValidation::Sms.new(8889999999, "The quick brown fox jumps over the lazy dog" * 4)
    puts sms.phone # => 8889999999
    puts sms.messages # => ["(MSG 1/2): The quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dogThe quick brown ", "(MSG 2/2): fox jumps over the lazy dog"]

    SmsValidation.configuration.on_message_too_long = :truncate
    sms = SmsValidation::Sms.new(8889999999, "The quick brown fox jumps over the lazy dog" * 4)
    puts sms.phone # => 8889999999
    puts sms.message # => ["The quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dogThe quick brown fox jumps over "]

    SmsValidation.configuration.on_message_too_long = :raise_error
    sms = SmsValidation::Sms.new(8889999999, "The quick brown fox jumps over the lazy dog" * 4)
    # => SmsValidation::Sms::MessageTooLongError, "Message cannot be longer than 160 characters"

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sms_validation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
