-- =====================================================================================
-- QUERY 15: Tourism Strategic Value Assessment
-- =====================================================================================
-- Comprehensive market evaluation framework combining growth potential, stability, 
-- competitive position, and strategic fit for long-term investment decisions.
-- 
-- Business Value: Provides holistic market evaluation for strategic planning 
-- and long-term investment decisions.
-- =====================================================================================

WITH StrategicMetrics AS (
  SELECT Country,
         -- Growth Potential
         AVG(Arrivals_Growth_Rate) AS GrowthPotential,
         -- Market Stability
         1.0 / NULLIF(STDEV(Arrivals), 0) AS MarketStability,
         -- Competitive Position
         AVG(Source_Market_Diversity) AS CompetitivePosition,
         -- Strategic Fit (based on market size and maturity)
         AVG(Arrivals) * AVG(Arrivals_per_Capita) AS StrategicFit
  FROM Tourism_Arrivals
  GROUP BY Country
),
NormalizedMetrics AS (
  SELECT Country, GrowthPotential, MarketStability, CompetitivePosition, StrategicFit,
         (GrowthPotential - MIN(GrowthPotential) OVER ()) / NULLIF(MAX(GrowthPotential) OVER () - MIN(GrowthPotential) OVER (), 0) AS NormGrowth,
         (MarketStability - MIN(MarketStability) OVER ()) / NULLIF(MAX(MarketStability) OVER () - MIN(MarketStability) OVER (), 0) AS NormStability,
         (CompetitivePosition - MIN(CompetitivePosition) OVER ()) / NULLIF(MAX(CompetitivePosition) OVER () - MIN(CompetitivePosition) OVER (), 0) AS NormCompetitive,
         (StrategicFit - MIN(StrategicFit) OVER ()) / NULLIF(MAX(StrategicFit) OVER () - MIN(StrategicFit) OVER (), 0) AS NormStrategic
  FROM StrategicMetrics
),
StrategicValue AS (
  SELECT Country, GrowthPotential, MarketStability, CompetitivePosition, StrategicFit,
         (NormGrowth + NormStability + NormCompetitive + NormStrategic) / 4.0 AS StrategicValueScore
  FROM NormalizedMetrics
)
SELECT Country, GrowthPotential, MarketStability, CompetitivePosition, StrategicFit, StrategicValueScore,
       NTILE(5) OVER (ORDER BY StrategicValueScore DESC) AS StrategicQuintile
FROM StrategicValue
ORDER BY StrategicValueScore DESC; 