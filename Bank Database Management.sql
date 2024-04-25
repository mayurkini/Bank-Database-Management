CREATE DATABASE CASESTUDY3
USE CASESTUDY3

SELECT * FROM CONTINENT
SELECT * FROM CUSTOMERS
SELECT * FROM TRANSACTIONS

/*Problem Statement:
You are the database developer of an international bank. You are responsible for
managing the bank’s database. You want to use the data to answer a few
questions about your customers regarding withdrawal, deposit and so on,
especially about the transaction amount on a particular date across various
regions of the world. Perform SQL queries to get the key insights of a customer.

Dataset:

The 3 key datasets for this case study are:

a. Continent: The Continent table has two attributes i.e., region_id and
region_name, where region_name consists of different continents such as
Asia, Europe, Africa etc., assigned with the unique region id.

b. Customers: The Customers table has four attributes named customer_id,
region_id, start_date and end_date which consists of 3500 records.

c. Transaction: Finally, the Transaction table contains around 5850 records
and has four attributes named customer_id, txn_date, txn_type and
txn_amount.*/

--1. Display the count of customers in each region who have done the transaction in the year 2020.

SELECT CON.region_name ,COUNT(T.customer_id) AS COUNT_OF_CUSTOMERS
FROM Transactions AS T
INNER JOIN Customers AS CST
ON T.customer_id=CST.customer_id
INNER JOIN Continent AS CON
ON  CON.region_id=CST.region_id
WHERE YEAR(T.txn_date)=2020
GROUP BY CON.region_name



--2. Display the maximum and minimum transaction amount of each transaction type.
SELECT TXN_TYPE ,MAX(TXN_AMOUNT) AS MAX_TRANSACTION_AMOUNT ,MIN(TXN_AMOUNT) AS MIN_TRANSACTION_AMOUNT
FROM Transactions
GROUP BY txn_type


--3. Display the customer id, region name and transaction amount where transaction type is deposit and transaction amount > 2000.
SELECT CST.customer_id,CON.region_name,T.txn_amount
FROM Transactions AS T
INNER JOIN Customers AS CST
ON T.customer_id=CST.customer_id
INNER JOIN Continent AS CON
ON  CON.region_id=CST.region_id
WHERE T.txn_type='DEPOSIT' AND T.txn_amount>2000

--4. Find duplicate records in the Customer table.
SELECT customer_id,region_id 
FROM Customers
GROUP BY customer_id,region_id
HAVING COUNT(*)>1



--5. Display the customer id, region name, transaction type and transaction amount for the minimum transaction amount in deposit.

SELECT CST.customer_id,CON.region_name,T.txn_amount,T.txn_type
FROM Transactions AS T
INNER JOIN Customers AS CST
ON T.customer_id=CST.customer_id
INNER JOIN Continent AS CON
ON  CON.region_id=CST.region_id
WHERE T.txn_type='DEPOSIT' AND T.txn_amount=(SELECT MIN(txn_amount) FROM Transactions)

--6. Create a stored procedure to display details of customers in the Transaction table where the transaction date is greater than Jun 2020.
CREATE PROCEDURE CUSTOMER_DETAILS
AS
SELECT * FROM Transactions
WHERE YEAR(txn_date)>=2020 AND MONTH(TXN_DATE)>06

EXEC CUSTOMER_DETAILS

--7. Create a stored procedure to insert a record in the Continent table.
CREATE PROCEDURE STR_INSERT @REIGION_ID INT,@REGION_NAME VARCHAR(20)
AS 
INSERT INTO Continent VALUES(@REIGION_ID,@REGION_NAME)

EXEC STR_INSERT 7,'DAHANU'



--8. Create a stored procedure to display the details of transactions that happened on a specific day.
CREATE PROCEDURE STR_TRANSC_DETAILS @TXN_DATE DATE
AS
BEGIN
SELECT * FROM Transactions
WHERE CONVERT(DATE,txn_date)=@TXN_DATE
END


EXEC STR_TRANSC_DETAILS '2020-01-21'




--9. Create a user defined function to add 10% of the transaction amount in a table.CREATE FUNCTION FUCN_ADD (@N INT)RETURNS TABLEAS RETURNSELECT *,(txn_amount+txn_amount*@N/100) NEW_TXN_AMOUNTFROM TransactionsSELECT * FROM FUCN_ADD (10)--10. Create a user defined function to find the total transaction amount for a given transaction type.
CREATE FUNCTION TOTAL (@TXN_TYPE VARCHAR(100))
RETURNS TABLE
AS 
RETURN
(SELECT SUM (txn_amount) AS TOTAL_AMOUNT 
FROM Transactions
WHERE txn_type=@TXN_TYPE
GROUP BY txn_type)


SELECT * FROM TOTAL ('WITHDRAWAL')



--11. Create a table value function which comprises the columns customer_id, region_id ,txn_date , txn_type , txn_amount which will retrieve data from the above table.
CREATE FUNCTION FUN_DATA  (@customer_id INT,@region_name VARCHAR(10),@txn_amount INT ,@txn_type VARCHAR(10),@txn_date DATE)
RETURNS TABLE AS
RETURN 
(SELECT @customer_id AS customer_id ,@region_name AS region_name,
@txn_amount AS Txn_amount,@txn_type AS txn_type,@txn_date AS txn_date
FROM Transactions AS T
INNER JOIN Customers AS CST
ON T.customer_id=CST.customer_id
INNER JOIN Continent AS CON
ON  CON.region_id=CST.region_id)




--12. Create a TRY...CATCH block to print a region id and region name in a single column.
BEGIN TRY
(SELECT CONCAT(region_id,'   ',region_name) FROM Continent)
END TRY
BEGIN CATCH
SELECT 
ERROR_STATE() AS ErrorState , ERROR_MESSAGE() ErrorMsg
END CATCH


--13. Create a TRY...CATCH block to insert a value in the Continent table.

BEGIN TRY
INSERT INTO Continent VALUES  (NULL ,'REDMI') 
END TRY
BEGIN CATCH 
PRINT 'ERROR:INSERTATION FAILED'
END CATCH


--14. Create a trigger to prevent deleting a table in a database.

CREATE TRIGGER tr_prevent_table_drop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    RAISERROR ('Table drop is not allowed.', 16, 1)
    ROLLBACK
END

drop table Continent

 --15. Create a trigger to audit the data in a table.

CREATE table customer_audit (id int identity(1,1), AuditData varchar(50), MODIFIED DATETIME)
select * from customer_audit
  CREATE TRIGGER trg_audit 
ON customers
FOR INSERT
as begin
Declare @id int
select @id = customer_id from inserted
insert into customer_audit values
('New customer with ID = ' + cast(@id as varchar(5)) + ' ' +'is added at', GETDATE())
end


insert into Customers values(2003,2,'2001-11-14','2001-11-14')
drop trigger trg_audit
select * from customer_audit
select * from Customers


--16. Create a trigger to prevent login of the same user id in multiple pages.

select * from sys.dm_exec_sessions order by is_user_process desc


select is_user_process, original_login_name
from sys.dm_exec_sessions
order by is_user_process desc


create trigger trg_logon
on all server
for logon
as begin
declare @LoginName varchar(50)
set @LoginName = ORIGINAL_LOGIN()
if(select count(*) from sys.dm_exec_sessions where is_user_process = 1 and original_login_name = @LoginName) > 3
begin
print 'Fourth connection attempt by ' +@loginName + 'Blocked'
rollback;
end
end

drop trigger trg_logon on all server

--17. Display top n customers on the basis of transaction type.

SELECT * FROM (
                SELECT *,
                  DENSE_RANK () OVER ( PARTITION BY txn_type ORDER BY txn_amount DESC) AS amount_rank
                   FROM Transactions) t
WHERE amount_rank < 5
--HERE 5 CAN BE REPLACED BY ANY N NUMBER ACCORDING TO THE QUESTION
--18. Create a pivot table to display the total purchase, withdrawal and deposit for all the customers.select customer_id, purchase, withdrawal, deposit
from
Transactions
PIVOT
(SUM(txn_amount) for txn_type in ([deposit],[withdrawal],[purchase]))
as PivotTable

