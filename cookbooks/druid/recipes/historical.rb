include_recipe "druid"

service "druid-historical" do
  action [:enable]
end

consul_service "druid-historical" do
  port node[:druid][:historical][:port]
end

consul_check "druid-historical-loadstatus" do
  service_id "druid-historical"
  args ["check_response.rb", "-u", "#{node[:fqdn]}:#{node[:druid][:historical][:port]}/druid/historical/v1/loadstatus", "-p", '{"cacheInitialized":true}']
  interval "1m"
  local_template true
end

consul_check "druid-historical-health" do
  service_id "druid-historical"
  args ["check_response_code.rb", "-u", "#{node[:fqdn]}:#{node[:druid][:historical][:port]}/druid/historical/v1/readiness"]
  interval "1m"
  local_template true
end

consul_check "druid-historical-runtime-timestamp" do
  service_id "druid-historical"
  args ["check_config_mod_time.rb", "-u", "druid-historical", "-c", "/var/app/druid/current/config/historical/runtime.properties", "-w"]
  interval "1m"
  local_template true
end

consul_check "druid-historical-common-timestamp" do
  service_id "druid-historical"
  args ["check_config_mod_time.rb", "-u", "druid-historical", "-c", "/var/app/druid/current/config/_common/common.runtime.properties", "-w"]
  interval "1m"
  local_template true
end
