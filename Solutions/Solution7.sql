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
if v2 > v1 then select "claimed higher than average";
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


