
-- Enhanced Tourism Dataset Compatibility Script
-- This script creates the Tourism_Arrivals table with the enhanced dataset

-- For SQL Server, use this format:
/*
CREATE TABLE Tourism_Arrivals (
    Country NVARCHAR(100),
    Country_Code NVARCHAR(10),
    Region NVARCHAR(50),
    Year INT,
    Month INT,
    Arrivals BIGINT,
    Arrivals_Growth_Rate DECIMAL(5,1),
    Arrivals_Per_Capita DECIMAL(10,6),
    Source_Market_Diversity DECIMAL(3,2),
    Peak_Season_Arrivals BIGINT,
    Off_Season_Arrivals BIGINT,
    Population BIGINT,
    GDP_Per_Capita INT,
    Tourism_Maturity NVARCHAR(20)
);

-- Then use BULK INSERT or import the CSV file
*/

-- For PostgreSQL, use this format:
/*
CREATE TABLE Tourism_Arrivals (
    Country VARCHAR(100),
    Country_Code VARCHAR(10),
    Region VARCHAR(50),
    Year INTEGER,
    Month INTEGER,
    Arrivals BIGINT,
    Arrivals_Growth_Rate DECIMAL(5,1),
    Arrivals_Per_Capita DECIMAL(10,6),
    Source_Market_Diversity DECIMAL(3,2),
    Peak_Season_Arrivals BIGINT,
    Off_Season_Arrivals BIGINT,
    Population BIGINT,
    GDP_Per_Capita INTEGER,
    Tourism_Maturity VARCHAR(20)
);

-- Then use COPY command or import the CSV file
*/

-- For SQLite, the table is created automatically when importing the CSV
-- All existing SQL solutions should work without modification
