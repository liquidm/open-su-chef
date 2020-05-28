include_recipe "java"
include_recipe "deploy"

deploy_skeleton "druid"

deploy_artifact "liquidm/druid" do
  user "druid"
  ref_name node[:druid][:git][:revision]
  strip_components 1
end

directory "/var/app/druid/current/conf" do
  recursive true
  action :delete
end

config_dir =  "/var/app/druid/current/config"

node_types = %i{
  historical
  middleManager
  indexer
  coordinator
  broker
  router
}

# TODO: cleanup
(node_types.map{|node_type| ["/var/app/druid/current/config/#{node_type}", "/var/app/druid/storage/tmp/#{node_type}"]} + %W(
  /var/app/druid/current/config/_common
  /var/app/druid/shared/error_dump
  /var/app/druid/storage
  /var/app/druid/storage/tmp
  /var/app/druid/storage/info
  /var/app/druid/storage/segment_cache
  /var/app/druid/storage/indexer
  /var/app/druid/storage/middleManager
  #{node[:druid][:indexer][:task_dir]}
)).flatten.each do |dir|
  directory dir do
    owner "druid"
    group "druid"
    mode "0755"
    recursive true
  end
end

gem_package "zk"

nagios_plugin "check_druid" do
  source "check_druid.rb"
end

nagios_plugin "check_druid_load_queue" do
  source "check_druid_load_queue.rb"
end

nagios_plugin "check_druid_segments" do
  source "check_druid_segments.rb"
end

nagios_plugin "check_druid_load_status" do
  source "check_druid_load_status.rb"
end

template "/var/app/druid/current/config/_common/log4j2.xml" do
  source "log4j2.xml"
  owner "root"
  group "root"
  mode "0644"
end

template "/var/app/druid/current/config/_common/common.runtime.properties" do
  source "common.runtime.properties.erb"
  owner "root"
  group "root"
  mode "0644"
end

classpath = %w{
  /var/app/druid/current/config/_common
  /var/app/druid/current/lib/*
  /etc/hadoop2
}



stop_cmds = {
  middleManager: %Q{#!/usr/bin/ruby
    require 'json'
    puts %x{/usr/bin/curl -X POST #{node[:fqdn]}:#{node[:druid][:middleManager][:port]}/druid/worker/v1/disable 2>/dev/null}
    loop do
      tasks = JSON.parse(%x{/usr/bin/curl #{node[:fqdn]}:#{node[:druid][:middleManager][:port]}/druid/worker/v1/tasks 2>/dev/null})
      puts "Waiting for \#{tasks.length} tasks"
      sleep 10
      break if tasks.length == 0
    end
  },
  indexer: %Q{#!/usr/bin/ruby
    require 'json'
    puts %x{/usr/bin/curl -X POST #{node[:fqdn]}:#{node[:druid][:indexer][:port]}/druid/worker/v1/disable 2>/dev/null}
    loop do
      tasks = JSON.parse(%x{/usr/bin/curl #{node[:fqdn]}:#{node[:druid][:indexer][:port]}/druid/worker/v1/tasks 2>/dev/null})
      puts "Waiting for \#{tasks.length} tasks"
      sleep 10
      break if tasks.length == 0
    end
  }
}

node_types.each do |druid_node|
  template "/var/app/druid/current/config/#{druid_node}/jvm.config" do
    source "jvm.config.erb"
    variables({
      druid_node: druid_node,
    })
    owner "root"
    group "root"
    mode "0644"
  end

  template "/var/app/druid/current/config/#{druid_node}/runtime.properties" do
    source "#{druid_node}/runtime.properties.erb"
    owner "root"
    group "root"
    mode "0644"
  end

  check_stop =  "/var/app/druid/bin/check-stop-#{druid_node}"

  if stop_cmds[druid_node]
    file check_stop do
      content stop_cmds[druid_node]
      owner "druid"
      group "druid"
      mode "0555"
    end
  else
    check_stop = nil
  end

  systemd_unit "druid-#{druid_node}.service" do
    template "druid-service.erb"
    variables({
      druid_node: druid_node,
      druid_nice: node[:druid][druid_node][:nice],
      druid_oom_score: node[:druid][druid_node][:oom_score],
      classpath: "/var/app/druid/current/config/#{druid_node}:#{classpath.join(':')}",
      check_stop: check_stop,
    })
  end
end

# fetching this dependency seems broken atm

# execute "fetch hadoop dependencies" do
#   command "/usr/bin/java `cat /var/app/druid/current/config/coordinator/jvm.config | xargs` -cp #{classpath.join(':')} org.apache.druid.cli.Main tools pull-deps || true"
#   cwd "/var/app/druid/current"
#   default_env true
#   user "druid"
# end
