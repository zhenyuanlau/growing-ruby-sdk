RSpec.describe Growing::Ruby::Sdk do
  it "has a version number" do
    expect(Growing::Ruby::Sdk::VERSION).not_to be nil
  end

  it "does something useful" do
    account_id = 'bfc5d6a3693a110d'
    data_source_id = '9857ab8fc91a8d3b'
    api_host = "http://117.50.94.81:8080"
    gio = Growing::Ruby::Sdk::Client.instance(account_id, data_source_id, api_host)
    expect(gio.collect_user("crm", {"name": "crm"})).to be true
    expect(gio.collect_cstm("crm", "crm", { a: "a" })).to be true
  end
end
