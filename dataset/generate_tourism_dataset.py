import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import json

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

def generate_tourism_dataset():
    """
    Generate a comprehensive tourism dataset that supports all 15 business questions
    with realistic patterns, multiple countries, regions, and additional dimensions.
    """
    
    # Define countries and regions with realistic characteristics
    countries_data = {
        # Europe - Mature markets with seasonal patterns
        'France': {'region': 'Europe', 'population': 67390000, 'gdp_per_capita': 42000, 'tourism_maturity': 'mature'},
        'Spain': {'region': 'Europe', 'population': 47350000, 'gdp_per_capita': 30000, 'tourism_maturity': 'mature'},
        'Italy': {'region': 'Europe', 'population': 60360000, 'gdp_per_capita': 35000, 'tourism_maturity': 'mature'},
        'Germany': {'region': 'Europe', 'population': 83190000, 'gdp_per_capita': 48000, 'tourism_maturity': 'mature'},
        'United Kingdom': {'region': 'Europe', 'population': 67220000, 'gdp_per_capita': 45000, 'tourism_maturity': 'mature'},
        'Netherlands': {'region': 'Europe', 'population': 17130000, 'gdp_per_capita': 52000, 'tourism_maturity': 'mature'},
        'Switzerland': {'region': 'Europe', 'population': 8650000, 'gdp_per_capita': 85000, 'tourism_maturity': 'mature'},
        'Austria': {'region': 'Europe', 'population': 9006000, 'gdp_per_capita': 50000, 'tourism_maturity': 'mature'},
        'Greece': {'region': 'Europe', 'population': 10423000, 'gdp_per_capita': 20000, 'tourism_maturity': 'mature'},
        'Portugal': {'region': 'Europe', 'population': 10196000, 'gdp_per_capita': 25000, 'tourism_maturity': 'mature'},
        'Poland': {'region': 'Eastern Europe', 'population': 38386000, 'gdp_per_capita': 18000, 'tourism_maturity': 'emerging'},
        'Czech Republic': {'region': 'Eastern Europe', 'population': 10700000, 'gdp_per_capita': 23000, 'tourism_maturity': 'emerging'},
        'Hungary': {'region': 'Eastern Europe', 'population': 9773000, 'gdp_per_capita': 17000, 'tourism_maturity': 'emerging'},
        'Romania': {'region': 'Eastern Europe', 'population': 19240000, 'gdp_per_capita': 14000, 'tourism_maturity': 'emerging'},
        'Croatia': {'region': 'Eastern Europe', 'population': 4105000, 'gdp_per_capita': 17000, 'tourism_maturity': 'emerging'},
        
        # North America - Large markets with diverse patterns
        'United States': {'region': 'North America', 'population': 331000000, 'gdp_per_capita': 65000, 'tourism_maturity': 'mature'},
        'Canada': {'region': 'North America', 'population': 38000000, 'gdp_per_capita': 45000, 'tourism_maturity': 'mature'},
        'Mexico': {'region': 'North America', 'population': 128900000, 'gdp_per_capita': 10000, 'tourism_maturity': 'emerging'},
        'Costa Rica': {'region': 'Central America', 'population': 5094000, 'gdp_per_capita': 12000, 'tourism_maturity': 'emerging'},
        'Panama': {'region': 'Central America', 'population': 4315000, 'gdp_per_capita': 15000, 'tourism_maturity': 'emerging'},
        'Guatemala': {'region': 'Central America', 'population': 17920000, 'gdp_per_capita': 5000, 'tourism_maturity': 'emerging'},
        'Jamaica': {'region': 'Caribbean', 'population': 2961000, 'gdp_per_capita': 5500, 'tourism_maturity': 'emerging'},
        'Dominican Republic': {'region': 'Caribbean', 'population': 10850000, 'gdp_per_capita': 8000, 'tourism_maturity': 'emerging'},
        'Bahamas': {'region': 'Caribbean', 'population': 393000, 'gdp_per_capita': 32000, 'tourism_maturity': 'mature'},
        'Cuba': {'region': 'Caribbean', 'population': 11330000, 'gdp_per_capita': 9000, 'tourism_maturity': 'emerging'},
        'Barbados': {'region': 'Caribbean', 'population': 287000, 'gdp_per_capita': 18000, 'tourism_maturity': 'mature'},
        
        # Asia - High growth markets
        'China': {'region': 'Asia', 'population': 1402000000, 'gdp_per_capita': 12000, 'tourism_maturity': 'emerging'},
        'Japan': {'region': 'Asia', 'population': 125800000, 'gdp_per_capita': 40000, 'tourism_maturity': 'mature'},
        'South Korea': {'region': 'Asia', 'population': 51270000, 'gdp_per_capita': 35000, 'tourism_maturity': 'mature'},
        'Thailand': {'region': 'Asia', 'population': 69800000, 'gdp_per_capita': 8000, 'tourism_maturity': 'emerging'},
        'Singapore': {'region': 'Asia', 'population': 5850000, 'gdp_per_capita': 65000, 'tourism_maturity': 'mature'},
        'Malaysia': {'region': 'Asia', 'population': 32700000, 'gdp_per_capita': 12000, 'tourism_maturity': 'emerging'},
        'Vietnam': {'region': 'Asia', 'population': 97340000, 'gdp_per_capita': 4000, 'tourism_maturity': 'emerging'},
        'India': {'region': 'Asia', 'population': 1380000000, 'gdp_per_capita': 2000, 'tourism_maturity': 'emerging'},
        'Indonesia': {'region': 'Asia', 'population': 273500000, 'gdp_per_capita': 4000, 'tourism_maturity': 'emerging'},
        'Philippines': {'region': 'Asia', 'population': 109600000, 'gdp_per_capita': 3500, 'tourism_maturity': 'emerging'},
        'Nepal': {'region': 'Asia', 'population': 29140000, 'gdp_per_capita': 1200, 'tourism_maturity': 'emerging'},
        'Sri Lanka': {'region': 'Asia', 'population': 21800000, 'gdp_per_capita': 4000, 'tourism_maturity': 'emerging'},
        
        # Middle East - Emerging luxury markets
        'United Arab Emirates': {'region': 'Middle East', 'population': 9890000, 'gdp_per_capita': 43000, 'tourism_maturity': 'emerging'},
        'Saudi Arabia': {'region': 'Middle East', 'population': 34800000, 'gdp_per_capita': 23000, 'tourism_maturity': 'emerging'},
        'Qatar': {'region': 'Middle East', 'population': 2880000, 'gdp_per_capita': 61000, 'tourism_maturity': 'emerging'},
        'Turkey': {'region': 'Middle East', 'population': 84340000, 'gdp_per_capita': 9000, 'tourism_maturity': 'emerging'},
        'Israel': {'region': 'Middle East', 'population': 9217000, 'gdp_per_capita': 43000, 'tourism_maturity': 'mature'},
        'Jordan': {'region': 'Middle East', 'population': 10200000, 'gdp_per_capita': 4200, 'tourism_maturity': 'emerging'},
        
        # Oceania - Island destinations
        'Australia': {'region': 'Oceania', 'population': 25690000, 'gdp_per_capita': 55000, 'tourism_maturity': 'mature'},
        'New Zealand': {'region': 'Oceania', 'population': 5080000, 'gdp_per_capita': 42000, 'tourism_maturity': 'mature'},
        'Fiji': {'region': 'Pacific Islands', 'population': 896000, 'gdp_per_capita': 6000, 'tourism_maturity': 'emerging'},
        'Samoa': {'region': 'Pacific Islands', 'population': 198000, 'gdp_per_capita': 4300, 'tourism_maturity': 'emerging'},
        'Papua New Guinea': {'region': 'Pacific Islands', 'population': 8947000, 'gdp_per_capita': 2500, 'tourism_maturity': 'emerging'},
        
        # Africa - Emerging markets
        'South Africa': {'region': 'Africa', 'population': 59310000, 'gdp_per_capita': 6000, 'tourism_maturity': 'emerging'},
        'Morocco': {'region': 'Africa', 'population': 36910000, 'gdp_per_capita': 3500, 'tourism_maturity': 'emerging'},
        'Egypt': {'region': 'Africa', 'population': 102300000, 'gdp_per_capita': 3000, 'tourism_maturity': 'emerging'},
        'Kenya': {'region': 'Africa', 'population': 53770000, 'gdp_per_capita': 2000, 'tourism_maturity': 'emerging'},
        'Nigeria': {'region': 'Sub-Saharan Africa', 'population': 206100000, 'gdp_per_capita': 2200, 'tourism_maturity': 'emerging'},
        'Ethiopia': {'region': 'Sub-Saharan Africa', 'population': 114900000, 'gdp_per_capita': 900, 'tourism_maturity': 'emerging'},
        'Tanzania': {'region': 'Sub-Saharan Africa', 'population': 59730000, 'gdp_per_capita': 1100, 'tourism_maturity': 'emerging'},
        'Ghana': {'region': 'Sub-Saharan Africa', 'population': 31070000, 'gdp_per_capita': 2200, 'tourism_maturity': 'emerging'},
        
        # South America - Diverse markets
        'Brazil': {'region': 'South America', 'population': 212600000, 'gdp_per_capita': 9000, 'tourism_maturity': 'emerging'},
        'Argentina': {'region': 'South America', 'population': 45196000, 'gdp_per_capita': 10000, 'tourism_maturity': 'emerging'},
        'Chile': {'region': 'South America', 'population': 19116000, 'gdp_per_capita': 15000, 'tourism_maturity': 'emerging'},
        'Peru': {'region': 'South America', 'population': 32972000, 'gdp_per_capita': 7000, 'tourism_maturity': 'emerging'},
        'Colombia': {'region': 'South America', 'population': 50880000, 'gdp_per_capita': 6000, 'tourism_maturity': 'emerging'},
        'Ecuador': {'region': 'South America', 'population': 17640000, 'gdp_per_capita': 6000, 'tourism_maturity': 'emerging'},
        'Uruguay': {'region': 'South America', 'population': 3474000, 'gdp_per_capita': 17000, 'tourism_maturity': 'emerging'},
        'Paraguay': {'region': 'South America', 'population': 7132000, 'gdp_per_capita': 5500, 'tourism_maturity': 'emerging'},
    }
    
    # Generate data for 5 years (2018-2022) to capture pre-COVID, COVID, and recovery patterns
    years = [2018, 2019, 2020, 2021, 2022]
    months = list(range(1, 13))
    
    data = []
    
    for country, country_info in countries_data.items():
        region = country_info['region']
        population = country_info['population']
        gdp_per_capita = country_info['gdp_per_capita']
        tourism_maturity = country_info['tourism_maturity']
        
        # Base tourism characteristics by region and maturity
        base_arrivals = population * 0.1  # Base tourism rate
        if tourism_maturity == 'mature':
            base_arrivals *= 1.5
        elif tourism_maturity == 'emerging':
            base_arrivals *= 0.8
        
        # Regional multipliers
        regional_multipliers = {
            'Europe': 1.2,
            'Eastern Europe': 0.9,
            'North America': 1.0,
            'Central America': 0.7,
            'Caribbean': 0.8,
            'Asia': 0.8,
            'Middle East': 0.6,
            'Oceania': 0.4,
            'Pacific Islands': 0.3,
            'Africa': 0.3,
            'Sub-Saharan Africa': 0.2,
            'South America': 0.5,
        }
        
        base_arrivals *= regional_multipliers[region]
        
        # Seasonal patterns by region
        seasonal_patterns = {
            'Europe': [0.6, 0.5, 0.7, 0.8, 1.0, 1.2, 1.5, 1.4, 1.1, 0.9, 0.7, 0.6],
            'Eastern Europe': [0.5, 0.4, 0.6, 0.7, 0.9, 1.1, 1.4, 1.3, 1.0, 0.8, 0.6, 0.5],
            'North America': [0.7, 0.6, 0.8, 0.9, 1.0, 1.1, 1.3, 1.2, 1.0, 0.9, 0.8, 0.7],
            'Central America': [0.8, 0.7, 0.9, 1.0, 1.1, 1.0, 1.2, 1.1, 1.0, 0.9, 0.8, 0.8],
            'Caribbean': [1.0, 1.0, 1.1, 1.1, 1.2, 1.2, 1.3, 1.3, 1.2, 1.1, 1.0, 1.0],
            'Asia': [0.8, 0.7, 0.9, 1.0, 1.1, 1.0, 1.2, 1.1, 1.0, 0.9, 0.8, 0.8],
            'Middle East': [1.0, 0.9, 1.1, 1.0, 0.8, 0.6, 0.5, 0.6, 0.8, 1.0, 1.1, 1.0],
            'Oceania': [1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1],
            'Pacific Islands': [1.1, 1.1, 1.0, 0.9, 0.8, 0.8, 0.9, 1.0, 1.1, 1.1, 1.1, 1.1],
            'Africa': [0.9, 0.8, 1.0, 1.1, 1.0, 0.9, 0.8, 0.9, 1.0, 1.1, 1.0, 0.9],
            'Sub-Saharan Africa': [0.8, 0.7, 0.9, 1.0, 1.1, 1.0, 0.9, 0.8, 0.9, 1.0, 1.1, 1.0],
            'South America': [0.8, 0.7, 0.9, 1.0, 1.1, 1.0, 0.9, 0.8, 0.9, 1.0, 1.1, 1.0],
        }
        
        # Growth patterns by year (pre-COVID, COVID, recovery)
        year_multipliers = {
            2018: 1.0,  # Baseline
            2019: 1.05, # Pre-COVID growth
            2020: 0.3,  # COVID impact (70% decline)
            2021: 0.6,  # Partial recovery
            2022: 0.85  # Strong recovery
        }
        
        # Generate monthly data for each year
        for year in years:
            year_multiplier = year_multipliers[year]
            
            for month in months:
                seasonal_multiplier = seasonal_patterns[region][month - 1]
                
                # Base monthly arrivals
                base_monthly = base_arrivals / 12 * seasonal_multiplier * year_multiplier
                
                # Add realistic variation
                variation = np.random.normal(0, 0.1)  # 10% standard deviation
                arrivals = max(0, base_monthly * (1 + variation))
                
                # Calculate growth rate (compared to same month previous year)
                if year > 2018:
                    # For simplicity, use a simplified growth calculation
                    growth_rate = (year_multiplier - year_multipliers[year-1]) / year_multipliers[year-1] * 100
                    growth_rate += np.random.normal(0, 5)  # Add some variation
                else:
                    growth_rate = np.random.normal(2, 3)  # Baseline growth
                
                # Calculate per capita arrivals
                arrivals_per_capita = arrivals / population
                
                # Source market diversity (0-1 scale, higher = more diverse)
                source_diversity = np.random.uniform(0.4, 0.9)
                
                # Peak and off-peak season arrivals (for seasonal analysis)
                if month in [6, 7, 8, 12]:  # Peak months
                    peak_arrivals = arrivals * 1.5
                    off_peak_arrivals = arrivals * 0.6
                else:
                    peak_arrivals = arrivals * 0.8
                    off_peak_arrivals = arrivals * 1.2
                
                # Add some realistic noise to peak/off-peak
                peak_arrivals *= np.random.uniform(0.9, 1.1)
                off_peak_arrivals *= np.random.uniform(0.9, 1.1)
                
                data.append({
                    'Country': country,
                    'Country_Code': country[:3].upper(),
                    'Region': region,
                    'Year': year,
                    'Month': month,
                    'Arrivals': int(arrivals),
                    'Arrivals_Growth_Rate': round(growth_rate, 1),
                    'Arrivals_Per_Capita': round(arrivals_per_capita, 6),
                    'Source_Market_Diversity': round(source_diversity, 2),
                    'Peak_Season_Arrivals': int(peak_arrivals),
                    'Off_Season_Arrivals': int(off_peak_arrivals),
                    'Population': population,
                    'GDP_Per_Capita': gdp_per_capita,
                    'Tourism_Maturity': tourism_maturity
                })
    
    return pd.DataFrame(data)

def generate_hotel_bookings_dataset(tourism_df):
    """
    Generate hotel bookings dataset that correlates with tourism arrivals
    """
    data = []
    
    for _, row in tourism_df.iterrows():
        # Hotel bookings correlate with arrivals but with some variation
        booking_rate = np.random.uniform(0.6, 0.9)  # 60-90% of arrivals book hotels
        bookings = int(row['Arrivals'] * booking_rate)
        
        # Average daily rate varies by region and maturity
        base_adr = row['GDP_Per_Capita'] * 0.1  # Base rate as % of GDP per capita
        if row['Tourism_Maturity'] == 'mature':
            base_adr *= 1.2
        elif row['Tourism_Maturity'] == 'emerging':
            base_adr *= 0.8
        
        # Seasonal variation in ADR
        if row['Month'] in [6, 7, 8, 12]:  # Peak months
            adr = base_adr * np.random.uniform(1.3, 1.8)
        else:
            adr = base_adr * np.random.uniform(0.7, 1.2)
        
        # Occupancy rate
        occupancy = np.random.uniform(0.4, 0.95)
        
        # Revenue
        revenue = bookings * adr * occupancy
        
        data.append({
            'Country': row['Country'],
            'Country_Code': row['Country_Code'],
            'Region': row['Region'],
            'Year': row['Year'],
            'Month': row['Month'],
            'Hotel_Bookings': bookings,
            'Average_Daily_Rate': round(adr, 2),
            'Occupancy_Rate': round(occupancy, 3),
            'Revenue': round(revenue, 2),
            'Tourism_Maturity': row['Tourism_Maturity']
        })
    
    return pd.DataFrame(data)

def generate_flight_data_dataset(tourism_df):
    """
    Generate flight data dataset that correlates with tourism arrivals
    """
    data = []
    
    for _, row in tourism_df.iterrows():
        # Flight capacity correlates with arrivals
        capacity_factor = np.random.uniform(1.2, 1.8)  # Airlines typically have 20-80% more capacity
        capacity = int(row['Arrivals'] * capacity_factor)
        
        # Load factor (how full flights are)
        load_factor = np.random.uniform(0.6, 0.95)
        
        # Actual passengers
        passengers = int(capacity * load_factor)
        
        # Average ticket price varies by region and distance
        base_ticket_price = row['GDP_Per_Capita'] * 0.05  # Base as % of GDP per capita
        if row['Region'] == 'Europe':
            base_ticket_price *= 0.8  # Shorter distances
        elif row['Region'] in ['Asia', 'Oceania']:
            base_ticket_price *= 1.5  # Longer distances
        
        # Seasonal variation
        if row['Month'] in [6, 7, 8, 12]:  # Peak months
            ticket_price = base_ticket_price * np.random.uniform(1.2, 1.6)
        else:
            ticket_price = base_ticket_price * np.random.uniform(0.8, 1.1)
        
        # Revenue
        revenue = passengers * ticket_price
        
        data.append({
            'Country': row['Country'],
            'Country_Code': row['Country_Code'],
            'Region': row['Region'],
            'Year': row['Year'],
            'Month': row['Month'],
            'Flight_Capacity': capacity,
            'Passengers': passengers,
            'Load_Factor': round(load_factor, 3),
            'Average_Ticket_Price': round(ticket_price, 2),
            'Revenue': round(revenue, 2),
            'Tourism_Maturity': row['Tourism_Maturity']
        })
    
    return pd.DataFrame(data)

def generate_tourism_revenue_dataset(tourism_df):
    """
    Generate tourism revenue dataset that combines all revenue streams
    """
    data = []
    
    for _, row in tourism_df.iterrows():
        # Base revenue per tourist varies by region and maturity
        base_revenue_per_tourist = row['GDP_Per_Capita'] * 0.3  # 30% of GDP per capita
        
        if row['Tourism_Maturity'] == 'mature':
            base_revenue_per_tourist *= 1.3
        elif row['Tourism_Maturity'] == 'emerging':
            base_revenue_per_tourist *= 0.7
        
        # Seasonal variation
        if row['Month'] in [6, 7, 8, 12]:  # Peak months
            revenue_per_tourist = base_revenue_per_tourist * np.random.uniform(1.2, 1.5)
        else:
            revenue_per_tourist = base_revenue_per_tourist * np.random.uniform(0.8, 1.1)
        
        # Total revenue
        total_revenue = row['Arrivals'] * revenue_per_tourist
        
        # Revenue breakdown
        accommodation_revenue = total_revenue * np.random.uniform(0.3, 0.5)
        transportation_revenue = total_revenue * np.random.uniform(0.2, 0.3)
        food_beverage_revenue = total_revenue * np.random.uniform(0.15, 0.25)
        activities_revenue = total_revenue * np.random.uniform(0.1, 0.2)
        
        data.append({
            'Country': row['Country'],
            'Country_Code': row['Country_Code'],
            'Region': row['Region'],
            'Year': row['Year'],
            'Month': row['Month'],
            'Total_Revenue': round(total_revenue, 2),
            'Accommodation_Revenue': round(accommodation_revenue, 2),
            'Transportation_Revenue': round(transportation_revenue, 2),
            'Food_Beverage_Revenue': round(food_beverage_revenue, 2),
            'Activities_Revenue': round(activities_revenue, 2),
            'Revenue_Per_Tourist': round(revenue_per_tourist, 2),
            'Tourism_Maturity': row['Tourism_Maturity']
        })
    
    return pd.DataFrame(data)

def main():
    """
    Generate all datasets and save them to CSV files
    """
    print("Generating comprehensive tourism dataset...")
    
    # Generate main tourism arrivals dataset
    tourism_df = generate_tourism_dataset()
    tourism_df.to_csv('Tourism_Arrivals_Enhanced.csv', index=False)
    print(f"Generated Tourism_Arrivals_Enhanced.csv with {len(tourism_df)} records")
    
    # Generate hotel bookings dataset
    hotel_df = generate_hotel_bookings_dataset(tourism_df)
    hotel_df.to_csv('Hotel_Bookings_Enhanced.csv', index=False)
    print(f"Generated Hotel_Bookings_Enhanced.csv with {len(hotel_df)} records")
    
    # Generate flight data dataset
    flight_df = generate_flight_data_dataset(tourism_df)
    flight_df.to_csv('Flight_Data_Enhanced.csv', index=False)
    print(f"Generated Flight_Data_Enhanced.csv with {len(flight_df)} records")
    
    # Generate tourism revenue dataset
    revenue_df = generate_tourism_revenue_dataset(tourism_df)
    revenue_df.to_csv('Tourism_Revenue_Enhanced.csv', index=False)
    print(f"Generated Tourism_Revenue_Enhanced.csv with {len(revenue_df)} records")
    
    # Create dataset summary
    summary = {
        'total_countries': int(len(tourism_df['Country'].unique())),
        'total_regions': int(len(tourism_df['Region'].unique())),
        'years_covered': [int(y) for y in tourism_df['Year'].unique()],
        'total_records': int(len(tourism_df)),
        'countries_by_region': {k: int(v) for k, v in tourism_df.groupby('Region')['Country'].nunique().to_dict().items()},
        'maturity_distribution': {k: int(v) for k, v in tourism_df.groupby('Tourism_Maturity')['Country'].nunique().to_dict().items()}
    }
    
    with open('dataset_summary.json', 'w') as f:
        json.dump(summary, f, indent=2)
    
    print("\nDataset Summary:")
    print(f"- Countries: {summary['total_countries']}")
    print(f"- Regions: {summary['total_regions']}")
    print(f"- Years: {summary['years_covered']}")
    print(f"- Total Records: {summary['total_records']}")
    print("\nCountries by Region:")
    for region, count in summary['countries_by_region'].items():
        print(f"  {region}: {count} countries")
    print("\nMaturity Distribution:")
    for maturity, count in summary['maturity_distribution'].items():
        print(f"  {maturity}: {count} countries")
    
    print("\nAll datasets generated successfully in enhanced_dataset/ folder!")

if __name__ == "__main__":
    main() 