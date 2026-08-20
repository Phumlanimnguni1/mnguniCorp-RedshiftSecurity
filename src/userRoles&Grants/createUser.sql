-- connecting to psql database

cd ~
export RedshiftEndpoint=labworkgrp.754943414246.us-west-2.redshift-serverless.amazonaws.com
echo $RedshiftEndpoint

cd ~
echo $RedshiftEndpoint
echo $RedshiftDB
psql -U dbadmin -h $RedshiftEndpoint -d $RedshiftDB -p 5439

-- 1. create a read-only role in the sales schema, run the following
create role sales_ro;

-- 2. create a new database user (data analyst) named Jane Doe
create user jane_doe with password 'AwsRSuser@123' 
valid until '9999-01-01'
session timeout 3600
connection limit 2;

-- 3. grant the schema usage and select access to the objects in the sales schema
grant usage on schema sales to role sales_ro;
grant select on all tables in schema sales to role sales_ro;

-- 4. assign the role sales_ro to jane_doe
grant role sales_ro to jane_doe;

-- 5. validate if read-only access is working, you now login as john_doe and attempt to run some queries with write operations.
quit
psql -U jane_doe -h $RedshiftEndpoint -d $RedshiftDB -p 5439 -W
AwsRSuser@123

-- 6. verify if you have logged in as jane_doe
select current_user;

-- 7.  validate the read-only permissions for the jane_doe user, create analytics query that finds the top five sellers in San Diego by total tickets sold in 2008:
SET search_path TO sales;

select sellerid, username, (firstname ||' '|| lastname) as name,
city, sum(qtysold)
from sales, date, users
where sales.sellerid = users.userid
and sales.dateid = date.dateid
and year = 2008
and city = 'San Diego'
group by sellerid, username, name, city
order by 5 desc
limit 5;

-- 8. validate the read-only restriction for user jane_doe, run the following INSERT statement:
INSERT into event values (8999,128,9,2049,'Terry Whitlock','2010-10-11 20:00:00');

-- 9. validate that jane_doe is assigned to the read-only sales_ro group
select user_is_member_of('jane_doe', 'sales_ro');


