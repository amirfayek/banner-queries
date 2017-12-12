## Identity Info

### Get PIDM/ID
SELECT gb_common.f_get_id(goremal_pidm) FROM goremal WHERE goremal_email_address='@fhda.edu';
SELECT goremal_pidm FROM goremal WHERE goremal_email_address='@fhda.edu';
SELECT spriden_pidm FROM spriden WHERE spriden_id = '';



## Contact Info

### Addresses

LEFT JOIN spraddr ON spraddr.rowid = f_get_address_rowid(spriden_pidm,'STDNADDR','A',SYSDATE,1,'S',NULL)

### Telephone
LEFT JOIN sprtele ON sprtele.rowid = f_get_sprtele_rowid(spriden_pidm,'STDNPHONE','A',NULL,1)

### Email
LEFT JOIN goremal ON goremal.rowid = f_get_email_rowid(spriden_pidm, 'STDNEMAL', 'A', NULL)



## Enrollment

### Registered, does not include drops
SELECT *
FROM sfrstcr
WHERE sfrstcr.sfrstcr_rsts_code IN
    (SELECT stvrsts.stvrsts_code
    FROM saturn.stvrsts stvrsts
    WHERE stvrsts.stvrsts_incl_sect_enrl = 'Y'
    );

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



