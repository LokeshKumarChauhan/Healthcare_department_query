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

select tr.diseaseID, di.diseaseName, pharmacyName,count(pe.personID) from disease di 
	join treatment tr on di.diseaseID=tr.diseaseID 
    join patient pa on tr.patientID=pa.patientID 
    join person pe on pe.personID=pa.patientID
    join prescription pr on pr.treatmentID=tr.treatmentID
    join pharmacy ph on pr.pharmacyID=ph.pharmacyID
    where year(tr.date) in (2021,2022)
    group by tr.diseaseID,ph.pharmacyID order by 1,2 ,3 desc;



-- Problem Statement 5:  
-- Walde, from Rock tower insurance, has sent a requirement for a report that presents which insurance company is targeting the patients 
-- of which state the most. Write a query for Walde that fulfills the requirement of Walde.
-- Note: We can assume that insurance company is targeting region more if the patients of that region are claiming more insurance of that company.

select ic.companyname, ad.state, count(tr.claimid) as most_claimed from address ad  
join insurancecompany ic on ad.addressid = ic.addressid
join insuranceplan ip on ic.companyid = ip.companyid
join claim cl on ip.uin = cl.uin
join treatment tr on tr.claimid = cl.claimid 
group by ic.companyname, ad.state;

