include_recipe "druid"

service "druid-middleManager" do
  action [:enable]
end

consul_service "druid-middleManager"

consul_check "druid-middleManager-health" do
  service_id "druid-middleManager"
  args ["check_response_code.rb", "-u", "#{node[:fqdn]}:#{node[:druid][:middleManager][:port]}/status/health"]
  interval "1m"
  local_template true
end

consul_check "druid-middleManager-runtime-timestamp" do
  service_id "druid-middleManager"
  args ["check_config_mod_time.rb", "-u", "druid-middleManager", "-c", "/var/app/druid/current/config/middleManager/runtime.properties", "-w"]
  interval "1m"
  local_template true
end

consul_check "druid-middleManager-common-timestamp" do
  service_id "druid-middleManager"
  args ["check_config_mod_time.rb", "-u", "druid-middleManager", "-c", "/var/app/druid/current/config/_common/common.runtime.properties", "-w"]
  interval "1m"
  local_template true
end
