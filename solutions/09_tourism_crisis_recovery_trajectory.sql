-- =====================================================================================
-- QUERY 9: Tourism Crisis Recovery Trajectory
-- =====================================================================================
-- Analyze post-crisis recovery patterns to identify countries with the fastest 
-- and most sustainable recovery trajectories.
-- 
-- Business Value: Informs crisis recovery strategies and identifies markets 
-- with strong bounce-back potential.
-- =====================================================================================

WITH CrisisBaseline AS (
  SELECT Country, Year, SUM(Arrivals) AS TotalArrivals
  FROM Tourism_Arrivals
  WHERE Year IN (2020, 2021, 2022)
  GROUP BY Country, Year
),
RecoveryMetrics AS (
  SELECT Country,
         -- Recovery rate (2022 vs 2020)
         CASE WHEN MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END) = 0 THEN NULL
              ELSE (MAX(CASE WHEN Year = 2022 THEN TotalArrivals ELSE 0 END) - 
                    MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END)) * 100.0 / 
                   MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END) END AS RecoveryRate,
         -- Recovery speed (2021 vs 2020)
         CASE WHEN MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END) = 0 THEN NULL
              ELSE (MAX(CASE WHEN Year = 2021 THEN TotalArrivals ELSE 0 END) - 
                    MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END)) * 100.0 / 
                   MAX(CASE WHEN Year = 2020 THEN TotalArrivals ELSE 0 END) END AS RecoverySpeed,
         -- Recovery sustainability (2022 vs 2021)
         CASE WHEN MAX(CASE WHEN Year = 2021 THEN TotalArrivals ELSE 0 END) = 0 THEN NULL
              ELSE (MAX(CASE WHEN Year = 2022 THEN TotalArrivals ELSE 0 END) - 
                    MAX(CASE WHEN Year = 2021 THEN TotalArrivals ELSE 0 END)) * 100.0 / 
                   MAX(CASE WHEN Year = 2021 THEN TotalArrivals ELSE 0 END) END AS RecoverySustainability
  FROM CrisisBaseline
  GROUP BY Country
),
RecoveryScore AS (
  SELECT Country, RecoveryRate, RecoverySpeed, RecoverySustainability,
         (RecoveryRate + RecoverySpeed + RecoverySustainability) / 3.0 AS RecoveryScore
  FROM RecoveryMetrics
  WHERE RecoveryRate IS NOT NULL AND RecoverySpeed IS NOT NULL AND RecoverySustainability IS NOT NULL
)
SELECT Country, RecoveryRate, RecoverySpeed, RecoverySustainability, RecoveryScore,
       NTILE(4) OVER (ORDER BY RecoveryScore DESC) AS RecoveryQuartile
FROM RecoveryScore
ORDER BY RecoveryScore DESC; 