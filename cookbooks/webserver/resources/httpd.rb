
property :package_name, String, name_property: true
property :package_source, String
property :temp_dir, String
property :compile_dir, String
property :additional_dependencies

resource_name :pkg_compile

action :download do

directory temp_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

#download mod_jk
remote_file "#{temp_dir}/#{package_name}.tar.gz" do
        source package_source
        owner 'root'
        group 'root'
        mode '0755'
        action :create
end

#unzip
bash 'extract_module' do
  cwd temp_dir
  code <<-EOH
    tar xzf #{package_name}.tar.gz
  EOH
end

end



#unzip and compile tomcat connector
action :configure do

if additional_dependencies
  additional_dependencies.each do |dep|
    package dep
  end
end

bash 'configure_module' do
  cwd temp_dir
  code <<-EOH
    cd #{compile_dir}  
    ./configure --with-apxs=/usr/bin/apxs
  EOH
end

end

action :make_install do
bash 'make_install_module' do
cwd temp_dir
code <<-EOH
	cd #{compile_dir} 
	make && make install
	EOH
end
end
#source workers.properties file and update it
action :workers do
template '/etc/httpd/conf/workers.properties' do
        source 'workers.properties.erb'
end
end
action :append_modjk do

append_if_no_line "httpd.conf" do
  path "/etc/httpd/httpd.conf"
  line "#mod_jk"
line "#LoadModule    jk_module  modules/mod_jk.so"
line "LoadModule    jk_module /usr/lib64/httpd/modules/mod_jk.so"

line "#JkWorkersFile conf/workers.properties"
line "JkWorkersFile /etc/httpd/conf/workers.properties"
line "JkShmFile     /var/log/httpd/mod_jk.shm"
line "JkLogFile     /var/log/httpd/mod_jk.log"
line "JkLogLevel      debug"
line 'JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"'
line "JkOptions     +ForwardKeySize +ForwardURICompat -ForwardDirectories"
line 'JkRequestLogFormat     "%w %V %T"'
line "#JkMount  /department1* department1"

line "Listen 80"
line "#NameVirtualHost *:80"

line "<VirtualHost *:80>"
line "        ServerName webserver"
line "        JkMount  /department1* department1"
line "        JkMount  /department2* department2"
line "</VirtualHost>"

line "<VirtualHost *:80>"
line "        ServerName webserver1"
line "        JkMount  /department3* department3"
line "</VirtualHost>"
end
end

#restart apache&tomcat services
action :restart_services do

service 'httpd' do
        action [:restart]
end

service 'tomcat' do
        action [:restart]
end

end
