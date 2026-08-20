psql -U dbadmin -h $RedshiftEndpoint -d $RedshiftDB -p 5439

--This task describes four different data masking scenarios.
-- Full data masking for regular users
-- Partial data masking for analytics users
-- Conditional data masking for fraud detection
-- Full data access for auditors

-- 1. create a sample test table that has sensitive data for credit card numbers
-- Create a sample test table that has sensitive data for credit card numbers.
SET SESSION AUTHORIZATION dbadmin;

CREATE TABLE credit_cards (
  customer_id INT,
  fraud boolean,
  tran_date date,
  credit_card TEXT
  
);
 INSERT INTO credit_cards
VALUES
  (100, 'Y' , current_date-10 ,'4532993817514842'),
  (100, 'N', current_date-60, '4716002041425888'),
  (102, 'N', current_date-100, '5243112427642649'),
  (102, 'Y', current_date-90, '6011720771834675'),
  (102, 'N', current_date-120,'6011378662059710'),
  (103, 'Y', current_date-30,'373611968625635')
;

select * from credit_cards;

-- 2. configure mask full credit card data for regular users in Amazon Redshift Serverless
SET SESSION AUTHORIZATION dbadmin;

--Run GRANT to grant permission to use the SELECT statement on the table.
GRANT SELECT ON credit_cards TO PUBLIC;

--create Regular user
CREATE USER regular_user WITH PASSWORD '1234Test!';

--create a masking policy that fully masks the credit card number
CREATE MASKING POLICY mask_credit_card_full
WITH (credit_card VARCHAR(256))
USING ('000000XXXX0000'::TEXT);

ATTACH MASKING POLICY mask_credit_card_full
ON credit_cards(credit_card)
TO PUBLIC;


SET SESSION AUTHORIZATION regular_user;

SELECT * FROM credit_cards;
-- Credit card data are fully masked.

-- 3.  configure dynamic data masking to reveal the last 4 digits of credit card numbers for analytics users
SET SESSION AUTHORIZATION dbadmin;

--create anlytic user
CREATE USER analytics_user WITH PASSWORD '1234Test!';

--create the analytics_role role and grant it to analytics_user
--regular_user does not have a role
CREATE ROLE analytics_role;

GRANT ROLE analytics_role TO analytics_user;

--create a user-defined function that partially obfuscates credit card data
CREATE FUNCTION REDACT_CREDIT_CARD (credit_card TEXT)
RETURNS TEXT IMMUTABLE
AS $$
    SELECT CASE
        WHEN LENGTH($1) >= 4 AND TRANSLATE($1, '0123456789', '') = ''
        THEN REPEAT('X', LENGTH($1) - 4) || RIGHT($1, 4)
        ELSE REPEAT('X', LENGTH($1))
    END
$$ LANGUAGE sql;

--create a masking policy that applies the REDACT_CREDIT_CARD function
CREATE MASKING POLICY mask_credit_card_partial
WITH (credit_card VARCHAR(256))
USING (REDACT_CREDIT_CARD(credit_card));


--attach mask_credit_card_partial to the analytics role
--users with the analytics role can see partial credit card information
ATTACH MASKING POLICY mask_credit_card_partial
ON credit_cards(credit_card)
TO ROLE analytics_role
PRIORITY 10;

--confirm the partial masking policy is in place for users with the analytics role by selecting from     the credit card table as analytics_user
SET SESSION AUTHORIZATION analytics_user;

SELECT * FROM credit_cards;

-- 4. configure dynamic data masking to reveal full credit card data only for the fraud team when the fraud flag is set to Yes
SET SESSION AUTHORIZATION dbadmin;

CREATE USER riskmanagment_user WITH PASSWORD '1234Test!';

--create the analytics_role role and grant it to analytics_user
--regular_user does not have a role
CREATE ROLE riskmanagment_role;

GRANT ROLE riskmanagment_role TO riskmanagment_user;

--Create a masking policy that partially redacts credit card numbers if the is_fraud value for that     row is TRUE,
--and otherwise blanks out the credit card number completely.

CREATE MASKING POLICY mask_credit_card_conditional
    WITH (fraud BOOLEAN, pan varchar(256)) 
    USING (CASE WHEN fraud THEN REDACT_CREDIT_CARD(pan)
                ELSE Null
           END);

ATTACH MASKING POLICY mask_credit_card_conditional ON credit_cards (credit_card)
 USING (fraud, credit_card)
 TO ROLE riskmanagment_role  PRIORITY 100;   

SET SESSION AUTHORIZATION riskmanagment_user;

SELECT * FROM credit_cards;

-- 5. allow auditors to view unmasked credit card data in Amazon Redshift Serverless
SET SESSION AUTHORIZATION dbadmin;

CREATE USER audit_user WITH PASSWORD '1234Test!';

--create the analytics_role role and grant it to analytics_user
--regular_user does not have a role
CREATE ROLE audit_role;

GRANT ROLE audit_role TO audit_user;

--Create a masking policy that partially redacts credit card numbers if the is_fraud value for that row is TRUE,
--and otherwise blanks out the credit card number completely.
CREATE MASKING POLICY show_full_credit_card_number
    WITH (credit_card varchar(256)) 
    USING (credit_card);

ATTACH MASKING POLICY show_full_credit_card_number ON credit_cards (credit_card)
 USING (credit_card)
 TO ROLE audit_role  PRIORITY 15;  

SET SESSION AUTHORIZATION audit_user;

SELECT * FROM credit_cards;
