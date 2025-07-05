-- =====================================================================================
-- QUERY 14: Tourism Market Efficiency Index
-- =====================================================================================
-- PURPOSE: Measure market efficiency by analyzing how well actual arrivals 
-- utilize peak season capacity and manage seasonal variations
-- 
-- BUSINESS QUESTION: "How efficiently does each tourism market utilize its 
-- peak season capacity and manage seasonal demand variations?"
-- 
-- APPROACH: Calculate efficiency using three key metrics:
--   • Peak Season Utilization - How well actual arrivals match peak capacity
--   • Seasonal Efficiency - How consistent arrivals are across seasons
--   • Capacity Optimization - How well the market balances peak vs off-peak
--   • Efficiency Index - Composite score of all metrics
-- 
-- Business Value: Identifies operational inefficiencies and optimization 
-- opportunities in tourism markets.
-- =====================================================================================

-- STEP 1: Calculate efficiency metrics for each country
-- This analyzes how well each market utilizes its capacity and manages seasonality
WITH EfficiencyMetrics AS (
  SELECT 
    Country,
    
    -- PEAK SEASON UTILIZATION: How well actual arrivals match peak capacity
    AVG(Arrivals * 1.0 / NULLIF(Peak_Season_Arrivals, 0)) AS PeakSeasonUtilization,
    
    -- OFF-SEASON EFFICIENCY: How well off-season capacity is utilized
    AVG(Arrivals * 1.0 / NULLIF(Off_Season_Arrivals, 0)) AS OffSeasonEfficiency,
    
    -- SEASONAL CONSISTENCY: How consistent arrivals are (inverse of variation)
    -- Higher values = more consistent (better efficiency)
    1.0 / NULLIF(STDEV(Arrivals * 1.0 / NULLIF(Peak_Season_Arrivals, 0)), 0) AS SeasonalConsistency,
    
    -- CAPACITY OPTIMIZATION: Balance between peak and off-season utilization
    -- Higher values = better balance (not over-reliant on peak season)
    AVG(Arrivals * 1.0 / NULLIF(Off_Season_Arrivals, 0)) / 
    NULLIF(AVG(Arrivals * 1.0 / NULLIF(Peak_Season_Arrivals, 0)), 0) AS CapacityOptimization,
    
    -- AVERAGE ARRIVALS: For context
    AVG(Arrivals) AS AvgArrivals,
    
    -- AVERAGE PEAK CAPACITY: For context
    AVG(Peak_Season_Arrivals) AS AvgPeakCapacity,
    
    -- AVERAGE OFF-SEASON CAPACITY: For context
    AVG(Off_Season_Arrivals) AS AvgOffSeasonCapacity
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Calculate overall market efficiency index and categorize markets
EfficiencyIndex AS (
  SELECT 
    Country,
    PeakSeasonUtilization,
    OffSeasonEfficiency,
    SeasonalConsistency,
    CapacityOptimization,
    AvgArrivals,
    AvgPeakCapacity,
    AvgOffSeasonCapacity,
    
    -- MARKET EFFICIENCY INDEX: Weighted average of all metrics
    (PeakSeasonUtilization * 0.3 + 
     OffSeasonEfficiency * 0.3 + 
     SeasonalConsistency * 0.2 + 
     CapacityOptimization * 0.2) AS MarketEfficiencyIndex,
    
    -- EFFICIENCY CATEGORY: Clear classification
    CASE 
      WHEN (PeakSeasonUtilization * 0.3 + 
            OffSeasonEfficiency * 0.3 + 
            SeasonalConsistency * 0.2 + 
            CapacityOptimization * 0.2) > 0.8 THEN 'Highly Efficient'
      WHEN (PeakSeasonUtilization * 0.3 + 
            OffSeasonEfficiency * 0.3 + 
            SeasonalConsistency * 0.2 + 
            CapacityOptimization * 0.2) > 0.6 THEN 'Efficient'
      WHEN (PeakSeasonUtilization * 0.3 + 
            OffSeasonEfficiency * 0.3 + 
            SeasonalConsistency * 0.2 + 
            CapacityOptimization * 0.2) > 0.4 THEN 'Moderately Efficient'
      WHEN (PeakSeasonUtilization * 0.3 + 
            OffSeasonEfficiency * 0.3 + 
            SeasonalConsistency * 0.2 + 
            CapacityOptimization * 0.2) > 0.2 THEN 'Inefficient'
      ELSE 'Highly Inefficient'
    END AS EfficiencyCategory
  FROM EfficiencyMetrics
)

-- STEP 3: Output clear, actionable efficiency analysis
SELECT 
       Country, 
       
       -- EFFICIENCY SCORE: Overall efficiency index (0-1 scale)
       CAST(ROUND(MarketEfficiencyIndex, 2) AS DECIMAL(10,2)) AS EfficiencyScore,
       
       -- EFFICIENCY STATUS: Clear classification
       EfficiencyCategory,
       
       -- PEAK UTILIZATION: How well peak season capacity is used
       CAST(ROUND(PeakSeasonUtilization, 2) AS DECIMAL(10,2)) AS PeakUtilization,
       
       -- OFF-SEASON EFFICIENCY: How well off-season capacity is used
       CAST(ROUND(OffSeasonEfficiency, 2) AS DECIMAL(10,2)) AS OffSeasonEfficiency,
       
       -- SEASONAL CONSISTENCY: How consistent the market is
       CAST(ROUND(SeasonalConsistency, 2) AS DECIMAL(10,2)) AS SeasonalConsistency,
       
       -- CAPACITY BALANCE: How well peak vs off-season is balanced
       CAST(ROUND(CapacityOptimization, 2) AS DECIMAL(10,2)) AS CapacityBalance,
       
       -- EFFICIENCY RANKING: Rank among all markets
       CAST(RANK() OVER (ORDER BY MarketEfficiencyIndex DESC) AS INTEGER) AS EfficiencyRank,
       
       -- STRATEGIC RECOMMENDATION: Actionable advice
       CASE 
         WHEN MarketEfficiencyIndex > 0.8 THEN 'Optimize & Scale'
         WHEN MarketEfficiencyIndex > 0.6 THEN 'Improve & Expand'
         WHEN MarketEfficiencyIndex > 0.4 THEN 'Review & Restructure'
         WHEN MarketEfficiencyIndex > 0.2 THEN 'Major Overhaul'
         ELSE 'Strategic Redesign'
       END AS StrategicRecommendation
FROM EfficiencyIndex
ORDER BY MarketEfficiencyIndex DESC;  -- Show most efficient markets first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- EFFICIENCY SCORE INTERPRETATION (0-1 scale):
-- 
-- 0.8-1.0: HIGHLY EFFICIENT
-- • Excellent capacity utilization across all seasons
-- • Consistent performance with minimal seasonal variation
-- • Well-balanced peak vs off-season operations
-- • Strategy: Optimize & Scale - focus on expansion and fine-tuning
--
-- 0.6-0.8: EFFICIENT
-- • Good capacity utilization with room for improvement
-- • Reasonable seasonal consistency
-- • Balanced operations with some optimization opportunities
-- • Strategy: Improve & Expand - targeted improvements and growth
--
-- 0.4-0.6: MODERATELY EFFICIENT
-- • Moderate capacity utilization with significant inefficiencies
-- • Some seasonal inconsistency
-- • Imbalanced operations requiring attention
-- • Strategy: Review & Restructure - operational review and restructuring
--
-- 0.2-0.4: INEFFICIENT
-- • Poor capacity utilization with major inefficiencies
-- • High seasonal inconsistency
-- • Poorly balanced operations
-- • Strategy: Major Overhaul - significant operational changes needed
--
-- 0.0-0.2: HIGHLY INEFFICIENT
-- • Very poor capacity utilization
-- • Extreme seasonal inconsistency
-- • Severely imbalanced operations
-- • Strategy: Strategic Redesign - complete operational redesign
--
-- METRIC INTERPRETATIONS:
-- 
-- Peak Utilization (0-1):
-- • 0.8-1.0: Excellent peak season capacity utilization
-- • 0.6-0.8: Good peak season utilization
-- • 0.4-0.6: Moderate peak season utilization
-- • <0.4: Poor peak season utilization
--
-- Off-Season Efficiency (0-1):
-- • 0.8-1.0: Excellent off-season capacity utilization
-- • 0.6-0.8: Good off-season utilization
-- • 0.4-0.6: Moderate off-season utilization
-- • <0.4: Poor off-season utilization
--
-- Seasonal Consistency (Higher = Better):
-- • >10: Very consistent performance across seasons
-- • 5-10: Consistent performance
-- • 2-5: Moderate consistency
-- • <2: High seasonal variation
--
-- Capacity Balance (0-1):
-- • 0.8-1.0: Excellent balance between peak and off-season
-- • 0.6-0.8: Good balance
-- • 0.4-0.6: Moderate balance
-- • <0.4: Poor balance (over-reliant on peak season)
--
-- STRATEGIC RECOMMENDATIONS:
-- 
-- OPTIMIZE & SCALE (Top 20% markets):
-- • Focus on expansion and market penetration
-- • Leverage efficiency for competitive advantage
-- • Share best practices with other markets
-- • Invest in technology and innovation
--
-- IMPROVE & EXPAND (21-40% markets):
-- • Identify and address specific inefficiencies
-- • Implement targeted improvements
-- • Expand successful operations
-- • Benchmark against top performers
--
-- REVIEW & RESTRUCTURE (41-60% markets):
-- • Conduct comprehensive operational review
-- • Restructure processes and systems
-- • Address seasonal imbalances
-- • Implement efficiency improvement programs
--
-- MAJOR OVERHAUL (61-80% markets):
-- • Significant operational changes required
-- • Redesign capacity management systems
-- • Address fundamental inefficiencies
-- • Consider strategic partnerships
--
-- STRATEGIC REDESIGN (Bottom 20% markets):
-- • Complete operational redesign needed
-- • Fundamental business model review
-- • Consider market exit or repositioning
-- • Seek external expertise and support
--
-- KEY BUSINESS APPLICATIONS:
-- 
-- FOR TOURISM BOARDS & GOVERNMENTS:
-- • Identify markets needing efficiency support
-- • Allocate resources based on efficiency potential
-- • Develop targeted efficiency improvement programs
-- • Benchmark performance across markets
--
-- FOR HOTEL CHAINS & ACCOMMODATION PROVIDERS:
-- • Identify markets for operational improvement
-- • Optimize capacity management strategies
-- • Develop seasonal pricing strategies
-- • Allocate resources based on efficiency
--
-- FOR AIRLINES & TRANSPORTATION COMPANIES:
-- • Optimize route planning based on efficiency
-- • Develop seasonal capacity strategies
-- • Identify markets for operational improvement
-- • Allocate fleet resources efficiently
--
-- FOR TRAVEL AGENCIES & TOUR OPERATORS:
-- • Focus on efficient markets for expansion
-- • Develop products for inefficient markets
-- • Adjust pricing strategies based on efficiency
-- • Allocate sales resources strategically
--
-- FOR INVESTORS & FINANCIAL INSTITUTIONS:
-- • Identify investment opportunities in efficient markets
-- • Assess risk based on market efficiency
-- • Prioritize markets for tourism investments
-- • Monitor efficiency improvements for investment decisions
--
-- EFFICIENCY BENEFITS:
-- This analysis helps identify operational inefficiencies and optimization
-- opportunities in tourism markets, enabling better resource allocation,
-- process improvement, and strategic planning for tourism businesses
-- and policymakers.
-- ===================================================================================== 