# Sleep Duration and Cardiovascular Health

## Overview

This project examines the relationship between weekday sleep duration and systolic blood pressure using publicly available data from the National Health and Nutrition Examination Survey (NHANES) 2017–2018 cycle.

The goal was to investigate whether sleep duration is associated with systolic blood pressure and whether the relationship is better described as linear or nonlinear after accounting for demographic and cardiovascular risk factors.

## Research Question

Is weekday sleep duration associated with mean systolic blood pressure among U.S. adults after adjustment for age, sex, BMI, and smoking status?

## Data Source

Data were obtained from the 2017–2018 National Health and Nutrition Examination Survey (NHANES).

Multiple NHANES datasets were merged using the participant identifier `SEQN`, including:

- Sleep questionnaire data
- Blood pressure examination data
- Demographic data
- Body measurement data
- Smoking questionnaire data

## Variables

**Primary exposure**
- Weekday sleep duration

**Outcome**
- Mean systolic blood pressure

**Covariates**
- Age
- Sex
- Body mass index (BMI)
- Smoking status

## Methods

Analyses were performed in R.

The workflow included:

- Importing NHANES `.XPT` files
- Cleaning and merging datasets using `SEQN`
- Calculating mean systolic blood pressure from repeated measurements
- Creating smoking-status categories
- Exploratory data analysis and visualization
- Linear regression
- Quadratic regression
- Survey-weighted multivariable regression
- Adjustment for NHANES sampling weights, strata, and primary sampling units

The final analytic sample included **5,142 participants** with complete data for the variables included in the survey-weighted model.

## Results

The initial unadjusted correlation between weekday sleep duration and mean systolic blood pressure was very small (`r = -0.022`).

In the survey-weighted multivariable linear model, weekday sleep duration showed essentially no linear association with mean systolic blood pressure after adjustment for age, sex, BMI, and smoking status.

When a quadratic sleep-duration term was added, evidence of a nonlinear relationship emerged.

The quadratic sleep term was statistically significant:

- **β = 0.259**
- **SE = 0.093**
- **p = 0.023**

The fitted curve suggested a shallow U-shaped association, with the lowest predicted systolic blood pressure occurring at approximately **7.6 hours of weekday sleep**.

Because NHANES is observational and cross-sectional, these findings should not be interpreted as evidence that sleep duration causes changes in blood pressure.

## Figure

![Survey-weighted association between sleep duration and systolic blood pressure](sleep_sbp_adjusted.png)

The figure shows predicted mean systolic blood pressure from the survey-weighted nonlinear model, adjusted for age, sex, BMI, and smoking status.

## Files

- `analysis.R` — complete R analysis
- `model_results.csv` — survey-weighted model coefficients and p-values
- `sleep_sbp_adjusted.png` — final adjusted figure
- `README.md` — project overview and findings

## Tools and Skills

- R
- tidyverse
- ggplot2
- haven
- survey
- Data cleaning
- Dataset merging
- Exploratory data analysis
- Multiple linear regression
- Nonlinear modeling
- Complex survey analysis
- Data visualization

## Limitations

- NHANES data are cross-sectional, so causal conclusions cannot be made.
- Weekday sleep duration is self-reported.
- Residual confounding may remain despite adjustment for major demographic and cardiovascular risk factors.
- The quadratic model provides a simplified representation of the relationship between sleep duration and blood pressure.
- Findings are specific to the NHANES 2017–2018 cycle and analytic sample used in this project.

## Author

**Nidhi S. Perla**  
University of South Florida
