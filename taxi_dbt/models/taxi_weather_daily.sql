with trip_info as (
  select
    trip_date,
    trip_minutes,
    trip_miles * 1.6 as trip_kms
  from {{ ref('stg_taxi_trips') }}
),
by_day as (
  select
    trip_date,
    avg(trip_minutes) as avg_trip_minutes,
    avg(trip_kms)     as avg_trip_kms,
    count(*)          as trips
  from trip_info
  group by trip_date
),
day_weather as (
  select
    weather_date as trip_date,
    temp_avg_c,
    temp_min_c,
    temp_max_c,
    wind_max,
    wind_avg,
    prcp_mm
  from {{ source('taxi_raw', 'weather_daily') }}
)
select
  d.trip_date,
  d.trips,
  round(d.avg_trip_minutes, 1) 	as avg_trip_minutes,
  round(d.avg_trip_kms,   1) 	as avg_trip_kms,
  round(w.temp_avg_c, 1) 	as temp_avg_c,
  round(w.temp_min_c, 1) 	as temp_min_c,
  round(w.temp_max_c, 1) 	as temp_max_c,
  round(w.wind_max, 1) 		as wind_max,
  round(w.wind_avg, 1)		as wind_avg,
  round(w.prcp_mm, 1) 		as prcp_mm
from by_day d
left join day_weather w using (trip_date)
order by d.trip_date

-- test