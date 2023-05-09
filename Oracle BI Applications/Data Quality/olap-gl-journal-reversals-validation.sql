with vJnl
as (select /*+materialize*/ PERIOD_NAME,
                            je_header_id,
                            ACCRUAL_REV_JE_HEADER_ID,
                            REVERSED_JE_HEADER_ID,
                            ACCRUAL_REV_PERIOD_NAME,
                            ACCRUAL_REV_STATUS,
                            ACCT_CV_ACCOUNTING_KFF,
                            SUM(AMOUNT_DR) as AMOUNT_DR,
                            SUM(AMOUNT_CR) as AMOUNT_CR,
                            SUM(AMOUNT) as AMOUNT,
                            ACCT_SV_ACCOUNT,
                            count(1) as NB_LINES
    from W_GL_JOURNAL_F jnl
    group by PERIOD_NAME,
             je_header_id,
             ACCRUAL_REV_JE_HEADER_ID,
             REVERSED_JE_HEADER_ID,
             ACCRUAL_REV_PERIOD_NAME,
             ACCRUAL_REV_STATUS,
             ACCT_CV_ACCOUNTING_KFF,
             ACCT_SV_ACCOUNT
   ),
     vReversed
as (select *
    from vJnl r
    where r.REVERSED_JE_HEADER_ID <> 0
   ),
     vOriginals
as (select o.*
    from vJnl o
    where o.JE_HEADER_ID in (
                                select r.REVERSED_JE_HEADER_ID from vJnl r
                            )
   ),
     vDiff
as (select vOriginals.period_name,
           vOriginals.je_header_id,
           vOriginals.ACCRUAL_REV_JE_HEADER_ID,
           vOriginals.ACCRUAL_REV_PERIOD_NAME,
           vOriginals.ACCRUAL_REV_STATUS,
           vOriginals.ACCT_CV_ACCOUNTING_KFF,
           vOriginals.ACCT_SV_ACCOUNT,
           vOriginals.AMOUNT_DR,
           vOriginals.AMOUNT_CR,
           vOriginals.AMOUNT,
           vOriginals.NB_LINES,
           vReversed.je_header_id as REVERSAL_JNL_JE_HEADER_ID,
           vReversed.period_name as REVERSAL_period_name,
           vReversed.REVERSED_JE_HEADER_ID,
           vReversed.ACCT_CV_ACCOUNTING_KFF as REV_ACCT_CV_ACCOUNTING_KFF,
           vReversed.AMOUNT_DR as REV_AMOUNT_DR,
           vReversed.AMOUNT_CR as REV_AMOUNT_CR,
           vReversed.AMOUNT as REV_AMOUNT,
           vReversed.NB_LINES as REV_NB_LINES,
           ABS(NVL(vOriginals.AMOUNT, 0) + NVL(vReversed.AMOUNT, 0)) as DIFF_ORIG_REV
    from vOriginals
        full outer join vReversed
            on vReversed.REVERSED_JE_HEADER_ID = vOriginals.JE_HEADER_ID
               and vReversed.ACCT_CV_ACCOUNTING_KFF = vOriginals.ACCT_CV_ACCOUNTING_KFF
   )
select *
from vDiff
where je_header_id in ( 5210798, 5207975 );


select je_name
from W_GL_JOURNAL_F
where je_header_id = 3407738;


with vJnl
as (select /*+materialize*/ PERIOD_NAME,
                            je_header_id,
                            ACCRUAL_REV_JE_HEADER_ID,
                            REVERSED_JE_HEADER_ID,
                            ACCRUAL_REV_PERIOD_NAME,
                            ACCRUAL_REV_STATUS,
                            ACCT_CV_ACCOUNTING_KFF,
                            SUM(AMOUNT_DR) as AMOUNT_DR,
                            SUM(AMOUNT_CR) as AMOUNT_CR,
                            SUM(AMOUNT) as AMOUNT,
                            ACCT_SV_ACCOUNT,
                            count(1) as NB_LINES
    from W_GL_JOURNAL_F jnl
    group by PERIOD_NAME,
             je_header_id,
             ACCRUAL_REV_JE_HEADER_ID,
             REVERSED_JE_HEADER_ID,
             ACCRUAL_REV_PERIOD_NAME,
             ACCRUAL_REV_STATUS,
             ACCT_CV_ACCOUNTING_KFF,
             ACCT_SV_ACCOUNT
   ),
     vReversed
as (select *
    from vJnl r
    where r.REVERSED_JE_HEADER_ID <> 0
   ),
     vOriginals
as (select o.*
    from vJnl o
    where o.JE_HEADER_ID in (
                                select r.REVERSED_JE_HEADER_ID from vJnl r
                            )
   ),
     vDiff
as (select vOriginals.period_name,
           vOriginals.je_header_id,
           vOriginals.ACCRUAL_REV_JE_HEADER_ID,
           vOriginals.ACCRUAL_REV_PERIOD_NAME,
           vOriginals.ACCRUAL_REV_STATUS,
           vOriginals.ACCT_CV_ACCOUNTING_KFF,
           vOriginals.ACCT_SV_ACCOUNT,
           vOriginals.AMOUNT_DR,
           vOriginals.AMOUNT_CR,
           vOriginals.AMOUNT,
           vOriginals.NB_LINES,
           vReversed.je_header_id as REVERSAL_JNL_JE_HEADER_ID,
           vReversed.period_name as REVERSAL_period_name,
           vReversed.REVERSED_JE_HEADER_ID,
           vReversed.ACCT_CV_ACCOUNTING_KFF as REV_ACCT_CV_ACCOUNTING_KFF,
           vReversed.AMOUNT_DR as REV_AMOUNT_DR,
           vReversed.AMOUNT_CR as REV_AMOUNT_CR,
           vReversed.AMOUNT as REV_AMOUNT,
           vReversed.NB_LINES as REV_NB_LINES,
           ABS(NVL(vOriginals.AMOUNT, 0) + NVL(vReversed.AMOUNT, 0)) as DIFF_ORIG_REV
    from vOriginals
        full outer join vReversed
            on vReversed.REVERSED_JE_HEADER_ID = vOriginals.JE_HEADER_ID
               and vReversed.ACCT_CV_ACCOUNTING_KFF = vOriginals.ACCT_CV_ACCOUNTING_KFF
   )
select *
from vDiff;