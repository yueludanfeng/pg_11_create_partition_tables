# 说明
* 作用：postgres11创建分表，替代传统触发器创建分表，从而加快入库速度

##  使用前提：

- 安装 PG 到 /home/postgres/pgsql 目录
- PG 版本 >=11.0

##  create_sub_tables_with_8hours.sh
 > 注意此脚本中创建的是8小时分表

* 使用方法：
  * 在数据库中创建好父表
  * 在环境中创建配制文件 partition_by_8_hours.conf
  * 将需要创建分表的表名称写入上面配置文件中
  * 执行脚本 create_sub_tables_with_8_hours.sh (可以将其加入定时任务中，从而实现每天自动创建分表)

##  create_sub_tables_with_8hours.sh
 > 注意此脚本中创建的按天分表

* 使用方法：
  * 在数据库中创建好父表
  * 在环境中创建配制文件 partition_interval_day.conf
  * 将需要创建分表的表名称写入上面配置文件中
  * 执行脚本 create_sub_tables_with_8_hours.sh (可以将其加入定时任务中，从而实现每天自动创建分表)

