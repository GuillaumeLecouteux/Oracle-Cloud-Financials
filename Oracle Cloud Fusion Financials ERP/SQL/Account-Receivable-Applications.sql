/*==================================
Fusion Real Time Reporting Query DDL Script Supplier_Changes.sql
BIP Report view for Supplier Changes

Change Control
Date           Author                Description
28-03-2022     Lakshman              commented og_id join for RA_CUST_TRX_TYPES_ALL as oeg id is not populated in table and not required as PK is CUST_TRX_TYPE_SEQ_ID
=====================================*/

WITH vCustSite as
(SELECT hca.CUST_ACCOUNT_ID      AS CUST_ACCOUNT_ID,
    HL.address1                 AS ADDRESS1,
    hca.ACCOUNT_NUMBER          AS ACCOUNT_NUMBER,  
 	hca.ACCOUNT_NAME            AS ACCOUNT_NAME, 
    hcsu.site_use_id            AS SITE_USE_ID
  
  FROM HZ_CUST_ACCOUNTS hca
  JOIN HZ_CUST_ACCT_SITES_ALL hcsa
  ON hcsa.cust_account_id = hca.cust_account_id
  JOIN hz_cust_site_uses_all hcsu
  ON hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
  JOIN HZ_PARTY_SITES HPS
  ON hcsa.party_site_id = hps.party_site_id  
  JOIN HZ_LOCATIONS HL
  ON hps.location_id = hl.location_id )
,
vApp as
(
SELECT
   RA.AMOUNT_APPLIED Activity_Amount,
   RA.AMOUNT_APPLIED_FROM Activity_Amount_Activity,
   RA.ACCTD_AMOUNT_APPLIED_FROM Activity_Amount_Activity_Base,
   NVL(RA.ACCTD_AMOUNT_APPLIED_TO,DECODE(INV.INVOICE_CURRENCY_CODE,ledg.CURRENCY_CODE,RA.AMOUNT_APPLIED,NULL)) Activity_Amount_Invoice_Base,
   decode(PS.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',PS.CLASS) Activity_Class,
   PS.INVOICE_CURRENCY_CODE Activity_Currency_Code,
   RA.APPLY_DATE Activity_Date,
   PS.EXCHANGE_DATE Activity_Exchange_Date,
   PS.EXCHANGE_RATE Activity_Exchange_Rate,
   PS.EXCHANGE_RATE_TYPE Activity_Exchange_Rate_Type,
   RA.GL_DATE Activity_GL_Date,
   (RA.ACCTD_AMOUNT_APPLIED_FROM - RA.ACCTD_AMOUNT_APPLIED_TO) Activity_Gain_Loss,
   PER.PERIOD_NAME Activity_Period_Name,
   per.PERIOD_YEAR||TRIM(TO_CHAR(per.PERIOD_NUM,'00')) AS PERIOD_KEY,
   PER.PERIOD_NUM Activity_Period_Number,
   PER.QUARTER_NUM Activity_Period_Quarter,
   PER.START_DATE Activity_Period_Start_Date,
   PER.PERIOD_YEAR Activity_Period_Year,
   PER.QUARTER_NUM Activity_Quarter_Number,
   ledg.CURRENCY_CODE Base_Currency_Code,
   PER.PERIOD_SET_NAME Calendar_Name,
   DECODE(PS.CLASS,'CM',PS.TRX_DATE,NULL) AS CREDIT_MEMO_DATE,
   DECODE(PS.CLASS,'CM',PS.TRX_NUMBER,NULL) AS CREDIT_MEMO_NUMBER,
   DECODE(PS.CLASS,'CM',0,NULL) AS CREDIT_MEMO_ID,
   CTYPE.NAME Credit_Memo_Type,
   NVL(INV.AMOUNT_DUE_REMAINING,0) Invoice_Balance_Due,
   (NVL(INV.AMOUNT_DUE_REMAINING,0))*NVL(INV.EXCHANGE_RATE,DECODE(
   INV.INVOICE_CURRENCY_CODE,ledg.CURRENCY_CODE,1,NULL)) Invoice_Balance_Due_Base,
   CASE WHEN RA.APPLIED_PAYMENT_SCHEDULE_ID=-8 /*Refund*/ THEN 'Refund' ELSE decode(INV.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo'
,'GUAR','Guarantee','INV','Invoice','PMT','Payment',INV.CLASS) END AS Invoice_Class,
   CASE WHEN RA.APPLIED_PAYMENT_SCHEDULE_ID=-8 /*Refund*/ THEN PS.INVOICE_CURRENCY_CODE ELSE INV.INVOICE_CURRENCY_CODE END AS Invoice_Currency_Code,
   INV.TRX_DATE Invoice_Date,
   INV.DUE_DATE Invoice_Due_Date,
   INV.EXCHANGE_DATE Invoice_Exchange_Date,
   INV.EXCHANGE_RATE Invoice_Exchange_Rate,
   INV.EXCHANGE_RATE_TYPE Invoice_Exchange_Rate_Type,
   INV.AMOUNT_DUE_ORIGINAL Invoice_Installment_Amount,
   (INV.AMOUNT_DUE_ORIGINAL)*NVL(INV.EXCHANGE_RATE,DECODE(INV.INVOICE_CURRENCY_CODE,ledg.CURRENCY_CODE,1,NULL)) Invoice_Installment_Amt_Base,
   NVL(INV.TERMS_SEQUENCE_NUMBER,1) Invoice_Installment_Number,
   NVL(INV.NUMBER_OF_DUE_DATES,1) Invoice_Installments,
   INV.TRX_NUMBER Invoice_Number,
   decode(INV.STATUS,'CL','Closed','OP','Open',INV.STATUS) Invoice_Status,
   INV.STATUS AS Invoice_Status_Code,
   ITYPE.NAME Invoice_Type,
   ledg.NAME Ledger_Name,
   hou.Name Operating_Unit_Name,
   TRX.PURCHASE_ORDER Purchase_Order,
   TRX.PURCHASE_ORDER_DATE Purchase_Order_Date,
   TRX.PURCHASE_ORDER_REVISION Purchase_Order_Revision,
   DECODE(PS.CLASS,'PMT',PS.TRX_DATE,NULL) AS RECEIPT_DATE,
   DECODE(PS.CLASS,'PMT',PS.TRX_NUMBER,NULL) AS RECEIPT_NUMBER,
   DECODE(PS.CLASS,'PMT',PS.CASH_RECEIPT_ID,NULL) AS RECEIPT_ID,
   RA.GL_DATE AS APP_GL_DATE,
   RM.RECEIPT_METHOD_ID,
   rm.NAME as RECEIPT_METHOD,
   CASE WHEN RA.APPLIED_PAYMENT_SCHEDULE_ID=-8 /*Refund*/ THEN PS.CUSTOMER_ID ELSE INV.CUSTOMER_ID END AS CUSTOMER_ID,
   RA.GL_POSTED_DATE,
   RA.ORG_ID,
   ledg.LEDGER_ID,
   RA.APPLIED_CUSTOMER_TRX_LINE_ID,
   INV.CUSTOMER_TRX_ID,
   RA.RECEIVABLE_APPLICATION_ID,
   INV.CUSTOMER_SITE_USE_ID,
   PS.PAYMENT_SCHEDULE_ID,
   RA.APPLIED_PAYMENT_SCHEDULE_ID

FROM AR_RECEIVABLE_APPLICATIONS_ALL RA
JOIN hr_operating_units hou
  ON RA.ORG_ID = hou.organization_id
LEFT OUTER JOIN AR_PAYMENT_SCHEDULES_ALL PS
  ON PS.PAYMENT_SCHEDULE_ID = RA.PAYMENT_SCHEDULE_ID
  AND PS.ORG_ID = hou.organization_id
  AND NVL(PS.RECEIPT_CONFIRMED_FLAG,'Y')='Y'
JOIN AR_PAYMENT_SCHEDULES_ALL INV
  ON RA.APPLIED_PAYMENT_SCHEDULE_ID=INV.PAYMENT_SCHEDULE_ID
  AND NVL(INV.RECEIPT_CONFIRMED_FLAG,'Y') = 'Y'
  AND INV.PAYMENT_SCHEDULE_ID!= -1
  AND (NVL(INV.ORG_ID + 0, -9999) = hou.organization_id OR INV.ORG_ID=-3116 /*Refund*/)
LEFT OUTER JOIN RA_CUST_TRX_TYPES_ALL ITYPE
  ON INV.CUST_TRX_TYPE_SEQ_ID= ITYPE.CUST_TRX_TYPE_SEQ_ID
--  AND ITYPE.ORG_ID = hou.organization_id  -- commented on 28-03-2022
LEFT OUTER JOIN RA_CUST_TRX_TYPES_ALL CTYPE
  ON PS.CUST_TRX_TYPE_SEQ_ID= CTYPE.CUST_TRX_TYPE_SEQ_ID
--  AND CTYPE.ORG_ID = hou.organization_id   -- commented on 28-03-2022
LEFT OUTER JOIN RA_CUSTOMER_TRX_ALL TRX
  ON TRX.CUSTOMER_TRX_ID = INV.CUSTOMER_TRX_ID
  AND TRX.ORG_ID = hou.organization_id
JOIN GL_LEDGERS ledg
  ON ledg.LEDGER_ID = RA.SET_OF_BOOKS_ID
JOIN GL_PERIODS PER
  ON RA.GL_DATE BETWEEN PER.START_DATE AND PER.END_DATE
  AND PER.PERIOD_SET_NAME = ledg.PERIOD_SET_NAME
  AND PER.PERIOD_TYPE = ledg.ACCOUNTED_PERIOD_TYPE
  AND PER.ADJUSTMENT_PERIOD_FLAG = 'N'
LEFT OUTER JOIN AR_CASH_RECEIPTS_ALL ACR
   on RA.CASH_RECEIPT_ID = ACR.CASH_RECEIPT_ID
LEFT OUTER JOIN AR_RECEIPT_METHODS RM
  ON RM.RECEIPT_METHOD_ID = ACR.RECEIPT_METHOD_ID
  
WHERE RA.STATUS IN ('APP','ACTIVITY')
  AND NVL(RA.CONFIRMED_FLAG,'Y')='Y'
  )
SELECT
    vApp.activity_amount_activity_base 		as activity_amount_base,
    vApp.activity_amount 					AS activity_amount,
    vApp.activity_date 							AS activity_date,
    vApp.credit_memo_number         				AS credit_memo_number,
    vApp.credit_memo_date           				AS credit_memo_date,
    vApp.activity_class             				AS activity_class,
    vApp.receipt_number             				AS receipt_number,
    vApp.invoice_balance_due_base   				AS invoice_balance_due_base,
    vApp.invoice_currency_code      				AS invoice_currency_code,
    vApp.invoice_number             				AS invoice_number,
    vApp.invoice_type               				AS invoice_type,
    vCustSite.address1                   					AS address1,
    vCustSite.account_name               					AS account_name,
    vCustSite.account_number             					AS account_number,
    vApp.base_currency_code         				AS base_currency_code,
    vApp.ledger_name                				AS ledger_name,
    vApp.operating_unit_name        				AS operating_unit_name,
	vApp.RECEIPT_METHOD as receipt_method,
    vApp.receipt_date 							AS receipt_date,
    vApp.invoice_due_date 						AS invoice_due_date,
    vApp.invoice_date 							AS invoice_date,
	vApp.app_gl_date as app_gl_date,
    vCustSite.cust_account_id            					AS cust_account_id
FROM
    vCustSite   ,
    vApp   
WHERE vCustSite.cust_account_id = vApp.customer_id
    AND vCustSite.site_use_id = vApp.customer_site_use_id
	and (vApp.operating_unit_name IN (:Operating_unit) OR 'DUMMY' IN (:Operating_unit || 'DUMMY'))
	and (vCustSite.account_name IN (:Customer_Name) OR 'DUMMY' IN (:Customer_Name || 'DUMMY'))
	and (vCustSite.account_number IN (:Customer_number) OR 'DUMMY' IN (:Customer_number || 'DUMMY'))
	and (vApp.invoice_number IN (:Trx_Number) OR 'DUMMY' IN (:Trx_Number || 'DUMMY'))
	and (vApp.receipt_number IN (:Receipt_number) OR 'DUMMY' IN (:Receipt_number || 'DUMMY'))
	and (vApp.invoice_type IN (:Trx_Type) OR 'DUMMY' IN (:Trx_Type || 'DUMMY'))
	and (vApp.receipt_method IN (:P_RECEIPT_METHOD) OR 'DUMMY' IN (:P_RECEIPT_METHOD || 'DUMMY'))
	and trunc(NVL(vApp.activity_date,sysdate)) between NVL(:Activity_Date_Start,trunc(nvl(vApp.activity_date,sysdate))) and NVL(:Activity_Date_End,trunc(nvl(vApp.activity_date,sysdate)))
	and trunc(NVL(vApp.invoice_date,sysdate)) between NVL(:Invoice_Date_Start,trunc(nvl(vApp.invoice_date,sysdate))) and NVL(:Invoice_Date_END,trunc(nvl(vApp.invoice_date,sysdate)))
	and trunc(NVL(vApp.invoice_due_date,sysdate)) between NVL(:Invoice_Due_Date_Start,trunc(nvl(vApp.invoice_due_date,sysdate))) and NVL(:Invoice_Due_Date_End,trunc(nvl(vApp.invoice_due_date,sysdate)))
	and trunc(NVL(vApp.receipt_date,sysdate)) between NVL(:Receipt_Date_Start,trunc(nvl(vApp.receipt_date,sysdate))) and NVL(:Receipt_Date_End,trunc(nvl(vApp.receipt_date,sysdate)))
