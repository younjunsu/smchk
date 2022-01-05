set linesize 500;
set feedback off;
col "Tablespace Name" format a20;
col "Bytes(MB)"       format 999,999,999;
col "MaxBytes(MB)"    format 999,999,999;
col "Used(MB)"        format 999,999,999;
col "Percent(%)"      format 9999999.99;
col "Free(MB)"        format 999,999,999;
col "Free_REAL(MB)"   format 999,999,999;

SELECT TO_CHAR(sysdate, 'yyyy/mm/dd hh24:mi:ss') "Current Time",
        TABLESPACE_NAME  "Tablespace Name",
                SUM("total MB")  "Bytes(MB)",
                SUM("max MB")    "MaxBytes(MB)",
                SUM("Used MB")   "Used(MB)",
                round( (SUM("Used MB") / SUM("total MB") * 100 ),2 ) "Percent(%)",
                SUM("Free MB")  "Free(MB)",
                SUM("max MB")-SUM("Used MB") "Free_REAL(MB)",
                round( (SUM("max MB")-SUM("Used MB")) / SUM("max MB") * 100, 2) "Free_REAL(%)"
        FROM   (Select D.TABLESPACE_NAME,
                        d.file_name "Datafile name",
                        DECODE(SUM(f.Bytes), null, ROUND(MAX(d.bytes)/1024/1024,2),
                                                    ROUND((MAX(d.bytes)/1024/1024) - (SUM(f.bytes)/1024/1024),2)) "Used MB",
                        DECODE(SUM(f.bytes), null, 0, ROUND(SUM(f.Bytes)/1024/1024,2)) "Free MB" ,
                        ROUND(MAX(d.bytes)/1024/1024,2) "total MB",
                        DECODE(ROUND(MAX(d.MAXBYTES)/1024/1024,2), 0, ROUND(MAX(d.bytes)/1024/1024,2),
                                                                        ROUND(MAX(d.MAXBYTES)/1024/1024,2)) "max MB"
                    From (SELECT * FROM DBA_FREE_SPACE WHERE BYTES/1024/1024 > 1) f , DBA_DATA_FILES d
                    Where f.tablespace_name(+) = d.tablespace_name
                    And f.file_id(+) = d.file_id
                    Group by D.TABLESPACE_NAME, d.file_name
                    Order by D.TABLESPACE_NAME
                )
        GROUP BY TABLESPACE_NAME
        ORDER BY "Free_REAL(%)", "Tablespace Name";
quit
