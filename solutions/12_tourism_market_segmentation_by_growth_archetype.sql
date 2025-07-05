-- =====================================================================================
-- QUERY 12: Tourism Market Segmentation by Growth Archetype
-- =====================================================================================
-- PURPOSE: Classify tourism markets into growth archetypes for targeted marketing 
-- and investment strategies
-- 
-- BUSINESS QUESTION: "How should we classify countries into growth archetypes 
-- (Sustained Growers, Cyclical Performers, Volatile Markets, Stable Markets) 
-- based on growth patterns?"
-- 
-- APPROACH: Segment markets using four key growth pattern metrics:
--   • Average Growth Rate - Long-term growth trend
--   • Growth Volatility - How much growth fluctuates
--   • Positive Growth Percentage - Consistency of positive growth
--   • Growth Range - Difference between best and worst years
--   • Archetype Classification - Assign each market to a growth archetype
-- 
-- Business Value: Enables targeted marketing strategies and investment approaches 
-- based on market growth characteristics.
-- =====================================================================================

-- STEP 1: Calculate growth pattern metrics for each country
-- These metrics capture the nature and consistency of market growth
WITH GrowthPatterns AS (
  SELECT Country,
         -- AVERAGE GROWTH RATE: Long-term growth trend
         AVG(Arrivals_Growth_Rate) AS AvgGrowth,
         
         -- GROWTH VOLATILITY: Standard deviation of growth rates
         -- Higher volatility = more unpredictable growth
         STDEV(Arrivals_Growth_Rate) AS GrowthVolatility,
         
         -- POSITIVE GROWTH PERCENTAGE: Share of periods with positive growth
         -- Higher percentage = more consistent positive growth
         COUNT(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1 END) * 1.0 / COUNT(*) AS PositiveGrowthPct,
         
         -- GROWTH RANGE: Difference between best and worst years
         -- Higher range = more extreme growth swings
         MAX(Arrivals_Growth_Rate) - MIN(Arrivals_Growth_Rate) AS GrowthRange
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Classify markets into growth archetypes based on patterns
GrowthArchetypes AS (
  SELECT Country, AvgGrowth, GrowthVolatility, PositiveGrowthPct, GrowthRange,
         -- GROWTH ARCHETYPE: Assign based on growth metrics
         CASE 
           WHEN AvgGrowth > 5 AND GrowthVolatility < 20 AND PositiveGrowthPct > 0.7 THEN 'Sustained Growers'
           WHEN AvgGrowth BETWEEN -5 AND 5 AND GrowthVolatility > 30 THEN 'Cyclical Performers'
           WHEN GrowthVolatility > 50 THEN 'Volatile Markets'
           WHEN AvgGrowth BETWEEN -2 AND 2 AND GrowthVolatility < 15 THEN 'Stable Markets'
           ELSE 'Mixed Pattern'
         END AS GrowthArchetype
  FROM GrowthPatterns
)

-- STEP 3: Output segmentation results with rounded metrics
SELECT 
       Country, 
       CAST(ROUND(AvgGrowth, 2) AS DECIMAL(10,2)) AS AvgGrowth,                      -- Average growth rate (%)
       CAST(ROUND(GrowthVolatility, 2) AS DECIMAL(10,2)) AS GrowthVolatility,        -- Growth volatility (standard deviation)
       CAST(ROUND(PositiveGrowthPct, 2) AS DECIMAL(10,2)) AS PositiveGrowthPct,      -- Consistency of positive growth
       CAST(ROUND(GrowthRange, 2) AS DECIMAL(10,2)) AS GrowthRange,                  -- Range of growth rates
       GrowthArchetype                                        -- Assigned growth archetype
FROM GrowthArchetypes
ORDER BY AvgGrowth DESC;  -- Show fastest growers first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Growth Archetype Interpretation:
-- 
-- SUSTAINED GROWERS:
-- • High average growth, low volatility, consistent positive growth
-- • Investment Focus: Expansion, premium products, long-term strategies
-- • Marketing Focus: Growth-oriented campaigns, new product launches
--
-- CYCLICAL PERFORMERS:
-- • Moderate average growth, high volatility, variable performance
-- • Investment Focus: Timing and flexibility, risk management
-- • Marketing Focus: Seasonal or event-driven campaigns
--
-- VOLATILE MARKETS:
-- • High volatility, unpredictable growth, large swings
-- • Investment Focus: High risk/high reward, opportunistic strategies
-- • Marketing Focus: Short-term promotions, rapid response
--
-- STABLE MARKETS:
-- • Low average growth, low volatility, consistent performance
-- • Investment Focus: Efficiency, cost control, steady returns
-- • Marketing Focus: Loyalty programs, retention strategies
--
-- MIXED PATTERN:
-- • Does not fit neatly into other categories
-- • Investment Focus: Custom strategies, further analysis needed
-- • Marketing Focus: Test and learn, pilot programs
--
-- Key Business Applications:
-- • Targeted marketing and product development
-- • Investment portfolio diversification
-- • Risk management and scenario planning
-- • Market entry and exit decisions
-- • Performance benchmarking and segmentation
--
-- Growth Pattern Metrics:
-- • Average Growth Rate: Long-term trend (higher = better)
-- • Growth Volatility: Predictability (lower = better)
-- • Positive Growth Percentage: Consistency (higher = better)
-- • Growth Range: Extremes (lower = more stable)
--
-- Segmentation Benefits:
-- This analysis enables executives to tailor marketing, investment,
-- and risk management strategies to the unique growth patterns of
-- each tourism market segment.
-- ===================================================================================== 