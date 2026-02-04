# 📊 Credit Risk & Delinquency Intelligence System

## 🚀 Project Overview

This project is an **end-to-end Credit Risk Analytics System** designed to analyze customer payment behavior, identify delinquency patterns, and estimate the **Probability of Default (PD)** for credit accounts.

The solution closely simulates **real-world banking and fintech risk analytics workflows**, using SQL for data engineering, Python for risk modeling, and Power BI for business intelligence and decision-making.

---

## 🎯 Business Problem

Banks and financial institutions need to answer critical questions such as:

- Which customers are paying late?
- How severe and frequent are payment delays?
- Which accounts are likely to default in the future?
- How should collections teams prioritize high-risk accounts?

This project addresses these questions using **data-driven risk intelligence**.

---

## 🧱 System Architecture

MySQL (Transactional Data)
↓
SQL Data Engineering (DPD & Delinquency)
↓
Python Feature Engineering & Risk Modeling
↓
MySQL (Risk Scores Output)
↓
Power BI Risk Intelligence Dashboard


---

## 🗂️ Data Model (SQL – MySQL)

### Core Tables
- `customers` – customer demographic information
- `credit_accounts` – credit account details
- `billing_statements` – monthly billing data
- `payments` – customer payment transactions
- `delinquency_snapshot` – cycle-level delinquency and DPD metrics

### Analytical Output Table
- `account_risk_scores` – final risk scores and segments used in Power BI

---

## ⏱️ Key Concepts Used

- **DPD (Days Past Due)**: Number of days payment is delayed beyond the due date
- **Delinquency**: Payment not received by the due date
- **Default (Proxy)**: Severe or repeated delinquency behavior used as a modeling proxy
- **PD (Probability of Default)**: Likelihood that an account may default

---

## ⚙️ Feature Engineering (Python)

Behavioral risk features engineered at account level include:

- Average Days Past Due (Avg DPD)
- Maximum Days Past Due (Max DPD)
- Delinquency Ratio (frequency of late payments)
- Delinquency Streak (consecutive delinquent cycles)
- Severe Delinquency Count (60+ DPD events)
- Recent Average DPD (early warning indicator)

---

## 🧠 Risk Modeling

- **Model Used**: Logistic Regression (Explainable Model)
- **Reason**: Interpretability is critical in regulated financial environments
- **Target Variable**: Behavioral default proxy derived from delinquency patterns

### Risk Segmentation
Accounts are classified into:
- **Low Risk**
- **Medium Risk**
- **High Risk**

based on their Probability of Default (PD) score.

---

## 📈 Power BI Dashboard

The Power BI dashboard is designed for different business stakeholders:

### Page 1 – Executive Risk Overview
- Total Accounts
- Average PD
- High Risk Account Percentage
- Risk Segment Distribution
- PD Score Distribution

### Page 2 – Risk Driver Analysis
- Avg DPD by Risk Segment
- Max DPD by Risk Segment
- PD vs Delinquency Ratio
- Top High-Risk Accounts

### Page 3 – Collections Action View
- Priority account list
- Risk-based filters
- Actionable KPIs for collections teams

---

## 🛠️ Tools & Technologies

- **SQL**: MySQL
- **Python**: Pandas, NumPy, Scikit-learn
- **Visualization**: Power BI
- **Modeling**: Logistic Regression
- **Connectivity**: SQLAlchemy, MySQL Connector

---

## 📁 Project Structure

Credit-Risk-Delinquency-Intelligence-System/
│
├── README.md
├── SQL/
│ └── credit_risk_delinquency_system.sql
│
├── Python/
│ └── Credit_Risk_RiskScoring_Pipeline.ipynb
│
└── PowerBI/
└── Credit_Risk_Intelligence_Dashboard.pbix


---

## 🧠 Key Learnings

- Practical understanding of credit risk and delinquency analysis
- Importance of explainable models in financial analytics
- Separation of transactional and analytical workloads
- End-to-end integration from database to dashboard

---

## 🔮 Future Enhancements

- Incorporate customer demographic features into modeling
- Add model performance metrics (ROC-AUC, KS statistic)
- Automate data refresh and model retraining
- Implement early warning alerts for emerging delinquencies

---

## 👤 Author

**Prathmesh Patil**  
Aspiring Data Analyst

 
It is a **production-style analytics solution** designed with real-world banking constraints and decision-making processes in mind.
