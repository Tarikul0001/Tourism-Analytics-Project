-- =====================================================================================
-- QUERY 4: Market Concentration Risk Assessment
-- =====================================================================================
-- PURPOSE: Identify markets vulnerable to seasonal shocks due to over-concentration 
-- of tourist arrivals in specific periods
-- 
-- BUSINESS QUESTION: "Which countries face the highest market concentration risk 
-- based on Herfindahl-Hirschman Index (HHI) analysis of monthly arrival distribution?"
-- 
-- APPROACH: Apply HHI (Herfindahl-Hirschman Index) to measure market concentration:
--   • Monthly Share Analysis - How much of annual arrivals occur in each month
--   • HHI Calculation - Sum of squared market shares (higher = more concentrated)
--   • Risk Assessment - Categorize markets using enhanced thresholds and percentile ranking
-- 
-- Business Value: Helps identify markets vulnerable to seasonal shocks and 
-- guides diversification strategies.
-- =====================================================================================

-- STEP 1: Calculate monthly market shares for each country and year
-- This measures what percentage of annual tourist arrivals occur in each month
WITH MonthlyShares AS (
  SELECT Country, Year, Month, Arrivals,
         -- YEARLY TOTAL: Total arrivals for the country in that year
         SUM(Arrivals) OVER (PARTITION BY Country, Year) AS YearlyTotal,
         
         -- MONTHLY SHARE: Percentage of annual arrivals that occur in each month
         -- Formula: (Monthly Arrivals ÷ Yearly Total) × 100
         -- Higher percentage = more concentrated in that month
         (Arrivals * 1.0 / NULLIF(SUM(Arrivals) OVER (PARTITION BY Country, Year), 0)) * 100 AS MonthlyShare
  FROM Tourism_Arrivals
),

-- STEP 2: Calculate Herfindahl-Hirschman Index (HHI) for each country and year
-- HHI measures market concentration by summing squared market shares
-- Higher HHI = more concentrated market = higher risk
HHI AS (
  SELECT Country, Year,
         -- HHI FORMULA: Sum of (Monthly Share)² for all 12 months
         -- Perfect distribution (8.33% each month) = HHI of 833
         -- Complete concentration (100% in one month) = HHI of 10,000
         SUM(POWER(MonthlyShare, 2)) AS HHI_Score
  FROM MonthlyShares
  GROUP BY Country, Year
),

-- STEP 3: Calculate HHI statistics across all years for each country
-- This gives us the long-term concentration patterns and stability
HHIStats AS (
  SELECT Country,
         -- AVERAGE HHI: Mean concentration level across all years
         AVG(HHI_Score) AS AvgHHI,
         
         -- HHI VOLATILITY: How much concentration varies year-over-year
         STDEV(HHI_Score) AS HHI_Volatility,
         
         -- YEARS ANALYZED: Number of years with data for reliability
         COUNT(*) AS YearsAnalyzed
  FROM HHI
  GROUP BY Country
),

-- STEP 4: Add percentile-based risk categorization for more meaningful distribution
RiskCategorization AS (
  SELECT Country, AvgHHI, HHI_Volatility, YearsAnalyzed,
         -- PERCENTILE-BASED RISK: Use NTILE to create meaningful risk categories
         NTILE(5) OVER (ORDER BY AvgHHI DESC) AS RiskPercentile,
         
         -- CONCENTRATION RISK CATEGORY based on percentiles and absolute thresholds
         CASE 
           WHEN AvgHHI < 1000 THEN 'Low Concentration'      -- Well-diversified across months
           WHEN AvgHHI < 1500 THEN 'Moderate Concentration' -- Some seasonal concentration
           WHEN AvgHHI < 2500 THEN 'High Concentration'     -- Highly concentrated in specific months
           ELSE 'Extreme Concentration'                     -- Extremely concentrated, high risk
         END AS ConcentrationRisk
  FROM HHIStats
)

-- STEP 5: Present results with proper decimal formatting
SELECT 
       Country, 
       CAST(ROUND(AvgHHI, 2) AS DECIMAL(10,2)) AS AvgHHI,                    -- Average HHI score (concentration measure)
       CAST(ROUND(HHI_Volatility, 2) AS DECIMAL(10,2)) AS HHI_Volatility,    -- HHI stability over time
       YearsAnalyzed,                                                         -- Number of years analyzed
       RiskPercentile,                                                        -- Risk percentile (1-5, 1 = highest risk)
       ConcentrationRisk,                                                     -- Concentration risk category
       
       -- RISK QUINTILE: Rank markets into 5 groups by concentration risk
       NTILE(5) OVER (ORDER BY AvgHHI DESC) AS RiskQuintile
FROM RiskCategorization
ORDER BY AvgHHI DESC;  -- Show highest concentration (highest risk) first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- HHI Score Interpretation:
-- 
-- LOW CONCENTRATION (HHI < 1000):
-- • Characteristics: Well-diversified tourist arrivals across all months
-- • Risk Level: Low - resilient to seasonal shocks
-- • Business Action: Maintain current operations, focus on growth
-- • Example: Each month has 6-10% of annual arrivals
--
-- MODERATE CONCENTRATION (HHI 1000-1500):
-- • Characteristics: Some seasonal concentration but reasonable diversification
-- • Risk Level: Medium - moderate vulnerability to seasonal shocks
-- • Business Action: Monitor seasonal patterns, develop off-season strategies
-- • Example: Peak months have 15-20% of annual arrivals
--
-- HIGH CONCENTRATION (HHI 1500-2500):
-- • Characteristics: Highly concentrated tourist arrivals in specific months
-- • Risk Level: High - vulnerable to seasonal shocks and disruptions
-- • Business Action: Develop diversification strategies, reduce seasonal dependence
-- • Example: Peak months have 25-35% of annual arrivals
--
-- EXTREME CONCENTRATION (HHI > 2500):
-- • Characteristics: Extremely concentrated tourist arrivals in few months
-- • Risk Level: Very High - highly vulnerable to seasonal shocks
-- • Business Action: Immediate diversification needed, consider business model changes
-- • Example: Peak months have 40%+ of annual arrivals
--
-- Risk Percentile Rankings:
-- 1: Top 20% - Highest concentration risk (immediate diversification needed)
-- 2: 21-40% - High concentration risk (develop diversification plans)
-- 3: 41-60% - Moderate concentration risk (monitor and optimize)
-- 4: 61-80% - Low concentration risk (maintain current strategies)
-- 5: Bottom 20% - Minimal concentration risk (well-diversified markets)
--
-- Key Business Applications:
-- • Risk assessment for tourism investment decisions
-- • Seasonal diversification strategy development
-- • Capacity planning and resource allocation
-- • Crisis management and business continuity planning
-- • Market entry and expansion decisions
--
-- Diversification Strategies for High-Risk Markets:
-- • Develop year-round attractions and activities
-- • Implement off-season marketing campaigns
-- • Create shoulder-season promotions and packages
-- • Diversify tourist source markets
-- • Develop business tourism and MICE segments
--
-- HHI Benchmark Examples:
-- • Perfect Distribution (8.33% each month): HHI = 833
-- • Moderate Concentration (peak months 15%): HHI ≈ 1200
-- • High Concentration (peak months 25%): HHI ≈ 1800
-- • Extreme Concentration (peak months 40%): HHI ≈ 3000
--
-- Market Concentration Risk:
-- This analysis helps identify markets that are overly dependent on specific
-- seasonal periods, making them vulnerable to weather events, economic shocks,
-- or other disruptions that could impact peak tourism seasons.
-- ===================================================================================== 