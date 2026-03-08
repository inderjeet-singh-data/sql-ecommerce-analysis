/*									   =============================================
    									  			E-COMMERCE DATA ANALYSIS
    									   			Author: INDERJEET SINGH
    									   			Database: MySQL
									   =============================================


									   =============================================
									       		 SECTION 0: DATA EXPLORATION
									   =============================================
									
									   Purpose: Validate data quality and understand structure                                                                          */

-- 1. Table row counts
SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'product_category', COUNT(*) FROM product_category;

/* RESULT
table_name      |row_count|
----------------+---------+
customers       |    99441|
orders          |    99441|
order_items     |   112650|
order_payments  |   103886|
order_reviews   |    99224|
products        |    32951|
sellers         |     3095|
product_category|       71|
*/

-- 2. Date range of data
SELECT 
    MIN(order_purchase_timestamp) as earliest_order,
    MAX(order_purchase_timestamp) as latest_order,
    DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) as days_of_data
FROM orders;

/* RESULT
earliest_order     |latest_order       |days_of_data|
-------------------+-------------------+------------+
2016-09-04 21:15:19|2018-10-17 17:30:18|         773|
*/


-- 3. Null check in in critical columns


-- ORDERS
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) as null_delivery_dates,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) as null_approval_dates,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) as null_customer_id
FROM orders;

/* RESULT
total_orders|null_delivery_dates|null_approval_dates|null_customer_id|
------------+-------------------+-------------------+----------------+
       99441|               2965|                160|               0|
*/


--  ORDER_ITEMS 

SELECT 
    COUNT(*) as total_items,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) as null_prices,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) as null_freight,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) as null_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) as null_seller_id
FROM order_items;

/* RESULT
total_items|null_prices|null_freight|null_product_id|null_seller_id|
-----------+-----------+------------+---------------+--------------+
     112650|          0|           0|              0|             0|
*/



-- PRODUCTS 

SELECT 
    COUNT(*) as total_products,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) as null_category
FROM products;

/* RESULT
total_products|null_category|
--------------+-------------+
         32951|            0|
*/






/*									   =============================================
									 		     SECTION 1: BUSINESS OVERVIEW
									   =============================================

									 Start with the big picture - understand the business                                        */

-- Q1. What is the total revenue generated?

SELECT 
	SUM(oi.price + oi.freight_value) total_revenue
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered';

/* RESULT 
 total_revenue : 15424683
 */

-- Q2. How many orders and customers do we have?

SELECT 
	count(DISTINCT order_id) order_count,
	COUNT(DISTINCT c.customer_unique_id) customer_count
FROM orders o 
JOIN customers c 
	ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered';

/* RESULT 
 order_count|customer_count|
-----------+--------------+
      96478|          93358|
 */

-- Q3. What's the monthly revenue trend?

SELECT 
	DATE_FORMAT(o.order_purchase_timestamp ,'%Y-%m') month_year,
	SUM(oi.price + oi.freight_value) total_revenue
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp IS NOT null
GROUP BY month_year
ORDER BY  month_year;

/* RESULT 
 month_year|total_revenue|
----------+-------------+
2016-09   |          144|
2016-10   |        46518|
2016-12   |           20|
2017-01   |       127614|
2017-02   |       271474|
2017-03   |       414719|
2017-04   |       391138|
2017-05   |       567146|
2017-06   |       490271|
2017-07   |       566550|
2017-08   |       646132|
2017-09   |       701369|
2017-10   |       751418|
2017-11   |      1153886|
2017-12   |       843381|
2018-01   |      1078398|
2018-02   |       966565|
2018-03   |      1120680|
2018-04   |      1132881|
2018-05   |      1128780|
2018-06   |      1012029|
2018-07   |      1027935|
2018-08   |       985635|
 */

-- Q4. What's the average order value (AOV)?

SELECT 
	ROUND(SUM(oi.price + oi.freight_value)/ COUNT(DISTINCT o.order_id),2) avg_order_value
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered';

/* RESULT 
 avg_order_value|
---------------+
         159.88|
 */



/*											   =============================================
											    		  SECTION 2: Product Analysis
											   =============================================
					
											    	 Which products drive the business?                                                  */

-- Q5. Top 10 best-selling products by quantity

SELECT 
	p.product_id,
	pc.product_category_name_english AS product_category,
	COUNT(*) AS time_sold,
	SUM(oi.price + oi.freight_value  ) AS total_revenue
FROM products p 
JOIN order_items oi 
	ON p.product_id = oi.product_id 
JOIN orders o 
	ON oi.order_id = o.order_id 
JOIN product_category pc 
	ON p.product_category_name = pc.product_category_name 
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, product_category  
ORDER BY time_sold  DESC 
LIMIT 10;

/* RESULT 
product_id                      |product_category     |time_sold|total_revenue|
--------------------------------+---------------------+---------+-------------+
aca2eb7d00ea1a7b8ebd4e68314663af|furniture_decor      |      520|        44195|
422879e10f46682990de24d770e7f83d|garden_tools         |      484|        34240|
99a4788cb24856965c36a24e339b6058|bed_bath_table       |      477|        49909|
389d119b48cf3043d311335e499d9c6b|garden_tools         |      390|        28588|
368c6c730842d78016ad823897a372db|garden_tools         |      388|        28029|
53759a2ecddad2bb87a079a1f1519f73|garden_tools         |      373|        27316|
d1c427060a0f73f6b889a5c7c61f2ac4|computers_accessories|      332|        58956|
53b36df67ebb7c41585e8d54d6772e08|watches_gifts        |      321|        39739|
154e7e31ebfa092203795c972e5804a6|health_beauty        |      274|         9846|
3dd2a17168ec895c781a9191c1e95ad7|computers_accessories|      272|        47893|
 */

-- Q6. Top 10 product categories by revenue

SELECT 
	pc.product_category_name_english product_category,
	COUNT(DISTINCT o.order_id) AS orders,
	SUM(oi.price + oi.freight_value ) total_revenue
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id 
JOIN products p 
	ON oi.product_id = p.product_id 
JOIN product_category pc 
	ON p.product_category_name = pc.product_category_name 
WHERE o.order_status = 'delivered'
GROUP BY product_category 
ORDER BY total_revenue DESC
LIMIT 10;

/* RESULT 
product_category     |orders|total_revenue|
---------------------+------+-------------+
health_beauty        |  8647|      1412285|
watches_gifts        |  5495|      1264641|
bed_bath_table       |  9272|      1226056|
sports_leisure       |  7530|      1118531|
computers_accessories|  6530|      1033035|
furniture_decor      |  6307|       880715|
housewares           |  5743|       758651|
cool_stuff           |  3559|       691870|
auto                 |  3810|       669489|
garden_tools         |  3448|       567409|
 */

-- Q7. Average price by product category

SELECT 	
	pc.product_category_name_english product_category,
	ROUND(AVG(oi.price),2) avg_price,
	COUNT(*) items_sold
FROM order_items oi
JOIN products p
	ON oi.product_id = p.product_id
JOIN product_category pc 
	ON p.product_category_name = pc.product_category_name 
WHERE pc.product_category_name_english IS NOT NULL 
GROUP BY product_category 
ORDER BY avg_price DESC
LIMIT 10;

/* RESULT 
 product_category                     |avg_price|items_sold|
-------------------------------------+---------+----------+
computers                            |  1098.35|       203|
small_appliances_home_oven_and_coffee|   624.30|        76|
home_appliances_2                    |   476.16|       238|
agro_industry_and_commerce           |   342.19|       212|
musical_instruments                  |   281.67|       680|
small_appliances                     |   280.81|       679|
fixed_telephony                      |   225.73|       264|
construction_tools_safety            |   209.03|       194|
watches_gifts                        |   201.17|      5991|
air_conditioning                     |   185.32|       297|
 */

-- Q8. Products with highest freight costs

SELECT 
	p.product_id,
	pc.product_category_name_english product_category ,
	ROUND(AVG(oi.freight_value),2) avg_freight,
	ROUND(AVG(oi.price),2) avg_price,
	ROUND(AVG(oi.freight_value)/AVG(oi.price)*100,2) freight_pct_of_price 
FROM order_items oi 
JOIN products p 
	ON oi.product_id = p.product_id
JOIN product_category pc 
	ON p.product_category_name = pc.product_category_name 
JOIN orders o 
	ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered'
GROUP BY p.product_id , pc.product_category_name_english 
HAVING COUNT(*) > 10  
ORDER BY freight_pct_of_price  DESC 
LIMIT 10;

/* RESULT 
 product_id                      |product_category|avg_freight|avg_price|freight_pct_of_price|
--------------------------------+----------------+-----------+---------+--------------------+
5dbf50af9485478b933f1028e108640d|electronics     |      16.42|     5.83|              281.43|
98224bfc1eaadb3a394ec334c60453ff|auto            |      11.58|     4.42|              262.26|
222efa72a47277d611b8b38d71149afd|housewares      |      12.64|     6.29|              201.14|
b756577e274d3a4793fc27209d7072db|health_beauty   |      19.21|    11.00|              174.68|
d7205c0ebebe2744d7c2e44b6d69cc95|bed_bath_table  |      15.17|     9.00|              168.52|
b60856ce32d90658dbf99b9485327c25|electronics     |      14.96|     9.00|              166.22|
2083a6feb4bbb31f6abc92fc24e468c0|telephony       |      10.88|     6.92|              157.22|
9007d9a8a0d332c61d9dd611fa341f4b|stationery      |      11.87|     8.00|              148.37|
12dc5e5d178b930cf87cf16e812fc2d5|perfumery       |      15.75|    11.00|              143.18|
91b08d34d0ba4db44da2dc382867ba49|telephony       |      15.65|    11.00|              142.23|
 */


/*											   =============================================
											   			SECTION 3: Customer Analysis
											   =============================================
											
											  		   Understand customer behavior                                                         */

-- Q9. Top 10 cities by number of customers

SELECT 
	c.customer_city ,
	c.customer_state ,
	COUNT(DISTINCT c.customer_unique_id ) count
FROM customers c
GROUP BY c.customer_city, c.customer_state 
ORDER BY count DESC
LIMIT 10;

/* RESULT 
 customer_city        |customer_state|count|
---------------------+--------------+-----+
sao paulo            |SP            |14984|
rio de janeiro       |RJ            | 6620|
belo horizonte       |MG            | 2672|
brasilia             |DF            | 2069|
curitiba             |PR            | 1465|
campinas             |SP            | 1398|
porto alegre         |RS            | 1326|
salvador             |BA            | 1209|
guarulhos            |SP            | 1153|
sao bernardo do campo|SP            |  908|
 */

-- Q10. Top 10 cities by revenue

SELECT 
	c.customer_city,
	COUNT(DISTINCT o.order_id) orders,
	SUM(oi.price + oi.freight_value) total_revenue,
	ROUND(SUM(oi.price + oi.freight_value )/ 
	(SELECT SUM(price + freight_value) revenue FROM order_items JOIN orders USING(order_id) WHERE order_status = 'delivered')*100.0,2) rev_cont_pct
FROM order_items oi 
JOIN orders o
	ON oi.order_id = o.order_id 
JOIN customers c
	ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city 
ORDER BY total_revenue DESC
LIMIT 10;

/* RESULT 
 customer_city |orders|total_revenue|rev_cont_pct|
--------------+------+-------------+------------+
sao paulo     | 15045|      2108774|       13.67|
rio de janeiro|  6601|      1112041|        7.21|
belo horizonte|  2697|       406045|        2.63|
brasilia      |  2071|       345236|        2.24|
curitiba      |  1489|       238503|        1.55|
porto alegre  |  1342|       214824|        1.39|
campinas      |  1406|       209032|        1.36|
salvador      |  1188|       207800|        1.35|
guarulhos     |  1144|       157789|        1.02|
niteroi       |   825|       135464|        0.88|
 */

-- Q11. Customer purchase frequency (repeat vs one-time)

SELECT 
	CASE WHEN order_count = 1 THEN 'One-Time' ELSE 'Repeat' END AS customer_type,
	COUNT(customer_id ) total_customers
FROM (
SELECT 
	c.customer_unique_id customer_id,
	COUNT(DISTINCT order_id) order_count
FROM orders o 
JOIN customers c 
	ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
)t
GROUP BY customer_type;

/* RESULT 
 customer_type|total_customers|
-------------+---------------+
One-Time     |          90557|
Repeat       |           2801|
 */

-- Q12. Average time between first and second purchase

SELECT 
	ROUND(AVG(TIMESTAMPDIFF(DAY, cur_mont_purc, next_mont_purc)),2) avg_days_between
FROM (
SELECT 
	c.customer_unique_id,
	o.order_purchase_timestamp cur_mont_purc,
	LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) next_mont_purc,
	ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ) rn
FROM customers c 
JOIN orders o 
	ON c.customer_id = o.customer_id 
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp IS NOT NULL
)t
WHERE rn = 1 AND t.next_mont_purc IS NOT NULL 

/* RESULT 
 avg_days_between|
----------------+
           80.84|
 */



/*									  	       =============================================
											   		    SECTION 4: Logistics & Delivery
											   =============================================

											  			 Operational efficiency                                                              */

-- Q13. Average delivery time by state

SELECT 
	c.customer_state state,
	COUNT(DISTINCT o.order_id) orders,
	ROUND(AVG(TIMESTAMPDIFF(SECOND ,o.order_purchase_timestamp ,o.order_delivered_customer_date )/86400),2) avg_delivery_days
FROM orders o 
JOIN customers c 
	ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state  
ORDER BY avg_delivery_days DESC;

/* RESULT 
 state|orders|avg_delivery_days|
-----+------+-----------------+
RR   |    41|            29.39|
AP   |    67|            27.19|
AM   |   145|            26.43|
AL   |   397|            24.54|
PA   |   946|            23.77|
MA   |   717|            21.57|
SE   |   335|            21.52|
CE   |  1279|            21.27|
AC   |    80|            21.04|
PB   |   517|            20.43|
PI   |   476|            19.46|
RO   |   243|            19.37|
BA   |  3256|            19.34|
RN   |   474|            19.28|
PE   |  1593|            18.45|
MT   |   886|            18.06|
TO   |   274|            17.66|
ES   |  1995|            15.79|
MS   |   701|            15.62|
GO   |  1957|            15.61|
RJ   | 12350|            15.31|
RS   |  5345|            15.30|
SC   |  3546|            14.95|
DF   |  2080|            12.97|
MG   | 11354|            12.01|
PR   |  4923|            11.99|
SP   | 40501|             8.76|
 */

-- Q14. On-time delivery rate

SELECT 
    COUNT(*) as total_delivered,
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) as on_time,
    ROUND(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as on_time_pct
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

/* RESULT 
 total_delivered|on_time|on_time_pct|
---------------+-------+-----------+
          96476|  88649|      91.89|
 */

-- Q15. Orders still in transit (not delivered)

SELECT 
	o.order_status,
	COUNT(DISTINCT o.order_id ) count
FROM orders o
WHERE o.order_status NOT  IN ("delivered", "unavailable", "canceled")
GROUP BY o.order_status 
ORDER BY count DESC;

/* RESULT 
 order_status|count|
------------+-----+
shipped     | 1107|
invoiced    |  314|
processing  |  301|
created     |    5|
approved    |    2|
 */					


/*										  	   =============================================
											   			SECTION 5: Payment Analysis
											   =============================================

											  			  How do customers pay?                                                               */

-- Q16. Payment methods distribution

SELECT 
	op.payment_type ,
	COUNT(op.payment_type ) count,
	ROUND(COUNT(op.payment_type)/(SELECT COUNT(payment_type) FROM order_payments )*100.0,0) pct_cont,
	ROUND(SUM(op.payment_value), 2) as total_value,
    ROUND(AVG(op.payment_value), 2) as avg_value
FROM order_payments op
GROUP BY op.payment_type 
ORDER BY count DESC;

/* RESULT 
payment_type|count|pct_cont|total_value|avg_value|
------------+-----+--------+-----------+---------+
credit_card |76795|      74|   12542823|   163.33|
boleto      |19784|      19|    2869601|   145.05|
voucher     | 5775|       6|     379408|    65.70|
debit_card  | 1529|       1|     218013|   142.59|
not_defined |    3|       0|          0|     0.00|
 */

-- Q17. Payment installments analysis

SELECT 
	op.payment_installments AS installments,
	COUNT(op.payment_installments ) count,
	ROUND(SUM(op.payment_value), 2) as total_value,
	ROUND(AVG(op.payment_value ),2) avg_value,
	ROUND(COUNT(op.payment_installments)/(SELECT COUNT(payment_installments) FROM order_payments)*100.0,2)  pct_cont
FROM order_payments op 
GROUP BY op.payment_installments 
ORDER BY count DESC;

/* RESULT 
installments|count|total_value|avg_value|pct_cont|
------------+-----+-----------+---------+--------+
           1|52546|    5907572|   112.43|   50.58|
           2|12413|    1579449|   127.24|   11.95|
           3|10461|    1491270|   142.56|   10.07|
           4| 7098|    1164027|   163.99|    6.83|
          10| 5328|    2211596|   415.09|    5.13|
           5| 5239|     961220|   183.47|    5.04|
           8| 4268|    1313460|   307.75|    4.11|
           6| 3920|     822658|   209.86|    3.77|
           7| 1626|     305183|   187.69|    1.57|
           9|  644|     131021|   203.45|    0.62|
          12|  133|      42785|   321.69|    0.13|
          15|   74|      32976|   445.62|    0.07|
          18|   27|      13137|   486.56|    0.03|
          11|   23|       2873|   124.91|    0.02|
          24|   18|      10980|   610.00|    0.02|
          20|   17|      10469|   615.82|    0.02|
          13|   16|       2407|   150.44|    0.02|
          14|   15|       2518|   167.87|    0.01|
          17|    8|       1396|   174.50|    0.01|
          16|    5|       1463|   292.60|    0.00|
          21|    3|        731|   243.67|    0.00|
           0|    2|        189|    94.50|    0.00|
          22|    1|        229|   229.00|    0.00|
          23|    1|        236|   236.00|    0.00|
 */

					
/*											   =============================================
											    	  SECTION 6: Customer Satisfaction
											   =============================================
				
														   Are customers happy?                                                                */

-- Q18. Review score distribution

SELECT 
  r.review_score ,
  COUNT(r.review_score ) distribution ,
  ROUND(COUNT(r.review_score )/(SELECT COUNT(review_score) FROM order_reviews ) *100,2) cont_pct
FROM order_reviews r 
GROUP BY r.review_score  
ORDER BY distribution DESC;

/* RESULT 
 review_score|distribution|cont_pct|
------------+------------+--------+
           5|       57328|   57.78|
           4|       19142|   19.29|
           1|       11424|   11.51|
           3|        8179|    8.24|
           2|        3151|    3.18|
 */

-- Q19. Categories with best/worst reviews

SELECT 
    pc.product_category_name_english,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    COUNT(*) AS review_count
FROM order_reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category pc ON p.product_category_name = pc.product_category_name
GROUP BY 1
HAVING review_count > 50 -- Filter out categories with too few reviews for stability
ORDER BY avg_score DESC
LIMIT 10;

/* RESULT 
 product_category_name_english       |avg_score|review_count|
-------------------------------------+---------+------------+
books_general_interest               |     4.45|         549|
costruction_tools_tools              |     4.44|          99|
books_imported                       |     4.40|          60|
books_technical                      |     4.37|         266|
food_drink                           |     4.32|         279|
luggage_accessories                  |     4.32|        1088|
small_appliances_home_oven_and_coffee|     4.30|          76|
fashion_shoes                        |     4.23|         261|
food                                 |     4.22|         495|
cine_photo                           |     4.21|          73|
 */


-- 20.	Does delivery delay impact review score?

SELECT  
    CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On-Time' ELSE 'delayed' END AS delivery_status,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp, o.order_delivered_customer_date)/86400),2) AS avg_deli_time,
    ROUND(AVG(r.review_score),2) AS avg_score
FROM orders o 
JOIN order_reviews r
	ON r.order_id = o.order_id 
WHERE o.order_status = 'delivered'
	AND o.order_delivered_customer_date IS NOT NULL 
GROUP BY delivery_status;

/*
RESULT 
delivery_status|avg_deli_time|avg_score|
---------------+-------------+---------+
On-Time        |        10.88|     4.29|
Delayed        |        31.39|     2.57|
*/

/*										 	   =============================================
											     		SECTION 7: Seller Performance 
											   =============================================
						
											  			  Who are the top sellers?                                                            */

-- Q21. Top 10 sellers by revenue

SELECT 
	RANK() OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) seller_rank,
	s.seller_id,
	s.seller_city ,
	s.seller_state ,
	SUM(oi.price + oi.freight_value) total_revenue,
	ROUND(SUM(oi.price + oi.freight_value)/ 
	(SELECT SUM(price + freight_value) revenue FROM order_items JOIN orders USING(order_id) WHERE order_status = 'delivered')*100.0,2) rev_cont_pct
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id 
JOIN sellers s 
	ON oi.seller_id = s.seller_id 
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id , s.seller_city , s.seller_state 
ORDER BY total_revenue DESC 
LIMIT 10;

/* RESULT 
seller_rank|seller_id                       |seller_city     |seller_state|total_revenue|rev_cont_pct|
-----------+--------------------------------+----------------+------------+-------------+------------+
          1|4869f7a5dfa277a7dca6462dcf3b52b2|guariba         |SP          |       247104|        1.60|
          2|7c67e1448b00f6e969d365cea6b010ab|itaquaquecetuba |SP          |       237902|        1.54|
          3|4a3ca9315b744ce9f8e9374361493884|ibitinga        |SP          |       231371|        1.50|
          4|53243585a1d6dc2643021fd1853d8905|lauro de freitas|BA          |       230819|        1.50|
          5|fa1c13f2614d7b5c4749cbc52fecda94|sumare          |SP          |       200882|        1.30|
          6|da8622b14eb17ae2831f4ac5b9dab84a|piracicaba      |SP          |       184844|        1.20|
          7|7e93a43ef30c4f03f38b393420bc753a|barueri         |SP          |       171984|        1.11|
          8|1025f0e2d44d7041d6cf58b6550e0bfa|sao paulo       |SP          |       171808|        1.11|
          9|7a67c85e85bb2ce8582c35f2203ad736|sao paulo       |SP          |       160286|        1.04|
         10|955fee9216a65b617aa5c0531780ce60|sao paulo       |SP          |       156590|        1.02|
 */

-- 22.  Month-over-Month (MoM%) Growth

SELECT 
	t.month_year ,
	ROUND((t.cur_mon_rev - LAG(t.cur_mon_rev ) OVER (ORDER BY t.year_num, t.month_num))/
	LAG(t.cur_mon_rev ) OVER ( ORDER BY t.year_num, t.month_num)*100,2) MoM_pct
FROM (
SELECT 
	DATE_FORMAT(o.order_purchase_timestamp , '%m-%Y') month_year,
	YEAR(o.order_purchase_timestamp) year_num,
	MONTH(o.order_purchase_timestamp) month_num,
	SUM(oi.price + oi.freight_value ) cur_mon_rev
FROM order_items oi 
JOIN orders o 
	ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY YEAR(o.order_purchase_timestamp) ,MONTH(o.order_purchase_timestamp),DATE_FORMAT(o.order_purchase_timestamp , '%m-%Y') 
)t ORDER BY t.year_num , t.month_num;

/*RESULT 
month_year|MoM_pct  |
----------+---------+
09-2016   |         |
10-2016   | 32204.17|
12-2016   |   -99.96|
01-2017   |637970.00|
02-2017   |   112.73|
03-2017   |    52.77|
04-2017   |    -5.69|
05-2017   |    45.00|
06-2017   |   -13.55|
07-2017   |    15.56|
08-2017   |    14.05|
09-2017   |     8.55|
10-2017   |     7.14|
11-2017   |    53.56|
12-2017   |   -26.91|
01-2018   |    27.87|
02-2018   |   -10.37|
03-2018   |    15.94|
04-2018   |     1.09|
05-2018   |    -0.36|
06-2018   |   -10.34|
07-2018   |     1.57|
08-2018   |    -4.12||
 */












