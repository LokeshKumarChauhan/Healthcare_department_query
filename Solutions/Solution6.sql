-- ============================ Problem Statement 6 ==============================================================================================

-- Problem Statement 1:The healthcare department wants a pharmacy report on the percentage of hospital-exclusive medicine prescribed 
-- in the year 2022. Assist the healthcare department to view for each pharmacy, the pharmacy id, pharmacy name, total quantity of medicine
-- prescribed in 2022, total quantity of hospital-exclusive medicine prescribed by the pharmacy in 2022, and the percentage of 
-- hospital-exclusive medicine to the total medicine prescribed in 2022. Order the result in descending order of the percentage found. 

select ph.pharmacyID,ph.pharmacyName,
	SUM(CASE WHEN hospitalExclusive= 'S' THEN quantity ELSE 0 END) AS total_Hospital_exclusice,
       SUM(CASE WHEN hospitalExclusive='N' THEN quantity ELSE quantity END) AS total_medicine,
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
		  when ranking2=1 then "min_treatment" end)as status from cte where ranking1=1 or ranking2=1 order by state,status;

-- Problem Statement 4: 
-- Manish, from the healthcare department, wants to know how many registered people are registered as patients as well, in each city.
-- Generate a report that shows each city that has 10 or more registered people belonging to it and the number of patients from that city
--  as well as the percentage of the patient with respect to the registered people.

select ad.city,count(pe.personID)as total_person, count(pa.patientid) patient_count, (count(pa.patientid)/count(pe.personID))*100 percentage 
from address ad inner join person pe on pe.addressid = ad.addressid
left join patient pa on pa.patientid = pe.personid group by city having count(pa.patientid) >=10;

-- Problem Statement 5:  
-- It is suspected by healthcare research department that the substance “ranitidine” might be causing some side effects. 
-- Find the top 3 companies using the substance in their medicine so that they can be informed about it.

select companyname, count(medicineid) as total_medicine from medicine 
where substancename like "%ranitidin%" group by companyname order by 2 desc limit 3;

