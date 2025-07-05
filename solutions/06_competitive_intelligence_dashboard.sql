-- =====================================================================================
-- QUERY 6: Competitive Intelligence Dashboard
-- =====================================================================================
-- For each country, identify their top 3 competitors based on similar arrival patterns, 
-- growth trajectories, and market positioning.
-- 
-- Business Value: Provides competitive intelligence for market positioning and 
-- strategic planning against key competitors.
-- =====================================================================================

WITH CountryProfiles AS (
  SELECT Country,
         AVG(Arrivals) AS AvgArrivals,
         STDEV(Arrivals) AS ArrivalsVolatility,
         AVG(Arrivals_Growth_Rate) AS AvgGrowthRate,
         AVG(Source_Market_Diversity) AS AvgDiversity,
         COUNT(*) AS DataPoints
  FROM Tourism_Arrivals
  GROUP BY Country
),
SimilarityMatrix AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         -- Euclidean distance for similarity
         SQRT(
           POWER((a.AvgArrivals - b.AvgArrivals) / NULLIF(a.AvgArrivals, 0), 2) +
           POWER((a.ArrivalsVolatility - b.ArrivalsVolatility) / NULLIF(a.ArrivalsVolatility, 0), 2) +
           POWER((a.AvgGrowthRate - b.AvgGrowthRate) / NULLIF(ABS(a.AvgGrowthRate), 0), 2) +
           POWER((a.AvgDiversity - b.AvgDiversity) / NULLIF(a.AvgDiversity, 0), 2)
         ) AS SimilarityScore
  FROM CountryProfiles a
  CROSS JOIN CountryProfiles b
  WHERE a.Country != b.Country
),
CompetitorRanking AS (
  SELECT Country1, Country2, SimilarityScore,
         ROW_NUMBER() OVER (PARTITION BY Country1 ORDER BY SimilarityScore ASC) AS CompetitorRank
  FROM SimilarityMatrix
)
SELECT Country1 AS Country, Country2 AS TopCompetitor, SimilarityScore
FROM CompetitorRanking
WHERE CompetitorRank <= 3
ORDER BY Country1, CompetitorRank; 