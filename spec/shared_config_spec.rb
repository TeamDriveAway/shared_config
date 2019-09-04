require "spec_helper"
RSpec.describe SharedConfig do
  let(:object){Aws::S3::Object.new(bucket_name: ENV['S3_CONFIG_BUCKET'], key: rand_string)}
  describe SharedConfig::S3 do
    let(:group_name){SecureRandom.hex(12)}
    let(:object_key){"s3://#{SecureRandom.hex}"}
    # let(:group){SharedConfig::Group.new(group_name)}

    it "calls create a group with supplied " do
      name = rand_string
      object_key = rand_string
      group = SharedConfig::Group.new(object_key: rand_string, object: object)

      expect(SharedConfig::ObjectKeys).to receive(:from_group_names).with(name){[object_key]}
      expect(SharedConfig::Group).to receive(:new).with(object_key: object_key){group}
      expect(group).to receive(:load)
      described_class.load(name)
    end
    #
    # it "calls load on each item in SharedConfig::Group.all" do
    #   expect(SharedConfig::Group).to receive(:all){[group]}
    #   expect(group).to receive(:load)
    #   described_class.load
    # end

    describe SharedConfig::ObjectKeys do
      describe "from_group_names" do
        it "should call from_group_name for each item supplied" do
          names = %w{some-name some-other}
          expect(described_class).to receive(:from_group_name).with('some-name')
          expect(described_class).to receive(:from_group_name).with('some-other')
          described_class.from_group_names(names)

          expect(described_class).to receive(:from_group_name).with('some-name')
          expect(described_class).to receive(:from_group_name).with('some-other')
          described_class.from_group_names(*names)
        end
      end
      describe "from_group_name" do
        it "should combine the the name with ENV['SHARED_CONFIG_PATH_ROOT']" do
          expect(described_class.from_group_name('some-group-name')).to eq("#{ENV['SHARED_CONFIG_PATH_ROOT']}/some-group-name.json")
          expect(described_class.from_group_name('some-group-name.json')).to eq("#{ENV['SHARED_CONFIG_PATH_ROOT']}/some-group-name.json")
        end
      end
    end
    describe SharedConfig::EnvVar do
      describe "set" do
        it "should set an environment variable" do
          key = rand_string
          value = rand_string
          described_class.set(key, value)
          expect(ENV[key]).to eq(value)
        end
      end
    end

    describe SharedConfig::Group do
      subject{described_class.new(object_key: rand_string, object: object)}

      describe "load" do
        it "should call EnvVar.set with item from load_json" do
          expect(subject).to receive(:load_json).with(subject.object){{"key"=>"value"}}
          expect(SharedConfig::EnvVar).to receive(:set).with("key", "value")
          subject.load
        end
      end
      describe "load_json" do
        let(:body){double("Body")}

        it "should return a parsed version of the object's content" do
          expect(object).to receive(:body){body}
          expect(body).to receive(:read){"\[1\]"}
          expect(subject.load_json(object)).to eq([1])
        end

        it "should not blow up if the json is unparseable" do
          expect(object).to receive(:body){body}
          expect(body).to receive(:read){""}
          expect(subject.load_json(object)).to eq({})
        end

        it "should not blow up if the returned value is nil" do
          expect(object).to receive(:body){body}
          expect(body).to receive(:read){nil}
          expect(subject.load_json(object)).to eq({})
        end
      end
      describe "load_object" do
        it "should load the object wth the env bucket" do
          client = Aws::S3::Client.new
          expect(subject).to receive(:client){client}
          expect(client).to receive(:get_object).with(bucket: ENV['S3_CONFIG_BUCKET'], key: subject.object_key){object}
          subject.load_object
          expect(subject.object).to eq(object)
        end
      end
    end

  end

  it "has a version number" do
    expect(SharedConfig::VERSION).not_to be nil
  end
  #
  # it "does something useful" do
  #   expect(false).to eq(true)
  # end
end
