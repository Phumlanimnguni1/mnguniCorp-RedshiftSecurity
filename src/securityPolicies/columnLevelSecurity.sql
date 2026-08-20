-- 1. connect to the Redshift endpoint as dbadmin user
psql -U dbadmin -h $RedshiftEndpoint -d $RedshiftDB -p 5439

-- 2.  retrieve all the columns data from the customer table in the sales schema
select * from sales.customer limit 10;

-- 3.  You notice that demographic data such as customer name, address, and phone number are considered personally identifiable information (PII) and should have restricted access. An analyst user should not access these PII columns. 
To restrict access, you actively set up column-level access control on the PII data.
To set up column-level privileges: As dbadmin user:
    revoke SELECT permission on all columns for customer table from the sales_ro role.
    As dbadmin user, grant role sales_ro SELECT permission on columns c_custkey, c_acctbal, c_mktsegment, c_nationkey and c_comment on customer table.

Revoke select on sales.customer from role sales_ro;

-- 4. You now set session authorization as data analyst user and validate (SELECT *) statement.
set temporary session authorization for jane_doe user.
-- As Jane Doe - Data Analyst
SET SESSION AUTHORIZATION 'jane_doe';
SELECT CURRENT_USER;

-- 5.  retrieve all the columns data from the customer table in the sales schema:
select * from sales.customer limit 10;

-- 6.  To set authorization for dbadmin user
SET SESSION AUTHORIZATION 'dbadmin';
SELECT CURRENT_USER;

-- 7. grant the sales_ro role SELECT access only to the columns they need for analytical purposes
GRANT SELECT (c_custkey, c_acctbal, c_mktsegment, c_nationkey, c_comment) ON sales.customer 
TO ROLE sales_ro;

-- 8. set temporary authorization for jane_doe user
SET SESSION AUTHORIZATION 'jane_doe';

-- 9. select only the columns which have the grant permitting access for the sales_ro role
select c_custkey, c_acctbal, c_mktsegment, c_nationkey, c_comment from sales.customer limit 10;


