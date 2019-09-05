require "spec_helper"
RSpec.describe SharedConfig do
  let(:object_summary){Aws::S3::ObjectSummary.new(ENV['S3_CONFIG_BUCKET'], "#{ENV['SHARED_CONFIG_PATH_ROOT']}/#{rand_string}.json")}
  let(:group_name){SecureRandom.hex(12)}
  let(:object_key){"s3://#{SecureRandom.hex}"}
  let(:client){Aws::S3::Client.new}
  let(:bucket){Aws::S3::Bucket.new(name: ENV['S3_CONFIG_BUCKET'], client: client)}

  describe SharedConfig::S3 do
    let(:group){SharedConfig::Group.new(object_key: object_key)}
    it "calls create a group with supplied " do
      group
      expect(SharedConfig::ObjectKeys).to receive(:from_group_names).with(group_name){[object_key]}
      expect(SharedConfig::Group).to receive(:new).with(object_key: object_key){group}
      expect(group).to receive(:load)
      described_class.load(group_name)
    end

    it "calls load on each item in SharedConfig::Group.all if nothing is passed in" do
      expect(SharedConfig::Group).to receive(:all){[group]}
      expect(group).to receive(:load)
      described_class.load
    end
  end

  describe SharedConfig::ObjectKeys do
    describe "from_group_names" do
      it "calls from_group_name for each item supplied" do
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
      it "combines the the name with ENV['SHARED_CONFIG_PATH_ROOT']" do
        expect(described_class.from_group_name('some-group-name')).to eq("#{ENV['SHARED_CONFIG_PATH_ROOT']}/some-group-name.json")
        expect(described_class.from_group_name('some-group-name.json')).to eq("#{ENV['SHARED_CONFIG_PATH_ROOT']}/some-group-name.json")
      end
    end
  end
  describe SharedConfig::EnvVar do
    describe "set" do
      it "sets an environment variable" do
        key = rand_string
        value = rand_string
        described_class.set(key, value)
        expect(ENV[key]).to eq(value)
      end
    end
  end

  describe SharedConfig::Group do
    subject{described_class.new(object_key: rand_string, object_summary: object_summary)}

    describe "load" do
      it "calls EnvVar.set with item from load_json" do
        expect(subject).to receive(:load_json).with(subject.object_summary){{"key"=>"value"}}
        expect(SharedConfig::EnvVar).to receive(:set).with("key", "value")
        subject.load
      end
    end

    describe "load_json" do
      let(:body){double("Body")}
      let(:object){Aws::S3::Object.new(bucket_name: bucket.name, key: object_summary.key)}
      it "returns a parsed version of the object's content" do
        expect(object_summary).to receive(:get){object}
        expect(object).to receive(:body){body}
        expect(body).to receive(:read){"\[1\]"}
        expect(subject.load_json(object_summary)).to eq([1])
      end

      it "does not blow up if the json is unparseable" do
        expect(object_summary).to receive(:get){object}
        expect(object).to receive(:body){body}
        expect(body).to receive(:read){""}
        expect(subject.load_json(object_summary)).to eq({})
      end

      it "does not blow up if the returned value is nil" do
        expect(object_summary).to receive(:get){object}
        expect(object).to receive(:body){body}
        expect(body).to receive(:read){nil}
        expect(subject.load_json(object_summary)).to eq({})
      end
    end

    describe "load_object_summary" do
      it "loads the object_summary wth the env bucket" do
        expect(described_class).to receive(:bucket){bucket}
        expect(Aws::S3::ObjectSummary).to receive(:new).with(bucket.name, subject.object_key){object_summary}
        subject.load_object_summary
        expect(subject.object_summary).to eq(object_summary)
      end
    end

    describe "all_object_summaries" do
      it "returns object_summary objects by the client" do
        expect(described_class).to receive(:bucket){bucket}
        collection = Aws::S3::ObjectSummary::Collection.new(nil)
        expect(bucket).to receive(:objects).with(prefix: ENV['SHARED_CONFIG_PATH_ROOT']){collection}
        expect(collection).to receive(:each)
        object_summaries = described_class.all_object_summaries
      end
    end

    describe "all" do
      it "returns a Group for each item in all_object_summaries" do
        expect(described_class).to receive(:all_object_summaries){[object_summary]}
        groups = described_class.all
        expect(groups.first.object_summary).to eq(object_summary)
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
