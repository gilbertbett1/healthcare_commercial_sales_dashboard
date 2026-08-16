-- East Africa healthcare commercial sales dashboard
-- --------------------------------------------------------

CREATE DATABASE IF NOT EXISTS healthcare_commercial_sales
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE healthcare_commercial_sales;

-- ----------------------------------------------
-- 1. dim_calendar 
-- ----------------------------------------------
CREATE TABLE IF NOT EXISTS dim_calendar (
    date_id INT PRIMARY KEY,
    calendar_date DATE NOT NULL,
    calendar_month TINYINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    calendar_quarter TINYINT NOT NULL,
    calendar_year SMALLINT NOT NULL,
    ugx_to_kes_rate DECIMAL(9,4) NOT NULL,
    tzs_to_kes_rate DECIMAL(9,4) NOT NULL,
    UNIQUE KEY uq_dim_calendar_date (calendar_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------
-- 2. dim_products
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50) NOT NULL,
    unit_cost DECIMAL(12,2) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    CHECK (unit_price >= unit_cost)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------
-- 3. dim_customers
-- --------------------------------------
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id  INT PRIMARY KEY,
    customer_name  VARCHAR(150) NOT NULL,
    customer_type  VARCHAR(30)  NOT NULL,
    city VARCHAR(50)  NOT NULL,
    country VARCHAR(30)  NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------
-- 4. dim_sales_reps
-- ---------------------------------
CREATE TABLE IF NOT EXISTS dim_sales_reps (
    sales_rep_id  INT PRIMARY KEY,
    rep_name VARCHAR(100) NOT NULL,
    territory_region VARCHAR(50) NOT NULL,
    country VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------
-- 5. fact_sales 
-- --------------------------------
CREATE TABLE IF NOT EXISTS fact_sales (
    invoice_line_id INT PRIMARY KEY,
    date_id INT NOT NULL,
    customer_id  INT NOT NULL,
    product_id  INT NOT NULL,
    sales_rep_id  INT NOT NULL,
    units_sold  INT NOT NULL,
    gross_revenue_local  DECIMAL(14,2) NOT NULL,
    discount_applied_local DECIMAL(14,2) NOT NULL,
    CHECK (units_sold > 0),
    CHECK (discount_applied_local <= gross_revenue_local),
    CONSTRAINT fk_sales_date FOREIGN KEY (date_id) REFERENCES dim_calendar(date_id),
    CONSTRAINT fk_sales_cust FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_sales_prod FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    CONSTRAINT fk_sales_rep FOREIGN KEY (sales_rep_id) REFERENCES dim_sales_reps(sales_rep_id),
    INDEX idx_sales_date (date_id),
    INDEX idx_sales_cust (customer_id),
    INDEX idx_sales_prod (product_id),
    INDEX idx_sales_rep (sales_rep_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------
-- 6. fact_targets 
-- ------------------------------
CREATE TABLE IF NOT EXISTS fact_targets (
    target_id  INT PRIMARY KEY,
    sales_rep_id  INT NOT NULL,
    date_id   INT NOT NULL, 
    monthly_target_kes DECIMAL(14,2) NOT NULL,
    CHECK (monthly_target_kes > 0),
    CONSTRAINT fk_targets_rep FOREIGN KEY (sales_rep_id) REFERENCES dim_sales_reps(sales_rep_id),
    CONSTRAINT fk_targets_date FOREIGN KEY (date_id) REFERENCES dim_calendar(date_id),
    UNIQUE KEY uq_rep_month (sales_rep_id, date_id),
    INDEX idx_targets_rep  (sales_rep_id),
    INDEX idx_targets_date (date_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;