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

select ad.state, count(tr.treatmentid) as total_treatment, count(tr.claimid) as total_claim ,count(tr.treatmentid)/count(tr.claimid) as ratio 
from address ad join person pe on ad.addressid = pe.addressid
join treatment tr on tr.patientid = pe.personid where tr.date >= "2021-04-01" and date <="2022-03-31" group by ad.state;

