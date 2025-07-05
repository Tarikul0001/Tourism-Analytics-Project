-- =====================================================================================
-- QUERY 10: Strategic Market Entry Timing
-- =====================================================================================
-- PURPOSE: Identify optimal timing for entering new tourism markets based on 
-- comprehensive analysis of growth patterns, market dynamics, and competitive landscape
-- 
-- BUSINESS QUESTION: "When is the optimal entry timing for new tourism markets 
-- based on growth acceleration, market saturation, and competitive intensity?"
-- 
-- APPROACH: Analyze market entry timing using simplified but effective metrics:
--   • Growth Momentum - Current vs previous period growth comparison
--   • Market Stability - Consistency of growth patterns
--   • Recovery Strength - Post-crisis recovery performance
--   • Market Opportunity - Available growth potential
--   • Entry Timing Score - Combined assessment for strategic guidance
-- 
-- Business Value: Provides differentiated market entry recommendations with
-- specific timing guidance and risk assessment for strategic planning.
-- =====================================================================================

-- STEP 1: Calculate basic growth metrics for each country
WITH CountryMetrics AS (
  SELECT 
    Country,
    -- AVERAGE GROWTH RATE: Overall growth performance
    AVG(Arrivals_Growth_Rate) AS AvgGrowthRate,
    
    -- GROWTH STABILITY: Standard deviation of growth rates (lower = more stable)
    STDEVP(Arrivals_Growth_Rate) AS GrowthVolatility,
    
    -- RECOVERY PERFORMANCE: Average growth in 2021-2022 (post-crisis)
    AVG(CASE WHEN Year >= 2021 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecoveryGrowth,
    
    -- MARKET SIZE: Average arrivals volume
    AVG(Arrivals) AS AvgArrivals,
    
    -- MAXIMUM ARRIVALS: Peak market size
    MAX(Arrivals) AS MaxArrivals,
    
    -- GROWTH POTENTIAL: Available market space
    (MAX(Arrivals) - AVG(Arrivals)) / NULLIF(MAX(Arrivals), 0) AS GrowthPotential,
    
    -- RECENT PERFORMANCE: Latest year growth (2022)
    AVG(CASE WHEN Year = 2022 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecentGrowth,
    
    -- CRISIS IMPACT: 2020 performance (negative = crisis impact)
    AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) AS CrisisImpact,
    
    -- RECOVERY STRENGTH: How well market recovered from crisis
    CASE 
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -50 
      AND AVG(CASE WHEN Year >= 2021 THEN Arrivals_Growth_Rate ELSE NULL END) > 20 
      THEN 'Strong Recovery'
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -30 
      AND AVG(CASE WHEN Year >= 2021 THEN Arrivals_Growth_Rate ELSE NULL END) > 10 
      THEN 'Moderate Recovery'
      WHEN AVG(CASE WHEN Year >= 2021 THEN Arrivals_Growth_Rate ELSE NULL END) > 0 
      THEN 'Weak Recovery'
      ELSE 'No Recovery'
    END AS RecoveryStatus
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Calculate market cycle position based on recent trends
MarketCycle AS (
  SELECT 
    Country,
    CASE 
      WHEN RecentGrowth > 30 THEN 'Accelerating Growth'
      WHEN RecentGrowth > 10 THEN 'Steady Growth'
      WHEN RecentGrowth > 0 THEN 'Slowing Growth'
      WHEN RecentGrowth > -20 THEN 'Stable'
      ELSE 'Declining'
    END AS MarketCyclePosition,
    
    CASE 
      WHEN RecoveryGrowth > 50 THEN 'High Recovery'
      WHEN RecoveryGrowth > 20 THEN 'Moderate Recovery'
      WHEN RecoveryGrowth > 0 THEN 'Low Recovery'
      ELSE 'No Recovery'
    END AS RecoveryStrength
  FROM CountryMetrics
),

-- STEP 3: Calculate entry timing score using simplified formula
EntryTiming AS (
  SELECT 
    cm.Country,
    cm.AvgGrowthRate,
    cm.GrowthVolatility,
    cm.RecoveryGrowth,
    cm.GrowthPotential,
    cm.RecentGrowth,
    cm.CrisisImpact,
    cm.RecoveryStatus,
    mc.MarketCyclePosition,
    mc.RecoveryStrength,
    
    -- GROWTH STABILITY SCORE: Inverse of volatility (higher = more stable)
    CASE 
      WHEN cm.GrowthVolatility = 0 THEN 1.0
      ELSE 1.0 / (1.0 + cm.GrowthVolatility)
    END AS GrowthStabilityScore,
    
    -- RECOVERY MOMENTUM SCORE: Based on recovery performance
    CASE 
      WHEN cm.RecoveryGrowth > 50 THEN 1.0
      WHEN cm.RecoveryGrowth > 20 THEN 0.8
      WHEN cm.RecoveryGrowth > 0 THEN 0.6
      WHEN cm.RecoveryGrowth > -20 THEN 0.4
      ELSE 0.2
    END AS RecoveryMomentumScore,
    
    -- MARKET OPPORTUNITY SCORE: Based on growth potential
    CASE 
      WHEN cm.GrowthPotential > 0.3 THEN 1.0
      WHEN cm.GrowthPotential > 0.2 THEN 0.8
      WHEN cm.GrowthPotential > 0.1 THEN 0.6
      WHEN cm.GrowthPotential > 0.05 THEN 0.4
      ELSE 0.2
    END AS MarketOpportunityScore,
    
    -- ENTRY TIMING SCORE: Combined weighted score
    (
      (CASE WHEN cm.GrowthVolatility = 0 THEN 1.0 ELSE 1.0 / (1.0 + cm.GrowthVolatility) END * 0.3) +
      (CASE 
        WHEN cm.RecoveryGrowth > 50 THEN 1.0
        WHEN cm.RecoveryGrowth > 20 THEN 0.8
        WHEN cm.RecoveryGrowth > 0 THEN 0.6
        WHEN cm.RecoveryGrowth > -20 THEN 0.4
        ELSE 0.2
       END * 0.4) +
      (CASE 
        WHEN cm.GrowthPotential > 0.3 THEN 1.0
        WHEN cm.GrowthPotential > 0.2 THEN 0.8
        WHEN cm.GrowthPotential > 0.1 THEN 0.6
        WHEN cm.GrowthPotential > 0.05 THEN 0.4
        ELSE 0.2
       END * 0.3)
    ) AS EntryTimingScore
  FROM CountryMetrics cm
  JOIN MarketCycle mc ON cm.Country = mc.Country
)

-- STEP 4: Generate simplified, executive-friendly output
SELECT 
       Country, 
       ROUND(EntryTimingScore, 2) AS EntryScore,                    -- Overall entry timing score (0-1)
       
       -- ENTRY RECOMMENDATION: Clear, actionable guidance
       CASE 
         WHEN EntryTimingScore >= 0.8 THEN 'IMMEDIATE ENTRY'
         WHEN EntryTimingScore >= 0.6 THEN 'TIMELY ENTRY'
         WHEN EntryTimingScore >= 0.4 THEN 'CAUTIOUS ENTRY'
         WHEN EntryTimingScore >= 0.2 THEN 'DELAY ENTRY'
         ELSE 'AVOID ENTRY'
       END AS Recommendation,
       
       -- TIMING: Specific timing guidance
       CASE 
         WHEN EntryTimingScore >= 0.8 THEN '3-6 months'
         WHEN EntryTimingScore >= 0.6 THEN '6-12 months'
         WHEN EntryTimingScore >= 0.4 THEN '12-18 months'
         WHEN EntryTimingScore >= 0.2 THEN '18-24 months'
         ELSE '24+ months'
       END AS Timing,
       
       -- RISK: Simple risk assessment
       CASE 
         WHEN EntryTimingScore >= 0.8 THEN 'Low'
         WHEN EntryTimingScore >= 0.6 THEN 'Low-Medium'
         WHEN EntryTimingScore >= 0.4 THEN 'Medium'
         WHEN EntryTimingScore >= 0.2 THEN 'Medium-High'
         ELSE 'High'
       END AS Risk,
       
       -- MARKET STATE: Current market condition
       MarketCyclePosition,
       
       -- RECOVERY: Recovery performance
       RecoveryStatus,
       
       -- STRATEGY: Recommended approach
       CASE 
         WHEN EntryTimingScore >= 0.8 THEN 'Aggressive Investment'
         WHEN EntryTimingScore >= 0.6 THEN 'Strategic Investment'
         WHEN EntryTimingScore >= 0.4 THEN 'Limited Investment'
         WHEN EntryTimingScore >= 0.2 THEN 'Monitor & Prepare'
         ELSE 'Alternative Markets'
       END AS Strategy
FROM EntryTiming
ORDER BY EntryTimingScore DESC;  -- Show best opportunities first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- ENTRY SCORE INTERPRETATION (0-1 scale):
-- 
-- 0.8-1.0: IMMEDIATE ENTRY
-- • Best market conditions for entry
-- • Low risk, high opportunity
-- • Enter within 3-6 months
-- • Strategy: Aggressive Investment
--
-- 0.6-0.8: TIMELY ENTRY  
-- • Good market conditions for entry
-- • Low-medium risk, good opportunity
-- • Enter within 6-12 months
-- • Strategy: Strategic Investment
--
-- 0.4-0.6: CAUTIOUS ENTRY
-- • Moderate market conditions
-- • Medium risk, moderate opportunity
-- • Enter within 12-18 months
-- • Strategy: Limited Investment
--
-- 0.2-0.4: DELAY ENTRY
-- • Poor market conditions
-- • Medium-high risk, limited opportunity
-- • Enter within 18-24 months
-- • Strategy: Monitor & Prepare
--
-- 0.0-0.2: AVOID ENTRY
-- • Worst market conditions
-- • High risk, minimal opportunity
-- • Reassess in 24+ months
-- • Strategy: Alternative Markets
--
-- MARKET CYCLE POSITIONS:
-- 
-- Accelerating Growth: Market expanding rapidly - optimal entry timing
-- Steady Growth: Stable growth patterns - good entry timing
-- Slowing Growth: Growth decelerating - cautious entry timing
-- Stable: Consistent performance - moderate entry timing
-- Declining: Market contracting - poor entry timing
--
-- RECOVERY STATUS:
-- 
-- Strong Recovery: High crisis impact with strong recovery - excellent resilience
-- Moderate Recovery: Moderate crisis impact with good recovery - good resilience
-- Weak Recovery: Limited crisis impact with weak recovery - cautious approach
-- No Recovery: Poor crisis impact or no recovery - avoid entry
--
-- RISK LEVELS:
-- 
-- Low: Optimal conditions, minimal risk
-- Low-Medium: Good conditions, manageable risk
-- Medium: Moderate conditions, careful planning required
-- Medium-High: Poor conditions, significant risk
-- High: Unfavorable conditions, high risk
--
-- STRATEGIC APPROACH:
-- 
-- Aggressive Investment: Significant investment, rapid market entry
-- Strategic Investment: Measured investment, planned market entry
-- Limited Investment: Minimal investment, cautious market entry
-- Monitor & Prepare: Research and preparation, delayed entry
-- Alternative Markets: Focus on other market opportunities
--
-- EXECUTIVE DECISION FRAMEWORK:
-- 
-- IMMEDIATE ENTRY MARKETS:
-- • Allocate significant resources and budget
-- • Develop comprehensive market entry plan
-- • Target market leadership position
-- • Monitor performance closely
--
-- TIMELY ENTRY MARKETS:
-- • Allocate moderate resources and budget
-- • Develop targeted market entry plan
-- • Target market challenger position
-- • Monitor market developments
--
-- CAUTIOUS ENTRY MARKETS:
-- • Allocate limited resources and budget
-- • Develop minimal market entry plan
-- • Target market follower position
-- • Monitor market conditions closely
--
-- DELAY ENTRY MARKETS:
-- • Allocate minimal resources for research
-- • Develop entry preparation plan
-- • Monitor market developments
-- • Consider alternative strategies
--
-- AVOID ENTRY MARKETS:
-- • Allocate no resources for entry
-- • Focus on alternative market opportunities
-- • Monitor for future improvements
-- • Consider other business strategies
--
-- KEY SUCCESS FACTORS:
-- 
-- TIMING: Enter when market conditions are optimal
-- RESOURCES: Allocate appropriate investment level
-- STRATEGY: Choose right market positioning
-- MONITORING: Track market developments closely
-- FLEXIBILITY: Adjust strategy based on market changes
--
-- STRATEGIC PLANNING:
-- This simplified analysis provides clear, actionable market entry
-- recommendations with specific timing, risk assessment, and strategic
-- guidance. Use this framework to prioritize markets and allocate
-- resources effectively for tourism market expansion.
-- ===================================================================================== 