# Advanced Time Series Analysis

## Overview
This repository contains a script for advanced time series analysis on Formula 1 racing data. The analysis includes cleaning and preprocessing data, building time series models, forecasting future performance, and predicting top-10 finishes using logistic regression.

## Features

### 1. Data Loading and Cleaning
- Loads Formula 1 results data from an Excel file using the `readxl` package.
- Handles missing values and converts date columns to appropriate formats.
- Computes cumulative and moving averages for metrics such as points and laps.

### 2. Feature Engineering
- Extracts time-based features like year and event month.
- Adds cumulative points, moving averages, and other key features for drivers.

### 3. Time Series Modeling
- Ensures time series continuity by filling gaps for each driver's sequence.
- Uses `tsibble` objects for advanced time series analysis.

### 4. Forecasting with ARIMA
- Fits an ARIMA model to predict driver points over time.
- Evaluates model performance using residuals and test data accuracy.
- Forecasts future performance up to 12 months and saves output as a CSV file.

### 5. Predictive Modeling with Logistic Regression
- Creates a binary target variable for top-10 finishes.
- Trains a logistic regression model on features like cumulative points and average speeds.
- Predicts outcomes and evaluates accuracy with visual comparisons of actual and predicted results.

### 6. Visualizations
- Generates dynamic plots for insights:
  - Driver points over time.
  - Forecasted vs. actual test data.
  - Predicted vs. actual top-10 finishes.

## Getting Started

### Prerequisites
Ensure you have the following R libraries installed:
```r
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
