# Sleep Duration and Cardiovascular Health
# NHANES 2017-2018
# Nidhi S. Perla

# Install packages needed for this project
install.packages(c("tidyverse", "haven"))

# Load packages
library(tidyverse)
library(haven)
# -----------------------------
# 1. Import NHANES sleep data
# -----------------------------

sleep <- read_xpt(
  "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SLQ_J.XPT"
)

# Look at the dataset
glimpse(sleep)
# Summary of weekday sleep duration
summary(sleep$SLD012)
# Distribution of weekday sleep duration
ggplot(sleep, aes(x = SLD012)) +
  geom_histogram(binwidth = 0.5) +
  labs(
    title = "Distribution of Weekday Sleep Duration",
    x = "Sleep Duration (hours)",
    y = "Number of Participants"
  )
# -----------------------------
# 2. Clean sleep data
# -----------------------------

sleep_clean <- sleep %>%
  select(SEQN, SLD012) %>%
  rename(sleep_hours = SLD012) %>%
  filter(!is.na(sleep_hours))

# Inspect cleaned sleep data
glimpse(sleep_clean)

# Number of participants
nrow(sleep_clean)
# -----------------------------
# 3. Import NHANES blood pressure data
# -----------------------------

bp <- read_xpt(
  "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/BPX_J.XPT"
)

glimpse(bp)
# Keep systolic blood pressure variables and calculate mean SBP

bp_clean <- bp %>%
  select(SEQN, BPXSY1, BPXSY2, BPXSY3, BPXSY4) %>%
  mutate(
    mean_sbp = rowMeans(
      across(c(BPXSY1, BPXSY2, BPXSY3, BPXSY4)),
      na.rm = TRUE
    )
  ) %>%
  filter(!is.nan(mean_sbp))

glimpse(bp_clean)
# -----------------------------
# 4. Merge sleep and blood pressure data
# -----------------------------

sleep_bp <- sleep_clean %>%
  inner_join(bp_clean, by = "SEQN")

# Inspect merged dataset
glimpse(sleep_bp)

# Number of participants with both sleep and BP data
nrow(sleep_bp)
# -----------------------------
# 5. Explore sleep and systolic blood pressure
# -----------------------------

# Summary of mean systolic blood pressure
summary(sleep_bp$mean_sbp)

# Correlation between sleep duration and systolic BP
cor(
  sleep_bp$sleep_hours,
  sleep_bp$mean_sbp,
  use = "complete.obs"
)
ggplot(sleep_bp, aes(x = sleep_hours, y = mean_sbp)) +
  geom_point(alpha = 0.15) +
  geom_smooth(method = "lm") +
  labs(
    title = "Sleep Duration and Systolic Blood Pressure",
    subtitle = "NHANES 2017–2018",
    x = "Weekday Sleep Duration (hours)",
    y = "Mean Systolic Blood Pressure (mmHg)"
  )
# -----------------------------
# 6. Import demographic data
# -----------------------------

demo <- read_xpt(
  "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DEMO_J.XPT"
)

glimpse(demo)
# Keep participant ID, age, and sex

demo_clean <- demo %>%
  select(SEQN, RIDAGEYR, RIAGENDR) %>%
  rename(
    age = RIDAGEYR,
    sex = RIAGENDR
  ) %>%
  mutate(
    sex = factor(
      sex,
      levels = c(1, 2),
      labels = c("Male", "Female")
    )
  )

glimpse(demo_clean)
# -----------------------------
# 7. Import body measurements
# -----------------------------

body <- read_xpt(
  "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/BMX_J.XPT"
)

glimpse(body)
body_clean <- body %>%
  select(SEQN, BMXBMI) %>%
  rename(
    bmi = BMXBMI
  ) %>%
  filter(!is.na(bmi))

glimpse(body_clean)

# -----------------------------
# 8. Add demographics and BMI
# -----------------------------

analysis_data <- sleep_bp %>%
  inner_join(demo_clean, by = "SEQN") %>%
  inner_join(body_clean, by = "SEQN")

glimpse(analysis_data)
nrow(analysis_data)
# -----------------------------
# 9. Multiple linear regression
# -----------------------------

model_adjusted <- lm(
  mean_sbp ~ sleep_hours + age + sex + bmi,
  data = analysis_data
)

summary(model_adjusted)
# -----------------------------
# 10. Test for a nonlinear sleep-BP relationship
# -----------------------------

model_nonlinear <- lm(
  mean_sbp ~ sleep_hours + I(sleep_hours^2) + age + sex + bmi,
  data = analysis_data
)

summary(model_nonlinear)
# Compare linear and nonlinear models
anova(model_adjusted, model_nonlinear)
ggplot(analysis_data, aes(x = sleep_hours, y = mean_sbp)) +
  geom_point(alpha = 0.1) +
  geom_smooth(
    method = "lm",
    formula = y ~ x + I(x^2)
  ) +
  labs(
    title = "Sleep Duration and Systolic Blood Pressure",
    subtitle = "Quadratic fit, NHANES 2017–2018",
    x = "Weekday Sleep Duration (hours)",
    y = "Mean Systolic Blood Pressure (mmHg)"
  )
# -----------------------------
# 11. Import smoking data
# -----------------------------

smoking <- read_xpt(
  "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SMQ_J.XPT"
)

glimpse(smoking)
# Create smoking status variable

smoking_clean <- smoking %>%
  select(SEQN, SMQ020, SMQ040) %>%
  mutate(
    smoking_status = case_when(
      SMQ020 == 2 ~ "Never",
      SMQ020 == 1 & SMQ040 %in% c(1, 2) ~ "Current",
      SMQ020 == 1 & SMQ040 == 3 ~ "Former",
      TRUE ~ NA_character_
    ),
    smoking_status = factor(
      smoking_status,
      levels = c("Never", "Former", "Current")
    )
  ) %>%
  select(SEQN, smoking_status) %>%
  filter(!is.na(smoking_status))

table(smoking_clean$smoking_status)
# -----------------------------
# 12. Add smoking to analysis dataset
# -----------------------------

analysis_final <- analysis_data %>%
  inner_join(smoking_clean, by = "SEQN")

# Check final sample size
nrow(analysis_final)

# Smoking distribution in final analytic sample
table(analysis_final$smoking_status)


library(survey)
# -----------------------------
# 13. Add NHANES survey design variables
# -----------------------------

survey_vars <- demo %>%
  select(SEQN, WTMEC2YR, SDMVSTRA, SDMVPSU)

analysis_survey <- analysis_final %>%
  inner_join(survey_vars, by = "SEQN")

# Check sample size
nrow(analysis_survey)

# Create NHANES survey design object

nhanes_design <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  nest = TRUE,
  data = analysis_survey
)

nhanes_design
# -----------------------------
# 14. Survey-weighted linear regression
# -----------------------------

weighted_model <- svyglm(
  mean_sbp ~ sleep_hours + age + sex + bmi + smoking_status,
  design = nhanes_design
)

summary(weighted_model)

# -----------------------------
# 15. Survey-weighted nonlinear model
# -----------------------------

weighted_nonlinear <- svyglm(
  mean_sbp ~ sleep_hours + I(sleep_hours^2) +
    age + sex + bmi + smoking_status,
  design = nhanes_design
)

summary(weighted_nonlinear)
# --------------------------------
# 16. Final survey-weighted figure
# --------------------------------

# Create sleep values from 3 to 12 hours
prediction_data <- data.frame(
  sleep_hours = seq(3, 12, by = 0.1),
  age = mean(analysis_survey$age, na.rm = TRUE),
  sex = factor("Female", levels = levels(analysis_survey$sex)),
  bmi = mean(analysis_survey$bmi, na.rm = TRUE),
  smoking_status = factor(
    "Never",
    levels = levels(analysis_survey$smoking_status)
  )
)

# Generate predicted systolic blood pressure
pred <- predict(
  weighted_nonlinear,
  newdata = prediction_data,
  se.fit = TRUE
)

prediction_data$predicted_sbp <- as.numeric(pred)

prediction_se <- as.numeric(SE(pred))

prediction_data$lower_ci <- prediction_data$predicted_sbp - 1.96 * prediction_se
prediction_data$upper_ci <- prediction_data$predicted_sbp + 1.96 * prediction_se

# Plot
final_plot <- ggplot() +
  geom_point(
    data = analysis_survey,
    aes(x = sleep_hours, y = mean_sbp),
    alpha = 0.04
  ) +
  geom_ribbon(
    data = prediction_data,
    aes(
      x = sleep_hours,
      ymin = lower_ci,
      ymax = upper_ci
    ),
    alpha = 0.2
  ) +
  geom_line(
    data = prediction_data,
    aes(x = sleep_hours, y = predicted_sbp),
    linewidth = 1
  ) +
  labs(
    title = "Sleep Duration and Systolic Blood Pressure",
    subtitle = "Survey-weighted adjusted model, NHANES 2017–2018",
    x = "Weekday Sleep Duration (hours)",
    y = "Mean Systolic Blood Pressure (mmHg)",
    caption = "Adjusted for age, sex, BMI, and smoking status"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.caption = element_text(hjust = 0),
    plot.margin = margin(10, 10, 20, 10)
  )

final_plot
# Save final figure
ggsave(
  "sleep_sbp_adjusted.png",
  plot = final_plot,
  width = 8,
  height = 6,
  dpi = 300
)
# --------------------------------
# 17. Final model results table
# --------------------------------

# Extract coefficients from survey-weighted nonlinear model
results_table <- as.data.frame(
  summary(weighted_nonlinear)$coefficients
)

# Add variable names as a column
results_table$Variable <- rownames(results_table)

# Reorder columns
results_table <- results_table[, c(
  "Variable",
  "Estimate",
  "Std. Error",
  "t value",
  "Pr(>|t|)"
)]

# Rename columns
colnames(results_table) <- c(
  "Variable",
  "Estimate",
  "Standard_Error",
  "t_value",
  "p_value"
)

# Round numeric values
results_table$Estimate <- round(results_table$Estimate, 3)
results_table$Standard_Error <- round(results_table$Standard_Error, 3)
results_table$t_value <- round(results_table$t_value, 3)
results_table$p_value <- signif(results_table$p_value, 3)

# View table
results_table
# Save final model results
write.csv(
  results_table,
  "model_results.csv",
  row.names = FALSE
)