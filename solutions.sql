/* Additional requested queries


This will output hosts grouped by # of CPU and by their memory sized in descending order*/
SELECT cpu_number, host_id, total_mem 
FROM (
SELECT cpu_number, host_id, total_mem, RANK() OVER(PARTITION BY cpu_number ORDER BY total_mem DESC)
FROM host_info
) AS s

/*This will get the average memory used in % for every 5 minute interval, for each host*/
SELECT host_id, host_name, total_memory, AVG(used_mem_percent) OVER(PARTITION BY five_min_interval ORDER BY host_id) as used_memory_percentage
FROM (
	SELECT a.host_id, 
	b.hostname as host_name, 
	b.total_mem as total_memory, 
	a.memory_free, 
	(date_trunc('hour', a.timestamp) + date_part('minute', a.timestamp)::int / 5 * interval '5 min') as five_min_interval,
	((b.total_mem-a.memory_free)/b.total_mem) as used_mem_percent
	FROM host_usage a
	INNER JOIN host_info b
	ON a.host_id = b.id
) AS x