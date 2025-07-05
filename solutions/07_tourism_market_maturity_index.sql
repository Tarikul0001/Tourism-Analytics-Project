-- =====================================================================================
-- QUERY 7: Tourism Market Maturity Index
-- =====================================================================================
-- Develop a composite index measuring market maturity based on arrival stability, 
-- diversity, growth sustainability, and seasonal balance.
-- 
-- Business Value: Guides market development strategies and identifies markets 
-- ready for different types of tourism investments.
-- =====================================================================================

WITH MarketIndicators AS (
  SELECT Country,
         -- Stability Index (inverse of coefficient of variation)
         1.0 / NULLIF(STDEV(Arrivals) / AVG(Arrivals), 0) AS StabilityIndex,
         -- Diversity Index (source market diversity)
         AVG(Source_Market_Diversity) AS DiversityIndex,
         -- Growth Sustainability (positive growth consistency)
         SUM(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS GrowthSustainability,
         -- Seasonal Balance (peak/off-peak ratio close to 1)
         1.0 / NULLIF(ABS(AVG(Peak_Season_Arrivals) / NULLIF(AVG(Off_Season_Arrivals), 0) - 1), 0) AS SeasonalBalance
  FROM Tourism_Arrivals
  GROUP BY Country
),
NormalizedIndicators AS (
  SELECT Country, StabilityIndex, DiversityIndex, GrowthSustainability, SeasonalBalance,
         (StabilityIndex - MIN(StabilityIndex) OVER ()) / NULLIF(MAX(StabilityIndex) OVER () - MIN(StabilityIndex) OVER (), 0) AS NormStability,
         (DiversityIndex - MIN(DiversityIndex) OVER ()) / NULLIF(MAX(DiversityIndex) OVER () - MIN(DiversityIndex) OVER (), 0) AS NormDiversity,
         (GrowthSustainability - MIN(GrowthSustainability) OVER ()) / NULLIF(MAX(GrowthSustainability) OVER () - MIN(GrowthSustainability) OVER (), 0) AS NormGrowth,
         (SeasonalBalance - MIN(SeasonalBalance) OVER ()) / NULLIF(MAX(SeasonalBalance) OVER () - MIN(SeasonalBalance) OVER (), 0) AS NormSeasonal
  FROM MarketIndicators
)
SELECT Country, StabilityIndex, DiversityIndex, GrowthSustainability, SeasonalBalance,
       (NormStability + NormDiversity + NormGrowth + NormSeasonal) / 4.0 AS MaturityIndex,
       NTILE(5) OVER (ORDER BY (NormStability + NormDiversity + NormGrowth + NormSeasonal) / 4.0 DESC) AS MaturityQuintile
FROM NormalizedIndicators
ORDER BY MaturityIndex DESC; 