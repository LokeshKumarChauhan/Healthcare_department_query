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
where year(tr.date) in (2020,2021,2022)
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
select pharmacyname, diseasename, sum(count1) total_prescriptions from cte group by pharmacyname, diseasename order by 1,3 desc;

-- Problem Statement 5:  
-- Praveen has requested for a report that finds for every disease how many males and females underwent treatment for each in the year 2022.
-- It would be helpful for Praveen if the aggregation for the different combinations is found as well.
-- Assist Praveen to create this report. 

select di.diseasename disease_name , pe.gender, count(pe.personid) total_person 
from person pe join treatment tr on tr.patientid = pe.personid
join disease di on di.diseaseid = tr.diseaseid where year(tr.date) = "2022" 
group by di.diseasename, pe.gender with rollup;

