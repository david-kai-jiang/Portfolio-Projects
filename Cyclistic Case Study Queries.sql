  ----- Combine all the data into one table -------------------------------------------
  
  CREATE TABLE `rare-ridge-375312.cyclistic`.combined_trip_data AS (
  SELECT *
  FROM `rare-ridge-375312.cyclistic.01_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.02_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.03_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.04_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.05_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.06_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.07_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.08_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.09_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.10_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.11_2022`
  UNION DISTINCT

  SELECT *
  FROM `rare-ridge-375312.cyclistic.12_2022`

  )


SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data



----- Calculate ride_length -----------------------------------------------------


SELECT started_at, ended_at, (ended_at - started_at) AS ride_length
FROM `rare-ridge-375312.cyclistic`.combined_trip_data


ALTER TABLE `rare-ridge-375312.cyclistic`.combined_trip_data
ADD COLUMN ride_length INTERVAL


UPDATE `rare-ridge-375312.cyclistic`.combined_trip_data AS a
SET a.ride_length = (ended_at - started_at)
WHERE a.ride_ID IS NOT null


------ Inspect data for anomalies -------------------------------------------

-- Check if their is a rider type other than member or casual (there are none)
SELECT DISTINCT member_casual
FROM `rare-ridge-375312.cyclistic`.combined_trip_data



-- Check if latitude and longitude are in the correct range (-90 to 90 for latitude and -180 to 180 for longitude) (there are all ok)
SELECT 
min (end_lng) AS min_end_lng, 
max(end_lng) AS max_end_lng, 
min (end_lat) AS min_end_lat, 
max(end_lat) AS max_end_lat, 
min (start_lng) AS min_start_lng, 
max(start_lng) AS max_start_lng, 
min (start_lat) AS min_start_lat, 
max(start_lat) AS max_start_lat
FROM `rare-ridge-375312.cyclistic`.combined_trip_data



-- Check if there are ride types other than electric, classic or docked (there are none)
SELECT rideable_type, COUNT(*)
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
GROUP BY rideable_type



-- Check if there are duplicate ride_ids (there are some)
SELECT ride_id, COUNT(ride_id) 
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
GROUP BY ride_id
HAVING COUNT(ride_id) > 1



-- Check if there are null start dates or end dates (there are none)
SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE started_at IS null OR ended_at IS null



--Check if there are null start/end longitudes or start/end latitudes (there are some)
SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE (start_lng IS null OR end_lng IS null OR start_lat IS null OR end_lat is null)



----- Exclude data with anomalies ------------------------------------------

ALTER TABLE `rare-ridge-375312.cyclistic`.combined_trip_data
ADD COLUMN exclude_row BOOL



-- Exlude cases where start time is greater than end time
SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE started_at >= ended_at
ORDER BY ride_length

UPDATE `rare-ridge-375312.cyclistic`.combined_trip_data
SET exclude_row = true
WHERE started_at >= ended_at



-- Exclude null start and end stations
SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE end_station_name IS null OR start_station_name IS null

UPDATE `rare-ridge-375312.cyclistic`.combined_trip_data
SET exclude_row = true
WHERE end_station_name IS null OR start_station_name IS null



-- Check if there are still unexcluded null start/end longitudes or start/end latitudes (there are none anymore)
SELECT *
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE (start_lng IS null OR end_lng IS null OR start_lat IS null OR end_lat is null) AND exclude_row IS null




---- Create queries for data visualizations ----------------------------------------

SELECT COUNT(*)
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null



-- Number of casual riders and member riders
SELECT member_casual, COUNT(ride_id) AS number_of_riders
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null
GROUP BY member_casual



-- Number of riders per month in the year per rider type (casual or member)
SELECT member_casual, CONCAT(EXTRACT(YEAR FROM started_at), "-", EXTRACT(MONTH FROM started_at)) AS year_month, COUNT(ride_id) AS number_of_riders
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null
GROUP BY member_casual, year_month



-- Number of riders per day of week per rider type (casual or member)
SELECT member_casual, day_of_week, COUNT(ride_id) AS number_of_riders
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null
GROUP BY member_casual, day_of_week



-- Number of riders per hour of day per rider type (casual or member)
SELECT member_casual, EXTRACT(HOUR FROM started_at) AS hour_of_day, COUNT(ride_id) AS number_of_riders
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null
GROUP BY member_casual, hour_of_day



-- Number of riders riding under 1 hour per rider type
SELECT member_casual, COUNT(*) AS count_under_1_hr
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null AND ride_length <= MAKE_INTERVAL(hour => 1)
GROUP BY member_casual
ORDER BY member_casual



-- Number of riders riding between 1 hour 2 hours per rider type
SELECT member_casual, COUNT(*) AS count_between_1_and_2_hr
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null AND ride_length > MAKE_INTERVAL(hour => 1) AND ride_length <= MAKE_INTERVAL(hour => 2)
GROUP BY member_casual
ORDER BY member_casual



-- Number of riders riding more than 2 hours per rider type
SELECT member_casual, COUNT(*) AS count_over_2_hr
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null AND ride_length > MAKE_INTERVAL(hour => 2)
GROUP BY member_casual
ORDER BY member_casual



-- Number of riders riding 0-10 min, 11-20 min, 21-30 min, 31-40 min, 41-50 min, 51-60 min
SELECT member_casual, COUNT(*) AS count_under_10_min
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null AND ride_length <= MAKE_INTERVAL(minute => 10)
GROUP BY member_casual
ORDER BY member_casual
-- Repeat this query 5 times for 11-20 min, 21-30 min, 31-40 min, 41-50 min, 51-60 min
SELECT member_casual, COUNT(*) AS count_51_60_min
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null AND ride_length >= MAKE_INTERVAL(minute => 51) AND ride_length <= MAKE_INTERVAL(minute => 60)
GROUP BY member_casual
ORDER BY member_casual



-- Count number of casual or member riders that use each bike type (eletric, docked or classic)
SELECT member_casual, rideable_type, COUNT(rideable_type) AS count
FROM `rare-ridge-375312.cyclistic`.combined_trip_data
WHERE exclude_row IS null
GROUP BY member_casual, rideable_type



-- Count the popular start and end stations points of casual riders (top 30)
WITH temp_table AS (
  SELECT CONCAT(start_station_name, " - ", end_station_name) AS popular_start_end_points
  FROM `rare-ridge-375312.cyclistic`.combined_trip_data
  WHERE exclude_row IS null AND member_casual = "casual" AND ride_length <= MAKE_INTERVAL(minute => 20)
)

SELECT popular_start_end_points, COUNT(popular_start_end_points) AS count_num
FROM temp_table
GROUP BY popular_start_end_points
ORDER BY count_num DESC
LIMIT 30



-- Count the popular start and end stations points of members riders (top 30)
WITH temp_table AS (
  SELECT CONCAT(start_station_name, " - ", end_station_name) AS popular_start_end_points
  FROM `rare-ridge-375312.cyclistic`.combined_trip_data
  WHERE exclude_row IS null AND member_casual = "member"
)

SELECT popular_start_end_points, COUNT(popular_start_end_points) AS count_num
FROM temp_table
GROUP BY popular_start_end_points
ORDER BY count_num DESC
LIMIT 30
