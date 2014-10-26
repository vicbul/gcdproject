#lodaing additional libraries
library(sqldf)

Sys.setlocale(category = "LC_ALL", locale = "English")
#reading test and train files into a data frame
x_test <- read.table("UCI HAR Dataset/test/X_test.txt")
x_train <- read.table("UCI HAR Dataset/train/X_train.txt")

'1. Merging the training and the test sets to create one data set.'

x_all <- rbind(x_test,x_train)
#reading variable names from features.txt. Keeping only the column of variable names.
features <- read.table("UCI HAR Dataset/features.txt")[,2]
#using features as x_all data frame column names to better identify variables.
names(x_all) <- features

'2. Extracting only the measurements on the mean and standard deviation for each measurement.'

mean_std_cols <- grep("*.mean\\(\\)|std\\(\\).*",names(x_all))
x_all_mean_std <- x_all[,mean_std_cols]

'3, Using descriptive activity names to name the activities in the data set'

#reading activity factors and adding them as a new column in the data set
act_test <- read.table("UCI HAR Dataset/test/y_test.txt")
act_train <- read.table("UCI HAR Dataset/train/y_train.txt")
act_all <- rbind(act_test,act_train)
names(act_all) <- "activity"
all_activities <- cbind(act_all,x_all_mean_std)

#replacing activity numbers with activity descriptive names
all_activities$activity <- as.factor(all_activities$activity)
act_lbl <- read.table("UCI HAR Dataset/activity_labels.txt",col.names=c("factor","name"))
levels(all_activities$activity) <- act_lbl$name

'4. Appropriately labels the data set with descriptive variable names.'
#Features as variable names are descriptive enough. Just is convenient removing special characteres like "-" and "()"
names(all_activities) <- gsub("-","_",names(all_activities))
names(all_activities) <- gsub("\\(|\\)","",names(all_activities))

'5. From the data set in step 4, creating a second, independent tidy data set with the average of each variable 
for each activity and each subject.'

#Reading test and train subjects ids into a data frame and binding then with each other and with "all_activities" data set
test_sbj <- read.table("UCI HAR Dataset/test/subject_test.txt")
train_sbj <- read.table("UCI HAR Dataset/train/subject_train.txt")
subject <- rbind(test_sbj,train_sbj)
names(subject) <- 'subject'
all_activities <- cbind(subject,all_activities)

#Here we create a new data frame out of "all_activities" grouped by activity then subject as requested using sqldf()
tidy_data <- sqldf("select activity,subject from all_activities group by activity, subject")
#Using a for loop to process the average value for each variable grouped by activity then subject, 
#adding them to the new data frame with a new descriptive label  
for(name in names(all_activities[,3:ncol(all_activities)])) {
    tidy_data <- cbind(tidy_data,fn$sqldf("select avg($name) as $name_avg from all_activities group by activity,subject"))
}

#FInally we clean the environment keeping the tidy data and writting it into a txt file
rm(list=subset(ls(),ls()!="tidy_data"))
write.table(tidy_data,"tidy_data.txt")
