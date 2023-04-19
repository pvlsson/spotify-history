-- Show latest value: looks like data is capped at 14.10.2022
select max(listen_date)
from pvl_spotify_history
where track_name is not null;

-- Count listens per year: 2020 and 2021 have about 10k each
select date_format(listen_date, '%Y') as ListenYear, count(*)
from pvl_spotify_history
where track_name is not null
group by 1;

-- Group per Spotify account
select username_hash, count(*)
from pvl_spotify_history
group by 1;

-- Show most listened songs of all time
select track_name, count(ID) as listens
from pvl_spotify_history
where track_name is not null
group by track_name
order by listens desc;

-- Show number of listens per year
select track_name,
    count(case when year(listen_date) = 2020 then ID else null end) as Year2020,
    count(case when year(listen_date) = 2021 then ID else null end) as Year2021,
    count(case when year(listen_date) = 2022 then ID else null end) as Year2022
from pvl_spotify_history
where track_name is not null
group by track_name
order by Year2020 desc;

-- Rank most listened songs per year
with spotify_data as (
    select *
    from pvl_spotify_history
    where date_format(listen_date, '%Y') in (2020, 2021, 2022)
        and track_name is not null
)

, yearly_listens as (
    select track_name, date_format(listen_date, '%Y') as listen_year, count(ID) as listens
    from spotify_data
    group by track_name, listen_year
)

, alltime_ranking as (
    select track_name, count(ID) as alltime_listens,
        dense_rank() over(order by count(ID) desc) as alltime_rank
    from spotify_data
    group by track_name
)

, yearly_ranking as (
    select yearly_listens.*,
           dense_rank() over(partition by listen_year order by listens desc) as yearly_rank
    from yearly_listens
    group by track_name, listen_year
)

, total as (
    select yearly_ranking.*,
            -- concat(yearly_rank, ' (', listens, ' listens)') as rank_listens,
            -- concat(alltime_rank, ' (', alltime_listens, ' listens)') as alltime_rank_listens,
            alltime_listens,
            alltime_rank
    from yearly_ranking
        left join alltime_ranking using (track_name)
)

select track_name,
       max(alltime_rank) as Ranking,
       max(alltime_listens) as Listens,
       max(case when listen_year = 2020 then yearly_rank else null end) as Year2020,
       max(case when listen_year = 2021 then yearly_rank else null end) as Year2021,
       max(case when listen_year = 2022 then yearly_rank else null end) as Year2022
from total
group by track_name
order by Ranking;