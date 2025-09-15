with src as (
  select *
  from astrafy-de-proj.taxi_raw.taxi_trips
)
select
  cast(trip_id as int64) as trip_id,
  timestamp(pickup_datetime)  as pickup_ts,
  timestamp(dropoff_datetime) as dropoff_ts,
  cast(passenger_count as int64) as passenger_count,
  cast(trip_distance as float64) as trip_distance,
  timestamp_diff(timestamp(dropoff_datetime), timestamp(pickup_datetime), minute) as trip_minutes
from src
