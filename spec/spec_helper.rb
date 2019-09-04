require "bundler/setup"
require 'dotenv/load'
require 'securerandom'
require "shared_config"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def rand_string
    return SecureRandom.hex(12)
  end

end
