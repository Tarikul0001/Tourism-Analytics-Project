-- =====================================================================================
-- QUERY 11: Tourism Investment Portfolio Optimization
-- =====================================================================================
-- Create an optimal investment portfolio across multiple tourism markets that 
-- maximizes returns while minimizing correlation risk.
-- 
-- Business Value: Guides strategic investment allocation across multiple markets 
-- for optimal risk-adjusted returns.
-- =====================================================================================

WITH MarketReturns AS (
  SELECT Country, Year, Month,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,
         Arrivals AS CurrentArrivals
  FROM Tourism_Arrivals
),
MonthlyReturns AS (
  SELECT Country, Year, Month,
         CASE WHEN PrevArrivals = 0 THEN NULL
              ELSE (CurrentArrivals - PrevArrivals) * 1.0 / PrevArrivals END AS MonthlyReturn
  FROM MarketReturns
  WHERE PrevArrivals IS NOT NULL
),
CorrelationMatrix AS (
  SELECT a.Country AS Country1, b.Country AS Country2,
         CORREL(a.MonthlyReturn, b.MonthlyReturn) AS Correlation
  FROM MonthlyReturns a
  JOIN MonthlyReturns b ON a.Year = b.Year AND a.Month = b.Month
  WHERE a.Country < b.Country
    AND a.MonthlyReturn IS NOT NULL AND b.MonthlyReturn IS NOT NULL
),
PortfolioOptimization AS (
  SELECT Country1, Country2, Correlation,
         CASE 
           WHEN Correlation < 0.3 THEN 'Low Correlation - Good Diversification'
           WHEN Correlation < 0.6 THEN 'Moderate Correlation - Acceptable'
           ELSE 'High Correlation - Poor Diversification'
         END AS DiversificationQuality
  FROM CorrelationMatrix
  WHERE Correlation IS NOT NULL
)
SELECT Country1, Country2, Correlation, DiversificationQuality
FROM PortfolioOptimization
ORDER BY Correlation ASC; 