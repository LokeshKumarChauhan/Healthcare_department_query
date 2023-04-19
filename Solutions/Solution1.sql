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

SELECT d.diseaseName,
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

