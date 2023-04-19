-- ============================ Problem Statement 11 ==============================================================================================

-- Problem Statement 1:
-- Patients are complaining that it is often difficult to find some medicines. They move from pharmacy to pharmacy to get the required medicine.
-- A system is required that finds the pharmacies and their contact number that have the required medicine in their inventory.
-- So that the patients can contact the pharmacy and order the required medicine.
-- Create a stored procedure that can fix the issue.
delimiter $$
drop procedure if exists find_medicine;
create procedure find_medicine (medname varchar(174))
begin 
select ph.pharmacyname, ph.pharmacyid from keep ke inner join pharmacy ph on ph.pharmacyid = ke.pharmacyid 
where ke.medicineid in (select medicineid from medicine where productname like concat("%", medname, "%"));
end $$
delimiter ;

call find_medicine("ostenan");

-- Problem Statement 2:
-- The pharmacies are trying to estimate the average cost of all the prescribed medicines per prescription, for all the prescriptions
-- they have prescribed in a particular year. Create a stored function that will return the required value when the pharmacyID and year
-- are passed to it. Test the function with multiple values.

delimiter $$
drop function if exists average_prescreption_bill;
create function average_prescreption_bill(phid int, year1 varchar(5))
returns numeric(20,5) deterministic
begin
declare v1 numeric;
select averageprice into v1 from
(
select prescriptionid, pharmacyid, avg(totalprice)"averageprice", year from
(
select co.prescriptionid, pr.pharmacyid, co.quantity*(select maxprice from medicine where medicineid = co.medicineid) "totalprice", (select year(date) from treatment where treatmentid = (select treatmentid from prescription where prescriptionid = co.prescriptionid)) "year"
from contain co inner join medicine me on co.medicineid = me.medicineid
inner join prescription pr on pr.prescriptionid = co.prescriptionid
inner join treatment tr on tr.treatmentid = pr.treatmentid order by 1
) a group by pharmacyid, year order by 2
) b where pharmacyid = phid and year = year1;
return v1;
end $$
delimiter ;





-- Problem Statement 3:
-- The healthcare department has requested an application that finds out the disease that was spread the most in a state for a given year.
-- So that they can use the information to compare the historical data and gain some insight.
-- Create a stored function that returns the name of the disease for which the patients from a particular state had the
-- most number of treatments for a particular year. Provided the name of the state and year is passed to the stored function.


-- Problem Statement 4:
-- The representative of the pharma union, Aubrey, has requested a system that she can use to find how many people in a specific city
-- have been treated for a specific disease in a specific year. Create a stored function for this purpose.



-- Problem Statement 5:
-- The representative of the pharma union, Aubrey, is trying to audit different aspects of the pharmacies. She has requested a system
-- that can be used to find the average balance for claims submitted by a specific insurance company in the year 2022. 
-- Create a stored function that can be used in the requested application. 

