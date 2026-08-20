psql -U dbadmin -h $RedshiftEndpoint -d $RedshiftDB -p 5439

-- 1. create the Data Engineer user mary_major, 
the Manager user richard_roe, 
their roles, and grant access to those roles
create user richard_roe with password 'AwsRSmgr@123';

create user mary_major with password 'AwsRSde@123';

create role sales_rw;

grant usage on schema sales to role sales_rw;

grant select, update, delete on all tables in schema sales to role sales_rw;

grant role sales_rw to mary_major;

create role select_all;

grant usage on schema sales to role select_all;

grant select on all tables in schema sales to role select_all;

grant role select_all to richard_roe;

-- 2. check the data in customer table.Currently, data for each country is visible when querying those tables. 
select c_nationkey,n_name,count(1) from sales.customer c join sales.nation n 
on c.c_nationkey=n.n_nationkey 
group by 1,2 limit 10;

-- 3. define a row-level security policy that allows the sales_ro role to only view data from their own country
CREATE RLS POLICY data_analyst_policy
WITH (c_nationkey bigint) AS cs
USING (
cs.c_nationkey IN (select n_nationkey from sales.nation n join sales.employee e on trim(n.n_name) = e.country_name and employee_user_name = current_user and e.employee_status='A'));

-- Grant select on Lookup tables
GRANT SELECT ON sales.nation ,sales.employee
TO RLS POLICY data_analyst_policy; 

-- Attach policy on the table to role
ATTACH RLS POLICY data_analyst_policy
ON sales.customer
TO ROLE sales_ro;

--Enable RLS security on tables
ALTER TABLE sales.customer ROW LEVEL SECURITY on;

-- 4. define a row level security policy for Data Engineers to restrict access based on region for the sales_rw role
CREATE RLS POLICY data_engg_policy
WITH (c_nationkey bigint) AS cs
USING (cs.c_nationkey IN (
select n_nationkey from sales.nation n join sales.region r on n.n_regionkey=r.R_REGIONKEY  join sales.employee e on trim(r.r_name)=e.region_name and employee_user_name = current_user and e.    employee_status='A'));

-- Grant select on Lookup tables
GRANT SELECT ON sales.region, sales.nation ,sales.employee
TO RLS POLICY data_engg_policy; 

-- Attach policy on the table to role
ATTACH RLS POLICY data_engg_policy
ON sales.customer
TO ROLE sales_rw;

-- 5. define a policy that allows access to all rows for the Manager role
CREATE RLS POLICY mgr_select_all
USING ( true );

ATTACH RLS POLICY mgr_select_all
ON sales.customer, sales.supplier
TO ROLE select_all;

-- 6. test the row-level security policy created for Manager role.
Note: The manager role policy grants the manager user complete access to all data without any row-level filtering. 
This enables the manager to view all customer details across nations.
--- As Richard Roe - manager

SET SESSION AUTHORIZATION 'richard_roe';

SELECT CURRENT_USER;

SELECT * FROM sales.customer limit 5;

select c_nationkey,n_name,count(1) from sales.customer c join sales.nation n 
on c.c_nationkey = n.n_nationkey
group by 1,2 limit 5;

--- policies applied: mgr_select_all

-- 7. test the row-level security policy created for Data Analyst role
Note: The data analyst role policy grants user Jane Doe to perform country-level analysis,
without overexposure of protected personal information
-- As Jane Doe - Data Analyst

SET SESSION AUTHORIZATION 'jane_doe';

SELECT CURRENT_USER;

select c_nationkey,n_name,count(1) from sales.customer c join sales.nation n 
on c.c_nationkey = n. n_nationkey
group by 1,2;

Select * from sales.customer limit 10;

-- 8.  test the row-level security policy created for Data Engineer role.
Note: The data engineer role can only actually DELETE rows from their allowed region as per the policy restrictions. 
Trying to delete rows from regions they don’t have access to will have no effect 
and delete zero rows after row-level security filtering is applied.
-- As Mary Major - Data Engineer

SET SESSION AUTHORIZATION 'mary_major';

SELECT CURRENT_USER;

select c_nationkey,n_name,count(1) from sales.customer c join sales.nation n on c.c_nationkey=n.    n_nationkey
group by 1,2;

-- This user can delete data only from it's own Region (ASIA)
Delete from sales.customer USING sales.nation where c_nationkey=n_nationkey 
and n_name='INDIA' and c_acctbal < 0;

--Try to delete data from AMERICA (UNITED STATES)
Delete from sales.customer USING sales.nation where c_nationkey=n_nationkey 
and n_name='UNITED STATES' and c_acctbal < 0; 

--- policies applied: data_engg_policy

