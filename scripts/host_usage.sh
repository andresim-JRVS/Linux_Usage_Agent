#!/bin/bash

psql_host=$1
port=$2
db_name=$3
user_name=$4
password=$5

# Step 0: Write some functions to get appropriate info

get_timestamp () {
timestamp=$(vmstat -t | egrep -v 'timestamp|UTC' | awk '{print $18" "$19}' | xargs)
}

get_memory_free () {
memory_free=$(vmstat -SM | egrep -v 'memory|free' | awk '{print $4}' | xargs)
}

get_cpu_idel () {
cpu_idel=$(vmstat | egrep -v 'cpu|id' | awk '{print $15}' | xargs)
}

get_cpu_kernel () {
cpu_kernel=$(vmstat | egrep -v 'cpu|sy' | awk '{print $14}' | xargs)
}

get_disk_io () {
disk_io=$(vmstat -d | egrep -v 'IO|cur' | awk '{print $10}' | xargs)
}

get_disk_avail () {
disk_avail=$(df -m --output=avail /dev/sda1 | tail -n 1)
}

execute_sql () {
sql_stmt=$1
export PGPASSWORD=$password
psql -h $psql_host -p $port -U user_name -d $db_name -c "$sql_stmt"
sleep 1
}

get_host_id () {
host_id=$(cat ~/host_id)
}

# Step 1: Get all the info into variables (by running functions)

get_timestamp
get_host_id
get_memory_free
get_cpu_idel
get_cpu_kernel
get_disk_io
get_disk_avail

# Step 2: Constuct an insert statement to put usage statistics into psql (also get id for the host)

insert_stmt=$(cat <<-END
INSERT INTO host_usage ("timestamp", host_id, memory_free, cpu_idel, cpu_kernel, disk_io, disk_available) 
VALUES('${timestamp}', '${host_id}', '${memory_free}', '${cpu_idel}', '${cpu_kernel}', '${disk_io}', '${disk_avail}');
END
)
echo $insert_stmt

# Step 3: Execute insert statement on the DB

execute_sql "$insert_stmt"
