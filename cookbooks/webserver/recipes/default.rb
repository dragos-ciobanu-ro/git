#install httpd and create index file
new_webserver 'build_website' do
action :config
action :unzip_compile
action :workers
end
