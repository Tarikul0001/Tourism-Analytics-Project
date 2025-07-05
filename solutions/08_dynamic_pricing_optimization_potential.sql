-- =====================================================================================
-- QUERY 8: Dynamic Pricing Optimization Potential
-- =====================================================================================
-- Analyze demand elasticity and capacity utilization patterns to identify markets 
-- with high potential for dynamic pricing strategies.
-- 
-- Business Value: Identifies revenue optimization opportunities through 
-- demand-based pricing strategies.
-- =====================================================================================

WITH DemandElasticity AS (
  SELECT Country, Year, Month,
         Arrivals,
         LAG(Arrivals) OVER (PARTITION BY Country ORDER BY Year, Month) AS PrevArrivals,
         -- Capacity utilization (assuming peak arrivals represent capacity)
         Arrivals * 1.0 / MAX(Arrivals) OVER (PARTITION BY Country, Year) AS CapacityUtilization
  FROM Tourism_Arrivals
),
ElasticityMetrics AS (
  SELECT Country,
         -- Price elasticity proxy (demand variation)
         STDEV(Arrivals) / AVG(Arrivals) AS DemandElasticity,
         -- Capacity utilization efficiency
         AVG(CapacityUtilization) AS AvgCapacityUtilization,
         -- Peak demand intensity
         MAX(Arrivals) / AVG(Arrivals) AS PeakIntensity,
         COUNT(*) AS DataPoints
  FROM DemandElasticity
  WHERE PrevArrivals IS NOT NULL
  GROUP BY Country
),
PricingPotential AS (
  SELECT Country, DemandElasticity, AvgCapacityUtilization, PeakIntensity,
         -- Pricing potential: High elasticity + Low utilization + High peak intensity
         DemandElasticity * (1 - AvgCapacityUtilization) * PeakIntensity AS PricingPotential
  FROM ElasticityMetrics
)
SELECT Country, DemandElasticity, AvgCapacityUtilization, PeakIntensity, PricingPotential,
       NTILE(4) OVER (ORDER BY PricingPotential DESC) AS PricingQuartile
FROM PricingPotential
ORDER BY PricingPotential DESC; 