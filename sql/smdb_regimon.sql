SET LINESIZE 500;
SET FEEDBACK off;
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD hh24:mi:ss';


prompt ######## AGENT DATA CHECK 
COL AGENT_TYPE FOR a15
COL AGENT_NAME FOR a40
COL AGENT_PATH FOR a60
COL AGENT_STATE FOR a15
COL CREATE_TIME FOR a25
COL UPDATE_TIME FOR a25

SELECT 
	AGENT_TYPE,
	AGENT_NAME,
	AGENT_PATH,
	AGENT_STATE,
    TO_DATE(CREATE_TIME) AS CREATE_TIME,
    TO_DATE(UPDATE_TIME) AS UPDATE_TIME
 FROM SMDB.AGENT;
prompt
prompt
prompt ######## RESOURCE DATA CHECK
COL RES_TYPE FOR a15
COL RES_VER FOR a15
COL RES_NAME FOR a40
COL RES_STATE FOR a15
COL CREATE_TIME FOR a25
COL UPDATE_TIME FOR a25

SELECT 
    RES_TYPE,
    RES_VER, 
    RES_NAME, 
    RES_STATE, 
    TO_DATE(CREATE_TIME) AS CREATE_TIME,
    TO_DATE(UPDATE_TIME) AS UPDATE_TIME
FROM SMDB.RESOURCE
WHERE
	AGENT_ID NOT IN (SELECT AGENT_ID FROM SMDB.AGENT WHERE AGENT_ID IS NOT NULL) OR
	AGENT_ID IS NULL;

