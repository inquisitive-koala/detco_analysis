# Load data ---------------
# Cmd-Alt-T to run
library(tidyr)
library(dplyr)
library(ggplot2)
library(ggcorrplot)
library(forcats)

data = read.csv(file='/path/to/file', sep='\t', stringsAsFactors=FALSE)
data$work_id = as.integer((data$work_id))
# Will be NA if author is anonymous
data$author = strsplit(data$author, ', ')
data$category = strsplit(data$category, ', ')
data$num_category = sapply(data$category, length)
data$fandom = strsplit(data$fandom, ', ')
data$num_fandom = sapply(data$fandom, length)
data$relationship = strsplit(data$relationship, ', ')
data$num_relationship = sapply(data$relationship, length)
data$character = strsplit(data$character, ', ')
data$num_character = sapply(data$character, length)
data$additional.tags = strsplit(data$additional.tags, ', ')
data$published = as.Date(data$published)
data$status.date = as.Date(data$status.date)
data$words = as.integer(ifelse(is.na(data$words), "0", data$words))
data$current_chapters = as.integer(sapply(strsplit(data$chapters, '/'), "[[", 1))
# Warning: will be NA if expected chapter count is ?
data$expected_chapters = as.integer(sapply(strsplit(data$chapters, '/'), "[[", 2))
data$comments = as.integer(ifelse(data$comments=="null", "0", data$comments))
data$kudos = as.integer(ifelse(data$kudos=="null", "0", data$kudos))
data$bookmarks = as.integer(ifelse(data$bookmarks=="null", "0", data$bookmarks))
data$hits = as.integer(data$hits)
data$age = as.numeric(Sys.Date()-data$published)

data_long = data
data_long = unnest(data_long, author, keep_empty = TRUE)
data_long = unnest(data_long, category, keep_empty = TRUE)
data_long = unnest(data_long, fandom, keep_empty = TRUE)
data_long = unnest(data_long, relationship, keep_empty = TRUE)
data_long = unnest(data_long, character, keep_empty = TRUE)
spammed = list('39054240', '27508378', '37681951', '18386918', '37665913', 
               '31307924', '39031080', '37672654', '39069660', '28150173', 
               '37713634', '36152419', '34614868')

KAISHIN = 'Kudou Shinichi | Edogawa Conan/Kuroba Kaito | Kaitou Kid'
SHINRAN = 'Kudou Shinichi | Edogawa Conan/Mouri Ran'
COAI = 'Haibara Ai | Miyano Shiho/Kudou Shinichi | Edogawa Conan'
AKAM = 'Akai Shuuichi | Okiya Subaru/Amuro Tooru | Furuya Rei'


# KH visualizations ------------
data_long %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(!(work_id %in% spammed)) %>%
  filter(!(rating == 'Not Rated')) %>%
  ggplot( aes(x=kudos/hits, group=factor(rating, levels=c('Explicit', 'Mature', 'Teen And Up Audiences', 'General Audiences')), fill=rating)) +
    geom_density(adjust=1.5, alpha=.7) +
    scale_fill_discrete(breaks=c('General Audiences', 'Teen And Up Audiences', 'Mature', 'Explicit'))

data_long %>%
  filter(!(work_id %in% spammed)) %>%
  filter(relationship %in% c(KAISHIN, SHINRAN, COAI, AKAM)) %>%
  filter(num_relationship == 1) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  ggplot( aes(x=kudos/hits, group=factor(relationship, levels=c(COAI, SHINRAN, AKAM, KAISHIN)), fill=relationship)) +
    geom_density(adjust=1.5, alpha=.7) +
    scale_fill_discrete(breaks=c(COAI, SHINRAN, AKAM, KAISHIN))

data_long %>%
  filter(num_category == 1) %>%
  filter(category %in% c('F/F', 'M/M', 'F/M')) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(!(work_id %in% spammed)) %>%
  ggplot( aes(x=kudos/hits, group=factor(category, levels=c('F/M', 'M/M', 'F/F', 'Gen')), fill=category)) +
    geom_density(adjust=1.5, alpha=.7)

# HT visualizations ---------
data_all = distinct(data_long, work_id, .keep_all=TRUE)
data_all %>%
  arrange(hits/age) %>%
  tail(10) %>%
  mutate(title = fct_reorder(title, hits/age)) %>%
  ggplot( aes(x=title, y=hits/age)) +
    geom_bar(stat="identity") +
    coord_flip() +
    ylab('hits/time')

# Hits per day by rating
mymode <- function(x){
  d<-density(x)
  return(d$x[which(d$y==max(d$y)[1])])
}

data_all %>% 
  group_by(rating) %>%
  summarize(mode=mymode(hits/age), avg=mean(hits/age), stddev=sd(hits/age)) %>%
  arrange(mode)

data %>%
  ggplot(aes(x=hits/age, group=factor(rating, levels=c('Explicit', 'Mature', 'Not Rated', 'Teen And Up Audiences', 'General Audiences')), fill=rating)) +
    geom_density(adjust=1.5, alpha=0.4) +
    xlim(0, 30) +
    xlab('hits/day') + 
    scale_fill_discrete(breaks=c('General Audiences', 'Teen And Up Audiences', 'Not Rated', 'Mature', 'Explicit'))

data %>%
  ggplot(aes(x=hits/age, group=num_relationship, fill=num_category)) +
  geom_density(adjust=1.5, alpha=0.8) +
  xlim(0, 30) +
  xlab('hits/day')

# Hits per day by category
data_all %>% 
  group_by(num_relationship) %>%
  summarize(average=mean(hits/age), stddev=sd(hits/age)) %>%
  arrange(num_relationship) %>%
  ggplot(aes(x = num_relationship, y = average)) +
    geom_bar(stat='identity', fill='skyblue', alpha=0.7) +
    geom_errorbar( aes(x=num_relationship, ymin=average-stddev, ymax=average+stddev), width=0.4, colour="orange", alpha=0.9, size=1)

# Fics over time -----------
pubs_hist = hist(data$published[data$published >= as.Date('2009-11-15')], "months", freq=TRUE, plot=FALSE)
pubs = data.frame(date=as.Date(pubs_hist$mids, origin='1970-01-01'), delta=pubs_hist$counts, count=cumsum(pubs_hist$counts))
pubs %>%
  ggplot(aes(x=date, y=delta)) +
    geom_point() + geom_line() +
    ylab("number new fics")

# fics/author etc ---------------
f_per_a = data_long %>% 
  distinct(work_id, author) %>% 
  filter(author != 'orphan_account') %>%
  group_by(author) %>% 
  summarize(fics = n())
f_per_a %>%
  arrange(fics) %>%
  tail(20) %>%
  mutate(author = fct_reorder(author, fics)) %>%
  ggplot( aes(x=author, y=fics)) +
    geom_bar(stat='identity') + coord_flip() +
    ylab('fics/author')
summarize(f_per_a, mean=mean(fics))

# authors by wordcount
w_per_a = distinct(data_long, work_id, author, .keep_all=TRUE) %>%
  filter(author != 'orphan_account') %>%
  group_by(author) %>%
  summarize(words = sum(words))
w_per_a %>%
  arrange(words) %>%
  tail(20) %>%
  mutate(author = fct_reorder(author, words)) %>%
  ggplot( aes(x=author, y=words)) +
    geom_bar(stat='identity') + coord_flip() +
    ylab('words/author')
summarize(w_per_a, mean=mean(words))

# authors by kudos
k_per_a = distinct(data_long, work_id, author, .keep_all=TRUE) %>%
  filter(author != 'orphan_account') %>%
  group_by(author) %>%
  summarize(kudos = sum(kudos))
k_per_a %>%
  arrange(kudos) %>%
  tail(25) %>%
  mutate(author = fct_reorder(author, kudos)) %>%
  ggplot( aes(x=author, y=kudos)) +
  geom_bar(stat='identity') + coord_flip() +
  ylab('kudos/author')
summarize(k_per_a, mean=mean(kudos))

# authors by comments
c_per_a = distinct(data_long, work_id, author, .keep_all=TRUE) %>%
  filter(author != 'orphan_account') %>%
  group_by(author) %>%
  summarize(comments = sum(comments))
c_per_a %>%
  arrange(comments) %>%
  tail(20) %>%
  mutate(author = fct_reorder(author, comments)) %>%
  ggplot( aes(x=author, y=comments)) +
  geom_bar(stat='identity') + coord_flip() +
  ylab('comments/author')
summarize(c_per_a, mean=mean(comments))

# intersection of top authors by fics and words
print('Most Prolific')
intersect(filter(f_per_a, rank(-fics) <= 20)[1], filter(w_per_a, rank(-words) <= 20)[1])

# ships/char
ships = distinct(data_long, relationship)
ships$character = strsplit(ships$relationship, '/| & ')
ships$type = ifelse(grepl('/', ships$relationship), 'romantic', 'unknown')
ships$type = ifelse(grepl(' & ', ships$relationship), 'platonic', ships$type)
ships = unnest(ships, character, keep_empty=TRUE)

ships %>%
  add_count(character) %>%
  filter(dense_rank(-n) <= 10) %>%
  arrange(n) %>%
  mutate(character = fct_reorder(character, n)) %>%
  ggplot(aes(fill=type, x=character)) +
    geom_bar(position='dodge', stat='count') +
    coord_flip() +
    ylab('num ships') +
    scale_fill_discrete(breaks=c('romantic', 'platonic'))

# fics/char
fics_per_char = data_long %>%
  distinct(work_id, character) %>%
  count(character, name='works') %>%
  arrange(-works)
fics_per_char %>%
  filter(rank(-works) <= 20) %>%
  arrange(works) %>%
  mutate(character = fct_reorder(character, works)) %>%
  ggplot(aes(x=character, y=works)) +
    geom_bar(stat='identity') +
    coord_flip() 

# Other bar graphs  ----------------------------
delta = 0.000000001
data_long %>%
  select(work_id, title, bookmarks, kudos, hits) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(!(work_id %in% spammed)) %>%
  mutate(ratio=bookmarks/hits) %>%
  filter(dense_rank(-ratio) <= 20) %>%
  mutate(title = fct_reorder(title, ratio)) %>%
  ggplot( aes(x=title, y=ratio)) +
    geom_bar(stat='identity') + 
    coord_flip() +
    ylab('bookmarks/hits')

data_long %>%
  select(work_id, title, bookmarks, kudos, hits) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(!(work_id %in% spammed)) %>%
  filter(dense_rank(-kudos) <= 20) %>%
  mutate(ratio=bookmarks/kudos) %>%
  mutate(title = fct_reorder(title, ratio)) %>%
  ggplot( aes(x=title, y=ratio)) +
    geom_bar(stat='identity') + 
    coord_flip() +
    ylab('bookmarks/kudos')

data_long %>%
  select(work_id, title, comments, current_chapters, kudos, hits) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(!(work_id %in% spammed)) %>%
  filter(dense_rank(-kudos) <= 20) %>%
  mutate(ratio=comments/current_chapters) %>%
  mutate(title = fct_reorder(title, ratio)) %>%
  ggplot( aes(x=title, y=ratio)) +
    geom_bar(stat='identity') + 
    coord_flip() +
    ylab('comments/chapter')

data_long %>%
  select(work_id, title, current_chapters, words) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  mutate(ratio=current_chapters) %>%
  filter(dense_rank(-ratio) <= 20) %>%
  mutate(title = fct_reorder(title, ratio)) %>%
  ggplot( aes(x=title, y=ratio)) +
  geom_bar(stat='identity') + 
  coord_flip() +
  ylab('chapter')

# Correlation of various variables --------------------
library(reshape2)

plot_coocc <- function(appearances, type) {
  coocc = melt(crossprod(table(appearances)))

  triangle = coocc
  names(triangle) = c('col1', 'col2', 'value')
  triangle$value[order(triangle$col1) == order(triangle$col2)] = NA
  maxval = max(triangle$value, na.rm=TRUE)
  
  triangle %>%
    ggplot(aes(x=col1, y=col2)) +
    geom_tile(aes(fill=value)) +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                         midpoint = maxval/2, limit = c(0, maxval))  +
    theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust = 1)) +
    xlab(type) + ylab(type) +
    ggtitle('Co-occurrences')
}

char_appearances = data_long %>%
  distinct(work_id, character) %>%
  add_count(character, name='appearances') %>%
  filter(dense_rank(-appearances) <= 20) %>%
  select('work_id', 'character')
plot_coocc(char_appearances, 'character')

# Correlations -------------------------
# Correlation of tags (all categories: 6, count(relationship) >= 2: 359, 
# all ratings: 5, count(character) >= 16: 89, most popular 100 additional tags: 
# 100)
# current chapters, num characters tagged, num relationships, is crossover
# with kudos/hits, bookmarks/hits, hits/days
category_data = data_long %>% distinct(work_id, category)
rating_data = data_long %>% distinct(work_id, rating)
relationship_data = data_long %>%
  distinct(work_id, relationship) %>%
  add_count(relationship) %>%
  filter(n >= 2) %>%
  select(work_id, relationship)
character_data = data_long %>%
  distinct(work_id, character) %>%
  add_count(character) %>%
  filter(n >= 16) %>%
  select(work_id, character)
split_tags = data_long %>%
  select(work_id, additional.tags) %>%
  distinct(work_id, .keep_all=TRUE)
split_tags$additional.tags = strsplit(split_tags$additional.tags, ', ')
at_data = split_tags %>%
  unnest(additional.tags) %>%
  add_count(additional.tags) %>%
  filter(n > 40) %>%
  select(work_id, additional.tags)
cross_data = data_long %>%
  select(work_id, fandom) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(fandom != '名探偵コナン | Detective Conan | Case Closed' &
           fandom != 'Magic Kaito') %>%
  select(work_id)
cross_data$is_crossover = "crossover"
complete_data = data_long %>%
  select(work_id, current_chapters, expected_chapters) %>%
  distinct(work_id, .keep_all=TRUE) %>%
  filter(current_chapters == expected_chapters) %>%
  select(work_id)
complete_data$is_complete = "complete"
big_data = data.frame(
  work_id = c(category_data$work_id, rating_data$work_id, 
              relationship_data$work_id, character_data$work_id, 
              at_data$work_id, cross_data$work_id, complete_data$work_id),
  tag = c(category_data$category, rating_data$rating, 
          relationship_data$relationship, character_data$character, 
          at_data$additional.tags, cross_data$is_crossover, complete_data$is_complete)
) %>% filter(!(work_id %in% spammed))
design = table(big_data)
perm = match(as.integer(rownames(design)), data$work_id)
kh = data$kudos[perm]/data$hits[perm]
ht = data$hits[perm]/data$age[perm]

# Calculate linear regression predictor
# Wasn't interesting
# kh_predictor = lm(kh ~ design)
# head(kh_predictor$coefficients[order(-kh_predictor$coefficients)])
# bh_predictor = lm(bh ~ design)
# head(bh_predictor$coefficients[order(-bh_predictor$coefficients)])
# ht_predictor = lm(ht ~ design)
# head(ht_predictor$coefficients[order(-ht_predictor$coefficients)])

# Calculate Pearson correlation (Kendall took too long)
kh_corr = cor(design, kh)
kh_corr = kh_corr[order(-kh_corr),]
ht_corr = cor(design, ht)
ht_corr = ht_corr[order(-ht_corr),]
k_corr = cor(design, data$kudos[perm])
k_corr = k_corr[order(-k_corr),]
h_corr = cor(design, data$hits[perm])
h_corr = h_corr[order(-h_corr),]

'Most and least correlated to kudos/hit'
head(names(kh_corr), 10)
'...'
tail(names(kh_corr), 10)
'Most and least correlated to hits/day'
head(names(ht_corr), 10)
'...'
tail(names(ht_corr), 10)

# Additional tags-------------------
library(wordcloud2)
a_tags = data_long %>%
  distinct(work_id, additional.tags) %>%
  select('additional.tags')
a_tags$additional.tags = strsplit(a_tags$additional.tags, ', ')
a_tags = unnest(a_tags, additional.tags)
freqs = count(a_tags, additional.tags) %>%
  filter(rank(-n) < 100)
wordcloud2(freqs)

# Wingfics ---------------------
data_at = unnest(data, additional.tags, keep_empty = TRUE)
data_at %>%
  filter(additional.tags == 'Wingfic' | additional.tags == 'wing!fic' | additional.tags == 'wing fic') %>%
  filter(!(work_id %in% spammed)) %>%
  mutate(title = fct_reorder(title, hits/kudos)) %>%
  ggplot(aes(x = title, y = hits/kudos)) +
    geom_bar(stat='identity') +
    coord_flip()
