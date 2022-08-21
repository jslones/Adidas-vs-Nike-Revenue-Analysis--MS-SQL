--Create tables with product_id as primary key
create table brands
(product_id varchar(10) primary key,
brand varchar(10))

create table finance
(product_id varchar(10) primary key,
listing_price float,
sale_price float,
discount float,
revenue float)

create table info
(product_name varchar(300),
product_id varchar(10) primary key,
description varchar(1000))

create table reviews
(product_id varchar(10) primary key,
rating float,
reviews float)

create table traffic
(product_id varchar(10) primary key,
last_visited smalldatetime)

--Change empty cells to null in brands table
update brands
set brand = null
where brand =''
go

--Count number of product id's with no information
select count(*) as Total_Row_Count,
       sum(case when b.brand is not null then 1
       else 0
	   end) as Brand_Count,
	   sum(case when f.revenue is not null then 1
	   else 0
	   end) as Finance_Count,
	   sum(case when i.description is not null then 1
	   else 0
	   end) as Info_Count,
	   sum(case when r.reviews is not null then 1
	   else 0
	   end) as Review_Count,
	   sum(case when t.last_visited is not null then 1
	   else 0
	   end) as Traffic_Count
from brands as b
left join finance as f on b.product_id = f.product_id
left join info as i on b.product_id = i.product_id
left join reviews as r on b.product_id = r.product_id
left join traffic as t on b.product_id = t.product_id
;
go

--Compare pricing and revenue between Addidas and Nike
with cte1 as
(select b.product_id, b.brand, 
       case when f.listing_price < 25.00 then 'Cheap'
	        when f.listing_price >=25 and f.listing_price < 75 then 'Affordable'
	        when f.listing_price >=75 and f.listing_price < 150 then 'Expensive'
	   else 'Elite'
	   end as Price_Category,
f.revenue
from brands as b
join finance as f on b.product_id = f.product_id
)
select brand, Price_Category, count(*) as NumberofProducts, sum(revenue) as Total_Revenue,
round(sum(revenue) / (select sum(revenue) from cte1),2) as Percent_Total_Sales
from cte1
where brand is not null
group by brand, Price_Category
order by brand, Price_Category
;
select brand, count(brand) as NumberofProducts, sum(revenue) Total_Revenue,
round(sum(revenue)/ count(brand),2) as AverageRev_PerItem
from brands as b
join finance as f on b.product_id = f.product_id
where brand is not null
group by brand
;
--Product pricing and sales for Adidas
with cte2 as
(select b.product_id, b.brand, 
       case when f.listing_price < 25.00 then 'Cheap'
	        when f.listing_price >=25 and f.listing_price < 75 then 'Affordable'
	        when f.listing_price >=75 and f.listing_price < 150 then 'Expensive'
	   else 'Elite'
	   end as Price_Category,
f.revenue
from brands as b
join finance as f on b.product_id = f.product_id
where b.brand = 'Adidas'
)
select brand, Price_Category, count(*) as NumberofAdidas, sum(revenue) as Adidas_Revenue,
round(sum(revenue)/(select sum(revenue) from cte2),2) as Percent_Revenue
from cte2
group by brand, Price_Category
;
--Comparing pricing and sales for Nike
with cte3 as
(select b.product_id, b.brand, 
       case when f.listing_price < 25.00 then 'Cheap'
	        when f.listing_price >=25 and f.listing_price < 75 then 'Affordable'
	        when f.listing_price >=75 and f.listing_price < 150 then 'Expensive'
	   else 'Elite'
	   end as Price_Category,
f.revenue
from brands as b
join finance as f on b.product_id = f.product_id
where b.brand = 'Nike'
)
select brand, Price_Category, count(*) as NumberofAdidas, sum(revenue) as Nike_Revenue,
round(sum(revenue)/(select sum(revenue) from cte3),2) as Percent_Revenue
from cte3
group by brand, Price_Category
go
--Analysis of how discount affects revenue for 
select b.brand, f.discount, count(*) as Number_Items, sum(f.revenue) Total_Revenue,
round(sum(f.revenue) / count(*),2) as Revenue_PerItem
from brands as b
join finance as f on b.product_id = f.product_id
where brand is not null
group by discount,brand
order by Revenue_PerItem desc
;
go

--Determine whether or not there is a correlation between revenue and number of reviews
with Means as
(select f.revenue, r.reviews, 
avg(f.revenue) over() as MeanRevenue, avg(r.reviews) over() as MeanReviews
from finance as f
join reviews as r on f.product_id = r.product_id
where revenue is not null and reviews != 0
),
Variances as
(select var(revenue) as VarRevenue,
        var(reviews) as VarReviews
from Means
),
StandardDev as
(select SQRT(VarRevenue) as StdRevenue,
SQRT(VarReviews) as StdReviews
from Variances
),
Covarainces as
(select avg((revenue - MeanRevenue)*(reviews - MeanReviews)) as Covariance
from Means
)
select Covariance / (StdRevenue * StdReviews) as Correlation
from Covarainces,StandardDev
go

--Analsis of footwear vs clothing revenue 
with cte as(
select case when i.description like '%shoe%' then 'Footwear'
       when i.description like '%trainer%' then 'Footwear'
	   when i.description like '%foot%' then 'Footwear'
       else 'Clothes'
       end as Product_type,
f.revenue
from info as i
join finance as f on i.product_id = f.product_id)
select Product_type, count(*) as Number_Products, round(sum(revenue),2) as Total_Revenue, round(sum(revenue)/count(*),2) as Revenue_PerItem
from cte
group by Product_type
;













