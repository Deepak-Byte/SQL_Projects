show databases;
create database netflix_db;
use netflix_db;
show tables;
create table netflix (show_id varchar(5), type varchar(10), title varchar(150), director varchar(210), cast varchar(1000),
country varchar(150), date_added varchar(50), release_year int(10), rating varchar(10), duration varchar(15),
listed_in varchar(25), description varchar(250));

select count(*) from netflix_titles;

select distinct type from netflix_titles;

-- 1.Count the number of movie vs TV show
select type, count(*) as Total_number from netflix_titles group by type;

-- 2.Find most common rating for Movie and TV show
select type, rating, count(*) as Total_count from netflix_titles group by 1,2  order by Total_count desc limit 2;

-- 3.List all movie which is realeased in specific year
select * from netflix_titles where type = 'Movie' and release_year = 2020;

-- 4.Find the top 5 country with the most content on netflix
select country, count(*) from netflix_titles group by country order by count(*) desc;

-- 5.Identified longest movie
select * from netflix_titles where type='Movie' and duration=(select max(duration) from netflix_titles);

-- 6.Find the content added in last 5 year  (Incomplete)
select * from netflix_titles 
where to_date(date_added,'Month DD, YYYY') >= year(now()) - interval 5 year;

-- 7.Find all movie/tv series made by director name='Rajiv'
select * from netflix_titles where director like '%Rajiv Menon%';

-- 8.List all series with more than 5 season 
select * from netflix_titles where type='TV Show' and substring(duration, 1,2);

-- 9.Number of cotent items in each genera
-- select type, listed_in, corss_apply string_split(listed_in, ',') as separated from netflix_titles; -- For Sqlserver only
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

-- 10.Find each year and the averag number of content released by india on netflix
select 
extract(year from str_to_date(date_added, '%M %d, %Y')) as years,
count(*),
count(*)/(select count(*) from netflix_titles where country = 'India') as average_no
from netflix_titles where country = 'India' group by years;	

-- 11.List all movies are documentories
select * from netflix_titles where listed_in like '%documentaries%';

-- 12.Find all data director column is null
select count(*) from netflix_titles where director like '';

-- 13.Find number of movi done by 'Salman Khan' in last 10 year
select title, release_year, cast from netflix_titles 
where type='Movie' and 
release_year > (select extract(year from curdate())- 10 year) and cast like 'Salman Khan';

-- 14.Find top 10 actors name who appeard highly in indian movie
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

-- 15.Categorize content based on presence of the keyword 'kill' and 'violance' in dscrepation field. 
-- Label this catwggory as 'Bad' and rest as 'Good' count of each category
with cte as(
SELECT title,
       CASE WHEN description LIKE '%Kill%' OR description LIKE '%Vilance%' THEN 'Bad' ELSE 'Good' END AS Category
FROM netflix_titles
)
select Category, count(*) as Total from cte group by Category;
