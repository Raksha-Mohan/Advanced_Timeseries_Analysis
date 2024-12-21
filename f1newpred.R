# Load necessary libraries
library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)
library(modeltime)
library(tidymodels)
library(timetk)
library(zoo) 
library(fable)
library(forecast)

# Specify the correct file path using forward slashes
file_path <- "C:/Users/raksh/OneDrive/Desktop/F1 Race Outcomes -Advanced Time Series Models/F1 data.xlsx"  # Update this path

# Read the dataset
f1_data <- read_excel(file_path, sheet = "results")

# View the structure of the dataset to check the 'round' column type
str(f1_data)

# Handle missing values (replace NA with 0 or appropriate strategies)
f1_data <- f1_data %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0))) %>%
  mutate(date = as.Date(date, format = "%Y-%m-%d"))

# Create time-based features, excluding 'round' column
f1_data <- f1_data %>%
  mutate(year = year(date),
         event_month = month(date, label = TRUE),
         cumulative_points = ave(points, driverId, FUN = cumsum))

# Select relevant columns for analysis, ignoring 'round'
df_clean <- f1_data %>%
  select(code, date, points, fastestLapSpeed, position, laps) %>%
  mutate(
    year = year(date)                # Extract the year from the date
  )

# Remove rows with missing `points`
df_clean <- df_clean %>%
  filter(!is.na(points)) %>%
  group_by(code) %>%
  arrange(date)

# Create cumulative points and moving averages (over last 3 races)
df_clean <- df_clean %>%
  group_by(code) %>%
  mutate(
    cum_points = cumsum(points),
    avg_points = zoo::rollapply(points, width = 3, FUN = mean, fill = 0, align = "right"),
    avg_laps = zoo::rollapply(laps, width = 3, FUN = mean, fill = 0, align = "right")
  )

# Optionally, you can inspect the cleaned data
glimpse(df_clean)

# Remove rows where 'code' is NA (invalid data rows)
df_clean <- df_clean %>%
  filter(!is.na(code))

# Ensure time series continuity by filling gaps in the date column for each driver
df_clean <- df_clean %>%
  group_by(code) %>%
  complete(date = seq.Date(min(date), max(date), by = "day"), fill = list(points = 0)) %>%
  fill(cum_points, avg_points, avg_laps, .direction = "down") %>%
  ungroup()  # Ungroup after the operation to avoid further issues with grouping

# Filter data for a specific driver by their `code` (replace "DRIVER_CODE" with actual code)
driver_data <- df_clean %>%
  filter(code == "HAM") %>%
  select(date, points, cum_points, avg_points) %>%
  as_tsibble(index = date)  # Convert to a time series object

# Visualize the points over time
ggplot(driver_data, aes(x = date, y = points)) +
  geom_line(color = "blue") +
  labs(title = "Driver's Points Over Time", x = "Date", y = "Points")

# Split data into training and testing sets
train_end_date <- max(driver_data$date) - months(6)  # Use last 6 months as the test set

train_data <- driver_data %>%
  filter(date <= train_end_date)

test_data <- driver_data %>%
  filter(date > train_end_date)

# Fit an ARIMA model to the training data
model <- train_data %>%
  model(ARIMA(points ~ trend() + season()))

# Print model summary
report(model)

# Extract residuals from the model
residuals_data <- residuals(model)

# View the structure of residuals_data to check the columns
glimpse(residuals_data)

# Forecast on the test data (6 months ahead)
forecast <- model %>%
  forecast(h = "6 months")

# Visualize the forecast vs actual test data
autoplot(forecast, test_data) +
  labs(title = "Forecast vs Actual", x = "Date", y = "Points")

# Evaluate forecast accuracy
accuracy(forecast, test_data)

# Forecast future performance for the next 12 months
future_forecast <- model %>%
  forecast(h = "12 months")

# Visualize the forecast
autoplot(future_forecast) +
  labs(title = "Future Performance Forecast", x = "Date", y = "Points")

# Save the forecast to a CSV file
write.csv(as.data.frame(future_forecast), "future_forecast.csv", row.names = FALSE)

# Create the binary target variable 'top_10_finish'
df_clean <- df_clean %>%
  mutate(
    position = replace_na(position, 20),  # Replace NA positions with 20
    fastestLapSpeed = replace_na(fastestLapSpeed, median(fastestLapSpeed, na.rm = TRUE)),  # Replace NA speeds with median
    top_10_finish = factor(ifelse(position <= 10, 1, 0))
  )

# Split data into training and testing sets (the same way as before)
train_data <- df_clean %>%
  filter(date <= train_end_date)

test_data <- df_clean %>%
  filter(date > train_end_date)

# logistic regression model
log_reg_model <- glm(top_10_finish ~ cum_points + avg_points + fastestLapSpeed + laps, 
                     data = train_data, 
                     family = binomial())

# Print model summary
summary(log_reg_model)

# Make predictions on the test data
test_data$predictions <- predict(log_reg_model, newdata = test_data, type = "response")
test_data$predicted_class <- factor(ifelse(test_data$predictions > 0.5, 1, 0))

# Calculate and print accuracy
accuracy <- mean(test_data$predicted_class == test_data$top_10_finish, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))

# Visualize the predicted vs actual classifications
ggplot(test_data, aes(x = date)) +
  geom_line(aes(y = as.numeric(top_10_finish) - 1, color = "Actual"), size = 1) +
  geom_line(aes(y = as.numeric(predicted_class) - 1, color = "Predicted"), size = 1) +
  labs(title = "Actual vs Predicted Top 10 Finishes", x = "Date", y = "Top 10 Finish")