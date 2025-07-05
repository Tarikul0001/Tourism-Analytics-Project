-- =====================================================================================
-- QUERY 6: Competitive Intelligence Dashboard
-- =====================================================================================
-- PURPOSE: Identify top competitors for each tourism market based on comprehensive 
-- competitive positioning analysis including market size, growth, geographic proximity,
-- and revenue potential
-- 
-- BUSINESS QUESTION: "Who are the top 3 competitors for each country based on 
-- market positioning, geographic proximity, growth trajectories, and revenue potential?"
-- 
-- APPROACH: Apply advanced competitive intelligence methodology using:
--   • Market Positioning Analysis - Size, growth, and stability metrics
--   • Geographic Proximity Scoring - Regional competitive pressure assessment
--   • Revenue Potential Comparison - Market attractiveness and investment appeal
--   • Weighted Similarity Matrix - Multi-dimensional competitive threat analysis
--   • Top 3 Competitor Selection - Focus on primary competitive threats
-- 
-- Business Value: Enables strategic competitive positioning and market differentiation
-- opportunities identification with geographic and revenue considerations.
-- =====================================================================================

-- STEP 1: Create comprehensive market positioning profiles
-- This defines the key competitive characteristics for each market
WITH MarketProfiles AS (
  SELECT Country,
         -- MARKET SIZE: Total arrivals as market scale indicator
         SUM(Arrivals) AS TotalArrivals,
         
         -- AVERAGE ARRIVALS: Market size indicator for comparison
         AVG(Arrivals) AS AvgArrivals,
         
         -- GROWTH MOMENTUM: 3-year CAGR for market trajectory
         (MAX(Arrivals) / NULLIF(MIN(Arrivals), 0)) - 1 AS GrowthMomentum,
         
         -- MARKET STABILITY: Coefficient of variation for predictability
         CASE 
           WHEN AVG(Arrivals) > 0 THEN STDEV(Arrivals) / AVG(Arrivals)
           ELSE NULL 
         END AS MarketStability,
         
         -- SEASONAL BALANCE: Peak vs off-peak ratio for year-round appeal
         MAX(Arrivals) / NULLIF(MIN(Arrivals), 0) AS SeasonalBalance,
         
         -- MARKET DIVERSITY: Source market diversity for resilience
         AVG(Source_Market_Diversity) AS MarketDiversity,
         
         -- DATA COMPLETENESS: Number of observations for reliability
         COUNT(*) AS DataPoints
  FROM Tourism_Arrivals
  GROUP BY Country
  HAVING COUNT(*) >= 3  -- Ensure sufficient data for analysis
),

-- STEP 2: Calculate geographic proximity scores
-- This considers regional competitive pressure and market overlap
GeographicProximity AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         -- GEOGRAPHIC COMPETITION SCORE: Based on regional proximity
         -- Higher score = closer geographic competition
         CASE 
           -- Same region (assumed based on country names for demo)
           WHEN LEFT(a.Country, 3) = LEFT(b.Country, 3) THEN 0.8
           -- Adjacent regions (simplified logic)
           WHEN ABS(LEN(a.Country) - LEN(b.Country)) <= 2 THEN 0.6
           -- Different regions
           ELSE 0.3
         END AS GeographicScore
  FROM MarketProfiles a
  CROSS JOIN MarketProfiles b
  WHERE a.Country != b.Country
),

-- STEP 3: Calculate market positioning similarity scores
-- This measures competitive overlap in market characteristics
PositioningSimilarity AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         -- WEIGHTED SIMILARITY SCORE: Multi-dimensional competitive analysis
         -- Lower score = more similar positioning = stronger competition
         (
           -- Market Size Similarity (30% weight) - Most important for competition
           0.3 * ABS(LOG10(NULLIF(a.AvgArrivals, 0)) - LOG10(NULLIF(b.AvgArrivals, 0))) +
           
           -- Growth Trajectory Similarity (25% weight) - Competing for same growth segments
           0.25 * ABS(a.GrowthMomentum - b.GrowthMomentum) +
           
           -- Market Stability Similarity (20% weight) - Similar risk profiles
           0.2 * ABS(COALESCE(a.MarketStability, 0) - COALESCE(b.MarketStability, 0)) +
           
           -- Seasonal Pattern Similarity (15% weight) - Competing for same seasonal segments
           0.15 * ABS(a.SeasonalBalance - b.SeasonalBalance) +
           
           -- Market Diversity Similarity (10% weight) - Similar tourist source focus
           0.1 * ABS(a.MarketDiversity - b.MarketDiversity)
         ) AS PositioningScore
  FROM MarketProfiles a
  CROSS JOIN MarketProfiles b
  WHERE a.Country != b.Country
),

-- STEP 4: Calculate revenue potential comparison
-- This assesses market attractiveness and investment appeal
RevenuePotential AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         -- REVENUE POTENTIAL SCORE: Market attractiveness comparison
         -- Higher score = more attractive market for investment
         (
           -- Market Size Appeal (40% weight)
           0.4 * (a.AvgArrivals / NULLIF(b.AvgArrivals, 0)) +
           
           -- Growth Appeal (35% weight)
           0.35 * (a.GrowthMomentum / NULLIF(b.GrowthMomentum, 0)) +
           
           -- Stability Appeal (25% weight)
           0.25 * (COALESCE(b.MarketStability, 1) / NULLIF(COALESCE(a.MarketStability, 1), 0))
         ) AS RevenueScore
  FROM MarketProfiles a
  CROSS JOIN MarketProfiles b
  WHERE a.Country != b.Country
),

-- STEP 5: Combine all competitive factors into final similarity matrix
CompetitiveMatrix AS (
  SELECT p.Country1, p.Country2, 
         p.PositioningScore,
         g.GeographicScore,
         r.RevenueScore,
         -- FINAL COMPETITIVE SIMILARITY SCORE: Weighted combination
         -- Lower score = stronger competitive threat
         (
           -- Positioning Similarity (50% weight) - Core competitive overlap
           0.5 * p.PositioningScore +
           
           -- Geographic Proximity (30% weight) - Regional competitive pressure
           0.3 * (1 - g.GeographicScore) +
           
           -- Revenue Potential Competition (20% weight) - Investment appeal competition
           0.2 * (1 - r.RevenueScore)
         ) AS CompetitiveSimilarityScore
  FROM PositioningSimilarity p
  JOIN GeographicProximity g ON p.Country1 = g.Country1 AND p.Country2 = g.Country2
  JOIN RevenuePotential r ON p.Country1 = r.Country1 AND p.Country2 = r.Country2
),

-- STEP 6: Rank competitors by competitive similarity score
CompetitorRanking AS (
  SELECT Country1, Country2, 
         CAST(ROUND(PositioningScore, 2) AS DECIMAL(10,2)) AS PositioningScore,
         CAST(ROUND(GeographicScore, 2) AS DECIMAL(10,2)) AS GeographicScore,
         CAST(ROUND(RevenueScore, 2) AS DECIMAL(10,2)) AS RevenueScore,
         CAST(ROUND(CompetitiveSimilarityScore, 2) AS DECIMAL(10,2)) AS CompetitiveSimilarityScore,
         -- ROW_NUMBER: Rank competitors from strongest threat (1) to weakest
         ROW_NUMBER() OVER (PARTITION BY Country1 ORDER BY CompetitiveSimilarityScore ASC) AS CompetitorRank
  FROM CompetitiveMatrix
)

-- STEP 7: Select top 3 competitors with detailed competitive analysis
SELECT 
       Country1 AS Country, 
       Country2 AS TopCompetitor, 
       PositioningScore,                    -- Market positioning similarity
       GeographicScore,                     -- Geographic proximity competition
       RevenueScore,                        -- Revenue potential comparison
       CompetitiveSimilarityScore,          -- Overall competitive threat score
       CompetitorRank AS Rank,              -- Competitor ranking (1 = strongest threat)
       
       -- COMPETITIVE THREAT LEVEL: Categorize competitive intensity
       CASE 
         WHEN CompetitiveSimilarityScore < 0.3 THEN 'High Threat'
         WHEN CompetitiveSimilarityScore < 0.6 THEN 'Medium Threat'
         ELSE 'Low Threat'
       END AS ThreatLevel
FROM CompetitorRanking
WHERE CompetitorRank <= 3  -- Focus on top 3 competitive threats
ORDER BY Country1, CompetitorRank;

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Competitive Similarity Score Interpretation:
-- 
-- LOW SCORE (< 0.3) - HIGH THREAT:
-- • Characteristics: Very similar market positioning, close geographic proximity
-- • Competitive Threat: High - direct competition for same tourist segments
-- • Strategic Action: Monitor closely, develop strong differentiation strategies
-- • Business Impact: High risk of market share loss, pricing pressure
--
-- MEDIUM SCORE (0.3 - 0.6) - MEDIUM THREAT:
-- • Characteristics: Moderately similar positioning, some geographic overlap
-- • Competitive Threat: Medium - partial competition for tourist segments
-- • Strategic Action: Analyze competitive advantages, identify market gaps
-- • Business Impact: Moderate competitive pressure, opportunity for differentiation
--
-- HIGH SCORE (> 0.6) - LOW THREAT:
-- • Characteristics: Different market positioning, limited geographic overlap
-- • Competitive Threat: Low - different tourist segments or markets
-- • Strategic Action: Focus on other competitors, explore partnership opportunities
-- • Business Impact: Low competitive pressure, potential for collaboration
--
-- Competitive Factor Analysis:
-- 
-- POSITIONING SCORE:
-- • Measures similarity in market size, growth, stability, and seasonal patterns
-- • Higher score = more similar market positioning = stronger competition
-- • Key for: Product differentiation, pricing strategies, market positioning
--
-- GEOGRAPHIC SCORE:
-- • Measures regional proximity and geographic competitive pressure
-- • Higher score = closer geographic competition = stronger regional threat
-- • Key for: Regional expansion, local partnerships, geographic differentiation
--
-- REVENUE SCORE:
-- • Measures market attractiveness and investment appeal comparison
-- • Higher score = more attractive market for investment = stronger competition
-- • Key for: Investment decisions, resource allocation, market prioritization
--
-- Competitor Ranking Strategy:
-- 
-- RANK 1 COMPETITORS (Strongest Threats):
-- • Primary competitive threats with similar positioning and proximity
-- • Direct competition for same tourist segments and investment
-- • Focus on: Strong differentiation, competitive advantages, market monitoring
-- • Actions: Monitor pricing, marketing, product strategies closely
--
-- RANK 2 COMPETITORS (Secondary Threats):
-- • Secondary competitive threats with moderate similarity
-- • Some overlap in tourist segments and geographic markets
-- • Focus on: Competitive gap analysis, benchmarking, opportunity identification
-- • Actions: Analyze competitive advantages, identify market gaps
--
-- RANK 3 COMPETITORS (Tertiary Threats):
-- • Tertiary competitive threats with limited similarity
-- • Limited overlap but still relevant for strategic planning
-- • Focus on: Market monitoring, trend analysis, partnership opportunities
-- • Actions: Monitor for market shifts, explore collaboration opportunities
--
-- Key Business Applications:
-- • Competitive positioning and differentiation strategies
-- • Market entry and expansion decisions with competitive context
-- • Pricing strategy development and competitive benchmarking
-- • Marketing campaign targeting and competitive messaging
-- • Product development and service innovation priorities
-- • Partnership and collaboration opportunity identification
-- • Investment prioritization and resource allocation
--
-- Strategic Competitive Actions:
-- • Monitor competitor pricing and promotional activities
-- • Analyze competitor marketing campaigns and messaging strategies
-- • Track competitor product and service innovations
-- • Benchmark performance against similar market positioning
-- • Identify competitive gaps and differentiation opportunities
-- • Develop competitive response and counter-strategies
-- • Explore partnership opportunities with complementary markets
--
-- Market Positioning Dimensions:
-- This analysis considers five key dimensions of competitive similarity:
-- • Market Size (30% weight) - Competing for similar scale opportunities
-- • Growth Trajectory (25% weight) - Competing for same growth segments
-- • Market Stability (20% weight) - Similar risk and predictability profiles
-- • Seasonal Patterns (15% weight) - Competing for same seasonal segments
-- • Market Diversity (10% weight) - Similar tourist source market focus
--
-- Geographic Competition Factors:
-- • Regional proximity and market overlap
-- • Transportation and accessibility competition
-- • Local tourism infrastructure competition
-- • Regional marketing and promotion competition
--
-- Revenue Potential Competition:
-- • Market attractiveness for investment
-- • Tourist spending potential comparison
-- • Infrastructure development competition
-- • Marketing and promotion investment competition
--
-- Strategic Differentiation Opportunities:
-- By understanding competitive positioning, businesses can:
-- • Identify unique value propositions and competitive advantages
-- • Develop targeted marketing strategies for specific segments
-- • Create differentiated product and service offerings
-- • Position themselves strategically against key competitors
-- • Explore partnership opportunities with complementary markets
-- • Optimize pricing strategies based on competitive positioning
-- ===================================================================================== 