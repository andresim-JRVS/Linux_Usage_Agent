#!/bin/bash

psql_host=$1
port=$2
db_name=$3
user_name=$4
password=$5

lscpu_out="lscpu"

get_hostname () {
hostname=$(hostname -f)
}

get_cpu_number () {
cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
}

get_lscpu_value () {
pattern=$1
value=$(echo "$lscpu_out" | egrep "$pattern" | awk -F':' '{print $2}' | xargs)
echo "value=$value"
}

get_cpu_architecture () {
get_lscpu_value "Architecture"
cpu_architecture=$value
}

get_cpu_model () {
get_lscpu_value "CPU Model"
cpu_model=$value
}

get_cpu_mhz () {
get_lscpu_value "CPU MHz"
cpu_mhz=$value
}

get_L2_cache () {
get_lscpu_value "L2 Cache"
L2_cache=$value
}

#1st Step: getting all data into variables.

get_hostname
get_cpu_number
get_cpu_architecture
get_cpu_model
get_cpu_mhz
get_L2_cache
total_mem=$(awk '/MemTotal/ {print $2} /proc/meminfo')
timestamp=$(date "+%Y-%m-%d %T")

#2nd Step: construct insert statement for the DB.

insert_stmt=$(cat <<-END
insert into host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, total_mem, "timestamp")
values('${hostname}', '${cpu_number}', '${cpu_architecture}', '${cpu_model}', '${cpu_mhz}', '${L2_cache}', '${total_mem}', '${timestamp}');
END
)
echo $insert_stmt

#3rd Step: execute insert statement on the DB.

export PGPASSWORD=$password
psql -h $psql_host -p $psql_port -U $user_name -d $db_name -c "$insert_stmt"
sleep 1

#4th Step: Save the host_id from PSQL to a local file

host_id=$(psql -h localhost -U postgres host_agent -c "select id from host_info where hostname='${hostname}'" | tail -3 | head -1 | xargs)
echo $host_id > ~/host_id
cat ~/host_id
