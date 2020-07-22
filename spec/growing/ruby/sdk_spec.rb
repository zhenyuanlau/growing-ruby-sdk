# frozen_string_literal: true

RSpec.describe Growing::Ruby::Sdk do
  it "has a version number" do
    expect(Growing::Ruby::Sdk::VERSION).not_to be nil
  end

  it "does something useful" do
    account_id = "bfc5d6a3693a110d"
    data_source_id = "9857ab8fc91a8d3b"
    api_host = "http://117.50.94.81:8080"
    gio = Growing::Ruby::Sdk::Client.instance(account_id, data_source_id, api_host)
    gio.collect_user("crm_user#{Time.now}", { "name": "crm" })
    gio.collect_cstm("crm_user#{Time.now}", "crm_cstm", { a: "a" })
    expect(gio.event_queue["collect_user"].length).not_to be 0
    gio.send_data
    expect(gio.event_queue.empty?).to be true
  end
end
