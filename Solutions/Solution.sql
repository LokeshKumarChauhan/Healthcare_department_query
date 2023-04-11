-- Problem Statement 1:Jimmy, from the healthcare department, has requested a report that shows how the number of treatments each age 
-- category of patients has gone through in the year 2022. 
-- The age category is as follows, Children (00-14 years), Youth (15-24 years), Adults (25-64 years), and Seniors (65 years and over).
-- Assist Jimmy in generating the report. 
with cte as (select t.treatmentID,t.date as treatment_date,t.patientID,t.diseaseID,t.claimID,p.ssn,p.dob,
year(curdate())-year(dob) as patient_age 
from treatment t join patient p on t.patientID=p.patientID order by patient_age )
SELECT CASE 
    WHEN patient_age BETWEEN 0 AND 14 THEN 'Children' 
    WHEN patient_age BETWEEN 15 AND 24 THEN 'Youth' 
    WHEN patient_age BETWEEN 25 AND 64 THEN 'Adults' 
    ELSE 'Seniors' 
  END AS age_category,   COUNT(*) AS number_of_treatments 
FROM cte WHERE YEAR(treatment_date) = 2022 GROUP BY age_category;



-- Problem Statement 2:  Jimmy, wants to know which disease is infecting people of which gender more often.Assist Jimmy with this purpose by 
-- generating a report that shows for each disease the male-to-female ratio.Sort the data in a way that is helpful for Jimmy.

SELECT t.diseaseID, d.diseaseName,
       SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END) AS female_count,
       (SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) / 
        SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END)) AS male_to_female_ratio
FROM treatment t join patient p on t.patientID=p.patientID join person pe on pe.personID=p.patientID join disease d on t.diseaseID=d.diseaseID
GROUP BY t.diseaseID ORDER BY male_to_female_ratio DESC;

-- Problem Statement 3: 
-- Jacob, from insurance management, has noticed that insurance claims are not made for all the treatments. 
-- He also wants to figure out if the gender of the patient has any impact on the insurance claim. 
-- Assist Jacob in this situation by generating a report that finds for each gender 
-- the number of treatments, number of claims, and treatment-to-claim ratio. And notice 
-- if there is a significant difference between the treatment-to-claim ratio of male and female patients.


select gender,count(treatmentID) as total_treatment,count(t.claimid) as total_claim ,count(treatmentID)/count(t.claimid) as ratio
from treatment t left join claim c on t.claimID=c.claimID  join patient p on t.patientID=p.patientID join person pe on p.patientID=pe.personID 
group by gender;


-- Problem Statement 4: The Healthcare department wants a report about the inventory of pharmacies. Generate a report on their behalf 
-- that shows how many units of medicine each pharmacy has in their inventory, the total maximum retail price of those medicines, and 
-- the total price of all the medicines after discount. 
-- Note: discount field in keep signifies the percentage of discount on the maximum price.
with cte as (
	select p.pharmacyID, p.pharmacyName, k.medicineID ,k.quantity, k.discount, m.maxPrice,
	(maxPrice*(100-discount)/100) as discount_price, 
	quantity*maxPrice as total_max_price
	from pharmacy p join keep k on p.pharmacyID=k.pharmacyID join medicine m on k.medicineID=m.medicineID
	order by pharmacyID,medicineID)
select * , quantity*discount_price as total_discounted_price from cte order by pharmacyID,medicineID ;

-- Problem Statement 5: The healthcare department suspects that some pharmacies prescribe more medicines than others in a single prescription, 
-- for them, generate a report that finds for each pharmacy the maximum, minimum and average number of medicines prescribed in their prescriptions. 
 
select pharmacyName, MAX(quantity_count) as max_val, MIN(quantity_count) as min_val, AVG(quantity_count) as average_val
FROM(  SELECT pr.prescriptionID, ph.pharmacyName, COUNT(DISTINCT(c.medicineID)) as quantity_count
	   FROM PHARMACY ph JOIN PRESCRIPTION pr ON ph.pharmacyId = pr.pharmacyId
	   JOIN CONTAIN c ON c.prescriptionId = pr.prescriptionId GROUP BY pr.prescriptionId
) A GROUP BY pharmacyName;

-- ============================ Problem Statement 2 ==============================================================================================

-- Problem Statement 1: A company needs to set up 3 new pharmacies, they have come up with an idea that the pharmacy can be set up in cities
-- where the pharmacy-to-prescription ratio is the lowest and the number of prescriptions should exceed 100. 
-- Assist the company to identify those cities where the pharmacy can be set up.

with cte as (select city,count( distinct p.pharmacyId)  as pharmacy_total ,count(prescriptionID)as prescription_total
    FROM pharmacy p join prescription pr on p.pharmacyID=pr.pharmacyID 	join address a on p.addressID=a.addressID
    group by city )
    select *,pharmacy_total/prescription_total as ratio from cte where prescription_total>100 order by ratio limit 3;


-- Problem Statement 2: The State of Alabama (AL) is trying to manage its healthcare resources more efficiently. For each city in their state, 
-- they need to identify the disease for which the maximum number of patients have gone for treatment. Assist the state for this purpose.
-- Note: The state of Alabama is represented as AL in Address Table.
with cte as (
	select state,city,t.diseaseID,diseaseName,count(distinct  p.patientID ) as total_patient,count( distinct t.treatmentID) as total_treatment 
	from address a left join person pe on a.addressID=pe.addressID
	join patient p on p.patientID=pe.personID 
	join treatment t on p.patientID=t.patientID
	join disease d on t.diseaseID=d.diseaseID
    group by state,city,diseaseID having state="AL" )   ,
cte2 as (select state,city ,diseaseID,diseaseName,total_patient,total_treatment ,rank() over (partition by city order by total_treatment desc , total_patient desc)as ranking from cte)
select city,count(diseaseId) as total_disease,sum(total_treatment) from cte2  where ranking=1 group by city 
order by sum(total_treatment) desc;



-- Problem Statement 3: The healthcare department needs a report about insurance plans. The report is required to include the insurance plan,
-- which was claimed the most and least for each disease.  Assist to create such a report.

with cte as (
	select i.planName, d.diseaseID, d.diseaseName, count(c.claimID)as  total_claim ,dense_rank() over(partition by d.diseaseID order by count(c.claimID) desc) as ranking1,dense_rank() over(partition by d.diseaseID order by count(c.claimID) ) as ranking2
	from  insuranceplan i join claim c on i.uin=c.uin join treatment t on t.claimID=c.claimID join disease d on d.diseaseID=t.diseaseID
	group by i.planName,d.diseaseID )
select planName,diseaseId, diseaseName,total_claim  from cte where ranking1=1 or ranking2=1; 





-- Problem Statement 4:The Healthcare department wants to know which disease is most likely to infect multiple people in the same household.
--  For each disease find the number of households that has more than one patient with the same disease. 
-- Note: 2 people are considered to be in the same household if they have the same address. 
with cte as (
	select d.diseasename, t.diseaseid, ad.addressid, count(pe.personid) 
	from address ad  join person pe on pe.addressid = ad.addressid 
	join treatment t on t.patientid = pe.personid
	join disease d on t.diseaseid = d.diseaseid 
	group by t.diseaseid, ad.addressid having(count(pe.personid))>1) 
select diseaseid, diseasename, count(addressid) total_household_with_same_disease from cte 
group by diseaseid order by diseaseId ;


-- Problem Statement 5:  An Insurance company wants a state wise report of the treatments to claim ratio 
-- between 1st April 2021 and 31st March 2022 (days both included). Assist them to create such a report.

select ad.state, count(tr.treatmentid)/count(tr.claimid) as ratio 
from address ad join person pe on ad.addressid = pe.addressid
join treatment tr on tr.patientid = pe.personid where tr.date >= "2021-04-01" and date <="2022-03-31" group by ad.state;

-- ============================ Problem Statement 3 ==============================================================================================
-- Problem Statement 1:  Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine that 
-- they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, wants to get a report of which pharmacies
-- have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. Assist Joshua to generate the report so that the pharmacies 
-- who prescribe hospital-exclusive medicine more often are advised to avoid such practice if possible.   

select pr.pharmacyid, count(c.medicineid) as total_medicine from prescription pr join contain c on  pr.prescriptionid = c.prescriptionid
 join medicine m on c.medicineid = m.medicineid  join treatment t on t.treatmentid = pr.treatmentid
where m.hospitalexclusive= "s" and year(t.date) in(2021, 2022) group by pr.pharmacyid order by total_medicine desc;


-- Problem Statement 2: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each 
-- insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.

select companyName, planName, count(tr.claimID) as Total_claim from insuranceplan ip 
join insurancecompany ic on ip.companyid = ic.companyid
join claim cl on ip.uin = cl.uin
join treatment tr on cl.claimid = tr.claimid group by companyname, planname order by Total_claim desc;

-- Problem Statement 3: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows 
-- each insurance company's name with their most and least claimed insurance plans.


with cte as (
	select ic.companyname, ip.planname, count(tr.treatmentid) total_treatment, 
	dense_rank() over(partition by ic.companyname order by count(tr.treatmentid)) "denserank"
	from insuranceplan ip join insurancecompany ic on ip.companyid = ic.companyid
	join claim cl on ip.uin = cl.uin
	join treatment tr on cl.claimid = tr.claimid 
    group by companyname, planname )
select companyname, (select planname from cte a where total_treatment = (select max(total_treatment) from cte b
where companyname = a.companyname) and companyname = b.companyname limit 1) "max claimed",
(select planname from cte a where total_treatment = (select min(total_treatment) from cte 
where companyname = a.companyname) and companyname = b.companyname limit 1) "least claimed" 
from cte b group by companyname; 

-- Problem Statement 4:  The healthcare department wants a state-wise health report to assess which state requires more attention in 
-- the healthcare sector. Generate a report for them that shows the state name, number of registered people in the state, number of 
-- registered patients in the state, and the people-to-patient ratio. sort the data by people-to-patient ratio. 

select ad.state,ad.state, count(pe.personid) as total_person , count(pa.patientid) as total_patient, count(pe.personID)/count(pa.patientID) as ratio_person_to_patient
from address ad join person pe on ad.addressid = pe.addressid
left join patient pa on pe.personid=pa.patientid  group by ad.state order by ratio_person_to_patient desc;

-- Problem Statement 5:  Jhonny, from the finance department of Arizona(AZ), has requested a report that lists the total quantity of medicine 
-- each pharmacy in his state has prescribed that falls under Tax criteria I for treatments that took place in 2021. 
-- Assist Jhonny in generating the report. 

select ph.pharmacyName, sum(co.quantity) as total_medicine
from address ad join pharmacy ph on ad.addressid = ph.addressid
join prescription pr on pr.pharmacyid = ph.pharmacyid
join contain co on pr.prescriptionid = co.prescriptionid
join treatment tr on tr.treatmentid = pr.treatmentid
join medicine me on me.medicineid = co.medicineid
where year(tr.date) = "2021" and me.taxcriteria = "I" and ad.state = "AZ" group by ph.pharmacyname order by pharmacyName;


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
-- Write a query that finds the sum of the quantity of all the medicines in a prescription and if the total quantity of medicine is less than 20 tag it as “low quantity”. If the quantity of medicine is from 20 to 49 (both numbers including) tag it as “medium quantity“ and if the quantity is more than equal to 50 then tag it as “high quantity”.
-- Show the prescription Id, the Total Quantity of all the medicines in that prescription, and the Quantity tag for all the prescriptions issued by 'Ally Scripts'.

select pr.prescriptionid, sum(co.quantity) total_quantity, 
(case when sum(co.quantity) < 20 then "low quantity"
when count(co.quantity) <= 49 then "medium quantity"                                                   
when count(co.quantity) >= 50 then "high quantity"
end) quantity_tag
from prescription pr join contain co on co.prescriptionid = pr.prescriptionid
join pharmacy ph on ph.pharmacyid = pr.pharmacyid where ph.pharmacyname = "ally scripts" group by pr.prescriptionid;


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
order by quantity_tag;

-- Problem Statement 4: 
-- Mack, From HealthDirect Pharmacy, wants to get a list of all the affordable and costly, hospital-exclusive medicines in the database.
-- Where affordable medicines are the medicines that have a maximum price of less than 50% of the avg maximum price of all the medicines 
-- in the database, and costly medicines are the medicines that have a maximum price of more than double the avg maximum price of all the medicines
-- in the database.  Mack wants clear text next to each medicine name to be displayed that identifies the medicine as affordable or costly.
-- The medicines that do not fall under either of the two categories need not be displayed.
-- Write a SQL query for Mack for this requirement.

select * from (select medicineID,productName, maxPrice,
(case
	when maxPrice>2* (select avg(maxPrice) from medicine) then "costly"
    when maxPrice< 0.5*(select avg(maxPrice) from medicine) then "Affordable"
end ) as "medicine_tag"
 from medicine where hospitalExclusive='S') sub where medicine_tag="costly" or medicine_tag="Affordable" order by medicineID;


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


-- ============================ Problem Statement 5 ==============================================================================================

-- ============================ Problem Statement 6 ==============================================================================================

-- ============================ Problem Statement 7 ==============================================================================================

-- ============================ Problem Statement 8 ==============================================================================================

-- ============================ Problem Statement 9 ==============================================================================================

-- ============================ Problem Statement 10 ==============================================================================================

-- ============================ Problem Statement 11 ==============================================================================================
