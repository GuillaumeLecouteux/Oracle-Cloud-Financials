WITH Get_Schedule_Count as(
SELECT COUNT(1) Schedule_Count,invoice_id
FROM   ap_payment_schedules_all
group by invoice_id)

, Get_Invoice_Due_Date as
(
SELECT MAX(due_date) as DUE_DATE
,invoice_id
FROM ap_payment_schedules_all
group by invoice_id
)
, AP_TB AS
  (SELECT to_date(:as_of_date,'DD-MM-YYYY') as_of_date ,
    xtb.invoice_id invoice_id ,
    xtb.TRX_CURRENCY_CODE,
    l.NAME as ledger_name,
    l.CURRENCY_CODE AS LEDGER_CURR_CODE,
    SUM(NVL(xtb.ENTERED_CR,0) - NVL(xtb.ENTERED_DR,0)) trx_amount_due,
    SUM(NVL(xtb.accounted_cr,0) - NVL(xtb.accounted_dr,0)) amount_due
  
  FROM AP_TRIAL_BALANCES xtb  , -- xla_trial_balances xtb,
    ap_invoices_all apa ,
    gl_ledgers l
  WHERE xtb.ledger_id       = l.ledger_id
  AND xtb.accounting_date              <= TO_DATE(:as_of_date,'DD-MM-YYYY')
  AND apa.invoice_id            = xtb.invoice_id
  GROUP BY xtb.invoice_id, 
    xtb.TRX_CURRENCY_CODE,
    l.NAME,
    l.CURRENCY_CODE
  HAVING SUM(NVL(xtb.accounted_cr,0) - NVL(xtb.accounted_dr,0)) <> 0
  )
  
, AP_INV AS
  (SELECT hou.name organisation ,
    nvl(v.vendor_name,party_name) as vendor_name,
    v.segment1 vendor_number,
    I.invoice_id,
    i.invoice_num,
    i.invoice_date,
    i.description,
    i.payment_status_flag ,
	gsc.Schedule_Count SCH_PAY_COUNT,
	gidd.due_date as DUE_DATE,
    ceil(to_date(:as_of_date,'dd-mm-yyyy') - gidd.due_date) DAYS_DUE,
    INVOICE_AMOUNT,
    BASE_AMOUNT,
    TOTAL_TAX_AMOUNT,
    INVOICE_AMOUNT - TOTAL_TAX_AMOUNT as INVOICE_NET_AMOUNT,
    EXCHANGE_RATE,
	(SELECT PayablesLookup.DISPLAYED_FIELD 
	    FROM AP_LOOKUP_CODES PayablesLookup 
	   WHERE  PayablesLookup.LOOKUP_TYPE = 'INVOICE TYPE' 
	     AND I.INVOICE_TYPE_LOOKUP_CODE = PayablesLookup.LOOKUP_CODE(+)) INVOICE_TYPE
  FROM ap_invoices_all i,
    POZ_SUPPLIERS_V v, 					-- ap_suppliers v,
    HR_ALL_ORGANIZATION_UNITS_TL hou,
    HZ_PARTIES HP,
	Get_Schedule_Count gsc,
	Get_Invoice_Due_Date gidd
  WHERE i.vendor_id       = v.vendor_id (+)
  and i.party_id = hp.party_id (+)
  AND hou.organization_id = i.org_id
  AND gsc.invoice_id (+) = i.invoice_id
  AND gidd.invoice_id (+) = i.invoice_id 
 )

, year_end_rate as(
    SELECT r.FROM_CURRENCY
    , r.TO_CURRENCY
    , r.CONVERSION_RATE
    FROM GL_DAILY_RATES r
    JOIN GL_PERIODS p
    ON p.end_date=r.conversion_date
    WHERE CONVERSION_TYPE = 'Corporate'
    AND p.PERIOD_SET_NAME=:PERIOD_SET_NAME
    AND p.ENTERED_PERIOD_NAME='12'
    AND TO_DATE(:as_of_date,'DD-MM-YYYY') BETWEEN p.year_start_date AND p.end_date
)

SELECT to_char(ap_tb.as_of_date,'DD-MM-YYYY') As_Of_Date,
  ap_inv.vendor_name,
  ap_inv.vendor_number,
  ap_inv.invoice_num,
  ap_inv.INVOICE_TYPE,
 REPLACE(REPLACE(TO_CHAR(ap_inv.description ), CHR(13),' '), CHR(10),' ') description,
  ap_inv.organisation,
  TO_CHAR(ap_inv.due_date,'DD-MM-YYYY') due_date,
  ap_inv.sch_pay_count,
  ap_inv.days_due,
  trx_currency_code as trx_currency,
  INVOICE_AMOUNT,  
  TOTAL_TAX_AMOUNT,
  EXCHANGE_RATE,
  INVOICE_AMOUNT*EXCHANGE_RATE,
  trx_amount_due,
  case when ap_tb.TRX_CURRENCY_CODE=ap_tb.LEDGER_CURR_CODE THEN 1 ELSE year_end_rate.CONVERSION_RATE END as year_end_rate,
  ap_tb.ledger_curr_code as functional_currency,
  ap_tb.amount_due,
  ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE INVOICE_NET_AMOUNT/INVOICE_AMOUNT end,2) as net_amount_due,
  ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE TOTAL_TAX_AMOUNT/INVOICE_AMOUNT end,2) as tax_amount_due,
  CASE WHEN to_date(ap_inv.DUE_DATE) > TO_DATE(as_of_date) OR AP_INV.SCH_PAY_COUNT> 1 THEN ROUND(ap_tb.amount_due,2) ELSE NULL END CURRENT_BUCKET,
  CASE WHEN to_date(ap_inv.DUE_DATE) > TO_DATE(as_of_date) OR AP_INV.SCH_PAY_COUNT> 1 THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE INVOICE_NET_AMOUNT/INVOICE_AMOUNT end,2) ELSE NULL END CURRENT_BUCKET_NET,
  CASE WHEN to_date(ap_inv.DUE_DATE) > TO_DATE(as_of_date) OR AP_INV.SCH_PAY_COUNT> 1 THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE TOTAL_TAX_AMOUNT/INVOICE_AMOUNT end,2) ELSE NULL END CURRENT_BUCKET_TAX,
  CASE WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) >= 0
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 30
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due,2)
    ELSE NULL
  END DAYS30_BUCKET,
  CASE WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) >= 0
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 30
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE INVOICE_NET_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS30_BUCKET_NET,
  CASE WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) >= 0
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 30
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE TOTAL_TAX_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS30_BUCKET_TAX,
  
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE))  > 30
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due,2)
    ELSE NULL
  END DAYS60_BUCKET,
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE))  > 30
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE INVOICE_NET_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS60_BUCKET_NET,
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE))  > 30
    AND (ceil(to_date(as_of_date)  - ap_inv.DUE_DATE)) <= 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE TOTAL_TAX_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS60_BUCKET_TAX,
  
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) > 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND (ap_tb.amount_due,2)
    ELSE NULL
  END DAYS61_PLUS_BUCKET,
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) > 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE INVOICE_NET_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS61_PLUS_BUCKET_NET,
  CASE
    WHEN (ceil(to_date(as_of_date) - ap_inv.DUE_DATE)) > 60
    AND AP_INV.SCH_PAY_COUNT = 1
    THEN ROUND(ap_tb.amount_due * case when INVOICE_AMOUNT=0 THEN 0 ELSE TOTAL_TAX_AMOUNT/INVOICE_AMOUNT end,2)
    ELSE NULL
  END DAYS61_PLUS_BUCKET_TAX,
  ap_inv.invoice_id
FROM ap_tb
JOIN ap_inv
ON ap_tb.invoice_id = ap_inv.invoice_id
LEFT OUTER JOIN year_end_rate
ON ap_tb.TRX_CURRENCY_CODE=year_end_rate.FROM_CURRENCY
AND ap_tb.LEDGER_CURR_CODE =year_end_rate.TO_CURRENCY
WHERE 1=1
 AND ap_tb.as_of_date    = TO_DATE(:as_of_date,'DD-MM-YYYY')
 AND ap_inv.organisation IN (:organisation)
