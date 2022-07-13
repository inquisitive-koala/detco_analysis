import argparse
import csv
import sys

def get_user_params():
	global input_csv_name
	global output_csv_name

	input_csv_name = sys.argv[1]
	output_csv_name = sys.argv[2]

AUTHOR = 2
def prettify_authors(row):
	newrow = row
	soup = row[AUTHOR]
	soup = soup.strip('[]')
	authors = soup.split(', ')
	authors = [a.strip("'") for a in authors]
	newrow[AUTHOR] = ', '.join(authors)
	if len(authors) > 1:
		print(newrow[AUTHOR])
	return newrow


if __name__ == '__main__':
	get_user_params()

	with open(input_csv_name, 'r') as incsv:
		with open(output_csv_name, 'a') as outcsv:
			rd = csv.reader(incsv, delimiter='\t', quotechar='"')
			wr = csv.writer(outcsv, delimiter='\t', quotechar='"')
			header = ['work_id', 'title', 'author', 'rating', 'category', 'fandom', 'relationship', 'character', 'additional tags', 'language', 'published', 'status', 'status date', 'words', 'chapters', 'comments', 'kudos', 'bookmarks', 'hits']
			wr.writerow(header)

			next(rd)		#skip first line
			for row in rd:
				wr.writerow(prettify_authors(row))

