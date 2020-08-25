include_recipe "druid"

service "druid-broker" do
  action [:enable]
end

consul_service "druid-broker" do
  port node[:druid][:broker][:port]
  tags [node[:druid][:broker][:service]]
end
