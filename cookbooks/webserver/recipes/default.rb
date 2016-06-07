#install httpd and create index file

pkg_compile 'modjk' do
  package_source 'http://mirrors.m247.ro/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.41-src.tar.gz'
  temp_dir '/var/tmp/magicshit'
  compile_dir 'tomcat-connectors-1.2.41-src/native'
  additional_dependencies ['httpd-devel.x86_64']
  action [:download, :configure, :make_install, :workers, :append_modjk, :restart_services]
end
