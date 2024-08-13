SET SQL_SAFE_UPDATES = 0;
-- 1. Create a trigger before_total_quantity_update to update total quantity of product when 
-- Quantity_On_Hand and Quantity_sell change values. Then Update total quantity when Product P1004 
-- have Quantity_On_Hand = 30, quantity_sell =35
Delimiter $$
create trigger before_total_quantity_update
before update on product
for each row
begin 
if old.quantity_on_hand <> new.quantity_on_hand or old.quantity_sell <> new.quantity_sell
then
set new.total_quantity = new.quantity_on_hand + new.quantity_sell;
end if;
end;
$$
update product
set quantity_on_hand = 30, quantity_sell = 35
where product_number = 'P1004';

-- 2. Create a trigger before_remark_salesman_update to update Percentage of per_remarks in a salesman 
-- table (will be stored in PER_MARKS column) : per_remarks = target_achieved*100/sales_target.
alter table salesman
add column per_marks float;

Delimiter $$
create trigger  before_remark_salesman_update
before update on salesman
for each row
begin
set new.per_marks = new.target_achieved*100/new.sales_target;
end;
$$

-- 3. Create a trigger before_product_insert to insert a product in product table.
Delimiter $$
create trigger before_product_insert
before insert on product
for each row
begin 
if new.product_name is not null then
insert into product
values(new.product_number, new.product_name, new.quantity_on_hand, new.quantity_sell, new.sell_price, new.cost_price,
new.profit, new.total_quantity, new.Exp_Date);
end if;
end;
$$

-- 4. Create a trigger to before update the delivery status to "Delivered" when an order is marked as 
-- "Successful".
Delimiter $$
create trigger before_update_the_delivery
before update on salesorder
for each row
begin
if new.order_status = 'Succesful' then
set new.delivery_status = 'Delivered';
end if;
end;
$$

-- 5. Create a trigger to update the remarks "Good" when a new salesman is inserted.
Delimiter $$
create trigger update_remark
before insert on salesman
for each row
begin
if new.salesman_number is not null then
set new.remark = 'Good';
end if;
end;
$$

-- 6. Create a trigger to enforce that the first digit of the pin code in the "Clients" table must be 7.
Delimiter $$
create trigger endforce_digit
before insert on clients
for each row
begin
if new.pincode not like '7%' then
signal sqlstate '45000' set message_text = 'Wrong first digit';
end if;
end;
$$

-- 7. Create a trigger to update the city for a specific client to "Unknown" when the client is deleted

create table deleted_clients(
Client_Number varchar(10),
Client_Name varchar(25) not null,
Address varchar(30),
City varchar(30),
Pincode int not null,
Province char(25),
Amount_Paid decimal(15,4),
Amount_Due decimal(15,4),
check(Client_Number like 'C%'),
primary key(Client_Number)
);

Delimiter $$
create trigger update_city
before delete on clients
for each row
begin
insert into deleted_clients
value(old.client_number,
old.client_name,
old.address,'Unknown',
old.pincode,
old.province, old.amount_paid,
old.amount_due);
end;
$$


-- 8. Create a trigger after_product_insert to insert a product and update profit and total_quantity in product 
-- table.
Delimiter $$
create trigger after_product_insert
before insert on product
for each row
begin
if new.quantity_on_hand is not null and new.quantity_sell is not null 
and new.sell_price is not null and new.cost_price is not null then
update product
	set profit = (new.quantity_sell * new.sell_price)-(new.Quantity_on_hand * new.cost_price)
    where product_number = new.product_number;
end if;
end;
$$

-- 9. Create a trigger to update the delivery status to "On Way" for a specific order when an order is inserted.
Delimiter $$
create trigger order_delivery_status
before insert on salesorder
for each row
begin
if new.order_number is not null then
set new.delivery_status = 'On Way';
end if;
end;
$$

-- 10. Create a trigger before_remark_salesman_update to update Percentage of per_remarks in a salesman 
-- table (will be stored in PER_MARKS column) If per_remarks >= 75%, his remarks should be ‘Good’. 
-- If 50% <= per_remarks < 75%, he is labeled as 'Average'. If per_remarks <50%, he is considered 
-- 'Poor'.

Delimiter $$
create trigger before_remark_salesman_update2
before update on salesman
for each row
begin
set new.per_marks = new.target_achieved*100/new.sales_target;
if new.per_marks >= 75 then set new.remark = 'Good';
elseif new.per_marks < 75 and new.per_marks >= 50 then set new.remark = 'Average';
elseif new.per_marks < 50 then set new.remark = 'Poor';
end if;
end;
$$

-- 11. Create a trigger to check if the delivery date is greater than the order date, if not, do not insert it.
Delimiter $$
create trigger check_delivery
before insert on salesorder
for each row
begin
if new.delivery_date is not null and new.order_date is not null and 
new.order_number is not null and
new.delivery_date < new.order_date then
signal sqlstate '45000' set message_text = 'The delivery_date is greater than order_date';
end if;
end;
$$

-- 12. Create a trigger to update Quantity_On_Hand when ordering a product (Order_Quantity)
Delimiter $$
create trigger update_Quantity
before insert on salesorderdetails
for each row
begin
update product
set quantity_on_hand = quantity_on_hand - new.order_quantity;
end;
$$
select * from salesorder;
insert into salesorderdetails
value('O2777', 'P999', -3);
select * from salesorderdetails;
select * from product;
-- b) Writing Function:
-- 1. Find the average salesman’s salary.
Delimiter $$
create function find_ave()
returns decimal(15,4)
deterministic
begin
declare avg_salary decimal(15,4);
select avg(salary) into avg_salary from salesman;
return avg_salary;
end;
$$
select find_ave();

-- 2. Find the name of the highest paid salesman.
Delimiter $$
create function find_highest_paid()
returns varchar(25)
deterministic
begin
declare sal_name varchar(25);
select salesman_name into sal_name from salesman 
order by salary desc limit 1;
return sal_name;
end;
$$
select find_highest_paid();

-- 3. Find the name of the salesman who is paid the lowest salary.
Delimiter $$
create function find_lowest_paid()
returns varchar(25)
deterministic
begin
declare sal_name varchar(25);
select salesman_name into sal_name from salesman 
order by salary asc limit 1;
return sal_name;
end;
$$
select find_lowest_paid();

-- 4. Determine the total number of salespeople employed by the company.
Delimiter $$
create function totalSalesPeople()
returns int
deterministic
begin
declare total int;
select count(Salesman_Number) into total from salesman;
return total;
end;
$$
select totalSalesPeople();

-- 5. Compute the total salary paid to the company's salesman.
Delimiter $$
create function totalSalary()
returns decimal(15,4)
deterministic
begin
declare total decimal(15,4);
select sum(salary) into total from salesman ;
return total;
end;
$$
select totalSalary();

-- 6. Find Clients in a Province
Delimiter $$
create function clients(p_province varchar(50))
returns varchar(500)
deterministic
begin
  declare client_list varchar(500);
  select group_concat(lower(client_name) separator ', ') into client_list
  from clients
  where province = p_province;
  return client_list;
end;
$$

select clients('Hanoi');
-- 7. Calculate Total Sales
Delimiter $$
create function totalSales()
returns int
deterministic
begin
declare total int;
select sum(order_quantity) into total from salesorderetails;
return total;
end;
$$
select totalSales();

-- 8. Calculate Total Order Amount
Delimiter $$
create function totalOrder()
returns int
deterministic
begin
declare total int;
select count(order_number) into total from salesorder ;
return total;
end;
$$
select totalOrder();