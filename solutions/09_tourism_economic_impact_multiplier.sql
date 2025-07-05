-- =====================================================================================
-- QUERY 9: Tourism Economic Impact Multiplier
-- =====================================================================================
-- PURPOSE: Estimate the economic multiplier effect of tourism for each market to 
-- quantify broader economic impact
-- 
-- BUSINESS QUESTION: "What is the estimated economic multiplier effect for each 
-- country based on arrival growth, diversity, and market stability?"
-- 
-- APPROACH: Calculate economic multiplier using four key factors:
--   • Growth Momentum - How fast tourism is expanding
--   • Economic Diversity - How diverse tourist sources are (economic spread)
--   • Market Stability - How predictable and stable the market is (IMPROVED)
--   • Market Scale - Size of the tourism market
--   • Multiplier Formula - Combines all factors for economic impact estimation
-- 
-- Business Value: Quantifies the broader economic impact of tourism development 
-- and guides investment prioritization.
-- =====================================================================================

-- STEP 1: Calculate key economic indicators for each country
-- These factors determine how much economic impact tourism generates
WITH EconomicIndicators AS (
  SELECT Country,
         -- GROWTH MOMENTUM: Average growth rate of tourist arrivals
         -- Higher growth = more economic activity and job creation
         AVG(Arrivals_Growth_Rate) AS GrowthMomentum,
         
         -- ECONOMIC DIVERSITY: Average source market diversity
         -- Higher diversity = broader economic impact across multiple source markets
         -- Reduces dependency on single markets and spreads economic benefits
         AVG(Source_Market_Diversity) AS EconomicDiversity,
         
         -- MARKET STABILITY: Improved calculation using coefficient of variation
         -- Higher stability = more predictable economic impact
         -- Stable markets provide consistent economic benefits over time
         -- Formula: 1 ÷ (Coefficient of Variation + 0.1) to avoid division by zero
         -- Coefficient of Variation = Standard Deviation / Mean
         -- Adding 0.1 prevents division by zero and provides meaningful scale
         1.0 / (NULLIF(STDEV(Arrivals), 0) / NULLIF(AVG(Arrivals), 0) + 0.1) AS MarketStability,
         
         -- MARKET SCALE: Average number of tourist arrivals
         -- Larger markets have different economic multiplier effects
         -- Scale affects infrastructure development and economic integration
         AVG(Arrivals) AS MarketScale,
         
         -- ADDITIONAL: Coefficient of Variation for volatility assessment
         -- Lower values = more stable, higher values = more volatile
         NULLIF(STDEV(Arrivals), 0) / NULLIF(AVG(Arrivals), 0) AS CoefficientOfVariation
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Calculate economic multiplier using improved formula
-- This estimates how much economic activity is generated per dollar of tourism spending
MultiplierCalculation AS (
  SELECT Country, GrowthMomentum, EconomicDiversity, MarketStability, MarketScale, CoefficientOfVariation,
         -- ECONOMIC MULTIPLIER: Estimated economic impact multiplier
         -- Base multiplier: 1.5 (standard tourism multiplier)
         1.5 +
         -- Growth premium: 0.1 for each 10% growth rate
         -- Growing markets generate more economic activity
         (GrowthMomentum / 10.0) * 0.1 +
         -- Diversity premium: 0.2 for high diversity
         -- Diverse markets spread economic benefits more broadly
         EconomicDiversity * 0.2 +
         -- Stability premium: 0.1 for high stability (improved scaling)
         -- Stable markets provide consistent economic benefits
         -- Using MarketStability directly (already scaled appropriately)
         MarketStability * 0.1 AS EconomicMultiplier
  FROM EconomicIndicators
)

-- STEP 3: Rank markets by economic multiplier and categorize them
SELECT 
       Country, 
       ROUND(GrowthMomentum, 2) AS GrowthMomentum,            -- Average growth rate (%)
       ROUND(EconomicDiversity, 2) AS EconomicDiversity,      -- Tourist source diversity
       ROUND(MarketStability, 2) AS MarketStability,          -- Market stability score (improved)
       ROUND(CoefficientOfVariation, 2) AS CoefficientOfVariation, -- Volatility measure
       ROUND(MarketScale, 2) AS MarketScale,                  -- Average market size
       ROUND(EconomicMultiplier, 2) AS EconomicMultiplier,    -- Economic impact multiplier
       
       -- STABILITY CATEGORY: Classify markets by stability level
       CASE 
         WHEN CoefficientOfVariation IS NULL THEN 'Insufficient Data'
         WHEN CoefficientOfVariation <= 0.3 THEN 'Highly Stable'
         WHEN CoefficientOfVariation <= 0.6 THEN 'Moderately Stable'
         WHEN CoefficientOfVariation <= 1.0 THEN 'Moderately Volatile'
         WHEN CoefficientOfVariation <= 1.5 THEN 'Highly Volatile'
         ELSE 'Extremely Volatile'
       END AS StabilityCategory,
       
       -- MULTIPLIER QUINTILE: Rank markets into 5 groups by economic impact potential
       NTILE(5) OVER (ORDER BY EconomicMultiplier DESC) AS MultiplierQuintile
FROM MultiplierCalculation
ORDER BY EconomicMultiplier DESC;  -- Show highest economic impact markets first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- IMPROVED Market Stability Interpretation:
-- 
-- When MarketStability is zero or very low, it indicates:
-- • EXTREME VOLATILITY: The market experiences massive swings in tourist arrivals
-- • UNPREDICTABLE ECONOMIC IMPACT: Difficult to plan infrastructure and employment
-- • HIGH RISK: Economic benefits are inconsistent and unreliable
-- • INVESTMENT CHALLENGES: Hard to justify long-term tourism investments
--
-- Stability Categories:
-- 
-- HIGHLY STABLE (CV ≤ 0.3):
-- • Characteristics: Consistent arrival patterns, predictable economic impact
-- • Economic Planning: Easy to plan infrastructure and employment
-- • Investment Appeal: High - reliable economic returns
-- • Example: Mature markets with steady tourism flows
--
-- MODERATELY STABLE (CV 0.3-0.6):
-- • Characteristics: Some seasonal variation but generally predictable
-- • Economic Planning: Good for planning with some seasonal adjustments
-- • Investment Appeal: Good - reasonably reliable returns
-- • Example: Markets with clear seasonal patterns
--
-- MODERATELY VOLATILE (CV 0.6-1.0):
-- • Characteristics: Significant variation, requires careful planning
-- • Economic Planning: Need robust planning with contingency measures
-- • Investment Appeal: Moderate - higher risk but manageable
-- • Example: Markets recovering from crises or with emerging tourism
--
-- HIGHLY VOLATILE (CV 1.0-1.5):
-- • Characteristics: Major swings, difficult to predict economic impact
-- • Economic Planning: Requires sophisticated risk management
-- • Investment Appeal: Low - high risk, uncertain returns
-- • Example: Markets with political instability or major external shocks
--
-- EXTREMELY VOLATILE (CV > 1.5):
-- • Characteristics: Massive swings, unpredictable economic impact
-- • Economic Planning: Very difficult to plan effectively
-- • Investment Appeal: Very low - extremely high risk
-- • Example: Markets during major crises or with severe instability
--
-- Business Implications of Zero/Low Market Stability:
-- 
-- FOR TOURISM BOARDS & GOVERNMENTS:
-- • Focus on crisis management and recovery planning
-- • Develop flexible tourism policies that can adapt to volatility
-- • Consider alternative economic development strategies
-- • Implement robust monitoring and early warning systems
--
-- FOR INVESTORS & BUSINESSES:
-- • Avoid long-term infrastructure investments
-- • Focus on flexible, scalable tourism operations
-- • Implement strong risk management strategies
-- • Consider short-term, opportunistic investments only
--
-- FOR POLICY MAKERS:
-- • Develop tourism policies that address volatility causes
-- • Implement economic diversification strategies
-- • Focus on building tourism resilience and recovery capacity
-- • Consider alternative economic sectors for development
--
-- Economic Multiplier Interpretation (Updated):
-- 
-- HIGH MULTIPLIER (> 2.0):
-- • Characteristics: High growth, diverse sources, stable market, large scale
-- • Economic Impact: Significant broader economic benefits
-- • Investment Priority: High - substantial economic development potential
-- • Risk Level: Low to moderate
--
-- MEDIUM-HIGH MULTIPLIER (1.7 - 2.0):
-- • Characteristics: Good growth, moderate diversity, stable market
-- • Economic Impact: Strong broader economic benefits
-- • Investment Priority: High - good economic development potential
-- • Risk Level: Low to moderate
--
-- MEDIUM MULTIPLIER (1.5 - 1.7):
-- • Characteristics: Moderate growth, some diversity, reasonable stability
-- • Economic Impact: Standard broader economic benefits
-- • Investment Priority: Medium - typical economic development potential
-- • Risk Level: Moderate
--
-- MEDIUM-LOW MULTIPLIER (1.3 - 1.5):
-- • Characteristics: Low growth, limited diversity, some volatility
-- • Economic Impact: Limited broader economic benefits
-- • Investment Priority: Low - limited economic development potential
-- • Risk Level: High
--
-- LOW MULTIPLIER (< 1.3):
-- • Characteristics: Very low growth, low diversity, high volatility
-- • Economic Impact: Minimal broader economic benefits
-- • Investment Priority: Very low - minimal economic development potential
-- • Risk Level: Very high
--
-- Multiplier Quintile Rankings:
-- 1: Top 20% - Highest economic impact potential (priority investment targets)
-- 2: 21-40% - High economic impact potential (good investment opportunities)
-- 3: 41-60% - Medium economic impact potential (standard investment opportunities)
-- 4: 61-80% - Low economic impact potential (limited investment opportunities)
-- 5: Bottom 20% - Minimal economic impact potential (avoid or specialized focus)
--
-- Key Business Applications:
-- • Investment prioritization and resource allocation
-- • Economic development planning and policy making
-- • Tourism infrastructure investment decisions
-- • Public-private partnership opportunities
-- • Economic impact assessment and reporting
-- • Risk assessment and crisis management planning
--
-- Economic Multiplier Components:
-- 
-- BASE MULTIPLIER (1.5):
-- • Standard tourism economic multiplier
-- • Represents direct and indirect economic effects
-- • Includes accommodation, food, transportation, retail, etc.
--
-- GROWTH PREMIUM:
-- • Additional economic activity from market expansion
-- • Job creation and infrastructure development
-- • Increased local business opportunities
--
-- DIVERSITY PREMIUM:
-- • Broader economic impact across multiple source markets
-- • Reduced dependency on single markets
-- • More stable economic benefits
--
-- STABILITY PREMIUM (IMPROVED):
-- • Consistent economic benefits over time
-- • Predictable economic planning and development
-- • Reduced economic volatility and risk
--
-- Economic Impact Categories:
-- 
-- DIRECT EFFECTS:
-- • Tourist spending on accommodation, food, transportation
-- • Direct employment in tourism sector
-- • Direct business revenue from tourism
--
-- INDIRECT EFFECTS:
-- • Supply chain impacts (food suppliers, transportation, etc.)
-- • Supporting services (banking, insurance, etc.)
-- • Infrastructure development and maintenance
--
-- INDUCED EFFECTS:
-- • Employee spending in local economy
-- • Business investment and expansion
-- • Government revenue and public services
--
-- Investment Strategy by Multiplier Level:
-- 
-- HIGH MULTIPLIER MARKETS:
-- • Prioritize for major tourism investments
-- • Focus on infrastructure development
-- • Develop comprehensive tourism strategies
-- • Target for public-private partnerships
--
-- MEDIUM MULTIPLIER MARKETS:
-- • Moderate investment with careful planning
-- • Focus on specific tourism segments
-- • Develop targeted infrastructure
-- • Monitor economic impact closely
--
-- LOW MULTIPLIER MARKETS:
-- • Limited investment or specialized focus
-- • Focus on niche tourism segments
-- • Minimal infrastructure development
-- • Consider alternative economic development strategies
--
-- Economic Development Benefits:
-- This analysis helps identify markets where tourism development
-- will generate the greatest broader economic benefits, including
-- job creation, infrastructure development, and local business growth.
-- The improved stability measure provides better risk assessment
-- and helps avoid investments in highly volatile markets.
-- ===================================================================================== 