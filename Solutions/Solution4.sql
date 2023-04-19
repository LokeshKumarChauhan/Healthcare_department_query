-- ============================ Problem Statement 4 ==============================================================================================

-- Problem Statement 1: “HealthDirect” pharmacy finds it difficult to deal with the product type of medicine being displayed in numerical form, 
-- they want the product type in words. Also, they want to filter the medicines based on tax criteria. 
-- Display only the medicines of product categories 1, 2, and 3 for medicines that come under tax category I and medicines of 
-- product categories 4, 5, and 6 for medicines that come under tax category II.
-- Write a SQL query to solve this problem.


select m.medicineID,productName, (case 
    when producttype = 1 then "generic"
	when producttype = 2 then "patent"
    when producttype = 3 then "reference"
    when producttype = 4 then "similar"
	when producttype = 5 then "new"
    when producttype = 6 then "specific"
    end ) product_category, 
(case 
    when producttype in (1,2,3) then 'I'
    when producttype in (4, 5, 6) then 'II' 
    end ) tax_category
from medicine m join keep ke on m.medicineid = ke.medicineid
join pharmacy ph on ke.pharmacyid = ph.pharmacyid where ph.pharmacyname = "healthdirect";

-- Problem Statement 2:  
-- 'Ally Scripts' pharmacy company wants to find out the quantity of medicine prescribed in each of its prescriptions.
-- Write a query that finds the sum of the quantity of all the medicines in a prescription and if the total quantity of medicine is less than 20
-- tag it as “low quantity”. If the quantity of medicine is from 20 to 49 (both numbers including) tag it as “medium quantity“ and
-- if the quantity is more than equal to 50 then tag it as “high quantity”.
-- Show the prescription Id, the Total Quantity of all the medicines in that prescription, and the Quantity tag for all the prescriptions
-- issued by 'Ally Scripts'.

select pr.prescriptionid, sum(co.quantity) total_quantity, 
(case when sum(co.quantity) < 20 then "low quantity"
when count(co.quantity) <= 49 then "medium quantity"                                                   
when count(co.quantity) >= 50 then "high quantity"
end) quantity_tag
from prescription pr 
join contain co on co.prescriptionid = pr.prescriptionid
join pharmacy ph on ph.pharmacyid = pr.pharmacyid 
where ph.pharmacyname = "ally scripts" 
group by pr.prescriptionid;


-- Problem Statement 3: 
-- In the Inventory of a pharmacy 'Spot Rx' the quantity of medicine is considered ‘HIGH QUANTITY’ when the quantity exceeds 7500 and 
-- ‘LOW QUANTITY’ when the quantity falls short of 1000. The discount is considered “HIGH” if the discount rate on a product is 30% or higher
-- and the discount is considered “NONE” when the discount rate on a product is 0%.
--  'Spot Rx' needs to find all the Low quantity products with high discounts and all the high-quantity products with no discount 
-- so they can adjust the discount rate according to the demand. 
-- Write a query for the pharmacy listing all the necessary details relevant to the given requirement.
with cte as (
select medicineID,quantity,discount, 
(case when quantity <=1000 then "Low quantity"
	  when quantity>= 7500 then "High quantity"   
end ) as quantity_tag ,
(case when discount<=0 then "None"
	  when discount>=30 then "High"
end ) as discount_tag
from keep k join pharmacy ph on k.pharmacyID=ph.pharmacyID 
where pharmacyName="Spot Rx" )
select * from cte where (quantity_tag='High quantity' and discount_tag='None') or (quantity_tag='Low quantity' and discount_tag='High') 
order by medicineId;

-- Problem Statement 4: 
-- Mack, From HealthDirect Pharmacy, wants to get a list of all the affordable and costly, hospital-exclusive medicines in the database.
-- Where affordable medicines are the medicines that have a maximum price of less than 50% of the avg maximum price of all the medicines 
-- in the database, and costly medicines are the medicines that have a maximum price of more than double the avg maximum price of all the medicines
-- in the database.  Mack wants clear text next to each medicine name to be displayed that identifies the medicine as affordable or costly.
-- The medicines that do not fall under either of the two categories need not be displayed.
-- Write a SQL query for Mack for this requirement.

select * from (
select medicineID,productName, maxPrice,
(case
	when maxPrice>2* (select avg(maxPrice) from medicine) then "costly"
    when maxPrice< 0.5*(select avg(maxPrice) from medicine) then "Affordable"
end ) as medicine_tag
 from medicine where hospitalExclusive='S'  ) sub 
 where medicine_tag="costly" or medicine_tag="Affordable" order by medicineID;


-- Problem Statement 5:  
-- The healthcare department wants to categorize the patients into the following category.
-- YoungMale: Born on or after 1st Jan  2005  and gender male.
-- YoungFemale: Born on or after 1st Jan  2005  and gender female.
-- AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
-- AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
-- MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
-- MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
-- ElderMale: Born before 1st Jan 1970, and gender male.
-- ElderFemale: Born before 1st Jan 1970, and gender female.
-- Write a SQL query to list all the patient name, gender, dob, and their category.

select pa.patientid, pe.personname, pa.dob, pe.gender, 
(case when pa.dob < "1970-01-01" and pe.gender = "male" then "Elder Male"
	  when pa.dob < "1970-01-01" and pe.gender = "female" then "Elder FeMale"
      when pa.dob < "1985-01-01" and pe.gender = "male" then "Mid Age Male"
      when pa.dob < "1985-01-01" and pe.gender = "female" then "Mid Age Female"
      when pa.dob < "2005-01-01" and pe.gender = "male" then "Adult Male"
      when pa.dob < "2005-01-01" and pe.gender = "female" then "Adult Female"
      when pa.dob >= "2005-01-01" and pe.gender = "male" then "Young Male"
      when pa.dob >= "2005-01-01" and pe.gender = "female" then "Young Female"
end) "category"  from patient pa join person pe on pe.personid = pa.patientid;

