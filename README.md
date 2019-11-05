# 说明

# create_sub_tables_with_8_hours.sh

* 作用：postgres11创建分表，替代传统触发器创建分表，从而加快入库速度

  > 注意此脚本中创建的是8小时分表，如果要是用按天分表，需要修改代码

* 使用前提：

  * 安装PG到/home/postgres/pgsql目录
  * PG版本>=11.0

* 使用方法：

  * 在环境中创建文件/usr/local/conf/partition_by_8_hours.conf
  * 将需要创建分表的表名称写入上面配置文件中
  * 执行脚本create_sub_tables_with_8_hours.sh(可以将其加入定时任务中，从而实现每天自动创建分表)

