# Netflix SQL Projects

![NetFlix logo](https://github.com/Deepak-Byte/SQL_Projects/blob/main/Netflix_logo.jpeg)

# Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

# Objectives
* Analyze the distribution of content types (movies vs TV shows).
* Identify the most common ratings for movies and TV shows.
* List and analyze content based on release years, countries, and durations.
* Explore and categorize content based on specific criteria and keywords.

# Dataset
Available in same repository

# Schema

```sql
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
);
```

# Business Problems and Solutions
### 1.Count the Number of Movies vs TV Shows
```sql
select type, count(*) as Total_number from netflix_titles group by type;
```

### 2.Find most common rating for Movie and TV show
```sql
select type, rating, count(*) as Total_count from netflix_titles group by 1,2  order by Total_count desc limit 2;
```

### 3.List all movie which is realeased in specific year
```sql
select * from netflix_titles where type = 'Movie' and release_year = 2020;
```

### 4.Find the top 5 country with the most content on netflix
```sql
select country, count(*) from netflix_titles group by country order by count(*) desc;
```

### 5.Identified longest movie
```sql
select * from netflix_titles where type='Movie' and duration=(select max(duration) from netflix_titles);
```

### 6.Find the content added in last 5 year 
```sql
select * from netflix_titles 
where YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) >= (select year(now()) - 5 year);
```

### 7.Find all movie/tv series made by director name='Rajiv'
```sql
select * from netflix_titles where director like '%Rajiv Menon%';
```

### 8.List all series with more than 5 season 
```sql
select * from netflix_titles where type='TV Show' and substring(duration, 1,2);
```

### 9.Number of cotent items in each genera
```sql
WITH RECURSIVE genre_split AS (
    SELECT show_id, 
           SUBSTRING_INDEX(listed_in, ',', 1) AS genre, 
           TRIM(BOTH ',' FROM SUBSTRING(listed_in, LOCATE(',', listed_in))) AS remaining
    FROM netflix_titles WHERE listed_in IS NOT NULL  
    UNION ALL
    SELECT show_id, 
           SUBSTRING_INDEX(remaining, ',', 1), 
           TRIM(BOTH ',' FROM SUBSTRING(remaining, LOCATE(',', remaining)))
    FROM genre_split WHERE remaining != '')
SELECT *
FROM genre_split;
```

### 10.Find each year and the averag number of content released by india on netflix
```sql
extract(year from str_to_date(date_added, '%M %d, %Y')) as years,
count(*),
count(*)/(select count(*) from netflix_titles where country = 'India') as average_no
from netflix_titles where country = 'India' group by years;	
```

### 11.List all movies are documentories
```sql
select * from netflix_titles where listed_in like '%documentaries%';
```

### 12.Find all data director column is null
```sql
select count(*) from netflix_titles where director like '';
```

### 13.Find number of movi done by 'Salman Khan' in last 10 year
```sql
select title, release_year, cast from netflix_titles 
where type='Movie' and 
release_year > (select extract(year from curdate())- 10 year) and
cast like 'Salman Khan';
```

### 14.Find top 10 actors name who appeard highly in indian movie
```sql
with recursive cye as(
select show_id, type, country,
substring_index(cast, ',', 1) as cast_name,
trim(both ',' from substring(cast, locate(',', cast))) as remaining
from netflix_titles
where cast is not null
union all
select show_id, type, country,
substring_index(remaining, ',', 1),
trim(both ',' from substring(remaining, locate(',', remaining))) 
from cye 
where remaining!=''
)
select cast_name, count(*) from cye 
where type='Movie' and cast_name is not null and country like 'India' group by cast_name order by count(*) desc limit 10; 
```
### 15.Categorize content based on presence of the keyword 'kill' and 'violance' in dscrepation field. Label this catwggory as 'Bad' and rest as 'Good' count of each category
```sql
with cte as(
SELECT title,
       CASE WHEN description LIKE '%Kill%' OR description LIKE '%Vilance%' THEN 'Bad' ELSE 'Good' END AS Category
FROM netflix_titles
)
select Category, count(*) as Total from cte group by Category;
```







