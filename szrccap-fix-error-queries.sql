/* 
This file is intended to clear SWACCAP errors or debug your CCCApply to Banner procedure or trigger.
It can be utilized by California schools that use Banner.
*/


/*** GENERAL ***/

/* 
Query Oracle errors 

Common Errors:
ORA-06508: PL/SQL: could not find program unit being called
Occurs when trigger is compiled while records are being processed or trigger
did not compiled.

ORA-20100: ::PIDM is required.::
When SWAMTCH is used it clears the PIDM. This may happen if there's an error in the trigger
*/
SELECT szrccap_seqno,
    szrccap_pidm,
    szrccap_ora_err_mesg,
    szrccap_cccapply_loaded,
    szrccap_banner_updated,
FROM szrccap
WHERE szrccap_ora_err_mesg IS NOT NULL
ORDER BY szrccap_cccapply_loaded DESC;

/* Query Records that aren't processed */
SELECT *
FROM szrccap
WHERE szrccap_cccapply_loaded IS NOT NULL
ORDER BY szrccap_cccapply_loaded DESC;

/* 
Use when you need to process records stuck in suspense, possibly after you
have made changes to the trigger. szrccap_banner_updated will have a date
if the record has been fully proccessed by Banner. Comment and uncomment
lines that apply to your issue.

ORA-06508: PL/SQL: could not find program unit being called
Occurs when trigger is compiled while records are being processed or trigger
did not compiled.

ORA-20100: ::PIDM is required.::
When SWAMTCH is used it clears the PIDM. This may happen if there's an error in the trigger

*/
UPDATE szrccap
SET szrccap_banner_updated  = NULL
WHERE szrccap_banner_updated IS NULL
-- Try and clear all records with Oracle errors
-- AND szrccap_ora_err_mesg IS NOT NULL
-- Try and clear all records with specific Oracle error.
-- AND szrccap_ora_err_mesg = 'ORA-06508: PL/SQL: could not find program unit being called';
-- Dont batch update old terms because emails will be sent to students
-- AND szrccap_term_code = 202031
-- Target specific record
AND szrccap_seqno = 'ENTER_SEQUENCE';



/*
SARADAP ERRORS
*/

/* Query relevant saradap fields */
SELECT szrccap_seqno,
    szrccap_term_code,
    szrccap_cccapply_loaded,
    szrccap_banner_updated,
    szrccap_sex,
    szrccap_coll_code,
    szrccap_program,
    szrccap_program_source,
    szrccap_edlv_code,
    szrccap_err_saradap,
    szrccap_ora_err_loc,
    szrccap_ora_err_mesg
FROM szrccap
WHERE szrccap_err_saradap LIKE 'E%'
--AND szrccap_seqno = 'ENTER_SEQUENCE'
--AND szrccap_pidm = 'ENTER_PIDM'
--AND szrccap_program_source = 'FH_CEA_1PH2'
AND szrccap_term_code >= 202111;

/*
Query program that is causing the error. 

Comment or uncomment what you need.

KNOWN CASES: 
-Setting is not checked in Banner.
-Old code in CCCApply that is no longer used.
-Typo in CCCApply like _ instead of -
-We enter the program field into the major field
in SWACCAP and that may cause issues.
*/

SELECT sobcurr_program,
               sobcurr_degc_code,
               sorcmjr_majr_code,
               sorcmjr_dept_code,
               sorcmjr_curr_rule,
               sorcmjr_cmjr_rule,
               sobcurr_camp_code,
               sobcurr_levl_code,
               sobcurr_coll_code
          FROM sobcurr,
               sorcmjr a,
               smrprle,
               sormcrl c
         WHERE     sobcurr_curr_rule = sorcmjr_curr_rule
               --AND sorcmjr_majr_code = :NEWszrccap_majr_code_1
               AND sobcurr_coll_code = :NEWszrccap_coll_code
               AND sobcurr_camp_code = :NEWszrccap_coll_code --:NEWszrccap_camp_code   ***fhda change
               AND a.sorcmjr_term_code_eff =
                      (SELECT MAX (b.sorcmjr_term_code_eff)
                         FROM sorcmjr b
                        WHERE     b.sorcmjr_majr_code = a.sorcmjr_majr_code
                              AND sobcurr_curr_rule = b.sorcmjr_curr_rule
                              AND b.sorcmjr_term_code_eff <= :v_process_term)
               AND a.sorcmjr_adm_ind = 'Y'
               AND sobcurr_program = :newszrccap_program
               AND sobcurr_program = smrprle_program
               AND c.sormcrl_term_code_eff =
                      (SELECT MAX (d.sormcrl_term_code_eff)
                         FROM sormcrl d
                        WHERE     d.sormcrl_curr_rule = sobcurr_curr_rule
                              AND sormcrl_term_code_eff <= :v_process_term)
               AND c.sormcrl_curr_rule = sobcurr_curr_rule
               -- These are settings that users should check. Contact A&R for them to adjust settings.
               AND sormcrl_adm_ind = 'Y'
               AND smrprle_locked_ind = 'Y'
               AND sobcurr_lock_ind = 'Y'
               AND sobcurr_program NOT LIKE 'R-%'
      ORDER BY sobcurr_degc_code;


/* 
Use to put the program code back.

When users try to fix a program code error in SWACCAP, they may try to
change the program code. Because we are entering the program field into
the major field, when a user selects a major, it will override the program
value. 
*/
UPDATE szrccap
set szrccap_program = szrccap_program_source
WHERE szrccap_err_saradap IN ('E10', 'E11')
AND szrccap_seqno = 'ENTER_SEQUENCE';

/* Use to put a default major when an old one was left in CCCApply. */

--For De Anza
UPDATE szrccap
SET szrccap_program         = 'DA_AA_2SME'
-- SELECT * FROM szrccap
WHERE szrccap_err_saradap  IN ('E10', 'E11')
AND szrccap_banner_updated IS NULL
AND szrccap_term_code      = 202031
AND szrccap_term_code LIKE '%2';

--For Foothill
UPDATE szrccap
SET szrccap_program         = 'FH_CEA_1FTV'
-- SELECT * FROM szrccap
WHERE szrccap_err_saradap  IN ('E10', 'E11')
AND szrccap_banner_updated IS NULL
AND szrccap_term_code      = 202121
AND szrccap_term_code LIKE '%1';


/* Education Level Errors */

--UPDATE szrccap
--SET szrccap_banner_updated = NULL
SELECT * 
FROM szrccap
WHERE szrccap_err_saradap IN ('E07')
AND szrccap_banner_updated IS NULL
AND szrccap_term_code >= 202031;



/*** IDEN ERRORS ***/

/* Query missing pidm */
SELECT szrccap_seqno,
    szrccap_ora_err_mesg,
    szrccap_cccapply_loaded,
    szrccap_banner_updated,
    szrccap_ora_err_loc
FROM szrccap
WHERE szrccap_ora_err_mesg = 'ORA-20100: ::PIDM is required.::'
ORDER BY szrccap_cccapply_loaded DESC;

/* Update pidm to our default value */
UPDATE szrccap
SET szrccap_pidm = '99999999'
WHERE szrccap_ora_err_mesg = 'ORA-20100: ::PIDM is required.::'
AND szrccap_banner_updated IS NULL
AND szrccap_term_code >= 202131;

/* Query students that have a matching error */
SELECT spriden_pidm, spriden_id, spriden_first_name, spriden_last_name, spbpers_birth_date, spbpers_ssn
FROM spriden,
    spbpers,
    szrccap
WHERE SOUNDEX (szrccap_last_name)     = spriden_soundex_last_name
AND SOUNDEX (szrccap_first_name)      = spriden_soundex_first_name
AND spriden_change_ind               IS NULL
AND spriden_id                       != NVL (szrccap_id, '*********')
AND ( NVL (spbpers_ssn, '*********') != NVL (szrccap_ssn, '*********')
 OR (spbpers_ssn                     IS NULL
AND szrccap_ssn                      IS NULL))
AND spbpers_pidm                      = spriden_pidm
AND TRUNC (spbpers_birth_date)        = TRUNC (TO_DATE(szrccap_birth_date))
AND szrccap_seqno                     = '2179560';


/*** FOLK ERRORS ***/

/* Query sorfolk errors */
 SELECT
    szrccap_seqno,
    szrccap_cccapply_loaded,
    szrccap_banner_updated,
    szrccap_natn_code_ma,
    szrccap_emer_natn_code,
    szrccap_emer_city,
    szrccap_emer_zip,
    szrccap_relt_code, --E02 errors
    szrccap_err_sorfolk
FROM szrccap
--WHERE szrccap_seqno = '2173968';
WHERE szrccap_err_sorfolk LIKE 'E%'
AND szrccap_cccapply_loaded > SYSDATE - 90;

/* 
Query invalid country code (szrccap_emer_natn_code) 

TODO: Find out why the country code formats are different for
some fields in CCCApply.
*/
 SELECT
    szrccap_seqno,
    szrccap_banner_updated,
    szrccap_natn_code_ma,
    szrccap_emer_natn_code,
    szrccap_emer_city,
    szrccap_emer_zip,
    szrccap_err_sorfolk
FROM szrccap
--WHERE szrccap_seqno = '2173968';
WHERE szrccap_err_sorfolk = 'E03'
AND szrccap_cccapply_loaded > SYSDATE - 90;

/* 
Update country code manually. Or to prevent this error for this country code, add country to translation table 
and use function baninst1.fhda_admission.f_ccc_translate_natn_code(szrccap_emer_natn_code)
*/
UPDATE szrccap
SET szrccap_emer_natn_code = baninst1.fhda_admission.f_ccc_translate_natn_code(szrccap_emer_natn_code)
--WHERE szrccap_seqno = '2146463';
WHERE szrccap_err_sorfolk = 'E03'
AND szrccap_cccapply_loaded > SYSDATE - 90
AND szrccap_banner_updated IS NULL;

/* 
Query relationship code errors

TODO: Find difference between szrccap_emer_relt_code and szrccap_relt_code.
These values are being inconsistently used in our trigger.
*/
 
SELECT szrccap_seqno,
    szrccap_term_code,
    szrccap_err_sorfolk,
    szrccap_relt_code,
    szrccap_emer_relt_code,
    szrccap_emer_first_name,
    szrccap_emer_last_name
FROM szrccap
WHERE szrccap_err_sorfolk LIKE 'E02'
AND szrccap_term_code >= 202111;

UPDATE szrccap
--SET szrccap_relt_code = 'M'
SET szrccap_relt_code = szrccap_emer_relt_code
WHERE szrccap_err_sorfolk LIKE 'E02'
AND szrccap_cccapply_loaded > SYSDATE - 90
--AND szrccap_seqno   = '2177222';


/* 
On job server to find what file a CWID is in. Filter by
approximate filename to speed search 
*/

--grep -R --include='CC-DA-210330*' '20233702' .