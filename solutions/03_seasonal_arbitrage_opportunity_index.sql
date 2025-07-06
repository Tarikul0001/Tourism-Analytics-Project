-- =====================================================================================
-- QUERY 3: Seasonal Arbitrage Opportunity Index
-- =====================================================================================
-- PURPOSE: Identify markets with the highest revenue optimization potential through 
-- seasonal pricing strategies
-- 
-- BUSINESS QUESTION: "Which of the 65 countries across 12 global regions have the highest potential for revenue 
-- optimization through seasonal pricing strategies based on peak/off-peak arrival ratios, 
-- seasonal stability, and market size?"
-- 
-- APPROACH: Analyze seasonal demand patterns to identify pricing arbitrage opportunities:
--   • Peak vs Off-Peak Ratio - How much demand varies between seasons
--   • Seasonal Stability - How predictable these patterns are
--   • Revenue Opportunity Score - Combines ratio and stability for opportunity scoring
-- 
-- Business Value: Identifies revenue optimization opportunities and dynamic pricing 
-- strategies for hotels, airlines, and tourism operators across diverse global markets, 
-- from year-round Caribbean destinations to seasonal European markets.
-- =====================================================================================

-- STEP 1: Analyze seasonal patterns for each country and year
-- This breaks down tourist arrivals into peak and off-peak seasons
WITH SeasonalAnalysis AS (
  SELECT Country, Year,
         -- PEAK SEASON: Average arrivals during high-demand periods
         AVG(Peak_Season_Arrivals) AS AvgPeakArrivals,
         
         -- OFF-PEAK SEASON: Average arrivals during low-demand periods  
         AVG(Off_Season_Arrivals) AS AvgOffArrivals,
         
         -- PEAK VOLATILITY: How consistent peak season demand is year-over-year
         STDEV(Peak_Season_Arrivals) AS PeakVolatility,
         
         -- OFF-PEAK VOLATILITY: How consistent off-peak season demand is year-over-year
         STDEV(Off_Season_Arrivals) AS OffVolatility
  FROM Tourism_Arrivals
  GROUP BY Country, Year
),

-- STEP 2: Calculate overall seasonal metrics across all years
-- This gives us the long-term seasonal patterns for each country
SeasonalMetrics AS (
  SELECT Country,
         -- OVERALL PEAK: Average peak season arrivals across all years
         AVG(AvgPeakArrivals) AS OverallPeak,
         
         -- OVERALL OFF-PEAK: Average off-peak season arrivals across all years
         AVG(AvgOffArrivals) AS OverallOff,
         
         -- PEAK STABILITY: How predictable peak season demand is (lower = more stable)
         AVG(PeakVolatility) AS PeakStability,
         
         -- OFF-PEAK STABILITY: How predictable off-peak season demand is (lower = more stable)
         AVG(OffVolatility) AS OffVolatility
  FROM SeasonalAnalysis
  GROUP BY Country
),

-- STEP 3: Calculate the revenue opportunity score
-- This combines seasonal demand ratio with stability to identify pricing opportunities
RevenueOpportunity AS (
  SELECT Country, OverallPeak, OverallOff,
         -- PEAK-OFF RATIO: How much higher peak demand is compared to off-peak
         -- Higher ratio = bigger seasonal difference = more pricing opportunity
         CASE WHEN OverallOff = 0 THEN NULL
              ELSE OverallPeak * 1.0 / OverallOff END AS PeakOffRatio,
         
         -- SEASONAL STABILITY: Average volatility of both seasons
         -- Lower stability = more predictable patterns = better for pricing strategies
         (PeakStability + OffVolatility) / 2.0 AS SeasonalStability,
         
         -- REVENUE OPPORTUNITY SCORE: More meaningful calculation
         -- Formula: PeakOffRatio × (1 - SeasonalStability/OverallPeak) × OverallPeak
         -- This rewards high ratios, low volatility, and larger market size
         CASE 
           WHEN OverallOff = 0 THEN NULL  -- No off-peak demand to compare against
           WHEN OverallPeak = 0 THEN NULL  -- No peak demand
           WHEN (PeakStability + OffVolatility) / 2.0 >= OverallPeak THEN NULL  -- Too volatile for pricing strategies
           ELSE (OverallPeak * 1.0 / OverallOff) * (1 - ((PeakStability + OffVolatility) / 2.0) / OverallPeak) * OverallPeak
         END AS RevenueOpportunityScore
  FROM SeasonalMetrics
)

-- STEP 4: Rank markets by revenue opportunity and categorize them
SELECT 
       Country, 
       OverallPeak,                                                                     -- Average peak season arrivals
       OverallOff,                                                                      -- Average off-peak season arrivals
       CAST(ROUND(PeakOffRatio, 2) AS DECIMAL(10,2)) AS PeakOffRatio,                  -- Peak to off-peak ratio
       CAST(ROUND(SeasonalStability, 2) AS DECIMAL(10,2)) AS SeasonalStability,        -- Seasonal demand stability
       CAST(ROUND(RevenueOpportunityScore, 2) AS DECIMAL(10,2)) AS RevenueOpportunityScore,  -- Revenue opportunity score
       
       -- OPPORTUNITY QUARTILE: Rank markets into 4 groups by revenue potential
       NTILE(4) OVER (ORDER BY RevenueOpportunityScore DESC) AS OpportunityQuartile
FROM RevenueOpportunity
WHERE RevenueOpportunityScore IS NOT NULL  -- Exclude markets with no meaningful seasonal patterns
ORDER BY RevenueOpportunityScore DESC;     -- Show highest opportunity markets first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Revenue Opportunity Score Interpretation:
-- 
-- HIGH OPPORTUNITY SCORE (> 1000):
-- • Characteristics: Large seasonal demand differences with predictable patterns and significant market size
-- • Pricing Strategy: Implement aggressive seasonal pricing, premium peak rates
-- • Revenue Opportunity: Significant potential for revenue optimization
-- • Example: Large market with 3x peak/off-peak ratio and stable patterns
--
-- MEDIUM OPPORTUNITY SCORE (500 - 1000):
-- • Characteristics: Moderate seasonal differences with reasonable predictability
-- • Pricing Strategy: Moderate seasonal pricing adjustments
-- • Revenue Opportunity: Good potential for revenue optimization
-- • Example: Medium market with 2x peak/off-peak ratio and some volatility
--
-- LOW OPPORTUNITY SCORE (< 500):
-- • Characteristics: Small seasonal differences, highly volatile patterns, or small market size
-- • Pricing Strategy: Minimal seasonal pricing, focus on other revenue drivers
-- • Revenue Opportunity: Limited potential for seasonal pricing optimization
-- • Example: Small market or similar peak/off-peak demand
--
-- NULL OPPORTUNITY SCORE:
-- • Characteristics: No off-peak demand, no peak demand, or excessive volatility
-- • Business Meaning: No meaningful seasonal pricing opportunities
-- • Action: Focus on other revenue optimization strategies
-- • Examples: Year-round consistent demand, zero arrivals, or unpredictable patterns
--
-- Opportunity Quartile Rankings:
-- 1: Top 25% - Highest revenue opportunities (implement aggressive seasonal pricing)
-- 2: 26-50% - Good revenue opportunities (moderate seasonal pricing)
-- 3: 51-75% - Limited revenue opportunities (minimal seasonal pricing)
-- 4: Bottom 25% - Minimal revenue opportunities (focus on other strategies)
--
-- Key Business Applications:
-- • Dynamic pricing strategies for hotels and accommodation providers
-- • Seasonal rate optimization for airlines and transportation companies
-- • Revenue management and yield optimization
-- • Marketing campaign timing and budget allocation
-- • Capacity planning and resource allocation across seasons
--
-- Pricing Strategy Examples:
-- • High Opportunity Markets: 50-100% price premium during peak seasons
-- • Medium Opportunity Markets: 20-50% price premium during peak seasons  
-- • Low Opportunity Markets: 5-20% price premium or flat pricing
-- • NULL Opportunity Markets: Focus on non-seasonal pricing strategies
--
-- Revenue Opportunity Concept:
-- This analysis identifies markets where businesses can charge significantly higher
-- prices during peak seasons while maintaining reasonable occupancy during off-peak
-- periods, maximizing overall revenue through strategic seasonal pricing.
-- The score considers market size, seasonal variation, and predictability.
-- ===================================================================================== 