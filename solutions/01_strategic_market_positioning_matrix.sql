-- =====================================================================================
-- QUERY 1: Strategic Market Positioning Matrix
-- =====================================================================================
-- Classify countries into "Market Leaders", "Emerging Challengers", "Stable Performers", 
-- and "At-Risk Markets" based on 3-year CAGR, market share stability, and recovery resilience.
-- 
-- Business Value: Enables strategic resource allocation and market prioritization 
-- for tourism development and investment decisions.
-- =====================================================================================

WITH MarketMetrics AS (
  SELECT Country,
         -- 3-Year CAGR
         (POWER(CAST(MAX(Arrivals) AS FLOAT) / NULLIF(MIN(Arrivals), 0), 1.0/3) - 1) * 100 AS CAGR_3Y,
         -- Market Share Stability (inverse of volatility)
         1.0 / NULLIF(STDEV(SUM(Arrivals) OVER (PARTITION BY Year)), 0) AS ShareStability,
         -- Recovery Resilience (2022 vs 2020)
         CASE WHEN SUM(CASE WHEN Year = 2020 THEN Arrivals ELSE 0 END) = 0 THEN NULL
              ELSE (SUM(CASE WHEN Year = 2022 THEN Arrivals ELSE 0 END) - 
                    SUM(CASE WHEN Year = 2020 THEN Arrivals ELSE 0 END)) * 100.0 / 
                   SUM(CASE WHEN Year = 2020 THEN Arrivals ELSE 0 END) END AS RecoveryResilience
  FROM Tourism_Arrivals
  WHERE Year >= (SELECT MAX(Year) FROM Tourism_Arrivals) - 2
  GROUP BY Country
),
RankedMetrics AS (
  SELECT Country, CAGR_3Y, ShareStability, RecoveryResilience,
         NTILE(4) OVER (ORDER BY CAGR_3Y DESC) AS CAGR_Rank,
         NTILE(4) OVER (ORDER BY ShareStability DESC) AS Stability_Rank,
         NTILE(4) OVER (ORDER BY RecoveryResilience DESC) AS Resilience_Rank
  FROM MarketMetrics
  WHERE CAGR_3Y IS NOT NULL AND ShareStability IS NOT NULL AND RecoveryResilience IS NOT NULL
),
StrategicScore AS (
  SELECT Country, CAGR_3Y, ShareStability, RecoveryResilience,
         (CAGR_Rank + Stability_Rank + Resilience_Rank) / 3.0 AS StrategicScore
  FROM RankedMetrics
)
SELECT Country, CAGR_3Y, ShareStability, RecoveryResilience, StrategicScore,
       CASE 
         WHEN StrategicScore <= 1.5 THEN 'Market Leaders'
         WHEN StrategicScore <= 2.5 THEN 'Emerging Challengers'
         WHEN StrategicScore <= 3.5 THEN 'Stable Performers'
         ELSE 'At-Risk Markets'
       END AS StrategicPosition
FROM StrategicScore
ORDER BY StrategicScore; 