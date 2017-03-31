default['scollector']['version']        = '0.5.0'
default['scollector']['user']           = ''
default['scollector']['password']       = ''
default['scollector']['use_external']   = false
default['scollector']['freq']           = 60
default['scollector'['tag_override']    = {}
default['scollector']['full_host']      = false
default['scollector']['bosun_host']     = ''
default['scollector']['bosun_port']     = '8090'
default['scollector']['bosun_protocol'] = 'https'
default['collector']['freq_dir']        = []
default['collector']['native_inputs']   = {}
default['collector']['external']        = {}

case node['kernel']['name'].downcase
when 'linux'
  default['scollector']['system_os']    = 'linux'
  default['scollector']['ext']          = ''
  default['scollector']['install_path'] = '/usr/local/scollector'
  default['scollector']['config_path']  = '/etc/scollector'
  default['collector']['collector_dir'] = "#{config_path}/collectors"
when 'windows'
  default['scollector']['system_os']    = 'windows'
  default['scollector']['ext']          = '.exe'
  default['scollector']['install_path'] = 'C:/Program Files/scollector'
  default['scollector']['config_path']  = install_path
  default['collector']['collector_dir'] = "#{install_path}/collectors"
else
  Chef::Log.fatal("#{node['kernel']['name']} is not supported")
end

if ['scollector']['use_external'].empty? or ['scollector']['use_external'].nil?
  default['collector']['collector_freq_dir'] = []
else
  default['collector']['collector_freq_dir'] = Array.new
  ['collector']['freq_dir'].each do |freq_dir|
    ['collector']['collector_freq_dir'] << "#{['collector']['collector_dir']}/#{['collector']['freq_dir']}"
  end
end

if node['kernel']['machine'].include?('64')
  ['scollector']['system_arch'] = 'amd64'
else
  Chef::Log.fatal("#{node['kernel']['machine']} is not supported")
end

['scollector']['binary']       = "scollector-#{['scollector']['system_os']}-#{['scollector']['system_arch']}#{['scollector']['ext']}"
['scollector']['download_url'] = "https://github.com/bosun-monitor/bosun/releases/download/#{['scollector']['version']}/#{['scollector']['binary']}"
['scollector']['ingredient']   = node['kernel']['name'].downcase

