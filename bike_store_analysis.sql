1 -- Top 5 Category of bike sold over all

with bike_type as (
					select b.brand_name,c.category_name,o.quantity
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	              ) 
select category_name as Bike_Categories, sum(quantity) as total_quantity_sold
from bike_type
group by category_name
order by total_quantity_sold desc
limit 5

2 -- Revenue generate by top 5 bike categories

with bike_type as (
					select  b.brand_name,c.category_name,o.quantity,p.list_price
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	              ) 
select category_name as Bike_Categories, round(sum(cast(quantity*list_price as numeric)),2) as revenue
from bike_type
group by category_name
order by revenue desc
limit 5

3 -- Top 3 brand in each bike category by quantity of bike sold

with bike_type as (
					select b.brand_name,c.category_name,o.quantity
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	              ),
brand_types as (
				select category_name,brand_name,sum(quantity) as total_quantity_sold
				from bike_type
				group by category_name,brand_name
				order by category_name
	          )
select category_name,brand_name,total_quantity_sold
from (
		select category_name,brand_name,
			   dense_rank() over(partition by category_name order by total_quantity_sold desc) as rnk,
			   total_quantity_sold
		from brand_types
	 ) subquery
where rnk < 4

4 -- Top 3 product in each brand with respect to the different categories on the bases of revenue generated

with bike_type as (
					select p.product_name,b.brand_name,c.category_name,o.quantity,p.list_price
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	              ),
brand_types as (
				select category_name,brand_name,product_name, sum(quantity) as total_quantity_sold,
	                   round(sum(cast(quantity*list_price as numeric)),2) as revenue
				from bike_type
				group by category_name,brand_name,product_name
				order by category_name
	          )
select category_name,brand_name,product_name,total_quantity_sold,revenue
from (
		select category_name,brand_name,product_name,
			   dense_rank() over(partition by category_name order by revenue desc) as rnk,
			   total_quantity_sold, revenue
		from brand_types
	 ) subquery
where rnk < 4

5 -- Total revenue and quantity sold with respect to different stores.

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              ) 
select store_name as store, sum(quantity) as total_quantity_sold,
       round(sum(cast(quantity*list_price as numeric)),2) as revenue
from bike_type
group by store_name
order by revenue desc

6 -- Top 3 categories of bikes by revenue generated in different store

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              ),
cte as (
			select store_name as store, category_name,sum(quantity) as total_quantity_sold,
				   round(sum(cast(quantity*list_price as numeric)),2) as revenue
			from bike_type
			group by store_name,category_name
	   )
select store,category_name,total_quantity_sold,revenue
from (
		select *,
			   dense_rank() over(partition by store order by revenue desc) as rnk
		from cte
	 ) subquery
where rnk < 4

7 -- Top 2 brand names based on revenue generated in each categories for different store

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              ),
cte as (
			select store_name as store, category_name,brand_name,sum(quantity) as total_quantity_sold,
				   round(sum(cast(quantity*list_price as numeric)),2) as revenue
			from bike_type
			group by store_name,category_name,brand_name
	   )
select store,category_name,brand_name,total_quantity_sold,revenue
from (
		select *,
			   dense_rank() over(partition by store,category_name order by revenue desc) as rnk
		from cte
	 ) subquery
where rnk < 3

8 -- Revenue generated by different store across the years

alter table orders
alter order_date  type date USING order_date::date

alter table orders
alter required_date  type date USING required_date::date

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name,
	                       extract(year from order_date) as order_year
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              )
select *
from (       
		select store,sum(case when order_year = 2016 then revenue else 0 end) as revenue_2016,
					 sum(case when order_year = 2017 then revenue else 0 end) as revenue_2017,
					 sum(case when order_year = 2018 then revenue else 0 end) as revenue_2018
		from (
				select store_name as store,order_year, sum(quantity) as total_quantity_sold,
					   round(sum(cast(quantity*list_price as numeric)),2) as revenue
				from bike_type
				group by store_name,order_year
				order by revenue
			 ) subquery
	   group by store
	  ) mainquery
	
9 -- percentage change in revenue generated over last two years(2017,2018)

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name,
	                       extract(year from order_date) as order_year
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              )
select store,round(((revenue_2017-revenue_2016)/revenue_2016)*100,2) as percentage_change_2017,
       round(((revenue_2018-revenue_2017)/revenue_2017)*100,2) as percentage_change_2018
from (       
		select store,sum(case when order_year = 2016 then revenue else 0 end) as revenue_2016,
					 sum(case when order_year = 2017 then revenue else 0 end) as revenue_2017,
					 sum(case when order_year = 2018 then revenue else 0 end) as revenue_2018
		from (
				select store_name as store,order_year, sum(quantity) as total_quantity_sold,
					   round(sum(cast(quantity*list_price as numeric)),2) as revenue
				from bike_type
				group by store_name,order_year
				order by revenue
			 ) subquery
        group by store
	) mainquery 

10 -- monthly trend over the last two years

with bike_type as (
					select b.brand_name,c.category_name,o.quantity,p.list_price,s.store_name,
	                       extract(year from order_date) as order_year,
	                       to_char(order_date,'Mon') as order_month,
	                       extract(month from order_date) as month_number
					from order_items o
					left join products p
					on o.product_id = p.product_id
					left join brands b
					on p.brand_id = b.brand_id
					left join categories c
					on p.category_id = c.category_id
	                left join orders i
	                on o.order_id = i.order_id
	                left join stores s
	                on i.store_id = s.store_id
	              )
select order_month,
       round(sum(case when order_year = 2017 then cast(quantity*list_price as numeric) else 0 end),2) as year_2017,
	   round(sum(case when order_year = 2018 then cast(quantity*list_price as numeric) else 0 end),2) as year_2018
from bike_type
group by order_month,month_number
order by month_number

11 -- Inventory of all the brand in respective stores

select distinct x.store_name,x.brand_name,x.category_name,x.product_name,
       coalesce(y.quantity,0) as stocked_quantity
from (
		select o.product_id,b.brand_name,c.category_name ,p.product_name,i.store_id,s.store_name
		from order_items o
		left join products p 
		on o.product_id = p.product_id
		left join brands b
		on p.brand_id = b.brand_id
		left join categories c
		on p.category_id = c.category_id
		left join orders i
		on o.order_id =  i.order_id
		left join stores s
		on i.store_id = s.store_id
	) x 
left join stocks y
on x.store_id = y.store_id and x.product_id = y.product_id
order by store_name


