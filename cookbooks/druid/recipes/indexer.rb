include_recipe "druid"

service "druid-indexer" do
  action [:enable]
end

consul_service "druid-indexer"

consul_check "druid-indexer-health" do
  service_id "druid-indexer"
  args ["check_response_code.rb", "-u", "#{node[:fqdn]}:#{node[:druid][:indexer][:port]}/status/health"]
  interval "1m"
  local_template true
end

consul_check "druid-indexer-runtime-timestamp" do
  service_id "druid-indexer"
  args ["check_config_mod_time.rb", "-u", "druid-indexer", "-c", "/var/app/druid/current/config/indexer/runtime.properties", "-w"]
  interval "1m"
  local_template true
end

consul_check "druid-indexer-common-timestamp" do
  service_id "druid-indexer"
  args ["check_config_mod_time.rb", "-u", "druid-indexer", "-c", "/var/app/druid/current/config/_common/common.runtime.properties", "-w"]
  interval "1m"
  local_template true
end
