--Lấy đại lý có tỷ lệ chuyển đổi lead >= 70%
select Distinct location_name, sales_agent_name, time_year, success_lead
from (
    --Tính phần trăm chuyển đổi lead của từng đại lý theo địa điểm và năm
		select location_name, sales_agent_name, time_year,count(*) as success_lead,
		percent_rank() over(order by count(*)) as PercentRank
		from w_lead_f lead inner join w_location_d l on lead.location_id = l.location_id
							inner join w_sales_agent_d s on lead.sales_agent_id = s.sales_agent_id
							inner join w_time_d t on lead.created_date = t.time_id
		where lower(lead_success) = 'y'
		group by location_name, time_year, sales_agent_name
		order by location_name,time_year,success_lead desc ) x
where PercentRank >= 0.7

-- Tính tỷ lệ giao hàng muộn tại các khu vực (khu vực ít giao muộn nhất sẽ sếp cao hơn)
SELECT l.location_name,time_year,
    Round(avg(getbusdaysdiff(x1.first_shipment_date, j.date_promised)),0) AS busdaysdiff
    , dense_rank() over(Partition by time_year order by Round(avg(getbusdaysdiff(x1.first_shipment_date, j.date_promised)),0)) as rank
    FROM w_job_f j,w_location_d l, w_time_d t,
    ( SELECT w_sub_job_f.job_id,
            min(w_job_shipment_f.actual_ship_date) AS first_shipment_date
           FROM w_job_shipment_f,
            w_sub_job_f,
            w_job_f
          WHERE w_sub_job_f.sub_job_id = w_job_shipment_f.sub_job_id AND w_job_f.job_id = w_sub_job_f.job_id AND w_job_shipment_f.actual_ship_date > w_job_f.date_promised
          GROUP BY w_sub_job_f.job_id) x1 
  WHERE  j.job_id = x1.job_id AND j.location_id = l.location_id AND 
  t.time_id=j.date_promised And j.date_promised < x1.first_shipment_date
  group by  time_year,l.location_name
  order by time_year,Rank,busdaysdiff DESC

  --Tính khách hàng mua hàng nhiều nhất
  SELECT c.cust_key, cust_name,time_year,sum(i.invoice_amount) AS suminvoiceamt
   FROM w_invoiceline_f i, w_customer_d c, w_time_d t
   where i.cust_key = c.cust_key and i.invoice_due_date = t.time_id
   GROUP BY c.cust_key,cust_name,time_year
     order by suminvoiceamt DESC

--Loại hàng bán nhiều nhất
select sales_class_desc,t.time_year as year, count(sales_class_desc) as "Sale_Class Number"
from w_invoiceline_f i  inner join w_sales_class_d s
on s.sales_class_id = i.sales_class_id
inner join w_time_d t on t.time_id = i.invoice_due_date
group by sales_class_desc,t.time_year
order by "Sale_Class Number" DESC