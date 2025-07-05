-- =====================================================================================
-- QUERY 8: Dynamic Pricing Optimization Potential
-- =====================================================================================
-- PURPOSE: Identify markets with the highest potential for revenue optimization 
-- through dynamic pricing strategies with executive-friendly insights
-- 
-- BUSINESS QUESTION: "What is the revenue optimization opportunity for each country 
-- based on seasonal demand elasticity and capacity utilization patterns?"
-- 
-- APPROACH: Analyze pricing optimization potential using three key factors:
--   • Demand Elasticity - How responsive demand is to price changes
--   • Capacity Utilization - How efficiently current capacity is being used
--   • Seasonal Variation - How much demand varies across seasons
--   • Optimization Score - Combines all factors for opportunity assessment
-- 
-- Business Value: Identifies revenue optimization opportunities and dynamic pricing 
-- strategies for hotels, airlines, and tourism operators with immediate actionable insights.
-- =====================================================================================

-- STEP 1: Calculate seasonal demand and capacity utilization metrics
WITH SeasonalDemand AS (
  SELECT Country, Year, Month,
         -- DEMAND: Actual tourist arrivals in each period
         Arrivals AS Demand,
         
         -- CAPACITY: Peak season arrivals as proxy for maximum capacity
         Peak_Season_Arrivals AS Capacity,
         
         -- UTILIZATION RATE: How much of peak capacity is being used
         -- Formula: Actual Demand ÷ Peak Capacity
         -- Higher rate = more efficient capacity utilization
         Arrivals * 1.0 / NULLIF(Peak_Season_Arrivals, 0) AS UtilizationRate
  FROM Tourism_Arrivals
),

-- STEP 2: Calculate demand elasticity and utilization efficiency metrics
-- These measure how responsive demand is to changes and how efficiently capacity is used
DemandElasticity AS (
  SELECT Country,
         -- DEMAND ELASTICITY: Approximation using demand variation
         -- Measures how much demand varies relative to average demand
         -- Higher elasticity = more responsive to price changes = better for dynamic pricing
         -- Formula: Standard Deviation ÷ Mean of utilization rates
         STDEV(UtilizationRate) / NULLIF(AVG(UtilizationRate), 0) AS DemandElasticity,
         
         -- AVERAGE UTILIZATION: Mean capacity utilization across all periods
         -- Lower utilization = more room for price optimization
         AVG(UtilizationRate) AS AvgUtilization,
         
         -- SEASONAL VARIATION: Range of utilization variation across seasons
         -- Higher variation = more opportunity for seasonal pricing strategies
         -- Formula: (Maximum - Minimum) ÷ Average utilization
         (MAX(UtilizationRate) - MIN(UtilizationRate)) / NULLIF(AVG(UtilizationRate), 0) AS SeasonalVariation,
         
         -- Additional context metrics
         AVG(Demand) AS AvgArrivals,
         COUNT(*) AS DataPoints
  FROM SeasonalDemand
  GROUP BY Country
),

-- STEP 3: Calculate overall optimization potential score
-- This combines all factors to identify markets with highest pricing optimization opportunity
OptimizationScore AS (
  SELECT Country, DemandElasticity, AvgUtilization, SeasonalVariation, AvgArrivals, DataPoints,
         -- OPTIMIZATION POTENTIAL: Combined score for dynamic pricing opportunity
         -- Formula: Demand Elasticity × (1 - Average Utilization) × Seasonal Variation
         -- Higher score = better opportunity for dynamic pricing strategies
         -- • High elasticity = demand responds to price changes
         -- • Low utilization = room for price increases
         -- • High variation = opportunity for seasonal pricing
         DemandElasticity * (1 - AvgUtilization) * SeasonalVariation AS OptimizationPotential
  FROM DemandElasticity
  WHERE DataPoints >= 24  -- Ensure sufficient data for analysis
)

-- STEP 4: Generate clean, executive-friendly output
SELECT 
  Country,
  
  -- CLEAN OPTIMIZATION SCORE: Single composite score (0-1 scale)
  ROUND(OptimizationPotential, 2) AS PricingOpportunityScore,
  
  -- PRICING STRATEGY: Clear business recommendation
  CASE 
    WHEN OptimizationPotential >= 0.5 THEN 'Aggressive Dynamic Pricing'
    WHEN OptimizationPotential >= 0.3 THEN 'Moderate Dynamic Pricing'
    WHEN OptimizationPotential >= 0.1 THEN 'Minimal Dynamic Pricing'
    ELSE 'Focus on Capacity Expansion'
  END AS PricingStrategy,
  
  -- REVENUE OPPORTUNITY: Business impact assessment
  CASE 
    WHEN OptimizationPotential >= 0.5 THEN 'High Revenue Potential'
    WHEN OptimizationPotential >= 0.3 THEN 'Good Revenue Potential'
    WHEN OptimizationPotential >= 0.1 THEN 'Limited Revenue Potential'
    ELSE 'Minimal Revenue Potential'
  END AS RevenueOpportunity,
  
  -- KEY DRIVERS: Top factors driving the opportunity
  CASE 
    WHEN DemandElasticity >= AvgUtilization AND DemandElasticity >= SeasonalVariation THEN 'Demand Elasticity'
    WHEN AvgUtilization <= DemandElasticity AND AvgUtilization <= SeasonalVariation THEN 'Low Utilization'
    WHEN SeasonalVariation >= DemandElasticity AND SeasonalVariation >= AvgUtilization THEN 'Seasonal Variation'
    WHEN DemandElasticity >= AvgUtilization THEN 'Demand Elasticity'
    ELSE 'Low Utilization'
  END + ' & ' +
  CASE 
    WHEN DemandElasticity >= AvgUtilization AND DemandElasticity >= SeasonalVariation 
         AND AvgUtilization <= SeasonalVariation THEN 'Low Utilization'
    WHEN DemandElasticity >= AvgUtilization AND DemandElasticity >= SeasonalVariation 
         AND SeasonalVariation <= AvgUtilization THEN 'Seasonal Variation'
    WHEN AvgUtilization <= DemandElasticity AND AvgUtilization <= SeasonalVariation 
         AND DemandElasticity >= SeasonalVariation THEN 'Demand Elasticity'
    WHEN AvgUtilization <= DemandElasticity AND AvgUtilization <= SeasonalVariation 
         AND SeasonalVariation >= DemandElasticity THEN 'Seasonal Variation'
    WHEN SeasonalVariation >= DemandElasticity AND SeasonalVariation >= AvgUtilization 
         AND DemandElasticity >= AvgUtilization THEN 'Demand Elasticity'
    WHEN SeasonalVariation >= DemandElasticity AND SeasonalVariation >= AvgUtilization 
         AND AvgUtilization >= DemandElasticity THEN 'Low Utilization'
    WHEN DemandElasticity >= AvgUtilization THEN 'Seasonal Variation'
    ELSE 'Demand Elasticity'
  END AS KeyDrivers,
  
  -- MARKET SIZE: Simple size indicator for context
  CASE 
    WHEN AvgArrivals >= 10000000 THEN 'Large'
    WHEN AvgArrivals >= 5000000 THEN 'Medium'
    WHEN AvgArrivals >= 1000000 THEN 'Small'
    ELSE 'Very Small'
  END AS MarketSize,
  
  -- IMPLEMENTATION PRIORITY: Clear prioritization guidance
  CASE 
    WHEN OptimizationPotential >= 0.5 THEN 'High Priority'
    WHEN OptimizationPotential >= 0.3 THEN 'Medium Priority'
    WHEN OptimizationPotential >= 0.1 THEN 'Low Priority'
    ELSE 'No Priority'
  END AS ImplementationPriority,
  
  -- RANKING: Simple ranking for quick reference
  ROW_NUMBER() OVER (ORDER BY OptimizationPotential DESC) AS OpportunityRank

FROM OptimizationScore
ORDER BY PricingOpportunityScore DESC;  -- Show highest opportunities first

-- =====================================================================================
-- CLEAN EXECUTIVE INTERPRETATION GUIDE:
-- =====================================================================================
-- 
-- OUTPUT EXPLANATION:
-- 
-- PricingOpportunityScore (0.00 - 1.00):
-- • Single composite score for dynamic pricing optimization potential
-- • Higher score = greater opportunity for revenue optimization
-- • Combines demand elasticity, capacity utilization, and seasonal variation
--
-- PricingStrategy Recommendations:
-- 
-- AGGRESSIVE DYNAMIC PRICING (0.50 - 1.00):
-- • Implement sophisticated dynamic pricing algorithms
-- • Use significant price premiums during peak periods
-- • Focus on revenue optimization over volume
-- • High Priority implementation
--
-- MODERATE DYNAMIC PRICING (0.30 - 0.49):
-- • Implement moderate seasonal pricing adjustments
-- • Use targeted price increases during high-demand periods
-- • Balance revenue optimization with market share
-- • Medium Priority implementation
--
-- MINIMAL DYNAMIC PRICING (0.10 - 0.29):
-- • Use minimal price variations
-- • Focus on efficiency and market share
-- • Limited pricing optimization opportunities
-- • Low Priority implementation
--
-- FOCUS ON CAPACITY EXPANSION (0.00 - 0.09):
-- • Prioritize capacity expansion over pricing optimization
-- • Focus on market share and volume
-- • Develop alternative revenue streams
-- • No Priority for pricing optimization
--
-- RevenueOpportunity Assessment:
-- • High Revenue Potential: Significant opportunity for revenue optimization
-- • Good Revenue Potential: Moderate opportunity for revenue improvement
-- • Limited Revenue Potential: Small opportunity for revenue gains
-- • Minimal Revenue Potential: Focus on other strategies
--
-- KeyDrivers Analysis:
-- • Shows top 2 factors driving the pricing opportunity
-- • Helps identify specific areas to focus on
-- • Examples: "Demand Elasticity & Low Utilization", "Seasonal Variation & Demand Elasticity"
--
-- MarketSize Context:
-- • Large: Significant economies of scale for pricing strategies
-- • Medium: Good market potential for pricing optimization
-- • Small: Emerging opportunities for pricing strategies
-- • Very Small: Niche markets with limited pricing flexibility
--
-- ImplementationPriority:
-- • High Priority: Implement pricing strategies immediately
-- • Medium Priority: Implement pricing strategies in next planning cycle
-- • Low Priority: Consider pricing strategies for future planning
-- • No Priority: Focus on other business strategies
--
-- BUSINESS APPLICATIONS:
-- 
-- Revenue Management Strategy:
-- • Use PricingOpportunityScore to prioritize markets for dynamic pricing
-- • Match PricingStrategy to your revenue management capabilities
-- • Consider MarketSize for scale of pricing initiatives
--
-- Pricing Implementation:
-- • Aggressive Dynamic Pricing: Implement sophisticated pricing algorithms
-- • Moderate Dynamic Pricing: Implement seasonal pricing adjustments
-- • Minimal Dynamic Pricing: Focus on efficiency and market share
-- • Capacity Expansion: Focus on infrastructure and capacity development
--
-- Resource Allocation:
-- • Allocate more resources to high-priority markets
-- • Invest in pricing technology for high-opportunity markets
-- • Focus on capacity development for low-opportunity markets
-- • Balance between revenue optimization and market expansion
--
-- Competitive Positioning:
-- • High Opportunity: Compete on pricing sophistication and revenue optimization
-- • Medium Opportunity: Compete on balanced pricing and market share
-- • Low Opportunity: Compete on efficiency and volume
-- • No Opportunity: Compete on capacity and market development
--
-- OPERATIONAL GUIDANCE:
-- 
-- Technology Investment:
-- • High Priority: Invest in sophisticated pricing algorithms and systems
-- • Medium Priority: Invest in seasonal pricing tools and analytics
-- • Low Priority: Invest in basic pricing optimization tools
-- • No Priority: Invest in capacity and infrastructure development
--
-- Team Development:
-- • High Priority: Develop revenue management and pricing expertise
-- • Medium Priority: Develop seasonal pricing and analytics capabilities
-- • Low Priority: Develop efficiency and operational expertise
-- • No Priority: Develop capacity planning and market development skills
--
-- Partnership Strategy:
-- • High Priority: Partner with pricing technology providers and revenue management experts
-- • Medium Priority: Partner with analytics providers and seasonal pricing specialists
-- • Low Priority: Partner with operational efficiency and market development experts
-- • No Priority: Partner with infrastructure and capacity development providers
--
-- SUCCESS METRICS:
-- 
-- For High Opportunity Markets:
-- • Revenue per available room/capacity, pricing optimization metrics
-- • Dynamic pricing effectiveness, seasonal revenue improvement
--
-- For Medium Opportunity Markets:
-- • Seasonal pricing effectiveness, revenue growth, market share
-- • Pricing optimization metrics, customer satisfaction
--
-- For Low Opportunity Markets:
-- • Operational efficiency, market share, volume growth
-- • Capacity utilization, cost optimization
--
-- For No Opportunity Markets:
-- • Capacity expansion, market development, infrastructure growth
-- • Market penetration, operational efficiency
--
-- CLEAN MATRIX BENEFITS:
-- This redesigned output provides:
-- • Immediate actionable insights for pricing strategy decisions
-- • Clear business recommendations for each market
-- • Easy prioritization of pricing optimization opportunities
-- • Executive-friendly format for revenue management decisions
-- • Focus on business outcomes rather than technical metrics
-- ===================================================================================== 