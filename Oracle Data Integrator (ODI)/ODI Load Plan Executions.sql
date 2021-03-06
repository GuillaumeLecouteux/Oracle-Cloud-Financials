SELECT sli.i_lp_inst AS load_PLAN_INSTANCE
     , SLR.NB_RUN AS RUN_NUMBER
     , SLI.LOAD_PLAN_NAME AS LOAD_PLAN_NAME
     , SLR.CONTEXT_CODE AS SOURCE_SYSTEM
     , DECODE(SLR.STATUS, 'D', 'Success', 'E', 'Error', 'Q', 'Queued', 'W', 'Waiting', 'M', 'Warning', 'R', 'Running',SLR.STATUS) AS LOAD_PLAN_STATUS
     , SLR.RETURN_CODE AS ERROR_CODE
     , SLR.DURATION as DURATION_IN_SEC
     , ROUND(SLR.DURATION/60,2) as DURATION_IN_MIN
     , CASE WHEN SLR.END_DATE IS NULL 
            THEN TRUNC(ROUND((NVL(SLR.END_DATE , SYSDATE) - SLR.START_DATE)*86400) / 3600)
           || ':' ||
                 LPAD(TRUNC(MOD(ROUND((NVL(SLR.END_DATE , SYSDATE) - SLR.START_DATE)*86400), 3600) / 60), 2, 0) || ':' || 
                 LPAD(MOD(ROUND((NVL(SLR.END_DATE , SYSDATE) - SLR.START_DATE)*86400), 60), 2, 0)
            ELSE TRUNC(SLR.DURATION / 3600) || ':' || LPAD(TRUNC(MOD(SLR.DURATION, 3600) / 60), 2, 0) || ':' || LPAD(MOD(SLR.DURATION, 60), 2, 0) 
       END AS LOAD_TIME
       , TRUNC(SLR.START_DATE) as START_DATE
     , SLR.START_DATE as START_DATE_TIME
     , TRUNC(SLR.END_DATE) as END_DATE
     , SLR.END_DATE as END_DATE_TIME
  FROM PRDODI_ODI_REPO.snp_lp_inst sli
  JOIN PRDODI_ODI_REPO.snp_lpi_run slr
  ON sli.i_lp_inst = slr.i_lp_inst
ORDER BY SLR.START_DATE DESC
;
