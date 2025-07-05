-- =====================================================================================
-- QUERY 1: Strategic Market Positioning Matrix
-- =====================================================================================
-- PURPOSE: Classify tourism markets into strategic categories for resource allocation
-- 
-- BUSINESS QUESTION: "How should we classify countries into Market Leaders, Emerging 
-- Challengers, Stable Performers, and At-Risk Markets for strategic planning?"
-- 
-- APPROACH: Analyze 3 key dimensions:
--   1. Growth Performance (3-Year CAGR) - How fast is the market growing?
--   2. Market Stability (Volatility Index) - How predictable is the market?
--   3. Crisis Resilience (Recovery Resilience) - How well did it recover from COVID?
-- 
-- Business Value: Enables strategic resource allocation and market prioritization 
-- for tourism development and investment decisions.
-- =====================================================================================

-- STEP 1: Calculate yearly totals for the last 3 years to analyze recent trends
-- This focuses on recent performance rather than historical data
WITH YearlyTotals AS (
  SELECT Country, Year, SUM(Arrivals) AS YearlyArrivals
  FROM Tourism_Arrivals
  WHERE Year >= (SELECT MAX(Year) FROM Tourism_Arrivals) - 2  -- Last 3 years
  GROUP BY Country, Year
),

-- STEP 1.5: Validate data completeness and get chronological values for CAGR
ValidatedData AS (
  SELECT Country, Year, YearlyArrivals
  FROM YearlyTotals
  WHERE Country IN (
    -- Only include countries with data for all 3 years
    SELECT Country 
    FROM YearlyTotals 
    GROUP BY Country 
    HAVING COUNT(*) = 3
  )
),

-- STEP 2: Calculate the 3 key performance metrics for each country
-- Each metric measures a different aspect of market strength
MarketMetrics AS (
  SELECT Country,
         -- METRIC 1: 3-Year Compound Annual Growth Rate (CAGR)
         -- Measures how fast the market is growing over the last 3 years
         -- Formula: (Final Year Value / First Year Value)^(1/2) - 1 (for 3 years = 2 periods)
         -- Higher CAGR = faster growing market
         CASE 
           WHEN MIN(YearlyArrivals) = 0 THEN NULL  -- Cannot calculate CAGR with zero base
           ELSE (POWER(CAST(MAX(YearlyArrivals) AS FLOAT) / MIN(YearlyArrivals), 1.0/2) - 1) * 100
         END AS CAGR_3Y,
         
         -- METRIC 2: Market Volatility Index (Coefficient of Variation)
         -- Measures how consistent/predictable the market performance is
         -- Formula: Standard Deviation / Mean (normalized by mean for fair comparison)
         -- Lower volatility = more stable/predictable market for planning
         CASE 
           WHEN AVG(YearlyArrivals) = 0 THEN NULL  -- Cannot calculate volatility with zero mean
           WHEN STDEV(YearlyArrivals) = 0 THEN 0   -- Perfect stability (no variation)
           ELSE STDEV(YearlyArrivals) / AVG(YearlyArrivals)
         END AS VolatilityIndex,
         
         -- METRIC 3: Recovery Resilience (2022 vs 2020 performance)
         -- Measures how well the market recovered from COVID-19 crisis
         -- Formula: (2022 Arrivals - 2020 Arrivals) ÷ 2020 Arrivals × 100
         -- Higher resilience = better crisis recovery capability
         CASE 
           WHEN SUM(CASE WHEN Year = 2020 THEN YearlyArrivals ELSE 0 END) = 0 THEN NULL
           WHEN SUM(CASE WHEN Year = 2022 THEN YearlyArrivals ELSE 0 END) IS NULL THEN NULL
           ELSE (SUM(CASE WHEN Year = 2022 THEN YearlyArrivals ELSE 0 END) - 
                 SUM(CASE WHEN Year = 2020 THEN YearlyArrivals ELSE 0 END)) * 100.0 / 
                SUM(CASE WHEN Year = 2020 THEN YearlyArrivals ELSE 0 END) 
         END AS RecoveryResilience
  FROM ValidatedData
  GROUP BY Country
),

-- STEP 3: Rank each country on each metric (1-4 scale, where 1 = best)
-- This normalizes different metrics to comparable scales
RankedMetrics AS (
  SELECT Country, CAGR_3Y, VolatilityIndex, RecoveryResilience,
         NTILE(4) OVER (ORDER BY CAGR_3Y DESC) AS CAGR_Rank,        -- 1 = highest growth
         NTILE(4) OVER (ORDER BY VolatilityIndex ASC) AS Stability_Rank,  -- 1 = most stable (lowest volatility)
         NTILE(4) OVER (ORDER BY RecoveryResilience DESC) AS Resilience_Rank  -- 1 = best recovery
  FROM MarketMetrics
  WHERE CAGR_3Y IS NOT NULL AND VolatilityIndex IS NOT NULL AND RecoveryResilience IS NOT NULL
),

-- STEP 4: Calculate overall strategic score by averaging the three rankings
-- Lower score = better overall performance (since 1 = best rank)
StrategicScore AS (
  SELECT Country, CAGR_3Y, VolatilityIndex, RecoveryResilience,
         (CAGR_Rank + Stability_Rank + Resilience_Rank) / 3.0 AS StrategicScore
  FROM RankedMetrics
)

-- STEP 5: Classify markets into strategic categories based on overall score
SELECT 
       Country, 
       CAST(ROUND(CAGR_3Y, 2) AS DECIMAL(10,2)) AS CAGR_3Y,                    -- 3-year growth rate (%)
       CAST(ROUND(VolatilityIndex, 4) AS DECIMAL(10,4)) AS VolatilityIndex,     -- Market volatility (lower = more stable)
       CAST(ROUND(RecoveryResilience, 2) AS DECIMAL(10,2)) AS RecoveryResilience, -- Recovery resilience (%)
       CAST(ROUND(StrategicScore, 2) AS DECIMAL(10,2)) AS StrategicScore,       -- Overall strategic score (1-4 scale)
       
       -- STRATEGIC CLASSIFICATION based on overall performance
       CASE 
         WHEN StrategicScore <= 1.5 THEN 'Market Leaders'        -- Top performers: High growth, stable, resilient
         WHEN StrategicScore <= 2.5 THEN 'Emerging Challengers'  -- Growing markets: Good potential but some volatility
         WHEN StrategicScore <= 3.5 THEN 'Stable Performers'     -- Steady markets: Consistent but slower growth
         ELSE 'At-Risk Markets'                                  -- Struggling markets: Poor growth, unstable, weak recovery
       END AS StrategicPosition
FROM StrategicScore
ORDER BY StrategicScore;  -- Show best performers first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Strategic Categories and Business Actions:
-- 
-- MARKET LEADERS (Score ≤ 1.5):
-- • Characteristics: High growth, stable performance, strong crisis recovery
-- • Actions: Invest heavily, expand operations, allocate premium resources
-- • Examples: Fast-growing, predictable markets that bounced back well from COVID
--
-- EMERGING CHALLENGERS (Score 1.5-2.5):
-- • Characteristics: Good growth potential but some volatility or recovery challenges
-- • Actions: Moderate investment, monitor closely, develop growth strategies
-- • Examples: Growing markets that need stability improvements or recovery support
--
-- STABLE PERFORMERS (Score 2.5-3.5):
-- • Characteristics: Consistent but slower growth, reliable performance
-- • Actions: Maintain current operations, optimize efficiency, gradual expansion
-- • Examples: Mature markets with steady but modest growth
--
-- AT-RISK MARKETS (Score > 3.5):
-- • Characteristics: Poor growth, unstable performance, weak crisis recovery
-- • Actions: Consider exit strategies, turnaround plans, or divestment
-- • Examples: Markets struggling with growth, volatility, or crisis recovery
--
-- Key Business Applications:
-- • Resource allocation decisions across different market types
-- • Investment prioritization for tourism development
-- • Risk management and portfolio diversification
-- • Strategic planning for market entry, expansion, or exit
-- • Performance benchmarking and competitive analysis
--
-- METRIC EXPLANATIONS:
-- • CAGR_3Y: 3-year compound annual growth rate (higher = faster growth)
-- • VolatilityIndex: Coefficient of variation (lower = more stable/predictable)
-- • RecoveryResilience: Percentage recovery from 2020 to 2022 (higher = better recovery)
-- • StrategicScore: Average ranking across all metrics (lower = better overall performance)
--
-- DATA QUALITY NOTES:
-- • Only countries with complete 3-year data are included
-- • CAGR calculation excludes countries with zero base year values
-- • Volatility calculation excludes countries with zero mean values
-- • Recovery resilience excludes countries missing 2020 or 2022 data
-- ===================================================================================== 