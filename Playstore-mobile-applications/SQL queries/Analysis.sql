/* Explore the split of the number of applications by different factors. */
--By category
SELECT category_name, COUNT(*) as num_application, ROUND(COUNT(*)/9660::numeric, 3) as proportion_of_total
FROM application as app
INNER JOIN category as cat
ON app.category_id = cat.id
GROUP BY 1
ORDER BY 2 DESC; 

-- By pricing type
SELECT price_type, COUNT(*) as num_application, ROUND(COUNT(*)/9660::numeric, 3) as proportion_of_total
FROM application
GROUP BY 1
ORDER BY 2 DESC;


/* Which application has the highest rating and number of reviews? The applications will be grouped by different factors, to determine the performance of each application. */
-- By category
SELECT category_name, SUM(num_reviews) as total_num_reviews, ROUND(AVG(rating),3) AS average_rating, ROUND(SUM(rating*num_reviews)/SUM(num_reviews),3) as weighted_avg_rating
FROM playstore as ps
INNER JOIN application as app
ON ps.app_id = app.id
INNER JOIN category as c
ON app.category_id = c.id
GROUP BY 1
ORDER BY 4 DESC
LIMIT 3;

-- By pricing type
SELECT price_type, SUM(num_reviews) as total_num_reviews, ROUND(AVG(ps.rating),3) AS average_rating, ROUND(SUM(ps.rating*num_reviews)/SUM(num_reviews),3) as weighted_avg_rating
FROM playstore as ps
INNER JOIN application as app
ON ps.app_id = app.id
GROUP BY 1;

-- Key insight: Check how the top 3 categories by weighted average rating compare in the number of applications available
WITH foo AS (
SELECT category_name, COUNT(*) as num_application, ROUND(COUNT(*)/9660::numeric, 3) as proportion_of_total, ROW_NUMBER() OVER (ORDER BY ROUND(COUNT(*)/9660::numeric, 3) DESC) as rank_out_of_33
FROM application as app
INNER JOIN category as cat
ON app.category_id = cat.id
GROUP BY 1)
SELECT * FROM foo
WHERE category_name IN ('Medical', 'Parenting', 'Health_And_Fitness')


/* Which applications have the most downloads? */
-- Check the proportion of apps that have downloads above 1 million
--By category
WITH downloads AS (
	SELECT category_name, COUNT(*) as total_count
	FROM playstore as ps
	INNER JOIN application as app
	ON ps.app_id = app.id
	INNER JOIN category as c
	ON app.category_id = c.id
	WHERE downloads IN ('1,000,000+','5,000,000+','10,000,000+', '50,000,000+','100,000,000+', '500,000,000+','1,000,000,000+')
	GROUP BY 1 ),
total AS (
	SELECT category_name, COUNT(*) as num_application
	FROM application as app
	INNER JOIN category as cat
	ON app.category_id = cat.id
	GROUP BY 1
)
SELECT downloads.category_name, total_count, ROUND(total_count/num_application::numeric,3) as proportion
FROM downloads
INNER JOIN total 
ON downloads.category_name = total.category_name
ORDER BY 3 DESC;

--What were the number of downloads for the top 3 categories based on ratings 
WITH downloads AS (
	SELECT category_name, COUNT(*) as total_count
	FROM playstore as ps
	INNER JOIN application as app
	ON ps.app_id = app.id
	INNER JOIN category as c
	ON app.category_id = c.id
	WHERE downloads IN ('1,000,000+','5,000,000+','10,000,000+', '50,000,000+','100,000,000+', '500,000,000+','1,000,000,000+')
	GROUP BY 1 ),
total AS (
	SELECT category_name, COUNT(*) as num_application
	FROM application as app
	INNER JOIN category as cat
	ON app.category_id = cat.id
	GROUP BY 1
)
SELECT downloads.category_name, total_count, ROUND(total_count/num_application::numeric,3) as proportion
FROM downloads
INNER JOIN total 
ON downloads.category_name = total.category_name
WHERE downloads.category_name IN ('Medical', 'Parenting', 'Health_And_Fitness');


--By pricing type
WITH downloads AS (
	SELECT price_type, COUNT(*) as total_count
	FROM playstore as ps
	INNER JOIN application as app
	ON ps.app_id = app.id
	WHERE downloads IN ('1,000,000+','5,000,000+','10,000,000+', '50,000,000+','100,000,000+', '500,000,000+','1,000,000,000+')
	GROUP BY 1),
total AS (
	SELECT price_type, COUNT(*) as num_application
	FROM application 
	GROUP BY 1
)
SELECT downloads.price_type, total_count, ROUND(total_count/num_application::numeric,3) as proportion
FROM downloads
INNER JOIN total 
ON downloads.price_type = total.price_type
ORDER BY 3 DESC;


/* Sentiments based on reviews */
-- Polarity by category
SELECT category_name, ROUND(SUM(sentiment_polarity)/COUNT(*),3) as avg_polarity
FROM reviews
INNER JOIN application as app
ON reviews.app_id = app.id
INNER JOIN category as c
ON app.category_id = c.id
GROUP BY category_name
ORDER BY 2 DESC;

-- Polarity for the 3 categories: Medical', 'Parenting', 'Health_And_Fitness
SELECT category_name, ROUND(SUM(sentiment_polarity)/COUNT(*),3) as avg_polarity
FROM reviews
INNER JOIN application as app
ON reviews.app_id = app.id
INNER JOIN category as c
ON app.category_id = c.id
WHERE category_name IN ('Medical', 'Parenting', 'Health_And_Fitness')
GROUP BY category_name
ORDER BY 2 DESC;

-- Count of positive, negative, neutral sentiment by category
SELECT category_name, sentiment, COUNT(*) as num_reviews
FROM reviews
INNER JOIN application as app
ON reviews.app_id = app.id
INNER JOIN category as c
ON app.category_id = c.id
WHERE sentiment IS NOT NULL
GROUP BY 1,2
ORDER BY 1 DESC;

-- export the query above to CSV file format
CREATE TABLE sentiment AS (
	SELECT category_name, sentiment, COUNT(*) as num_reviews
	FROM reviews
	INNER JOIN application as app
	ON reviews.app_id = app.id
	INNER JOIN category as c
	ON app.category_id = c.id
	WHERE sentiment IS NOT NULL
	GROUP BY 1,2
	ORDER BY 1 DESC
);

COPY sentiment TO 'sentiment.csv'
DELIMITER ',' CSV HEADER;