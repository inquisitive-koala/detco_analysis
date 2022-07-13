'''
Count the number of fics in a list that have a particular tag 
(or any of its alternate tags as defined by AO3's tag wranglers)
'''

import os
import re
import time
import requests
import csv
import sys
import datetime
import argparse
import pickle


url = ""
input_csv_name = ""
output_csv_name = ""
delay = 5
retries = 3

FANDOM = 5
RELATIONSHIP = 6
CHARACTER = 7 
ADDITIONAL_TAGS = 8


def get_user_params():
	global input_csv_name
	global output_csv_name
	global map_pickle_name
	
	parser = argparse.ArgumentParser(description='Extract metadata from a fic csv')
	parser.add_argument(
		'csv', metavar='csv', 
		help='the name of the csv with the base set of metadata')
	parser.add_argument(
		'out_csv', metavar='out_csv', 
		help='the name of the output csv')
	parser.add_argument(
		'map_pickle', metavar='map_pickle', 
		help='the name of the canonical map pickle file')

	args = parser.parse_args()
	input_csv_name = args.csv
	output_csv_name = args.out_csv
	map_pickle_name = args.map_pickle

def canonicalize_tags(row, canonical_map):
	c_row = row
	c_tags = ', '.join([canonical_map[t] for t in row[FANDOM].split(', ') if t])
	c_row[FANDOM] = c_tags
	c_tags = ', '.join([canonical_map[t] for t in row[RELATIONSHIP].split(', ') if t])
	c_row[RELATIONSHIP] = c_tags
	c_tags = ', '.join([canonical_map[t] for t in row[CHARACTER].split(', ') if t])
	c_row[CHARACTER] = c_tags
	#c_tags = ', '.join([canonical_map[t] for t in row[ADDITIONAL_TAGS].split(', ')])
	#c_row[ADDITIONAL_TAGS] = c_tags

	return c_row

def main():
	csv.field_size_limit(1000000000)  # up the field size because stories are long
	get_user_params()
	
	canonical_map = {}

	with open(input_csv_name, 'r') as incsv:
		rd = csv.reader(incsv, delimiter='\t', quotechar='"')
		next(rd)		# skip first line
		canonical_map = pickle.load(open(map_pickle_name, 'rb'))

	with open(input_csv_name, 'r') as incsv:
		with open(output_csv_name, 'a') as outcsv:
			rd = csv.reader(incsv, delimiter='\t', quotechar='"')
			wr = csv.writer(outcsv, delimiter='\t', quotechar='"')
			next(rd)		#skip first line
			for row in rd:
				wr.writerow(canonicalize_tags(row, canonical_map))


main()