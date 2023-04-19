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
select planName,diseaseId, diseaseName,total_claim  from cte where ranking1=1 or ranking2=1
order by diseaseID, total_claim desc; 





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
-- Problem Statement 1: 
-- Johansson is trying to prepare a report on patients who have gone through treatments more than once. Help Johansson prepare a report
-- that shows the patient's name, the number of treatments they have undergone, and their age, Sort the data in a way that the patients
--  who have undergone more treatments appear on top.
select pe.personID, pe.personName, count(tr.treatmentID) as total_treatment
from person pe join patient pa on pe.personID=pa.patientID join treatment tr on tr.patientID=pa.patientID
group by pe.personID having count(tr.treatmentID)>1
order by total_treatment desc  ; 

-- Problem Statement 2:Bharat is researching the impact of gender on different diseases, He wants to analyze if a certain disease is more 
-- likely to infect a certain gender or not. Help Bharat analyze this by creating a report showing for every disease how many 
-- males and females underwent treatment for each in the year 2021. It would also be helpful for Bharat if the male-to-female ratio is also shown.

SELECT t.diseaseID, d.diseaseName,
       SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END) AS female_count,
       (SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) / 
        SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END)) AS male_to_female_ratio
FROM treatment t join patient p on t.patientID=p.patientID join person pe on pe.personID=p.patientID join disease d on t.diseaseID=d.diseaseID
where year(t.date)=2021 GROUP BY t.diseaseID ORDER BY male_to_female_ratio DESC;


-- Problem Statement 3:  
-- Kelly, from the Fortis Hospital management, has requested a report that shows for each disease, the top 3 cities that had 
-- the most number treatment for that disease. Generate a report for Kelly’s requirement.
with cte as(
select t.diseaseID,diseaseName,city, count(treatmentID) as total_treatment, 
dense_rank() over (partition by t.diseaseID order by count(treatmentID) desc)as ranking 
from  treatment t join patient p on t.patientID=p.patientID 
			join person pe on pe.personID=p.patientID 
            join disease d on t.diseaseID=d.diseaseID
            join address ad on pe.addressID=ad.addressID
group by t.diseaseID,city order by count(treatmentID) desc)
select diseaseName,city,total_treatment from cte where ranking<=3;

-- Problem Statement 4: 
-- Brooke is trying to figure out if patients with a particular disease are preferring some pharmacies over others or not,
-- For this purpose, she has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions
-- they have prescribed for each disease in 2021 and 2022, She expects the number of prescriptions prescribed in 2021 and 2022 be displayed
-- in two separate columns.
-- Write a query for Brooke’s requirement.

select tr.diseaseID,di.diseaseName,pharmacyID,count(pe.personID) from disease di 
	join treatment tr on di.diseaseID=tr.diseaseID 
    join patient pa on tr.patientID=pa.patientID 
    join person pe on pe.personID=pa.patientID
    join prescription pr on pr.treatmentID=tr.treatmentID
    where year(tr.date) in (2021,2022)
    group by tr.diseaseID,pharmacyID order by 1,2 ,3 desc;



-- Problem Statement 5:  
-- Walde, from Rock tower insurance, has sent a requirement for a report that presents which insurance company is targeting the patients 
-- of which state the most. Write a query for Walde that fulfills the requirement of Walde.
-- Note: We can assume that insurance company is targeting region more if the patients of that region are claiming more insurance of that company.

select ic.companyname, ad.state, count(tr.claimid) from address ad  
join insurancecompany ic on ad.addressid = ic.addressid
join insuranceplan ip on ic.companyid = ip.companyid
join claim cl on ip.uin = cl.uin
join treatment tr on tr.claimid = cl.claimid 
group by ic.companyname, ad.state;

-- ============================ Problem Statement 6 ==============================================================================================
-- Problem Statement 1:The healthcare department wants a pharmacy report on the percentage of hospital-exclusive medicine prescribed 
-- in the year 2022. Assist the healthcare department to view for each pharmacy, the pharmacy id, pharmacy name, total quantity of medicine
-- prescribed in 2022, total quantity of hospital-exclusive medicine prescribed by the pharmacy in 2022, and the percentage of 
-- hospital-exclusive medicine to the total medicine prescribed in 2022. Order the result in descending order of the percentage found. 

select ph.pharmacyID,ph.pharmacyName,
	SUM(CASE WHEN hospitalExclusive= 'S' THEN quantity ELSE 0 END) AS total_Hospital_exclusice,
       SUM(CASE WHEN hospitalExclusive='N' THEN quantity ELSE quantity END) AS total,
       (SUM(CASE WHEN hospitalExclusive= 'S' THEN quantity ELSE 0 END)/
       SUM(CASE WHEN hospitalExclusive='N' THEN quantity ELSE quantity END)*100) as percentage
	from pharmacy ph 
	join prescription pr on ph.pharmacyID=pr.pharmacyID
    join contain ct on ct.prescriptionID=pr.prescriptionID
    join medicine me on me.medicineID=ct.medicineID
    join treatment tr on tr.treatmentID=pr.treatmentID
where year(tr.date) in (2022)
group by ph.pharmacyID order by percentage desc;

-- Problem Statement 2:  
-- Sarah, from the healthcare department, has noticed many people do not claim insurance for their treatment. She has requested a state-wise
-- report of the percentage of treatments that took place without claiming insurance. Assist Sarah by creating a report as per her requirement.

select ad.state, count(tr.treatmentid) treatment_count, count(tr.claimid) claim_count,  
100 - (count(tr.claimid)/count(tr.treatmentid))*100 percentage_not_claim
from address ad 
join person pe on ad.addressid = pe.addressid
join patient pa on pe.personID=pa.patientID
join treatment tr on tr.patientid = pa.patientID
group by ad.state;

-- Problem Statement 3:  
-- Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. 
-- Assist Sarah by creating a report which shows for each state, the number of the most and least treated diseases by the patients of that state
--  in the year 2022. 
	with cte as(
	select state,diseaseName, total_treatment,dense_rank() over(partition by state order by total_treatment desc ) as ranking1, dense_rank() over(partition by state order by total_treatment ) as ranking2 from
    (select state,diseaseName, count( tr.treatmentID) as total_treatment
	from address ad 
	join person pe on ad.addressID=pe.addressID
    join patient pa on pa.patientID=pe.personID
    join treatment tr on tr.patientID=pa.patientID
    join disease di on tr.diseaseID=di.diseaseID
    where year(tr.date)=2022
    group by state,tr.diseaseID) sub )
    select state, diseaseName , 
    (case when ranking1=1 then "max_treatment" 
		  when ranking2=1 then "min_treatment" end)as status from cte where ranking1=1 or ranking2=1 order by state,diseaseName;
-- Problem Statement 4: 
-- Manish, from the healthcare department, wants to know how many registered people are registered as patients as well, in each city.
-- Generate a report that shows each city that has 10 or more registered people belonging to it and the number of patients from that city
--  as well as the percentage of the patient with respect to the registered people.

select ad.city, count(pa.patientid) patient_count, count(pa.patientid)/(select count(*) from patient)*100 percentage 
from address ad inner join person pe on pe.addressid = ad.addressid
left join patient pa on pa.patientid = pe.personid group by city having count(pa.patientid) >=10;

-- Problem Statement 5:  
-- It is suspected by healthcare research department that the substance “ranitidine” might be causing some side effects. 
-- Find the top 3 companies using the substance in their medicine so that they can be informed about it.

select companyname, count(medicineid) as total_medicine from medicine 
where substancename like "%ranitidina%" group by companyname order by 2 desc limit 3;

-- ============================ Problem Statement 7 ==============================================================================================
-- Problem Statement 1:Insurance companies want to know if a disease is claimed higher or lower than average.  
-- Write a stored procedure that returns “claimed higher than average” or “claimed lower than average” when the diseaseID is passed to it. 
-- Hint: Find average number of insurance claims for all the diseases.  If the number of claims for the passed disease is higher than 
-- the average return “claimed higher than average” otherwise “claimed lower than average”.

delimiter $$
drop procedure if exists disease_claim;
create procedure disease_claim (disid int)
begin
declare v1 int;
declare v2 int;
select avg(total_claim) average into v1 from
( select di.diseasename, count(tr.claimid) total_claim from treatment tr  
join disease di on di.diseaseid = tr.diseaseid group by di.diseasename ) a;
select count(claimid) into v2 from treatment where diseaseid = disid;
if v2 > v1 then 	select "claimed higher than average";
else select "claimed lower than average";
end if;
end $$
delimiter ;
call disease_claim(40);
call disease_claim(30);


-- Problem Statement 2:  
-- Joseph from Healthcare department has requested for an application which helps him get genderwise report for any disease. 
-- Write a stored procedure when passed a disease_id returns 4 columns, disease_name, number_of_male_treated, number_of_female_treated, 
-- more_treated_genderWhere, more_treated_gender is either ‘male’ or ‘female’ based on which gender underwent more often for the disease, 
-- if the number is same for both the genders, the value should be ‘same’.

delimiter $$
drop procedure if exists disease_report;
create procedure disease_report(disid int)
begin
with cte as (SELECT t.diseaseID, d.diseaseName,
       SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END) AS female_count,
       (SUM(CASE WHEN pe.gender = 'male' THEN 1 ELSE 0 END) -
		SUM(CASE WHEN pe.gender = 'female' THEN 1 ELSE 0 END)) AS difference_treatment_count
FROM treatment t join patient p on t.patientID=p.patientID join person pe on pe.personID=p.patientID join disease d on t.diseaseID=d.diseaseID
where t.diseaseId=disid
GROUP BY t.diseaseID ORDER BY difference_treatment_count DESC) 
select diseaseId,diseaseName,male_count,female_count, 
(case when male_count>female_count then "Male"
	  when male_count<female_count then "Female"
      when male_count=female_count then "Same" 
end) as Max_claimed from cte;

end $$
Delimiter ;
call disease_report(35);
call disease_report(40);


-- Problem Statement 3:  
-- The insurance companies want a report on the claims of different insurance plans. 
-- Write a query that finds the top 3 most and top 3 least claimed insurance plans.
-- The query is expected to return the insurance plan name,  insurance company name which has that plan and whether the plan is the 
-- most claimed or least claimed. 
with top3 as
(
select ic.companyname, ip.planname, count(tr.claimid) total_claim from insurancecompany ic 
join insuranceplan ip on ic.companyid = ip.companyid
join claim cl on ip.uin = cl.uin
join treatment tr on tr.claimid = cl.claimid
group by ic.companyname, ip.planname
)
(select companyname, planname, "mostclaimed", total_claim from top3 order by total_claim desc limit 3)
union
(select companyname, planname, "leastclaimed", total_claim from top3 order by total_claim asc limit 3);




-- Problem Statement 4: 
-- The healthcare department wants to know which category of patients is being affected the most by each disease.Assist the department 
-- in creating a report regarding this.Provided the healthcare department has categorized the patients into the following category.
-- YoungMale: Born on or after 1st Jan  2005  and gender male.
-- YoungFemale: Born on or after 1st Jan  2005  and gender female.
-- AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
-- AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
-- MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
-- MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
-- ElderMale: Born before 1st Jan 1970, and gender male.
-- ElderFemale: Born before 1st Jan 1970, and gender female.
with cte as (select * ,dense_rank() over(partition by diseaseName order by total_patient desc ) ranking from  (
select di.diseasename, (case when pa.dob < "1970-01-01" and pe.gender = "male" then "eldermale"
							  when pa.dob < "1970-01-01" and pe.gender = "female" then "elderfemale"
							  when pa.dob < "1985-01-01" and pe.gender = "male" then "midagemale"
							  when pa.dob < "1985-01-01" and pe.gender = "female" then "midagefemale"
							  when pa.dob < "2005-01-01" and pe.gender = "male" then "adultmale"
							  when pa.dob < "2005-01-01" and pe.gender = "female" then "adultfemale"
							  when pa.dob >= "2005-01-01" and pe.gender = "male" then "youngmale"
							  when pa.dob >= "2005-01-01" and pe.gender = "female" then "youngfemale" 
							  end) category, count(tr.patientid) total_patient
                              from patient pa 
join person pe on pe.personid = pa.patientid
join treatment tr on tr.patientid = pa.patientid
join disease di on di.diseaseid = tr.diseaseid 
group by diseaseName,category )sub )
select diseaseName, category as max_claimed_category,total_patient from cte where ranking=1 ;


-- Problem Statement 5:  
-- Anna wants a report on the pricing of the medicine. She wants a list of the most expensive and most affordable medicines only. 
-- Assist anna by creating a report of all the medicines which are pricey and affordable, listing the companyName, productName, description,
-- maxPrice, and the price category of each. Sort the list in descending order of the maxPrice.
-- Note: A medicine is considered to be “pricey” if the max price exceeds 1000 and “affordable” if the price is under 5. Write a query to find
 
select * from 
(select companyname, productname, maxprice, 
(case when maxprice>1000 then "pricey"
	  when maxprice<5 then "affordable"
end) price_category from medicine order by maxprice desc) a where price_category is not null;


-- ============================ Problem Statement 8 ==============================================================================================
-- The healthcare department attempting to use the resources more efficiently. It already has some queries that are being used for different purposes. The management suspects that these queries might not be efficient so they have requested to optimize the existing queries wherever necessary.
-- Given are some queries written in SQL server which may be optimized if necessary.

-- Query 1: 
-- For each age(in years), how many patients have gone for treatment?
SELECT year(curdate())-year(dob)as age, count(distinct treatmentID) AS num_Treatments
FROM person pe 
JOIN Patient pa ON pa.patientID = pe.personID
JOIN Treatment tr ON tr.patientID = pa.patientID
group by year(curdate())-year(dob)
order by numTreatments desc;


-- Query 2: 
-- For each city, Find the number of registered people, number of pharmacies, and number of insurance companies.


select ad.city,count(distinct pe.personID) as registered_patient ,
count(distinct  ph.pharmacyID) as total_Pharmacy, 
count(distinct ic.companyID) as Total_insurance_companies
from Address ad 
left join Pharmacy ph on ph.addressID = ad.addressID 
left join person pe on ad.addressId=pe.addressId
left join insurancecompany ic on ad.addressID=ic.addressID
group by city
order by count(ph.pharmacyID) desc;

-- Query 3: 
-- Total quantity of medicine for each prescription prescribed by Ally Scripts
-- If the total quantity of medicine is less than 20 tag it as "Low Quantity".
-- If the total quantity of medicine is from 20 to 49 (both numbers including) tag it as "Medium Quantity".
-- If the quantity is more than equal to 50 then tag it as "High quantity".

select 
pr.prescriptionID, sum(quantity) as totalQuantity,
CASE WHEN sum(quantity) < 20 THEN 'Low Quantity' 
	WHEN sum(quantity) < 50 THEN 'Medium Quantity'
	ELSE 'High Quantity' END AS Tag
FROM Contain c JOIN Prescription pr on pr.prescriptionID = c.prescriptionID
JOIN Pharmacy ph on ph.pharmacyID = pr.pharmacyID 
where ph.pharmacyName = 'Ally Scripts'
group by c.prescriptionID;

-- Query 4: 
-- The total quantity of medicine in a prescription is the sum of the quantity of all the medicines in the prescription.
-- Select the prescriptions for which the total quantity of medicine exceeds
-- the avg of the total quantity of medicines for all the prescriptions.

with cte as  
(select ph.pharmacyID, pr.prescriptionID, sum(quantity) as totalQuantity
from Pharmacy ph
join Prescription pr on ph.pharmacyID = pr.pharmacyID
join Contain c on c.prescriptionID = pr.prescriptionID
join Medicine m on m.medicineID = c.medicineID
join Treatment tr on tr.treatmentID = pr.treatmentID
group by ph.pharmacyID, pr.prescriptionID
order by ph.pharmacyID, pr.prescriptionID) 
select * from cte
where totalQuantity > (select avg(totalQuantity) from cte);


-- Query 5: 
-- Select every disease that has 'p' in its name, and 
-- the number of times an insurance claim was made for each of them. 

SELECT d.diseaseName, COUNT(*) as num_Claims
FROM Disease d
JOIN Treatment t ON d.diseaseID = t.diseaseID
JOIN Claim c On t.claimID = c.claimID
WHERE diseaseName like "%p%"
GROUP BY diseaseName;

-- ============================ Problem Statement 9 ==============================================================================================

-- Problem Statement 1: 
-- Brian, the healthcare department, has requested for a report that shows for each state how many people underwent treatment for 
-- the disease “Autism”.  He expects the report to show the data for each state as well as each gender and for each state and gender combination. 
-- Prepare a report for Brian for his requirement.

select state,diseaseName,gender,count(tr.treatmentID) as total_treatment from disease d
left join treatment tr on tr.diseaseID=d.diseaseID
left join patient pa on pa.patientID=tr.patientID
left join person pe on pe.personID=pa.patientID
left join address ad on ad.addressID=pe.addressID
where diseaseName="Autism"
group by state,diseaseName,gender
order by state,diseaseName;

-- Problem Statement 2:  
-- Insurance companies want to evaluate the performance of different insurance plans they offer. 
-- Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.
-- The report would be more relevant if the data compares the performance for different years(2020, 2021 and 2022) and if the report also 
-- includes the total number of claims in the different years, as well as the total number of claims for each plan in all 3 years combined.

select companyName,planName ,year(tr.date) as year_treatment,count( c.claimId) 
from insurancecompany ic 
join insuranceplan ip on ic.companyID=ip.companyID 
join claim c on c.uin=ip.uin
join treatment tr on tr.claimID=c.claimID
group by companyName,planName,year(tr.date)
order by companyName,planName,year_treatment;


-- Problem Statement 3:  
-- Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. Assist Sarah by
-- creating a report which shows each state the number of the most and least treated diseases by the patients of that state in the year 2022.
-- It would be helpful for Sarah if the aggregation for the different combinations is found as well. Assist Sarah to create this report. 

with cte as(
select state,t.diseaseID,diseaseName, count(treatmentID) as total_treatment, 
dense_rank() over (partition by state,t.diseaseID order by count(treatmentID) desc)as ranking 
from  treatment t join patient p on t.patientID=p.patientID 
			join person pe on pe.personID=p.patientID 
            join disease d on t.diseaseID=d.diseaseID
            join address ad on pe.addressID=ad.addressID
group by state,t.diseaseID order by count(treatmentID) desc)
select state,diseaseName,total_treatment from cte where ranking=1 ;

-- Problem Statement 4: 
-- Jackson has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for 
-- each disease in the year 2022, along with this Jackson also needs to view how many prescriptions were prescribed by each pharmacy,
-- and the total number prescriptions were prescribed for each disease.
-- Assist Jackson to create this report. 

with cte as
( 
select ph.pharmacyname, di.diseasename, count(pr.prescriptionid) "count1" from pharmacy ph inner join prescription pr on ph.pharmacyid = pr.pharmacyid 
inner join treatment tr on tr.treatmentid = pr.treatmentid
inner join disease di on di.diseaseid = tr.diseaseid
where year(tr.date) = "2022" group by ph.pharmacyname, di.diseasename
)
select pharmacyname, diseasename, sum(count1) total_prescriptions from cte group by pharmacyname, diseasename order by 1;

-- Problem Statement 5:  
-- Praveen has requested for a report that finds for every disease how many males and females underwent treatment for each in the year 2022.
-- It would be helpful for Praveen if the aggregation for the different combinations is found as well.
-- Assist Praveen to create this report. 

select di.diseasename disease_name , pe.gender, count(pe.personid) total_person 
from person pe join treatment tr on tr.patientid = pe.personid
join disease di on di.diseaseid = tr.diseaseid where year(tr.date) = "2022" 
group by di.diseasename, pe.gender with rollup;

-- ============================ Problem Statement 10 ==============================================================================================
-- Problem Statement 1:
-- The healthcare department has requested a system to analyze the performance of insurance companies and their plan.
-- For this purpose, create a stored procedure that returns the performance of different insurance plans of an insurance company. 
-- When passed the insurance company ID the procedure should generate and return all the insurance plan names the provided company issues,
-- the number of treatments the plan was claimed for, and the name of the disease the plan was claimed for the most.
-- The plans which are claimed more are expected to appear above the plans that are claimed less.
Delimiter //
drop procedure if exists company_plans;
create procedure company_plans (id int)
begin
select ic.companyName,ip.planName,diseaseName,count(distinct tr.treatmentID) as total_treatment
from insurancecompany ic 
join insuranceplan ip on ic.companyID=ip.companyID
join claim c on c.uin=ip.uin 
join treatment tr on tr.claimID=c.claimID
join disease d on d.diseaseID=tr.diseaseID
where ic.companyId=id
group by companyName,planName,diseaseName
order by companyName, planName, total_treatment desc;
end //
Delimiter ;
call company_plans(112.18);

-- Problem Statement 2:
-- It was reported by some unverified sources that some pharmacies are more popular for certain diseases.
-- The healthcare department wants to check the validity of this report.
-- Create a stored procedure that takes a disease name as a parameter and would return the top 3 pharmacies the patients are preferring
--  for the treatment of that disease in 2021 as well as for 2022.
-- Check if there are common pharmacies in the top 3 list for a disease, in the years 2021 and the year 2022.
-- Call the stored procedure by passing the values “Asthma” and “Psoriasis” as disease names and draw a conclusion from the result
Delimiter //
drop procedure if exists pharma_medicine;
create procedure pharma_medicine (dis varchar(55))
begin
with cte as (select diseaseName, pharmacyName, year(tr.date) as year_treatment, count(pr.prescriptionId) as total_count, 
row_number() over (partition by diseaseName,year(tr.date) order by count(pr.prescriptionId) desc ) as rowCounting
from disease d 
join treatment tr on d.diseaseID=tr.diseaseID
join prescription pr on tr.treatmentID=pr.treatmentID
join pharmacy ph on ph.pharmacyID=pr.pharmacyID
where diseaseName=dis and  year(tr.date) in (2021,2022)
group by diseaseName, pharmacyName,year(tr.date) )
select diseaseName, pharmacyName, year_treatment,total_count from cte
where rowCounting<=3
order by diseaseName, year_treatment,total_count desc;
end //
Delimiter ;
call pharma_medicine("Alzheimer's disease");
call pharma_medicine("Amyotrophic lateral sclerosis");
call pharma_medicine("Asthma");

-- Problem Statement 3:
-- Jacob, as a business strategist, wants to figure out if a state is appropriate for setting up an insurance company or not.
-- Write a stored procedure that finds the num_patients, num_insurance_companies, and insurance_patient_ratio,
-- the stored procedure should also find the avg_insurance_patient_ratio and if the insurance_patient_ratio of the
-- given state is less than the avg_insurance_patient_ratio then it Recommendation section can have the value “Recommended”
-- otherwise the value can be “Not Recommended”.
-- Description of the terms used:
-- num_patients: number of registered patients in the given state
-- num_insurance_companies:  The number of registered insurance companies in the given state
-- insurance_patient_ratio: The ratio of registered patients and the number of insurance companies in the given state
-- avg_insurance_patient_ratio: The average of the ratio of registered patients and the number of insurance for all the states.

Delimiter //
drop procedure if exists company_recommendation;
create procedure company_recommendation(st varchar(40))
begin
with cte as(
select ad.state, count(pa.patientid) num_patients,count(ic.companyid) num_insurance_companies, 
count(ic.companyid)/count(pa.patientid) insurance_patient_ratio 
from address ad 
left join person pe on pe.addressid = ad.addressid
left join insurancecompany ic on ic.addressid = ad.addressid
left join patient pa on  pa.patientid = pe.personid group by ad.state )
select state,num_patients, num_insurance_companies,insurance_patient_ratio, 
(case when insurance_patient_ratio >=  (select avg(insurance_patient_ratio) from cte) then "Recommended" else "Not Recommended" end ) as Recommendation
 from cte where state=st  order by insurance_patient_ratio desc ;
 end //
 Delimiter ;

call company_recommendation('MA');
call company_recommendation('MD');
call company_recommendation('OK');

-- Problem Statement 4:
-- Currently, the data from every state is not in the database, The management has decided to add the data from other states and cities as well.
-- It is felt by the management that it would be helpful if the date and time were to be stored whenever new city or state data is inserted.
-- The management has sent a requirement to create a PlacesAdded table if it doesn’t already exist, that has four attributes.
-- placeID, placeName, placeType, and timeAdded.
-- Description
-- placeID: This is the primary key, it should be auto-incremented starting from 1
-- placeName: This is the name of the place which is added for the first time
-- placeType: This is the type of place that is added for the first time. The value can either be ‘city’ or ‘state’
-- timeAdded: This is the date and time when the new place is added
-- You have been given the responsibility to create a system that satisfies the requirements of the management.
-- Whenever some data is inserted in the Address table that has a new city or state name,the PlacesAdded table should be updated with relevant data.
 create table placesadded(placeid int primary key auto_increment,
						 placename varchar(50),
                         placetype varchar(5) check(placetype in ("city", "state")),
                         timeadded datetime);
            
delimiter //
drop trigger if exists insert_place_data;            
create trigger insert_place_data
before insert on address
for each row
begin
if new.state not in (select distinct(state) from address) then 
	insert into placesadded(placename, placetype, timeadded) values(new.state, "state", now());
end if;
if new.city not in (select distinct(city) from address) then 
	insert into placesadded(placename, placetype, timeadded) values(new.city, "city", now());
end if;	
end //
delimiter ;
select * from placesadded;
insert into address(addressid, address1, city, state, zip) values(12345, "Meerut","Meerut", "UP", 250001);


-- Problem Statement 5:
-- Some pharmacies suspect there is some discrepancy in their inventory management. The quantity in the ‘Keep’ is updated regularly
-- and there is no record of it. They have requested to create a system that keeps track of all the transactions whenever the quantity
-- of the inventory is updated.
-- You have been given the responsibility to create a system that automatically updates a Keep_Log table which has  the following fields:
-- id: It is a unique field that starts with 1 and increments by 1 for each new entry
-- medicineID: It is the medicineID of the medicine for which the quantity is updated.
-- quantity: The quantity of medicine which is to be added. If the quantity is reduced then the number can be negative.
-- For example:  If in Keep the old quantity was 700 and the new quantity to be updated is 1000, then in Keep_Log the quantity should be 300.
-- Example 2: If in Keep the old quantity was 700 and the new quantity to be updated is 100, then in Keep_Log the quantity should be -600.
create table keep_log(id int unique auto_increment,
					  medicineid int,
                      quantity int);
delimiter //
drop trigger if exists inventory;
create trigger inventory
before update 
on keep for each row
begin
insert into keep_log(medicineid, quantity) values (old.medicineid, new.quantity - old.quantity);
end //
delimiter ;
select * from keep_log;

update keep set quantity =1735 where medicineId=17648 ;

SET SQL_SAFE_UPDATES = 0;


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

select avg(avg_price) as total_average_price from (select ph.pharmacyID ,pr.prescriptionID ,avg(maxPrice*quantity) as avg_price
from pharmacy ph join prescription pr on ph.pharmacyID=pr.pharmacyID 
 join contain c on c.prescriptionID=pr.prescriptionID
 join medicine m on c.medicineID=m.medicineID
 join treatment tr on tr.treatmentID=pr.treatmentID 
where ph.pharmacyID=id and year(tr.date) in (year_input)
group by ph.pharmacyID,pr.prescriptionID) sub;

drop function if exists average_prescreption_bill;
delimiter $$
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

