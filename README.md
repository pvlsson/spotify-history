# spotify-history
Export my listening data from Spotify, combine files in Docker, and query using SQL

## Purpose
Prepare data on my music listening habits over the past years for subsequent analyses in SQL/Python/Tableau.

## Tasks
1. Export data from Spotify
2. Convert .json into .csv
3. Load .csv into local MySQL server, clean up, remove sensitive data
4. Analyze via SQL

## 1. Export listening data
Request extended streaming history from Spotify → Account → Privacy settings.  The data arrives within a few 
weeks per email in .json format.

## 2. Convert to .csv
I had three Spotify accounts over the past three years, so I needed to merge all their data in a single file.

I setup a Docker container with the task to take .json files from my local machine, convert them into a single .csv. Dockerfile and Python script were prepared largely with the help of ChatGPT.

The workflow looks like this:
1. Open project folder
2. Build image container from Dockerfile in that folder: `docker build -t spotify_project .`
3. Run Docker container based on that image in detached mode `docker run -d --rm spotify_project`
4. While the container is running, run `docker cp` to copy-paste the final .csv file from the container to my computer
5. Stop container using `docker stop`

## 3. Transform data in MySQL
Firstly, I get my local MySQL server up and running. The easiest way to setup MySQL on a Mac is using Homebrew. If 
you are on Windows, you can install XAMPP which includes MariaDB database.

After connecting to local MySQL server, I run `initial_load.sql`.

I delete the following sensitive data:
- IP address
- Listen timestamp (replaced with date)
- Device name (replaced with generic platform name, e.g. iOS)
- User name (hash with MD5)

Also, I add an auto increment ID field as a primary key to the table.

## 4. Analyze using SQL
I did some analyses of the final dataset in `analyze.sql`.

I am planning to delve deeper into the data, possibly using Python or Tableau.