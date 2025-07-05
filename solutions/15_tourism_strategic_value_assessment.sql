-- =====================================================================================
-- QUERY 15: Tourism Strategic Value Assessment 
-- =====================================================================================
-- PURPOSE: Provide clear, actionable investment recommendations for tourism markets
--
-- BUSINESS QUESTION: "Which countries should we invest in for tourism development?"
--
-- APPROACH: Focus on essential business metrics with clear investment recommendations
-- Clean, executive-friendly output with actionable insights
-- =====================================================================================

-- STEP 1: Find the most recent year in our data
WITH MaxYear AS (
  SELECT MAX([Year]) AS MaxYear FROM Tourism_Arrivals
),

-- STEP 2: Calculate essential business metrics
BusinessMetrics AS (
  SELECT 
    [Country],
    SUM([Arrivals]) AS TotalArrivals,
    AVG(CASE WHEN [Year] >= my.MaxYear - 1 
             THEN [Arrivals_Growth_Rate] ELSE NULL END) AS RecentGrowthRate,
    AVG([Source_Market_Diversity]) AS MarketDiversity,
    CASE 
      WHEN SUM([Arrivals]) < 10000 OR COUNT(*) < 12 THEN 'Insufficient Data'
      ELSE 'Good Data'
    END AS DataQuality
  FROM Tourism_Arrivals
  CROSS JOIN MaxYear my
  GROUP BY [Country]
),

-- STEP 3: Create simple investment recommendations
InvestmentRecommendations AS (
  SELECT 
    [Country],
    TotalArrivals,
    RecentGrowthRate,
    MarketDiversity,
    DataQuality,
    
    -- SIMPLE INVESTMENT RECOMMENDATION
    CASE 
      WHEN TotalArrivals >= 100000000 AND RecentGrowthRate >= 20 AND DataQuality = 'Good Data' 
           THEN 'Invest Now'
      WHEN TotalArrivals >= 50000000 AND RecentGrowthRate >= 10 AND DataQuality = 'Good Data' 
           THEN 'Strategic Investment'
      WHEN TotalArrivals >= 25000000 AND RecentGrowthRate >= 0 AND DataQuality = 'Good Data' 
           THEN 'Monitor & Opportunistic'
      WHEN DataQuality = 'Insufficient Data' 
           THEN 'Need More Data'
      ELSE 'Not Recommended'
    END AS InvestmentAction,
    
    -- KEY BUSINESS INSIGHT
    CASE 
      WHEN TotalArrivals >= 100000000 AND RecentGrowthRate >= 30 
           THEN 'Major expansion opportunity'
      WHEN TotalArrivals >= 50000000 AND MarketDiversity >= 0.6 
           THEN 'Stable, diverse market'
      WHEN RecentGrowthRate >= 40 
           THEN 'High growth momentum'
      WHEN MarketDiversity < 0.5 
           THEN 'Concentrated market - diversification needed'
      WHEN TotalArrivals >= 100000000 
           THEN 'Large market opportunity'
      ELSE 'Standard market'
    END AS KeyInsight
  FROM BusinessMetrics
)

-- STEP 4: Clean, executive-friendly output
SELECT 
  [Country],
  FORMAT(TotalArrivals, '#,##0') AS 'Market Size (Arrivals)',
  ROUND(RecentGrowthRate, 1) AS 'Recent Growth (%)',
  ROUND(MarketDiversity, 2) AS 'Market Diversity',
  InvestmentAction AS 'Investment Recommendation',
  KeyInsight AS 'Key Business Insight'
FROM InvestmentRecommendations
ORDER BY 
  CASE InvestmentAction
    WHEN 'Invest Now' THEN 1
    WHEN 'Strategic Investment' THEN 2
    WHEN 'Monitor & Opportunistic' THEN 3
    WHEN 'Need More Data' THEN 4
    ELSE 5
  END,
  TotalArrivals DESC;

-- =====================================================================================
-- EXECUTIVE SUMMARY:
-- =====================================================================================
-- 
-- INVESTMENT RECOMMENDATIONS:
-- 
-- Invest Now:
-- • Large markets (100M+ arrivals) with strong growth (20%+)
-- • Immediate investment and aggressive expansion
-- • High priority for resource allocation
--
-- Strategic Investment:
-- • Medium markets (50-100M arrivals) with moderate growth (10%+)
-- • Measured, strategic expansion over 6-12 months
-- • Balanced risk-return profile
--
-- Monitor & Opportunistic:
-- • Smaller markets (25-50M arrivals) with stable performance
-- • Selective investment based on specific opportunities
-- • Focus on efficiency and optimization
--
-- Need More Data:
-- • Markets with insufficient data for reliable analysis
-- • Collect more data before making investment decisions
-- • Monitor for improvement
--
-- Not Recommended:
-- • Markets with poor performance or insufficient scale
-- • Avoid investment, consider exit strategies
--
-- KEY BUSINESS INSIGHTS:
-- • Major expansion: High volume + strong growth
-- • Stable investment: Good size + diversity
-- • Growth momentum: Strong recent performance
-- • Diversification: Concentrated markets need variety
-- • Large opportunity: Significant market size
-- ===================================================================================== 