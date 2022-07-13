'''
Count the number of fics in a list that have a particular tag 
(or any of its alternate tags as defined by AO3's tag wranglers)
'''

import os
from bs4 import BeautifulSoup
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

TAG_ID = 0
TAG_NAME = 2
IS_CANONICAL = 3
MERGER_ID = 5

def get_user_params():
	global input_csv_name
	global tag_csv_name
	global out_pickle_name

	parser = argparse.ArgumentParser(description='Extract metadata from a fic csv')
	parser.add_argument(
		'csv', metavar='csv', 
		help='the name of the csv with the base set of metadata')
	parser.add_argument(
		'tag_csv', metavar='tag_csv', 
		help='the name of the tag csv')
	parser.add_argument(
		'out_pickle', metavar='out_pickle',
		help='the name of the file to write the canonical map to')

	args = parser.parse_args()
	input_csv_name = args.csv
	tag_csv_name = args.tag_csv
	out_pickle_name = args.out_pickle

def extract_unique_tags(rd):
	unique_tags = set()
	for row in rd:
		unique_tags |= set(row[FANDOM].split(', '))
		unique_tags |= set(row[RELATIONSHIP].split(', '))
		unique_tags |= set(row[CHARACTER].split(', '))
		#unique_tags |= set(row[ADDITIONAL_TAGS].split(', '))
	return unique_tags - {''}

# From cached CSV
def get_cached_canonical_map(rd, tag_rd):
	unique_tags = extract_unique_tags(rd)
	tags_to_canonical_ids = dict.fromkeys(unique_tags)	
	canonical_ids_to_tags = {}
	for row in tag_rd:
		idx = int(row[TAG_ID])
		name = row[TAG_NAME]
		is_canonical = row[IS_CANONICAL] == 'true'
		if name in unique_tags:
			if is_canonical:
				tags_to_canonical_ids[name] = idx
			if row[MERGER_ID]:
				tags_to_canonical_ids[name] = int(row[MERGER_ID])
			# else will leave blank since it's possible it was merged in the future.
		if is_canonical:
			canonical_ids_to_tags[idx] = name
			
	canonical_map = dict.fromkeys(unique_tags)
	for t in unique_tags:
		if tags_to_canonical_ids[t]:	# had a merger id in the spreadsheet
			canonical_map[t] = canonical_ids_to_tags[tags_to_canonical_ids[t]]

	return canonical_map
	
# AO3-facing code
def build_tag_url(tag): 
	munged = tag.replace('/', '*s*')
	munged = munged.replace('.', '*d*')
	munged = munged.replace('#', '*h*')
	munged = munged.replace('?', '*q*')
	return "https://archiveofourown.org/tags/" + munged

def get_webpage(tag, delay=delay):
	url = build_tag_url(tag)
	time.sleep(delay)
	return requests.get(url)

def get_canonical_tag(tag):
	for i in range(retries):
		req = get_webpage(tag, delay*(i+1)*1.1)
		soup = BeautifulSoup(req.text, "lxml")
		homeprofile = soup.find(class_="tag home profile")
		if homeprofile:
			break
		else:
			print('RETRY', i+1)
	if not homeprofile:
		return

	texts = homeprofile.select('p')
	for text in texts:
		if "It's a common tag." in text.text:
			return tag
		if "This tag has not been marked common and can't be filtered on" in text.text:
			return tag

	# If not a canonical tag, and has been synned, get canonical
	mergers = homeprofile.find(class_="merger module")
	if mergers:
		tag = homeprofile.select_one('p > a').text
		return tag

def add_to_canonical_map(canonical_map):
	for t in canonical_map.keys():
		if not canonical_map[t]:
			print(t)
			ctag = get_canonical_tag(t)
			print(ctag)
			if not ctag:
				canonical_map[t] = 'ERROR'
				continue
			canonical_map[t] = ctag
	return canonical_map

def get_canonical_map():
	canonical_map = {}

	with open(input_csv_name, 'r') as incsv:
		with open(tag_csv_name, 'r') as tagcsv:
			rd = csv.reader(incsv, delimiter='\t', quotechar='"')
			tag_rd = csv.reader(tagcsv, delimiter=',', quotechar='"')
			next(rd)		# skip first line
			next(tag_rd)
			canonical_map = get_cached_canonical_map(rd, tag_rd)
	print('total num tags: ', len(canonical_map))

	count = 0
	for t in canonical_map.keys():
		if not canonical_map[t]:
			count += 1
	print('remaining tags ', count)
	canonical_map = add_to_canonical_map(canonical_map)	
	return canonical_map

def main():
	get_user_params()
	canonical_map = get_canonical_map()
	pickle.dump(canonical_map, open(out_pickle_name, 'wb'))

main()