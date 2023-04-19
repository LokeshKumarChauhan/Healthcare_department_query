-- ============================ Problem Statement 8 ==============================================================================================

-- The healthcare department attempting to use the resources more efficiently. It already has some queries that are being used for different purposes. The management suspects that these queries might not be efficient so they have requested to optimize the existing queries wherever necessary.
-- Given are some queries written in SQL server which may be optimized if necessary.

-- Query 1: 
-- For each age(in years), how many patients have gone for treatment?
SELECT year(curdate())-year(dob)as age, count(distinct tr.treatmentID) AS num_Treatments
FROM person pe 
JOIN Patient pa ON pa.patientID = pe.personID
JOIN Treatment tr ON tr.patientID = pa.patientID
group by year(curdate())-year(dob)
order by num_Treatments desc;


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
WHERE diseaseName like "%p%" or "%P%"
GROUP BY diseaseName;

