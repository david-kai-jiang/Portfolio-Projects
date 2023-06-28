--Question 2: comparison view of a patient’s PHQ score on a given date, their score from their previous assessment, 
--and the date of their previous assessment and the PHQ delta between the scores

WITH phq_scores AS (
  SELECT 
  patient_id, 
  phq_score, 
  score_date, 
  ROW_NUMBER() OVER
    (PARTITION BY patient_id ORDER BY score_date) AS row1, 
  (ROW_NUMBER() OVER
    (PARTITION BY patient_id ORDER BY score_date) + 1) AS row2
  FROM `cerebral-391120.cerebral.scores`
  ORDER BY patient_id
)

SELECT 
  s1.patient_id, 
  s1.phq_score, 
  s1.score_date, 
  s2.phq_score AS prior_phq_score, 
  s2.score_date AS prior_score_date, 
  (s1.phq_score - s2.phq_score) AS phq_score_delta,
  EXTRACT(DAY FROM (s1.score_date - s2.score_date)) AS score_date_delta
FROM phq_scores AS s1
LEFT JOIN phq_scores AS s2
  ON s1.patient_id = s2.patient_id
  AND s1.row1 = s2.row2
ORDER BY s1.patient_id, s1.score_date DESC

--Question 3.1: How many patients were prescribed a drug before their first PHQ assessment?
  
WITH drugs AS (
  SELECT 
    patient_id, written_date, 
    ROW_NUMBER() OVER(
      PARTITION BY patient_id ORDER BY written_date) AS row_drugs
  FROM `cerebral-391120.cerebral.drugs`
  ORDER BY patient_id
),
scores AS (
  SELECT 
    patient_id, 
    phq_score, 
    score_date, 
    ROW_NUMBER() OVER
      (PARTITION BY patient_id ORDER BY score_date) AS row_scores, 
  FROM `cerebral-391120.cerebral.scores`
  ORDER BY patient_id
)

SELECT COUNT(drugs.patient_id) AS num_patients
FROM drugs
INNER JOIN scores
  ON drugs.patient_id = scores.patient_id
  AND drugs.row_drugs = scores.row_scores
WHERE drugs.written_date < scores.score_date
  AND drugs.row_drugs = 1
  AND scores.row_scores = 1


--Question 3.2: How many female patients were assessed for PHQ score at least twice after the first time they were prescribed drug H?
  
WITH patients_sex AS (
  SELECT 
    CAST(SPLIT(patient_id, '_')[offset(2)] AS INTEGER) AS patient_id,
    sex
  FROM `cerebral-391120.cerebral.patients`
),
drug_H AS (
  SELECT 
    patient_id,
    written_date,
    ROW_NUMBER() OVER (
      PARTITION BY patient_id ORDER BY written_date) AS row_H
  FROM `cerebral-391120.cerebral.drugs` AS d
  WHERE d.drug_name = "H"
)

SELECT scores.patient_id, COUNT(scores.patient_id) AS num_PHQ_score_twice
FROM `cerebral-391120.cerebral.scores` AS scores
LEFT JOIN patients_sex
  ON patients_sex.patient_id = scores.patient_id
LEFT JOIN drug_H
  ON drug_H.patient_id = scores.patient_id
WHERE drug_H.row_H = 1
  AND scores.score_date > drug_h.written_date
  AND patients_sex.sex = "female"
GROUP BY scores.patient_id
HAVING COUNT(scores.patient_id)>=2
ORDER BY scores.patient_id
