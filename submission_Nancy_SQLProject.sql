/*

-----------------------------------------------------------------------------------------------------------------------------------
                                               Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

		

-----------------------------------------------------------------------------------------------------------------------------------

                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
  SELECT 
    offender_sex, 
    COUNT(*) AS count
FROM 
    report_t
GROUP BY 
    offender_sex;
    
select sum(cctv_count)
from location_t;

select population_density, area_name
from location_t;


select sum(population_density)
from location_t;

select count(officer_code) from officer_t;
select count(precinct_code) from officer_t;
SELECT 
    count(report_no) AS total_crime_reported
FROM 
    report_t;
    
  SELECT 
    victim_sex, 
    COUNT(*) AS count
FROM 
    victim_t
GROUP BY 
    victim_sex;


/*-- QUESTIONS RELATED TO CRIME
-- [Q1] Which was the most frequent crime committed each week? 
-- Hint: Use a subquery and the windows function to find out the number of crimes reported each week and assign a rank. 
Then find the highest crime committed each week

Note: For reference, refer to question number 3 - mls_week-2_gl-beats_solution.sql. 
      You'll get an overview of how to use subquery and windows function from this question */
      
use crimedata;
show tables

SELECT week_number, crime_type, crimes_reported 
FROM (
    SELECT 
        week_number, 
        crime_type, 
        COUNT(*) AS crimes_reported, 
        RANK() OVER(PARTITION BY week_number ORDER BY COUNT(*) DESC) AS high_crime_reported 
    FROM report_t 
    GROUP BY week_number, crime_type
) AS wk_crime 
WHERE wk_crime.high_crime_reported = 1;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q2] Is crime more prevalent in areas with a higher population density, fewer police personnel, and a larger precinct area? 
-- Hint: Add the population density, count the total areas, total officers and cases reported in each precinct code and check the trend*/

SELECT 
    o.precinct_code, 
    SUM(l.population_density) AS pop_density, 
    COUNT(DISTINCT l.area_code) AS total_areas, 
    COUNT(DISTINCT o.officer_code) AS total_officers, 
    COUNT(*) AS total_cases
FROM report_t AS r
JOIN location_t AS l ON r.area_code = l.area_code
JOIN officer_t AS o ON r.officer_code = o.officer_code
GROUP BY o.precinct_code
ORDER BY total_cases DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q3] At what points of the day is the crime rate at its peak? Group this by the type of crime.
-- Hint: 
time day parts
[1] 00:00 to 05:00 = Midnight, 
[2] 05:01 to 12:00 = Morning, 
[3] 12:01 to 18:00 = Afternoon,
[4] 18:01 to 21:00 = Evening, 
[5] 21:00 to 24:00 = Night

Use a subquery, windows function to find the number of crimes reported each week and assign the rank.
Then find out at what points of the day the crime rate is at its peak.
 
 Note: For reference, refer to question number 3 - mls_week-2_gl-beats_solution.sql. 
      You'll get an overview of how to use subquery, windows function from this question */
      

SELECT 
    dayparts, 
    SUM(crimes_reported) AS total_crimes
FROM (
    SELECT 
        CASE 
            WHEN HOUR(r.incident_time) >= 00 AND HOUR(r.incident_time) < 05 THEN 'Midnight' 
            WHEN HOUR(r.incident_time) >= 05 AND HOUR(r.incident_time) < 12 THEN 'Morning' 
            WHEN HOUR(r.incident_time) >= 12 AND HOUR(r.incident_time) < 18 THEN 'Afternoon' 
            WHEN HOUR(r.incident_time) >= 18 AND HOUR(r.incident_time) <= 21 THEN 'Evening' 
            ELSE 'Night' 
        END AS dayparts, 
        COUNT(*) AS crimes_reported
    FROM report_t AS r
    GROUP BY dayparts
) AS crime_summary
GROUP BY dayparts
ORDER BY total_crimes DESC;







-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q4] At what point in the day do more crimes occur in a different locality?
-- Hint: 
time day parts
[1] 00:00 to 05:00 = Midnight, 
[2] 05:01 to 12:00 = Morning, 
[3] 12:01 to 18:00 = Afternoon,
[4] 18:01 to 21:00 = Evening, 
[5] 21:00 to 24:00 = Night

Use a subquery and the windows function to find the number of crimes reported in each area and assign the rank.
Then find out at what point in the day more crimes occur in a different locality.
 
 Note: For reference, refer to question number 3 - mls_week-2_gl-beats_solution.sql. 
      You'll get an overview of how to use subquery, windows function from this question */

SELECT 
    area_name, 
    dayparts, 
    total_crimes
FROM (
    SELECT 
        l.area_name, 
        CASE 
            WHEN HOUR(r.incident_time) >= 00 AND HOUR(r.incident_time) < 05 THEN 'Midnight'
            WHEN HOUR(r.incident_time) >= 05 AND HOUR(r.incident_time) < 12 THEN 'Morning'
            WHEN HOUR(r.incident_time) >= 12 AND HOUR(r.incident_time) < 18 THEN 'Afternoon'
            WHEN HOUR(r.incident_time) >= 18 AND HOUR(r.incident_time) <= 21 THEN 'Evening'
            ELSE 'Night'
        END AS dayparts,
        COUNT(*) AS total_crimes,
        RANK() OVER (
            PARTITION BY l.area_name 
            ORDER BY COUNT(*) DESC
        ) AS rank_crimes
    FROM report_t AS r
    JOIN location_t AS l ON l.area_code = r.area_code
    GROUP BY l.area_name, dayparts
) AS crime_summary
WHERE rank_crimes = 1
ORDER BY area_name, total_crimes DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q5] Which age group of people is more likely to fall victim to crimes at certain points in the day?
-- Hint: Age 0 to 12 kids, 13 to 23 teenage, 24 to 35 Middle age, 36 to 55 Adults, 56 to 120 old.*/

SELECT 
    age_group, 
    dayparts, 
    total_victims
FROM (
    SELECT 
        CASE 
            WHEN v.victim_age >= 0 AND v.victim_age < 12 THEN 'Kids'
            WHEN v.victim_age >= 13 AND v.victim_age < 23 THEN 'Teenage'
            WHEN v.victim_age >= 24 AND v.victim_age < 35 THEN 'Middle Age'
            WHEN v.victim_age >= 36 AND v.victim_age < 55 THEN 'Adults'
            WHEN v.victim_age >= 56 AND v.victim_age <= 120 THEN 'Old'
            ELSE 'Unknown'
        END AS age_group,
        CASE 
            WHEN HOUR(r.incident_time) >= 0 AND HOUR(r.incident_time) < 5 THEN 'Midnight'
            WHEN HOUR(r.incident_time) >= 5 AND HOUR(r.incident_time) < 12 THEN 'Morning'
            WHEN HOUR(r.incident_time) >= 12 AND HOUR(r.incident_time) < 18 THEN 'Afternoon'
            WHEN HOUR(r.incident_time) >= 18 AND HOUR(r.incident_time) <= 21 THEN 'Evening'
            ELSE 'Night'
        END AS dayparts,
        COUNT(*) AS total_victims,
        RANK() OVER (
            PARTITION BY 
                CASE 
                    WHEN HOUR(r.incident_time) >= 0 AND HOUR(r.incident_time) < 5 THEN 'Midnight'
                    WHEN HOUR(r.incident_time) >= 5 AND HOUR(r.incident_time) < 12 THEN 'Morning'
                    WHEN HOUR(r.incident_time) >= 12 AND HOUR(r.incident_time) < 18 THEN 'Afternoon'
                    WHEN HOUR(r.incident_time) >= 18 AND HOUR(r.incident_time) <= 21 THEN 'Evening'
                    ELSE 'Night'
                END 
            ORDER BY COUNT(*) DESC
        ) AS rank_victims
    FROM report_t AS r
    JOIN victim_t AS v ON r.victim_code = v.victim_code
    GROUP BY age_group, dayparts
) AS victim_summary
ORDER BY dayparts, total_victims DESC;





-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q6] What is the status of reported crimes?.
-- Hint: Count the number of crimes for different case statuses. */

SELECT 
    case_status_desc AS case_status,
    COUNT(*) AS total_crimes
FROM report_t
GROUP BY case_status_desc
ORDER BY total_crimes DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q7] Does the existence of CCTV cameras deter crimes from happening?
-- Hint: Check if there is a correlation between the number of CCTVs in each area and the crime rate.*/
	
      SELECT 
    l.area_name,
    l.cctv_count AS total_cctvs,
    COUNT(r.report_no) AS total_crimes,
    SUM(CASE WHEN r.cctv_flag = 'Yes' THEN 1 ELSE 0 END) AS crimes_with_cctv,
    ROUND(SUM(CASE WHEN r.cctv_flag = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(r.report_no), 2) AS cctv_coverage_percentage
FROM location_t AS l
LEFT JOIN report_t AS r ON l.area_code = r.area_code
GROUP BY l.area_name, l.cctv_count
ORDER BY total_crimes DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q8] How much footage has been recovered from the CCTV at the crime scene?
-- Hint: Use the case when function, add separately when cctv_flag is true and false and check whether in particular area how many cctv is there,
How much CCTV footage is available? How much CCTV footage is not available? */

SELECT 
    l.area_name,
    l.cctv_count AS total_cctvs,
    COUNT(r.report_no) AS total_crimes,
    SUM(CASE WHEN r.cctv_flag = 'Yes' THEN 1 ELSE 0 END) AS crimes_with_cctv,
    SUM(CASE WHEN r.cctv_flag = 'No' THEN 1 ELSE 0 END) AS crimes_without_cctv
FROM location_t AS l
LEFT JOIN report_t AS r ON l.area_code = r.area_code
GROUP BY l.area_name, l.cctv_count
ORDER BY total_crimes DESC;




-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q9] Is crime more likely to be committed by relation of victims than strangers?
-- Hint: Find the distinct crime type along with the count of crime when the offender is related to the victim.*/

SELECT 
    offender_relation,
    crime_type,
    COUNT(*) AS crime_count
FROM 
    report_t
GROUP BY 
    offender_relation, crime_type;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* -- [Q10] What are the methods used by the public to report a crime? 
-- Hint: Find the complaint type along with the count of crime.*/

SELECT 
    complaint_type,
    COUNT(*) AS crime_count
FROM 
    report_t
GROUP BY 
    complaint_type;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



