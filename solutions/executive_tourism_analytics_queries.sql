-- =====================================================================================
-- Executive-Level Tourism Analytics Queries
-- =====================================================================================
-- This file contains 15 advanced SQL queries designed for executive-level 
-- decision-making and strategic planning in the tourism industry.
-- 
-- Dataset: Tourism_Arrivals.csv
-- Columns: Country, Country_Code, Region, Year, Month, Arrivals, 
--          Arrivals_Growth_Rate, Arrivals_Per_Capita, Source_Market_Diversity, 
--          Peak_Season_Arrivals, Off_Season_Arrivals
-- =====================================================================================

-- =====================================================================================
-- QUERY 1: Strategic Market Positioning Matrix
-- =====================================================================================
-- Classify countries into "Market Leaders", "Emerging Challengers", "Stable Performers", 
-- and "At-Risk Markets" based on 3-year CAGR, market share stability, and recovery resilience.
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

-- =====================================================================================
-- QUERY 2: Tourism Investment Risk-Return Profile
-- =====================================================================================
-- Calculate Sharpe Ratio equivalent for tourism markets using arrivals growth as returns 
-- and volatility as risk, identifying optimal investment destinations.
-- =====================================================================================

WITH MonthlyReturns AS (
  SELECT Country, Year, Month,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,
         Arrivals AS CurrentArrivals
  FROM Tourism_Arrivals
),
GrowthRates AS (
  SELECT Country, Year, Month,
         CASE WHEN PrevArrivals = 0 THEN NULL
              ELSE (CurrentArrivals - PrevArrivals) * 1.0 / PrevArrivals END AS MonthlyReturn
  FROM MonthlyReturns
  WHERE PrevArrivals IS NOT NULL
),
RiskReturn AS (
  SELECT Country,
         AVG(MonthlyReturn) AS AvgReturn,
         STDEV(MonthlyReturn) AS ReturnVolatility,
         COUNT(*) AS DataPoints
  FROM GrowthRates
  WHERE MonthlyReturn IS NOT NULL
  GROUP BY Country
  HAVING COUNT(*) >= 12  -- Minimum 12 months of data
)
SELECT Country, AvgReturn, ReturnVolatility,
       CASE WHEN ReturnVolatility = 0 THEN NULL
            ELSE AvgReturn / ReturnVolatility END AS SharpeRatio,
       NTILE(5) OVER (ORDER BY CASE WHEN ReturnVolatility = 0 THEN NULL
                                   ELSE AvgReturn / ReturnVolatility END DESC) AS RiskReturnQuintile
FROM RiskReturn
ORDER BY SharpeRatio DESC;

-- =====================================================================================
-- QUERY 3: Seasonal Arbitrage Opportunity Index
-- =====================================================================================
-- Identify countries with the highest potential for revenue optimization through 
-- seasonal pricing strategies based on peak/off-peak arrival ratios.
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

-- =====================================================================================
-- QUERY 4: Market Concentration Risk Assessment
-- =====================================================================================
-- Calculate Herfindahl-Hirschman Index (HHI) for each country's monthly arrival 
-- distribution to identify over-dependence on specific periods.
-- =====================================================================================

WITH MonthlyShares AS (
  SELECT Country, Year, Month, Arrivals,
         SUM(Arrivals) OVER (PARTITION BY Country, Year) AS YearlyTotal,
         (Arrivals * 1.0 / NULLIF(SUM(Arrivals) OVER (PARTITION BY Country, Year), 0)) * 100 AS MonthlyShare
  FROM Tourism_Arrivals
),
HHI AS (
  SELECT Country, Year,
         SUM(POWER(MonthlyShare, 2)) AS HHI_Score
  FROM MonthlyShares
  GROUP BY Country, Year
),
HHIStats AS (
  SELECT Country,
         AVG(HHI_Score) AS AvgHHI,
         STDEV(HHI_Score) AS HHI_Volatility,
         COUNT(*) AS YearsAnalyzed
  FROM HHI
  GROUP BY Country
)
SELECT Country, AvgHHI, HHI_Volatility, YearsAnalyzed,
       CASE 
         WHEN AvgHHI < 1000 THEN 'Low Concentration'
         WHEN AvgHHI < 1800 THEN 'Moderate Concentration'
         ELSE 'High Concentration'
       END AS ConcentrationRisk,
       NTILE(5) OVER (ORDER BY AvgHHI DESC) AS RiskQuintile
FROM HHIStats
ORDER BY AvgHHI DESC;

-- =====================================================================================
-- QUERY 5: Tourism Resilience Stress Test
-- =====================================================================================
-- Simulate different crisis scenarios and rank countries by their ability to 
-- maintain arrivals under various stress conditions.
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

-- =====================================================================================
-- QUERY 6: Competitive Intelligence Dashboard
-- =====================================================================================
-- For each country, identify their top 3 competitors based on similar arrival patterns, 
-- growth trajectories, and market positioning.
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

-- =====================================================================================
-- QUERY 7: Tourism Market Maturity Index
-- =====================================================================================
-- Develop a composite index measuring market maturity based on arrival stability, 
-- diversity, growth sustainability, and seasonal balance.
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

-- =====================================================================================
-- QUERY 8: Dynamic Pricing Optimization Potential
-- =====================================================================================
-- Calculate the revenue optimization opportunity for each country based on seasonal 
-- demand elasticity and capacity utilization patterns.
-- =====================================================================================

WITH SeasonalDemand AS (
  SELECT Country, Year, Month,
         Arrivals AS Demand,
         Peak_Season_Arrivals AS Capacity,
         Arrivals * 1.0 / NULLIF(Peak_Season_Arrivals, 0) AS UtilizationRate
  FROM Tourism_Arrivals
),
DemandElasticity AS (
  SELECT Country,
         -- Price elasticity approximation using demand variation
         STDEV(UtilizationRate) / AVG(UtilizationRate) AS DemandElasticity,
         -- Capacity utilization efficiency
         AVG(UtilizationRate) AS AvgUtilization,
         -- Seasonal demand variation
         (MAX(UtilizationRate) - MIN(UtilizationRate)) / AVG(UtilizationRate) AS SeasonalVariation
  FROM SeasonalDemand
  GROUP BY Country
),
OptimizationScore AS (
  SELECT Country, DemandElasticity, AvgUtilization, SeasonalVariation,
         -- Higher elasticity + lower utilization + higher variation = higher optimization potential
         DemandElasticity * (1 - AvgUtilization) * SeasonalVariation AS OptimizationPotential
  FROM DemandElasticity
)
SELECT Country, DemandElasticity, AvgUtilization, SeasonalVariation, OptimizationPotential,
       NTILE(4) OVER (ORDER BY OptimizationPotential DESC) AS OptimizationQuartile
FROM OptimizationScore
ORDER BY OptimizationPotential DESC;

-- =====================================================================================
-- QUERY 9: Tourism Economic Impact Multiplier
-- =====================================================================================
-- Estimate the economic multiplier effect for each country based on arrival growth, 
-- diversity, and market stability.
-- =====================================================================================

WITH EconomicIndicators AS (
  SELECT Country,
         -- Growth momentum
         AVG(Arrivals_Growth_Rate) AS GrowthMomentum,
         -- Market diversity (proxy for economic spread)
         AVG(Source_Market_Diversity) AS EconomicDiversity,
         -- Market stability (reduces economic volatility)
         1.0 / NULLIF(STDEV(Arrivals), 0) AS MarketStability,
         -- Arrival scale (larger markets have different multipliers)
         AVG(Arrivals) AS MarketScale
  FROM Tourism_Arrivals
  GROUP BY Country
),
MultiplierCalculation AS (
  SELECT Country, GrowthMomentum, EconomicDiversity, MarketStability, MarketScale,
         -- Base multiplier: 1.5 for tourism
         1.5 +
         -- Growth premium: 0.1 for each 10% growth
         (GrowthMomentum / 10.0) * 0.1 +
         -- Diversity premium: 0.2 for high diversity
         EconomicDiversity * 0.2 +
         -- Stability premium: 0.1 for high stability
         MarketStability * 0.0001 AS EconomicMultiplier
  FROM EconomicIndicators
)
SELECT Country, GrowthMomentum, EconomicDiversity, MarketStability, MarketScale, EconomicMultiplier,
       NTILE(5) OVER (ORDER BY EconomicMultiplier DESC) AS MultiplierQuintile
FROM MultiplierCalculation
ORDER BY EconomicMultiplier DESC;

-- =====================================================================================
-- QUERY 10: Strategic Market Entry Timing
-- =====================================================================================
-- Identify optimal entry timing for new tourism markets based on growth acceleration, 
-- market saturation, and competitive intensity.
-- =====================================================================================

WITH GrowthAcceleration AS (
  SELECT Country, Year, Month,
         Arrivals_Growth_Rate,
         LAG(Arrivals_Growth_Rate, 3) OVER (PARTITION BY Country ORDER BY Year, Month) AS Growth_3MonthsAgo,
         Arrivals_Growth_Rate - LAG(Arrivals_Growth_Rate, 3) OVER (PARTITION BY Country ORDER BY Year, Month) AS GrowthAcceleration
  FROM Tourism_Arrivals
),
MarketSaturation AS (
  SELECT Country,
         -- Market saturation based on arrival growth deceleration
         AVG(CASE WHEN GrowthAcceleration < 0 THEN ABS(GrowthAcceleration) ELSE 0 END) AS SaturationLevel,
         -- Market maturity based on arrival stability
         STDEV(Arrivals_Growth_Rate) AS MarketMaturity
  FROM GrowthAcceleration
  GROUP BY Country
),
EntryTiming AS (
  SELECT Country, SaturationLevel, MarketMaturity,
         -- Lower saturation + higher maturity = better entry timing
         (1 - SaturationLevel) * MarketMaturity AS EntryTimingScore
  FROM MarketSaturation
)
SELECT Country, SaturationLevel, MarketMaturity, EntryTimingScore,
       CASE 
         WHEN EntryTimingScore >= 0.7 THEN 'Optimal Entry Window'
         WHEN EntryTimingScore >= 0.5 THEN 'Good Entry Opportunity'
         WHEN EntryTimingScore >= 0.3 THEN 'Moderate Entry Risk'
         ELSE 'High Entry Risk'
       END AS EntryRecommendation
FROM EntryTiming
ORDER BY EntryTimingScore DESC;

-- =====================================================================================
-- QUERY 11: Tourism Crisis Recovery Trajectory
-- =====================================================================================
-- Analyze recovery patterns post-crisis and predict recovery timeframes for 
-- different market segments.
-- =====================================================================================

WITH CrisisImpact AS (
  SELECT Country, Year, Month,
         Arrivals,
         LAG(Arrivals, 12) OVER (PARTITION BY Country, Month ORDER BY Year) AS PreCrisisArrivals,
         Arrivals * 1.0 / NULLIF(LAG(Arrivals, 12) OVER (PARTITION BY Country, Month ORDER BY Year), 0) AS RecoveryRatio
  FROM Tourism_Arrivals
  WHERE Year >= 2020
),
RecoveryTrajectory AS (
  SELECT Country,
         AVG(CASE WHEN Year = 2020 THEN RecoveryRatio ELSE NULL END) AS CrisisImpact,
         AVG(CASE WHEN Year = 2021 THEN RecoveryRatio ELSE NULL END) AS Recovery2021,
         AVG(CASE WHEN Year = 2022 THEN RecoveryRatio ELSE NULL END) AS Recovery2022,
         -- Recovery speed
         (AVG(CASE WHEN Year = 2022 THEN RecoveryRatio ELSE NULL END) - 
          AVG(CASE WHEN Year = 2020 THEN RecoveryRatio ELSE NULL END)) / 2.0 AS RecoverySpeed
  FROM CrisisImpact
  GROUP BY Country
),
RecoveryPrediction AS (
  SELECT Country, CrisisImpact, Recovery2021, Recovery2022, RecoverySpeed,
         CASE 
           WHEN RecoverySpeed > 0.3 THEN 'Fast Recovery (6-12 months)'
           WHEN RecoverySpeed > 0.1 THEN 'Moderate Recovery (12-24 months)'
           WHEN RecoverySpeed > 0 THEN 'Slow Recovery (24+ months)'
           ELSE 'No Recovery Detected'
         END AS PredictedRecoveryTime
  FROM RecoveryTrajectory
)
SELECT Country, CrisisImpact, Recovery2021, Recovery2022, RecoverySpeed, PredictedRecoveryTime
FROM RecoveryPrediction
ORDER BY RecoverySpeed DESC;

-- =====================================================================================
-- QUERY 12: Tourism Market Segmentation by Growth Archetype
-- =====================================================================================
-- Classify countries into growth archetypes (Sustained Growers, Cyclical Performers, 
-- Volatile Markets, Stable Markets) based on growth patterns.
-- =====================================================================================

WITH GrowthPatterns AS (
  SELECT Country,
         AVG(Arrivals_Growth_Rate) AS AvgGrowth,
         STDEV(Arrivals_Growth_Rate) AS GrowthVolatility,
         COUNT(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1 END) * 1.0 / COUNT(*) AS PositiveGrowthPct,
         MAX(Arrivals_Growth_Rate) - MIN(Arrivals_Growth_Rate) AS GrowthRange
  FROM Tourism_Arrivals
  GROUP BY Country
),
GrowthArchetypes AS (
  SELECT Country, AvgGrowth, GrowthVolatility, PositiveGrowthPct, GrowthRange,
         CASE 
           WHEN AvgGrowth > 5 AND GrowthVolatility < 20 AND PositiveGrowthPct > 0.7 THEN 'Sustained Growers'
           WHEN AvgGrowth BETWEEN -5 AND 5 AND GrowthVolatility > 30 THEN 'Cyclical Performers'
           WHEN GrowthVolatility > 50 THEN 'Volatile Markets'
           WHEN AvgGrowth BETWEEN -2 AND 2 AND GrowthVolatility < 15 THEN 'Stable Markets'
           ELSE 'Mixed Pattern'
         END AS GrowthArchetype
  FROM GrowthPatterns
)
SELECT Country, AvgGrowth, GrowthVolatility, PositiveGrowthPct, GrowthRange, GrowthArchetype
FROM GrowthArchetypes
ORDER BY AvgGrowth DESC;

-- =====================================================================================
-- QUERY 13: Tourism Investment Portfolio Optimization
-- =====================================================================================
-- Create optimal tourism investment portfolios by selecting countries that maximize 
-- returns while minimizing correlation.
-- =====================================================================================

WITH CountryReturns AS (
  SELECT Country, Year, Month,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,
         Arrivals AS CurrentArrivals
  FROM Tourism_Arrivals
),
MonthlyReturns AS (
  SELECT Country, Year, Month,
         CASE WHEN PrevArrivals = 0 THEN NULL
              ELSE (CurrentArrivals - PrevArrivals) * 1.0 / PrevArrivals END AS Return
  FROM CountryReturns
  WHERE PrevArrivals IS NOT NULL
),
ReturnStats AS (
  SELECT Country,
         AVG(Return) AS AvgReturn,
         STDEV(Return) AS ReturnVolatility,
         COUNT(*) AS DataPoints
  FROM MonthlyReturns
  WHERE Return IS NOT NULL
  GROUP BY Country
  HAVING COUNT(*) >= 12
),
CorrelationMatrix AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         CORREL(a.Return, b.Return) AS Correlation
  FROM MonthlyReturns a
  JOIN MonthlyReturns b ON a.Year = b.Year AND a.Month = b.Month
  WHERE a.Country != b.Country
  GROUP BY a.Country, b.Country
),
PortfolioOptimization AS (
  SELECT r.Country, r.AvgReturn, r.ReturnVolatility,
         AVG(ABS(c.Correlation)) AS AvgCorrelation
  FROM ReturnStats r
  LEFT JOIN CorrelationMatrix c ON r.Country = c.Country1 OR r.Country = c.Country2
  GROUP BY r.Country, r.AvgReturn, r.ReturnVolatility
)
SELECT Country, AvgReturn, ReturnVolatility, AvgCorrelation,
       (AvgReturn / NULLIF(ReturnVolatility, 0)) * (1 - AvgCorrelation) AS PortfolioScore,
       NTILE(5) OVER (ORDER BY (AvgReturn / NULLIF(ReturnVolatility, 0)) * (1 - AvgCorrelation) DESC) AS PortfolioRank
FROM PortfolioOptimization
ORDER BY PortfolioScore DESC;

-- =====================================================================================
-- QUERY 14: Tourism Market Efficiency Index
-- =====================================================================================
-- Measure market efficiency by comparing actual arrival patterns to theoretical 
-- optimal patterns based on seasonal demand.
-- =====================================================================================

WITH SeasonalOptimal AS (
  SELECT Country, Month,
         AVG(Arrivals) AS ActualArrivals,
         AVG(Peak_Season_Arrivals) AS OptimalCapacity,
         AVG(Off_Season_Arrivals) AS OffSeasonBaseline
  FROM Tourism_Arrivals
  GROUP BY Country, Month
),
EfficiencyMetrics AS (
  SELECT Country,
         -- Capacity utilization efficiency
         AVG(ActualArrivals * 1.0 / NULLIF(OptimalCapacity, 0)) AS CapacityEfficiency,
         -- Seasonal demand matching
         1.0 / NULLIF(STDEV(ActualArrivals * 1.0 / NULLIF(OptimalCapacity, 0)), 0) AS DemandMatching,
         -- Off-season optimization
         AVG(ActualArrivals * 1.0 / NULLIF(OffSeasonBaseline, 0)) AS OffSeasonEfficiency
  FROM SeasonalOptimal
  GROUP BY Country
),
EfficiencyIndex AS (
  SELECT Country, CapacityEfficiency, DemandMatching, OffSeasonEfficiency,
         (CapacityEfficiency + DemandMatching + OffSeasonEfficiency) / 3.0 AS MarketEfficiencyIndex
  FROM EfficiencyMetrics
)
SELECT Country, CapacityEfficiency, DemandMatching, OffSeasonEfficiency, MarketEfficiencyIndex,
       NTILE(5) OVER (ORDER BY MarketEfficiencyIndex DESC) AS EfficiencyQuintile
FROM EfficiencyIndex
ORDER BY MarketEfficiencyIndex DESC;

-- =====================================================================================
-- QUERY 15: Tourism Strategic Value Assessment
-- =====================================================================================
-- Calculate the strategic value of each tourism market based on growth potential, 
-- market size, competitive position, and economic impact.
-- =====================================================================================

WITH MarketMetrics AS (
  SELECT Country,
         -- Market size (total arrivals)
         SUM(Arrivals) AS TotalArrivals,
         -- Growth potential (recent growth trend)
         AVG(CASE WHEN Year >= (SELECT MAX(Year) FROM Tourism_Arrivals) - 1 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecentGrowth,
         -- Market stability (inverse of volatility)
         1.0 / NULLIF(STDEV(Arrivals), 0) AS MarketStability,
         -- Market diversity
         AVG(Source_Market_Diversity) AS MarketDiversity,
         -- Seasonal balance
         1.0 / NULLIF(ABS(AVG(Peak_Season_Arrivals) / NULLIF(AVG(Off_Season_Arrivals), 0) - 1), 0) AS SeasonalBalance
  FROM Tourism_Arrivals
  GROUP BY Country
),
NormalizedMetrics AS (
  SELECT Country, TotalArrivals, RecentGrowth, MarketStability, MarketDiversity, SeasonalBalance,
         (TotalArrivals - MIN(TotalArrivals) OVER ()) / NULLIF(MAX(TotalArrivals) OVER () - MIN(TotalArrivals) OVER (), 0) AS NormSize,
         (RecentGrowth - MIN(RecentGrowth) OVER ()) / NULLIF(MAX(RecentGrowth) OVER () - MIN(RecentGrowth) OVER (), 0) AS NormGrowth,
         (MarketStability - MIN(MarketStability) OVER ()) / NULLIF(MAX(MarketStability) OVER () - MIN(MarketStability) OVER (), 0) AS NormStability,
         (MarketDiversity - MIN(MarketDiversity) OVER ()) / NULLIF(MAX(MarketDiversity) OVER () - MIN(MarketDiversity) OVER (), 0) AS NormDiversity,
         (SeasonalBalance - MIN(SeasonalBalance) OVER ()) / NULLIF(MAX(SeasonalBalance) OVER () - MIN(SeasonalBalance) OVER (), 0) AS NormBalance
  FROM MarketMetrics
),
StrategicValue AS (
  SELECT Country, TotalArrivals, RecentGrowth, MarketStability, MarketDiversity, SeasonalBalance,
         -- Weighted strategic value score
         NormSize * 0.25 + NormGrowth * 0.30 + NormStability * 0.20 + 
         NormDiversity * 0.15 + NormBalance * 0.10 AS StrategicValueScore
  FROM NormalizedMetrics
)
SELECT Country, TotalArrivals, RecentGrowth, MarketStability, MarketDiversity, SeasonalBalance, StrategicValueScore,
       CASE 
         WHEN StrategicValueScore >= 0.8 THEN 'High Strategic Value'
         WHEN StrategicValueScore >= 0.6 THEN 'Medium Strategic Value'
         WHEN StrategicValueScore >= 0.4 THEN 'Low Strategic Value'
         ELSE 'Minimal Strategic Value'
       END AS StrategicValueCategory,
       NTILE(5) OVER (ORDER BY StrategicValueScore DESC) AS StrategicValueQuintile
FROM StrategicValue
ORDER BY StrategicValueScore DESC;

-- =====================================================================================
-- END OF EXECUTIVE TOURISM ANALYTICS QUERIES
-- ===================================================================================== 