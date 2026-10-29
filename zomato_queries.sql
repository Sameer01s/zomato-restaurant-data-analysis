CREATE DATABASE IF NOT EXISTS zomato_db;
USE zomato_db;

DROP TABLE IF EXISTS zomato;

CREATE TABLE zomato (
RestaurantID INT,
RestaurantName VARCHAR(255),
CountryCode INT,
Country VARCHAR(100),
City VARCHAR(100),
Address TEXT,
Locality VARCHAR(255),
LocalityVerbose TEXT,
Longitude DOUBLE,
Latitude DOUBLE,
Cuisines VARCHAR(255),
Currency VARCHAR(100),
Has_Table_booking VARCHAR(10),
Has_Online_delivery VARCHAR(10),
Is_delivering_now VARCHAR(10),
Switch_to_order_menu VARCHAR(10),
Price_range INT,
Votes INT,
Average_Cost_for_two INT,
Rating DOUBLE,
Datekey_Opening VARCHAR(20),
Year INT,
Monthno INT,
Monthfullname VARCHAR(20),
Quarter VARCHAR(10),
YearMonth VARCHAR(20),
weekdayno INT,
Weekdayname VARCHAR(20),
FinancialMOnth VARCHAR(10),
FinancialQuarter VARCHAR(10)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomato project one.csv'
INTO TABLE zomato
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM zomato;

-- Build a country Map Table
CREATE TABLE country_master (
CountryCode INT PRIMARY KEY,
CountryName VARCHAR(100)
);
Select * from country_master;
SELECT 
    z.RestaurantID,
    z.RestaurantName,
    z.City,
    c.CountryName
FROM zomato z
LEFT JOIN country_master c ON z.CountryCode = c.CountryCode;
-- Q2 Build a Calendar Table using the Column Datekey
CREATE TABLE calendar_table AS
SELECT DISTINCT
    STR_TO_DATE(Datekey_Opening, '%d-%m-%Y') AS DateKey,

    YEAR(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Year,
    MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Monthno,
    MONTHNAME(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Monthfullname,
    CONCAT('Q', QUARTER(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y'))) AS Quarter,
    CONCAT(YEAR(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')), '-', LEFT(MONTHNAME(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')), 3)) AS YearMonth,
    DAYOFWEEK(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Weekdayno,
    DAYNAME(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Weekdayname,

    -- Financial Month: April=FM1 ... March=FM12
    CASE MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y'))
        WHEN 4 THEN 'FM1' WHEN 5 THEN 'FM2' WHEN 6 THEN 'FM3'
        WHEN 7 THEN 'FM4' WHEN 8 THEN 'FM5' WHEN 9 THEN 'FM6'
        WHEN 10 THEN 'FM7' WHEN 11 THEN 'FM8' WHEN 12 THEN 'FM9'
        WHEN 1 THEN 'FM10' WHEN 2 THEN 'FM11' WHEN 3 THEN 'FM12'
    END AS FinancialMonth,

    -- Financial Quarter
    CASE 
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (4,5,6) THEN 'FQ1'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (7,8,9) THEN 'FQ2'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (10,11,12) THEN 'FQ3'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (1,2,3) THEN 'FQ4'
    END AS FinancialQuarter

FROM zomato
WHERE Datekey_Opening IS NOT NULL AND Datekey_Opening != ''
ORDER BY DateKey;
SELECT * FROM calendar_table;

-- Q3 Find the Numbers of Restaurants based on City and Country.
SELECT 
    c.CountryName,
    z.City,
    COUNT(z.RestaurantID) AS No_of_Restaurants
FROM zomato z
LEFT JOIN country_master c ON z.CountryCode = c.CountryCode
GROUP BY c.CountryName, z.City
ORDER BY No_of_Restaurants DESC;

-- Q4 Numbers of Restaurants opening based on Year , Quarter , Month
SET SESSION sql_mode = '';
SELECT 
    YEAR(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Year,
    CASE 
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (4,5,6) THEN 'FQ1'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (7,8,9) THEN 'FQ2'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (10,11,12) THEN 'FQ3'
        WHEN MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) IN (1,2,3) THEN 'FQ4'
    END AS Financial_Quarter,
    MONTHNAME(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')) AS Month,
    COUNT(RestaurantID) AS No_of_Restaurants
FROM zomato
WHERE Datekey_Opening != '' AND Datekey_Opening IS NOT NULL
GROUP BY 
    YEAR(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')),
    Financial_Quarter,
    MONTHNAME(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')),
    MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y'))
ORDER BY 
    YEAR(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y')),
    MONTH(STR_TO_DATE(Datekey_Opening, '%d-%m-%Y'));
    
 -- Q5 Count of Restaurants based on Average Ratings   
    SELECT 
    CASE 
        WHEN Rating >= 4 THEN 'Excellent (4+)'
        WHEN Rating >= 3 THEN 'Good (3-4)'
        ELSE 'Average (<3)'
    END AS Rating_Category,
    COUNT(RestaurantID) AS No_of_Restaurants
FROM zomato
GROUP BY Rating_Category
ORDER BY No_of_Restaurants DESC;

-- Q6 Create buckets based on Average Price of reasonable size and find out how many restaurants falls in each buckets
SELECT 
    CASE 
        WHEN Average_Cost_for_two <= 300 THEN '0-300 Budget'
        WHEN Average_Cost_for_two <= 600 THEN '301-600 Affordable'
        WHEN Average_Cost_for_two <= 1000 THEN '601-1000 Mid-Range'
        WHEN Average_Cost_for_two <= 2000 THEN '1001-2000 Premium'
        ELSE '2000+ Luxury'
    END AS Price_Bucket,
    COUNT(RestaurantID) AS No_of_Restaurants
FROM zomato
WHERE Average_Cost_for_two IS NOT NULL
GROUP BY Price_Bucket
ORDER BY MIN(Average_Cost_for_two);

-- Q7Percentage of Restaurants based on "Has_Table_booking"
SELECT 
    Has_Table_booking,
    COUNT(*) AS No_of_Restaurants,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato), 2) AS Percentage
FROM zomato
GROUP BY Has_Table_booking;

-- Q8 Percentage of Restaurants based on "Has_Online_delivery"
SELECT 
    Has_Online_delivery AS Has_Online_Delivery,
    COUNT(*) AS No_of_Restaurants,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato), 2) AS Percentage
FROM zomato
WHERE Has_Online_delivery IS NOT NULL AND Has_Online_delivery != ''
GROUP BY Has_Online_delivery;



