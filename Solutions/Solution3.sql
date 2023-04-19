-- ============================ Problem Statement 3 ==============================================================================================

-- Problem Statement 1:  Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine that 
-- they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, wants to get a report of which pharmacies
-- have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. Assist Joshua to generate the report so that the pharmacies 
-- who prescribe hospital-exclusive medicine more often are advised to avoid such practice if possible.   

select pr.pharmacyid, count(c.medicineid) as total_medicine from prescription pr 
join contain c on  pr.prescriptionid = c.prescriptionid
join medicine m on c.medicineid = m.medicineid  join treatment t on t.treatmentid = pr.treatmentid
where m.hospitalexclusive= "s" and year(t.date) in(2021, 2022) 
group by pr.pharmacyid order by total_medicine desc;


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

select ad.state, count(pe.personid) as total_person , count(pa.patientid) as total_patient, count(pa.patientID)/count(pe.personID) as ratio_patient_to_person
from address ad join person pe on ad.addressid = pe.addressid
left join patient pa on pe.personid=pa.patientid  group by ad.state order by ratio_patient_to_person desc;

-- Problem Statement 5:  Jhonny, from the finance department of Arizona(AZ), has requested a report that lists the total quantity of medicine 
-- each pharmacy in his state has prescribed that falls under Tax criteria I for treatments that took place in 2021. 
-- Assist Jhonny in generating the report. 

select ph.pharmacyName, sum(co.quantity) as total_medicine_quantity
from address ad join pharmacy ph on ad.addressid = ph.addressid
join prescription pr on pr.pharmacyid = ph.pharmacyid
join contain co on pr.prescriptionid = co.prescriptionid
join treatment tr on tr.treatmentid = pr.treatmentid
join medicine me on me.medicineid = co.medicineid
where year(tr.date) = "2021" and me.taxcriteria = "I" and ad.state = "AZ" group by ph.pharmacyname order by pharmacyName;


