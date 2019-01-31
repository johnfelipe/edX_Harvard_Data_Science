
# --- LIBRARIES ----------------------------------------------------------------

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(gridExtra)) install.packages("gridExtra", repos = "http://cran.r-project.org")
if(!require(rpart)) install.packages("rpart", repos = "http://cran.r-project.org")
if(!require(rpart.plot)) install.packages("rpart.plot", repos = "http://cran.r-project.org")
if(!require(randomForest)) install.packages("randomForest", repos = "http://cran.r-project.org")
if(!require(rpart)) install.packages("rpart", repos = "http://cran.r-project.org")
if(!require(rpart.plot)) install.packages("rpart.plot", repos = "http://cran.r-project.org")
if(!require(randomForest)) install.packages("randomForest", repos = "http://cran.r-project.org")

# --- ORIGINAL DATASET ---------------------------------------------------------

# Read csv file from IBM Watson Analytics sample datasets
# https://www.ibm.com/communities/analytics/watson-analytics-blog/guide-to-sample-datasets/

crm <- read.csv(url("https://community.watsonanalytics.com/wp-content/uploads/2015/04/WA_Fn-UseC_-Sales-Win-Loss.csv?cm_mc_uid=32200886596915345345263&cm_mc_sid_50200000=88110211548169944710&cm_mc_sid_52640000=47085071548169944717"), 
              header = TRUE)

# --- INITIAL EXPLORATION OF THE DATASET ---------------------------------------

# Let's have a look at our crm dataset
head(crm)

# Let's see the structure of our dataset and the types of variables that it contains
str(crm)

# We note that some features have the wrong type as integer instead of factor

# Let's convert them to the right type
cols <- c("Client.Size.By.Employee.Count", "Client.Size.By.Revenue", "Deal.Size.Category", "Revenue.From.Client.Past.Two.Years")
crm[, cols] <- data.frame(apply(crm[cols], 2, as.factor))

# Let's check again the types of our variables 
str(crm)

# Let's check if our dataset has missing values
cat("Do we have any missing value?", any(is.na(crm)),"\n")

# Let's check if our dataset has duplicated rows
cat("We have", n_distinct(crm$Opportunity.Number), "unique opportunity numbers out of a total of", nrow(crm), 
    "so the percentage of duplicated rows is:", (1-n_distinct(crm$Opportunity.Number)/nrow(crm))*100)

# So we have 0.25% of our dataset that is duplications. Let's see what rows are duplicated and how they are duplicated.
n_occur <- data.frame(table(crm$Opportunity.Number))
head(crm[crm$Opportunity.Number %in% n_occur$Var1[n_occur$Freq > 1],], 10)

# Some duplications are simple row duplication but some others look like an update of the opportunity (mostly the USD amount) in a new row.
# As we don't have any date information to identify the update, we will just delete the duplications. 
crm <- crm[!duplicated(crm["Opportunity.Number"]), ]

# Let's check if our new dataset has missing values
cat("Do we have any missing value?", any(is.na(crm)),"\n")

# Let's check if our new dataset has duplicated rows
cat("We have", n_distinct(crm$Opportunity.Number), "unique opportunity numbers out of a total of", nrow(crm), 
    "so the percentage of duplicated rows is:", (1-n_distinct(crm$Opportunity.Number)/nrow(crm))*100)

# Correlation for numeric features
cor(crm[,unlist(lapply(crm,is.numeric))])

# Correlation between "Total Days Identified Through Qualified" and "Total Days Identified Through Closing"

crm %>%
    select(Total.Days.Identified.Through.Closing, Total.Days.Identified.Through.Qualified) %>%
    
    ggplot(aes(x = Total.Days.Identified.Through.Qualified, y = Total.Days.Identified.Through.Closing)) +
    geom_point() + 
    geom_smooth(method = "lm") +
    labs(subtitle = "Total Days Through Qualified vs Total Days Through Closing", x = "Total Days Identified Through Qualified", y = "Total Days Identified Through Closing")

# Chi-squared test for factor/categorical features

ssg = chisq.test(crm$Supplies.Subgroup, crm$Supplies.Group, simulate.p.value = TRUE)$p.value
sr = chisq.test(crm$Supplies.Subgroup, crm$Region)$p.value
srm = chisq.test(crm$Supplies.Subgroup, crm$Route.To.Market, simulate.p.value = TRUE)$p.value
scsr = chisq.test(crm$Supplies.Subgroup, crm$Client.Size.By.Revenue)$p.value
scse = chisq.test(crm$Supplies.Subgroup, crm$Client.Size.By.Employee.Count)$p.value
sy = chisq.test(crm$Supplies.Subgroup, crm$Revenue.From.Client.Past.Two.Years, simulate.p.value = TRUE)$p.value
sc = chisq.test(crm$Supplies.Subgroup, crm$Competitor.Type)$p.value
sd = chisq.test(crm$Supplies.Subgroup, crm$Deal.Size.Category)$p.value

gr = chisq.test(crm$Supplies.Group, crm$Region)$p.value
grm = chisq.test(crm$Supplies.Group, crm$Route.To.Market, simulate.p.value = TRUE)$p.value
gcsr = chisq.test(crm$Supplies.Group, crm$Client.Size.By.Revenue)$p.value
gcse = chisq.test(crm$Supplies.Group, crm$Client.Size.By.Employee.Count)$p.value
gy = chisq.test(crm$Supplies.Group, crm$Revenue.From.Client.Past.Two.Years, simulate.p.value = TRUE)$p.value
gc = chisq.test(crm$Supplies.Group, crm$Competitor.Type)$p.value
gd = chisq.test(crm$Supplies.Group, crm$Deal.Size.Category)$p.value

rrm = chisq.test(crm$Region, crm$Route.To.Market)$p.value
rcsr = chisq.test(crm$Region, crm$Client.Size.By.Revenue)$p.value
rcse = chisq.test(crm$Region, crm$Client.Size.By.Employee.Count)$p.value
ry = chisq.test(crm$Region, crm$Revenue.From.Client.Past.Two.Years)$p.value
rc = chisq.test(crm$Region, crm$Competitor.Type)$p.value
rd = chisq.test(crm$Region, crm$Deal.Size.Category)$p.value

mcsr = chisq.test(crm$Route.To.Market, crm$Client.Size.By.Revenue)$p.value
mcse = chisq.test(crm$Route.To.Market, crm$Client.Size.By.Employee.Count)$p.value
my = chisq.test(crm$Route.To.Market, crm$Revenue.From.Client.Past.Two.Years)$p.value
mc = chisq.test(crm$Route.To.Market, crm$Competitor.Type)$p.value
md = chisq.test(crm$Route.To.Market, crm$Deal.Size.Category)$p.value

ccse = chisq.test(crm$Client.Size.By.Revenue, crm$Client.Size.By.Employee.Count)$p.value
cy = chisq.test(crm$Client.Size.By.Revenue, crm$Revenue.From.Client.Past.Two.Years)$p.value
cc = chisq.test(crm$Client.Size.By.Revenue, crm$Competitor.Type)$p.value
cd = chisq.test(crm$Client.Size.By.Revenue, crm$Deal.Size.Category)$p.value

ey = chisq.test(crm$Client.Size.By.Employee.Count, crm$Revenue.From.Client.Past.Two.Years)$p.value
ec = chisq.test(crm$Client.Size.By.Employee.Count, crm$Competitor.Type)$p.value
ed = chisq.test(crm$Client.Size.By.Employee.Count, crm$Deal.Size.Category)$p.value

yc = chisq.test(crm$Revenue.From.Client.Past.Two.Years, crm$Competitor.Type)$p.value
yd = chisq.test(crm$Revenue.From.Client.Past.Two.Years, crm$Deal.Size.Category)$p.value

td = chisq.test(crm$Competitor.Type, crm$Deal.Size.Category)$p.value

cormatrix = matrix(c(0, ssg, sr, srm, scsr, scse, sy, sc, sd,
                     ssg, 0, gr, grm, gcsr, gcse, gy, gc, gd,
                     sr, gr, 0, rrm, rcsr, rcse, ry, rc, rd, 
                     srm, grm, rrm, 0, mcsr, mcse, my, mc, md,
                     scsr, gcsr, rcsr, mcsr, 0, ccse, cy, cc, cd,
                     scse, gcse, rcse, mcse, ccse, 0, ey, ec, ed,
                     sy, gy, ry, my, cy, ey, 0, yc, yd,
                     sc, gc, rc, mc, cc, ec, yc, 0, td,
                     sd, gd, rd, md, cd, ed, yd, td, 0), 
                   9, 9, byrow = TRUE)

row.names(cormatrix) = colnames(cormatrix) = c("Supplies.Subgroup", "Supplies.Group", "Region", "Route.To.Market", "Client.Size.By.Revenue",
                                              "Client.Size.By.Employee.Count", "Revenue.From.Client.Past.Two.Years", "Competitor.Type", "Deal.Size.Category")
cormatrix

# Let's see the frequencies for our variable of interest, the win/loss opportunities
table(crm$Opportunity.Result) 

# Let's see the rates of win/loss opportunities
round(table(crm$Opportunity.Result)/nrow(crm), 2) 

cat("The maximum opportunity amount is", max(crm$Opportunity.Amount.USD)/1000, "thousand USD, the average is", 
    round(mean(crm$Opportunity.Amount.USD)), "thousand USD, and the median is",
    median(crm$Opportunity.Amount.USD), "thousand USD.")

# --- OPPORTUNITY AMOUNTS AND OPPORTUNITY RESULTS BY REGION ---------------------------------------------------------------------

# Opportunity amounts by region
par <- ggplot(data = crm, aes(x = Region, y = Opportunity.Amount.USD/1000)) +
            geom_bar(stat = "identity", fill = "#D55E00") +
            theme(axis.text.x = element_text()) +
            labs(subtitle = "Opportunity Amounts across Regions", x = "", y = "Value in kUSD")


# Opportunity results by region
prr <- ggplot(data = crm, aes(Region, fill = Opportunity.Result)) +
            geom_bar(aes(y = (..count..)/sum(..count..)), alpha = 0.9, position = "dodge") +
            scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
            scale_y_continuous(labels = scales::percent) +
            theme(axis.text.x = element_text()) +
            labs(subtitle = "Opportunities Results across Regions", x = "", y = "Total Opportunities")

# Success rates by region
psr <- crm %>%
        group_by(Region, Opportunity.Result) %>%
        summarise(count = n()) %>%
        spread(key = "Opportunity.Result", value = "count", convert = TRUE) %>%
        mutate(success_rate = Won / (Won + Loss)) %>%

        ggplot(aes(x = Region, y = success_rate)) + 
            geom_bar(stat = "identity", fill = "#009E73") +
            geom_text(aes(label = round(success_rate*100, 1)), position = position_stack(vjust = 0.5)) +
            scale_y_continuous(labels = scales::percent) +
            theme(axis.text.x = element_text()) +
            labs(subtitle = "Success Rates by Region", x = "", y = "Success Rate")

grid.arrange(par, prr, psr, layout_matrix = rbind(c(1, 1, 1), c(2, 2, 2), c(3, 3, 3)))

# --- OPPORTUNITY RESULTS BASED ON OPPORTUNITY AMOUNTS BY REGION ----------------------------------------------------------------

# Let's see how the opportunity amount influences our deal outcome
ggplot(data = crm, aes(x = Region, y = Opportunity.Amount.USD/1000, fill = Opportunity.Result)) +
    geom_boxplot() +
    scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
    labs(subtitle = "Opportunities Results based on Opportunity Amounts accross Regions", x = "", y = "Value in kUSD")

# --- OPPORTUNITY RESULTS BY DEAL SIZE CATEGORY ---------------------------------------------------------------------------------

# Opportunity results by deal size category 
prd <- ggplot(data = crm, aes(Deal.Size.Category, fill = Opportunity.Result)) +
        geom_bar(aes(y = (..count..)/sum(..count..)), alpha = 0.9, position = "dodge") +
        scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
        scale_y_continuous(labels = scales::percent) +
        scale_x_discrete(labels = c("1" = "< 10 kUSD", "2" = "[10 kUDS, 25 kUSD]", "3" = "[25 kUDS, 50 kUSD]",
                                    "4" = "[50 kUDS, 100 kUSD]", "5" = "[100 kUDS, 250 kUSD]", 
                                    "6" = "[250 kUDS, 500 kUSD]", "7" = "> 500 kUSD")) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Opportunity Results by Deal Size Category", x = "", y = "Total Opportunities")

# Success rates by deal size category
psd <- crm %>%
        group_by(Deal.Size.Category, Opportunity.Result) %>%
        summarise(count = n()) %>%
        spread(key = "Opportunity.Result", value = "count", convert = TRUE) %>%
        mutate(success_rate = Won / (Won + Loss)) %>%

        ggplot(aes(x = Deal.Size.Category, y = success_rate)) + 
            geom_bar(stat = "identity", fill = "#009E73") +
            geom_text(aes(label = round(success_rate*100, 1)), position = position_stack(vjust = 0.5)) +
            scale_y_continuous(labels = scales::percent) +
            scale_x_discrete(labels = c("1" = "< 10 kUSD", "2" = "[10 kUDS, 25 kUSD]", "3" = "[25 kUDS, 50 kUSD]",
                                        "4" = "[50 kUDS, 100 kUSD]", "5" = "[100 kUDS, 250 kUSD]", 
                                        "6" = "[250 kUDS, 500 kUSD]", "7" = "> 500 kUSD")) +
            theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
            labs(subtitle = "Success Rates by Deal Size Category", x = "", y = "Success Rate")

grid.arrange(prd, psd, layout_matrix = rbind(c(1, 1), c(2, 2)))

# --- OPPORTUNITY AMOUNTS BY REGION AND ROUTE TO MARKET -------------------------------------------------------------------------

# Routes to Market by Region
ggplot(data = crm, aes(x = Region, y = Opportunity.Amount.USD/1000, fill = Route.To.Market), alpha = 0.9) + 
    geom_bar(stat = "identity", position = "stack") +
    scale_fill_discrete(name = "Route To Market") +
    labs(subtitle = "Opportunity Amounts across Routes to Market and by Region", x = "", y = "Value in kUSD")

# --- OPPORTUNITY RESULTS BY ROUTE TO MARKET AND DEAL SIZE CATEGORY -------------------------------------------------------------

# Opportunity results by route to market and deal size category 

labels <- c("1" = "< 10 kUSD", "2" = "[10 kUDS, 25 kUSD]", "3" = "[25 kUDS, 50 kUSD]", "4" = "[50 kUDS, 100 kUSD]", 
            "5" = "[100 kUDS, 250 kUSD]", "6" = "[250 kUDS, 500 kUSD]", "7" = "> 500 kUSD")

ggplot(data = crm, aes(Route.To.Market, fill = Opportunity.Result)) +
        geom_bar(aes(y = (..count..)/sum(..count..)), alpha = 0.9, position = "dodge") +
        scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
        scale_y_continuous(labels = scales::percent) +
        facet_wrap(~Deal.Size.Category, labeller = labeller(Deal.Size.Category = labels)) + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Opportunity Results by Route to Market and Deal Size Category", x = "", y = "Percentage of Total Results")

# Success rates by route to market and deal size category

crm %>%
    group_by(Route.To.Market, Deal.Size.Category, Opportunity.Result) %>%
    summarise(count = n()) %>%
    spread(key = "Opportunity.Result", value = "count", fill = 0, convert = TRUE) %>%
    mutate(success_rate = Won / (Won + Loss)) %>%

    ggplot(aes(x = Route.To.Market, y = success_rate)) + 
        geom_bar(stat = "identity",  fill = "#009E73") +
        geom_text(aes(label = round(success_rate*100, 1)), position = position_stack(vjust = 0.5)) +
        scale_y_continuous(labels = scales::percent) +
        facet_wrap(~Deal.Size.Category, labeller = labeller(Deal.Size.Category = labels)) + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Success Rates by Route To Market and by Deal Size Category", x = "", y = "Success Rate")

# --- CREATE DATASETS FOR THE PROJECT -------------------------------------------------------------------------------------------

# Sales set is 90% of the crm data and Validation set is the remaining 10%
set.seed(1)
test_index <- createDataPartition(y = crm$Opportunity.Result, times = 1, p = 0.1, list = FALSE)
sales <- crm[-test_index,]
validation <- crm[test_index,]

# --- SPLIT TRAIN/TEST SETS -----------------------------------------------------------------------------------------------------

set.seed(699)
test_index <- createDataPartition(y = sales$Opportunity.Result, times = 1, p = 0.2, list = FALSE)
train_set <- sales[-test_index,]
test_set <- sales[test_index,]

# --- DECISION TREE WITH RPART PACKAGE ------------------------------------------------------------------------------------------

library(rpart)
library(rpart.plot)

# Fitting decision tree (rpart package) to the train set
# Note that we remove the Opportunity Number as it cannot be an actual cause of our 0pportunity Result
rpa_tree_fit <- rpart(Opportunity.Result ~ . -Opportunity.Number, data = train_set, method = "class") 

# Display the results 
printcp(rpa_tree_fit)

# Tree visualization
rpart.plot(rpa_tree_fit, extra = 4)

 # Detailed summary of splits
summary(rpa_tree_fit)

# Predicting the test set results
rpa_tree_pred <- predict(rpa_tree_fit, newdata = test_set[-7], type = "class") # remove "Opportunity Result" for prediction

# Confusion matrix
confusionMatrix(rpa_tree_pred, test_set$Opportunity.Result)

# --- RANDOM FOREST WITH RANDOMFOREST PACKAGE ----------------------------------------------------------------------------------

library(randomForest)

# Fitting random forest to the train set
# Note that we remove the Opportunity Number as it cannot be an actual cause of our 0pportunity Result
forest_fit = randomForest(Opportunity.Result ~ .-Opportunity.Number, data = train_set) 

# Choosing the number of trees
plot(forest_fit)

# Variables of importance
apply(importance(forest_fit), 2, sort, decreasing = TRUE)

# Predicting the test set results
forest_pred = predict(forest_fit, newdata = test_set[-7]) # remove "Opportunity Result" for prediction

# Confusion matrix
confusionMatrix(forest_pred, test_set$Opportunity.Result)

# --- VALIDATION OF RANDOM FOREST MODEL -----------------------------------------------------------------------------------------

# Fitting random forest to the sales set
val_forest_fit = randomForest(Opportunity.Result ~ .-Opportunity.Number, data = sales)

# Variables of importance
apply(importance(val_forest_fit), 2, sort, decreasing = TRUE)

# Predicting the validation set results
val_forest_pred = predict(val_forest_fit, newdata = validation[, -7]) # remove "Opportunity Result" for prediction

# Confusion matrix
confusionMatrix(val_forest_pred, validation$Opportunity.Result)

# --- OPPORTUNITY RESULTS BY REVENUE FROM CLIENT PAST 2 YEARS -------------------------------------------------------------------

# Opportunity results by revenue from client past 2 years 
prc <- ggplot(data = crm, aes(Revenue.From.Client.Past.Two.Years, fill = Opportunity.Result)) +
        geom_bar(aes(y = (..count..)), alpha = 0.9, position = "dodge") +
        scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
        scale_x_discrete(labels = c("0" = "No business", "1" = "[1 kUSD, 50 kUSD]", "2" = "[50 kUDS, 400 kUSD]",
                                    "3" = "[400 kUDS, 1.5 mUSD]", "4" = "> 1.5 mUSD")) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Opportunity Results by Revenue from Client past 2 Years", x = "", y = "Number of Opportunities")


# Success rates by revenue from client past 2 years 
psc <- crm %>%
        group_by(Revenue.From.Client.Past.Two.Years, Opportunity.Result) %>%
        summarise(count = n()) %>%
        spread(key = "Opportunity.Result", value = "count", convert = TRUE) %>%
        mutate(success_rate = Won / (Won + Loss)) %>%

        ggplot(aes(x = Revenue.From.Client.Past.Two.Years, y = success_rate)) +
            geom_bar(stat = "identity", fill = "#009E73") +
            geom_text(aes(label = round(success_rate*100, 1)), position = position_stack(vjust = 0.5)) +
            scale_y_continuous(labels = scales::percent) +
            scale_x_discrete(labels = c("0" = "No business", "1" = "[1 kUSD, 50 kUSD]", "2" = "[50 kUDS, 400 kUSD]",
                                        "3" = "[400 kUDS, 1.5 mUSD]", "4" = "> 1.5 mUSD")) +
            theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
            labs(subtitle = "Success Rates by Revenue from Client past 2 Years", x = "Categories of Revenue from Client Past 2 Years", y = "Success Rate")

grid.arrange(prc, psc, layout_matrix = rbind(c(1, 1, 1), c(2, 2, 2)))

# --- OPPORTUNITY RESULTS BY REVENUE FROM CLIENT PAST 2 YEARS AND TOTAL DAYS IDENTIFIED THROUGH QUALIFIED -----------------------

# Opportunity results by past revenues and total days identified through qualified
ggplot(data = crm, aes(x = Revenue.From.Client.Past.Two.Years, y = Total.Days.Identified.Through.Qualified, fill = Opportunity.Result)) +
    geom_boxplot() +
    scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
    scale_x_discrete(labels = c("0" = "No business", "1" = "[1 kUSD, 50 kUSD]", "2" = "[50 kUDS, 400 kUSD]",
                                "3" = "[400 kUDS, 1.5 mUSD]", "4" = "> 1.5 mUSD")) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
    labs(subtitle = "Opportunities based on Total Days Identified Through Qualified and by Revenue From Client Past Two Years ", 
         x = "Revenue From Client Past Two Years", y = "Total Days Identified Through Qualified")

# Opportunity results by past revenues and total days identified through qualified

labels_1 <- c("0" = "No business", "1" = "[1 kUSD, 50 kUSD]", "2" = "[50 kUDS, 400 kUSD]", "3" = "[400 kUDS, 1.5 mUSD]", "4" = "> 1.5 mUSD")
labels_2 <- c("1" = "< 2 days", "2" = "2 to 7 days", "3" = "8 to 15 days", "4" = "16 to 31 days", "5" = "> 1 month")

crm %>% 
    mutate(Total.Days.Identified.Through.Qualified.Category = cut(crm$Total.Days.Identified.Through.Qualified, c(0, 2, 8, 16, 32, 366),
                                                                  right = FALSE, labels = c(1:5))) %>%

    ggplot(aes(Revenue.From.Client.Past.Two.Years, fill = Opportunity.Result)) + 
        geom_bar(aes(y = (..count..)/sum(..count..)), alpha = 0.9, position = "dodge") +
        scale_fill_manual(name = "Opportunity Result", values = c("#CC6666", "#0072B2")) +
        scale_y_continuous(labels = scales::percent) +
        scale_x_discrete(labels = labels_1) +
        facet_wrap(~Total.Days.Identified.Through.Qualified.Category, labeller = labeller(Total.Days.Identified.Through.Qualified.Category = labels_2)) + 
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Opportunity Results by Past Revenues and Total Days Identified Through Qualified", 
         x = "Categories of Revenue from Client Past 2 Years", y = "Percentage of Total Results")

# Success rates by past revenues and total days identified through qualified

crm %>% 
    mutate(Total.Days.Identified.Through.Qualified.Category = cut(crm$Total.Days.Identified.Through.Qualified, c(0, 2, 8, 16, 32, 366), 
                                                                              right = FALSE, labels = c(1:5))) %>%
    group_by(Revenue.From.Client.Past.Two.Years, Total.Days.Identified.Through.Qualified.Category, Opportunity.Result) %>%
    summarise(count = n()) %>%
    spread(key = "Opportunity.Result", value = "count", convert = TRUE) %>%
    mutate(success_rate = Won / (Won + Loss)) %>%

ggplot(aes(x = Revenue.From.Client.Past.Two.Years, y = success_rate)) +
    geom_bar(stat = "identity",  fill = "#009E73") +
    geom_text(aes(label = round(success_rate*100, 1)), position = position_stack(vjust = 0.5)) +
    scale_y_continuous(labels = scales::percent) +
    scale_x_discrete(labels = labels_1) +
    facet_wrap(~Total.Days.Identified.Through.Qualified.Category, labeller = labeller(Total.Days.Identified.Through.Qualified.Category = labels_2)) + 
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
    labs(subtitle = "Success Rates by Past Revenues and by Total Days Identified Through Qualified", x = "Categories of Revenue from Client Past 2 Years", y = "Success Rate")

# --- OPPORTUNITY RESULTS BY REVENUE FROM CLIENT PAST 2 YEARS, TOTAL DAYS IDENTIFIED THROUGH QUALIFIED AND DEAL SIZE CATEGORY ---

# Success rates by past revenues, total days identified through qualified and deal size category
crm %>%
    mutate(Total.Days.Identified.Through.Qualified.Category = cut(crm$Total.Days.Identified.Through.Qualified, c(0, 2, 8, 16, 32, 366),
                                                                  right = FALSE, labels = c(1:5))) %>%
    group_by(Revenue.From.Client.Past.Two.Years, Total.Days.Identified.Through.Qualified.Category, Deal.Size.Category, Opportunity.Result) %>%
    summarise(count = n()) %>%
    spread(key = "Opportunity.Result", value = "count", fill = 0, convert = TRUE) %>%
    mutate(success_rate = Won / (Won + Loss)) %>%
    filter(Revenue.From.Client.Past.Two.Years == 0 & Total.Days.Identified.Through.Qualified.Category %in% c(1, 2, 3)) %>%

ggplot(aes(x = Deal.Size.Category, y = success_rate, 
                      group = interaction(Revenue.From.Client.Past.Two.Years, Total.Days.Identified.Through.Qualified.Category, Deal.Size.Category),
                      fill = Total.Days.Identified.Through.Qualified.Category), alpha = 0.9) +
        geom_bar(stat = "identity", position = "dodge") +
        scale_fill_discrete(name = "Total Days Identified Through Qualified", breaks = c(1, 2, 3), labels = c("< 2 days", "2 to 7 days", "8 to 15 days")) +
        scale_y_continuous(labels = scales::percent) +
        scale_x_discrete(labels = c("1" = "< 10 kUSD", "2" = "[10 kUDS, 25 kUSD]", "3" = "[25 kUDS, 50 kUSD]",
                                    "4" = "[50 kUDS, 100 kUSD]", "5" = "[100 kUDS, 250 kUSD]", 
                                    "6" = "[250 kUDS, 500 kUSD]", "7" = "> 500 kUSD")) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0)) +
        labs(subtitle = "Succesful Deal Conversions with New Prospects by Deal Size Category", x = "Deal Size Category", y = "Success Rate")
