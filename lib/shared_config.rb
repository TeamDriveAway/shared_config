require "shared_config/version"
require 'aws-sdk-s3'

module SharedConfig
  class Error < StandardError; end
  class S3
    class << self
      def load(*group_names)
        groups = ObjectKeys.from_group_names(*group_names).map{|object_key| SharedConfig::Group.new(object_key: object_key)}
        groups.each(&:load)
      end
    end
  end

  class ObjectKeys
    class << self
      def from_group_names(*group_names)
        return group_names.flatten.map {|group_name| self.from_group_name(group_name)}
      end

      def from_group_name(group_name)
        filename = group_name =~ /\.json$/ ? group_name : "#{group_name}.json"
        elements = [ENV['SHARED_CONFIG_PATH_ROOT'], filename]

        return File.join(elements.compact.reject(&:empty?))
      end
    end
  end

  class EnvVar
    def self.set(key, value)
      puts "---- #{key}" if ENV['DEBUG_SHARED_CONFIG']
      ENV[key] = "#{value}"
    end
  end

  class Group
    attr_reader :object_key, :object
    def initialize(object_key:, object: nil)
      @object_key=object_key
      @object = object
      self.load_object unless object
    end

    def load
      self.load_json(self.object).each{|key, value|
        EnvVar.set(key, value)
      }
    end

    def load_object
      puts self.object_key
      @object=self.client.get_object(bucket: ENV['S3_CONFIG_BUCKET'], key: self.object_key)
    end

    def load_json(object)
      string = object.body.read
      return {} if string.nil? || string.empty?
      return  JSON.parse(string)
    end

    def client
      return Aws::S3::Client.new
    end

    def self.all
      return []
    end
  end
end
