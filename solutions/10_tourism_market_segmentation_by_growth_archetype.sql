-- =====================================================================================
-- QUERY 10: Tourism Market Segmentation by Growth Archetype
-- =====================================================================================
-- Segment countries into growth archetypes: "High Growth Volatile", "Stable Growth", 
-- "Mature Markets", and "Declining Markets" based on growth patterns and volatility.
-- 
-- Business Value: Enables targeted marketing and development strategies for 
-- different market segments.
-- =====================================================================================

WITH GrowthPatterns AS (
  SELECT Country,
         AVG(Arrivals_Growth_Rate) AS AvgGrowthRate,
         STDEV(Arrivals_Growth_Rate) AS GrowthVolatility,
         COUNT(*) AS DataPoints,
         SUM(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS PositiveGrowthRatio
  FROM Tourism_Arrivals
  WHERE Arrivals_Growth_Rate IS NOT NULL
  GROUP BY Country
),
GrowthSegments AS (
  SELECT Country, AvgGrowthRate, GrowthVolatility, PositiveGrowthRatio,
         CASE 
           WHEN AvgGrowthRate > 5 AND GrowthVolatility > 10 THEN 'High Growth Volatile'
           WHEN AvgGrowthRate > 2 AND GrowthVolatility <= 10 THEN 'Stable Growth'
           WHEN AvgGrowthRate BETWEEN -2 AND 2 THEN 'Mature Markets'
           WHEN AvgGrowthRate < -2 THEN 'Declining Markets'
           ELSE 'Mixed Pattern'
         END AS GrowthArchetype
  FROM GrowthPatterns
  WHERE DataPoints >= 12  -- Minimum 12 months of data
)
SELECT Country, AvgGrowthRate, GrowthVolatility, PositiveGrowthRatio, GrowthArchetype,
       NTILE(4) OVER (ORDER BY AvgGrowthRate DESC) AS GrowthQuartile
FROM GrowthSegments
ORDER BY AvgGrowthRate DESC; 