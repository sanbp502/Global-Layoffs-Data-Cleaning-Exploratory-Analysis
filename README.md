# Global Layoffs Data Cleaning and Exploratory Analysis
# Overview
This project analyzes global company layoffs between 2020 and 2023 in order to identify  patterns with applications for business risk, capital efficiency, and resilience based on industry, company size, and funding stage. SQL was used in order to transform, clean, and explore the data, drawing insights from a large dataset of real-world corporate events during and after the COVID-19 pandemic.

# Dataset Description
The dataset contains over 2,000+ records of company layoffs with the following attributes:
- Company name and location
- Industry and country
- Funding stage (e.g., Seed, Series A–D, Post-IPO)
- Total employees laid off
- Percentage of workforce laid off
- Date of layoff event
- Funds raised (in millions USD)

# Tools and Techniques
The project used SQL in the MySQL platform, and required Common Table Expressions (CTEs), window functions, aggregations, rolling metrics, and staging tables for data handling.

# Data Cleaning
Preparing the data for analysis included:
- Removing duplicates through window functions when no unique identifier was present
- Standardizing categorical fields including name, industry, or locations
- Converting fields into appropriate types for correct formatting
- Filling blank data where appropriate through available matching entries
- Removing irrelevant records with unreliable data (such as NULL data for both layoff totals and percentages)

# Data Analysis and Key Insights
- Companies that shut down were analyzed by funds raised. Results showed that significant 
  capital investment does not guarantee survival, with many companies that repeatedly laid off workers on different instances still shutting down, serving as potential case studies.
- Layoff size and failure rate was analyzed by funding stage, with early stage companies like Seed and Series A having shutdowns at higher rates compared to companies at later funding stages, even if these companies had bigger layoffs. This follows typical business lifecycle risk profiles
- Aggregation and rolling totals revealed moderate layoffs through 2020 and 2021, with a sharp increase in late 2022 and 2023 showing 5 months accounting for nearly half of all layoffs in the dataset. Ranking showed large technology companies being partly responsible   for this sharp increase.
- Further analysis may include the mentioned case studies with areas like industry, funding allocation, local market, and management in order to better comprehend reasons for shutdown. Insights can be considered for investment allocation based on industry, funding stage, and job growth market.
