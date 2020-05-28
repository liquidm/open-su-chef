include_recipe "druid"

service "druid-coordinator" do
  action [:enable]
end

consul_service "druid-coordinator" do
  port node[:druid][:coordinator][:port]
end
