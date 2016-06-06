
property :name, String
property :package_source, String
property :temp_dir, String

resource_name :new_webserver
action :config do

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
directory '/var/tmp/install' do
        owner 'root'
        group 'root'
        mode '0755'
        action:create
end

#download mod_jk
remote_file "/var/tmp/install/tomcat-connectors-1.2.41-src.tar.gz" do
        source 'http://mirrors.m247.ro/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.41-src.tar.gz'
        owner 'root'
        group 'root'
        mode '0755'
        action :create
end 

#install httpd dependecies
package 'httpd-devel.x86_64'

end

#unzip and compile tomcat connector
action :unzip_compile do

bash 'extract_module' do
  cwd '/var/tmp/install'
  code <<-EOH
        tar xzf tomcat-connectors-1.2.41-src.tar.gz
        cd /var/tmp/install/tomcat-connectors-1.2.41-src && echo "***Switched to dir" > /var/tmp/install/install.log
        ./configure --with-apxs=/usr/local/apache/bin/apxs && echo "***Config completed" >> /var/tmp/install/install.log
        make && echo "***Make completed" >> /var/tmp/install/install.log
        make install && echo "***Install completed" >> /var/tmp/install/install.log
        date >> /var/tmp/install/finished.log
    EOH
end

end

#source workers.properties file and update it
action :workers do
template '/etc/httpd/conf/workers.properties' do
        source 'workers.properties.erb'
end

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

#restart apache&tomcat services

service 'httpd' do
        action [:restart]
end

service 'tomcat' do
        action [:restart]
end
end
