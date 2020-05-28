include_recipe "druid"

service "druid-router" do
  action [:enable]
end

consul_service "druid-router" do
  port node[:druid][:router][:port]
end

consul_check "druid-router-runtime-timestamp" do
  service_id "druid-router"
  args ["check_config_mod_time.rb", "-u", "druid-router", "-c", "/var/app/druid/current/config/router/runtime.properties", "-w"]
  interval "1m"
  local_template true
end

consul_check "druid-router-common-timestamp" do
  service_id "druid-router"
  args ["check_config_mod_time.rb", "-u", "druid-router", "-c", "/var/app/druid/current/config/_common/common.runtime.properties", "-w"]
  interval "1m"
  local_template true
end
