![Ansible Molecule Pipeline](https://github.com/inmotionhosting/ansible-role-mysql/actions/workflows/main.yml/badge.svg) [![GPL-3.0 License](https://img.shields.io/github/license/inmotionhosting/ansible-role-mysql.svg?color=blue)](https://github.com/inmotionhosting/ansible-role-mysql/blob/master/LICENSE) [![GitHub stars](https://img.shields.io/github/stars/inmotionhosting/ansible-role-mysql.svg)](https://github.com/inmotionhosting/ansible-role-mysql/stargazers)

![InMotion Hosting Ultrastack](https://www.inmotionhosting.com/wp-content/uploads/2024/01/ultrastack-logo-black-vertical.png)

# Ansible Role: MySQL
Modular Ansible Role for deploying and configuring MySQL/MariaDB

## Requirements
This Ansible role supports the two latest stable releases of specific
server-focused Linux distributions and aims to follow their deprecation
policies. Additionally we will focus on supporting the latest two stable
releases of each, which at the time of writing are as follows:

* CentOS 7.x
* Debian 10 or later
* Ubuntu 20.04 LTS or later
* AlmaLinux 8.x or later
* RockyLinux 8.x or later

## Dependencies
* community.mysql

## Role Variables
Available variables are listed below with their default values (you can also see `defaults/main.yml`)

| Variable | Description |
| -------- | ----------- |
| mysql_config_file | Default: `/etc/my.cnf`
| mysql_config_include_dir | Default: `/etc/my.cnf.d`
| mysql_daemon | Default: `mariadb`
| mysql_innodb_buffer_pool_size | Default: `128M`
| mysql_innodb_file_per_table | Default: `1`
| mysql_innodb_log_buffer_size | Default: `16M`
| mysql_innodb_log_file_size | Default: `96M`
| mysql_log_dir | Default: `/var/log/`
| mysql_log_error | Default: `"{{ mysql_log_dir }}/mariadb/mariadb.log"`
| mysql_log_file_group | Default: `mysql`
| mysql_log_warning | Default: `1`
| mysql_packages | Default: `The MySQL packages to install`
| mysql_query_alloc_block_size | Default: `16384`
| mysql_query_cache_limit | Default: `1M`
| mysql_query_cache_min_res_unit | Default: `4096`
| mysql_query_cache_size | Default: `16M`
| mysql_query_cache_strip_comments | Default: `0`
| mysql_query_cache_type | Default: `1`
| mysql_query_cache_wlock_invalidate | Default: `0`
| mysql_query_prealloc_size | Default: `24576`
| mysql_root_home | Default: `/root`
| mysql_root_password_update | Default: `false`
| mysql_root_username | Default: `root`
| mysql_slow_query_log_enabled | Default: `true`
| mysql_slow_query_log_file | Default: `"{{ mysql_log_dir }}/mysql-slow.log"`
| mysql_socket | Default: `true`
| mysql_socket_path | Default: `/var/lib/mysql/mysql.sock`
| mysql_supports_innodb_large_prefix | Default: `true`
| mysql_syslog_tag | Default: `mariadb`
| password_generate | Default: `"{{ lookup('password', '/dev/null length=15 chars=ascii_letters') }}"`


## Example Playbook
```yaml
- hosts: www
  roles:
     - role: inmotionhosting.mysql
```

## License
GPLv3

## Author Information
[InMotion Hosting](https://inmotionhosting.com)
