
-- Create Tables for HR database

-- create an Education table
Create table Education (
Education_ID serial primary key,
Education_Lvl varchar(50));

-- create a Job table
Create table Job (
Job_ID serial primary key,
Job_Title varchar(50));

-- create a Salary table

Create table Salary (
Salary_ID serial primary key,
Salary Money);

-- create a Department table
Create table Department (
Department_ID serial primary key,
Department_Name varchar(50));

-- create an Employee table

Create table Employee (
Employee_ID varchar(8) primary key,
Employee_Name  varchar(50),
Employee_Email varchar(100),
Hire_Date DATE,
Educaion_ID int references Education(Education_ID));

-- create a Location table

Create table Location (
Location_ID serial primary key,
Location varchar(50));

-- create a State table

Create table State (
State_ID Serial primary key,
State varchar(2),
Location_ID int references Location(Location_ID));


-- create a City table
Create table City (
City_ID Serial primary key,
City varchar(50),
State_ID int references State(State_ID));

-- create an Address table

Create table Address (
Address_ID Serial primary key,
Address varchar(100),
City_ID int references City(City_ID));


-- create an Employee History table

Create table Employee_History (
Employee_ID varchar(8) references Employee(Employee_ID),
Manager_ID varchar(8) references Employee(Employee_ID),
Address_ID int references Address(Address_ID),
Department_ID int references Department(Department_ID),
Job_ID int references Job(Job_ID),
Salary_ID int references Salary(Salary_ID),
Start_Date DATE,
End_Date DATE,
--primary key (Employee_ID, Manager_ID, Address_ID,Department_ID,Job_ID,Salary_ID));
primary key (Employee_ID,Start_Date));

-- Insert data into these tables from staging tables

-- Insert data into an Education table
INSERT INTO Education (Education_Lvl)
SELECT DISTINCT(education_lvl) FROM proj_stg;

-- Insert data into a Job table

INSERT INTO Job (Job_Title)
SELECT DISTINCT(job_title) FROM proj_stg;


-- Insert data into a Salary table

INSERT INTO Salary (Salary)
SELECT DISTINCT(salary) FROM proj_stg;

-- Insert data into a Department table

INSERT INTO Department (Department_Name)
SELECT DISTINCT(department_nm) FROM proj_stg;


-- Insert data into an Employee table

INSERT INTO Employee (Employee_ID,Employee_Name,Employee_Email,Hire_Date,Educaion_ID)
SELECT s.Emp_ID, s.Emp_NM, s.Email,s.hire_dt, e.Education_ID
FROM proj_stg AS s
JOIN Education AS e
ON s.education_lvl = e.Education_Lvl
where s.end_dt >='2099-01-01';


-- Insert data into a Location table

INSERT INTO Location (Location)
SELECT DISTINCT(location) FROM proj_stg;


-- Insert data into a State table

INSERT INTO State (State,Location_ID)
SELECT distinct(s.state), l.Location_ID
FROM proj_stg AS s
JOIN Location AS l
ON s.location = l.Location;


-- Insert data into a City table

INSERT INTO City (City,State_ID)
SELECT distinct(s.city), st.State_ID
FROM proj_stg AS s
JOIN State AS st
ON s.state = st.State;

-- Insert data into an Address table

INSERT INTO Address (Address,City_ID)
SELECT distinct(s.address), c.City_ID
FROM proj_stg AS s
JOIN City as c
ON s.city=c.City;


-- Insert data into an Employee History table

INSERT INTO Employee_History (Employee_ID,Manager_ID,Address_ID,Department_ID,Job_ID,Salary_ID,Start_Date,End_Date)
-- working query lets expand this 
select e.Employee_ID,m.Emp_ID,a.Address_ID,d.Department_ID,j.Job_ID,sal.Salary_ID,s.start_dt,s.end_dt
from proj_stg as s
left join proj_stg as m
on (m.Emp_NM=s.manager) 
join Employee as e
on s.Emp_ID=e.Employee_ID
Join Address as a
on a.Address=s.address
Join Department as d
on d.Department_Name=s.department_nm
Join Job as j 
on j.Job_Title=s.job_title
Join Salary as sal
on sal.Salary=Money(s.salary);
--where s.Emp_ID='E17054'
--Limit 10;

-- Optional exercise 1
--Create a view that returns all employee attributes

Create View Employee_View as
-- Query for creating view
Select e.Employee_ID, e.Employee_Name ,
e.Employee_Email ,e.Hire_Date ,
j.Job_Title ,sal.Salary ,d.Department_Name ,
eh.Manager_ID ,eh.Start_date ,eh.End_Date ,
l.Location ,a.Address,c.City ,
st.State ,ed.Education_Lvl 
from Employee as e
Join Employee_History as eh
on e.Employee_ID=eh.Employee_ID
Join Job as j
on eh.Job_ID=j.Job_ID
Join Salary as sal
on eh.Salary_ID=sal.Salary_ID
Join Department as d
on eh.Department_ID=d.Department_ID
Join Address as a
on eh.Address_ID=a.Address_ID
Join City as c
on c.City_ID=a.City_ID
join State as st  
on st.State_ID=c.State_ID
Join location as l
on l.Location_ID=st.Location_ID
Join Education as ed
on e.educaion_id=ed.Education_ID;

-- Optional exercise 2
--Create a view for procedure

Create View Employee_View_P as
-- Query for creating view
Select e.Employee_Name ,
j.Job_Title ,d.Department_Name ,
s.Manager ,eh.Start_date ,eh.End_Date 
from proj_stg as s
left join proj_stg as m
on (m.Emp_NM=s.manager) 
Join Employee as e
on s.Emp_ID=e.Employee_ID
Join Employee_History as eh
on e.Employee_ID=eh.Employee_ID
Join Job as j
on eh.Job_ID=j.Job_ID
Join Department as d
on eh.Department_ID=d.Department_ID;


-- Create a Function named emp_jobs

CREATE OR REPLACE FUNCTION emp_jobs(Emp_Name varchar(8)) 
  RETURNS TABLE (Employee_Name varchar(50),
                 Job_Title varchar(100), 
                 Department_Name  varchar(50),
                  Manager varchar(8),
                  Start_Date Date,
                  End_Date Date) AS 
$func$
  BEGIN
    RETURN QUERY
    Select ev.Employee_Name,
    ev.Job_Title,
    ev.Department_Name,
    ev.Manager_ID,ev.Start_Date,ev.End_Date
   from Employee_View as ev
    where ev.Employee_Name =Emp_Name;
  END;
$func$  LANGUAGE plpgsql;
    
SELECT * from emp_jobs('Eric  Baxter');    

-- Optional exercise 3
-- create user
create user NonMgr with encrypted password 'PGpassword';

-- grant access on all tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO NonMgr;

-- Revoke access from salary table
REVOKE All ON Salary FROM NonMgr;

