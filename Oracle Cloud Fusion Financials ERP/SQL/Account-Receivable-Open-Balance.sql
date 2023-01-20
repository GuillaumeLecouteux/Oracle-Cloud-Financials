with vOrg as (
SELECT
    o2.organization_id as ORG_ID,
    o2.name AS ORG_NAME,
    lg.ledger_id as LEDGER_ID,
    lg.ledger_id as SET_OF_BOOKS_ID,
    lg.name as LEDGER_NAME,
    lg.CURRENCY_CODE as LEDGER_CURRENCY,
    lg.CHART_OF_ACCOUNTS_ID,
    o3.ATTRIBUTE1 FUSION_ORG_ID
FROM gl_ledgers lg,
    hr_operating_units o2,
    hr_organization_information o3
WHERE o3.org_information3 = TO_CHAR(lg.ledger_id)
    AND o3.organization_id = o2.organization_id
)
, vRMCustomer as
(
SELECT HCSA.CUST_ACCOUNT_ID as CUSTOMER_ID
, HCSA.CUST_ACCT_SITE_ID
, HCSA.BILL_TO_FLAG
, HCSU.SITE_USE_ID
, HCSU.SITE_USE_CODE
, CRM.CUSTOMER_ID as CRM_CUSTOMER_ID_SITE
, CRM.SITE_USE_ID as CRM_SITE_USE_ID_SITE
, CRMAcct.CUSTOMER_ID as CRM_CUSTOMER_ID_ACCT
, CRMAcct.SITE_USE_ID as CRM_SITE_USE_ID_ACCT
, RM.NAME AS RECEIPT_METHOD_NAME_SITE
, RMAcct.NAME AS RECEIPT_METHOD_NAME_ACCT
, NVL(RM.NAME, RMAcct.NAME) as CUST_RECEIPT_METHOD_NAME
, CASE WHEN RM.NAME IS NOT NULL THEN 'Site' ELSE 'Account' END AS RECEIPT_METHOD_LEVEL

FROM HZ_CUST_ACCT_SITES_ALL HCSA  
JOIN HZ_CUST_SITE_USES_ALL HCSU
ON HCSU.CUST_ACCT_SITE_ID = HCSA.CUST_ACCT_SITE_ID
AND HCSU.SITE_USE_CODE='BILL_TO'
LEFT OUTER JOIN RA_CUST_RECEIPT_METHODS CRM
  ON HCSU.SITE_USE_ID = CRM.SITE_USE_ID
  AND HCSA.CUST_ACCOUNT_ID = CRM.CUSTOMER_ID
  AND crm.PRIMARY_FLAG='Y'
  and  SYSDATE BETWEEN crm.start_date AND NVL(crm.end_date,SYSDATE)
LEFT OUTER JOIN AR_RECEIPT_METHODS RM
  ON RM.RECEIPT_METHOD_ID = crm.RECEIPT_METHOD_ID
LEFT OUTER JOIN RA_CUST_RECEIPT_METHODS CRMAcct
  ON CRMAcct.SITE_USE_ID = NULL
  AND HCSA.CUST_ACCOUNT_ID = CRMAcct.CUSTOMER_ID
  AND crmAcct.PRIMARY_FLAG='Y'
  and  SYSDATE BETWEEN crmAcct.start_date AND NVL(crmAcct.end_date,SYSDATE)
LEFT OUTER JOIN AR_RECEIPT_METHODS RMAcct
  ON RMAcct.RECEIPT_METHOD_ID = crmAcct.RECEIPT_METHOD_ID
)
, vCustomer as
(
SELECT HCA.CUST_ACCOUNT_ID,
HCA.ACCOUNT_NUMBER,
NVL(HCA.ACCOUNT_NAME,'N/A') AS ACCOUNT_NAME,


HCP.CREDIT_CLASSIFICATION as CREDIT_CLASSIFICATION_CODE,
HCP.CUST_ACCOUNT_PROFILE_ID,
HCP.EFFECTIVE_START_DATE as CUST_PRF_START_DATE,
HCP.EFFECTIVE_END_DATE as CUST_PRF_END_DATE,
HCP.SITE_USE_ID as CUST_PRF_SITE_USE_ID,

CC.LOOKUP_TYPE,
CC.MEANING AS CREDIT_CLASSIFICATION

FROM HZ_CUST_ACCOUNTS HCA
JOIN HZ_CUSTOMER_PROFILES_F HCP
  ON HCP.CUST_ACCOUNT_ID=HCA.CUST_ACCOUNT_ID
  AND HCP.SITE_USE_ID IS NULL
  AND SYSDATE BETWEEN HCP.EFFECTIVE_START_DATE AND HCP.EFFECTIVE_END_DATE
LEFT OUTER JOIN AR_LOOKUPS CC ON CC.LOOKUP_CODE=HCP.CREDIT_CLASSIFICATION
  AND CC.LOOKUP_TYPE = 'AR_CMGT_CREDIT_CLASSIFICATION'
)
, vReceiptApp AS
(
select RA.CASH_RECEIPT_ID, RA.RECEIVABLE_APPLICATION_ID, RA.STATUS as RECEIPT_APP_STATUS
from AR_RECEIVABLE_APPLICATIONS_ALL RA 
where RA.STATUS IN ('UNAPP','ACC')
AND NVL(RA.CONFIRMED_FLAG, 'Y') = 'Y'
)
, vARSchedules AS
(
  SELECT aps.PAYMENT_SCHEDULE_ID,
   aps.ORG_ID,
   aps.CUSTOMER_ID,
   aps.CLASS, /*INV for Invoice, DM for Debit Memo, CM for Credit Memo, CB for Chargeback, PMT for receipt and BR for bills receivable.*/
   aps.CUSTOMER_TRX_ID, /*Using the CUSTOMER_TRX_ID foreign key column, the AR_PAYMENT_SCHEDULES_ALL table joins to RA_CUSTOMER_TRX_ALL table for nonpayment transaction entries, such as the creation of credit memos, debit memos, invoices, or chargebacks.*/
   aps.CUSTOMER_SITE_USE_ID,
   aps.CASH_RECEIPT_ID,  /*Using the CASH_RECEIPT_ID foreign key column, the AR_PAYMENT_SCHEDULES_ALL table joins to the AR_CASH_RECEIPTS_ALL table for invoice-related payment transactions.*/
   APS.amount_due_original AMOUNT_DUE_ORIGINAL,

   APS.acctd_amount_due_remaining ACCTD_AMOUNT_DUE_REMAINING,
   APS.amount_due_remaining AMOUNT_DUE_REMAINING, /*The sum of the AMOUNT_DUE_REMAINING column for a customer for all confirmed payment schedules reflects the current customer balance.If this amount is negative, then the AMOUNT_DUE_REMAINING column indicates the credit balance amount currently available for this customer. Receivables stores debit items such as invoices, debit memos, chargebacks, deposits, and guarantees as positive numbers in the AMOUNT_DUE_REMAINING and AMOUNT_DUE_ORIGINAL columns. Credit items such as credit memos and receipts are stored as negative numbers. */
   
   ACH.acctd_amount as ACH_ACCTD_AMOUNT_DUE_REMAINING,
   ACH.amount as ACH_AMOUNT_DUE_REMAINING,
   
   aps.AMOUNT_APPLIED, /*When a receipt is applied, Receivables updates the AMOUNT_APPLIED, AMOUNT_DUE_REMAINING, and STATUS columns.*/
   aps.STATUS,
   aps.RECEIPT_CONFIRMED_FLAG, /*Receipts are confirmed or not confirmed as designated by the CONFIRMED_FLAG*/
   aps.TERM_ID,
   aps.TERMS_SEQUENCE_NUMBER, /*For invoices with split terms, Oracle Receivables creates one record in the RA_CUSTOMER_TRX_ALL table and one record in the AR_PAYMENT_SCHEDULES_ALL table for each installment. In the AR_PAYMENT_SCHEDULES_ALL table, the DUE_DATE and AMOUNT_DUE_REMAINING columns can differ for each installment of a split term invoice. Each installment is differentiated by the TERMS_SEQUENCE_NUMBER column.*/
   APS.due_date DUE_DATE,
   aps.REVERSED_CASH_RECEIPT_ID, /*If you create a debit memo reversal when you reverse a receipt, Receivables creates a new payment schedule record for the debit memo and populates the REVERSED_CASH_RECEIPT_ID column with the CASH_RECEIPT_ID column for the reversed receipt.*/
   aps.ASSOCIATED_CASH_RECEIPT_ID, /*Receivables creates a new payment schedule record when you create a chargeback. The ASSOCIATED_CASH_RECEIPT_ID column is the cash receipt of the payment you entered when you created the chargeback. */
   APS.GL_DATE,
   APS.GL_DATE_CLOSED, /*The ACTUAL_DATE_CLOSED column gives the date you applied a payment or credit to an open transaction that set the AMOUNT_DUE_REMAINING column to 0 for that transaction. The GL_DATE_CLOSED column indicates the accounting date the transaction was closed.*/
   aps.ACTUAL_DATE_CLOSED,
   aps.INVOICE_CURRENCY_CODE,
   APS.tax_original TAX_ORIGINAL,
   APS.tax_remaining TAX_REMAINING,
   round(APS.tax_remaining * NVL(APS.exchange_rate,1),2) as acctd_tax_remaining,
   APS.EXCHANGE_DATE,
   APS.EXCHANGE_RATE,

   rt.NAME as TERM_NAME,

   vOrg.LEDGER_NAME,
   vOrg.LEDGER_CURRENCY,
   
   RCTA.bill_to_customer_id as BILL_TO_CUSTOMER_ID,
   RCTA.bill_to_site_use_id as BILL_TO_SITE_USE_ID,
   RCTA.complete_flag as TRX_COMPLETE_FLAG,
   HOU.name as BUSINESS_UNIT,
   
   Decode(CTT.TYPE,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',CTT.TYPE) TRANSACTION_CLASS,
   CTT.name TRANSACTION_TYPE,
   
   RCTA.trx_date TRX_DATE,
   RCTA.trx_number TRX_NUMBER,
   RCTA.PURCHASE_ORDER,
   
   acr.RECEIVABLES_TRX_ID,
   acr.RECEIPT_NUMBER,
   acr.RECEIPT_DATE,
   ach.CASH_RECEIPT_HISTORY_ID,
   ach.status as RECEIPT_STATUS,
   
   RM.RECEIPT_METHOD_ID,
   rm.NAME as RECEIPT_METHOD
   
   
FROM AR_PAYMENT_SCHEDULES_ALL APS
JOIN vOrg
   ON vOrg.org_id = aps.org_id
JOIN HR_ALL_ORGANIZATION_UNITS_TL HOU
   ON aps.ORG_ID = hou.organization_id

/*invoices*/
LEFT OUTER JOIN RA_CUSTOMER_TRX_ALL RCTA
  ON RCTA.customer_trx_id = aps.customer_trx_id
LEFT OUTER JOIN RA_CUST_TRX_TYPES_ALL CTT
   ON RCTA.CUST_TRX_TYPE_SEQ_ID = ctt.CUST_TRX_TYPE_SEQ_ID

/*receipts*/
LEFT OUTER JOIN AR_CASH_RECEIPTS_ALL ACR
   on APS.CASH_RECEIPT_ID = ACR.CASH_RECEIPT_ID
   AND NVL(aps.RECEIPT_CONFIRMED_FLAG, 'Y')='Y' /*confirmed receipts only*/
LEFT OUTER JOIN AR_CASH_RECEIPT_HISTORY_ALL ACH
  ON acr.cash_receipt_id = ach.cash_receipt_id
  AND ach.current_record_flag = 'Y'
LEFT OUTER JOIN AR_RECEIPT_METHODS RM
  ON RM.RECEIPT_METHOD_ID=ACR.RECEIPT_METHOD_ID

LEFT OUTER JOIN RA_TERMS rt
  ON rt.TERM_ID = APS.TERM_ID

WHERE  
	(
	  aps.status = 'OP' /*open only*/
	  OR
	  (
	   aps.status = 'CL'
	   AND ach.status = 'REMITTED'
	   and ach.current_record_flag = 'Y'
	   and rm.NAME in ('Direct Debit','Direct Debit1','Direct-Debit')
	   )
	)
)
, vBase as (
 Select vARSchedules.BUSINESS_UNIT as BUSINESS_UNIT,
 vCustomer.ACCOUNT_NUMBER,
 vCustomer.ACCOUNT_NAME,
(case when STATUS='OP' then ACCTD_AMOUNT_DUE_REMAINING end) as ACCTD_AMOUNT_DUE_REMAINING,
(case when STATUS='OP' then AMOUNT_DUE_REMAINING end) as AMOUNT_DUE_REMAINING,

CREDIT_CLASSIFICATION,

/*below is by trx*/
 vARSchedules.CLASS,
 case when class = 'PMT' then RECEIPT_NUMBER else TRX_NUMBER end as TRX_NUMBER,
 case when class = 'PMT' then RECEIPT_DATE else TRX_DATE end as TRX_DATE,
 TRANSACTION_CLASS,
 TRANSACTION_TYPE,
 RECEIPT_STATUS,
 vARSchedules.RECEIPT_METHOD as PMT_RECEIPT_METHOD,
 --SCHEDULE_TYPE,
 STATUS,
 INVOICE_CURRENCY_CODE,
 TERM_NAME,
 TERM_ID,
 DUE_DATE,
 LEDGER_CURRENCY,
 vARSchedules.EXCHANGE_RATE,
 vARSchedules.EXCHANGE_DATE,
 PAYMENT_SCHEDULE_ID,
 CUSTOMER_TRX_ID,
 CASH_RECEIPT_ID,
 CASH_RECEIPT_HISTORY_ID,
 vARSchedules.RECEIPT_METHOD_ID,
 vCustomer.CUST_ACCOUNT_ID,
 vARSchedules.CUSTOMER_SITE_USE_ID,
 vRMCustomer.CUST_RECEIPT_METHOD_NAME,
 NVL(vARSchedules.RECEIPT_METHOD,vRMCustomer.CUST_RECEIPT_METHOD_NAME) as RECEIPT_METHOD,
 GL_DATE,
 tax_remaining,
 acctd_tax_remaining,
 
 vARSchedules.PURCHASE_ORDER,
 
 case when (trunc(sysdate) - trunc(due_date)) < 1 then (case when STATUS='OP' then AMOUNT_DUE_REMAINING end) else 0 end as current_due_remaining,
 case when (trunc(sysdate) - trunc(due_date)) < 1 then (case when STATUS='OP' then ACCTD_AMOUNT_DUE_REMAINING end) else 0 end as current_acct_due_remaining,
 case when (trunc(sysdate) - trunc(due_date)) between 1 and 10  then (case when STATUS='OP' then AMOUNT_DUE_REMAINING end) else 0 end as bucket_1_10_due_remaining,
 case when (trunc(sysdate) - trunc(due_date)) between 1 and 10  then (case when STATUS='OP' then ACCTD_AMOUNT_DUE_REMAINING end) else 0 end as bucket_1_10_acct_due_remaining
 
From vCustomer
join vARSchedules
on vCustomer.CUST_ACCOUNT_ID=vARSchedules.CUSTOMER_ID
LEFT OUTER JOIN vRMCustomer
  ON vARSchedules.CUSTOMER_ID=vRMCustomer.CUSTOMER_ID
  AND vARSchedules.CUSTOMER_SITE_USE_ID=vRMCustomer.SITE_USE_ID

WHERE (BUSINESS_UNIT IN (:Operating_Unit) OR 'All' IN (:Operating_Unit || 'All')) 
AND  (ACCOUNT_NAME IN (:Customer_Name) OR 'All' IN (:Customer_Name || 'All'))
AND  (ACCOUNT_NUMBER IN (:Customer_Number) OR 'All' IN (:Customer_Number || 'All'))
AND  (NVL(vARSchedules.RECEIPT_METHOD,vRMCustomer.CUST_RECEIPT_METHOD_NAME) IN (:P_RECEIPT_METHOD) OR 'All' IN (:P_RECEIPT_METHOD|| 'All'))
AND DUE_DATE <= NVL(:P_DUE_DATE,DUE_DATE)
AND (vARSchedules.CLASS IN (:P_TRX_CLASS) OR 'All' IN (:P_TRX_CLASS || 'All')) /*INV for Invoice, DM for Debit Memo, CM for Credit Memo, CB for Chargeback, PMT for receipt and BR for bills receivable.*/
)
select vBase.*
/*trx only*/
, TRUNC(SYSDATE) - DUE_DATE AS DAYS_LATE
, CASE WHEN TRUNC(SYSDATE)-(DUE_DATE+1) < 0 THEN 'N' ELSE 'Y' END AS OVERDUE_FLAG
 from vBase

where status='OP' 

ORDER BY BUSINESS_UNIT, ACCOUNT_NAME, TRX_DATE
