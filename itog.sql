use Bank

create table Client(
ID int primary key,
First_name varchar(250) not null,
Last_name varchar(250)
);

create table Employee(
ID int primary key,
First_name varchar(250) not null,
Last_name varchar(250),
Position varchar(250) not null
);

create table Payment(
ID int primary key,
Payer_ID int not null,
Currency varchar(50) not null,
Amount money not null
);

create table Deposit_info(
Deposit_name varchar(250) primary key,
Interest_rate DECIMAL(2,2) not null,
Duration_days int not null
);

create table Deposits(
ID int primary key,
Payment_ID int not null,
Deposit_info varchar(250) not null,
Resp_employee_ID int not null,
Open_date date not null
);

create table [Transfer](
ID int primary key,
Payment_ID int not null,
To_client_ID int not null,
Resp_employee_ID int not null,);

ALTER TABLE Payment ADD CONSTRAINT FK_1 FOREIGN KEY (Payer_ID) REFERENCES Client (ID);
ALTER TABLE Deposits ADD CONSTRAINT FK_2 FOREIGN KEY (Payment_ID) REFERENCES Payment (ID);
ALTER TABLE Deposits ADD CONSTRAINT FK_3 FOREIGN KEY (Deposit_info) REFERENCES Deposit_info (Deposit_name);
ALTER TABLE Deposits ADD CONSTRAINT FK_4 FOREIGN KEY (Resp_employee_ID) REFERENCES Employee (ID);
ALTER TABLE [Transfer] ADD CONSTRAINT FK_5 FOREIGN KEY (Payment_ID) REFERENCES Payment (ID);
ALTER TABLE [Transfer] ADD CONSTRAINT FK_6 FOREIGN KEY (To_client_ID) REFERENCES Client (ID);
ALTER TABLE [Transfer] ADD CONSTRAINT FK_7 FOREIGN KEY (Resp_employee_ID) REFERENCES Employee (ID);


insert into Client values 
(1,'Evgeniy','A'),
(2, 'Maxim','B'),
(3, 'Ugabuga', null);

insert into Employee values 
(1,'Anton','A','Manager'),
(2, 'Maxim','Belov','Accountant'),
(3, 'Engeniy', 'Pukanovich', 'Manager');

insert into Payment values
(6,3,'RUB',77000),
(5,1,'RUB',50000),
(1,1,'USD',1000),
(2,1,'USD',3000),
(3,2,'RUB',15000),
(4,3,'RUB',300000);

--drop table Deposit_info;
insert into Deposit_info values
('Deposit 9', 0.09, 365),
('Deposit 7', 0.07, 180)

--drop table Deposits;
insert into Deposits values
(3,6,'Deposit 7', 1, '2021-11-15'),
(1, 3, 'Deposit 9', 1, '2021-11-15'),
(2, 4, 'Deposit 7', 1, '2021-10-23')

insert into [Transfer] values
(555, 5, 3, 2),
(777,1,2,2),
(2131, 2, 2, 2)

select * from Deposits

select * from Deposits as dep inner join Deposit_info as inf on dep.Deposit_info=inf.Deposit_name

--1 
go
--подсчитывает количество вкладов, закончившихся к определенной дате
create procedure count_ended_deposits (@dte date)
as
begin
select count(*) as deposits_count from Deposits as dep
inner join Deposit_info as inf 
on dep.Deposit_info=inf.Deposit_name 
where ( select DATEADD(day, inf.Duration_days,dep.Open_date))<@dte
end

declare @d date;
set @d='2023-11-23';
exec count_ended_deposits @d

go

--считает сумму платежей, сделанных в каждой валюте, для определенного клиента
create procedure sum_payments (@client_id int)
as
begin
select Currency, sum(Amount) as Amount from Payment
where Payer_ID=@client_id
group by Currency;
end

declare @d int;
set @d=1;
exec sum_payments @d

go

--какой клиет перевел какому клиенту по ид
create view v_transfers_by_id
as
select p.Payer_ID as from_client, tr.To_client_ID as to_client
from [Transfer] as tr
inner join Payment as p
on tr.Payment_ID = p.ID

--какой клиет перевел какому клиенту по именам
create procedure transfer_by_name
as
begin
select c1.First_name as from_client, c2.First_name as to_client from v_transfers_by_id as v
inner join Client as c1 on v.from_client=c1.ID
inner join Client as c2 on v.to_client=c2.ID
end

exec transfer_by_name
go

--2
select * from Deposit_info

DECLARE DynamicCursor CURSOR
DYNAMIC
SCROLL_LOCKS
FOR SELECT Interest_rate FROM Deposit_info
FOR UPDATE;

OPEN DynamicCursor
DECLARE @Interest_rate decimal;

FETCH NEXT FROM DynamicCursor
INTO @Interest_rate
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE Deposit_info
	SET Interest_rate = Interest_rate + 0.01
	WHERE CURRENT OF DynamicCursor
	FETCH NEXT FROM DynamicCursor
	INTO @Interest_rate
END;

CLOSE DynamicCursor;
DEALLOCATE DynamicCursor;

--вернуть обратно
UPDATE Deposit_info
SET Interest_rate = 0.07
where Deposit_name='Deposit 7';

UPDATE Deposit_info
SET Interest_rate = 0.09
where Deposit_name='Deposit 9';

--3 
go

create trigger Deposit_delete on Deposit_info 
instead of delete as
update Deposit_info set Deposit_name='DEPRECATED'+Deposit_name where Deposit_name = (select Deposit_name from deleted);

delete from Deposit_info where Deposit_name='Deposit 9';

select * from Deposit_info;

update Deposit_info set Deposit_name='Deposit 9' where Deposit_name = 'DEPRECATEDDeposit 9';
--4
go
select * from Deposits

create function BigClients(@mon money)
returns @big_clients table(
client_ID int,
total_deposits money)
as
begin
insert into @big_clients(client_ID, total_deposits)
select c.ID ,sum(Amount) as summa from Deposits as d
inner join Payment as p on d.Payment_ID=p.ID
inner join Client as c on p.Payer_ID=c.ID
group by c.ID
having sum(Amount)>@mon;
return;
end;

select * from BigClients(10000)