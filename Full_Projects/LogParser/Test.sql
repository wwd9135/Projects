Q5 — Medium:
deliveries
delivery_id | driver  | region | distance_km | delivery_date | on_time
------------|---------|--------|-------------|---------------|--------
1           | William | North  | 45          | 2024-01-05    | true
2           | William | North  | 32          | 2024-01-12    | true
3           | William | South  | 67          | 2024-02-08    | false
4           | Sarah   | North  | 28          | 2024-01-15    | true
5           | Sarah   | South  | 55          | 2024-02-20    | true
6           | Sarah   | South  | 71          | 2024-03-10    | false
7           | John    | North  | 38          | 2024-02-15    | true
8           | John    | South  | 49          | 2024-03-01    | true
9           | John    | South  | 63          | 2024-03-20    | true
For each driver show their total deliveries, total distance, on time delivery percentage rounded to 2 decimal places, their rank by on time percentage, 
and their average distance per delivery rounded to 2 decimal places. Only show drivers with more than 2 deliveries.

Need a method to count on time = true, then divide that by total.

WITH one AS(
    SELECT driver, COUNT(*) AS total_deliveries, SUM(distance_km) AS total_distance, SUM(CASE WHEN on_time = true THEN 1 ELSE 0 END) AS onTime_count, ROUND(AVG(distance_km),2) AS average_distance
    FROM deliveries
    GROUP BY driver
), two AS (
    SELECT driver, total_deliveries, total_distance, onTime_count, average_distance,ROUND(onTime_count * 100.0 / total_deliveries) AS on_time_percentage
    FROM one
)
SELECT driver, total_deliveries, total_distance, average_distance, on_time_percentage, DENSE_RANK() OVER(ORDER BY on_time_percentage DESC) AS rnk
FROM two
WHERE total_deliveries > 2