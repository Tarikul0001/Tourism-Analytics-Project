-- =====================================================================================
-- QUERY 5: Tourism Resilience Stress Test
-- =====================================================================================
-- Simulate different crisis scenarios and rank countries by their ability to 
-- maintain arrivals under various stress conditions.
-- 
-- Business Value: Enables crisis preparedness planning and identifies markets 
-- with strong resilience for strategic focus.
-- =====================================================================================

WITH Baseline AS (
  SELECT Country, Year, SUM(Arrivals) AS TotalArrivals
  FROM Tourism_Arrivals
  WHERE Year >= (SELECT MAX(Year) FROM Tourism_Arrivals) - 2
  GROUP BY Country, Year
),
StressScenarios AS (
  SELECT Country,
         -- Scenario 1: 50% drop in peak season
         SUM(CASE WHEN Year = (SELECT MAX(Year) FROM Tourism_Arrivals) THEN TotalArrivals * 0.5 ELSE TotalArrivals END) AS Scenario1,
         -- Scenario 2: 30% drop across all months
         SUM(CASE WHEN Year = (SELECT MAX(Year) FROM Tourism_Arrivals) THEN TotalArrivals * 0.7 ELSE TotalArrivals END) AS Scenario2,
         -- Scenario 3: 20% drop in off-season only
         SUM(TotalArrivals) AS Scenario3
  FROM Baseline
  GROUP BY Country
),
ResilienceScore AS (
  SELECT Country, Scenario1, Scenario2, Scenario3,
         (Scenario1 + Scenario2 + Scenario3) / 3.0 AS AvgResilience,
         STDEV(Scenario1, Scenario2, Scenario3) AS ResilienceStability
  FROM StressScenarios
)
SELECT Country, Scenario1, Scenario2, Scenario3, AvgResilience, ResilienceStability,
       NTILE(4) OVER (ORDER BY AvgResilience DESC) AS ResilienceQuartile
FROM ResilienceScore
ORDER BY AvgResilience DESC; 