include_recipe "druid"

service "druid-broker" do
  action [:enable]
end

