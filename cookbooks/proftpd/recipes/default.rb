#
# Cookbook Name:: proftpd
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'yum-epel'

package 'proftpd' do
    action :install
 end
 
 package 'tcl' do
    action :install
 end

package 'expect' do
    action :install
 end

 service "proftpd" do
	supports :status => true, :restart => true, :start => true, :stop => true, :reload => true
  	action [:start, :enable]
 end

 group "proftpd" do
  gid 2600
   action  :create
end

user "proftpd" do
  group_name "proftpd"
  group_id 2600
  action  :create
  home '/opt/proftpd'
end

 template '/opt/proftpd/bin/sftpCreateUser.sh' do
  source 'sftpCreateUser.sh.erb'
  owner 'proftpd'
  group 'proftpd'
  mode '0644'
end

template '/opt/proftpd/bin/sftpChangePassword.sh' do
  source 'sftpChangePassword.sh.erb'
  owner 'proftpd'
  group 'proftpd'
  mode '0644'
end

template '/opt/proftpd/etc/proftpf.conf.orig' do
  source 'proftpd.conf.orig.erb'
  owner 'proftpd'
  group 'proftpd'
  mode '0644'
end

file '/opt/proftpd/etc/<prefix> accounts.txt' do
	owner 'proftpd'
    group 'proftpd'
    mode 0755
    action :touch
 end

file '/opt/proftpd/etc/sftpd.group' do
	owner 'proftpd'
    group 'proftpd'
    mode 0440
    action :touch
  end

 file '/opt/proftpd/etc/sftpd.passwd' do
	owner 'proftpd'
    group 'proftpd'
    mode 0440
    action :touch
   end

  directory '/var/log/proftpd/<directory>' do
  owner 'proftpd'
  group 'proftpd'
  mode '0755'
  action :create
  end

  directory '/sftp/home' do
  owner 'proftpd'
  group 'proftpd'
  mode '0755'
  action :create
  end

  file '/root/.smbcred_<crename>'
    source 'smbcred.conf.erb'
    notifies :restart, "service[proftpd]"
end
   
 