-- =====================================================================================
-- QUERY 2: Tourism Investment Risk-Return Profile
-- =====================================================================================
-- PURPOSE: Identify tourism markets with the best risk-return profiles for investment
-- 
-- BUSINESS QUESTION: "Which tourism markets offer the optimal risk-return profile 
-- for investment using Sharpe Ratio analysis?"
-- 
-- APPROACH: Apply financial investment theory to tourism markets:
--   • Returns = Monthly growth in tourist arrivals
--   • Risk = Volatility (standard deviation) of monthly returns
--   • Sharpe Ratio = Average Return ÷ Risk (higher = better risk-adjusted returns)
-- 
-- Business Value: Supports investment portfolio optimization and capital allocation 
-- decisions for tourism infrastructure and marketing investments.
-- =====================================================================================

-- STEP 1: Calculate monthly tourist arrivals for each country to track performance over time
-- This creates a time series to analyze growth patterns and volatility
WITH MonthlyReturns AS (
  SELECT Country, Year, Month,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,  -- Previous month's arrivals
         Arrivals AS CurrentArrivals                                                       -- Current month's arrivals
  FROM Tourism_Arrivals
),

-- STEP 2: Calculate monthly growth rates (returns) for each country
-- This measures how much tourist arrivals grew or declined month-over-month
GrowthRates AS (
  SELECT Country, Year, Month,
         -- Calculate monthly return: (Current - Previous) ÷ Previous
         -- This gives us the percentage change in arrivals each month
         CASE WHEN PrevArrivals = 0 THEN NULL  -- Avoid division by zero
              ELSE (CurrentArrivals - PrevArrivals) * 1.0 / PrevArrivals END AS MonthlyReturn
  FROM MonthlyReturns
  WHERE PrevArrivals IS NOT NULL  -- Only include months with previous data
),

-- STEP 3: Calculate risk-return metrics for each country
-- This applies financial analysis principles to tourism market performance
RiskReturn AS (
  SELECT Country,
         -- AVERAGE RETURN: Mean monthly growth rate (higher = better)
         AVG(MonthlyReturn) AS AvgReturn,
         
         -- RISK (VOLATILITY): Standard deviation of monthly returns (lower = less risky)
         STDEV(MonthlyReturn) AS ReturnVolatility,
         
         -- DATA QUALITY: Number of data points for reliability
         COUNT(*) AS DataPoints
  FROM GrowthRates
  WHERE MonthlyReturn IS NOT NULL
  GROUP BY Country
  HAVING COUNT(*) >= 12  -- Minimum 12 months of data for reliable analysis
)

-- STEP 4: Calculate Sharpe Ratio and rank markets by risk-adjusted performance
-- Sharpe Ratio = Average Return ÷ Risk (higher ratio = better risk-adjusted returns)
SELECT 
       Country, 
       CAST(ROUND(AvgReturn, 2) AS DECIMAL(10,2)) AS AvgReturn,                    -- Average monthly growth rate (%)
       CAST(ROUND(ReturnVolatility, 2) AS DECIMAL(10,2)) AS ReturnVolatility,      -- Risk measure (standard deviation)
       
       -- SHARPE RATIO: Risk-adjusted return measure
       -- Formula: Average Return ÷ Risk (higher = better)
       -- Null if volatility is zero (no risk, but also no meaningful ratio)
       CAST(ROUND(CASE WHEN ReturnVolatility = 0 THEN NULL
            ELSE AvgReturn / ReturnVolatility END, 2) AS DECIMAL(10,2)) AS SharpeRatio,
       
       -- RISK-RETURN QUINTILE: Rank markets into 5 groups (1 = best risk-adjusted returns)
       NTILE(5) OVER (ORDER BY CASE WHEN ReturnVolatility = 0 THEN NULL
                                   ELSE AvgReturn / ReturnVolatility END DESC) AS RiskReturnQuintile
FROM RiskReturn
ORDER BY SharpeRatio DESC;  -- Show best risk-adjusted performers first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Sharpe Ratio Interpretation:
-- 
-- HIGH SHARPE RATIO (> 1.0):
-- • Characteristics: High returns with relatively low risk
-- • Investment Action: Primary investment targets, allocate more capital
-- • Example: Market with 15% average growth and 10% volatility = Sharpe Ratio of 1.5
--
-- MEDIUM SHARPE RATIO (0.5 - 1.0):
-- • Characteristics: Good returns with moderate risk
-- • Investment Action: Secondary investment opportunities, moderate allocation
-- • Example: Market with 10% average growth and 12% volatility = Sharpe Ratio of 0.83
--
-- LOW SHARPE RATIO (< 0.5):
-- • Characteristics: Low returns relative to risk, or high risk relative to returns
-- • Investment Action: Avoid or minimal investment, focus on risk reduction
-- • Example: Market with 5% average growth and 15% volatility = Sharpe Ratio of 0.33
--
-- Risk-Return Quintile Rankings:
-- 1: Top 20% - Best risk-adjusted returns (primary investment targets)
-- 2: 21-40% - Good risk-adjusted returns (secondary opportunities)
-- 3: 41-60% - Average risk-adjusted returns (maintain current positions)
-- 4: 61-80% - Below average risk-adjusted returns (reduce exposure)
-- 5: Bottom 20% - Poor risk-adjusted returns (avoid or exit)
--
-- Key Business Applications:
-- • Investment portfolio optimization across multiple tourism markets
-- • Capital allocation decisions for tourism infrastructure projects
-- • Risk management and diversification strategies
-- • Performance benchmarking against financial investment standards
-- • Due diligence for tourism investment opportunities
--
-- Financial Analogy:
-- This analysis treats tourism markets like financial assets:
-- • Tourist arrivals = Revenue/earnings
-- • Monthly growth = Investment returns
-- • Volatility = Investment risk
-- • Sharpe Ratio = Risk-adjusted performance measure
-- ===================================================================================== 