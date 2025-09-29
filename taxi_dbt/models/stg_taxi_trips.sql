{{ config(materialized='table') }}
with src as (
  select
    unique_key,
    taxi_id,
    trip_start_timestamp,
    trip_end_timestamp,
    trip_seconds,
    trip_miles,
    pickup_community_area,
    dropoff_community_area,
    pickup_census_tract,
    dropoff_census_tract,
    payment_type,        
    company,
    pickup_latitude,
    pickup_longitude,
    pickup_location,
    dropoff_latitude,
    dropoff_longitude,
    dropoff_location
  from {{ source('chicago_taxi', 'taxi_trips') }}
  where date(trip_start_timestamp) >= date('2023-06-01')
    and date(trip_start_timestamp) <=  date('2023-12-31')
)
select
  *,
  date(trip_start_timestamp) as trip_date,	-- to have also the date as a field
  safe_divide(trip_seconds, 60) as trip_minutes  -- easier to understand
from src
