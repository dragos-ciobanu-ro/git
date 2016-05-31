#
# Cookbook Name:: learn_chef_tomcat
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

#install httpd and set index.html file content
package 'httpd'

service 'httpd' do
	action [:enable, :start]
end

file '/var/www/html/index.html' do
  content '<html>
  <body>
    <h1>hello world</h1>
  </body>
</html>'
end

#install tomcat deploy sample.war then start/enable TC service
package 'tomcat'

remote_file '/usr/share/tomcat/webapps/sample.war' do
	source 'https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war'
	owner 'tomcat'
	group 'tomcat'
	mode '0755'
	action :create
end

service 'tomcat' do
        action [:enable, :start]
end

#prepare mod_jk install dir
remote_directory '/var/tmp/install' do
	source 'install'
	owner 'root'
	group 'root'
	mode '0755'
	action:create
end 

#download mod_jk
remote_file '/var/tmp/install/tomcat-connectors-1.2.41-src.tar.gz' do
	source 'http://mirrors.m247.ro/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.41-src.tar.gz'
	owner 'root'
	group 'root'
	mode '0755'
	action :create
end

#install httpd dependecies
package 'httpd-devel.x86_64'

#unpack mod_jk & build library
bash 'extract_module' do
  cwd '/var/tmp/install'
  code <<-EOH
        tar xzf tomcat-connectors-1.2.41-src.tar.gz     
        cd /var/tmp/install/tomcat-connectors-1.2.41-src
        echo "***Switched to dir" > /var/tmp/install/install.log
        ./configure --with-apxs=/usr/local/apache/bin/apxs 
        echo "***Config completed" >> /var/tmp/install/install.log
        make 
        echo "***Make completed" >> /var/tmp/install/install.log
        make install 
        echo "***Install completed" >> /var/tmp/install/install.log
        touch /var/tmp/install/finished
    EOH
end

#add workers.properties file
#file '/etc/httpd/conf/workers.properties' do
#	content 'worker.list=department1,department2,department3
#		worker.department1.type=ajp13
#		worker.department1.port=8009
#		worker.department1.host=localhost
#		worker.department2.type=ajp13
#		worker.department2.port=8009
#		worker.department2.host=localhost
#		worker.department3.type=ajp13
#		worker.department3.port=8009
#		worker.department3.host=localhost'
#end

#source workers.properties template file
template '/etc/httpd/conf/workers.properties' do
	source 'workers.properties.erb'
end

#append mod_jk config to httpd.conf

bash 'append_to_config' do
        code <<-EOF
                cat /root/work/mod_jk.conf >> /etc/httpd/conf/httpd.conf
        EOF
end

#restart apache&tomcat services

service 'httpd' do
	action [:restart]
end

service 'tomcat' do
	action [:restart]
end
