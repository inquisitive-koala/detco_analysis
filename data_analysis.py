import argparse
import csv
import matplotlib.pyplot as plt

kudos_blocklist = ['39054240',
			 '27508378',
			 '37681951',
			 '18386918',
			 '37665913',
			 '31307924',
			 '39031080',
			 '37672654',
			 '39069660',
			 '28150173',
			 '37713634',
			 '36152419',
			 '34614868']

def get_user_params():
	global input_csv_name

	parser = argparse.ArgumentParser(description='Extract metadata from a fic csv')
	parser.add_argument(
		'csv', metavar='csv', 
		help='the name of the csv with the base set of metadata')

	args = parser.parse_args()
	input_csv_name = args.csv

class Work(object):
	def __init__(self, row):
		self.work_id = row[0]
		self.title = row[1]
		self.author = [x.strip("'") for x in row[2].lstrip('[').rstrip(']').split(', ')]
		self.rating = row[3]
		self.categories = row[4].split(', ')
		self.fandoms = row[5].split(', ')
		self.relationships = row[6].split(', ')
		self.characters = row[7].split(', ')
		self.additional_tags = row[8]
		self.language = row[9]
		self.published = row[10]
		self.status = row[11]
		self.status_date = row[12]
		self.words = row[13]
		pair = row[14].split('/')
		self.chapters = pair[0]
		self.expected_chapters = pair[1]
		self.comments = 0 if row[15] == 'null' else int(row[15])
		self.kudos = 0 if row[16] == 'null' else int(row[16])
		self.bookmarks = 0 if row[17] == 'null' else int(row[17])
		self.hits = 0 if row[18] == 'null' else int(row[18])

	def __str__(self):
		return self.work_id + ' ' + self.title + ' ::: ' + self.rating

	def __repl__(self):
		return __str__(self)

# Sanity check
def most_kudosed(works):
	works.sort(key=lambda w: w.kudos, reverse=True)
	for w in works[:10]:
		print(w.work_id, w.title, w.kudos)

def highest_kh_ratio(works):
	works.sort(key=lambda w: w.kudos/float(w.hits), reverse=True)
	for w in works[:20]:
		print(w, w.comments, w.kudos, w.bookmarks, w.hits)

def visualize_all_kh_ratios(works):
	ratios = [w.kudos/float(w.hits) for w in works]
	plt.hist(ratios, bins=100)
	plt.title('All')
	plt.show()

def is_romantic(work):
	return any(['/' in r for r in work.relationships])

def filter_ship_strict(ship_tag):
	return lambda lst : [w for w in lst if len(w.relationships) == 1 and ship_tag == w.relationships[0]]
def filter_ship_first(ship_tag):
	return lambda lst : [w for w in lst if w.relationships and ship_tag == w.relationships[0]]
def filter_ship_loose(ship_tag):
	return lambda lst : [w for w in lst if ship_tag in w.relationships]

def visualize_shinran_kh_ratios(works):
	filter_shinran = filter_ship_strict('Kudou Shinichi | Edogawa Conan/Mouri Ran')
	ratios = [w.kudos/float(w.hits) for w in filter_shinran(works)]
	plt.hist(ratios, bins=10)
	plt.title('ShinRan')
	plt.show()

def visualize_kaishin_kh_ratios(works):
	filter_kaishin = filter_ship_loose('Kudou Shinichi | Edogawa Conan/Kuroba Kaito | Kaitou Kid')
	print(len(filter_kaishin(works)))
	ratios = [w.kudos/float(w.hits) for w in filter_kaishin(works)]
	plt.hist(ratios, bins=15)
	plt.title('KaiShin')
	plt.show()

def visualize_coai_kh_ratios(works):
	filter_coai = filter_ship_strict('Haibara Ai | Miyano Shiho/Kudou Shinichi | Edogawa Conan')
	ratios = [w.kudos/float(w.hits) for w in filter_coai(works)]
	plt.hist(ratios, bins=20)
	plt.title('CoAi')
	plt.show()

def visualize_romantic_kh_ratios(works):
	ratios = [w.kudos/float(w.hits) for w in works if is_romantic(w)]
	plt.hist(ratios, bins=50)
	plt.title('Romantic')
	plt.show()

def visualize_platonic_kh_ratios(works):
	ratios = [w.kudos/float(w.hits) for w in works if not is_romantic(w)]
	plt.hist(ratios, bins=30)
	plt.title('Platonic')
	plt.show()

def visualize_kh_by_rating(works):
	n_works = [w for w in works if w.rating == 'Not Rated']
	g_works = [w for w in works if w.rating == 'General Audiences']
	t_works = [w for w in works if w.rating == 'Teen And Up Audiences']
	m_works = [w for w in works if w.rating == 'Mature']
	e_works = [w for w in works if w.rating == 'Explicit']

	plt.hist([w.kudos/float(w.hits) for w in g_works], bins=30)
	plt.hist([w.kudos/float(w.hits) for w in t_works], bins=20)
	plt.hist([w.kudos/float(w.hits) for w in m_works], bins=10)
	plt.hist([w.kudos/float(w.hits) for w in e_works], bins=10)
	plt.title('By rating')
	plt.show()


if __name__ == '__main__':
	get_user_params()

	all_works = []
	with open(input_csv_name, 'r') as incsv:
		rd = csv.reader(incsv, delimiter='\t', quotechar='"')
		next(rd)		# skip first line
		for row in rd:
			all_works.append(Work(row))

	visualize_kaishin_kh_ratios(all_works)
	works = [w for w in all_works if not w.work_id in kudos_blocklist]
	#highest_kh_ratio(works)
	visualize_all_kh_ratios(works)
	visualize_kh_by_rating(works)
