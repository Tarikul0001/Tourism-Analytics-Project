-- =====================================================================================
-- QUERY 4: Market Concentration Risk Assessment
-- =====================================================================================
-- Calculate Herfindahl-Hirschman Index (HHI) for each country's monthly arrival 
-- distribution to identify over-dependence on specific periods.
-- 
-- Business Value: Helps identify markets vulnerable to seasonal shocks and 
-- guides diversification strategies.
-- =====================================================================================

WITH MonthlyShares AS (
  SELECT Country, Year, Month, Arrivals,
         SUM(Arrivals) OVER (PARTITION BY Country, Year) AS YearlyTotal,
         (Arrivals * 1.0 / NULLIF(SUM(Arrivals) OVER (PARTITION BY Country, Year), 0)) * 100 AS MonthlyShare
  FROM Tourism_Arrivals
),
HHI AS (
  SELECT Country, Year,
         SUM(POWER(MonthlyShare, 2)) AS HHI_Score
  FROM MonthlyShares
  GROUP BY Country, Year
),
HHIStats AS (
  SELECT Country,
         AVG(HHI_Score) AS AvgHHI,
         STDEV(HHI_Score) AS HHI_Volatility,
         COUNT(*) AS YearsAnalyzed
  FROM HHI
  GROUP BY Country
)
SELECT Country, AvgHHI, HHI_Volatility, YearsAnalyzed,
       CASE 
         WHEN AvgHHI < 1000 THEN 'Low Concentration'
         WHEN AvgHHI < 1800 THEN 'Moderate Concentration'
         ELSE 'High Concentration'
       END AS ConcentrationRisk,
       NTILE(5) OVER (ORDER BY AvgHHI DESC) AS RiskQuintile
FROM HHIStats
ORDER BY AvgHHI DESC; 