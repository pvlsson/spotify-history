import sys
import os
import pandas as pd

# Get the input and output directory paths from command line arguments
input_dir = sys.argv[1]
output_file = sys.argv[2]

# Create an empty list to store the dataframes
dfs = []

# Loop through the input directory and read each JSON file into a dataframe
for filename in os.listdir(input_dir):
    if filename.endswith('.json'):
        path = os.path.join(input_dir, filename)
        df = pd.read_json(path)
        dfs.append(df)

# Concatenate the dataframes into a single dataframe
combined_df = pd.concat(dfs)

# Write the concatenated dataframe to a CSV file
output_path = os.path.join(output_file, 'spotify_data_combined.csv')
combined_df.to_csv(output_path, index=False)