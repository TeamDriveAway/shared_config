require "shared_config/version"
require 'aws-sdk-s3'

module SharedConfig
  class Error < StandardError; end
  class S3
    class << self
      def load(*group_names)

        if (group_names = ObjectKeys.from_group_names(*group_names)).any?
          groups = group_names.map{|object_key|
            SharedConfig::Group.new(object_key: object_key)
          }
        else
          groups = SharedConfig::Group.all
        end
        groups.each(&:load)
        return "#{groups.length} groups loaded"
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
    attr_reader :object_key, :object_summary
    def initialize(object_key: nil, object_summary: nil)
      @object_key=object_key
      @object_summary = object_summary
      self.load_object_summary unless object_summary
    end

    def load
      puts "Loading Shared Config - #{self.object_key}" if ENV['DEBUG_SHARED_CONFIG']
      self.load_json(self.object_summary).each{|key, value|
        EnvVar.set(key, value)
      }
    end

    def load_object_summary
      @object_summary=Aws::S3::ObjectSummary.new(self.class.bucket.name, self.object_key)
    end

    def load_json(object_summary)
      string = object_summary.get.body.read
      return {} if string.nil? || string.empty?
      return  JSON.parse(string)
    end

    class << self
      def bucket
        return Aws::S3::Bucket.new(:name=>ENV['S3_CONFIG_BUCKET'], :client=>Aws::S3::Client.new)
      end

      def all_object_summaries
        object_summaries = []
        self.bucket.objects(prefix: ENV['SHARED_CONFIG_PATH_ROOT']).each{|os|
          if os.key =~ /\.json$/
            object_summaries << os
          end
        }
        return object_summaries
      end

      def all
        self.all_object_summaries.map{|os| new(object_summary: os, object_key: os.key)}
      end
    end
  end
end
