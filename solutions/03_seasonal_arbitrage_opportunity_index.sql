-- =====================================================================================
-- QUERY 3: Seasonal Arbitrage Opportunity Index
-- =====================================================================================
-- Identify countries with the highest potential for revenue optimization through 
-- seasonal pricing strategies based on peak/off-peak arrival ratios.
-- 
-- Business Value: Identifies revenue optimization opportunities and dynamic pricing 
-- strategies for hotels, airlines, and tourism operators.
-- =====================================================================================

WITH SeasonalAnalysis AS (
  SELECT Country, Year,
         AVG(Peak_Season_Arrivals) AS AvgPeakArrivals,
         AVG(Off_Season_Arrivals) AS AvgOffArrivals,
         STDEV(Peak_Season_Arrivals) AS PeakVolatility,
         STDEV(Off_Season_Arrivals) AS OffVolatility
  FROM Tourism_Arrivals
  GROUP BY Country, Year
),
SeasonalMetrics AS (
  SELECT Country,
         AVG(AvgPeakArrivals) AS OverallPeak,
         AVG(AvgOffArrivals) AS OverallOff,
         AVG(PeakVolatility) AS PeakStability,
         AVG(OffVolatility) AS OffStability
  FROM SeasonalAnalysis
  GROUP BY Country
),
ArbitrageIndex AS (
  SELECT Country, OverallPeak, OverallOff,
         CASE WHEN OverallOff = 0 THEN NULL
              ELSE OverallPeak * 1.0 / OverallOff END AS PeakOffRatio,
         (PeakStability + OffStability) / 2.0 AS SeasonalStability,
         -- Arbitrage Index: High ratio + Low volatility = High opportunity
         CASE WHEN OverallOff = 0 THEN NULL
              ELSE (OverallPeak * 1.0 / OverallOff) * (1.0 / NULLIF((PeakStability + OffStability) / 2.0, 0)) END AS ArbitrageIndex
  FROM SeasonalMetrics
)
SELECT Country, OverallPeak, OverallOff, PeakOffRatio, SeasonalStability, ArbitrageIndex,
       NTILE(4) OVER (ORDER BY ArbitrageIndex DESC) AS OpportunityQuartile
FROM ArbitrageIndex
WHERE ArbitrageIndex IS NOT NULL
ORDER BY ArbitrageIndex DESC; 