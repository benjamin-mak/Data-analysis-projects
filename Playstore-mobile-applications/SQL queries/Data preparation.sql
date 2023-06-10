/*Data preparation and cleaning*/

--Create database 
CREATE DATABASE playstore_apps
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


/* 1. Create 'application' table */
CREATE TABLE application AS
SELECT * FROM google_play_apps;

--Remove duplicate values from "App"
ALTER TABLE application
ADD COLUMN id SERIAL PRIMARY KEY;

DELETE FROM application AS a
USING application as b
WHERE a.id < b.id AND a."App" = b."App";

ALTER TABLE application
DROP COLUMN id;

-- add PK column 
ALTER TABLE application
ADD COLUMN id SERIAL PRIMARY KEY;

-- 'Genre' column is not is 1st normal form, split the values to one value per column, and then drop the 'Genres column'
ALTER TABLE application
ADD COLUMN genre1 text,
ADD COLUMN genre2 text;

WITH foo AS(
SELECT SPLIT_PART("Genres" ,';',1), SPLIT_PART("Genres" ,';',2) AS split_part2, id
FROM application
)
UPDATE application
SET genre1 = split_part,
genre2 = split_part2
FROM foo
WHERE foo.id = application.id;

ALTER TABLE application 
DROP COLUMN "Genres";

--Rename columns
ALTER TABLE application
RENAME COLUMN "App" TO app_name;
ALTER TABLE application
RENAME COLUMN "Size" TO app_size;
ALTER TABLE application
RENAME COLUMN "Type" TO price_type;
ALTER TABLE application
RENAME COLUMN "Price" TO price;
ALTER TABLE application
RENAME COLUMN "Category" TO category;
ALTER TABLE application
RENAME COLUMN "Rating" TO rating;
ALTER TABLE application
RENAME COLUMN "Reviews" TO num_reviews;
ALTER TABLE application
RENAME COLUMN "Installs" TO downloads;
ALTER TABLE application
RENAME COLUMN "Last Updated" TO last_updated;
ALTER TABLE application
RENAME COLUMN "Current Ver" TO current_ver;
ALTER TABLE application
RENAME COLUMN "Android Ver" TO android_ver;

/* 2. Create 'content_rating' table */
-- Change blank to 'No rating'
UPDATE application
SET "Content Rating" = 'No rating'
WHERE "Content Rating" = '';

CREATE TABLE content_rating AS
SELECT DISTINCT "Content Rating" as rating FROM application;

-- Add PK column
ALTER TABLE content_rating
ADD COLUMN id SERIAL PRIMARY KEY;

-- Add foreign key "content_rating" to application table
ALTER TABLE application
ADD COLUMN content_rating int;

UPDATE application
SET content_rating = content_rating.id
FROM content_rating
WHERE application."Content Rating" = content_rating.rating;

ALTER TABLE application
DROP COLUMN "Content Rating";

ALTER TABLE application
ADD CONSTRAINT FK_content_rating
FOREIGN KEY (content_rating) REFERENCES content_rating(id);

-- One entry had mixed up details and had to be cleaned
UPDATE application
SET category = NULL,
rating = '1.9',
num_reviews = '19',
app_size = '3',
downloads = '1,000+',
price_type = 'Free',
price = '0',
last_updated = 'February 11,2018',
current_ver = '1.0.19',
android_ver = '4.0 and up',
genre1 = NULL,
content_rating = 5
WHERE app_name = 'Life Made WI-Fi Touchscreen Photo Frame';


/* 3. Create 'category' table */
--Proper case category column
WITH foo AS (
	SELECT INITCAP(category),id FROM application
)
UPDATE application
SET category = initcap
FROM foo
WHERE application.id = foo.id;

--Create 'category' table
CREATE TABLE category AS
SELECT DISTINCT category as category_name FROM application
WHERE category IS NOT NULL;

-- Add primary key
ALTER TABLE category
ADD COLUMN id SERIAL PRIMARY KEY;

-- Add foreign key column to 'application' table
ALTER TABLE application
ADD COLUMN category_id int;

UPDATE application
SET category_id = category.id
FROM category
WHERE application.category = category.category_name;

ALTER TABLE application
DROP COLUMN category;

ALTER TABLE application
ADD CONSTRAINT FK_category_id
FOREIGN KEY (category_id) REFERENCES category(id);

/* 4. Create 'genre' table */
-- replace blank values with null in 'genre2' column
UPDATE application
SET genre2 = NULL
WHERE genre2 = '';

-- Create 'genre' table
CREATE TABLE genre AS
SELECT DISTINCT genre1 as genre_name 
FROM application
WHERE genre1 IS NOT NULL
UNION 
SELECT DISTINCT genre2
FROM application 
WHERE genre2 IS NOT NULL;

-- Add PK to genre table
ALTER TABLE genre
ADD COLUMN id SERIAL PRIMARY KEY;

-- Add foreign key to columns 'genre1_id' and 'genre2_id'
ALTER TABLE application
ADD COLUMN genre1_id int,
ADD COLUMN genre2_id int;

UPDATE application
SET genre1_id = genre.id
FROM genre
WHERE application.genre1 = genre.genre_name;

UPDATE application
SET genre2_id = genre.id
FROM genre
WHERE application.genre2 = genre.genre_name;

ALTER TABLE application
ADD CONSTRAINT FK_genre1_id
FOREIGN KEY (genre1_id) REFERENCES genre(id),
ADD CONSTRAINT FK_genre2_id
FOREIGN KEY (genre2_id) REFERENCES genre(id);

ALTER TABLE application
DROP COLUMN genre1, 
DROP COLUMN genre2;

/* 5. Create playstore table */
CREATE TABLE playstore AS
SELECT id AS app_id, rating, num_reviews, downloads
FROM application;

-- Add primary key
ALTER TABLE playstore 
ADD PRIMARY KEY (app_id); 

-- Add foreign key constraint on 'app_id'
ALTER TABLE playstore
ADD CONSTRAINT FK_app_id
FOREIGN KEY (app_id) REFERENCES application(id);

ALTER TABLE application
DROP COLUMN rating,
DROP COLUMN num_reviews,
DROP COLUMN downloads;

/* 6. Edit reviews table */
--Add primary key column
ALTER TABLE reviews
ADD COLUMN id SERIAL PRIMARY KEY;

--ALTER TABLE reviews
--RENAME COLUMN "App" TO app_id;
ALTER TABLE reviews
RENAME COLUMN "App" TO app_name;
ALTER TABLE reviews
RENAME COLUMN "Translated_Review" TO review;
ALTER TABLE reviews
RENAME COLUMN "Sentiment" TO sentiment;
ALTER TABLE reviews
RENAME COLUMN "Sentiment_Polarity" TO sentiment_polarity;
ALTER TABLE reviews
RENAME COLUMN "Sentiment_Subjectivity" TO sentiment_subjectivity;

-- Create foreign key
ALTER TABLE reviews
ADD COLUMN app_id INT;

UPDATE reviews
SET app_id = application.id
FROM application
WHERE reviews.app_name = application.app_name;

ALTER TABLE reviews
ADD CONSTRAINT FK_app_id
FOREIGN KEY (app_id) REFERENCES application(id);

/*Update errors in app names 
--Query not finished
UPDATE reviews
SET app_id = 1017
WHERE app_name = 'Birdays – Birthday reminder';
UPDATE reviews
SET app_id = 1189
WHERE app_name = 'DELISH KITCHEN - 無料レシピ動画で料理を楽しく・簡単に！'; */


/* Add other constraints to tables and transform data to fit constraints */

-- application table
-- Update all valuse for price_type column to be either free/paid
UPDATE application
SET price_type = 'Free'
WHERE price_type ='NaN';

--Remove $ from price column
UPDATE application
SET price = replace(price, '$', '');

--Change date format for last_updated column
UPDATE application
SET last_updated = TO_DATE(last_updated, 'Month DD, YYYY');

-- Add constraints to columns: Change app_size column to numeric; change price column to numeric; change last_updated column to date type; Add not null constraint
ALTER TABLE application
ALTER COLUMN app_name SET NOT NULL,
ALTER COLUMN app_size TYPE NUMERIC USING app_size::numeric,
ALTER COLUMN app_size SET NOT NULL,
ALTER COLUMN price_type SET NOT NULL,
ALTER COLUMN price TYPE NUMERIC USING price::numeric,
ADD CHECK (price >= 0),
ALTER COLUMN last_updated TYPE DATE USING last_updated::date;

--content_rating table
-- Add not null contraint
ALTER TABLE content_rating
ALTER COLUMN rating SET NOT NULL;

-- category table
-- Add not null contraint
ALTER TABLE category
ALTER COLUMN category_name SET NOT NULL;

-- genre table
-- Add not null contraint
ALTER TABLE genre
ALTER COLUMN genre_name SET NOT NULL;

-- playstore table
-- Convert NaN to null values for rating column
UPDATE playstore 
SET rating = NULL
WHERE rating = 'NaN';

-- Update downloads column, change value of 0+ to 1+
UPDATE playstore
SET downloads = '1+'
WHERE downloads = '0+';

-- Add constraints to columns: change rating column to numeric, change num_reviews column to integer
ALTER TABLE playstore
ALTER COLUMN rating TYPE numeric USING rating::numeric,
ADD CHECK (rating >= 0 AND rating <= 5),
ALTER COLUMN num_reviews TYPE int USING num_reviews::int,
ADD CHECK (num_reviews >= 0);

-- reviews table
-- Convert nan values to null values
UPDATE reviews
SET review = Null,
sentiment = NULL,
sentiment_polarity = NULL,
sentiment_subjectivity = NULL
WHERE review = 'nan';

-- Add contraints to columns: change sentiment_polarity and sentiment_subjectivity columns to numeric type
ALTER TABLE reviews
ALTER COLUMN sentiment_polarity TYPE numeric USING sentiment_polarity::numeric,
ALTER COLUMN sentiment_subjectivity TYPE numeric USING sentiment_subjectivity::numeric,
ADD CHECK (sentiment_polarity >= -1 AND sentiment_polarity <= 1),
ADD CHECK (sentiment_subjectivity >= 0 AND sentiment_subjectivity <= 1);
