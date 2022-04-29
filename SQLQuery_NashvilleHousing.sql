/*

Nashville Housing Data Cleaning

Skills used: Joins, CTE's, Alter/Update Tables, Substring, Parsename, Case Statements, Window Functions

*/

Select*
From [Portfolio Project 2]..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CAST(SaleDate AS DATE)


--------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data due to NULL data. JOINED tables based on correlating ParcelID, however, UniqueID is different

Select *
From [Portfolio Project 2]..NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From [Portfolio Project 2]..NashvilleHousing a
JOIN [Portfolio Project 2]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From [Portfolio Project 2]..NashvilleHousing a
JOIN [Portfolio Project 2]..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------------

-- Breaking out PropertyAddress into individual columns (Address, City)

Select PropertyAddress
From [Portfolio Project 2]..NashvilleHousing

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From [Portfolio Project 2]..NashvilleHousing

-- Create 2 new columns to be able to add new split values in

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update [Portfolio Project 2]..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update [Portfolio Project 2]..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

Select *
From [Portfolio Project 2]..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------------

-- Breaking out OwnerAddress into individual columns (Address, City, State) with use of PARSENAME

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM [Portfolio Project 2]..NashvilleHousing


ALTER TABLE [Portfolio Project 2]..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update [Portfolio Project 2]..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update [Portfolio Project 2]..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update [Portfolio Project 2]..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [Portfolio Project 2]..NashvilleHousing
Group by SoldAsVacant
Order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM [Portfolio Project 2]..NashvilleHousing


Update [Portfolio Project 2]..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END


--------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM [Portfolio Project 2]..NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1


-- Delete Unused Columns

Select *
FROM [Portfolio Project 2]..NashvilleHousing

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE [Portfolio Project 2]..NashvilleHousing
DROP COLUMN SaleDate

