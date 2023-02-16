SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

--Standardize date format: 

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM DataCleaningProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


--Populate property address data
SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningProject.dbo.NashvilleHousing a
JOIN DataCleaningProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningProject.dbo.NashvilleHousing a
JOIN DataCleaningProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL 


--Breaking out address into individual columns (Address, City, State) 
SELECT PropertyAddress
FROM DataCleaningProject.dbo.NashvilleHousing

--Using substrings for the property addresses: 
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM DataCleaningProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing 
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 

--Using PARSENAME for owner addresses: 
SELECT OwnerAddress
FROM DataCleaningProject.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM DataCleaningProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE NashvilleHousing 
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--Change Y and N to Yes and No in "Sold as Vacant" field 
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM DataCleaningProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM DataCleaningProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

--Remove duplicates 

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM DataCleaningProject.dbo.NashvilleHousing
)
--DELETE
--FROM RowNumCTE 
--WHERE row_num > 1 
SELECT * 
FROM RowNumCTE 

--Delete unused columns

SELECT *
FROM DataCleaningProject.dbo.NashvilleHousing

ALTER TABLE DataCleaningProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--Cleaning up column names 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN'; 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.PropertySplitCity', 'PropertyCity', 'COLUMN'; 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.PropertySplitAddress', 'PropertyAddress', 'COLUMN'; 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.OwnerSplitAddress', 'OwnerAddress', 'COLUMN'; 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.OwnerSplitCity', 'OwnerCity', 'COLUMN'; 
sp_rename 'DataCleaningProject.dbo.NashvilleHousing.OwnerSplitState', 'OwnerState', 'COLUMN'; 