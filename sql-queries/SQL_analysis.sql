/* 
      File Name      : churn_analysis.sql
      Project        : Telecom Churn Analysis
      Author         : Aditya Chauhan
      Created On     : 2026-01-23
      Description    :
             - This SQL script analyzes customer churn behavior
             - Calculates churn rate by contract type and tenure
             - Identifies high-risk customer segments
       Database       : Telecom_churn_analysis
*/



-- STEP-1 create a table named telecom customers
CREATE TABLE telecom_customers
(
    customerID VARCHAR(25) PRIMARY KEY,  
	gender	VARCHAR(10),
	SeniorCitizen INT8,
	Partner VARCHAR(5),
	Dependents	VARCHAR(5),
	tenure	INT8,
	PhoneService VARCHAR(5),
	MultipleLines	VARCHAR(25),
	InternetService	VARCHAR(25),
	OnlineSecurity	VARCHAR(25),
	OnlineBackup	VARCHAR(25),
	DeviceProtection VARCHAR(25),	
	TechSupport	VARCHAR(25),
	StreamingTV	VARCHAR(25),
	StreamingMovies	VARCHAR(25),
	Contract	VARCHAR(25),
	PaperlessBilling VARCHAR(5),	
	PaymentMethod	VARCHAR(50),
	MonthlyCharges	DECIMAL(10,2),
	TotalCharges VARCHAR(25),	
	Churn VARCHAR(5)

)

-- STEP-2 Importing data into the table

	COPY telecom_customers(customerID,gender,SeniorCitizen,Partner,Dependents,tenure,PhoneService,MultipleLines,InternetService,OnlineSecurity,OnlineBackup,DeviceProtection,TechSupport,StreamingTV,StreamingMovies,Contract,PaperlessBilling,PaymentMethod,MonthlyCharges,TotalCharges,Churn
)
FROM 'D:\my new projects\End-To-End Projects\Telcom churn analysis\Data\tele_churn_data.csv'
DELIMITER ','
CSV HEADER;

-- STEP-3 Data cleaning and Type conversion

-- 3.1--PROBLEM - CHANGE TOTAL CHARGES COLUMN DATATYPE FROM VARCHAR TO DECIMAL(10,2)

            --CHECK FOR PROBLEMATIC VALUES
             SELECT customerID,tenure,TotalCharges
             FROM telecom_customers
             WHERE TotalCharges =' '
          -- Totalcharges show null becuase because tenure is 0(early customers didn't pay any monthly charge).So change null values to 0.
            UPDATE telecom_customers
            SET TotalCharges = '0'
            WHERE tenure = 0;
           -- Change column data type from varchar to decimal
          ALTER table telecom_customers
           ALTER COLUMN TotalCharges TYPE DECIMAL(10,2)
           USING TotalCharges :: DECIMAL(10,2);
-- 3.2-- PROBLEM- CHANGE CHURN COLUMN VALUES YES/NO TO 0/1 AND CHANGE DATA TYPE FROM VARCHAR TO INTEGER FOR MAKING QUERIES SHORTER AND ABLE TO PERFORM CALCULATIONS DIRECTLY.
       --  Change the column values to numbers
            UPDATE telecom_customers
            SET Churn = CASE 
            WHEN Churn = 'Yes' THEN 1 
             ELSE 0 
            END;

          -- Change the column type to INTEGER (so it's optimized for math)
           ALTER TABLE telecom_customers
           ALTER COLUMN Churn TYPE INTEGER
		   USING Churn :: INTEGER;

--STEP 4 DATA ANALYSIS
--QUES-1 - HOW BIG IS THE CHURN PROBLEM ?
 SELECT 
 COUNT(*) AS total_customers,
 SUM(Churn) AS churned_customers,
 ROUND(SUM(CHURN)*100/COUNT(*),2) AS churn_rate_percentage
 FROM telecom_customers;

 /* Business insights
   1-The overall customer churn rate is ~26–27%, indicating that approximately 1 in 4 customers discontinue services.
   2-This level of churn represents a significant revenue and customer lifetime value risk, highlighting the need for targeted retention strategies.
*/
 
 -- QUES-2- WHICH CONTRACT TYPE CHURNS THE MOST ?
  SELECT
  Contract as Contract_Name,
  COUNT(*) AS total_customers,
  SUM(Churn) AS churned_customers,
  ROUND(SUM(Churn)*100/COUNT(*),2) AS churn_rate
  FROM telecom_customers
  GROUP BY Contract
  ORDER BY churn_rate DESC;

  /* Business insights
   1- Customers on month-to-month contracts account for the highest churn rate of 42% , significantly higher than one-year(11%) and two-year contracts(2%).
*/

  --QUES-3-- DO NEW CUSTOMERS CHURN MORE ?

  --CREATING TENURE BUCKETS
  SELECT
    CASE 
        WHEN tenure < 6 THEN '0-6 Months'
        WHEN tenure BETWEEN 6 AND 12 THEN '6-12 Months'
        WHEN tenure BETWEEN 13 AND 24 THEN '1-2 Years'
        ELSE '2+ Years'
    END AS tenure_group,
    COUNT(*) AS total_customers,
    SUM(Churn) AS churned_customers,
    ROUND(
        SUM(Churn) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM telecom_customers
GROUP BY tenure_group
ORDER BY churn_rate DESC;

/* Business insights
   1- Customers with tenure less than 6 months exhibit the highest churn rate of 54% across all tenure segments.
   2- Churn risk decreases steadily as tenure increases, with customers staying longer than 2 years showing the lowest churn.
*/

--Ques-4- Does Payment method affect churn?
SELECT 
PaymentMethod AS payment_method,
COUNT(*) AS total_customers,
SUM(Churn) AS churned_customers,
ROUND(SUM(Churn)*100/COUNT(*)) AS churn_rate
FROM telecom_customers
GROUP BY payment_method
ORDER BY churn_rate DESC;

/* Business insights
   1- Customers using electronic check payment method show the highest churn rate of 45% among all payment types
   2- Customers using automatic payment methods (credit card / bank transfer) demonstrate significantly lower churn.
*/

--Ques-4  Are high paying customers leaving ?
SELECT
    Churn,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charge,
    ROUND(AVG(TotalCharges), 2) AS avg_total_charge
FROM telecom_customers
GROUP BY Churn;

/* Business insights
   1- Churned customers have a higher average monthly charge(74>61) compared to retained customers.
   2- Higher pricing sensitivity contributes directly to churn behavior.
*/

--Ques-5 Can we create a reusable churn summary for dashboards and reports ?
CREATE VIEW churn_summary AS
SELECT
    Contract,
    PaymentMethod,
    COUNT(*) AS total_customers,
    SUM(Churn) AS churned_customers,
    ROUND(
        SUM(Churn) * 100.0 / COUNT(*),
        2
    ) AS churn_rate
FROM telecom_customers
GROUP BY Contract, PaymentMethod;


Ques-6- Which customer segments should retention teams focus on first ?
SELECT
    Contract,
    PaymentMethod,
    churn_rate,
    RANK() OVER (ORDER BY churn_rate DESC) AS risk_rank
FROM (
    SELECT
        Contract,
        PaymentMethod,
        ROUND(
            SUM(Churn) * 100.0 / COUNT(*),
            2
        ) AS churn_rate
    FROM telecom_customers
    GROUP BY Contract, PaymentMethod
) t;

/* Business insights
   1- he highest-risk segment consists of:

       a-Month-to-month contract customers

       b-Electronic check payment users

       c-Low tenure (< 6 months)
*/























