#!/bin/sh

SUB_TABLES_FILE_8_hours=/var/partition_by_8_hours.conf
DB_NAME=postgres
BIN_PSQL=/home/postgres/pgsql/bin/psql


# 注意1:
# 需要实现已经在数据库中创建好了主表
# CREATE TABLE test_partition( 
# id serial,
# user_id int,
# create_time timestamp without time zone
# ) partition by range(create_time);

# 注意2:
# 需要事项创建配置文件bk jl xuyc ilj ffbn d fubn tmxp jbqu 
# vim /var/partition_by_8_hours.conf
# test_partition


# 获取数据库密码
export_dbpasswd()
{
	export PGUSER=postgres
	export PGPASSWORD=passwd
}


get_next_date_with_duration()
{
    start_date=$1
    # 2019_11_09_01
    year=`echo $start_date | awk -F'_' '{print $1}'`
    month=`echo $start_date | awk -F'_' '{print $2}'`
    day=`echo $start_date | awk -F'_' '{print $3}'`
    duartion=`echo $start_date | awk -F'_' '{print $4}'`   

    str_start_date=`echo "${year}-${month}-${day}"`
    if [[ $duartion -eq "01" ]]; then 
        next_date=`echo "${year}_${month}_${day}_02"`
    elif [[ $duartion -eq "02" ]]; then 
        next_date=`echo "${year}_${month}_${day}_03"`
    elif [[ $duartion -eq "03" ]]; then 
        next_date=`date --date="${str_start_date} +1days" +%Y_%m_%d_01`
    fi
    echo $next_date
}

create_default_sub_table()
{
    local tbl_name=$1
    ${BIN_PSQL} -Upostgres -d ${DB_NAME} -qAt -c \
    "CREATE TABLE if not exists ${tbl_name}_default PARTITION OF ${tbl_name} DEFAULT; "
}

create_sub_tables_with_8_hours()
{
    local tbl_name=$1
    local current_date_with_duration=$2
    
    local year=`echo $current_date_with_duration|awk -F'_' '{print $1}'`
    local month=`echo $current_date_with_duration|awk -F'_' '{print $2}'`
    local day=`echo $current_date_with_duration|awk -F'_' '{print $3}'`
    local duration=`echo $current_date_with_duration|awk -F'_' '{print $4}'`
    local current_date="`echo ${year}-${month}-${day}`"
    
    if [[ "$duration" = '01' ]];then 
        text_sql="CREATE TABLE if not exists ${tbl_name}_${current_date_with_duration} PARTITION OF ${tbl_name} for values from ('${current_date}') to ('${current_date} 08:00:00'); "
    elif [[ "$duration" = '02' ]];then 
        text_sql="CREATE TABLE if not exists ${tbl_name}_${current_date_with_duration} PARTITION OF ${tbl_name} for values from ('${current_date} 08:00:00') to ('${current_date} 16:00:00'); "
    elif [[ "$duration" = '03' ]];then 
        text_sql="CREATE TABLE if not exists ${tbl_name}_${current_date_with_duration} PARTITION OF ${tbl_name} for values from ('${current_date} 16:00:00') to ('${current_date} 24:00:00'); "
    fi 
    # echo "${text_sql}"
    ${BIN_PSQL} -Upostgres -d ${DB_NAME} -qAt -c "${text_sql}"
}

main()
{
    # 当前日期
    local start_date=`date "+%Y_%m_%d"`
    # 下个月末(with duration)
    local next_month_end_date_with_duration=`date --date="$(date +%Y-%m-01) +2 month -1 day" '+%Y_%m_%d_03'`

    local current_date_with_duration="${start_date}_01"
	
	export_dbpasswd
	
    while read -r line
	do
        local tbl_name=`echo $line`
		if [[ "${tbl_name}" = "" ]];then
			exit 0
		fi
        create_default_sub_table "${tbl_name}"
        while [[ "${current_date_with_duration}" < "${next_month_end_date_with_duration}" ]]
        do
            create_sub_tables_with_8_hours "${tbl_name}" "${current_date_with_duration}"
            # echo "${current_date_with_duration}"
            current_date_with_duration=`get_next_date_with_duration ${current_date_with_duration}`
        done
        if [[ "${current_date_with_duration}" = "${next_month_end_date_with_duration}" ]];then 
            # echo "${current_date_with_duration}"
            create_sub_tables_with_8_hours "${tbl_name}" "${current_date_with_duration}"
        fi
    done < ${SUB_TABLES_FILE_8_hours}
}

main
