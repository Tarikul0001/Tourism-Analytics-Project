-- =====================================================================================
-- QUERY 14: Tourism Economic Impact Multiplier
-- =====================================================================================
-- Estimate the economic impact of tourism by analyzing per capita arrivals, 
-- spending patterns, and economic multipliers.
-- 
-- Business Value: Quantifies tourism's economic contribution and supports 
-- policy development and investment decisions.
-- =====================================================================================

WITH EconomicImpact AS (
  SELECT Country, Year,
         SUM(Arrivals) AS TotalArrivals,
         AVG(Arrivals_per_Capita) AS AvgPerCapita,
         -- Economic multiplier proxy (based on arrival diversity and stability)
         AVG(Source_Market_Diversity) * (1.0 / NULLIF(STDEV(Arrivals), 0)) AS EconomicMultiplier
  FROM Tourism_Arrivals
  GROUP BY Country, Year
),
ImpactAnalysis AS (
  SELECT Country,
         AVG(TotalArrivals) AS AvgTotalArrivals,
         AVG(AvgPerCapita) AS OverallPerCapita,
         AVG(EconomicMultiplier) AS OverallMultiplier,
         -- Economic impact score
         AVG(TotalArrivals) * AVG(AvgPerCapita) * AVG(EconomicMultiplier) AS EconomicImpactScore
  FROM EconomicImpact
  GROUP BY Country
)
SELECT Country, AvgTotalArrivals, OverallPerCapita, OverallMultiplier, EconomicImpactScore,
       NTILE(5) OVER (ORDER BY EconomicImpactScore DESC) AS ImpactQuintile
FROM ImpactAnalysis
ORDER BY EconomicImpactScore DESC; 