/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
 
 
 
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/


SELECT 
    STATE, 
    COUNT(CUSTOMER_ID) AS CUSTOMER_COUNT
FROM customer_t
GROUP BY 1
ORDER BY 2 DESC ;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 
*/


-- Define a CTE that assigns numbers to ratings

WITH RATING_BUCKET AS
(
	SELECT
    QUARTER_NUMBER,
        CASE 
			WHEN CUSTOMER_FEEDBACK = "Very Bad" THEN "1"
            WHEN CUSTOMER_FEEDBACK = "Bad" THEN "2"
            WHEN CUSTOMER_FEEDBACK = "Okay" THEN "3"
            WHEN CUSTOMER_FEEDBACK = "Good" THEN "4"
            WHEN CUSTOMER_FEEDBACK = "Very Good" THEN "5"
		END AS CUSTOMER_RATING
	FROM order_t
)
SELECT
	QUARTER_NUMBER,
    AVG(CUSTOMER_RATING) AS "AVG_RATING"
FROM RATING_BUCKET
GROUP BY 1
ORDER BY 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
 */     

select count(quarter_number), customer_feedback from
order_t
group by 3;

select count(customer_id) from order_t;

WITH RATING_BUCKET AS
(
	SELECT
    QUARTER_NUMBER,
        CASE 
			WHEN CUSTOMER_FEEDBACK = "Very Bad" THEN "1"
            WHEN CUSTOMER_FEEDBACK = "Bad" THEN "2"
            WHEN CUSTOMER_FEEDBACK = "Okay" THEN "3"
            WHEN CUSTOMER_FEEDBACK = "Good" THEN "4"
            WHEN CUSTOMER_FEEDBACK = "Very Good" THEN "5"
		END AS CUSTOMER_RATING
	FROM order_t
)
SELECT
	QUARTER_NUMBER,
	(SUM((CASE WHEN CUSTOMER_RATING = "1" THEN 1 ELSE 0 END)) / COUNT(CUSTOMER_RATING))*100 AS "VERY_BAD(%)",
    (SUM((CASE WHEN CUSTOMER_RATING = 2 THEN 1 ELSE 0 END)) / COUNT(CUSTOMER_RATING))*100 AS "BAD(%)",
    (SUM((CASE WHEN CUSTOMER_RATING = 3 THEN 1 ELSE 0 END))/ COUNT(CUSTOMER_RATING))*100 AS "OKAY(%)",
    (SUM((CASE WHEN CUSTOMER_RATING = 4 THEN 1 ELSE 0 END))/ COUNT(CUSTOMER_RATING))*100 AS "GOOD(%)",
    (SUM((CASE WHEN CUSTOMER_RATING = 5 THEN 1 ELSE 0 END))/ COUNT(CUSTOMER_RATING))*100 AS "VERY_GOOD(%)" 
FROM RATING_BUCKET
GROUP BY 1
ORDER BY 1; 
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/


SELECT 
	prod.VEHICLE_MAKER, 
    COUNT(DISTINCT ord.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM product_t AS prod
JOIN order_t AS ord
ON prod.product_id = ord.product_id
GROUP BY 1
ORDER BY 2 DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/


SELECT
	 state, vehicle_maker,
RANK () OVER (PARTITION BY state order by count(distinct customer_id) DESC
    ) CUSTOMER_RANK
FROM customer_t c  inner join order_t o  using (customer_id) 
inner join product_t p  using (product_id)
group by 2,1
;

SELECT vehicle_maker, state
FROM (
  SELECT state, vehicle_maker, RANK() OVER (PARTITION BY state ORDER BY COUNT(distinct customer_id) DESC) AS rankk
  FROM customer_t c  inner join order_t o  using (customer_id) 
inner join product_t p  using (product_id)
  GROUP BY state, vehicle_maker
) AS t
WHERE t.rankk = 1;

SELECT state, vehicle_maker, RANK() OVER (PARTITION BY state ORDER BY COUNT(distinct customer_id) DESC) AS rankk
FROM customer_t c  inner join order_t o  using (customer_id) 
inner join product_t p  using (product_id)
GROUP BY state, vehicle_maker;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT
	QUARTER_NUMBER,
	COUNT(ORDER_ID) AS NUMBER_OF_ORDERS
FROM order_t
GROUP BY 1
ORDER BY 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      
      WITH Quarter_Revenue AS 
(
	SELECT
		QUARTER_NUMBER,
		sum(quantity * (vehicle_price - ((discount/100)*vehicle_Price))) revenue
	FROM 
		order_t
	GROUP BY 1
)
SELECT
	QUARTER_NUMBER,
    REVENUE,
    LAG(REVENUE)  OVER (ORDER BY QUARTER_NUMBER) AS PREVIOUS_QUARTER_REVENUE,
    ((REVENUE - LAG(REVENUE) OVER (ORDER BY QUARTER_NUMBER))/LAG(REVENUE) OVER(ORDER BY QUARTER_NUMBER) * 100)   AS "QUARTER OVER QUARTER REVENUE(%)"
FROM
	Quarter_Revenue;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

select 
	quarter_number,
	count(distinct order_id) as number_of_orders,
	sum(quantity * (vehicle_price - ((discount/100)*vehicle_Price)))  revenue
from order_t
group by quarter_number
order by quarter_number;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT 
	cust.CREDIT_CARD_TYPE,
	AVG(ord.DISCOUNT) AVG_DISCOUNT
FROM customer_t cust
JOIN order_t ord
USING(CUSTOMER_ID)
GROUP BY 1
ORDER BY 2 DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/


SELECT 
	QUARTER_NUMBER, 
    AVG(datediff( SHIP_DATE,order_date)) AVERAGE_SHIPPING
FROM order_t
GROUP BY 1
ORDER BY 1; 

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



