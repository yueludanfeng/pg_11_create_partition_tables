#!/bin/sh

SUB_TABLES_FILE_INTERVAL_DAY=/var/partition_interval_day.conf
DB_NAME=imos
BIN_PSQL=/home/postgres/pgsql/bin/psql

# 注意1:
# 需要实现已经在数据库中创建好了主表
# CREATE TABLE test( 
# id serial,
# user_id int,
# create_time timestamp without time zone
# ) partition by range(create_time);

# 注意2:
# 需要事先创建配置文件并将需要创建按天分表的父表名称写进去
# vim /var/partition_interval_day.conf
# test


# 获取数据库密码
export_dbpasswd()
{
    export PGUSER=postgres
    export PGPASSWORD=passwd
}


get_next_date_with_duration()
{
    local start_date=$1
    # 2019_11_09_01
    year=`echo $start_date | awk -F'_' '{print $1}'`
    month=`echo $start_date | awk -F'_' '{print $2}'`
    day=`echo $start_date | awk -F'_' '{print $3}'`
    # duartion=`echo $start_date | awk -F'_' '{print $4}'`   
    str_start_date=`echo "${year}-${month}-${day}"`
    next_date=`date --date="${str_start_date} +1days" +%Y_%m_%d`
    echo $next_date
}

create_default_sub_table()
{
    local tbl_name=$1
    ${BIN_PSQL} -Upostgres -d ${DB_NAME} -qAt -c \
    "CREATE TABLE if not exists ${tbl_name}_default PARTITION OF ${tbl_name} DEFAULT; "
}

create_sub_tables_interval_day()
{
    local tbl_name=$1
    local current_date_with_dash=$2
    local year=`echo $current_date_with_dash|awk -F'_' '{print $1}'`
    local month=`echo $current_date_with_dash|awk -F'_' '{print $2}'`
    local day=`echo $current_date_with_dash|awk -F'_' '{print $3}'`
    local current_date="`echo ${year}-${month}-${day}`"
    
    text_sql="CREATE TABLE if not exists ${tbl_name}_${current_date_with_dash} PARTITION OF ${tbl_name} for values from ('${current_date}') to ('${current_date} 24:00:00'); "
    ${BIN_PSQL} -Upostgres -d ${DB_NAME} -qAt -c "${text_sql}"
}

main()
{
    # 当前日期
    local start_date=`date "+%Y_%m_%d"`
    # 下个月末(with duration)
    local next_month_end_date=`date --date="$(date +%Y-%m-01) +2 month -1 day" '+%Y_%m_%d'`

    local current_date="${start_date}"
	
	export_dbpasswd
	
    while read -r line
	do
        local tbl_name=`echo $line`
		if [[ "${tbl_name}" = "" ]];then
			exit 0
		fi
        create_default_sub_table "${tbl_name}"
        while [[ "${current_date}" < "${next_month_end_date}" ]]
        do
            create_sub_tables_interval_day "${tbl_name}" "${current_date}"
            current_date=`get_next_date_with_duration ${current_date}`
        done
        if [[ "${current_date}" = "${next_month_end_date}" ]];then 
            create_sub_tables_interval_day "${tbl_name}" "${current_date}"
        fi
    done < ${SUB_TABLES_FILE_INTERVAL_DAY}
}

main
