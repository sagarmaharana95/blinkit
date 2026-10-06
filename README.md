# 🛒 Blinkit Quick-Commerce Analytics — End-to-End Data Analysis

[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Power BI](https://img.shields.io/badge/Power_BI-Desktop-F2C811?style=flat&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 Executive Summary & Business Problem
In quick-commerce, order fulfillment speed, customer experience, and unit economics determine profitability. A Blinkit-style delivery model faced operational bottlenecks, delivery SLA degradation, and high revenue exposure from unhappy customers.

This end-to-end data analytics project examines **8 normalized relational datasets** (~100K+ transaction and inventory rows) to:
- Diagnose systemic delivery SLA breaches across distribution hubs and zones.
- Quantify customer churn risk and revenue tied to negative experiences.
- Evaluate customer lifetime value (LTV) distribution and validate pre-assigned customer segments using data-driven metrics.

---

## 🎯 Key Business Questions Answered
1. **SLA Reliability:** Which zones, hubs, or time bands consistently breach the 10-15 minute delivery window?
2. **Revenue at Risk:** What proportion of gross revenue is tied to poor ratings, delayed orders, or customer support escalations?
3. **Customer Concentration:** Does order value follow a Pareto distribution (80/20 rule), and are pre-existing customer segments actionable for retention marketing?

---

## 🛠️ Tech Stack & Architecture

| Layer | Tools & Libraries | Purpose |
| :--- | :--- | :--- |
| **Database** | MySQL 8.0 | Relational schema design, constraints, cleaning, window functions, and business queries |
| **Analytics & EDA** | Python, Pandas, NumPy, Seaborn, Matplotlib | Outlier detection, distribution validation, statistical checks |
| **BI & Visualization** | Power BI, DAX, Power Query | Star Schema modeling, automated KPIs, executive dashboarding |
| **Version Control** | Git, GitHub | Project management and documentation |

---

## 🔍 Engineering & Analytics Workflow

### 1. Database Engineering (MySQL)
- **Schema Normalization:** Designed an 8-table relational model enforcing primary and foreign key constraints across `customers`, `orders`, `order_items`, `products`, `stores`, `inventory`, `deliveries`, and `feedback`.
- **Data Cleansing:** Standardized mixed date-time strings (`YYYY-MM-DD` vs `DD/MM/YYYY`), handled integer overflow on order IDs using `BIGINT`, and filtered anomalous negative delivery durations caused by logging errors.
- **Advanced Querying:** Implemented `CTEs`, `DENSE_RANK()`, `LAG()`, and `NTILE()` to compute rolling SLA breach rates, order frequency intervals, and quartile-based customer spend tiers.

### 2. Exploratory Data Analysis (Python)
- Validated delivery duration distributions (log-normal skew).
- Analyzed correlation between delivery delay duration and rating drop-off.
- Identified that existing marketing customer tiers failed statistical clustering tests, proving a need for behavior-driven RFM segmentation.

### 3. Business Intelligence & Modeling (Power BI)
- Structured a **Star Schema** with bi-directional cross-filtering where necessary.
- Formulated key DAX measures:
  - `SLA Breach Rate %` = `DIVIDE(CALCULATE(COUNT(Orders[OrderID]), Deliveries[DeliveryTimeMinutes] > 15), COUNT(Orders[OrderID]), 0)`
  - `Revenue at Churn Risk` = `CALCULATE(SUM(Orders[TotalAmount]), Feedback[Rating] <= 2)`
  - `Pareto Cumulative Revenue %` using window functions.

---

## 📊 Key Findings & Strategic Impact

* 🚨 **Systemic SLA Breaches (30.6%):** Almost one-third of total orders failed SLA targets. Delays concentrated heavily in 3 dense urban clusters during peak evening hours (7:00 PM – 10:00 PM).
* 💸 **₹36L+ Revenue at Direct Risk:** Over ₹36,00,000 in gross merchandise value (GMV) originated from users reporting 1-star or 2-star ratings, highlighting an immediate churn risk.
* ⚖️ **Pareto Concentration:** The top **20% of customers drive ~41% of total revenue**, indicating that retention campaigns targeting high-frequency spenders offer a significantly higher ROI than broad top-of-funnel customer acquisition.
* 🏷️ **Segment Misalignment:** Pre-assigned customer categories exhibited near-identical mean order values ($p > 0.05$), highlighting the necessity of switching to dynamic RFM (Recency, Frequency, Monetary) segmentation.

---

## 📁 Repository Structure

```text
blinkit-analytics-project/
├── README.md
├── requirements.txt
├── .gitignore
├── LICENSE
├── data/
│   ├── raw/                      # Raw datasets (git-ignored if large)
│   └── processed/                # Cleaned datasets
├── sql/
│   ├── 01_schema_creation.sql    # DDL statements and foreign key constraints
│   ├── 02_data_cleaning.sql      # Type casting, anomaly remediation, null handling
│   └── 03_business_kpis.sql      # Advanced analytics, window functions, and CTEs
├── notebooks/
│   └── blinkit_eda.ipynb         # Python data validation and visual checks
├── dashboard/
│   └── blinkit_dashboard.pbix    # Interactive Power BI report file
└── images/
    ├── dashboard_screenshot.png  # Overview image for the README
    └── data_model.png            # Star schema diagram
```

---

## 🚀 How to Reproduce

### 1. Database Setup
```bash
# Clone the repository
git clone https://github.com/your-username/blinkit-analytics-project.git
cd blinkit-analytics-project

# Load schema and run scripts in MySQL
mysql -u root -p < sql/01_schema_creation.sql
mysql -u root -p < sql/02_data_cleaning.sql
mysql -u root -p < sql/03_business_kpis.sql
```

### 2. Python Environment Setup
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
jupyter notebook notebooks/blinkit_eda.ipynb
```

### 3. Power BI Dashboard
1. Open `dashboard/blinkit_dashboard.pbix` in Power BI Desktop.
2. Update the MySQL data source credentials under **Home > Transform Data > Data Source Settings** to point to your local instance.

---

## 🖼️ Dashboard Preview

![Blinkit Executive Dashboard](images/dashboard_screenshot.png)

---

## 👤 Author
- **Name / GitHub:** [@your-username](https://github.com/your-username)
- **LinkedIn:** [Your LinkedIn Profile](https://linkedin.com/in/your-profile)