#
# Cookbook:: scollector
# Recipe:: redhat
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
case node['platform_version'].to_i
when /^7/
  init_file = 'scollector.service'
  init_path = '/etc/systemd/system'
when /^6/
  init_file = 'scollector'
  init_path = '/etc/init.d'
end

directories = [
	       node['scollector']['install_path'],
	       node['scollector']['config_path'],
	       node['collector']['collector_dir']
	      ]

directories.each do |dir|
  directory dir do
    owner  'root'
    group  'root'
    mode   '0755'
    action :create
  end
end

remote_file "#{node['scollector']['install_path']}/scollector" do
  source node['scollector']['download_url']
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
  notifies :restart, 'service[scollector]', :delayed
end

cookbook_file "#{init_path}/#{init_file}" do
  owner    'root'
  group    'root'
  mode     '0755'
  action   :create
  source   "init_scrpts/#{init_file}"
  notifies :restart, 'service[scollector]', :delayed
end

template "#{node['scollector']['config_path']}/scollector.toml" do
  owner    'root'
  group    'root'
  mode     '0644'
  action   :create
  source   'redhat.toml.erb'
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
    owner  'root'
    group  'root'
    mode   '0755'
    action :create
  end

  collector_source = "collectors/#{node['kernel']['name'].downcase}"

  node['collector']['external'].each do |k,v|
    if node['collector']['freq_dir'].include?(v['freq'])
      collector_path = "#{node['collector']['collector_dir']}/#{v['freq']}"

      cookbook_file "#{collector_path}/#{v['freq']}" do
        owner 'root'
	group 'root'
	mode  '0755'
	action v['action']
	source "#{collector_source}/#{k}"
	notifies :restart, 'service[scollector]', :delayed
      end
    else
      Chef::Log.fatal('freq is not valid')
    end
  end
end

service 'scollector' do
  action [:enable, :start]
end

