-- =====================================================================================
-- QUERY 5: Tourism Resilience Stress Test
-- =====================================================================================
-- PURPOSE: Simulate crisis scenarios to identify markets with strong resilience 
-- and ability to maintain tourist arrivals under stress conditions
-- 
-- BUSINESS QUESTION: "How do different countries perform under various crisis 
-- scenarios, and what is their ability to maintain arrivals under stress conditions?"
-- 
-- APPROACH: Apply stress testing methodology to tourism markets:
--   • Baseline Analysis - Current performance over last 3 years
--   • Crisis Scenarios - Simulate different stress conditions as percentage impacts
--   • Resilience Scoring - Measure ability to maintain performance under stress
--   • Stability Assessment - Consistency across different scenarios
-- 
-- Business Value: Enables crisis preparedness planning and identifies markets 
-- with strong resilience for strategic focus.
-- =====================================================================================

-- STEP 1: Identify the most recent year for baseline calculations
-- This ensures we're testing resilience against current market conditions
WITH MaxYear AS (
  SELECT MAX(Year) AS MaxYear FROM Tourism_Arrivals
),

-- STEP 2: Calculate baseline performance for the last 3 years
-- This establishes the "normal" performance level before applying stress scenarios
Baseline AS (
  SELECT Country, Year, SUM(Arrivals) AS TotalArrivals
  FROM Tourism_Arrivals, MaxYear
  WHERE Year >= MaxYear.MaxYear - 2  -- Last 3 years for baseline
  GROUP BY Country, Year
),

-- STEP 3: Calculate baseline averages to avoid large number arithmetic
BaselineAvg AS (
  SELECT Country, AVG(TotalArrivals) AS AvgBaselineArrivals
  FROM Baseline
  GROUP BY Country
),

-- STEP 4: Apply crisis scenarios as percentage impacts on baseline
-- This avoids arithmetic overflow by working with percentages
StressScenarios AS (
  SELECT Country, AvgBaselineArrivals,
         -- SCENARIO 1: Severe Peak Season Crisis (50% drop)
         -- Simulates events like natural disasters, political unrest during peak periods
         AvgBaselineArrivals * 0.5 AS Scenario1_Impact,
         
         -- SCENARIO 2: Broad Economic Crisis (30% drop)
         -- Simulates global economic downturns, pandemics, major recessions
         AvgBaselineArrivals * 0.7 AS Scenario2_Impact,
         
         -- SCENARIO 3: Off-Season Vulnerability (20% drop)
         -- Simulates reduced discretionary travel, economic pressure on off-peak periods
         AvgBaselineArrivals * 0.8 AS Scenario3_Impact
  FROM BaselineAvg
),

-- STEP 5: Calculate resilience scores and stability metrics
-- This measures how well markets perform across different crisis scenarios
ResilienceScore AS (
  SELECT Country, AvgBaselineArrivals, Scenario1_Impact, Scenario2_Impact, Scenario3_Impact,
         -- AVERAGE RESILIENCE: Mean performance across all three scenarios
         -- Higher score = better ability to maintain arrivals under stress
         (Scenario1_Impact + Scenario2_Impact + Scenario3_Impact) / 3.0 AS AvgResilience,
         
         -- RESILIENCE STABILITY: Range-based stability measurement
         -- Lower stability = more consistent performance across different crisis types
         -- Using range ratio to avoid arithmetic overflow
         CASE 
           WHEN (Scenario1_Impact + Scenario2_Impact + Scenario3_Impact) / 3.0 = 0 THEN NULL
           ELSE (GREATEST(Scenario1_Impact, Scenario2_Impact, Scenario3_Impact) - 
                 LEAST(Scenario1_Impact, Scenario2_Impact, Scenario3_Impact)) / 
                ((Scenario1_Impact + Scenario2_Impact + Scenario3_Impact) / 3.0)
         END AS ResilienceStability
  FROM StressScenarios
)

-- STEP 6: Rank markets by resilience and categorize them
SELECT 
       Country, 
       CAST(ROUND(AvgBaselineArrivals, 2) AS DECIMAL(10,2)) AS AvgBaselineArrivals,  -- Average baseline arrivals
       CAST(ROUND(Scenario1_Impact, 2) AS DECIMAL(10,2)) AS Scenario1_Impact,        -- Severe crisis impact
       CAST(ROUND(Scenario2_Impact, 2) AS DECIMAL(10,2)) AS Scenario2_Impact,        -- Economic crisis impact
       CAST(ROUND(Scenario3_Impact, 2) AS DECIMAL(10,2)) AS Scenario3_Impact,        -- Off-season crisis impact
       CAST(ROUND(AvgResilience, 2) AS DECIMAL(10,2)) AS AvgResilience,              -- Average resilience across scenarios
       CAST(ROUND(ResilienceStability, 2) AS DECIMAL(10,2)) AS ResilienceStability,  -- Consistency across scenarios
       
       -- RESILIENCE QUARTILE: Rank markets into 4 groups by crisis resilience
       NTILE(4) OVER (ORDER BY AvgResilience DESC) AS ResilienceQuartile
FROM ResilienceScore
ORDER BY AvgResilience DESC;  -- Show most resilient markets first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- Crisis Scenario Descriptions:
-- 
-- SCENARIO 1 - Severe Peak Season Crisis (50% drop):
-- • Simulates: Natural disasters, political unrest, major events during peak periods
-- • Impact: 50% reduction from baseline arrivals
-- • Business Risk: High impact on revenue during critical periods
--
-- SCENARIO 2 - Broad Economic Crisis (30% drop):
-- • Simulates: Global recessions, pandemics, major economic downturns
-- • Impact: 30% reduction from baseline arrivals
-- • Business Risk: Sustained impact across all business periods
--
-- SCENARIO 3 - Off-Season Vulnerability (20% drop):
-- • Simulates: Reduced discretionary travel, economic pressure on off-peak periods
-- • Impact: 20% reduction from baseline arrivals
-- • Business Risk: Reduced year-round business sustainability
--
-- Resilience Score Interpretation:
-- 
-- HIGH RESILIENCE (Top Quartile):
-- • Characteristics: Strong performance across all crisis scenarios
-- • Business Action: Safe investment targets, expand operations, allocate resources
-- • Risk Profile: Low vulnerability to various crisis types
--
-- MEDIUM-HIGH RESILIENCE (Second Quartile):
-- • Characteristics: Good performance in most scenarios with some vulnerability
-- • Business Action: Moderate investment, develop crisis mitigation strategies
-- • Risk Profile: Moderate vulnerability to specific crisis types
--
-- MEDIUM-LOW RESILIENCE (Third Quartile):
-- • Characteristics: Variable performance across scenarios
-- • Business Action: Cautious investment, strengthen crisis preparedness
-- • Risk Profile: Higher vulnerability to certain crisis types
--
-- LOW RESILIENCE (Bottom Quartile):
-- • Characteristics: Poor performance across multiple crisis scenarios
-- • Business Action: Avoid investment, develop turnaround strategies
-- • Risk Profile: High vulnerability to various crisis types
--
-- Resilience Stability Interpretation:
-- • Low Stability Score: Consistent performance across different crisis types
-- • High Stability Score: Variable performance depending on crisis type
--
-- Key Business Applications:
-- • Crisis preparedness and business continuity planning
-- • Investment risk assessment and portfolio diversification
-- • Strategic market selection for expansion
-- • Insurance and risk management planning
-- • Emergency response and recovery planning
--
-- Crisis Preparedness Strategies:
-- • Diversify tourist source markets to reduce dependency
-- • Develop year-round attractions to reduce seasonal vulnerability
-- • Build strong local tourism infrastructure
-- • Establish crisis communication and response protocols
-- • Maintain financial reserves for crisis periods
--
-- Stress Testing Benefits:
-- This analysis helps identify markets that are most likely to maintain
-- tourist arrivals during various crisis scenarios, enabling better
-- risk management and strategic planning for tourism businesses.
-- ===================================================================================== 