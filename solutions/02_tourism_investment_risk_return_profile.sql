-- =====================================================================================
-- QUERY 2: Tourism Investment Risk-Return Profile
-- =====================================================================================
-- Calculate Sharpe Ratio equivalent for tourism markets using arrivals growth as returns 
-- and volatility as risk, identifying optimal investment destinations.
-- 
-- Business Value: Supports investment portfolio optimization and capital allocation 
-- decisions for tourism infrastructure and marketing investments.
-- =====================================================================================

WITH MonthlyReturns AS (
  SELECT Country, Year, Month,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,
         Arrivals AS CurrentArrivals
  FROM Tourism_Arrivals
),
GrowthRates AS (
  SELECT Country, Year, Month,
         CASE WHEN PrevArrivals = 0 THEN NULL
              ELSE (CurrentArrivals - PrevArrivals) * 1.0 / PrevArrivals END AS MonthlyReturn
  FROM MonthlyReturns
  WHERE PrevArrivals IS NOT NULL
),
RiskReturn AS (
  SELECT Country,
         AVG(MonthlyReturn) AS AvgReturn,
         STDEV(MonthlyReturn) AS ReturnVolatility,
         COUNT(*) AS DataPoints
  FROM GrowthRates
  WHERE MonthlyReturn IS NOT NULL
  GROUP BY Country
  HAVING COUNT(*) >= 12  -- Minimum 12 months of data
)
SELECT Country, AvgReturn, ReturnVolatility,
       CASE WHEN ReturnVolatility = 0 THEN NULL
            ELSE AvgReturn / ReturnVolatility END AS SharpeRatio,
       NTILE(5) OVER (ORDER BY CASE WHEN ReturnVolatility = 0 THEN NULL
                                   ELSE AvgReturn / ReturnVolatility END DESC) AS RiskReturnQuintile
FROM RiskReturn
ORDER BY SharpeRatio DESC; 