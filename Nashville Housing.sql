CREATE DATABASE IF NOT EXISTS Nashville_Housing;
CREATE TABLE IF NOT EXISTS Nashville_housing
(UniqueID INT NOT NULL PRIMARY KEY,
ParcelID VARCHAR(30),
LandUse	VARCHAR(50),
PropertyAddress	VARCHAR(100),
SaleDate VARCHAR(20),
SalePrice INT,
LegalReference VARCHAR(50),
SoldAsVacant VARCHAR(10),
OwnerName VARCHAR(100),
OwnerAddress VARCHAR(100),
Acreage	FLOAT,
TaxDistrict	VARCHAR(50),
LandValue INT,
BuildingValue INT,
TotalValue INT,
YearBuilt YEAR,
Bedrooms INT,
FullBath INT,
HalfBath INT);

SELECT * FROM nashville_housing;
SET SQL_SAFE_UPDATES = 0;
----------------------------------------------
------------ Step 1: Data Cleaning------------
-- # Some columns are not relevant and need to be dropped
--- Columns to drop (ParcelID, LegalReference, and OwnerName)--
ALTER TABLE nashville_housing
DROP COLUMN ParcelID,
DROP COLUMN LegalReference,
DROP COLUMN OwnerName;


------ Find duplicates --
SELECT UniqueID, COUNT(*)
FROM nashville_housing
GROUP BY UniqueID
HAVING COUNT(*) > 1;

----- The data seems to have no duplicates --- 

-- CREATE NEW COLUMNS - --------------
ALTER TABLE nashville_housing
ADD COLUMN SaleDay VARCHAR(5),
ADD COLUMN SaleMonth VARCHAR (10),
ADD COLUMN SaleYear VARCHAR (10);

---- Once we have created the new columns, we fill them with data from the Sale_Date variable----
--- Sale day
UPDATE nashville_housing
SET SaleDay = SUBSTRING_INDEX(SaleDate, '-', 1);

-- Sale Month
UPDATE nashville_housing
SET SaleMonth = SUBSTRING_INDEX(SUBSTRING_INDEX(SaleDate, '-', 2), '-', -1);

-- Sale year
UPDATE nashville_housing
SET SaleYear = RIGHT(SaleDate, 2);

--- Change to relevant data types
ALTER TABLE nashville_housing MODIFY COLUMN SaleDay INT;
ALTER TABLE nashville_housing MODIFY COLUMN SaleYEAR YEAR; 

------- CREATE NEW COLUMNS - --------------
ALTER TABLE nashville_housing
ADD COLUMN PropertyCity VARCHAR(30),
ADD COLUMN OwnerCity VARCHAR (60),
ADD COLUMN OwnerState VARCHAR (60);

--- update the three new columns
-- Property City
UPDATE nashville_housing
SET PropertyCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

--- Owner City
UPDATE nashville_housing
SET OwnerCity = SUBSTRING_INDEX(OwnerAddress, ',', -1);

---- Owner State
UPDATE nashville_housing
SET OwnerState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

------ Add a new column (Acreage_range)----
ALTER TABLE nashville_housing
MODIFY COLUMN Acreage_Range VARCHAR(20);

--- Upate the Acreage_Range column
UPDATE nashville_housing
SET Acreage_Range = 
	CASE WHEN Acreage <= 0.5 THEN '0-0.5'
       WHEN Acreage <= 1.0 THEN '0.6-1.0'
       WHEN Acreage <= 1.5 THEN '1.0-1.5'
       WHEN Acreage <= 2.0 THEN '1.5-2.0'
       WHEN Acreage <= 2.5 THEN '2.0-2.5'
       WHEN Acreage <= 3.0 THEN '2.5-3.0'
       WHEN Acreage <= 4.0 THEN '3.0-4.0'
       WHEN Acreage <= 5.0 THEN '4.0-5.0'
       WHEN Acreage <= 10 THEN '5.0 - 10.0'
       ELSE 'Above 10'
  END;
  
  --- Upate the SoldAsVacant column to change Y to Yes, and N to No
  
UPDATE nashville_housing
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'No' THEN 'No'
       WHEN SoldAsVacant = 'N' THEN 'No'
       WHEN SoldAsVacant = 'Y' THEN 'Yes'
       ELSE 'Yes'
  END;

-- CREATE NEW COLUMN Sales_margin to check the difference between the TotalValue and the SalePrice- --------------
ALTER TABLE nashville_housing
ADD COLUMN SaleMargin INT;

-- Update the new column
UPDATE nashville_housing
SET SaleMargin = SalePrice-TotalValue;
                        


SELECT* FROM nashville_housing;

------------------------------------------------------------------
--------- Data Analysis ------------------------------------------
--- 1: What are the number of houses for sale by Acreage Range?

SELECT Acreage_Range, COUNT(*) AS Number_of_Houses FROM nashville_housing
GROUP BY Acreage_Range
ORDER BY Number_of_Houses DESC; 

--- 2: What are the number of houses for sale by city?

SELECT PropertyCity, COUNT(*) AS Number_of_Houses FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''
GROUP BY PropertyCity
ORDER BY Number_of_Houses DESC; 

--- 3: What are the average prices per city?

SELECT PropertyCity, ROUND(AVG(SalePrice), 2) AS Average_Price
FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''  -- Exclude null and empty string values
GROUP BY PropertyCity
ORDER BY Average_Price DESC;

--- 4: What are the total acreage by city? 

SELECT PropertyCity, ROUND(SUM(Acreage), 2) AS Total_Acreage
FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''  -- Exclude null and empty string values
GROUP BY PropertyCity
ORDER BY Total_Acreage DESC;

--- 5: What is the land and building value by city? 

SELECT PropertyCity, ROUND(AVG(LandValue), 2) AS Avg_Land_Value
FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''  
GROUP BY PropertyCity
ORDER BY Avg_Land_Value DESC;

--- 6: What is the building value by city? 

SELECT PropertyCity, ROUND(AVG(BuildingValue), 2) AS Avg_Building_Value
FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''  
GROUP BY PropertyCity
ORDER BY Avg_Building_Value DESC;

--- 7: What is the sale price by land use? 

SELECT LandUse, ROUND(AVG(SalePrice), 2) AS Avg_Sale_Price
FROM nashville_housing  
GROUP BY LandUse
ORDER BY Avg_Sale_Price DESC;

--- 8: What is the sale price by number of bedrooms?

SELECT DISTINCT Bedrooms, ROUND(AVG(SalePrice), 2) AS Avg_Sale_Price
FROM nashville_housing 
WHERE Bedrooms <> 0 
GROUP BY Bedrooms
ORDER BY Avg_Sale_Price DESC;

--- 9: What is the sale price by number of FullBaths?

SELECT DISTINCT FullBath, ROUND(AVG(SalePrice), 2) AS Avg_Sale_Price
FROM nashville_housing
WHERE FullBath <> 0   
GROUP BY FullBath
ORDER BY Avg_Sale_Price DESC;

--- 10: What is the sale price by number of HalfBaths?

SELECT DISTINCT HalfBath, ROUND(AVG(SalePrice), 2) AS Avg_Sale_Price
FROM nashville_housing
WHERE HalfBath <> 0   
GROUP BY HalfBath
ORDER BY Avg_Sale_Price DESC;


--- 11: What is the sale price by based on whether the house was vacant or not?

SELECT DISTINCT SoldAsVacant, ROUND(AVG(SalePrice), 2) AS Avg_Sale_Price
FROM nashville_housing
GROUP BY SoldAsVacant;

--- 12: What is the sales margin/value based on the different cities? 

SELECT PropertyCity, ROUND(AVG(SaleMargin), 2) AS AVG_Sales_Margin
FROM nashville_housing
WHERE PropertyCity IS NOT NULL AND PropertyCity <> ''  
GROUP BY PropertyCity
ORDER BY AVG_Sales_Margin DESC;

--- 13: Which months record the most sales? 

SELECT SaleMonth, COUNT(SaleMonth) AS Number_of_Sales
FROM nashville_housing  
GROUP BY SaleMonth
ORDER BY Number_of_Sales DESC;


