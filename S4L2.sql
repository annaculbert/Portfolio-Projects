/*
Skills 4 Life Pediatric Occupational Therapy Data Exploration & Analysis

Data exploration of data gathered from the pediatric outpatient clinic named Skills 4 Life to identify trends in patient demographics 
and patient visits for improved marketing strategy. Data includes patient information from October 2020 - May 2022.

Skills used: Joins, CTE's, Case Statements, Unions, Converting Data Types, Temp Tables, Data Cleaning, Aggregate Functions, Alter tables

*/

SELECT *
FROM [S4L Analytics]..Demographics

SELECT *
FROM [S4L Analytics]..Encounters2021

SELECT *
FROM [S4L Analytics]..Encounters2022

--------------------------------------------------------------------------------------------------------------------------------

-- Clean data to change genders labeled 'Unknown' to correct label based on therapist-patient information. 
-- Convert various columns from ncarchar(255) to DATE

UPDATE [S4L Analytics]..Demographics
SET Gender = 'Male'
WHERE Gender = 'Unknown'

UPDATE [S4L Analytics]..Demographics
SET DateOfJoining = CONVERT(NVARCHAR(255),CONVERT(DATE, DateOfJoining, 105))
ALTER TABLE [S4L Analytics]..Demographics
ALTER COLUMN DateOfJoining DATE

UPDATE [S4L Analytics]..Encounters2021
SET Month = CONVERT(NVARCHAR(255), CONVERT(DATE, Month, 105))
ALTER TABLE [S4L Analytics]..Encounters2021
ALTER COLUMN Month DATE

UPDATE [S4L Analytics]..Encounters2022
SET Month = CONVERT(NVARCHAR(255), CONVERT(DATE, Month, 105))
ALTER TABLE [S4L Analytics]..Encounters2021
ALTER COLUMN Month DATE


--------------------------------------------------------------------------------------------------------------------------------

-- Create column with patient age using date of birth

ALTER TABLE Demographics 
ADD Age AS DATEDIFF(YEAR, DOB, GETDATE())

--------------------------------------------------------------------------------------------------------------------------------

-- Determine number of patients that fall under various categories to identify commonalities in demographics

SELECT Age, COUNT(Age) AS TotalCount,
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..Demographics
GROUP BY Age

SELECT Gender, AVG(Age) AS AvgAge
FROM [S4L Analytics]..Demographics
GROUP BY Gender

SELECT City, COUNT(City) AS CountCity
FROM [S4L Analytics]..Demographics
WHERE City IS NOT NULL
GROUP BY City
ORDER BY CountCity DESC

--------------------------------------------------------------------------------------------------------------------------------

/* Calculate the number of new patients who joined each month to determine busier vs. slower times for families to establish 
services for their child.  October 2020 was excluded from calculation as many patients were entered into new EHR system that 
month, even though they were already established patients.
*/

ALTER TABLE [S4L Analytics]..Demographics
ADD JoinYear AS YEAR(DateOfJoining)

ALTER TABLE [S4L Analytics]..Demographics
ADD JoinMonth AS MONTH(DateOfJoining)

WITH TotalJoined2020 AS (
	SELECT JoinMonth, COUNT(*) AS TotalJoined2020
	FROM [S4L Analytics]..Demographics
	WHERE JoinYear = 2020 AND DateOfJoining NOT LIKE '2020-10%'
	GROUP BY JoinMonth),
	TotalJoined2021 AS (
	SELECT JoinMonth, COUNT(*) AS TotalJoined2021
	FROM [S4L Analytics]..Demographics
	WHERE JoinYear = 2021
	GROUP BY JoinMonth),
	TotalJoined2022 AS (
	SELECT JoinMonth, COUNT(*) AS TotalJoined2022
	FROM [S4L Analytics]..Demographics
	WHERE JoinYear = 2022
	GROUP BY JoinMonth)
SELECT b.JoinMonth, a.TotalJoined2020, b.TotalJoined2021, c.TotalJoined2022
FROM TotalJoined2020 a
FULL OUTER JOIN TotalJoined2021 b
ON (a.JoinMonth = b.JoinMonth)
FULL OUTER JOIN TotalJoined2022 c
ON (b.JoinMonth = c.JoinMonth)
ORDER BY a.JoinMonth

SELECT JoinYear, JoinMonth, COUNT(*) AS TotalJoined
FROM [S4L Analytics]..Demographics
WHERE DateOfJoining NOT LIKE '2020-10%'
GROUP BY JoinYear, JoinMonth
ORDER BY TotalJoined DESC

--------------------------------------------------------------------------------------------------------------------------------

-- Identifying growth pattern of business from January 2021 - June 2022 based on patient encounters

SELECT *
FROM [S4L Analytics]..Encounters2022
WHERE [Encounter Count] > 1
UNION
SELECT *
FROM [S4L Analytics]..Encounters2021
ORDER BY Month

--------------------------------------------------------------------------------------------------------------------------------

-- Adding column to label patients per their diagnosis

ALTER TABLE [S4L Analytics]..ADHDComb_Patients$
ADD Diagnosis_1 AS 'ADHD_Comb'

ALTER TABLE [S4L Analytics]..AttConcDef_Patients$
ADD Diagnosis_2 AS 'AttConcDef'

ALTER TABLE [S4L Analytics]..Dis#OfWrittenExp_Patients$
ADD Diagnosis_3 AS 'DisOfWrittenExp'

ALTER TABLE [S4L Analytics]..FrontalLobe_Patients$
ADD Diagnosis_4 AS 'FrontalLobeDef'

ALTER TABLE [S4L Analytics]..OtherLackCoord_Patients$
ADD Diagnosis_5 AS 'OtherLackCoord'

--------------------------------------------------------------------------------------------------------------------------------

-- Creating a temp table to explore demographics based on diagnoses

DROP TABLE IF EXISTS #temp_UNION
SELECT *
	INTO #temp_UNION
FROM
(
SELECT Diagnosis_1 AS Diagnoses, COUNT(*) AS Count, ROUND(AVG(Age), 0) AS Avg_Age,
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..ADHDComb_Patients$
GROUP BY Diagnosis_1
UNION
SELECT Diagnosis_2, COUNT(*), ROUND(AVG(Age), 0),
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..AttConcDef_Patients$
GROUP BY Diagnosis_2
UNION
SELECT Diagnosis_3, COUNT(*), ROUND(AVG(Age), 0),
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..Dis#OfWrittenExp_Patients$
GROUP BY Diagnosis_3
UNION
SELECT Diagnosis_4, COUNT(*), ROUND(AVG(Age), 0),
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..FrontalLobe_Patients$
GROUP BY Diagnosis_4
UNION
SELECT Diagnosis_5, COUNT(*), ROUND(AVG(Age), 0),
SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount
FROM [S4L Analytics]..OtherLackCoord_Patients$
GROUP BY Diagnosis_5
) a

SELECT *
FROM #temp_UNION
ORDER BY Count DESC

--------------------------------------------------------------------------------------------------------------------------------

-- Identifying referral source types to better develop marketing strategies

DROP TABLE IF EXISTS #temp_UNION_Source
SELECT *
	INTO #temp_UNION_Source
FROM
(
SELECT Source, COUNT(*) AS Count
FROM [S4L Analytics]..ADHDComb_Patients$
GROUP BY Source
UNION
SELECT Source, COUNT(*)
FROM [S4L Analytics]..AttConcDef_Patients$
GROUP BY Source
UNION
SELECT Source, COUNT(*)
FROM [S4L Analytics]..Dis#OfWrittenExp_Patients$
GROUP BY Source
UNION
SELECT Source, COUNT(*)
FROM [S4L Analytics]..FrontalLobe_Patients$
GROUP BY Source
UNION
SELECT Source, COUNT(*)
FROM [S4L Analytics]..OtherLackCoord_Patients$
GROUP BY Source
) a

SELECT Source, SUM(Count) AS Source_Count
FROM #temp_UNION_Source
WHERE Source is NOT NULL
GROUP BY Source
ORDER BY Source_Count DESC

/*
See Tableau dashboard for summaries and recommendations.
*/
