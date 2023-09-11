# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

				SELECT market FROM dim_customer
				where customer like "Atliq Exclusive" and region = "APAC"
				group by market
				order by market;

# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#unique_products_2020 unique_products_2021 percentage_chg

				select X.A as unique_product_2020, Y.B as unique_products_2021, 
						ROUND((B-A)*100/A, 2) as percentage_chg
				from
					(
					(select count(distinct(product_code)) as A from fact_sales_monthly
						where fiscal_year = 2020) X,
					(select count(distinct(product_code)) as B from fact_sales_monthly
						where fiscal_year = 2021) Y 
					);

# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of 
# product counts. The final output contains 2 fields,
# segment , product_count

					select segment, count(product_code) as product_count from dim_product
					group by segment
					order by product_count desc;

# 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields,
# segment ,product_count_2020 , product_count_2021 ,difference

				WITH CTE1 AS 
					(SELECT P.segment AS A , COUNT(DISTINCT(FS.product_code)) AS B 
						FROM dim_product P, fact_sales_monthly FS
						WHERE P.product_code = FS.product_code
						GROUP BY FS.fiscal_year, P.segment
						HAVING FS.fiscal_year = "2020"),
				CTE2 AS
					(
					SELECT P.segment AS C , COUNT(DISTINCT(FS.product_code)) AS D 
					FROM dim_product P, fact_sales_monthly FS
					WHERE P.product_code = FS.product_code
					GROUP BY FS.fiscal_year, P.segment
					HAVING FS.fiscal_year = "2021"
					)     
    
                SELECT CTE1.A AS segment, CTE1.B AS product_count_2020, 
					CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference  
				FROM CTE1, CTE2
				WHERE CTE1.A = CTE2.C ;


# 5. Get the products that have the highest and lowest manufacturing costs.
 # The final output should contain these fields,
  # product_code product manufacturing_cost
  
			select p.product_code , p.product, m.manufacturing_cost 
			from dim_product p 
			join fact_manufacturing_cost m 
			on m.product_code = p.product_code
			where manufacturing_cost in( (select max(manufacturing_cost)from fact_manufacturing_cost),
                             (select min(manufacturing_cost)from fact_manufacturing_cost) );
						
# 6. Generate a report which contains the top 5 customers who received an
  #average high pre_invoice_discount_pct for the fiscal year 2021 and in the
 #Indian market. The final output contains these fields,
 #customer_code ,customer ,average_discount_percentage

				select c.customer_code , c.customer,
					round(avg(pre_invoice_discount_pct),4) as average_discount_percentage
				from dim_customer c 
				join fact_pre_invoice_deductions pre
				on pre.customer_code = c.customer_code
				where market="india" and fiscal_year=2021
				group by c.customer_code
				order by  average_discount_percentage desc
				limit 5;

# 7. Get the complete report of the Gross sales amount for the customer “Atliq
  #Exclusive” for each month. This analysis helps to get an idea of low and
#high-performing months and take strategic decisions.
#The final report contains these columns:
# Month,Year , Gross sales Amount

				select
					concat(monthname(date), ' (', YEAR(date), ')') AS 'Month',
					s.fiscal_year,
					round(sum(gross_price * sold_quantity),2) as Gross_sales_Amount_millions 
				from dim_customer c
				join fact_sales_monthly s
				on s.customer_code = c.customer_code
				join fact_gross_price g 
				on g.product_code = s.product_code
				where c.customer like 'Atliq Exclusive'
				group by month ,s.fiscal_year
				order by s.fiscal_year;

# 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
# output contains these fields sorted by the total_sold_quantity, Quarter ,total_sold_quantity

SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then CONCAT('[',1,'] ',MONTHNAME(date))  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then CONCAT('[',2,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then CONCAT('[',3,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then CONCAT('[',4,'] ',MONTHNAME(date))
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters;

			SELECT 
			CASE
				WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
				WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
				WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
				WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
			END AS Quarters,
				SUM(sold_quantity) AS total_sold_quantity
			FROM fact_sales_monthly
			WHERE fiscal_year = 2020
			GROUP BY Quarters
			ORDER BY total_sold_quantity DESC;

# 9. Which channel helped to bring more gross sales in the fiscal year 2021
 # and the percentage of contribution? The final output contains these fields,
   # channel ,gross_sales_mln ,percentag
   
				with cte as (select 
								c.channel ,
								round(sum(gross_price * sold_quantity)/1000000,2) as gross_sales_mln 
	
				from dim_customer c
				join fact_sales_monthly s 
				on s.customer_code = c.customer_code
				join fact_gross_price g 
				on g.product_code = s.product_code
				where s.fiscal_year =2021
				group by c.channel
				order by gross_sales_mln desc)
		select *,
			concat(round(gross_sales_mln*100/sum(gross_sales_mln) over(),2), ' %') as  percentage
		from cte;

# 10. Get the Top 3 products in each division that have a high
  #total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
  # division ,product_code ,product, total_sold_quantity ,rank_order
		with cte as  
				(select 
					p.division ,p.product_code ,p.product,
					sum(s.sold_quantity) as total_sold_quantity 
			from dim_product p 
			join fact_sales_monthly s 
			on s.product_code = p.product_code
			where fiscal_year= 2021
			group by p.division ,p.product_code, P.product),
		cte1 as (
				select *,
				rank() over(partition by division order by total_sold_quantity desc) as Rank_order
				from cte)
		select * from cte1
		where Rank_order<=3;
 

 
      
  
  
  
  
  
  
  
  
  
  
  
  

