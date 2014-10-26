---
title: "README"
output: html_document
---
##Getting and Cleaning Data course project

Victor Bulnes Peñalver

victorbulnes.webs.com

***
"tidy\_dataset.txt" is the product of processing the raw data provided for this assignment. Such raw data was collected from the "Human Activity Using Smartphones Dataset", created through a series of experiments carried out with a group of 30 voluteers (subjects) performing six different acivities (WALKING, WALKING\_UPSTAIRS, WALKING\_DOWNSTAIRS, SITTING, STANDING, LAYING) while wearing a smarthphone on the waist, and using its sensors to capture the data.

This data process is embded within the R script *"run_analysis.R"*, which contains a series of instructions for manipulating and transforming raw data, in order to get a tidy data set of the means and standard deviations of all the measurements within it, ordered by activity and subject. For a step by step detailed guide on how that process is conducted, as well as getting a list of output variables and their descriptions, please refer to the *"CodeBook.md"* file on this repository.

To know more about the raw data please visit the following link:

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

***

**List of Raw data files required for the analysis:**

Raw data can be downloaded here:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

The source data set is divided in two subgroups, *test* and *train*, each one corresponding to a different set of subjects, and stored in different folders. here there is a list of files included in the data set that are needed to complete this assignment:

- 'README.txt' : Extended information about the source data set.

- 'features_info.txt': Shows information about the variables used on the feature vector.

- 'features.txt': List of all features.

- 'activity_labels.txt': Links the class labels with their activity name.

- 'train/X_train.txt': Training set.

- 'train/y_train.txt': Training labels.

- 'train/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30.

- 'test/X_test.txt': Test set.

- 'test/y_test.txt': Test labels.

- 'test/subject_test.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30.

***

**Project's output files:**

- README.md : Description of the project content and objectives.

- CodeBook.md : Step by step detailed explanation of the data cleaning process and its final output (list of variables and their descriptions)

- run_analysis.R : R script that takes raw data as an input and generates a tidy data set as an output.

- tidy_data.txt : Final tidy data set stored iin a text file, with the means an standard deviations of each measurement present in raw data, ordered by activity and subject.

