FROM python:3.9

# Create folder in Docker container
RUN mkdir /spotify_project
RUN mkdir /spotify_project/output_csv
WORKDIR /spotify_project

# Copy the json files into the container
COPY /data/input_json /spotify_project/input_json

# Install the necessary packages
RUN pip install pandas

# Run a script to transform the json files into csv files and stack them into a single csv
COPY /py/transform.py /spotify_project
CMD python /spotify_project/transform.py /spotify_project/input_json /spotify_project/output_csv/ ; sleep infinity