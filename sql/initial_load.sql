-- Select database
use pvl_files;

-- Table for raw data from Spotify
drop table if exists pvl_files.pvl_spotify_history;
create table if not exists pvl_files.pvl_spotify_history (
    ts timestamp,
    username varchar(50),
    platform varchar(50),
    ms_played int,
    conn_country varchar(10),
    ip_addr_decrypted varchar(100),
    user_agent_decrypted varchar(100),
    master_metadata_track_name varchar(255),
    master_metadata_album_artist_name varchar(255),
    master_metadata_album_album_name varchar(255),
    spotify_track_uri varchar(255),
    episode_name varchar(255) null,
    episode_show_name varchar(255) null,
    spotify_episode_uri varchar(255) null,
    reason_start varchar(100),
    reason_end varchar(100),
    shuffle boolean null,
    skipped boolean null,
    offline boolean null,
    offline_timestamp varchar(100),
    incognito_mode boolean null
);

-- Allow loading data into tables from local disk
set global local_infile = 1;
show global variables like 'local_infile';

-- Insert data
truncate table pvl_files.pvl_spotify_history;
load data local infile '/data/output_csv/spotify_data_combined.csv'
into table pvl_files.pvl_spotify_history
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Recode platform field from specific to generic
alter table pvl_files.pvl_spotify_history
add column platform_group varchar(50) null
first;

update pvl_files.pvl_spotify_history
set platform_group = case when platform like 'iOS%' then 'iOS'
    when platform like 'android%' then 'Android'
    when platform like 'OS X%' or platform = 'osx' then 'Mac'
    when platform like 'windows%' then 'Windows'
    when platform like 'web_player%' then 'Web Player'
    when platform like '%Google_Home%' then 'Google Home'
    else 'Other' end
where platform_group is null;

/* -- check that all values from platform are coded correctly
select *
from pvl_files.pvl_spotify_history
where platform_group is null

select platform_group, platform, count(*)
from pvl_files.pvl_spotify_history
group by 1, 2
order by 1
*/

-- Convert milliseconds played to time format
alter table pvl_files.pvl_spotify_history
add column played_time time null;

update pvl_files.pvl_spotify_history
set played_time = date_format(sec_to_time((ms_played/1000)), '%H:%i:%s')
where played_time is null;

-- Hash username
alter table pvl_files.pvl_spotify_history
add column username_hash varchar(255) null
first;

update pvl_files.pvl_spotify_history
set username_hash = md5(username)
where username_hash is null;

-- Convert timestamp into simple date
alter table pvl_files.pvl_spotify_history
add column listen_date date null
first;

update pvl_files.pvl_spotify_history
set listen_date = date(ts)
where listen_date is null;

-- Order by timestamp
alter table pvl_files.pvl_spotify_history
order by ts asc;

-- Add ID field and set as primary key
/*
-- Timestamp doesn't work as a primary key - not unique
select count(ts), count(distinct ts)
from pvl_spotify_history

-- This script fails as ordering by timestamp is canceled
alter table pvl_files.pvl_spotify_history
add column id int primary key auto_increment
first;
*/

-- Adapted from https://stackoverflow.com/questions/7661181/how-to-add-auto-increment-primary-key-based-on-an-order-of-column
alter table pvl_files.pvl_spotify_history
add column id int
first;

set @a = 0;
update pvl_files.pvl_spotify_history
set id = (@a:=@a+1)
where id is null
order by ts asc;

alter table pvl_files.pvl_spotify_history
add primary key id (id);

alter table pvl_files.pvl_spotify_history
change id id int not null auto_increment;

-- Set blank values to null
update pvl_files.pvl_spotify_history
set master_metadata_track_name = null
where master_metadata_track_name = '';

update pvl_files.pvl_spotify_history
set master_metadata_album_artist_name = null
where master_metadata_album_artist_name = '';

update pvl_files.pvl_spotify_history
set master_metadata_album_album_name = null
where master_metadata_album_album_name = '';

update pvl_files.pvl_spotify_history
set spotify_track_uri = null
where spotify_track_uri = '';

-- Add new columns for analytics
alter table pvl_files.pvl_spotify_history
add column track_name varchar(255) null;

update pvl_files.pvl_spotify_history
set track_name = concat(master_metadata_album_artist_name, ' - ', master_metadata_track_name)
where track_name is null
and master_metadata_album_artist_name is not null
and master_metadata_track_name is not null;

-- Delete unnecessary/sensitive fields
alter table pvl_files.pvl_spotify_history
drop offline,
drop incognito_mode,
drop shuffle,
drop ts,
drop ms_played,
drop username,
drop platform,
drop ip_addr_decrypted,
drop user_agent_decrypted,
drop episode_name,
drop episode_show_name,
drop spotify_episode_uri,
drop offline_timestamp;