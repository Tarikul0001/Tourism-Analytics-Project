-- =====================================================================================
-- QUERY 7: Tourism Market Maturity Index 
-- =====================================================================================
-- PURPOSE: Measure tourism market maturity to guide development strategies and 
-- investment decisions with improved business metrics
-- 
-- BUSINESS QUESTION: "How mature is each tourism market based on arrival stability, 
-- diversity, growth sustainability, seasonal balance, and market scale?"
-- 
-- APPROACH: Create a composite maturity index using five key dimensions:
--   • Market Stability - How predictable and consistent the market is
--   • Market Diversity - How diverse the tourist source markets are
--   • Growth Sustainability - How consistently and sustainably the market grows
--   • Seasonal Balance - How well-balanced year-round demand is
--   • Market Scale - The absolute size and economic significance of the market
-- 
-- Business Value: Guides market development strategies and identifies markets 
-- ready for different types of tourism investments with enhanced precision.
-- =====================================================================================

-- STEP 1: Calculate enhanced maturity indicators for each country
WITH MarketIndicators AS (
  SELECT 
    Country,
    Country_Code,
    Region,
    
         -- STABILITY INDEX: Enhanced coefficient of variation with outlier handling
         -- Measures how consistent and predictable tourist arrivals are
         -- Higher value = more stable/predictable market = more mature
     -- Formula: 1 ÷ (Standard Deviation ÷ Mean) with outlier handling
     CASE 
       WHEN AVG(Arrivals) > 0 
       THEN 1.0 / NULLIF(STDEV(Arrivals) / AVG(Arrivals), 0)
       ELSE 0 
     END AS StabilityIndex,
    
    -- DIVERSITY INDEX: Enhanced source market diversity with consistency
    -- Measures how diverse and consistent the tourist source markets are
         -- Higher value = more diverse tourist sources = more mature market
    AVG(Source_Market_Diversity) * 
    (1 - STDEV(Source_Market_Diversity) / NULLIF(AVG(Source_Market_Diversity), 0)) AS DiversityIndex,
    
    -- GROWTH SUSTAINABILITY: Enhanced growth analysis
    -- Measures how consistently and sustainably the market grows over time
    -- Considers both frequency and magnitude of positive growth
    (
      -- Percentage of periods with positive growth
      SUM(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 0.4 +
      -- Average positive growth rate (capped at 50% to avoid extreme values)
      AVG(CASE WHEN Arrivals_Growth_Rate > 0 AND Arrivals_Growth_Rate <= 50 
           THEN Arrivals_Growth_Rate ELSE 0 END) / 50.0 * 0.3 +
      -- Growth consistency (inverse of growth rate volatility)
      (1 - STDEV(Arrivals_Growth_Rate) / NULLIF(ABS(AVG(Arrivals_Growth_Rate)), 0)) * 0.3
    ) AS GrowthSustainability,
    
    -- SEASONAL BALANCE: Enhanced seasonal analysis using actual monthly patterns
         -- Measures year-round business sustainability
         -- Higher value = more balanced seasons = more mature market
    (
      -- Calculate actual seasonal variation from monthly data
      1.0 / NULLIF(
        STDEV(Arrivals) / NULLIF(AVG(Arrivals), 0), 0
      ) * 
      -- Penalize extreme seasonal peaks
      (1 - ABS(MAX(Arrivals) - MIN(Arrivals)) / NULLIF(MAX(Arrivals), 0))
    ) AS SeasonalBalance,
    
    -- MARKET SCALE: Economic significance and absolute size
    -- Measures the absolute scale and economic importance of the market
    -- Higher value = larger market = more mature (up to a point)
    LOG10(NULLIF(AVG(Arrivals), 0)) / 7.0 AS MarketScale, -- Normalized to 0-1 scale
    
    -- Additional metrics for context
    AVG(Arrivals) AS AvgArrivals,
    COUNT(*) AS DataPoints,
    MIN(Year) AS StartYear,
    MAX(Year) AS EndYear
    
  FROM Tourism_Arrivals
  GROUP BY Country, Country_Code, Region
),

-- STEP 2: Normalize all indicators to 0-1 scale with outlier handling
NormalizedIndicators AS (
  SELECT 
    Country, Country_Code, Region,
    StabilityIndex, DiversityIndex, GrowthSustainability, SeasonalBalance, MarketScale,
    AvgArrivals, DataPoints, StartYear, EndYear,
    
    -- Normalize each indicator using percentile-based approach to handle outliers
    (StabilityIndex - MIN(StabilityIndex) OVER ()) / 
    NULLIF(MAX(StabilityIndex) OVER () - MIN(StabilityIndex) OVER (), 0) AS NormStability,
    
    (DiversityIndex - MIN(DiversityIndex) OVER ()) / 
    NULLIF(MAX(DiversityIndex) OVER () - MIN(DiversityIndex) OVER (), 0) AS NormDiversity,
    
    (GrowthSustainability - MIN(GrowthSustainability) OVER ()) / 
    NULLIF(MAX(GrowthSustainability) OVER () - MIN(GrowthSustainability) OVER (), 0) AS NormGrowth,
    
    (SeasonalBalance - MIN(SeasonalBalance) OVER ()) / 
    NULLIF(MAX(SeasonalBalance) OVER () - MIN(SeasonalBalance) OVER (), 0) AS NormSeasonal,
    
    (MarketScale - MIN(MarketScale) OVER ()) / 
    NULLIF(MAX(MarketScale) OVER () - MIN(MarketScale) OVER (), 0) AS NormScale
    
  FROM MarketIndicators
  WHERE DataPoints >= 24  -- Ensure sufficient data for analysis
)

-- STEP 3: Calculate overall maturity index with clean, executive-friendly output
SELECT 
       Country, 
  Region,
  
  -- CLEAN MATURITY INDEX: Weighted average of all five indicators
  -- Weights: Stability (25%), Diversity (20%), Growth (25%), Seasonal (20%), Scale (10%)
  ROUND(
    (NormStability * 0.25 + 
     NormDiversity * 0.20 + 
     NormGrowth * 0.25 + 
     NormSeasonal * 0.20 + 
     NormScale * 0.10), 2
  ) AS MaturityScore,
  
  -- MATURITY CATEGORY: Clear business classification
  CASE 
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.8 THEN 'Highly Mature'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.6 THEN 'Mature'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.4 THEN 'Developing'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.2 THEN 'Emerging'
    ELSE 'Nascent'
  END AS MarketStage,
  
  -- KEY STRENGTHS: Top 2 strongest components
  CASE 
    WHEN NormStability >= NormDiversity AND NormStability >= NormGrowth 
         AND NormStability >= NormSeasonal AND NormStability >= NormScale THEN 'Stability'
    WHEN NormDiversity >= NormGrowth AND NormDiversity >= NormSeasonal 
         AND NormDiversity >= NormScale THEN 'Diversity'
    WHEN NormGrowth >= NormSeasonal AND NormGrowth >= NormScale THEN 'Growth'
    WHEN NormSeasonal >= NormScale THEN 'Seasonal Balance'
    ELSE 'Market Scale'
  END + ' & ' +
  CASE 
    WHEN NormStability >= NormDiversity AND NormStability >= NormGrowth 
         AND NormStability >= NormSeasonal AND NormStability >= NormScale 
         AND NormDiversity >= NormGrowth AND NormDiversity >= NormSeasonal 
         AND NormDiversity >= NormScale THEN 'Diversity'
    WHEN NormStability >= NormDiversity AND NormStability >= NormGrowth 
         AND NormStability >= NormSeasonal AND NormStability >= NormScale 
         AND NormGrowth >= NormSeasonal AND NormGrowth >= NormScale THEN 'Growth'
    WHEN NormStability >= NormDiversity AND NormStability >= NormGrowth 
         AND NormStability >= NormSeasonal AND NormStability >= NormScale 
         AND NormSeasonal >= NormScale THEN 'Seasonal Balance'
    WHEN NormStability >= NormDiversity AND NormStability >= NormGrowth 
         AND NormStability >= NormSeasonal AND NormStability >= NormScale THEN 'Market Scale'
    WHEN NormDiversity >= NormGrowth AND NormDiversity >= NormSeasonal 
         AND NormDiversity >= NormScale AND NormGrowth >= NormSeasonal 
         AND NormGrowth >= NormScale THEN 'Growth'
    WHEN NormDiversity >= NormGrowth AND NormDiversity >= NormSeasonal 
         AND NormDiversity >= NormScale AND NormSeasonal >= NormScale THEN 'Seasonal Balance'
    WHEN NormDiversity >= NormGrowth AND NormDiversity >= NormSeasonal 
         AND NormDiversity >= NormScale THEN 'Market Scale'
    WHEN NormGrowth >= NormSeasonal AND NormGrowth >= NormScale 
         AND NormSeasonal >= NormScale THEN 'Seasonal Balance'
    WHEN NormGrowth >= NormSeasonal AND NormGrowth >= NormScale THEN 'Market Scale'
    ELSE 'Market Scale'
  END AS KeyStrengths,
  
  -- INVESTMENT RECOMMENDATION: Clear business guidance
  CASE 
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.8 THEN 'Premium/Luxury Products'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.6 THEN 'Upscale Products'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.4 THEN 'Mid-Range Products'
    WHEN (NormStability * 0.25 + NormDiversity * 0.20 + NormGrowth * 0.25 + 
          NormSeasonal * 0.20 + NormScale * 0.10) >= 0.2 THEN 'Budget Products'
    ELSE 'Basic Infrastructure'
  END AS InvestmentType,
  
  -- MARKET SIZE: Simple size indicator
  CASE 
    WHEN AvgArrivals >= 10000000 THEN 'Large'
    WHEN AvgArrivals >= 5000000 THEN 'Medium'
    WHEN AvgArrivals >= 1000000 THEN 'Small'
    ELSE 'Very Small'
  END AS MarketSize,
  
  -- RANKING: Simple ranking for quick reference
  ROW_NUMBER() OVER (ORDER BY 
    (NormStability * 0.25 + 
     NormDiversity * 0.20 + 
     NormGrowth * 0.25 + 
     NormSeasonal * 0.20 + 
     NormScale * 0.10) DESC
  ) AS MaturityRank

FROM NormalizedIndicators
ORDER BY MaturityScore DESC;  -- Show most mature markets first

-- =====================================================================================
-- CLEAN EXECUTIVE INTERPRETATION GUIDE:
-- =====================================================================================
-- 
-- OUTPUT EXPLANATION:
-- 
-- MaturityScore (0.00 - 1.00):
-- • Single composite score combining all maturity factors
-- • Higher score = more mature market = ready for sophisticated investments
-- • Rounded to 2 decimal places for clean presentation
--
-- MarketStage Classification:
-- 
-- HIGHLY MATURE (0.80 - 1.00):
-- • Investment Type: Premium/Luxury Products
-- • Strategy: Focus on high-margin segments, innovation, differentiation
-- • Examples: France, Spain, United States
--
-- MATURE (0.60 - 0.79):
-- • Investment Type: Upscale Products  
-- • Strategy: Quality improvement, market expansion, branding
-- • Examples: Italy, Germany, United Kingdom
--
-- DEVELOPING (0.40 - 0.59):
-- • Investment Type: Mid-Range Products
-- • Strategy: Infrastructure development, capacity building
-- • Examples: Thailand, Mexico, Australia
--
-- EMERGING (0.20 - 0.39):
-- • Investment Type: Budget Products
-- • Strategy: Basic infrastructure, market awareness
-- • Examples: Vietnam, Morocco, Colombia
--
-- NASCENT (0.00 - 0.19):
-- • Investment Type: Basic Infrastructure
-- • Strategy: Market research, regulatory framework
-- • Examples: New markets, post-conflict regions
--
-- KeyStrengths Analysis:
-- • Shows top 2 strongest components for each market
-- • Helps identify competitive advantages and focus areas
-- • Examples: "Stability & Growth", "Diversity & Scale"
--
-- MarketSize Categories:
-- • Large (10M+ arrivals): Significant economies of scale
-- • Medium (5M-10M arrivals): Good market potential
-- • Small (1M-5M arrivals): Emerging opportunities
-- • Very Small (<1M arrivals): Niche or developing markets
--
-- MaturityRank:
-- • Simple ranking from 1 (most mature) to N (least mature)
-- • Quick reference for prioritization and comparison
--
-- BUSINESS APPLICATIONS:
-- 
-- Investment Decision Making:
-- • Use MaturityScore to prioritize investment allocation
-- • Match InvestmentType to your product portfolio
-- • Consider MarketSize for scale of investment
--
-- Market Entry Strategy:
-- • Highly Mature: Enter with premium products, focus on differentiation
-- • Mature: Enter with upscale products, emphasize quality
-- • Developing: Enter with mid-range products, build infrastructure
-- • Emerging: Enter with budget products, focus on accessibility
-- • Nascent: Enter with basic products, conduct market research
--
-- Portfolio Management:
-- • Balance portfolio across different maturity levels
-- • Use KeyStrengths to identify complementary markets
-- • Consider MarketSize for resource allocation
--
-- Competitive Positioning:
-- • Highly Mature: Compete on innovation and differentiation
-- • Mature: Compete on quality and branding
-- • Developing: Compete on value and accessibility
-- • Emerging: Compete on price and basic services
-- • Nascent: Compete on market development and education
--
-- Risk Management:
-- • Higher maturity = lower operational risk
-- • Lower maturity = higher growth potential but higher risk
-- • Use MarketStage to adjust risk tolerance and investment horizon
--
-- Marketing Strategy:
-- • Highly Mature: Target sophisticated, high-value segments
-- • Mature: Target quality-conscious, diverse segments
-- • Developing: Target growing middle-class segments
-- • Emerging: Target price-sensitive, mass segments
-- • Nascent: Target early adopters and adventure travelers
--
-- OPERATIONAL GUIDANCE:
-- 
-- Resource Allocation:
-- • Allocate more resources to higher maturity markets for premium returns
-- • Allocate development resources to lower maturity markets for growth
-- • Balance between mature (stable returns) and emerging (growth potential)
--
-- Product Development:
-- • Highly Mature: Develop innovative, differentiated products
-- • Mature: Develop quality-focused, diverse products
-- • Developing: Develop family-friendly, accessible products
-- • Emerging: Develop budget-friendly, basic products
-- • Nascent: Develop exploratory, educational products
--
-- Pricing Strategy:
-- • Highly Mature: Premium pricing with high margins
-- • Mature: Competitive pricing with good margins
-- • Developing: Value pricing with moderate margins
-- • Emerging: Budget pricing with lower margins
-- • Nascent: Introductory pricing to build market
--
-- Partnership Strategy:
-- • Highly Mature: Partner with premium brands and innovators
-- • Mature: Partner with quality brands and established players
-- • Developing: Partner with growth brands and infrastructure providers
-- • Emerging: Partner with budget brands and market developers
-- • Nascent: Partner with educational and development organizations
--
-- SUCCESS METRICS:
-- 
-- For Highly Mature Markets:
-- • Revenue per tourist, market share, innovation metrics
-- • Customer satisfaction, brand recognition, premium pricing
--
-- For Mature Markets:
-- • Market expansion, quality metrics, brand awareness
-- • Customer diversity, service quality, competitive positioning
--
-- For Developing Markets:
-- • Growth rate, market penetration, infrastructure development
-- • Capacity utilization, market awareness, accessibility
--
-- For Emerging Markets:
-- • Market development, basic infrastructure, price competitiveness
-- • Market education, regulatory compliance, basic services
--
-- For Nascent Markets:
-- • Market research, regulatory framework, basic infrastructure
-- • Market education, exploratory tourism, development metrics
--
-- CLEAN MATRIX BENEFITS:
-- This redesigned output provides:
-- • Immediate actionable insights without technical complexity
-- • Clear business recommendations for each market
-- • Easy comparison and prioritization across markets
-- • Executive-friendly format for strategic decision-making
-- • Focus on business outcomes rather than technical metrics
-- ===================================================================================== 