/* 

CLEANING DATA IN SQL

*/

SELECT * 
FROM dbo.NashvilleHousing

------------------------------------------------------------------------------------------

-- 1. Standardize Date Format (Sale Date)

SELECT SaleDate
FROM dbo.NashvilleHousing

--We want to remove the time at the end
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM dbo.NashvilleHousing

UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)
WHERE UniqueID IS NOT NULL

SELECT * 
FROM dbo.NashvilleHousing

-- The query above works for me and it changed the dataset
-- but alternatively I could have done the query below,
-- which would have added a new column SaleDateConverted.

ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted Date;

Update dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted
FROM dbo.NashvilleHousing




------------------------------------------------------------------------------------------

-- 2. Populate Property Address data

-- Some Property Adresses are null however they can be filled 
-- Check if every ParcelID has a corresponding Property Address

SELECT ParcelID, PropertyAddress
FROM dbo.NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

-- We are going to do a sort of index match / vlookup 
-- If the Parcel ID and Unique ID corresponds to a Property Address then replace the null with the Address by joining them
-- To ensure we don't mess the data up we also join using the Unique ID because this value is distinct for each entry

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- the query above will show you the Nulls
-- and the query below will show you the value to fill them with based on matching the PropertyAddress to parcelID (new column)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Now let's update our data

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL




------------------------------------------------------------------------------------------

--  3. Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM dbo.NashvilleHousing
--WHERE PropertyAddress is null
--ORDER BY ParcelID

-- CHARINDEX counts the values regardless of the type on the column we specify 
-- We specify that we want to see all the values in the column up to a certain point, the comma
SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM dbo.NashvilleHousing

-- Then we specify we want to see values less the comma (-1)
SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM dbo.NashvilleHousing

-- For the part after the comma we now specify that we want the values after the comma
SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as AddressEnd
FROM dbo.NashvilleHousing

-- Now let's update the table

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

Update dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

Update dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM dbo.NashvilleHousing

-- Seperating with parsename

SELECT OwnerAddress
FROM dbo.NashvilleHousing

-- Parsename looks for dots/periods so we replace , with .

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)





------------------------------------------------------------------------------------------

-- 4. Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Change Y to Yes, N to No

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
 FROM dbo.NashvilleHousing

 -- Update Table

 UPDATE dbo.NashvilleHousing
 SET SoldAsVacant = 
 CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END




------------------------------------------------------------------------------------------
-- 5. Remove Duplicates (Using CTE) N/b: In a workplace setting consult before you do this

-- Let's find the duplicates, where the row number is > 1 is a duplicate

SELECT *,
ROW_NUMBER() OVER(
		     PARTITION BY ParcelID, 
			              PropertyAddress,
						  SalePrice,
				          SaleDate,
				          LegalReference
				          ORDER BY UniqueID) 
						  row_num

FROM dbo.NashvilleHousing
ORDER BY ParcelID

-- Let's put the duplicates in a CTE

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER(
		     PARTITION BY ParcelID, 
			              PropertyAddress,
						  SalePrice,
				          SaleDate,
				          LegalReference
				          ORDER BY UniqueID) 
						  row_num

FROM dbo.NashvilleHousing )

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete the values in the CTE

WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER(
		     PARTITION BY ParcelID, 
			              PropertyAddress,
						  SalePrice,
				          SaleDate,
				          LegalReference
				          ORDER BY UniqueID) 
						  row_num

FROM dbo.NashvilleHousing )

DELETE 
FROM RowNumCTE
WHERE row_num > 1

-- we've gone from 56477 rows to 56373 rows, consult before you do this


------------------------------------------------------------------------------------------
-- 6. Delete Unused columns. N/b: In a workplace setting consult before you do this
-- I'm removing the columns we split - recall the addresses and sale dates

SELECT * 
FROM dbo.NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate
