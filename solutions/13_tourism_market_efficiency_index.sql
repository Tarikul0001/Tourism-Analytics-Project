-- =====================================================================================
-- QUERY 13: Tourism Market Efficiency Index
-- =====================================================================================
-- Compare actual arrival patterns against optimal patterns to identify markets 
-- with efficiency gaps and optimization opportunities.
-- 
-- Business Value: Identifies operational optimization opportunities and 
-- capacity utilization improvements.
-- =====================================================================================

WITH OptimalPatterns AS (
  SELECT Country, Year,
         AVG(Arrivals) AS AvgArrivals,
         -- Optimal pattern: Even distribution across months
         SUM(Arrivals) / 12.0 AS OptimalMonthlyArrivals,
         -- Actual vs Optimal variance
         SUM(POWER(Arrivals - (SUM(Arrivals) OVER (PARTITION BY Country, Year) / 12.0), 2)) AS VarianceFromOptimal
  FROM Tourism_Arrivals
  GROUP BY Country, Year
),
EfficiencyMetrics AS (
  SELECT Country,
         AVG(AvgArrivals) AS OverallAvgArrivals,
         AVG(OptimalMonthlyArrivals) AS OverallOptimal,
         AVG(VarianceFromOptimal) AS OverallVariance,
         -- Efficiency index: Lower variance = higher efficiency
         1.0 / NULLIF(AVG(VarianceFromOptimal), 0) AS EfficiencyIndex
  FROM OptimalPatterns
  GROUP BY Country
)
SELECT Country, OverallAvgArrivals, OverallOptimal, OverallVariance, EfficiencyIndex,
       NTILE(5) OVER (ORDER BY EfficiencyIndex DESC) AS EfficiencyQuintile
FROM EfficiencyMetrics
ORDER BY EfficiencyIndex DESC; 