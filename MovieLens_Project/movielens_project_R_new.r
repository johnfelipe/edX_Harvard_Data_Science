
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

# --- USED LIBRARIES ----------------------------------------

if(!require(lubridate)) install.packages("lubridate", repos = "http://cran.r-project.org")
if(!require(gridExtra)) install.packages("gridExtra", repos = "http://cran.r-project.org")

# --- INITIAL EXPLORATION OF THE EDX DATASET ----------------

# Dimensions of the edx dataset

head(edx)

cat("The edx dataset has", nrow(edx), "rows and", ncol(edx), "columns.\n")
cat("There are", n_distinct(edx$userId), "different users and", n_distinct(edx$movieId), "different movies in the edx dataset.")

# Check if edx has missing values
any(is.na(edx))

# What are the ratings year by year?
# Note: This process could take several minutes

edx_year_rating <- edx %>% 
    transform (date = as.Date(as.POSIXlt(timestamp, origin = "1970-01-01", format = "%Y-%m-%d"), format = "%Y-%m-%d")) %>%
    mutate (year_month = format(as.Date(date), "%Y-%m"))

ggplot(edx_year_rating) + 
    geom_point(aes(x = date, y = rating)) +
    scale_x_date(date_labels = "%Y", date_breaks  = "1 year") +
    labs(title = "Ratings Year by Year", x = "Year", y = "Rating")

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

# Clean up memory
rm(edx_year_rating, edx_yearmonth_rating)
gc()

# --- EXPLORING USERS ---------------------------------------

edx_users <- edx %>%
    group_by(userId) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

summary(edx_users$count)

cat("The most active user(s) rated", max(edx_users$count), "movies and the least active user(s) rated", min(edx_users$count), "movies.\n")
cat("In average, an user rated about", round(mean(edx_users$count)), "movies, and the median is", median(edx_users$count), "movies.")

ggplot(edx_users) +
        geom_point(aes(x = userId, y = count)) +
        scale_y_log10() +
        labs(title = "Users' Activity", x = "userId", y = "Number of reviews (log scale)")        

# How many active users do we have per year?

users_year <- edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    select(timestamp, userId) %>%
    group_by(timestamp) %>%
    summarise(count = n_distinct(userId))
              
ggplot(data = users_year, aes(x = timestamp, y = count)) +
    geom_bar(stat = "identity") + 
    labs(title = "Active Users per Year", x = "Year", y = "Number of active users")

# How many reviews do we have for the most active users?

user_year_rating <-edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    group_by(timestamp, userId) %>%
    summarise(count = n()) %>%
    arrange(desc(count))

summary(user_year_rating$count)

# Let's see further about high counts of reviews given

head(user_year_rating)

# Let's see further about userId 14463.

userId_14463 <- edx %>% 
    filter(userId == 14463) %>%
    summarize(count = n(), avg = mean(rating), median = median(rating), std = sd(rating), max = max(rating), min = min(rating))
    
userId_14463

# --- Users' rating characteristics -------------------------

users_rating_char <- edx %>%
    group_by(userId) %>%
    summarize(count = n(), avg = mean(rating), median = median(rating), std = sd(rating)) %>%
    arrange(desc(count))

# What are the averages of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = avg)) +
    labs(title = "Averages of Ratings per User", x = "userId", y = "Rating")

# What are the medians of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = median)) +
    labs(title = "Medians of Ratings per User ", x = "userId", y = "Rating")

# What are the standard deviations of ratings per user?
ggplot(users_rating_char) + 
    geom_point(aes(x = userId, y = std)) +
    labs(title = "Standard Deviations of Ratings per User", x = "userId", y = "Rating")

# Clean up memory
rm(edx_users, users_year, user_year_rating, userId_14463, users_rating_char)
gc()

# --- EXPLORING MOVIES --------------------------------------

edx_movies <- edx %>%
    group_by(movieId) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

summary(edx_movies$count)

cat("The most reviewed movie(s) was(were) rated by", max(edx_movies$count), "users and the least reviewed one(s) was(were) rated by", min(edx_movies$count), "user.\n")
cat("A movie, in average, is rated about", round(mean(edx_movies$count)), "times, and the median is", median(edx_movies$count), "ratings.")

# How many movies are rated per year?

movies_year <- edx %>%
    transform(timestamp = format(as.POSIXlt(timestamp, origin = "1970-01-01"), "%Y")) %>%
    select(timestamp, movieId) %>%
    group_by(timestamp) %>%
    summarise(count = n_distinct(movieId))
              
ggplot(data = movies_year, aes(x = timestamp, y = count)) +
    geom_bar(stat = "identity") + 
    labs(title = "Movies Rated per Year", x = "Year", y = "Number of ratings")

# What are the most reviewed movies? 
movies_votes <- edx %>%
    group_by(movieId, title) %>%
    summarize(count = n()) %>%
    arrange(desc(count))

head(movies_votes)

# What are the most popular movies? 

# Best movies (by ratings average and with a minimum of 1,000 ratings)
top_movies <- edx %>%
    group_by(movieId, title) %>%
    filter(n() >= 1000) %>%
    summarise(count = n(), avg = mean(rating), median = median(rating), min = min(rating), max = max(rating)) %>%
    arrange(desc(avg))

head(top_movies)

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

# Top 10 popular movies

top10_movies <- new_top_movies %>% select(movieId, title, count, avg) %>% head(10)

ggplot(data = top10_movies, aes(x = title, y = avg)) +
    geom_point(aes(size = count),color = "blue") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0)) +
    labs(title = "Most Popular Movies", x = "Movie", y = "Rating average")

head(new_top_movies, 10)

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

# What are the most rated movie genres?
# Note: This process could take several minutes

movies_genre <- edx %>%
    separate_rows(genres, sep = "\\|")

genres_ratings <- movies_genre %>% # Separate the combined genre categories into single genres
    group_by(genres) %>%
    summarise(count = n()) %>%
    arrange(desc(count))

genres_ratings 

movies_genre %>% filter(genres == "(no genres listed)")

ggplot(data = genres_ratings, aes(x = reorder(genres, -count), y = count)) +
        geom_bar(stat = "identity") + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(title = "Movies by Genre", x = "Movies genre", y = "Number of ratings")

# What are the most popular genres? 

# Best genres (by ratings average)
top_genres <- movies_genre %>%
  group_by(genres) %>%
  summarise(count = n(), avg = mean(rating)) %>%
  arrange(desc(avg))

top_genres

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

# Most popular genres
ggplot(data = new_top_genres, aes(x = genres, y = avg)) +
    geom_point(aes(size = count),color = "blue") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0)) +
    labs(title = "Most Popular Genres", x = "Movies genre", y = "Rating average")

# Clean up memory
rm(edx_movies, movies_year, movies_votes, top_movies, wr, new_top_movies, top10_movies, 
   title_year, movies_title_year, 
   movies_genre, genres_ratings, top_genres, new_top_genres) 
gc()

# --- EXPLORING RATINGS -------------------------------------

summary(edx$rating)

# Distribution of ratings
ggplot(data = edx, aes(x = rating)) +
    geom_bar() + 
    labs(title = "Distribution of Ratings", x = "Rating", y = "Number of ratings")

# How do the ratings distributions compare before and after half-star scores are allowed?
# The half-star rating has been implemented from 18 February 2003 (timestamp = 1045526400

edx_before <- subset(edx, timestamp < 1045526400)
edx_after <- subset(edx, timestamp >= 1045526400)

# Numbers of rows before and after 18 Feb 2003
cat("There are", nrow(edx_before), "ratings before 18 Feb 2003, without half-star scoring and", nrow(edx_after), "ratings after 18 Feb 2003, with half-star scoring.")

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

ggplot(data = rates, aes(x = count_users, y = count_ratings)) + 
                geom_point() + 
                geom_smooth(method = "lm") +
                labs(title = "Number of Users vs Number of Ratings", x = "Number of users", y = "Number of ratings")

# Ratings average per year

avg_rating_year <- edx_year_rating %>%
  group_by(timestamp) %>%
  summarise(count = n(), average = mean(rating), std = sd(rating), median = median(rating), min = min(rating), max = max(rating)) %>%
  arrange(desc(average))

ggplot(data = avg_rating_year, aes(x = timestamp, y = average)) +
                geom_point(aes(size = count),color = "blue") +
                labs(title = "Rating Averages, aggregated by year", x = "Year", y = "Rating Average")

# Clean up memory
rm(edx_before, edx_after, pbef, paft,
   edx_year_rating, users_year, ratings_year, rates, avg_rating_year)
gc()

# --- USED LIBRARIES ----------------------------------------

if(!require(knitr)) install.packages("knitr", repos = "http://cran.us.r-project.org")
# if(!require(e1071)) install.packages("e1071", repos = "http://cran.r-project.org")

# --- SPLIT TRAIN/TEST SETS ---------------------------------

set.seed(699)
test_index <- createDataPartition(y = edx$rating, times = 1, p = 0.2, list = FALSE)
train_set <- edx[-test_index,]
test_set <- edx[test_index,]

# Use semi_join() to ensure that all users and movies in the test set are also in the training set
test_set <- test_set %>% 
  semi_join(train_set, by = "movieId") %>%
  semi_join(train_set, by = "userId")

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

# --- MODELING USER AND MOVIE EFFECTS ----------------------------------

# Let's plot the average rating for users who have rated at least 100 movies
train_set %>% 
  group_by(userId) %>% 
  summarize(b_u = mean(rating)) %>% 
  filter(n() >= 100) %>%
  ggplot(aes(b_u)) + 
  geom_histogram(bins = 30, color  = "black")

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

# --- MATRIX DECOMPOSITION ---------------------------------------------

# We use PCA to uncover patterns in user/movie relationships

# First, tet's remove the user and movie bias to create residuals
new_train_set <- train_set %>% 
  left_join(movie_reg_means, by = "movieId") %>% 
  left_join(user_reg_means, by = "userId") %>%
  mutate(resids = rating - mu - b_i - b_u)

# Next we create a matrix using spread()
# Note: This process could take several minutes

r <- new_train_set %>% 
  select(userId, movieId, resids) %>%
  spread(movieId, resids) %>% 
  as.matrix()

rownames(r) <- r[,1]
r <- r[,-1]
r[is.na(r)] <- 0 # For the sake of simplicity, we just apply 0 to all missing data

# Singular value decomposition
# Note: This process could take several long minutes

pca <- prcomp(r - rowMeans(r), center = TRUE, scale = FALSE)

dim(pca$x) # Principal components
dim(pca$rotation) # Users' effects

# Variability
var_explained <- cumsum(pca$sdev^2/sum(pca$sdev^2))
plot(var_explained)

# Factorization of the 4000 first principal components, which explain almost all the variability 

k <- 4000

pred <- pca$x[,1:k] %*% t(pca$rotation[,1:k])
colnames(pred) <- colnames(r)

# Note: This process could take several very long minutes

interaction <- 
    data.frame(userId = as.numeric(rownames(r)), pred, check.names = FALSE) %>% 
    tbl_df %>%
    gather(movieId, b_ui, -userId) %>% 
    mutate(movieId = as.numeric(movieId))

# Clean up memory
rm(pred, pca, r)
gc()

# Note: This process could take several very long hours

joined <- test_set %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  left_join(interaction, by=c('movieId','userId')) %>%
  replace_na(list(b_i=0, b_u=0, b_ui=0))

predictions <- joined %>% mutate(resids = rating - mu - joined$b_i - joined$b_u - joined$b_ui)
head(predictions)

predicted_ratings <- mu + predictions$b_i + predictions$b_u + predictions$b_ui

matrix_decomp_model_rmse <- RMSE(predicted_ratings, predictions$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Matrix Factorization",  
                                     RMSE = matrix_decomp_model_rmse))
rmse_results %>% kable

# --- NAIVE BAYES CLASSIFICATION ---------------------------------------

cols <- c("userId", "movieId", "rating", "genres")
predictions[,cols] <- data.frame(apply(predictions[cols], 2, as.factor))

# Note: This process could take several minutes

library(e1071)

nb_fit <- naiveBayes(rating ~ userId + movieId + genres + resids, data = predictions[, -c(4:5, 7:10)], laplace = 1e-3)
nb_pred <- predict(nb_fit, predictions[, -c(3:5, 7:10)])

# --- ACCURACY ---------------------------------------------------------

val_nb <- predictions %>% mutate(nb_pred)

matches_nb <- val_nb[val_nb$rating == val_nb$nb_pred,]
accuracy_nb <- round((nrow(matches_nb)/nrow(val_nb))*100, 2)

cat("The accuracy with the test set is", accuracy_nb)

# Clean up memory
rm(test_index, train_set, test_set,
   RMSE, mu, predictions, naive_rmse,
   rmse_results, movie_means, joined, predicted_ratings, model1_rmse,
   lambdas, tmp, rmses, lambda, movie_reg_means, model1_reg_rmse,
   lambdas_2, lambda_2, user_reg_means, model2_reg_rmse,
   new_train_set, var_explained, k, interaction, matrix_decomp_model_rmse,
   cols, nb_fit, nb_pred, val_nb, matches_nb, accuracy_nb)
gc()

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

# --- MATRIX DECOMPOSITION ---------------------------------------------

# We use PCA to uncover patterns in user/movie relationships

# First, tet's remove the user and movie bias to create residuals
new_edx <- edx %>% 
  left_join(movie_reg_means, by = "movieId") %>% 
  left_join(user_reg_means, by = "userId") %>%
  mutate(resids = rating - mu - b_i - b_u)

# Next we create a matrix using spread()
# Note: This process could take several minutes

r <- new_edx %>% 
  select(userId, movieId, resids) %>%
  spread(movieId, resids) %>% 
  as.matrix()

rownames(r) <- r[,1]
r <- r[,-1]
r[is.na(r)] <- 0 # For the sake of simplicity, we just apply 0 to all missing data

# Singular value decomposition
# Note: This process could take several long minutes

pca <- prcomp(r - rowMeans(r), center = TRUE, scale = FALSE)

# Variability
var_explained <- cumsum(pca$sdev^2/sum(pca$sdev^2))
plot(var_explained)

# Factorization of the 4000 first principal components, which explain almost all the variability 

k <- 4000

pred <- pca$x[,1:k] %*% t(pca$rotation[,1:k])
colnames(pred) <- colnames(r)

# Note: This process could take several very long minutes

interaction <- 
    data.frame(userId = as.numeric(rownames(r)), pred, check.names = FALSE) %>% 
    tbl_df %>%
    gather(movieId, b_ui, -userId) %>% 
    mutate(movieId = as.numeric(movieId))

# Clean up memory
rm(pred, pca, r)
gc()

# Note: This process could take several very long hours

joined <- validation %>% 
  left_join(movie_reg_means, by='movieId') %>% 
  left_join(user_reg_means, by='userId') %>% 
  left_join(interaction, by=c('movieId','userId')) %>%
  replace_na(list(b_i=0, b_u=0, b_ui=0))

predictions <- joined %>% mutate(resids = rating - mu - joined$b_i - joined$b_u - joined$b_ui)
head(predictions)

predicted_ratings <- mu + predictions$b_i + predictions$b_u + predictions$b_ui

matrix_decomp_model_rmse <- RMSE(predicted_ratings, predictions$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method = "Matrix Factorization, validation",  
                                     RMSE = matrix_decomp_model_rmse))
rmse_results %>% kable

# --- NAIVE BAYES CLASSIFICATION ---------------------------------------

cols <- c("userId", "movieId", "rating", "genres")
predictions[,cols] <- data.frame(apply(predictions[cols], 2, as.factor))

# Note: This process could take several minutes

nb_fit <- naiveBayes(rating ~ userId + movieId + genres + resids, data = predictions[, -c(4:5, 7:10)], laplace = 1e-3)
nb_pred <- predict(nb_fit, predictions[, -c(3:5, 7:10)])

# --- ACCURACY ---------------------------------------------------------

val_nb <- predictions %>% mutate(nb_pred)

matches_nb <- val_nb[val_nb$rating == val_nb$nb_pred,]
accuracy_nb <- round((nrow(matches_nb)/nrow(val_nb))*100, 2)

cat("The accuracy with the validation set is", accuracy_nb)
