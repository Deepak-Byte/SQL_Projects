# Netflix SQL Projects

![NetFlix logo](https://github.com/Deepak-Byte/SQL_Projects/blob/main/Netflix_logo.jpeg)

# Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

# Objectives
-> Analyze the distribution of content types (movies vs TV shows).
-> Identify the most common ratings for movies and TV shows.
-> List and analyze content based on release years, countries, and durations.
-> Explore and categorize content based on specific criteria and keywords.

# Dataset
Available in same repository

# Schema
'''sql
DROP TABLE IF EXISTS netflix_titles;
CREATE TABLE netflix_titles
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
)'''

# Business Problems and Solutions
### 1.Count the Number of Movies vs TV Shows
'''sql
select type, count(*) as Total_number from netflix_titles group by type'''

### 2.Find most common rating for Movie and TV show
'''sql
select type, rating, count(*) as Total_count from netflix_titles group by 1,2  order by Total_count desc limit 2'''









