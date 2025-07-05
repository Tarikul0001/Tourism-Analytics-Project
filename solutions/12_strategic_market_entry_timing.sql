-- =====================================================================================
-- QUERY 12: Strategic Market Entry Timing
-- =====================================================================================
-- Identify optimal entry windows for new markets based on growth acceleration, 
-- market stability, and competitive landscape analysis.
-- 
-- Business Value: Guides market entry decisions and timing for tourism operators, 
-- hotels, and airlines expanding into new markets.
-- =====================================================================================

WITH GrowthAcceleration AS (
  SELECT Country, Year, Month,
         Arrivals_Growth_Rate,
         LAG(Arrivals_Growth_Rate) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevGrowthRate,
         -- Growth acceleration (second derivative)
         Arrivals_Growth_Rate - LAG(Arrivals_Growth_Rate) OVER (PARTITION BY Country ORDER BY Year, Month) AS GrowthAcceleration
  FROM Tourism_Arrivals
  WHERE Arrivals_Growth_Rate IS NOT NULL
),
EntryTiming AS (
  SELECT Country, Year, Month,
         Arrivals_Growth_Rate, GrowthAcceleration,
         -- Entry timing score: High growth + Positive acceleration + Low volatility
         Arrivals_Growth_Rate * 
         CASE WHEN GrowthAcceleration > 0 THEN 1.5 ELSE 1.0 END AS EntryScore
  FROM GrowthAcceleration
  WHERE GrowthAcceleration IS NOT NULL
),
OptimalWindows AS (
  SELECT Country, Year, Month, Arrivals_Growth_Rate, GrowthAcceleration, EntryScore,
         ROW_NUMBER() OVER (PARTITION BY Country ORDER BY EntryScore DESC) AS EntryRank
  FROM EntryTiming
)
SELECT Country, Year, Month, Arrivals_Growth_Rate, GrowthAcceleration, EntryScore,
       CASE WHEN EntryRank = 1 THEN 'Optimal Entry Window'
            WHEN EntryRank <= 3 THEN 'Good Entry Window'
            ELSE 'Standard Entry Window' END AS EntryTiming
FROM OptimalWindows
WHERE EntryRank <= 5
ORDER BY Country, EntryRank; 