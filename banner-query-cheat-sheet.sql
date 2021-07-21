## Identity Info

### Get PIDM/ID
SELECT goremal_pidm, gb_common.f_get_id(goremal_pidm) FROM goremal WHERE goremal_email_address='amitroland@fhda.edu';
SELECT goremal_pidm FROM goremal WHERE goremal_email_address='@fhda.edu';
SELECT spriden_pidm FROM spriden WHERE spriden_id = '';



## Contact Info

### Addresses

LEFT JOIN spraddr ON spraddr.rowid = f_get_address_rowid(spriden_pidm,'STDNADDR','A',SYSDATE,1,'S',NULL)

### Telephone
LEFT JOIN sprtele ON sprtele.rowid = f_get_sprtele_rowid(spriden_pidm,'STDNPHONE','A',NULL,1)

### Email
LEFT JOIN goremal ON goremal.rowid = f_get_email_rowid(spriden_pidm, 'STDNEMAL', 'A', NULL)

### SGBSTDN
JOIN ON sgbstdn.ROWID = f_get_current_sgbstdn_rowid(student.spriden_pidm, (SELECT student.f_fhda_current_aidy FROM DUAL))


## Enrollment

### Registered, does not include drops
SELECT *
FROM sfrstcr
JOIN ssbsect ON sfrstcr_crn = ssbsect_crn AND sfrstcr_term_code = ssbsect_term_code
WHERE sfrstcr.sfrstcr_rsts_code IN
    (SELECT stvrsts.stvrsts_code
    FROM saturn.stvrsts stvrsts
    WHERE stvrsts.stvrsts_incl_sect_enrl = 'Y'
    )
AND sfrstcr_term_code = :p_term;

SELECT *
FROM sfbetrm
WHERE EXISTS
  (SELECT 1
  FROM sfrstcr
  WHERE sfrstcr_term_code = sfbetrm.SFBETRM_TERM_CODE
  AND sfrstcr_pidm        = sfbetrm_pidm
  AND sfrstcr_rsts_code  IN
    (SELECT stvrsts.stvrsts_code
    FROM saturn.stvrsts stvrsts
    WHERE stvrsts.stvrsts_incl_sect_enrl = 'Y'
    )
  )
AND sfbetrm_term_code = :TERM;

### Registered, does not include withdraws
SELECT *
FROM sfrstcr
WHERE sfrstcr.sfrstcr_rsts_code LIKE 'R%';


SELECT *
FROM sirasgn
JOIN ssbsect
ON  ssbsect_term_code = sirasgn_term_code
AND ssbsect_crn       = sirasgn_crn
WHERE sirasgn_pidm    = gb_common.f_get_pidm('10697515');

SELECT *
FROM ssbsect
JOIN ssrcorq
ON  ssbsect_term_code = ssrcorq_term_code
AND ssbsect_crn       = ssrcorq_crn
WHERE ssrcorq_term_code    = 202032;

select * from gorrsql where lower(gorrsql_where_clause) like '%pebempl%';
select * from pebempl where pebempl_pidm = gb_common.f_get_pidm(:p_cwid);

select * from sortest where sortest_pidm = gb_common.f_get_pidm(:p_cwid);


### SECURITY

#### Find security groups user is a part of
SELECT * FROM bansecr.gurucls WHERE gurucls_userid = 'Q11249993';

#### List users in a security group
SELECT spriden_id,
  spriden_first_name,
  spriden_last_name,
  gurucls_class_code
FROM bansecr.gurucls
JOIN spriden
ON spriden_id             = SUBSTR(gurucls_userid, 2)
WHERE spriden_change_ind IS NULL
AND gurucls_class_code = 'FHDA_STUDENT_CASHIER_DA_SUPER';

#### List users in each group user is part of
SELECT spriden_id,
  spriden_first_name,
  spriden_last_name,
  gurucls_class_code
FROM bansecr.gurucls g1
JOIN spriden
ON spriden_id             = SUBSTR(gurucls_userid, 2)
WHERE spriden_change_ind IS NULL
AND EXISTS
  (SELECT 1
  FROM bansecr.gurucls g2
  WHERE g2.gurucls_class_code = g1.gurucls_class_code
  AND g2.gurucls_userid       = 'Q10403726'
  );