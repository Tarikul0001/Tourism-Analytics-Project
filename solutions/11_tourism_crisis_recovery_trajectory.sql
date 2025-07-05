-- =====================================================================================
-- QUERY 11: Tourism Crisis Recovery Trajectory 
-- =====================================================================================
-- PURPOSE: Analyze post-crisis recovery patterns and predict recovery timeframes 
-- for different tourism markets using available data
-- 
-- BUSINESS QUESTION: "What are the recovery patterns post-crisis and predicted 
-- recovery timeframes for different market segments?"
-- 
-- APPROACH: Assess recovery using crisis baseline and post-crisis performance:
--   • Crisis Baseline - Average arrivals during crisis (2020)
--   • Recovery Trajectory - How quickly arrivals are rebounding (2021, 2022)
--   • Recovery Speed - Rate of improvement post-crisis
--   • Recovery Prediction - Categorize markets by expected recovery timeframe
--   • Recovery Resilience - Market's ability to bounce back from crisis
-- 
-- Business Value: Informs crisis recovery strategies and identifies markets 
-- with strong bounce-back potential for post-crisis investment.
-- =====================================================================================

-- STEP 1: Calculate crisis baseline and recovery metrics for each country
-- This establishes crisis levels and measures recovery from 2020 baseline
WITH CrisisRecovery AS (
  SELECT 
    Country,
    -- CRISIS BASELINE: Average arrivals during crisis (2020)
    AVG(CASE WHEN Year = 2020 THEN Arrivals ELSE NULL END) AS CrisisBaseline,
    
    -- CRISIS GROWTH RATE: Average growth rate during crisis (2020)
    AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) AS CrisisGrowthRate,
    
    -- RECOVERY 2021: Average arrivals in 2021 (first recovery year)
    AVG(CASE WHEN Year = 2021 THEN Arrivals ELSE NULL END) AS Recovery2021,
    
    -- RECOVERY 2022: Average arrivals in 2022 (second recovery year)
    AVG(CASE WHEN Year = 2022 THEN Arrivals ELSE NULL END) AS Recovery2022,
    
    -- RECOVERY GROWTH 2021: Average growth rate in 2021
    AVG(CASE WHEN Year = 2021 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecoveryGrowth2021,
    
    -- RECOVERY GROWTH 2022: Average growth rate in 2022
    AVG(CASE WHEN Year = 2022 THEN Arrivals_Growth_Rate ELSE NULL END) AS RecoveryGrowth2022,
    
    -- CRISIS SEVERITY: How severe the crisis impact was
    CASE 
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -80 THEN 'Severe Crisis'
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -60 THEN 'Major Crisis'
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -40 THEN 'Moderate Crisis'
      WHEN AVG(CASE WHEN Year = 2020 THEN Arrivals_Growth_Rate ELSE NULL END) < -20 THEN 'Minor Crisis'
      ELSE 'Minimal Impact'
    END AS CrisisSeverity
  FROM Tourism_Arrivals
  GROUP BY Country
),

-- STEP 2: Calculate recovery ratios and trajectory metrics
RecoveryAnalysis AS (
  SELECT 
    Country,
    CrisisBaseline,
    CrisisGrowthRate,
    Recovery2021,
    Recovery2022,
    RecoveryGrowth2021,
    RecoveryGrowth2022,
    CrisisSeverity,
    
    -- RECOVERY RATIO 2021: How much recovered by 2021
    CASE 
      WHEN CrisisBaseline = 0 OR CrisisBaseline IS NULL THEN NULL
      ELSE Recovery2021 / CrisisBaseline 
    END AS RecoveryRatio2021,
    
    -- RECOVERY RATIO 2022: How much recovered by 2022
    CASE 
      WHEN CrisisBaseline = 0 OR CrisisBaseline IS NULL THEN NULL
      ELSE Recovery2022 / CrisisBaseline 
    END AS RecoveryRatio2022,
    
    -- RECOVERY SPEED: Rate of improvement from 2020 to 2022
    CASE 
      WHEN CrisisBaseline = 0 OR CrisisBaseline IS NULL THEN NULL
      ELSE (Recovery2022 - CrisisBaseline) / CrisisBaseline / 2.0
    END AS RecoverySpeed,
    
    -- RECOVERY MOMENTUM: Acceleration of recovery
    RecoveryGrowth2022 - RecoveryGrowth2021 AS RecoveryMomentum,
    
    -- RECOVERY CONSISTENCY: How consistent the recovery has been
    CASE 
      WHEN RecoveryGrowth2021 > 0 AND RecoveryGrowth2022 > 0 THEN 'Consistent Recovery'
      WHEN RecoveryGrowth2021 > 0 OR RecoveryGrowth2022 > 0 THEN 'Inconsistent Recovery'
      ELSE 'No Recovery'
    END AS RecoveryConsistency
  FROM CrisisRecovery
),

-- STEP 3: Categorize recovery trajectory and predict future recovery
RecoveryPrediction AS (
  SELECT 
    Country,
    CrisisBaseline,
    CrisisGrowthRate,
    Recovery2021,
    Recovery2022,
    RecoveryRatio2021,
    RecoveryRatio2022,
    RecoverySpeed,
    RecoveryMomentum,
    CrisisSeverity,
    RecoveryConsistency,
    
    -- RECOVERY TRAJECTORY: Overall recovery pattern
    CASE 
      WHEN RecoverySpeed > 2.0 THEN 'Exceptional Recovery'
      WHEN RecoverySpeed > 1.0 THEN 'Strong Recovery'
      WHEN RecoverySpeed > 0.5 THEN 'Moderate Recovery'
      WHEN RecoverySpeed > 0 THEN 'Weak Recovery'
      ELSE 'No Recovery'
    END AS RecoveryTrajectory,
    
    -- PREDICTED RECOVERY TIME: Based on current trajectory
    CASE 
      WHEN RecoverySpeed > 2.0 THEN 'Already Recovered'
      WHEN RecoverySpeed > 1.0 THEN 'Fast Recovery (3-6 months)'
      WHEN RecoverySpeed > 0.5 THEN 'Moderate Recovery (6-12 months)'
      WHEN RecoverySpeed > 0 THEN 'Slow Recovery (12-24 months)'
      ELSE 'Long-term Recovery (24+ months)'
    END AS PredictedRecoveryTime,
    
    -- RECOVERY RESILIENCE: Market's ability to bounce back
    CASE 
      WHEN RecoverySpeed > 1.5 AND RecoveryMomentum > 0 THEN 'High Resilience'
      WHEN RecoverySpeed > 0.8 AND RecoveryMomentum > -10 THEN 'Good Resilience'
      WHEN RecoverySpeed > 0.3 THEN 'Moderate Resilience'
      WHEN RecoverySpeed > 0 THEN 'Low Resilience'
      ELSE 'Poor Resilience'
    END AS RecoveryResilience
  FROM RecoveryAnalysis
)

-- STEP 4: Output simplified, executive-friendly recovery analysis
SELECT 
       Country, 
               CAST(ROUND(RecoverySpeed, 2) AS DECIMAL(10,2)) AS RecoverySpeed,  -- Recovery rate (higher = faster)
        
        -- RECOVERY STATUS: Clear recovery assessment
        CASE 
          WHEN RecoverySpeed > 2.0 THEN 'Exceptional Recovery'
          WHEN RecoverySpeed > 1.0 THEN 'Strong Recovery'
          WHEN RecoverySpeed > 0.5 THEN 'Moderate Recovery'
          WHEN RecoverySpeed > 0 THEN 'Weak Recovery'
          ELSE 'No Recovery'
        END AS RecoveryStatus,
       
       -- TIMING: Predicted recovery timeframe
       CASE 
         WHEN RecoverySpeed > 2.0 THEN 'Already Recovered'
         WHEN RecoverySpeed > 1.0 THEN '3-6 months'
         WHEN RecoverySpeed > 0.5 THEN '6-12 months'
         WHEN RecoverySpeed > 0 THEN '12-24 months'
         ELSE '24+ months'
       END AS RecoveryTiming,
       
       -- CRISIS IMPACT: How severe the crisis was
       CrisisSeverity,
       
       -- RESILIENCE: Market's bounce-back ability
       RecoveryResilience,
       
       -- STRATEGY: Recommended approach
       CASE 
         WHEN RecoverySpeed > 1.0 THEN 'Accelerate Investment'
         WHEN RecoverySpeed > 0.5 THEN 'Strategic Investment'
         WHEN RecoverySpeed > 0 THEN 'Cautious Investment'
         ELSE 'Monitor & Wait'
       END AS Strategy,
       
       -- RECOVERY PROGRESS: Current recovery level
       CASE 
         WHEN RecoveryRatio2022 > 3.0 THEN 'Beyond Pre-Crisis'
         WHEN RecoveryRatio2022 > 2.0 THEN 'Fully Recovered'
         WHEN RecoveryRatio2022 > 1.5 THEN 'Mostly Recovered'
         WHEN RecoveryRatio2022 > 1.0 THEN 'Partially Recovered'
         WHEN RecoveryRatio2022 > 0.5 THEN 'Limited Recovery'
         ELSE 'Still in Crisis'
       END AS RecoveryProgress
FROM RecoveryPrediction
ORDER BY RecoverySpeed DESC;  -- Show fastest recovering markets first

-- =====================================================================================
-- INTERPRETATION GUIDE FOR EXECUTIVES:
-- =====================================================================================
-- 
-- RECOVERY SPEED INTERPRETATION:
-- 
-- > 2.0: EXCEPTIONAL RECOVERY
-- • Market has already exceeded crisis levels
-- • Exceptional bounce-back performance
-- • Strategy: Accelerate Investment
-- • Timing: Already Recovered
--
-- 1.0-2.0: STRONG RECOVERY
-- • Market recovering rapidly from crisis
-- • Strong positive momentum
-- • Strategy: Accelerate Investment
-- • Timing: 3-6 months
--
-- 0.5-1.0: MODERATE RECOVERY
-- • Market showing steady recovery
-- • Moderate but consistent improvement
-- • Strategy: Strategic Investment
-- • Timing: 6-12 months
--
-- 0.0-0.5: WEAK RECOVERY
-- • Market recovering slowly
-- • Limited improvement from crisis
-- • Strategy: Cautious Investment
-- • Timing: 12-24 months
--
-- < 0.0: NO RECOVERY
-- • Market still struggling
-- • No improvement from crisis levels
-- • Strategy: Monitor & Wait
-- • Timing: 24+ months
--
-- CRISIS SEVERITY LEVELS:
-- 
-- Severe Crisis: >80% decline in arrivals - extreme impact
-- Major Crisis: 60-80% decline in arrivals - significant impact
-- Moderate Crisis: 40-60% decline in arrivals - moderate impact
-- Minor Crisis: 20-40% decline in arrivals - limited impact
-- Minimal Impact: <20% decline in arrivals - minor impact
--
-- RECOVERY RESILIENCE:
-- 
-- High Resilience: Strong recovery speed with positive momentum
-- Good Resilience: Good recovery speed with stable momentum
-- Moderate Resilience: Moderate recovery speed
-- Low Resilience: Weak recovery speed
-- Poor Resilience: No recovery or declining momentum
--
-- RECOVERY PROGRESS:
-- 
-- Beyond Pre-Crisis: Exceeded pre-crisis levels by 200%+
-- Fully Recovered: Exceeded pre-crisis levels by 100%+
-- Mostly Recovered: Exceeded pre-crisis levels by 50%+
-- Partially Recovered: Reached pre-crisis levels
-- Limited Recovery: 50-100% of pre-crisis levels
-- Still in Crisis: <50% of pre-crisis levels
--
-- STRATEGIC APPROACHES:
-- 
-- Accelerate Investment: Markets with strong recovery - increase investment
-- Strategic Investment: Markets with moderate recovery - measured investment
-- Cautious Investment: Markets with weak recovery - limited investment
-- Monitor & Wait: Markets with no recovery - avoid investment
--
-- KEY BUSINESS APPLICATIONS:
-- 
-- FOR TOURISM BOARDS & GOVERNMENTS:
-- • Prioritize markets for recovery support
-- • Allocate recovery funding strategically
-- • Develop targeted recovery campaigns
-- • Monitor recovery progress and adjust strategies
--
-- FOR HOTEL CHAINS & ACCOMMODATION PROVIDERS:
-- • Identify markets for expansion and investment
-- • Prioritize markets for capacity restoration
-- • Develop market-specific recovery strategies
-- • Allocate resources based on recovery potential
--
-- FOR AIRLINES & TRANSPORTATION COMPANIES:
-- • Plan route restoration and expansion
-- • Prioritize markets for capacity increases
-- • Develop recovery-focused marketing campaigns
-- • Allocate fleet resources strategically
--
-- FOR TRAVEL AGENCIES & TOUR OPERATORS:
-- • Focus marketing efforts on recovering markets
-- • Develop products for high-recovery markets
-- • Adjust pricing strategies based on recovery
-- • Allocate sales resources strategically
--
-- FOR INVESTORS & FINANCIAL INSTITUTIONS:
-- • Identify investment opportunities in recovering markets
-- • Assess risk based on recovery resilience
-- • Prioritize markets for tourism investments
-- • Monitor recovery progress for investment decisions
--
-- RECOVERY STRATEGY BY MARKET TYPE:
-- 
-- EXCEPTIONAL RECOVERY MARKETS:
-- • Aggressive expansion and investment
-- • Rapid capacity restoration
-- • Market leadership positioning
-- • Leverage recovery momentum
--
-- STRONG RECOVERY MARKETS:
-- • Strategic expansion and investment
-- • Gradual capacity restoration
-- • Market challenger positioning
-- • Support recovery momentum
--
-- MODERATE RECOVERY MARKETS:
-- • Cautious expansion and investment
-- • Limited capacity restoration
-- • Market follower positioning
-- • Monitor recovery progress
--
-- WEAK RECOVERY MARKETS:
-- • Minimal expansion and investment
-- • Focus on cost control
-- • Market niche positioning
-- • Develop turnaround strategies
--
-- NO RECOVERY MARKETS:
-- • Avoid expansion and investment
-- • Focus on risk mitigation
-- • Consider exit strategies
-- • Monitor for improvement signs
--
-- CRISIS RECOVERY BENEFITS:
-- This analysis helps identify which markets are recovering fastest
-- from crisis, enabling better resource allocation, strategic planning,
-- and investment decisions for tourism businesses and policymakers.
-- ===================================================================================== 