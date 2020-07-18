RSpec.describe Growing::Ruby::Sdk do
  it "has a version number" do
    expect(Growing::Ruby::Sdk::VERSION).not_to be nil
  end

  it "does something useful" do
    account_id = '*' * 16
    gio = Growing::Ruby::Sdk::Client.instance(account_id, "https://api.growingio.com")
    expect(gio.track('1', 'e', {})).to be true
  end
end
