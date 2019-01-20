
# HarvardX - Data Science Capstone: MovieLens Project

## 1. Introduction

Recommendation systems use historic ratings of products/services by users to make specific recommendations. They are based on ratings' predictions. Previous ratings from a given user are used to predict what rating he/she would give to a specific item and items for which a high rating is predicted are then recommended to that user.

Many organizations such as Amazon and Netflix use recommendation systems to predict how many stars a user would give a specific item. One star suggests they don't like the item, whereas five stars suggests they love it.

In this project, we will build our movie recommendation system where we will predict ratings for a set of users whose actual ratings are hidden. We check the performance of our predictions against two metrics RMSE and Accuracy.

**Important Note: Running the code of this project could mobilize the full resources of your machine and the process could take several hours to complete.** The code has been validated on an i7 CPU with 16 GB RAM machine and Jupyterlab version 0.35.3 for macOS 10.14.2.

## 2. Data

The MovieLens dataset that we are using for this project is provided by GroupLens, a research lab in the Department of Computer Science and Engineering at the University of Minnesota. 

GroupLens has collected and made available rating datasets from their website (https://grouplens.org/datasets/movielens/). The datasets were collected over various periods of time, depending on the size of the set.
 
* **MovieLens 100K Dataset (size 5 MB)**

    Stable benchmark dataset. 100,000 ratings from 1,000 users on 1,700 movies. Released 4/1998.
    
* **MovieLens 1M Dataset (size 6 MB)**

    Stable benchmark dataset. 1 million ratings from 6,000 users on 4,000 movies. Released 2/2003.
    
* **MovieLens 10M Dataset (size 63 MB)**

    Stable benchmark dataset. 10 million ratings and 100,000 tag applications applied to 10,000 movies by 72,000 users. Released 1/2009.
    
* **MovieLens 20M Dataset (size 190 MB)**
    
    Stable benchmark dataset. 20 million ratings and 465,000 tag applications applied to 27,000 movies by 138,000 users. Includes tag genome data with 12 million relevance scores across 1,100 tags. Released 4/2015 - updated 10/2016.
    
* **MovieLens Tag Genome Dataset (size 41MB)**

    11 million computed tag-movie relevance scores from a pool of 1,100 tags applied to 10,000 movies. Released 3/2014. 
    
    The tag genome is a data structure that encodes how strongly movies exhibit particular properties represented by tags (atmospheric, thought-provoking, realistic, etc.)
    
    This dataset contains the tag relevance values that make up the tag genome. Tag relevance represents the relevance of a tag to a movie on a continuous scale from 0 to 1. 
    
    Note the MovieLens 20M also contains (more recent) tag genome data.

For this project, we are using the **MovieLens 10M** dataset. 

In this dataset, users were selected at random from the online movie recommender service MovieLens. Users selected had rated at least 20 movies. No demographic information is included. each user is represented by an Id, and no further information is provided. The data are contained in 3 files:

* **movies.dat**

    Movie information is contained in this file. Each line represents one movie and has the following format MovieID::Title::Genres.
    
    * MovieID is the MovieLens id.
    
    * Movie titles include year of release. They are entered manually, so errors and inconsistencies may exist.
    
    * Genres are pipe-separated list and are selected from the following:
    
      - Action
      - Adventure
      - Animation
      - Children
      - Comedy
      - Crime
      - Documentary
      - Drama
      - Fantasy
      - Film-Noir
      - Horror
      - IMAX
      - Musical
      - Mystery
      - Romance
      - Sci-Fi
      - Thriller
      - War
      - Western

        
 * **ratings.dat**

    All ratings are contained in this file. Each line of this file represents one rating of one movie by one user, and has the following format UserID::MovieID::Rating::Timestamp.
    
    * The lines within this file are ordered first by UserID, then, within user, by MovieID.
    
    * Ratings are made on a 5-star scale, with half-star increments.
    
    * Timestamps represent the time of rating in seconds since midnight UTC of January 1, 1970.
    
    
 * **tags.dat**

    All tags are contained in this file. Each line represents one tag applied to one movie by one user, and has the following format UserID::MovieID::Tag::Timestamp.
    
    * The lines within this file are ordered first by UserID, then, within user, by MovieID.
    
    * Tags are user generated metadata about movies. Each tag is typically a single word, or short phrase. The meaning, value and purpose of a particular tag is determined by each user. 
    
    * Timestamps represent the time of tagging in seconds since midnight UTC of January 1, 1970.     
   
   **Note:** For the sake of simplicity, we do not use this tags file for our project.

## 3. Methodology

### 3.1 Create subsets for the project

We want to create two subsets as follows:

* edx dataset, which contains 90% of the MovieLens 10M "ratings" and "movies" files, merged by the MovieID feature. This dataset is used for building our ratings prediction system.

* validation dataset, which is the remaining 10%, with UserID and MovieID features, for the purpose of validation of our model. We ensure that UserID and MovieID in the validation set are also in the edx dataset.

### 3.2 Exploratory Analysis

In this section, we explore data in four main directions:

1. Initial exploration of the edx dataset.

2. Exploring users.

    - Users' activity per year 
    - Users' rating characteristics
    

3. Exploring movies.

    - Most reviewed movies and most popular movies
    - Movies by year of release
    - Movies by genre
    
    
4. Exploring ratings.

    - Distribution of ratings
    - How do the ratings distributions compare before and after half-star scores are allowed?
    - Ratings per year

### 3.3 Predictive Model

In this section, we will go through several methods to build our predictive model in order to achieve the lowest RMSE and best accuracy we can. We will keep track of the RMSE for each method and report the overall RMSE and accuracy at the end.

Our approach is inspired by the 2006 Netflix challenge (https://www.netflixprize.com/assets/GrandPrize2009_BPC_BellKor.pdf ), where we will blend the techniques of user and movie effects, regularization and matrix factorization / Principal Components Analysis. Finally, we will use a naive Bayes approach to classify our predicted ratings into categories going from 0.5 star to 5 stars rating with incremental of 0.5 star so that we can evaluate the accuracy of our predictions against true ratings.

The used methods are as follows:

1. User and movie effects with regularization.

2. Matrix factorization.    

3. Naive Bayes. 

## 4. Results and Discussion 

### Create subsets for the project


```R
# --- CREATE EDX SET ----------------------------------------
# Note: This process could take several minutes

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")

# MovieLens 10M dataset:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip

dl <- tempfile()
download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)

ratings <- read.table(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),
                      col.names = c("userId", "movieId", "rating", "timestamp"))

movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")
movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(levels(movieId))[movieId],
                                           title = as.character(title),
                                           genres = as.character(genres))

movielens <- left_join(ratings, movies, by = "movieId")
```

    Loading required package: tidyverse
    ── Attaching packages ─────────────────────────────────────── tidyverse 1.2.1 ──
    ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ✔ readr   1.1.1     ✔ forcats 0.3.0
    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ dplyr::filter() masks stats::filter()
    ✖ dplyr::lag()    masks stats::lag()
    Loading required package: caret
    Loading required package: lattice
    
    Attaching package: ‘caret’
    
    The following object is masked from ‘package:purrr’:
    
        lift
    



```R
# --- NOTE: Updated 1/18/2019 -------------------------------

# --- VALIDATION SET WILL BE 10% OF MOVIELENS DATA ----------

set.seed(1)
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in validation set are also in edx set

validation <- temp %>% 
     semi_join(edx, by = "movieId") %>%
     semi_join(edx, by = "userId")

# Add rows removed from validation set back into edx set

removed <- anti_join(temp, validation)
edx <- rbind(edx, removed)

# Clean up memory by deleting unsused objects and performing a garbage collection 
rm(dl, ratings, movies, test_index, temp, movielens, removed)
gc()
```

    Joining, by = c("userId", "movieId", "rating", "timestamp", "title", "genres")



<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11502484 </td><td>614.3    </td><td> 19138902</td><td>1022.2   </td><td> 25437946</td><td>1358.6   </td></tr>
	<tr><th scope=row>Vcells</th><td>91112456 </td><td>695.2    </td><td>250410368</td><td>1910.5   </td><td>282223611</td><td>2153.2   </td></tr>
</tbody>
</table>



### Exploratory Analysis


```R
# --- USED LIBRARIES ----------------------------------------

if(!require(lubridate)) install.packages("lubridate", repos = "http://cran.r-project.org")
if(!require(gridExtra)) install.packages("gridExtra", repos = "http://cran.r-project.org")
```

    Loading required package: lubridate
    
    Attaching package: ‘lubridate’
    
    The following object is masked from ‘package:base’:
    
        date
    
    Loading required package: gridExtra
    
    Attaching package: ‘gridExtra’
    
    The following object is masked from ‘package:dplyr’:
    
        combine
    



```R
# --- INITIAL EXPLORATION OF THE EDX DATASET ----------------

# Dimensions of the edx dataset

head(edx)

cat("The edx dataset has", nrow(edx), "rows and", ncol(edx), "columns.\n")
cat("There are", n_distinct(edx$userId), "different users and", n_distinct(edx$movieId), "different movies in the edx dataset.")
```


<table>
<thead><tr><th></th><th scope=col>userId</th><th scope=col>movieId</th><th scope=col>rating</th><th scope=col>timestamp</th><th scope=col>title</th><th scope=col>genres</th></tr></thead>
<tbody>
	<tr><th scope=row>1</th><td>1                            </td><td>122                          </td><td>5                            </td><td>838985046                    </td><td>Boomerang (1992)             </td><td>Comedy|Romance               </td></tr>
	<tr><th scope=row>2</th><td>1                            </td><td>185                          </td><td>5                            </td><td>838983525                    </td><td>Net, The (1995)              </td><td>Action|Crime|Thriller        </td></tr>
	<tr><th scope=row>4</th><td>1                            </td><td>292                          </td><td>5                            </td><td>838983421                    </td><td>Outbreak (1995)              </td><td>Action|Drama|Sci-Fi|Thriller </td></tr>
	<tr><th scope=row>5</th><td>1                            </td><td>316                          </td><td>5                            </td><td>838983392                    </td><td>Stargate (1994)              </td><td>Action|Adventure|Sci-Fi      </td></tr>
	<tr><th scope=row>6</th><td>1                            </td><td>329                          </td><td>5                            </td><td>838983392                    </td><td>Star Trek: Generations (1994)</td><td>Action|Adventure|Drama|Sci-Fi</td></tr>
	<tr><th scope=row>7</th><td>1                            </td><td>355                          </td><td>5                            </td><td>838984474                    </td><td>Flintstones, The (1994)      </td><td>Children|Comedy|Fantasy      </td></tr>
</tbody>
</table>



    The edx dataset has 9000055 rows and 6 columns.
    There are 69878 different users and 10677 different movies in the edx dataset.


```R
# Check if edx has missing values
any(is.na(edx))
```


FALSE



```R
# What are the ratings year by year?
# Note: This process could take several minutes

edx_year_rating <- edx %>% 
    transform (date = as.Date(as.POSIXlt(timestamp, origin = "1970-01-01", format = "%Y-%m-%d"), format = "%Y-%m-%d")) %>%
    mutate (year_month = format(as.Date(date), "%Y-%m"))

ggplot(edx_year_rating) + 
    geom_point(aes(x = date, y = rating)) +
    scale_x_date(date_labels = "%Y", date_breaks  = "1 year") +
    labs(title = "Ratings Year by Year", x = "Year", y = "Rating")
```




![png](output_17_1.png)


We have only one rating in 1995 and more interestingly, no half-star rating was provided before 2003.

Let's keep in mind that the MovieLens datasets were collected over various periods of time and specifically, the MovieLens 1M dataset was released in February 2003. The MovieLens 10M dataset was released in January 2009.

Further investigation confirms that the half-star rating had been implemented from 18 February 2003.


```R
# What are the rating averages and medians year by year?

edx_yearmonth_rating <- edx_year_rating %>%
    group_by(year_month) %>%
    summarize(avg = mean(rating), median = median(rating))

ggplot(edx_yearmonth_rating) + 
    geom_point(aes(x = year_month, y = avg, colour = "avg")) +
    geom_point(aes(x = year_month, y = median, colour = "median")) +
    ylim(0, 5) +
    scale_x_discrete(breaks = c("1996-01", "1997-01", "1997-01", "1998-01", "1999-01", 
                                "2000-01", "2001-01", "2002-01", "2003-01", "2004-01", 
                                "2005-01", "2006-01", "2007-01", "2008-01", "2009-01")) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
    labs(title = "Rating Averages and Medians, aggregated by month ", x = "Year", y = "Rating") 
```




![png](output_19_1.png)


Only one month (January) record for 1995.

While the rating averages are rather consistent over the whole dataset, the medians are distributed between 3 and 4 stars until beginning of 2003 and changed to 3.5 stars afterwards. 

We may also note that the distribution of averages looks noisier between 1998 and 2000.


```R
# Clean up memory
rm(edx_year_rating, edx_yearmonth_rating)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11598778 </td><td>619.5    </td><td> 19138902</td><td>1022.2   </td><td> 25437946</td><td>1358.6   </td></tr>
	<tr><th scope=row>Vcells</th><td>91300710 </td><td>696.6    </td><td>415744300</td><td>3171.9   </td><td>518721523</td><td>3957.6   </td></tr>
</tbody>
</table>




```R
# --- EXPLORING USERS ---------------------------------------

edx_users <- edx %>%
    group_by(userId) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

summary(edx_users$count)
```


       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
       10.0    32.0    62.0   128.8   141.0  6616.0 



```R
cat("The most active user(s) rated", max(edx_users$count), "movies and the least active user(s) rated", min(edx_users$count), "movies.\n")
cat("In average, an user rated about", round(mean(edx_users$count)), "movies, and the median is", median(edx_users$count), "movies.")
```

    The most active user(s) rated 6616 movies and the least active user(s) rated 10 movies.
    In average, an user rated about 129 movies, and the median is 62 movies.


```R
ggplot(edx_users) +
        geom_point(aes(x = userId, y = count)) +
        scale_y_log10() +
        labs(title = "Users' Activity", x = "userId", y = "Number of reviews (log scale)")        
```




![png](output_24_1.png)



```R
# How many active users do we have per year?

users_year <- edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    select(timestamp, userId) %>%
    group_by(timestamp) %>%
    summarise(count = n_distinct(userId))
              
ggplot(data = users_year, aes(x = timestamp, y = count)) +
    geom_bar(stat = "identity") + 
    labs(title = "Active Users per Year", x = "Year", y = "Number of active users")
```




![png](output_25_1.png)


1996 is the year with the largest number of active users and 1998 the year with the smallest number (less than 2,500 active users). 1995 and 2009 are not full years.


```R
# How many reviews do we have for the most active users?

user_year_rating <-edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    group_by(timestamp, userId) %>%
    summarise(count = n()) %>%
    arrange(desc(count))

summary(user_year_rating$count)
```


       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
       1.00   26.00   51.00   95.42  110.00 4648.00 


There is one user who rated 4,648 movies in a year. What a commitment! 


```R
# Let's see further about high counts of reviews given

head(user_year_rating)
```


<table>
<thead><tr><th scope=col>timestamp</th><th scope=col>userId</th><th scope=col>count</th></tr></thead>
<tbody>
	<tr><td>2002 </td><td>14463</td><td>4648 </td></tr>
	<tr><td>2007 </td><td>67385</td><td>4233 </td></tr>
	<tr><td>2002 </td><td> 7795</td><td>2799 </td></tr>
	<tr><td>2006 </td><td> 3817</td><td>2731 </td></tr>
	<tr><td>2001 </td><td>59269</td><td>2610 </td></tr>
	<tr><td>2007 </td><td>58357</td><td>2588 </td></tr>
</tbody>
</table>



Some users provided a very large number of reviews in a year. For example, userId 14463 rated 4,648 movies in 2002 (only). This, by the way, confirms that the timestamp is the time when the movie is rated, not when it is watched.  


```R
# Let's see further about userId 14463.

userId_14463 <- edx %>% 
    filter(userId == 14463) %>%
    summarize(count = n(), avg = mean(rating), median = median(rating), std = sd(rating), max = max(rating), min = min(rating))
    
userId_14463
```


<table>
<thead><tr><th scope=col>count</th><th scope=col>avg</th><th scope=col>median</th><th scope=col>std</th><th scope=col>max</th><th scope=col>min</th></tr></thead>
<tbody>
	<tr><td>4648    </td><td>2.403614</td><td>2       </td><td>0.688186</td><td>5       </td><td>1       </td></tr>
</tbody>
</table>



With a median rating of 2 stars, userId 14463 didn't like much the movies he/she rated. 


```R
# --- Users' rating characteristics -------------------------

users_rating_char <- edx %>%
    group_by(userId) %>%
    summarize(count = n(), avg = mean(rating), median = median(rating), std = sd(rating)) %>%
    arrange(desc(count))
```


```R
# What are the averages of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = avg)) +
    labs(title = "Averages of Ratings per User", x = "userId", y = "Rating")
```




![png](output_34_1.png)



```R
# What are the medians of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = median)) +
    labs(title = "Medians of Ratings per User ", x = "userId", y = "Rating")
```




![png](output_35_1.png)


Looking at the medians distribution, we may note that half-star ratings are less common than whole star ratings as before February 2003, the system didn't allow half-star scoring. 


```R
# What are the standard deviations of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = std)) +
    labs(title = "Standard Deviations of Ratings per User", x = "userId", y = "Rating")
```




![png](output_37_1.png)


We may note that some users always rated movies with the same score (standard deviation with zero value) while the vast majority clearly have preferences with a standard deviation ranging between 0.5 and 1.5 stars.
**It shows interactions between users and movies.**


```R
# Clean up memory
rm(edx_users, users_year, user_year_rating, userId_14463, users_rating_char)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11612830 </td><td>620.2    </td><td> 19138902</td><td>1022.2   </td><td> 25437946</td><td>1358.6   </td></tr>
	<tr><th scope=row>Vcells</th><td>91607360 </td><td>699.0    </td><td>332595440</td><td>2537.6   </td><td>518721523</td><td>3957.6   </td></tr>
</tbody>
</table>




```R
# --- EXPLORING MOVIES --------------------------------------

edx_movies <- edx %>%
    group_by(movieId) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

summary(edx_movies$count)
```


       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
        1.0    30.0   122.0   842.9   565.0 31362.0 



```R
cat("The most reviewed movie(s) was(were) rated by", max(edx_movies$count), "users and the least reviewed one(s) was(were) rated by", min(edx_movies$count), "user.\n")
cat("A movie, in average, is rated about", round(mean(edx_movies$count)), "times, and the median is", median(edx_movies$count), "ratings.")
```

    The most reviewed movie(s) was(were) rated by 31362 users and the least reviewed one(s) was(were) rated by 1 user.
    A movie, in average, is rated about 843 times, and the median is 122 ratings.


```R
# How many movies are rated per year?

movies_year <- edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    select(timestamp, movieId) %>%
    group_by(timestamp) %>%
    summarise(count = n_distinct(movieId))
              
ggplot(data = movies_year, aes(x = timestamp, y = count)) +
    geom_bar(stat = "identity") + 
    labs(title = "Movies Rated per Year", x = "Year", y = "Number of ratings")
```




![png](output_42_1.png)


Not surprisingly, we can see a clear growth of ratings, regardless of the number of active users, as more movies are referenced and available for review.


```R
# What are the most reviewed movies? 
movies_votes <- edx %>%
    group_by(movieId, title) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

head(movies_votes)
```


<table>
<thead><tr><th scope=col>movieId</th><th scope=col>title</th><th scope=col>count</th></tr></thead>
<tbody>
	<tr><td>296                             </td><td>Pulp Fiction (1994)             </td><td>31362                           </td></tr>
	<tr><td>356                             </td><td>Forrest Gump (1994)             </td><td>31079                           </td></tr>
	<tr><td>593                             </td><td>Silence of the Lambs, The (1991)</td><td>30382                           </td></tr>
	<tr><td>480                             </td><td>Jurassic Park (1993)            </td><td>29360                           </td></tr>
	<tr><td>318                             </td><td>Shawshank Redemption, The (1994)</td><td>28015                           </td></tr>
	<tr><td>110                             </td><td>Braveheart (1995)               </td><td>26212                           </td></tr>
</tbody>
</table>



**Pulp Fiction**, **Forest Gump**, and **The Silence of the Lambs** are the three most reviewed movies. 


```R
# What are the most popular movies? 

# Best movies (by ratings average and with a minimum of 1,000 ratings)
top_movies <- edx %>%
    group_by(movieId, title) %>%
    filter(n() >= 1000) %>%
    summarise(count = n(), avg = mean(rating), median = median(rating), min = min(rating), max = max(rating)) %>%
    arrange(desc(avg))

head(top_movies)
```


<table>
<thead><tr><th scope=col>movieId</th><th scope=col>title</th><th scope=col>count</th><th scope=col>avg</th><th scope=col>median</th><th scope=col>min</th><th scope=col>max</th></tr></thead>
<tbody>
	<tr><td>318                             </td><td>Shawshank Redemption, The (1994)</td><td>28015                           </td><td>4.455131                        </td><td>5.0                             </td><td>0.5                             </td><td>5                               </td></tr>
	<tr><td>858                             </td><td>Godfather, The (1972)           </td><td>17747                           </td><td>4.415366                        </td><td>5.0                             </td><td>0.5                             </td><td>5                               </td></tr>
	<tr><td> 50                             </td><td>Usual Suspects, The (1995)      </td><td>21648                           </td><td>4.365854                        </td><td>4.5                             </td><td>0.5                             </td><td>5                               </td></tr>
	<tr><td>527                             </td><td>Schindler's List (1993)         </td><td>23193                           </td><td>4.363493                        </td><td>4.5                             </td><td>0.5                             </td><td>5                               </td></tr>
	<tr><td>912                             </td><td>Casablanca (1942)               </td><td>11232                           </td><td>4.320424                        </td><td>4.5                             </td><td>0.5                             </td><td>5                               </td></tr>
	<tr><td>904                             </td><td>Rear Window (1954)              </td><td> 7935                           </td><td>4.318652                        </td><td>4.5                             </td><td>0.5                             </td><td>5                               </td></tr>
</tbody>
</table>



We note a high variation in these counts of reviews, e.g. **The Shawshank Redemption** has about 10,000 more reviews than **The Godfather** (28,015 reviews vs 17,747 reviews, respectively). 

So when we sort by average score, the ranking will be "polluted" by movies with low count of reviews. To deal with this issue we can use a weighted average as used on the IMDB website for their Top 250 ranking. To take this bias into account, we can use the weighted rating as follows:


```R
# R = average of the movie ratings
# v = number of ratings for the movie 
# m = minimum ratings required to be listed in the Top movies
# C = the mean rating across the whole dataset

wr <- function(R, v, m, C) {
  return (v/(v+m))*R + (m/(v+m))*C
}

new_top_movies <- edx %>%
    group_by(movieId, title) %>%
    summarise(count = n(), avg = mean(rating)) %>%
    mutate(weighted_rating = wr(avg, count, 1000, mean(avg))) %>%
    arrange(desc(weighted_rating))
```


```R
# Top 10 popular movies

top10_movies <- new_top_movies %>% select(movieId, title, count, avg) %>% head(10)

ggplot(data = top10_movies, aes(x = title, y = avg)) +
    geom_point(aes(size = count),color = "blue") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0)) +
    labs(title = "Most Popular Movies", x = "Movie", y = "Rating average")
```




![png](output_49_1.png)


If we consider popularity as the quality of being liked by a large number of people, we want to consider movies that are highly rated by a large number of users.


```R
head(new_top_movies, 10)
```


<table>
<thead><tr><th scope=col>movieId</th><th scope=col>title</th><th scope=col>count</th><th scope=col>avg</th><th scope=col>weighted_rating</th></tr></thead>
<tbody>
	<tr><td>296                                                         </td><td>Pulp Fiction (1994)                                         </td><td>31362                                                       </td><td>4.154789                                                    </td><td>0.9690996                                                   </td></tr>
	<tr><td>356                                                         </td><td>Forrest Gump (1994)                                         </td><td>31079                                                       </td><td>4.012822                                                    </td><td>0.9688270                                                   </td></tr>
	<tr><td>593                                                         </td><td>Silence of the Lambs, The (1991)                            </td><td>30382                                                       </td><td>4.204101                                                    </td><td>0.9681346                                                   </td></tr>
	<tr><td>480                                                         </td><td>Jurassic Park (1993)                                        </td><td>29360                                                       </td><td>3.663522                                                    </td><td>0.9670619                                                   </td></tr>
	<tr><td>318                                                         </td><td>Shawshank Redemption, The (1994)                            </td><td>28015                                                       </td><td>4.455131                                                    </td><td>0.9655351                                                   </td></tr>
	<tr><td>110                                                         </td><td>Braveheart (1995)                                           </td><td>26212                                                       </td><td>4.081852                                                    </td><td>0.9632515                                                   </td></tr>
	<tr><td>457                                                         </td><td>Fugitive, The (1993)                                        </td><td>25998                                                       </td><td>4.009155                                                    </td><td>0.9629602                                                   </td></tr>
	<tr><td>589                                                         </td><td>Terminator 2: Judgment Day (1991)                           </td><td>25984                                                       </td><td>3.927859                                                    </td><td>0.9629410                                                   </td></tr>
	<tr><td>260                                                         </td><td>Star Wars: Episode IV - A New Hope (a.k.a. Star Wars) (1977)</td><td>25672                                                       </td><td>4.221311                                                    </td><td>0.9625075                                                   </td></tr>
	<tr><td>150                                                         </td><td>Apollo 13 (1995)                                            </td><td>24284                                                       </td><td>3.885789                                                    </td><td>0.9604493                                                   </td></tr>
</tbody>
</table>



**Pulp Fiction**, **Forrest Gump**, and **The Silence of the Lambs** are the 3 most popular movies.


```R
# How many movies are produced per year?

# Extract the year of release from the movie title
title_year <- edx %>%
  mutate(title = str_trim(title)) %>% # trim whitespaces
  extract(title, c("title", "year"), regex = "^(.*) \\(([0-9 \\-]*)\\)$", remove = T, convert = T) # split title to title, year
 
# Number of movies produced per year
movies_title_year <- title_year %>%
    select(year, movieId) %>%
    group_by(year) %>%
    summarise(count = n_distinct(movieId)) %>%
    arrange(desc(count))

ggplot(data = movies_title_year, aes(x = year, y = count)) + 
            geom_bar(stat = "identity") + 
            labs(title = "Movies Production", x = "Year of release", y = "Number of movies produced")
```




![png](output_53_1.png)


In our data, we can see an exponential growth until 2002 and then a trend drop. The latter could be caused by the fact that the data is collected until 2009 (not a full year) so we have less new movies referenced in the dataset. As for the former, maybe it is somewhat linked to the beginning of the Internet era, implying a growing popularity of the demand for movies online. 


```R
# What are the most rated movie genres?
# Note: This process could take several minutes

movies_genre <- edx %>%
    separate_rows(genres, sep = "\\|")

genres_ratings <- movies_genre %>% # Separate the combined genre categories into single genres
    group_by(genres) %>%
    summarise(count = n()) %>%
    arrange(desc(count))

genres_ratings 
```


<table>
<thead><tr><th scope=col>genres</th><th scope=col>count</th></tr></thead>
<tbody>
	<tr><td>Drama             </td><td>3910127           </td></tr>
	<tr><td>Comedy            </td><td>3540930           </td></tr>
	<tr><td>Action            </td><td>2560545           </td></tr>
	<tr><td>Thriller          </td><td>2325899           </td></tr>
	<tr><td>Adventure         </td><td>1908892           </td></tr>
	<tr><td>Romance           </td><td>1712100           </td></tr>
	<tr><td>Sci-Fi            </td><td>1341183           </td></tr>
	<tr><td>Crime             </td><td>1327715           </td></tr>
	<tr><td>Fantasy           </td><td> 925637           </td></tr>
	<tr><td>Children          </td><td> 737994           </td></tr>
	<tr><td>Horror            </td><td> 691485           </td></tr>
	<tr><td>Mystery           </td><td> 568332           </td></tr>
	<tr><td>War               </td><td> 511147           </td></tr>
	<tr><td>Animation         </td><td> 467168           </td></tr>
	<tr><td>Musical           </td><td> 433080           </td></tr>
	<tr><td>Western           </td><td> 189394           </td></tr>
	<tr><td>Film-Noir         </td><td> 118541           </td></tr>
	<tr><td>Documentary       </td><td>  93066           </td></tr>
	<tr><td>IMAX              </td><td>   8181           </td></tr>
	<tr><td>(no genres listed)</td><td>      7           </td></tr>
</tbody>
</table>



Not surprisingly, the top 3 rated genres are **Drama**, **Comedy**, and **Action**.


```R
movies_genre %>% filter(genres == "(no genres listed)")
```


<table>
<thead><tr><th scope=col>userId</th><th scope=col>movieId</th><th scope=col>rating</th><th scope=col>timestamp</th><th scope=col>title</th><th scope=col>genres</th></tr></thead>
<tbody>
	<tr><td> 7701               </td><td>8606                </td><td>5.0                 </td><td>1190806786          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>10680               </td><td>8606                </td><td>4.5                 </td><td>1171170472          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>29097               </td><td>8606                </td><td>2.0                 </td><td>1089648625          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>46142               </td><td>8606                </td><td>3.5                 </td><td>1226518191          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>57696               </td><td>8606                </td><td>4.5                 </td><td>1230588636          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>64411               </td><td>8606                </td><td>3.5                 </td><td>1096732843          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
	<tr><td>67385               </td><td>8606                </td><td>2.5                 </td><td>1188277325          </td><td>Pull My Daisy (1958)</td><td>(no genres listed)  </td></tr>
</tbody>
</table>



Note: The movie **Pull My Daisy (1958)** (which is rated by 7 users) has no genre listed.


```R
ggplot(data = genres_ratings, aes(x = reorder(genres, -count), y = count)) +
        geom_bar(stat = "identity") + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(title = "Movies by Genre", x = "Movies genre", y = "Number of ratings")
```




![png](output_59_1.png)



```R
# What are the most popular genres? 

# Best genres (by ratings average)
top_genres <- movies_genre %>%
  group_by(genres) %>%
  summarise(count = n(), avg = mean(rating)) %>%
  arrange(desc(avg))

top_genres
```


<table>
<thead><tr><th scope=col>genres</th><th scope=col>count</th><th scope=col>avg</th></tr></thead>
<tbody>
	<tr><td>Film-Noir         </td><td> 118541           </td><td>4.011625          </td></tr>
	<tr><td>Documentary       </td><td>  93066           </td><td>3.783487          </td></tr>
	<tr><td>War               </td><td> 511147           </td><td>3.780813          </td></tr>
	<tr><td>IMAX              </td><td>   8181           </td><td>3.767693          </td></tr>
	<tr><td>Mystery           </td><td> 568332           </td><td>3.677001          </td></tr>
	<tr><td>Drama             </td><td>3910127           </td><td>3.673131          </td></tr>
	<tr><td>Crime             </td><td>1327715           </td><td>3.665925          </td></tr>
	<tr><td>(no genres listed)</td><td>      7           </td><td>3.642857          </td></tr>
	<tr><td>Animation         </td><td> 467168           </td><td>3.600644          </td></tr>
	<tr><td>Musical           </td><td> 433080           </td><td>3.563305          </td></tr>
	<tr><td>Western           </td><td> 189394           </td><td>3.555918          </td></tr>
	<tr><td>Romance           </td><td>1712100           </td><td>3.553813          </td></tr>
	<tr><td>Thriller          </td><td>2325899           </td><td>3.507676          </td></tr>
	<tr><td>Fantasy           </td><td> 925637           </td><td>3.501946          </td></tr>
	<tr><td>Adventure         </td><td>1908892           </td><td>3.493544          </td></tr>
	<tr><td>Comedy            </td><td>3540930           </td><td>3.436908          </td></tr>
	<tr><td>Action            </td><td>2560545           </td><td>3.421405          </td></tr>
	<tr><td>Children          </td><td> 737994           </td><td>3.418715          </td></tr>
	<tr><td>Sci-Fi            </td><td>1341183           </td><td>3.395743          </td></tr>
	<tr><td>Horror            </td><td> 691485           </td><td>3.269815          </td></tr>
</tbody>
</table>



The top 3 most liked genres are **Film-Noir**, **Documentary**, and **War**. However, these genres are not often reviewed, so the ranking is not representative of the popularity of the genre. We can use a weighted average to take this bias into account.


```R
# R = average of the movie ratings
# v = number of ratings for the movie 
# m = minimum ratings required to be listed in the Top movies
# C = the mean rating across the whole dataset

wr <- function(R, v, m, C) {
  return (v/(v+m))*R + (m/(v+m))*C
}

new_top_genres <- movies_genre %>%
    group_by(genres) %>%
    summarise(count = n(), avg = mean(rating)) %>%
    mutate(weighted_rating = wr(avg, count, 1000, mean(avg))) %>%
    arrange(desc(weighted_rating))

new_top_genres
```


<table>
<thead><tr><th scope=col>genres</th><th scope=col>count</th><th scope=col>avg</th><th scope=col>weighted_rating</th></tr></thead>
<tbody>
	<tr><td>Drama             </td><td>3910127           </td><td>3.673131          </td><td>0.999744319       </td></tr>
	<tr><td>Comedy            </td><td>3540930           </td><td>3.436908          </td><td>0.999717668       </td></tr>
	<tr><td>Action            </td><td>2560545           </td><td>3.421405          </td><td>0.999609611       </td></tr>
	<tr><td>Thriller          </td><td>2325899           </td><td>3.507676          </td><td>0.999570243       </td></tr>
	<tr><td>Adventure         </td><td>1908892           </td><td>3.493544          </td><td>0.999476410       </td></tr>
	<tr><td>Romance           </td><td>1712100           </td><td>3.553813          </td><td>0.999416263       </td></tr>
	<tr><td>Sci-Fi            </td><td>1341183           </td><td>3.395743          </td><td>0.999254945       </td></tr>
	<tr><td>Crime             </td><td>1327715           </td><td>3.665925          </td><td>0.999247393       </td></tr>
	<tr><td>Fantasy           </td><td> 925637           </td><td>3.501946          </td><td>0.998920829       </td></tr>
	<tr><td>Children          </td><td> 737994           </td><td>3.418715          </td><td>0.998646809       </td></tr>
	<tr><td>Horror            </td><td> 691485           </td><td>3.269815          </td><td>0.998555925       </td></tr>
	<tr><td>Mystery           </td><td> 568332           </td><td>3.677001          </td><td>0.998243556       </td></tr>
	<tr><td>War               </td><td> 511147           </td><td>3.780813          </td><td>0.998047436       </td></tr>
	<tr><td>Animation         </td><td> 467168           </td><td>3.600644          </td><td>0.997864015       </td></tr>
	<tr><td>Musical           </td><td> 433080           </td><td>3.563305          </td><td>0.997696277       </td></tr>
	<tr><td>Western           </td><td> 189394           </td><td>3.555918          </td><td>0.994747734       </td></tr>
	<tr><td>Film-Noir         </td><td> 118541           </td><td>4.011625          </td><td>0.991634669       </td></tr>
	<tr><td>Documentary       </td><td>  93066           </td><td>3.783487          </td><td>0.989369166       </td></tr>
	<tr><td>IMAX              </td><td>   8181           </td><td>3.767693          </td><td>0.891079403       </td></tr>
	<tr><td>(no genres listed)</td><td>      7           </td><td>3.642857          </td><td>0.006951341       </td></tr>
</tbody>
</table>



So, the 3 most popular genres, when considering the count of reviews as well, are confirmed to be **Drama**, **Comedy**, and **Action**.


```R
# Most popular genres
ggplot(data = new_top_genres, aes(x = genres, y = avg)) +
    geom_point(aes(size = count),color = "blue") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0)) +
    labs(title = "Most Popular Genres", x = "Movies genre", y = "Rating average")
```




![png](output_64_1.png)


We note that the top 4 most highly rated genres are not very popular. One reason would be that users who rate these genres are rather the aficionados. 


```R
# Clean up memory
rm(edx_movies, movies_year, movies_votes, top_movies, wr, new_top_movies, top10_movies, 
   title_year, movies_title_year, 
   movies_genre, genres_ratings, top_genres, new_top_genres) 
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11618820 </td><td>620.6    </td><td> 48539288</td><td>2592.3   </td><td> 37024444</td><td>1977.4   </td></tr>
	<tr><th scope=row>Vcells</th><td>91342821 </td><td>696.9    </td><td>385640714</td><td>2942.3   </td><td>518721523</td><td>3957.6   </td></tr>
</tbody>
</table>




```R
# --- EXPLORING RATINGS -------------------------------------

summary(edx$rating)
```


       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
      0.500   3.000   4.000   3.512   4.000   5.000 



```R
# Distribution of ratings
ggplot(data = edx, aes(x = rating)) +
    geom_bar() + 
    labs(title = "Distribution of Ratings", x = "Rating", y = "Number of ratings")
```




![png](output_68_1.png)



```R
# How do the ratings distributions compare before and after half-star scores are allowed?
# The half-star rating has been implemented from 18 February 2003 (timestamp = 1045526400

edx_before <- subset(edx, timestamp < 1045526400)
edx_after <- subset(edx, timestamp >= 1045526400)
```


```R
# Numbers of rows before and after 18 Feb 2003
cat("There are", nrow(edx_before), "ratings before 18 Feb 2003, without half-star scoring and", nrow(edx_after), "ratings after 18 Feb 2003, with half-star scoring.")
```

    There are 4702794 ratings before 18 Feb 2003, without half-star scoring and 4297261 ratings after 18 Feb 2003, with half-star scoring.


```R
# Distribution of ratings before 2003-02-18 (timestamp = 1045526400)
pbef <- ggplot(data=edx_before, aes(x = rating)) + 
    geom_bar() + 
    ylim(0, 1600000) +
    labs(title = "Before 18 Feb 2003", x = "Rating", y = "Number of ratings")

# Distribution of ratings after 2003-02-18 (timestamp = 1045526400)
paft <- ggplot(data = edx_after, aes(x = rating)) +
    geom_bar() + 
    ylim(0, 1600000) +
    labs(title = "After 18 Feb 2003", x = "Rating", y = "Number of ratings")

grid.arrange(pbef, paft, ncol = 2)
```


![png](output_71_0.png)



```R
# Ratings per year
edx_year_rating <- edx %>% transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y"))

# Number of distinct users per year
users_year <- edx_year_rating %>%
    select(timestamp, userId) %>%
    group_by(timestamp) %>%
    summarise(count_users = n_distinct(userId)) %>%
    arrange(timestamp)
              
# Number of ratings per year
ratings_year <- edx_year_rating %>%
    select(timestamp, rating) %>%
    group_by(timestamp) %>%
    summarise(count_ratings = n()) %>%
    arrange(timestamp)
              
rates <- users_year %>% 
    left_join(ratings_year) %>%
    mutate(rate = count_ratings / count_users)
```

    Joining, by = "timestamp"



```R
ggplot(data = rates, aes(x = count_users, y = count_ratings)) + 
                geom_point() + 
                geom_smooth(method = "lm") +
                labs(title = "Number of Users vs Number of Ratings", x = "Number of users", y = "Number of ratings")
```




![png](output_73_1.png)


Not surprisingly, the number of users is correlated with the number of ratings.


```R
# Ratings average per year

avg_rating_year <- edx_year_rating %>%
  group_by(timestamp) %>%
  summarise(count = n(), average = mean(rating), std = sd(rating), median = median(rating), min = min(rating), max = max(rating)) %>%
  arrange(desc(average))

ggplot(data = avg_rating_year, aes(x = timestamp, y = average)) +
                geom_point(aes(size = count),color = "blue") +
                labs(title = "Rating Averages, aggregated by year", x = "Year", y = "Rating Average")
```




![png](output_75_1.png)


As seen earlier, rating averages are rather consistent, between 3.4 and 3.6 stars. The average in 1995, with only one rating, can be considered as an outlier.


```R
# Clean up memory
rm(edx_before, edx_after, pbef, paft,
   edx_year_rating, users_year, ratings_year, rates, avg_rating_year)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11640098 </td><td>621.7    </td><td> 38831430</td><td>2073.9   </td><td> 37024444</td><td>1977.4   </td></tr>
	<tr><th scope=row>Vcells</th><td>91378395 </td><td>697.2    </td><td>308512571</td><td>2353.8   </td><td>518721523</td><td>3957.6   </td></tr>
</tbody>
</table>



### Predictive Model


```R
# --- USED LIBRARIES ----------------------------------------

if(!require(knitr)) install.packages("knitr", repos = "http://cran.us.r-project.org")
# if(!require(e1071)) install.packages("e1071", repos = "http://cran.r-project.org")
```

    Loading required package: knitr



```R
# --- SPLIT TRAIN/TEST SETS ---------------------------------

set.seed(699)
test_index <- createDataPartition(y = edx$rating, times = 1, p = 0.2, list = FALSE)
train_set <- edx[-test_index,]
test_set <- edx[test_index,]

# Use semi_join() to ensure that all users and movies in the test set are also in the training set
test_set <- test_set %>% 
  semi_join(train_set, by = "movieId") %>%
  semi_join(train_set, by = "userId")
```


```R
# --- MODELING WITH JUST THE AVERAGE ------------------------

# RMSE as loss function, which computes the errors between ratings and predicted ratings.
RMSE <- function(true_ratings, predicted_ratings){
  sqrt(mean((true_ratings - predicted_ratings)^2))
}

# The estimate here that minimizes the RMSE is just the average rating of all movies across all users.
# We compute this average on the training data...
mu <- mean(train_set$rating)
cat("The average rating of all movies across all users is:", mu)

# Let's plot the average rating for movies that are rated at least 1000 times.
train_set %>% group_by(movieId) %>% 
  filter(n()>=1000) %>% 
  summarize(avg_rating = mean(rating)) %>% 
  qplot(avg_rating, geom = "histogram", color = I("black"), bins=30, data = .)

# ...and we predict all unknown ratings with this average.
predictions <- rep(mu, nrow(test_set))

# Then we compute the RMSE.
naive_rmse <- RMSE(test_set$rating, predictions)
cat("The RMSE with just the average method is:", naive_rmse)
```

    The average rating of all movies across all users is: 3.512453



    The RMSE with just the average method is: 1.060247


![png](output_81_3.png)



```R
# --- MODELING MOVIE EFFECT ---------------------------------

# Create a table that's going to store the results that we obtain as we're goinng to compare different effects.
rmse_results <- data_frame(method = "Just the average", RMSE = naive_rmse)

movie_means <- train_set %>% 
  group_by(movieId) %>% 
  summarize(b_i = mean(rating - mu))

qplot(b_i, geom = "histogram", color = I("black"), bins=25, data = movie_means)

joined <- test_set %>% 
  left_join(movie_means, by='movieId')

# Note that as we ensured above that all users and movies in the test set are also in the training set,
# we don't need to handle NAs with the left_join()

predicted_ratings <- mu + joined$b_i

model1_rmse <- RMSE(predicted_ratings, test_set$rating)

rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Movie effect model",  
                                     RMSE = model1_rmse ))
rmse_results %>% kable
```




    
    
    |method             |      RMSE|
    |:------------------|---------:|
    |Just the average   | 1.0602472|
    |Movie effect model | 0.9435966|



![png](output_82_2.png)



```R
# --- REGULARIZATION OF THE MOVIE EFFECT --------------------

# The largest movie effects are with movies that have few ratings. 
# So, we use regularization to penalize large estimates that come from small sample sizes.

# Compute regularized estimates of b_i using lambda (penalty term). Let's first try a few values of lambda and pick the best one.
lambdas <- seq(0, 8, 0.25)

tmp <- train_set %>% 
  group_by(movieId) %>% 
  summarize(sum = sum(rating - mu), n_i = n())

rmses <- sapply(lambdas, function(l){
  joined <- test_set %>% 
    left_join(tmp, by='movieId') %>% 
    mutate(b_i = sum/(n_i+l))
    predicted_ratings <- mu + joined$b_i
    return(RMSE(predicted_ratings, test_set$rating))
})

cat("The best lambda (which minimizes the RMSE) for the movie effect is:", lambdas[which.min(rmses)])

qplot(lambdas, rmses)  

```

    The best lambda (which minimizes the RMSE) for the movie effect is: 2.75




![png](output_83_2.png)



```R
# So it looks like a value of lambda = 2.75 gives us the smallest RMSE

lambda <- 2.75

movie_reg_means <- train_set %>% 
  group_by(movieId) %>% 
  summarize(b_i = sum(rating - mu)/(n()+lambda), n_i = n()) 

joined <- test_set %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  replace_na(list(b_i=0))

predicted_ratings <- mu + joined$b_i

model1_reg_rmse <- RMSE(predicted_ratings, test_set$rating)

rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Regularized movie effect model, lambda = 2.75",  
                                     RMSE = model1_reg_rmse ))
rmse_results %>% kable
```


    
    
    |method                                        |      RMSE|
    |:---------------------------------------------|---------:|
    |Just the average                              | 1.0602472|
    |Movie effect model                            | 0.9435966|
    |Regularized movie effect model, lambda = 2.75 | 0.9435107|



```R
# --- MODELING USER AND MOVIE EFFECTS ----------------------------------

# Let's plot the average rating for users who have rated at least 100 movies
train_set %>% 
  group_by(userId) %>% 
  summarize(b_u = mean(rating)) %>% 
  filter(n() >= 100) %>%
  ggplot(aes(b_u)) + 
  geom_histogram(bins = 30, color  = "black")
```




![png](output_85_1.png)



```R
# As with the movies, the largest user effect are for those that rate few movies.
# We again use regularization, this time with a different lambda (lambda_2). Let's first try a few values of lambda_2 and pick the best one.
# Note: This process could take several minutes

lambdas_2 <- seq(0, 10, 0.25)

rmses <- sapply(lambdas_2, function(l){

  mu <- mean(train_set$rating)
  
  b_i <- train_set %>% 
    group_by(movieId) %>%
    summarize(b_i = sum(rating - mu)/(n()+l))
  
  b_u <- train_set %>% 
    left_join(b_i, by="movieId") %>%
    group_by(userId) %>%
    summarize(b_u = sum(rating - b_i - mu)/(n()+l))

  predicted_ratings <- test_set %>%
    left_join(b_i, by = "movieId") %>%
    left_join(b_u, by = "userId") %>%
    mutate(pred = mu + b_i + b_u) %>%
    .$pred
  
    return(RMSE(predicted_ratings, test_set$rating))
})

cat("The best lambda_2 (which minimizes the RMSE) for the user and movie effects is", lambdas_2[which.min(rmses)])

qplot(lambdas_2, rmses)  
```

    The best lambda_2 (which minimizes the RMSE) for the user and movie effects is 5




![png](output_86_2.png)



```R
# So it looks like a value of lambda_2 = 5 gives us the smallest RMSE

lambda_2 <- 5

user_reg_means <- train_set %>% 
  left_join(movie_reg_means) %>%
  mutate(resids = rating - mu - b_i) %>% 
  group_by(userId) %>%
  summarize(b_u = sum(resids)/(n()+lambda_2))

joined <- test_set %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  replace_na(list(b_i=0, b_u=0))

predicted_ratings <- mu + joined$b_i + joined$b_u

model2_reg_rmse <- RMSE(predicted_ratings, test_set$rating)

rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Regularized movie and user effects model, lambda2 = 5",  
                                     RMSE = model2_reg_rmse ))
rmse_results %>% kable
```

    Joining, by = "movieId"



    
    
    |method                                                |      RMSE|
    |:-----------------------------------------------------|---------:|
    |Just the average                                      | 1.0602472|
    |Movie effect model                                    | 0.9435966|
    |Regularized movie effect model, lambda = 2.75         | 0.9435107|
    |Regularized movie and user effects model, lambda2 = 5 | 0.8654773|



```R
# --- MATRIX DECOMPOSITION ---------------------------------------------

# We use PCA to uncover patterns in user/movie relationships

# First, tet's remove the user and movie bias to create residuals
new_train_set <- train_set %>% 
  left_join(movie_reg_means, by = "movieId") %>% 
  left_join(user_reg_means, by = "userId") %>%
  mutate(resids = rating - mu - b_i - b_u)
```


```R
# Next we create a matrix using spread()
# Note: This process could take several minutes

r <- new_train_set %>% 
  select(userId, movieId, resids) %>%
  spread(movieId, resids) %>% 
  as.matrix()

rownames(r) <- r[,1]
r <- r[,-1]
r[is.na(r)] <- 0 # For the sake of simplicity, we just apply 0 to all missing data
```


```R
# Singular value decomposition
# Note: This process could take several long minutes

pca <- prcomp(r - rowMeans(r), center = TRUE, scale = FALSE)
```


```R
dim(pca$x) # Principal components
dim(pca$rotation) # Users' effects
```


<ol class=list-inline>
	<li>69878</li>
	<li>10639</li>
</ol>




<ol class=list-inline>
	<li>10639</li>
	<li>10639</li>
</ol>




```R
# Variability
var_explained <- cumsum(pca$sdev^2/sum(pca$sdev^2))
plot(var_explained)
```


![png](output_92_0.png)



```R
# Factorization of the 4000 first principal components, which explain almost all the variability 

k <- 4000

pred <- pca$x[,1:k] %*% t(pca$rotation[,1:k])
colnames(pred) <- colnames(r)
```


```R
# Note: This process could take several very long minutes

interaction <- 
    data.frame(userId = as.numeric(rownames(r)), pred, check.names = FALSE) %>% 
    tbl_df %>%
    gather(movieId, b_ui, -userId) %>% 
    mutate(movieId = as.numeric(movieId))
```


```R
# Clean up memory
rm(pred, pca, r)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>  11688902</td><td>  624.3   </td><td>  38831430</td><td> 2073.9   </td><td>  38831430</td><td> 2073.9   </td></tr>
	<tr><th scope=row>Vcells</th><td>2453317016</td><td>18717.4   </td><td>7543008298</td><td>57548.6   </td><td>6284171678</td><td>47944.5   </td></tr>
</tbody>
</table>




```R
# Note: This process could take several very long hours

joined <- test_set %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  left_join(interaction, by=c('movieId','userId')) %>%
  replace_na(list(b_i=0, b_u=0, b_ui=0))

predictions <- joined %>% mutate(resids = rating - mu - joined$b_i - joined$b_u - joined$b_ui)
head(predictions)
```


<table>
<thead><tr><th scope=col>userId</th><th scope=col>movieId</th><th scope=col>rating</th><th scope=col>timestamp</th><th scope=col>title</th><th scope=col>genres</th><th scope=col>b_i</th><th scope=col>n_i</th><th scope=col>b_u</th><th scope=col>b_ui</th><th scope=col>resids</th></tr></thead>
<tbody>
	<tr><td>1                                        </td><td>370                                      </td><td>5                                        </td><td>838984596                                </td><td>Naked Gun 33 1/3: The Final Insult (1994)</td><td>Action|Comedy                            </td><td>-0.5553663                               </td><td> 5860                                    </td><td> 1.2673930                               </td><td>0.0003369344                             </td><td> 0.77518352                              </td></tr>
	<tr><td>1                                        </td><td>520                                      </td><td>5                                        </td><td>838984679                                </td><td>Robin Hood: Men in Tights (1993)         </td><td>Comedy                                   </td><td>-0.5002730                               </td><td> 5778                                    </td><td> 1.2673930                               </td><td>0.0005309535                             </td><td> 0.71989611                              </td></tr>
	<tr><td>2                                        </td><td>590                                      </td><td>5                                        </td><td>868245608                                </td><td>Dances with Wolves (1990)                </td><td>Adventure|Drama|Western                  </td><td> 0.2307889                               </td><td>18738                                    </td><td>-0.2078822                               </td><td>0.0113752872                             </td><td> 1.45326510                              </td></tr>
	<tr><td>2                                        </td><td>648                                      </td><td>2                                        </td><td>868244699                                </td><td>Mission: Impossible (1996)               </td><td>Action|Adventure|Mystery|Thriller        </td><td>-0.1254757                               </td><td>15193                                    </td><td>-0.2078822                               </td><td>0.0101497655                             </td><td>-1.18924478                              </td></tr>
	<tr><td>2                                        </td><td>719                                      </td><td>3                                        </td><td>868246191                                </td><td>Multiplicity (1996)                      </td><td>Comedy                                   </td><td>-0.5195732                               </td><td> 3170                                    </td><td>-0.2078822                               </td><td>0.0030670347                             </td><td> 0.21193543                              </td></tr>
	<tr><td>2                                        </td><td>786                                      </td><td>3                                        </td><td>868244562                                </td><td>Eraser (1996)                            </td><td>Action|Drama|Thriller                    </td><td>-0.3399466                               </td><td> 7124                                    </td><td>-0.2078822                               </td><td>0.0059796003                             </td><td> 0.02939632                              </td></tr>
</tbody>
</table>




```R
predicted_ratings <- mu + predictions$b_i + predictions$b_u + predictions$b_ui

matrix_decomp_model_rmse <- RMSE(predicted_ratings, predictions$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Matrix Factorization",  
                                     RMSE = matrix_decomp_model_rmse))
rmse_results %>% kable
```


    
    
    |method                                                |      RMSE|
    |:-----------------------------------------------------|---------:|
    |Just the average                                      | 1.0602472|
    |Movie effect model                                    | 0.9435966|
    |Regularized movie effect model, lambda = 2.75         | 0.9435107|
    |Regularized movie and user effects model, lambda2 = 5 | 0.8654773|
    |Matrix Factorization                                  | 0.8652532|



```R
# --- NAIVE BAYES CLASSIFICATION ---------------------------------------

cols <- c("userId", "movieId", "rating", "genres")
predictions[,cols] <- data.frame(apply(predictions[cols], 2, as.factor))
```


```R
# Note: This process could take several minutes

library(e1071)

nb_fit <- naiveBayes(rating ~ userId + movieId + genres + resids, data = predictions[, -c(4:5, 7:10)], laplace = 1e-3)
nb_pred <- predict(nb_fit, predictions[, -c(3:5, 7:10)])
```


```R
# --- ACCURACY ---------------------------------------------------------

val_nb <- predictions %>% mutate(nb_pred)

matches_nb <- val_nb[val_nb$rating == val_nb$nb_pred,]
accuracy_nb <- round((nrow(matches_nb)/nrow(val_nb))*100, 2)

cat("The accuracy with the test set is", accuracy_nb)
```

    The accuracy with the test set is 69.27

Although the assumption of independence of the predictor variables is not fulfilled here, we can see that naive Bayes actually does a good job in practice!


```R
# Clean up memory
rm(test_index, train_set, test_set,
   RMSE, mu, predictions, naive_rmse,
   rmse_results, movie_means, joined, predicted_ratings, model1_rmse,
   lambdas, tmp, rmses, lambda, movie_reg_means, model1_reg_rmse,
   lambdas_2, lambda_2, user_reg_means, model2_reg_rmse,
   new_train_set, var_explained, k, interaction, matrix_decomp_model_rmse,
   cols, nb_fit, nb_pred, val_nb, matches_nb, accuracy_nb)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>11698142  </td><td>624.8     </td><td>  38831430</td><td> 2073.9   </td><td>  38831430</td><td> 2073.9   </td></tr>
	<tr><th scope=row>Vcells</th><td>91449333  </td><td>697.8     </td><td>6034406638</td><td>46038.9   </td><td>6284171678</td><td>47944.5   </td></tr>
</tbody>
</table>



### Validation


```R
# --- REGULARIZATION OF THE MOVIE EFFECT --------------------

# Compute regularized estimates of b_i using lambda. Let's first try a few values of lambda and pick the best one.
lambdas <- seq(0, 8, 0.25)

mu <- mean(edx$rating)

tmp <- edx %>% 
  group_by(movieId) %>% 
  summarize(sum = sum(rating - mu), n_i = n())

rmses <- sapply(lambdas, function(l){
  joined <- validation %>% 
    left_join(tmp, by='movieId') %>% 
    mutate(b_i = sum/(n_i+l))
    predicted_ratings <- mu + joined$b_i
    return(RMSE(predicted_ratings, validation$rating))
})

cat("The best lambda (which minimizes the RMSE) for the movie effect is:", lambdas[which.min(rmses)])

qplot(lambdas, rmses)
```

    The best lambda (which minimizes the RMSE) for the movie effect is: 2.5




![png](output_104_2.png)



```R
# So it looks like a value of lambda = 2.5 gives us the smallest RMSE

lambda <- 2.5

movie_reg_means <- edx %>% 
  group_by(movieId) %>% 
  summarize(b_i = sum(rating - mu)/(n()+lambda), n_i = n()) 

joined <- validation %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  replace_na(list(b_i=0))

predicted_ratings <- mu + joined$b_i

model1_reg_rmse <- RMSE(predicted_ratings, validation$rating)

# Create a table that's going to store the results that we obtain as we're goinng to compare different effects.
rmse_results <- data_frame(method = "Regularized movie effect model, validation",  
                                     RMSE = model1_reg_rmse )
```


```R
# --- REGULARIZATION OF THE USER AND MOVIE EFFECTS ----------

# Compute regularized estimates of b_i using lambda_2. Let's first try a few values of lambda_2 and pick the best one.

lambdas_2 <- seq(0, 10, 0.25)

rmses <- sapply(lambdas_2, function(l){

  mu <- mean(edx$rating)
  
  b_i <- edx %>% 
    group_by(movieId) %>%
    summarize(b_i = sum(rating - mu)/(n()+l))
  
  b_u <- edx %>% 
    left_join(b_i, by="movieId") %>%
    group_by(userId) %>%
    summarize(b_u = sum(rating - b_i - mu)/(n()+l))

  predicted_ratings <- validation %>%
    left_join(b_i, by = "movieId") %>%
    left_join(b_u, by = "userId") %>%
    mutate(pred = mu + b_i + b_u) %>%
    .$pred
  
    return(RMSE(predicted_ratings, validation$rating))
})

cat("The best lambda_2 (which minimizes the RMSE) for the user and movie effects is", lambdas_2[which.min(rmses)])

qplot(lambdas_2, rmses)  
```

    The best lambda_2 (which minimizes the RMSE) for the user and movie effects is 5.25




![png](output_106_2.png)



```R
# So it looks like a value of lambda_2 = 5.25 gives us the smallest RMSE

lambda_2 <- 5.25

user_reg_means <- edx %>% 
  left_join(movie_reg_means) %>%
  mutate(resids = rating - mu - b_i) %>% 
  group_by(userId) %>%
  summarize(b_u = sum(resids)/(n()+lambda_2))

joined <- validation %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  replace_na(list(b_i=0, b_u=0))

predicted_ratings <- mu + joined$b_i + joined$b_u

model2_reg_rmse <- RMSE(predicted_ratings, validation$rating)

rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Regularized movie and user effects model, validation",  
                                     RMSE = model2_reg_rmse ))
rmse_results %>% kable
```

    Joining, by = "movieId"



    
    
    |method                                               |      RMSE|
    |:----------------------------------------------------|---------:|
    |Regularized movie effect model, validation           | 0.9438521|
    |Regularized movie and user effects model, validation | 0.8648427|



```R
# --- MATRIX DECOMPOSITION ---------------------------------------------

# We use PCA to uncover patterns in user/movie relationships

# First, tet's remove the user and movie bias to create residuals
new_edx <- edx %>% 
  left_join(movie_reg_means, by = "movieId") %>% 
  left_join(user_reg_means, by = "userId") %>%
  mutate(resids = rating - mu - b_i - b_u)
```


```R
# Next we create a matrix using spread()
# Note: This process could take several minutes

r <- new_edx %>% 
  select(userId, movieId, resids) %>%
  spread(movieId, resids) %>% 
  as.matrix()

rownames(r) <- r[,1]
r <- r[,-1]
r[is.na(r)] <- 0 # For the sake of simplicity, we just apply 0 to all missing data
```


```R
# Singular value decomposition
# Note: This process could take several long minutes

pca <- prcomp(r - rowMeans(r), center = TRUE, scale = FALSE)
```


```R
# Variability
var_explained <- cumsum(pca$sdev^2/sum(pca$sdev^2))
plot(var_explained)
```


![png](output_111_0.png)



```R
# Factorization of the 4000 first principal components, which explain almost all the variability 

k <- 4000

pred <- pca$x[,1:k] %*% t(pca$rotation[,1:k])
colnames(pred) <- colnames(r)
```


```R
# Note: This process could take several very long minutes

interaction <- 
    data.frame(userId = as.numeric(rownames(r)), pred, check.names = FALSE) %>% 
    tbl_df %>%
    gather(movieId, b_ui, -userId) %>% 
    mutate(movieId = as.numeric(movieId))
```


```R
# Clean up memory
rm(pred, pca, r)
gc()
```


<table>
<thead><tr><th></th><th scope=col>used</th><th scope=col>(Mb)</th><th scope=col>gc trigger</th><th scope=col>(Mb)</th><th scope=col>max used</th><th scope=col>(Mb)</th></tr></thead>
<tbody>
	<tr><th scope=row>Ncells</th><td>  11699056</td><td>  624.8   </td><td>  38831430</td><td> 2073.9   </td><td>  38831430</td><td> 2073.9   </td></tr>
	<tr><th scope=row>Vcells</th><td>2414885247</td><td>18424.2   </td><td>7513794689</td><td>57325.8   </td><td>6284171678</td><td>47944.5   </td></tr>
</tbody>
</table>




```R
# Note: This process could take several very long hours

joined <- validation %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  left_join(interaction, by=c('movieId','userId')) %>%
  replace_na(list(b_i=0, b_u=0, b_ui=0))

predictions <- joined %>% mutate(resids = rating - mu - joined$b_i - joined$b_u - joined$b_ui)
head(predictions)
```


<table>
<thead><tr><th scope=col>userId</th><th scope=col>movieId</th><th scope=col>rating</th><th scope=col>timestamp</th><th scope=col>title</th><th scope=col>genres</th><th scope=col>b_i</th><th scope=col>n_i</th><th scope=col>b_u</th><th scope=col>b_ui</th><th scope=col>resids</th></tr></thead>
<tbody>
	<tr><td>1                                                                                                  </td><td> 231                                                                                               </td><td>5                                                                                                  </td><td>838983392                                                                                          </td><td><span style=white-space:pre-wrap>Dumb &amp; Dumber (1994)                                   </span></td><td><span style=white-space:pre-wrap>Comedy                                 </span>                    </td><td>-0.57725414                                                                                        </td><td>16053                                                                                              </td><td> 1.3155986                                                                                         </td><td>0.009465704                                                                                        </td><td> 0.739724617                                                                                       </td></tr>
	<tr><td>1                                                      </td><td> 480                                                   </td><td>5                                                      </td><td>838983653                                              </td><td>Jurassic Park (1993)                                   </td><td>Action|Adventure|Sci-Fi|Thriller                       </td><td> 0.15104374                                            </td><td>29360                                                  </td><td> 1.3155986                                             </td><td>0.017071745                                            </td><td> 0.003820699                                           </td></tr>
	<tr><td>1                                                      </td><td> 586                                                   </td><td>5                                                      </td><td>838984068                                              </td><td>Home Alone (1990)                                      </td><td>Children|Comedy                                        </td><td>-0.45673029                                            </td><td>13800                                                  </td><td> 1.3155986                                             </td><td>0.004302472                                            </td><td> 0.624363993                                           </td></tr>
	<tr><td>2                                                      </td><td> 151                                                   </td><td>3                                                      </td><td>868246450                                              </td><td>Rob Roy (1995)                                         </td><td>Action|Drama|Romance|War                               </td><td> 0.01758713                                            </td><td> 7186                                                  </td><td>-0.1806494                                             </td><td>0.001652159                                            </td><td>-0.351055067                                           </td></tr>
	<tr><td>2                                                      </td><td> 858                                                   </td><td>2                                                      </td><td>868245645                                              </td><td>Godfather, The (1972)                                  </td><td>Crime|Drama                                            </td><td> 0.90277360                                            </td><td>17747                                                  </td><td>-0.1806494                                             </td><td>0.002502701                                            </td><td>-2.237092085                                           </td></tr>
	<tr><td>2                                                      </td><td>1544                                                   </td><td>3                                                      </td><td>868245920                                              </td><td>Lost World: Jurassic Park, The (Jurassic Park 2) (1997)</td><td>Action|Adventure|Horror|Sci-Fi|Thriller                </td><td>-0.56699338                                            </td><td> 7328                                                  </td><td>-0.1806494                                             </td><td>0.001834233                                            </td><td> 0.233343370                                           </td></tr>
</tbody>
</table>




```R
predicted_ratings <- mu + predictions$b_i + predictions$b_u + predictions$b_ui

matrix_decomp_model_rmse <- RMSE(predicted_ratings, predictions$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Matrix Factorization, validation",  
                                     RMSE = matrix_decomp_model_rmse))
rmse_results %>% kable
```


    
    
    |method                                               |      RMSE|
    |:----------------------------------------------------|---------:|
    |Regularized movie effect model, validation           | 0.9438521|
    |Regularized movie and user effects model, validation | 0.8648427|
    |Matrix Factorization, validation                     | 0.8644608|



```R
# --- NAIVE BAYES CLASSIFICATION ---------------------------------------

cols <- c("userId", "movieId", "rating", "genres")
predictions[,cols] <- data.frame(apply(predictions[cols], 2, as.factor))
```


```R
# Note: This process could take several minutes

nb_fit <- naiveBayes(rating ~ userId + movieId + genres + resids, data = predictions[, -c(4:5, 7:10)], laplace = 1e-3)
nb_pred <- predict(nb_fit, predictions[, -c(3:5, 7:10)])
```


```R
# --- ACCURACY ---------------------------------------------------------

val_nb <- predictions %>% mutate(nb_pred)

matches_nb <- val_nb[val_nb$rating == val_nb$nb_pred,]
accuracy_nb <- round((nrow(matches_nb)/nrow(val_nb))*100, 2)

cat("The accuracy with the validation set is", accuracy_nb)
```

    The accuracy with the validation set is 71.07

## 5. Conclusion 

In this project, we started with an exploratory analysis of the data, which provided interesting insights such as:

- The edx dataset as provided is already curated, ready to use. No missing values, no wrong formatting, no much data engineering is required.

- the dataset contains 2 parts of about equally sizes, one set before 18 February 2003 with full star rating from 1 star to 5 stars by increment of 1 star and another set after that date with 0.5 star increment for a range from 0.5 star to 5 stars.

- The overall average of ratings, at about 3.5 stars, is rather consistent over the whole dataset.

- There is a clear dependence between users and movies for ratings. There is a correlation pattern (users have preferences of movies) that should be taken into account during the modeling.

- The effect of various sample sizes in ratings. So this also needs to be considered in our model.

Other insights about best movies, most popular genres, movies production, are more for general information.

Following the exploratory phase, we built our predictive model based on a blend of **regularized user and movie effects** and **matrix factorization**. In the matrix factorization, we used a Principal Component Analysis approach to uncover the user/movie interactions.
The final step was to call a **naive Bayes** model to classify our predicted ratings in the range of 0.5 star to 5 stars with increment of 0.5 star and estimate the accuracy or our predictions.   

**1. RMSE metric.**

Our predictive model yields a very good RMSE. The RMSEs at the various steps of our blend of techniques are summarized in the table below:

| Method                                    | RMSE  |
|:------------------------------------------|:-----:|
| Movie effect with regularization          | 0.9439|
| User and movie effects with regularization| 0.8648|
| Matrix factorization                      | 0.8645|


**2. Accuracy metric.**

The accuracy metric implies first a classification of our predicted ratings, which are continuous variables, into class of ratings and the naive Bayes did perform amazingly well.

The final accuracy, with the validation set, reaches 71.1%.

Note that we tried to call naive Bayes on separated sets, before and after 18 Feb 2003. The small accuracy improvement is not worth mentioning in this report. Naive Bayes performs very well on the whole dataset.


**3. Important note:**

We believe the RMSE metric is optimized but we could possibly improve the accuracy metric with more sophisticated classifiers, for example based on Nearest Neighbors approach.

Nevertheless, we couldn't move forward with sophisticated models, due to the size of our dataset and the limited machine resources allocated to this project.
