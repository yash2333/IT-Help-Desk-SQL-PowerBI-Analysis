# IT Help Desk Analytics — SQL & Power BI

An end-to-end data analytics project analyzing IT Help Desk cases to understand resolution performance, SLA compliance, agent efficiency, workload, priority risk, monthly trends, and case severity.

## Tools & Technologies
- MySQL / SQL
- Power BI
- DAX
- Excel (data preparation, where applicable)

## Project Objective
The objective of this project is to transform IT Help Desk case data into useful operational insights for monitoring service performance and identifying areas that may require attention.

## SQL Analysis
The SQL analysis includes:
1. Average resolution time for each service agent
2. Agents with above-average resolution time
3. Overall SLA compliance
4. Agent speed ranking
5. SLA compliance and risk ranking by priority
6. Month-over-month change in average resolution time
7. Case type with the worst SLA compliance each month
8. Monthly resolved cases and running total
9. Weekly workload for the top 5 agents by total case volume
10. Impact of case severity on resolution time and SLA compliance

## SQL Concepts Demonstrated
- SELECT, WHERE, GROUP BY, ORDER BY
- CASE expressions
- Aggregate functions: COUNT, SUM, AVG
- CTEs (`WITH`)
- CROSS JOIN
- INNER JOIN
- Window functions
- RANK()
- LAG()
- Running totals
- Date/time functions
- `STR_TO_DATE()`
- `TIMESTAMPDIFF()`
- `YEAR()`, `MONTH()`, `YEARWEEK()`

## Data Preparation
A working SQL view named `case_data` converts the source case sent and resolution timestamps into proper DATETIME values. The source contains two date formats, so conditional `STR_TO_DATE()` logic is used before analysis.

## SLA Logic
The SQL analysis uses the following priority-based SLA targets from the project:
- 3_High → 4 hours
- 2_Medium → 8 hours
- 1_Low → 24 hours
- 0_Unassigned → 72 hours

## Power BI
The companion Power BI report is used to present the analytical results as an interactive dashboard. Add screenshots of the final dashboard to the `PowerBI` folder.

## Repository Structure
```text
IT-Help-Desk-SQL-PowerBI-Analysis/
├── README.md
├── SQL/
│   └── IT_Help_Desk_Analysis.sql
├── PowerBI/
│   └── dashboard-screenshot.png
└── Insights/
    └── business_insights.md
```

## Note
This repository documents the analysis performed in the project SQL script. Business conclusions should be based on the actual query outputs/dashboard values rather than assumed results.
