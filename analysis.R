# ============================================================
# Sleep Duration and Systolic Blood Pressure
# NHANES 2013-2018
# Nidhi S. Perla
# ============================================================

# Required packages:
# tidyverse
# haven
# survey

library(tidyverse)
library(haven)
library(survey)

# ============================================================
# 1. Helper function for standardized SBP averaging
# ============================================================

# If only one SBP reading is available, use that reading.
# If multiple readings are available, exclude the first reading
# and average the remaining available readings.

calculate_nhanes_bp <- function(r1, r2, r3, r4) {

  result <- rep(NA_real_, length(r1))

  for (i in seq_along(r1)) {

    readings <- c(r1[i], r2[i], r3[i], r4[i])
    available <- readings[!is.na(readings)]

    if (length(available) == 0) {

      result[i] <- NA_real_

    } else if (length(available) == 1) {

      result[i] <- available[1]

    } else {

      later_readings <- c(r2[i], r3[i], r4[i])
      later_readings <- later_readings[!is.na(later_readings)]

      if (length(later_readings) > 0) {
        result[i] <- mean(later_readings)
      } else {
        result[i] <- r1[i]
      }
    }
  }

  result
}


# ============================================================
# 2. Function to prepare one NHANES cycle
# ============================================================

prepare_cycle <- function(
  sleep_url,
  bp_url,
  demo_url,
  body_url,
  smoking_url,
  cycle_label,
  sleep_variable
) {

  sleep_raw <- read_xpt(sleep_url)
  bp_raw <- read_xpt(bp_url)
  demo_raw <- read_xpt(demo_url)
  body_raw <- read_xpt(body_url)
  smoking_raw <- read_xpt(smoking_url)

  # ----------------------------------------------------------
  # Sleep
  # ----------------------------------------------------------

  sleep_clean <- sleep_raw %>%
    transmute(
      SEQN,
      sleep_hours = .data[[sleep_variable]]
    ) %>%
    filter(!is.na(sleep_hours))

  # ----------------------------------------------------------
  # Systolic blood pressure
  # ----------------------------------------------------------

  bp_clean <- bp_raw %>%
    transmute(
      SEQN,
      mean_sbp = calculate_nhanes_bp(
        BPXSY1,
        BPXSY2,
        BPXSY3,
        BPXSY4
      )
    ) %>%
    filter(!is.na(mean_sbp))

  # ----------------------------------------------------------
  # Demographics and survey variables
  # ----------------------------------------------------------

  demo_clean <- demo_raw %>%
    transmute(
      SEQN,
      age = RIDAGEYR,

      sex = factor(
        RIAGENDR,
        levels = c(1, 2),
        labels = c("Male", "Female")
      ),

      race_ethnicity = factor(
        RIDRETH3,
        levels = c(1, 2, 3, 4, 6, 7),
        labels = c(
          "Mexican American",
          "Other Hispanic",
          "Non-Hispanic White",
          "Non-Hispanic Black",
          "Non-Hispanic Asian",
          "Other/Multiracial"
        )
      ),

      WTMEC2YR,
      SDMVSTRA,
      SDMVPSU
    )

  # ----------------------------------------------------------
  # BMI
  # ----------------------------------------------------------

  body_clean <- body_raw %>%
    transmute(
      SEQN,
      bmi = BMXBMI
    ) %>%
    filter(!is.na(bmi))

  # ----------------------------------------------------------
  # Smoking status
  # ----------------------------------------------------------

  smoking_clean <- smoking_raw %>%
    transmute(
      SEQN,

      smoking_status = case_when(
        SMQ020 == 2 ~ "Never",
        SMQ020 == 1 & SMQ040 == 3 ~ "Former",
        SMQ020 == 1 & SMQ040 %in% c(1, 2) ~ "Current",
        TRUE ~ NA_character_
      ),

      smoking_status = factor(
        smoking_status,
        levels = c("Never", "Former", "Current")
      )
    ) %>%
    filter(!is.na(smoking_status))

  # ----------------------------------------------------------
  # Merge cycle data
  # ----------------------------------------------------------

  cycle_data <- sleep_clean %>%
    inner_join(bp_clean, by = "SEQN") %>%
    inner_join(demo_clean, by = "SEQN") %>%
    inner_join(body_clean, by = "SEQN") %>%
    inner_join(smoking_clean, by = "SEQN") %>%
    filter(age >= 18) %>%
    mutate(
      cycle = cycle_label,

      sleep_category = case_when(
        sleep_hours < 6 ~ "<6 h",
        sleep_hours >= 6 & sleep_hours < 7 ~ "6-<7 h",
        sleep_hours >= 7 & sleep_hours < 9 ~ "7-<9 h",
        sleep_hours >= 9 ~ ">=9 h",
        TRUE ~ NA_character_
      ),

      sleep_category = factor(
        sleep_category,
        levels = c(
          "7-<9 h",
          "6-<7 h",
          "<6 h",
          ">=9 h"
        )
      )
    ) %>%
    filter(!is.na(sleep_category))

  return(cycle_data)
}


# ============================================================
# 3. Prepare NHANES 2013-2014
# ============================================================

nhanes_1314 <- prepare_cycle(
  sleep_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/SLQ_H.XPT",

  bp_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/BPX_H.XPT",

  demo_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/DEMO_H.XPT",

  body_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/BMX_H.XPT",

  smoking_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2013/DataFiles/SMQ_H.XPT",

  cycle_label = "2013-2014",

  sleep_variable = "SLD010H"
)


# ============================================================
# 4. Prepare NHANES 2015-2016
# ============================================================

nhanes_1516 <- prepare_cycle(
  sleep_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/SLQ_I.XPT",

  bp_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/BPX_I.XPT",

  demo_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/DEMO_I.XPT",

  body_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/BMX_I.XPT",

  smoking_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles/SMQ_I.XPT",

  cycle_label = "2015-2016",

  sleep_variable = "SLD012"
)


# ============================================================
# 5. Prepare NHANES 2017-2018
# ============================================================

nhanes_1718 <- prepare_cycle(
  sleep_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SLQ_J.XPT",

  bp_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/BPX_J.XPT",

  demo_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/DEMO_J.XPT",

  body_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/BMX_J.XPT",

  smoking_url =
    "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/SMQ_J.XPT",

  cycle_label = "2017-2018",

  sleep_variable = "SLD012"
)


# ============================================================
# 6. Pool the three survey cycles
# ============================================================

pooled_data <- bind_rows(
  nhanes_1314,
  nhanes_1516,
  nhanes_1718
) %>%
  mutate(
    cycle = factor(
      cycle,
      levels = c(
        "2013-2014",
        "2015-2016",
        "2017-2018"
      )
    ),

    # Three consecutive 2-year cycles are pooled.
    WTMEC6YR = WTMEC2YR / 3
  )


# ============================================================
# 7. Inspect analytic sample
# ============================================================

cat("\nFinal pooled analytic sample:\n")
print(nrow(pooled_data))

cat("\nParticipants by survey cycle:\n")
print(table(pooled_data$cycle))

cat("\nParticipants by sleep category:\n")
print(table(pooled_data$sleep_category))

cat("\nSummary of systolic blood pressure:\n")
print(summary(pooled_data$mean_sbp))


# ============================================================
# 8. Create pooled NHANES survey design
# ============================================================

pooled_design <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTMEC6YR,
  nest = TRUE,
  data = pooled_data
)

cat("\nSurvey design degrees of freedom:\n")
print(degf(pooled_design))


# ============================================================
# 9. Model 1: unadjusted
# ============================================================

model_unadjusted <- svyglm(
  mean_sbp ~ sleep_category,
  design = pooled_design
)


# ============================================================
# 10. Model 2: primary adjusted model
# ============================================================

model_primary <- svyglm(
  mean_sbp ~
    sleep_category +
    age +
    sex +
    bmi +
    smoking_status +
    cycle,
  design = pooled_design
)


# ============================================================
# 11. Model 3: additional race/ethnicity adjustment
# ============================================================

model_race <- svyglm(
  mean_sbp ~
    sleep_category +
    age +
    sex +
    bmi +
    smoking_status +
    cycle +
    race_ethnicity,
  design = pooled_design
)


# ============================================================
# 12. Extract primary <6 h vs 7-<9 h results
# ============================================================

extract_short_sleep <- function(model) {

  term <- "sleep_category<6 h"
  ci <- confint(model)

  data.frame(
    Estimate_mmHg =
      unname(coef(model)[term]),

    CI_lower =
      unname(ci[term, 1]),

    CI_upper =
      unname(ci[term, 2]),

    p_value =
      unname(
        summary(model)$coefficients[
          term,
          "Pr(>|t|)"
        ]
      )
  )
}


model_results <- bind_rows(

  cbind(
    Model = "Unadjusted",
    extract_short_sleep(model_unadjusted)
  ),

  cbind(
    Model = "Adjusted: age, sex, BMI, smoking, cycle",
    extract_short_sleep(model_primary)
  ),

  cbind(
    Model = "Adjusted + race/ethnicity",
    extract_short_sleep(model_race)
  )

) %>%
  mutate(
    Estimate_mmHg = round(Estimate_mmHg, 2),
    CI_lower = round(CI_lower, 2),
    CI_upper = round(CI_upper, 2),
    p_value = signif(p_value, 3)
  )

cat("\nFinal pooled model results:\n")
print(model_results)


# ============================================================
# 13. Cycle-specific primary models
# ============================================================

run_cycle_model <- function(data, label) {

  design_cycle <- svydesign(
    ids = ~SDMVPSU,
    strata = ~SDMVSTRA,
    weights = ~WTMEC2YR,
    nest = TRUE,
    data = data
  )

  model_cycle <- svyglm(
    mean_sbp ~
      sleep_category +
      age +
      sex +
      bmi +
      smoking_status,
    design = design_cycle
  )

  term <- "sleep_category<6 h"
  ci <- confint(model_cycle)

  data.frame(
    Survey_Cycle = label,
    Estimate_mmHg =
      unname(coef(model_cycle)[term]),
    CI_lower =
      unname(ci[term, 1]),
    CI_upper =
      unname(ci[term, 2])
  )
}


cycle_specific_results <- bind_rows(

  run_cycle_model(
    filter(pooled_data, cycle == "2013-2014"),
    "2013-2014"
  ),

  run_cycle_model(
    filter(pooled_data, cycle == "2015-2016"),
    "2015-2016"
  ),

  run_cycle_model(
    filter(pooled_data, cycle == "2017-2018"),
    "2017-2018"
  )

)


pooled_ci <- confint(model_primary)

pooled_result <- data.frame(
  Survey_Cycle = "Pooled 2013-2018",

  Estimate_mmHg =
    unname(
      coef(model_primary)["sleep_category<6 h"]
    ),

  CI_lower =
    unname(
      pooled_ci[
        "sleep_category<6 h",
        1
      ]
    ),

  CI_upper =
    unname(
      pooled_ci[
        "sleep_category<6 h",
        2
      ]
    )
)


cycle_specific_results <- bind_rows(
  cycle_specific_results,
  pooled_result
) %>%
  mutate(
    Estimate_mmHg = round(Estimate_mmHg, 2),
    CI_lower = round(CI_lower, 2),
    CI_upper = round(CI_upper, 2)
  )

cat("\nCycle-specific and pooled estimates:\n")
print(cycle_specific_results)


# ============================================================
# 14. Sleep category x survey cycle interaction
# ============================================================

interaction_model <- svyglm(
  mean_sbp ~
    sleep_category * cycle +
    age +
    sex +
    bmi +
    smoking_status,
  design = pooled_design
)

interaction_test <- regTermTest(
  interaction_model,
  ~sleep_category:cycle
)

cat("\nSleep category x survey cycle interaction:\n")
print(interaction_test)


# ============================================================
# 15. Final forest plot
# ============================================================

forest_data <- cycle_specific_results %>%
  mutate(
    Survey_Cycle = factor(
      Survey_Cycle,
      levels = rev(c(
        "2013-2014",
        "2015-2016",
        "2017-2018",
        "Pooled 2013-2018"
      ))
    )
  )


forest_plot <- ggplot(
  forest_data,
  aes(
    x = Estimate_mmHg,
    y = Survey_Cycle
  )
) +

  geom_vline(
    xintercept = 0,
    linetype = "dashed"
  ) +

  geom_errorbarh(
    aes(
      xmin = CI_lower,
      xmax = CI_upper
    ),
    height = 0.12
  ) +

  geom_point(
    size = 3
  ) +

  labs(
    title =
      "Very Short Weekday Sleep and Systolic Blood Pressure Across Survey Cycles",

    subtitle =
      "<6 hours compared with 7–<9 hours of weekday sleep",

    x =
      "Adjusted Difference in Systolic Blood Pressure (mmHg)",

    y = NULL,

    caption =
      "Cycle-specific models adjusted for age, sex, BMI, and smoking status; pooled model additionally adjusted for survey cycle."
  ) +

  theme_classic(base_size = 12)


forest_plot


# ============================================================
# 16. Save outputs
# ============================================================

write.csv(
  model_results,
  "model_results.csv",
  row.names = FALSE
)

write.csv(
  cycle_specific_results,
  "cycle_specific_results.csv",
  row.names = FALSE
)

ggsave(
  "sleep_sbp_adjusted.png",
  plot = forest_plot,
  width = 8,
  height = 5,
  dpi = 300
)


# ============================================================
# 17. Key final results
# ============================================================

cat("\n============================================\n")
cat("FINAL STUDY SUMMARY\n")
cat("============================================\n")

cat("\nAnalytic sample N:\n")
print(nrow(pooled_data))

cat("\nPrimary pooled models:\n")
print(model_results)

cat("\nCycle-specific results:\n")
print(cycle_specific_results)

cat("\nCycle interaction:\n")
print(interaction_test)
