-- =====================================================================================
-- QUERY 13: Tourism Investment Portfolio Optimization 
-- =====================================================================================
-- PURPOSE: Optimize tourism investment portfolios by selecting countries that 
-- maximize returns while minimizing correlation (risk)
-- 
-- BUSINESS QUESTION: "How can we create optimal tourism investment portfolios by 
-- selecting countries that maximize returns while minimizing correlation?"
-- 
-- APPROACH: Apply portfolio theory to tourism markets using simplified metrics:
--   • Average Return - Expected return from each market
--   • Return Volatility - Risk/uncertainty of returns
--   • Market Diversity - How different the market is from others
--   • Portfolio Score - Combines all factors for optimal allocation
-- 
-- Business Value: Guides strategic investment allocation across multiple markets 
-- for optimal risk-adjusted returns.
-- =====================================================================================

-- STEP 1: Calculate basic return metrics for each country
-- This measures growth performance and risk for each market
WITH CountryMetrics AS (
  SELECT 
    Country,
    -- AVERAGE GROWTH RATE: Expected return from the market
    AVG(Arrivals_Growth_Rate) AS AvgReturn,
    
    -- GROWTH VOLATILITY: Risk/uncertainty of returns
    STDEVP(Arrivals_Growth_Rate) AS ReturnVolatility,
    
    -- POSITIVE GROWTH RATIO: Consistency of positive returns
    AVG(CASE WHEN Arrivals_Growth_Rate > 0 THEN 1.0 ELSE 0.0 END) AS PositiveGrowthRatio,
    
    -- RECOVERY PERFORMANCE: Post-crisis recovery (2021-2022)
    AVG(CASE WHEN Year >= 2021 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecoveryPerformance,
    
    -- MARKET SIZE: Average arrivals volume
    AVG(Arrivals) AS MarketSize,
    
    -- GROWTH STABILITY: Inverse of volatility (higher = more stable)
    CASE 
      WHEN STDEVP(Arrivals_Growth_Rate) = 0 THEN 1.0
      ELSE 1.0 / (1.0 + STDEVP(Arrivals_Growth_Rate))
    END AS GrowthStability
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Calculate market diversity score
-- This measures how different each market is from the average
MarketDiversity AS (
  SELECT 
    Country,
    AvgReturn,
    ReturnVolatility,
    PositiveGrowthRatio,
    RecoveryPerformance,
    MarketSize,
    GrowthStability,
    
    -- MARKET DIVERSITY: How different this market is from average
    -- Based on deviation from overall market averages
    ABS(AvgReturn - (SELECT AVG(AvgReturn) FROM CountryMetrics)) +
    ABS(ReturnVolatility - (SELECT AVG(ReturnVolatility) FROM CountryMetrics)) +
    ABS(PositiveGrowthRatio - (SELECT AVG(PositiveGrowthRatio) FROM CountryMetrics)) AS MarketDiversity,
    
    -- DIVERSIFICATION SCORE: Normalized diversity (0-1 scale)
    (ABS(AvgReturn - (SELECT AVG(AvgReturn) FROM CountryMetrics)) +
     ABS(ReturnVolatility - (SELECT AVG(ReturnVolatility) FROM CountryMetrics)) +
     ABS(PositiveGrowthRatio - (SELECT AVG(PositiveGrowthRatio) FROM CountryMetrics))) / 3.0 AS DiversificationScore
  FROM CountryMetrics
),

-- STEP 3: Calculate portfolio optimization metrics
PortfolioOptimization AS (
  SELECT 
    Country,
    AvgReturn,
    ReturnVolatility,
    PositiveGrowthRatio,
    RecoveryPerformance,
    MarketSize,
    GrowthStability,
    MarketDiversity,
    DiversificationScore,
    
    -- RISK-ADJUSTED RETURN: Return per unit of risk
    CASE 
      WHEN ReturnVolatility = 0 THEN AvgReturn
      ELSE AvgReturn / ReturnVolatility
    END AS RiskAdjustedReturn,
    
    -- PORTFOLIO SCORE: Combined optimization score
    -- Formula: (Risk-Adjusted Return × 0.4) + (Diversification × 0.3) + (Stability × 0.3)
    (
      (CASE WHEN ReturnVolatility = 0 THEN AvgReturn ELSE AvgReturn / ReturnVolatility END * 0.4) +
      (DiversificationScore * 0.3) +
      (GrowthStability * 0.3)
    ) AS PortfolioScore
  FROM MarketDiversity
)

-- STEP 4: Output portfolio optimization results
SELECT 
       Country, 
       CAST(ROUND(AvgReturn, 2) AS DECIMAL(10,2)) AS AvgReturn,                        -- Average growth rate (%)
       CAST(ROUND(ReturnVolatility, 2) AS DECIMAL(10,2)) AS ReturnVolatility,          -- Growth volatility (risk)
       CAST(ROUND(RiskAdjustedReturn, 2) AS DECIMAL(10,2)) AS RiskAdjustedReturn,      -- Return per unit of risk
       CAST(ROUND(DiversificationScore, 2) AS DECIMAL(10,2)) AS DiversificationScore,  -- Market diversity (0-1)
       CAST(ROUND(GrowthStability, 2) AS DECIMAL(10,2)) AS GrowthStability,            -- Growth stability (0-1)
       CAST(ROUND(PortfolioScore, 2) AS DECIMAL(10,2)) AS PortfolioScore,              -- Overall portfolio score
       
       -- PORTFOLIO RECOMMENDATION: Investment guidance
       CASE 
         WHEN PortfolioScore > 0.8 THEN 'Core Portfolio'
         WHEN PortfolioScore > 0.6 THEN 'Growth Portfolio'
         WHEN PortfolioScore > 0.4 THEN 'Balanced Portfolio'
         WHEN PortfolioScore > 0.2 THEN 'Conservative Portfolio'
         ELSE 'Avoid Portfolio'
       END AS PortfolioRecommendation,
       
       -- ALLOCATION STRATEGY: Investment approach
       CASE 
         WHEN PortfolioScore > 0.8 THEN 'High Allocation (25-40%)'
         WHEN PortfolioScore > 0.6 THEN 'Medium Allocation (15-25%)'
         WHEN PortfolioScore > 0.4 THEN 'Moderate Allocation (10-15%)'
         WHEN PortfolioScore > 0.2 THEN 'Low Allocation (5-10%)'
         ELSE 'Minimal Allocation (0-5%)'
       END AS AllocationStrategy,
       
       -- RISK LEVEL: Portfolio risk assessment
       CASE 
         WHEN ReturnVolatility < 20 THEN 'Low Risk'
         WHEN ReturnVolatility < 40 THEN 'Medium Risk'
         WHEN ReturnVolatility < 60 THEN 'High Risk'
         ELSE 'Very High Risk'
       END AS RiskLevel,
       
       -- DIVERSIFICATION BENEFIT: Portfolio diversification value
       CASE 
         WHEN DiversificationScore > 0.7 THEN 'High Diversification'
         WHEN DiversificationScore > 0.5 THEN 'Good Diversification'
         WHEN DiversificationScore > 0.3 THEN 'Moderate Diversification'
         ELSE 'Low Diversification'
       END AS DiversificationBenefit
FROM PortfolioOptimization
ORDER BY PortfolioScore DESC;  -- Show best portfolio candidates first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- PORTFOLIO SCORE INTERPRETATION:
-- 
-- > 0.8: CORE PORTFOLIO
-- • Excellent risk-adjusted returns with high diversification
-- • Investment Focus: Primary portfolio holdings
-- • Allocation: 25-40% of portfolio
-- • Strategy: High allocation, long-term holding
--
-- 0.6-0.8: GROWTH PORTFOLIO
-- • Good risk-adjusted returns with moderate diversification
-- • Investment Focus: Growth-oriented holdings
-- • Allocation: 15-25% of portfolio
-- • Strategy: Medium allocation, growth focus
--
-- 0.4-0.6: BALANCED PORTFOLIO
-- • Moderate risk-adjusted returns with balanced characteristics
-- • Investment Focus: Balanced holdings
-- • Allocation: 10-15% of portfolio
-- • Strategy: Moderate allocation, balanced approach
--
-- 0.2-0.4: CONSERVATIVE PORTFOLIO
-- • Lower risk-adjusted returns, conservative approach
-- • Investment Focus: Conservative holdings
-- • Allocation: 5-10% of portfolio
-- • Strategy: Low allocation, conservative approach
--
-- < 0.2: AVOID PORTFOLIO
-- • Poor risk-adjusted returns, high correlation
-- • Investment Focus: Avoid or minimal allocation
-- • Allocation: 0-5% of portfolio
-- • Strategy: Minimal allocation or avoid
--
-- COMPONENT ANALYSIS:
-- 
-- Risk-Adjusted Return (Higher = Better):
-- • > 1.0: Excellent return per unit of risk
-- • 0.5-1.0: Good return per unit of risk
-- • 0.2-0.5: Moderate return per unit of risk
-- • < 0.2: Poor return per unit of risk
--
-- Diversification Score (0-1 scale):
-- • > 0.7: High diversification benefit
-- • 0.5-0.7: Good diversification benefit
-- • 0.3-0.5: Moderate diversification benefit
-- • < 0.3: Low diversification benefit
--
-- Growth Stability (0-1 scale):
-- • > 0.8: Highly stable growth patterns
-- • 0.6-0.8: Stable growth patterns
-- • 0.4-0.6: Moderately stable growth
-- • < 0.4: Unstable growth patterns
--
-- RISK LEVELS:
-- 
-- Low Risk: < 20% volatility - stable, predictable returns
-- Medium Risk: 20-40% volatility - moderate risk and return
-- High Risk: 40-60% volatility - higher risk, higher potential return
-- Very High Risk: > 60% volatility - high risk, uncertain returns
--
-- DIVERSIFICATION BENEFITS:
-- 
-- High Diversification: Significantly different from average market
-- Good Diversification: Moderately different from average market
-- Moderate Diversification: Somewhat different from average market
-- Low Diversification: Similar to average market
--
-- STRATEGIC APPLICATIONS:
-- 
-- FOR INVESTMENT MANAGERS:
-- • Portfolio construction and optimization
-- • Risk management and diversification
-- • Asset allocation decisions
-- • Performance monitoring and rebalancing
--
-- FOR TOURISM BOARDS & GOVERNMENTS:
-- • Investment attraction prioritization
-- • Market development focus
-- • Resource allocation strategies
-- • Risk assessment and mitigation
--
-- FOR HOTEL CHAINS & ACCOMMODATION PROVIDERS:
-- • Market expansion prioritization
-- • Investment allocation across markets
-- • Risk management strategies
-- • Portfolio diversification
--
-- FOR AIRLINES & TRANSPORTATION COMPANIES:
-- • Route optimization and expansion
-- • Market diversification strategies
-- • Risk management and hedging
-- • Investment allocation decisions
--
-- PORTFOLIO CONSTRUCTION STRATEGY:
-- 
-- CORE PORTFOLIO MARKETS:
-- • Allocate 25-40% of total investment
-- • Focus on long-term growth and stability
-- • Monitor performance closely
-- • Consider as foundation holdings
--
-- GROWTH PORTFOLIO MARKETS:
-- • Allocate 15-25% of total investment
-- • Focus on growth opportunities
-- • Monitor for acceleration potential
-- • Consider for expansion opportunities
--
-- BALANCED PORTFOLIO MARKETS:
-- • Allocate 10-15% of total investment
-- • Focus on balanced risk-return
-- • Monitor for improvement opportunities
-- • Consider for tactical allocation
--
-- CONSERVATIVE PORTFOLIO MARKETS:
-- • Allocate 5-10% of total investment
-- • Focus on stability and preservation
-- • Monitor for recovery potential
-- • Consider for defensive positioning
--
-- AVOID PORTFOLIO MARKETS:
-- • Allocate 0-5% of total investment
-- • Focus on risk mitigation
-- • Monitor for improvement signs
-- • Consider exit strategies
--
-- PORTFOLIO OPTIMIZATION BENEFITS:
-- This analysis helps executives build optimal tourism investment portfolios
-- by selecting markets that maximize risk-adjusted returns while providing
-- diversification benefits through market differences and stability.
-- ===================================================================================== 