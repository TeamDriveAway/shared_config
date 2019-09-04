RSpec.describe SharedConfig do
  it "has a version number" do
    expect(SharedConfig::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
