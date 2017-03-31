#
# Cookbook:: scollector
# Recipe:: windows
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
directories = [
	       node['scollector']['install_path'],
	       node['collector']['collector_dir']
	      ]

directories.each do |dir|
  directory dir do
    rights :full_control, 'administrator'
    action :create
  end
end

remote_file "#{node['scollector']['install_path']}/scollector#{node['scollector']['ext']}" do
  rights   :full_control, 'administrator'
  action   :create
  notifies :run, 'execute[register-service]', :immediately
end

template "#{node['scollector']['config_path']}/scollector.toml" do
  rights   :full_control, 'administrator'
  action   :create
  source   'windows.toml.erb'
  notifies :restart, 'service[scollector]', :delayed
  variables({
    user: node['scollector']['user'],
    password: node['scollector']['password'],
    proto: node['scollector']['bosun_protocol'],
    host: node['scollector']['bosun_host'],
    port: node['scollector']['bosun_port'],
    external_collectors: node['scollector']['use_external'],
    collector_dir: node['collector']['collector_dir'],
    freq: node['scollector']['freq'],
    full_host: node['scollector']['full_host'],
    tag_override: node['scollector']['tag_override'],
    collector: node['collector']['native_inputs']
  })
end

if node['scollector']['use_external']
  directory node['collector']['collector_freq_dir'] do
    rights :full_control, 'administrator'
    action :create
  end

  collector_source = "collectors/#{node['kernel']['name'].downcase}"

  node['collector']['external'].each do |k,v|
    if node['collector']['freq_dir'].include?(v['freq'])
      collector_path = "#{node['collector']['collector_dir']}/#{v['freq']}"

      cookbook_file "#{collector_path}/#{v['freg']}" do
        rights :full_control, 'administrator'
	action v['action']
	source "#{collector_source}/#{k}"
	notifies :restart, 'service[scollector]', :delayed
      end
    else
      Chef::Log.fatal('freq is not valid')
    end
  end
end

execute 'register-service' do
  command "#{node['scollector']['install_path']}/scollector#{node['scollector']['ext']} --winsvc=install"
  action  :nothing
end

service 'scollector' do
  action [:enable, :start]
end

