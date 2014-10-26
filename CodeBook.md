---
title: "CodeBook"
output: html_document
---

This is a code book document that describes the variables, the data, and any transformations or work performed to clean up the data provided for this project on the Coursera project section of Getting and Cleaning data course (getdata-008). This document follows the guidelines provided there, dividing the process, and hence the code, in five steps until reaching the totality of the script requested (*run_analysis.R*):

Some additional libraries need to be loaded in order to run *"run_analysis.R"* script:

    library(sqldf)

**1. Merge the training and the test sets to create one data set:**

First of all the relevant data need to be read and stored as data frames on R environment. Assuming the zip file have been already downloaded and decompressed on the working directory, the files that need to be read are "*X\_test.txt*" and "*X\_train.txt*" both containing the measurements taken for all subjects while performing the activities studied.   


    x_test <- read.table("UCI HAR Dataset/test/X_test.txt")
    x_train <- read.table("UCI HAR Dataset/train/X_train.txt")


Merging the data frames by rows (*X\_train* at the bottom of *X\_test*) using *rbind()*.

    x_all <- rbind(x_test,x_train)

Now the two data frames are merged into one. However columns names are missing. THe names are stored on a separate file named "*features.txt*", one variable name per line. Lets store in a variable only the variable names to use them as names for our data frame:

    features <- read.table("UCI HAR Dataset/features.txt")[,2]
    names(x_all) <- features

**2. Extract only the measurements on the mean and standard deviation for each measurement.**

Here we are requested to take only the mean and standard deviation of all the measurement taken from the sensors. According to *"features_info.txt"* instructions, sensor signal variable names are as follows:

- tBodyAcc-XYZ*
- tGravityAcc-XYZ*
- tBodyAccJerk-XYZ*
- tBodyGyro-XYZ*
- tBodyGyroJerk-XYZ*
- tBodyAccMag*
- tGravityAccMag*
- tBodyAccJerkMag*
- tBodyGyroMag*
- tBodyGyroJerkMag*
- fBodyAcc-XYZ*
- fBodyAccJerk-XYZ*
- fBodyGyro-XYZ*
- fBodyAccMag*
- fBodyAccJerkMag*
- fBodyGyroMag*
- fBodyGyroJerkMag*

*-XYZ' is used to denote 3-axial signals in the X, Y and Z directions*

Mean and standard deviation were calculated for all 33 previous variables (containing "*mean()*"" and "*std()*" on their variable names). That makes a total of 66 measurements. So we are seeking for a data frame containing 66 columns. We can use this as a reference to check if the output is correct.

Now is time to extract the variables requested creating a regex rule for finding patterns on variable names corresponding to those containing "*mean()*" and "*std()*" on their names.

    mean_std_cols <- grep("*.mean\\(\\)|std\\(\\).*",names(x_all))
    x_all_mean_std <- x_all[,mean_std_cols]

As expected the new data frame has 66 columns.

**3. Use descriptive activity names to name the activities in the data set**

Again, the data frame is missing information about what activity corresponds to each observation or row. According to the information provided on "*README.txt*" there are six activities performed by the subjects, codified from 1 to 6 as specified on "*activity_labels.txt*":

1. WALKING
2. WALKING\_UPSTAIRS
3. WALKING\_DOWNSTAIRS
4. SITTING
5. STANDING
6. LAYING

Unfortunately those labels are in another file that we have to read to add it to our data frame as the first column under the name "*activity*":

    act_test <- read.table("UCI HAR Dataset/test/y_test.txt")
    act_train <- read.table("UCI HAR Dataset/train/y_train.txt")
    act_all <- rbind(act_test,act_train)
    names(act_all) <- "activity"
    all_activities <- cbind(act_all,x_all_mean_std)

Now in order to replace activity number with descriptive labels we turn "activity" column class into a factor, and then we turn factor levels into new labels according to the classification in *"activity_labels.txt"*.

    all_activities$activity <- as.factor(all_activities$activity)
    act_lbl <- read.table("UCI HAR Dataset/activity_labels.txt",col.names=c("factor","name"))
    levels(all_activities$activity) <- act_lbl$name

**4. Appropriately label the data set with descriptive variable names.**

Using the names provided in *"features.txt"* as variable names, as we already did, seems coherent and descriptive. However it is convenient to remove especial characters like "-" and "()" which could create problems later on subsetting the data using some functions like *sqldf()*. 

    names(all_activities) <- gsub("-","_",names(all_activities))
    names(all_activities) <- gsub("\\(|\\)","",names(all_activities))

Now variable names look something like *"tBodyAcc_mean_X"*.

**5. From the data set in step 4, create a second, independent tidy data set with the average of each variable for each activity and each subject.**

Again *"subject"* ids are located in independent files named *"subject_test.txt"* and *"subject_train.txt"*, with each line corresponding to the *"subject"* from which the set of measurement in that same position were taken. So once again we have to read, merge and then add it to our data frame as a new column named *"subject"*:

    test_sbj <- read.table("UCI HAR Dataset/test/subject_test.txt")
    train_sbj <- read.table("UCI HAR Dataset/train/subject_train.txt")
    subject <- rbind(test_sbj,train_sbj)
    names(subject) <- 'subject'
    all_activities <- cbind(subject,all_activities)

Now the final step is to create an independent new data set with the average of each variable grouped by activity and subject. By this we understand that each subject will have an average of each variable per kind of activity, hence, having 30 subjects in total and 6 kind of activities we should get 30x6 rows in the new data set.

In our current data set we have 68 columns. The two firsts are *"subject"* and *"activity"*, which will be used for summarizing, and need no average calculation. Thus we can start extracting those two columns into a new data frame grouped by activity and then subject (notice that here we are using *"sqldf()"* to be able to select using SQL language): 

    tidy_data <- sqldf("select activity,subject from all_activities group by activity, subject")

At this point we only need to add the rest of the variables to the new *"tidy_data"* data frame. We can achieve this using a for loop iterating the rest of the columns (3-68), grouping by activity and subject, summarizing by average, and finally merging it with the new data frame:

    for(name in names(all_activities[,3:ncol(all_activities)])) {
        tidy_data <- cbind(tidy_data,fn$sqldf("select avg($name) as $name_avg from all_activities group by activity,subject"))
    }

Notice that in the process we have changed the name of the variables adding *"_avg"* at the end of each one, to indicate that it is an average of the mean/standar deviation of the measurements of each subject.

Finally we have our final data set *"tidy_data"* ready, so we can clean the the rest of the objects and write it into a txt file :

    rm(list=subset(ls(),ls()!="tidy_data"))
    write.table(tidy_data,"tidy_data.txt")

***

The following code creates a *"variables_desc.txt"* file in the working directory, with a list of *tidy_data* variables names and descritions.

    write('\n\t"tidy_data" DATA FRAME VARIABLES DESCRIPTION.\n\n\n',file="variables_desc.txt")
    for (var in names(tidy_data)) {
        if (var == "activity") {
            write(paste("",var,":\n"),"variables_desc.txt",append=TRUE);
            for (activity in sqldf("select distinct(activity) from tidy_data")) {
                write(paste("\n\t",activity,":\n\n\t\t Subject performing activity",activity),"variables_desc.txt",append=TRUE) 
            }
        } 
        
        else if (var == "subject") {
            write(paste("\n",var,":\n"),"variables_desc.txt",append=TRUE);
            for (subject in sqldf("select distinct(subject) from tidy_data")) {
                write(paste("\t",subject,":\t Subject number",subject),"variables_desc.txt",append=TRUE) 
            }
        } else {
            pre <- gsub("_","-",var);
            pre <- gsub("-avg","",pre);
            if (length(grep("*.mean.*",pre))==1) {
                pre <- gsub("mean","mean()",pre)
            } else {
                pre <- gsub("std","std()",pre)
            }
            grep("*.mean.*",pre);
            write(paste("\n",var,":\n\n\tSubject's average value of the variable",pre,'. See description in "features_info.txt".'),"variables_desc.txt",append=TRUE)
        }
    }
    
**"tidy_data" DATA FRAME VARIABLES DESCRIPTION.**



 activity : 


     LAYING :

		 Subject performing activity LAYING

	 SITTING :

		 Subject performing activity SITTING

	 STANDING :

		 Subject performing activity STANDING

	 WALKING :

		 Subject performing activity WALKING

	 WALKING_DOWNSTAIRS :

		 Subject performing activity WALKING_DOWNSTAIRS

	 WALKING_UPSTAIRS :

		 Subject performing activity WALKING_UPSTAIRS

 subject : 

	 1 :	 Subject number 1
	 2 :	 Subject number 2
	 3 :	 Subject number 3
	 4 :	 Subject number 4
	 5 :	 Subject number 5
	 6 :	 Subject number 6
	 7 :	 Subject number 7
	 8 :	 Subject number 8
	 9 :	 Subject number 9
	 10 :	 Subject number 10
	 11 :	 Subject number 11
	 12 :	 Subject number 12
	 13 :	 Subject number 13
	 14 :	 Subject number 14
	 15 :	 Subject number 15
	 16 :	 Subject number 16
	 17 :	 Subject number 17
	 18 :	 Subject number 18
	 19 :	 Subject number 19
	 20 :	 Subject number 20
	 21 :	 Subject number 21
	 22 :	 Subject number 22
	 23 :	 Subject number 23
	 24 :	 Subject number 24
	 25 :	 Subject number 25
	 26 :	 Subject number 26
	 27 :	 Subject number 27
	 28 :	 Subject number 28
	 29 :	 Subject number 29
	 30 :	 Subject number 30

 tBodyAcc_mean_X_avg : 

	Subject's average value of the variable tBodyAcc-mean()-X . See description in "features_info.txt".

 tBodyAcc_mean_Y_avg : 

	Subject's average value of the variable tBodyAcc-mean()-Y . See description in "features_info.txt".

 tBodyAcc_mean_Z_avg : 

	Subject's average value of the variable tBodyAcc-mean()-Z . See description in "features_info.txt".

 tBodyAcc_std_X_avg : 

	Subject's average value of the variable tBodyAcc-std()-X . See description in "features_info.txt".

 tBodyAcc_std_Y_avg : 

	Subject's average value of the variable tBodyAcc-std()-Y . See description in "features_info.txt".

 tBodyAcc_std_Z_avg : 

	Subject's average value of the variable tBodyAcc-std()-Z . See description in "features_info.txt".

 tGravityAcc_mean_X_avg : 

	Subject's average value of the variable tGravityAcc-mean()-X . See description in "features_info.txt".

 tGravityAcc_mean_Y_avg : 

	Subject's average value of the variable tGravityAcc-mean()-Y . See description in "features_info.txt".

 tGravityAcc_mean_Z_avg : 

	Subject's average value of the variable tGravityAcc-mean()-Z . See description in "features_info.txt".

 tGravityAcc_std_X_avg : 

	Subject's average value of the variable tGravityAcc-std()-X . See description in "features_info.txt".

 tGravityAcc_std_Y_avg : 

	Subject's average value of the variable tGravityAcc-std()-Y . See description in "features_info.txt".

 tGravityAcc_std_Z_avg : 

	Subject's average value of the variable tGravityAcc-std()-Z . See description in "features_info.txt".

 tBodyAccJerk_mean_X_avg : 

	Subject's average value of the variable tBodyAccJerk-mean()-X . See description in "features_info.txt".

 tBodyAccJerk_mean_Y_avg : 

	Subject's average value of the variable tBodyAccJerk-mean()-Y . See description in "features_info.txt".

 tBodyAccJerk_mean_Z_avg : 

	Subject's average value of the variable tBodyAccJerk-mean()-Z . See description in "features_info.txt".

 tBodyAccJerk_std_X_avg : 

	Subject's average value of the variable tBodyAccJerk-std()-X . See description in "features_info.txt".

 tBodyAccJerk_std_Y_avg : 

	Subject's average value of the variable tBodyAccJerk-std()-Y . See description in "features_info.txt".

 tBodyAccJerk_std_Z_avg : 

	Subject's average value of the variable tBodyAccJerk-std()-Z . See description in "features_info.txt".

 tBodyGyro_mean_X_avg : 

	Subject's average value of the variable tBodyGyro-mean()-X . See description in "features_info.txt".

 tBodyGyro_mean_Y_avg : 

	Subject's average value of the variable tBodyGyro-mean()-Y . See description in "features_info.txt".

 tBodyGyro_mean_Z_avg : 

	Subject's average value of the variable tBodyGyro-mean()-Z . See description in "features_info.txt".

 tBodyGyro_std_X_avg : 

	Subject's average value of the variable tBodyGyro-std()-X . See description in "features_info.txt".

 tBodyGyro_std_Y_avg : 

	Subject's average value of the variable tBodyGyro-std()-Y . See description in "features_info.txt".

 tBodyGyro_std_Z_avg : 

	Subject's average value of the variable tBodyGyro-std()-Z . See description in "features_info.txt".

 tBodyGyroJerk_mean_X_avg : 

	Subject's average value of the variable tBodyGyroJerk-mean()-X . See description in "features_info.txt".

 tBodyGyroJerk_mean_Y_avg : 

	Subject's average value of the variable tBodyGyroJerk-mean()-Y . See description in "features_info.txt".

 tBodyGyroJerk_mean_Z_avg : 

	Subject's average value of the variable tBodyGyroJerk-mean()-Z . See description in "features_info.txt".

 tBodyGyroJerk_std_X_avg : 

	Subject's average value of the variable tBodyGyroJerk-std()-X . See description in "features_info.txt".

 tBodyGyroJerk_std_Y_avg : 

	Subject's average value of the variable tBodyGyroJerk-std()-Y . See description in "features_info.txt".

 tBodyGyroJerk_std_Z_avg : 

	Subject's average value of the variable tBodyGyroJerk-std()-Z . See description in "features_info.txt".

 tBodyAccMag_mean_avg : 

	Subject's average value of the variable tBodyAccMag-mean() . See description in "features_info.txt".

 tBodyAccMag_std_avg : 

	Subject's average value of the variable tBodyAccMag-std() . See description in "features_info.txt".

 tGravityAccMag_mean_avg : 

	Subject's average value of the variable tGravityAccMag-mean() . See description in "features_info.txt".

 tGravityAccMag_std_avg : 

	Subject's average value of the variable tGravityAccMag-std() . See description in "features_info.txt".

 tBodyAccJerkMag_mean_avg : 

	Subject's average value of the variable tBodyAccJerkMag-mean() . See description in "features_info.txt".

 tBodyAccJerkMag_std_avg : 

	Subject's average value of the variable tBodyAccJerkMag-std() . See description in "features_info.txt".

 tBodyGyroMag_mean_avg : 

	Subject's average value of the variable tBodyGyroMag-mean() . See description in "features_info.txt".

 tBodyGyroMag_std_avg : 

	Subject's average value of the variable tBodyGyroMag-std() . See description in "features_info.txt".

 tBodyGyroJerkMag_mean_avg : 

	Subject's average value of the variable tBodyGyroJerkMag-mean() . See description in "features_info.txt".

 tBodyGyroJerkMag_std_avg : 

	Subject's average value of the variable tBodyGyroJerkMag-std() . See description in "features_info.txt".

 fBodyAcc_mean_X_avg : 

	Subject's average value of the variable fBodyAcc-mean()-X . See description in "features_info.txt".

 fBodyAcc_mean_Y_avg : 

	Subject's average value of the variable fBodyAcc-mean()-Y . See description in "features_info.txt".

 fBodyAcc_mean_Z_avg : 

	Subject's average value of the variable fBodyAcc-mean()-Z . See description in "features_info.txt".

 fBodyAcc_std_X_avg : 

	Subject's average value of the variable fBodyAcc-std()-X . See description in "features_info.txt".

 fBodyAcc_std_Y_avg : 

	Subject's average value of the variable fBodyAcc-std()-Y . See description in "features_info.txt".

 fBodyAcc_std_Z_avg : 

	Subject's average value of the variable fBodyAcc-std()-Z . See description in "features_info.txt".

 fBodyAccJerk_mean_X_avg : 

	Subject's average value of the variable fBodyAccJerk-mean()-X . See description in "features_info.txt".

 fBodyAccJerk_mean_Y_avg : 

	Subject's average value of the variable fBodyAccJerk-mean()-Y . See description in "features_info.txt".

 fBodyAccJerk_mean_Z_avg : 

	Subject's average value of the variable fBodyAccJerk-mean()-Z . See description in "features_info.txt".

 fBodyAccJerk_std_X_avg : 

	Subject's average value of the variable fBodyAccJerk-std()-X . See description in "features_info.txt".

 fBodyAccJerk_std_Y_avg : 

	Subject's average value of the variable fBodyAccJerk-std()-Y . See description in "features_info.txt".

 fBodyAccJerk_std_Z_avg : 

	Subject's average value of the variable fBodyAccJerk-std()-Z . See description in "features_info.txt".

 fBodyGyro_mean_X_avg : 

	Subject's average value of the variable fBodyGyro-mean()-X . See description in "features_info.txt".

 fBodyGyro_mean_Y_avg : 

	Subject's average value of the variable fBodyGyro-mean()-Y . See description in "features_info.txt".

 fBodyGyro_mean_Z_avg : 

	Subject's average value of the variable fBodyGyro-mean()-Z . See description in "features_info.txt".

 fBodyGyro_std_X_avg : 

	Subject's average value of the variable fBodyGyro-std()-X . See description in "features_info.txt".

 fBodyGyro_std_Y_avg : 

	Subject's average value of the variable fBodyGyro-std()-Y . See description in "features_info.txt".

 fBodyGyro_std_Z_avg : 

	Subject's average value of the variable fBodyGyro-std()-Z . See description in "features_info.txt".

 fBodyAccMag_mean_avg : 

	Subject's average value of the variable fBodyAccMag-mean() . See description in "features_info.txt".

 fBodyAccMag_std_avg : 

	Subject's average value of the variable fBodyAccMag-std() . See description in "features_info.txt".

 fBodyBodyAccJerkMag_mean_avg : 

	Subject's average value of the variable fBodyBodyAccJerkMag-mean() . See description in "features_info.txt".

 fBodyBodyAccJerkMag_std_avg : 

	Subject's average value of the variable fBodyBodyAccJerkMag-std() . See description in "features_info.txt".

 fBodyBodyGyroMag_mean_avg : 

	Subject's average value of the variable fBodyBodyGyroMag-mean() . See description in "features_info.txt".

 fBodyBodyGyroMag_std_avg : 

	Subject's average value of the variable fBodyBodyGyroMag-std() . See description in "features_info.txt".

 fBodyBodyGyroJerkMag_mean_avg : 

	Subject's average value of the variable fBodyBodyGyroJerkMag-mean() . See description in "features_info.txt".

 fBodyBodyGyroJerkMag_std_avg : 

	Subject's average value of the variable fBodyBodyGyroJerkMag-std() . See description in "features_info.txt".
