WITH  date_range AS
      (
        SELECT TRUNC(CAST(:P_END_DATE as DATE),'MM')-1 as date_from_exclusive
        , CAST(:P_END_DATE as DATE) as date_to_inclusive
        FROM DUAL
      ),
	  vOrg as (
		SELECT /*+ materialize */ o2.organization_id as ORG_ID,
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
			AND o2.organization_id IN (:P_BUSINESS_UNIT /*300000001720626*/)
		),
      payment_schedules AS
      (
	  SELECT ps.org_id,
              ps.gl_date,
              ps.gl_date_closed,
              ps.class ps_class,
              ps.cash_receipt_id,
              ps.receipt_confirmed_flag,
              ps.customer_trx_id,
              ps.payment_schedule_id,
			  ps.acctd_amount_due_remaining,
			  ps.amount_due_remaining,
			  ps.due_date,
			  ps.trx_number,
			  ps.trx_date,
			  ps.invoice_currency_code,
			  round(ps.exchange_rate,5) as exchange_rate,
			  round(ps.amount_due_original * NVL(ps.exchange_rate,1),2) as acctd_amount_due_original,
			  ps.amount_due_original,
			  ps.customer_id,
			  ps.tax_original,
			  ps.tax_remaining,
			  round(ps.tax_remaining * NVL(ps.exchange_rate,1),2) as acctd_tax_remaining,
			  ps.cust_trx_type_seq_id
      FROM ar_payment_schedules_all ps
	  CROSS JOIN date_range
      WHERE ps.gl_date_closed   >=  date_from_exclusive
      AND ps.org_id             IN (:P_BUSINESS_UNIT /*300000001720626*/)
      AND ps.gl_date            <=  date_to_inclusive
      ),
      ps_transactions AS
      (
	  SELECT ps.org_id,
            ps.PAYMENT_SCHEDULE_ID,
            ps.gl_date,
            ps.gl_date_closed,
            ps.ps_class ps_class,
            ps.cash_receipt_id,
            ps.receipt_confirmed_flag,
            ps.customer_trx_id,
            ps.acctd_amount_due_remaining,
			ps.amount_due_remaining,
            trx.trx_class,
			trx.trx_number,
			trx.trx_date,
			ps.invoice_currency_code,
			ps.amount_due_original,
			ps.acctd_amount_due_original,
			ps.customer_id,
			ps.due_date,
			types.name as transaction_type,
			ps.tax_remaining,
			ps.acctd_tax_remaining
        FROM ra_customer_trx_all trx,
           ra_cust_trx_types_all types,
           payment_schedules ps
        WHERE ps.customer_trx_id          = trx.customer_trx_id
        AND ps.org_id =  trx.org_id
        AND trx.cust_trx_type_seq_id     = types.cust_trx_type_seq_id
        AND types.post_to_gl             = 'Y'
        AND types.accounting_affect_flag = 'Y'
         AND nvl(trx.intercompany_flag,'N') <> 'Y'
      ),
      receipt_appln AS
      (
	  SELECT ra.gl_date ra_gl_date,
               ps.gl_date ps_gl_date,
               ps.org_id,
               ps.gl_date_closed,
               ra.acctd_amount_applied_to,
               ra.acctd_earned_discount_taken,
               ra.acctd_unearned_discount_taken,
               ra.acctd_amount_applied_from,
			   ra.amount_applied,
               ra.earned_discount_taken,
               ra.unearned_discount_taken,
               ra.amount_applied_from,
               ra.status,
               ra.application_type,
               ps.ps_class,
               ps.trx_class,
               ra.applied_payment_schedule_id,
               ps.payment_schedule_id as ps_payment_schedule_id,
               ra.payment_schedule_id as ra_payment_schedule_id,
			   ps.trx_number,
			   ps.trx_date,
			   ps.customer_id,
			   ps.due_date,
			   ps.transaction_type,
			   ps.invoice_currency_code,
			   ra.tax_applied as tax_remaining,
			   case when ra.amount_applied = 0 then 0 else ra.tax_applied *  ra.acctd_amount_applied_to / ra.amount_applied end as acctd_tax_remaining
         FROM ar_receivable_applications_all ra
		 JOIN ps_transactions ps
		   ON ra.applied_payment_schedule_id = ps.payment_schedule_id
		   AND ps.org_id = ra.org_id
		 CROSS JOIN date_range
         WHERE ra.gl_date >   date_from_exclusive
         AND ra.org_id IN  (:P_BUSINESS_UNIT /*300000001720626*/)
         AND NVL(ra.confirmed_flag,'Y') = 'Y'
         AND ra.status IN ('APP','ACTIVITY')
       UNION ALL
         SELECT ra.gl_date ra_gl_date,
               ps.gl_date ps_gl_date,
               ps.org_id,
               ps.gl_date_closed,
               ra.acctd_amount_applied_to,
               ra.acctd_earned_discount_taken,
               ra.acctd_unearned_discount_taken,
               ra.acctd_amount_applied_from,
			   ra.amount_applied,
               ra.earned_discount_taken,
               ra.unearned_discount_taken,
               ra.amount_applied_from,			   
               ra.status,
               ra.application_type,
               ps.ps_class,
               ps.trx_class,
               ra.applied_payment_schedule_id,
               ps.payment_schedule_id as ps_payment_schedule_id,
               ra.payment_schedule_id as ra_payment_schedule_id,
			   ps.trx_number,
			   ps.trx_date,
			   ps.customer_id,
			   ps.due_date,
			   ps.transaction_type,
			   ps.invoice_currency_code,
			   ra.tax_applied as tax_remaining,
			   case when ra.amount_applied = 0 then 0 else ra.tax_applied *  ra.acctd_amount_applied_to / ra.amount_applied end as acctd_tax_remaining
         FROM ar_receivable_applications_all ra
		 JOIN ps_transactions ps
		   ON ra.payment_schedule_id = ps.payment_schedule_id
		   AND ps.org_id = ra.org_id
		 CROSS JOIN date_range
         WHERE ra.gl_date >   date_from_exclusive
         AND ra.org_id IN  (:P_BUSINESS_UNIT /*300000001720626*/)
         AND NVL(ra.confirmed_flag,'Y') = 'Y'
         AND ra.status IN ('APP','ACTIVITY')
      ),
      invoices AS 
	  (
	    SELECT 'Invoices' as current_schedule, ps_trx.org_id, ps_trx.trx_number, ps_trx.trx_date, ps_trx.gl_date, ps_trx.acctd_amount_due_original,ps_trx.customer_id,ps_trx.due_date,ps_trx.transaction_type,ps_trx.invoice_currency_code,
           CASE
               WHEN ps_trx.gl_date      <=  date_from_exclusive
               AND ps_trx.gl_date_closed >  date_from_exclusive
               THEN 1 * ps_trx.acctd_amount_due_remaining
           END as acctd_start_bal,
           CASE
               WHEN ps_trx.gl_date      <=  date_to_inclusive
               AND ps_trx.gl_date_closed >  date_to_inclusive
               THEN 1 * ps_trx.acctd_amount_due_remaining
            END as acctd_end_bal,
			 CASE
               WHEN ps_trx.gl_date      <=  date_from_exclusive
               AND ps_trx.gl_date_closed >  date_from_exclusive
               THEN 1 * ps_trx.amount_due_remaining
           END as start_bal,
           CASE
               WHEN ps_trx.gl_date      <=  date_to_inclusive
               AND ps_trx.gl_date_closed >  date_to_inclusive
               THEN 1 * ps_trx.amount_due_remaining
            END as end_bal,
			CASE
               WHEN ps_trx.gl_date      <=  date_from_exclusive
               AND ps_trx.gl_date_closed >  date_from_exclusive
               THEN 1 * ps_trx.acctd_tax_remaining
           END as acctd_tax_start_bal,
           CASE
               WHEN ps_trx.gl_date      <=  date_to_inclusive
               AND ps_trx.gl_date_closed >  date_to_inclusive
               THEN 1 * ps_trx.acctd_tax_remaining
            END as acctd_tax_end_bal,
			 CASE
               WHEN ps_trx.gl_date      <=  date_from_exclusive
               AND ps_trx.gl_date_closed >  date_from_exclusive
               THEN 1 * ps_trx.tax_remaining
           END as tax_start_bal,
           CASE
               WHEN ps_trx.gl_date      <=  date_to_inclusive
               AND ps_trx.gl_date_closed >  date_to_inclusive
               THEN 1 * ps_trx.tax_remaining
            END as tax_end_bal
        FROM ps_transactions ps_trx
		CROSS JOIN date_range
        WHERE ps_trx.trx_class IN ( 'CB', 'CM','DEP','DM','GUAR','INV','BR', DECODE( 'Y', 'Y', 'ONACC','N'))
	  ),
	  applied_receipts AS
	  (
	    SELECT  'Applied Receipts' as current_schedule,  ra.org_id, ra.trx_number, ra.trx_date,ra.ps_gl_date, ra.acctd_amount_applied_from as acctd_amount_due_original,ra.customer_id,ra.due_date,ra.transaction_type,ra.invoice_currency_code,
           CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               AND ra.ra_gl_date        >  date_from_exclusive
               THEN (ra.acctd_amount_applied_to + NVL(ra.acctd_earned_discount_taken,0) + NVL(ra.acctd_unearned_discount_taken,0))
           END as acctd_start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               AND ra.ra_gl_date        >  date_to_inclusive
               THEN (ra.acctd_amount_applied_to + NVL(ra.acctd_earned_discount_taken,0) + NVL(ra.acctd_unearned_discount_taken,0))
           END as acctd_end_bal,
		   CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               AND ra.ra_gl_date        >  date_from_exclusive
               THEN (ra.amount_applied + NVL(ra.earned_discount_taken,0) + NVL(ra.unearned_discount_taken,0))
           END as start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               AND ra.ra_gl_date        >  date_to_inclusive
               THEN (ra.amount_applied + NVL(ra.earned_discount_taken,0) + NVL(ra.unearned_discount_taken,0))
           END as end_bal,
			CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               THEN ra.acctd_tax_remaining
           END as acctd_tax_start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               THEN ra.acctd_tax_remaining
            END as acctd_tax_end_bal,
			 CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               THEN ra.tax_remaining
           END as tax_start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               THEN ra.tax_remaining
            END as tax_end_bal
        FROM receipt_appln ra
		CROSS JOIN date_range
        WHERE ra.status = 'APP'
        AND ra.APPLIED_PAYMENT_SCHEDULE_ID = ra.PS_PAYMENT_SCHEDULE_ID
        AND ps_class IN ( 'CB', 'CM','DEP','DM','GUAR','INV','BR')
        AND decode('Y' , 'Y' ,'Y' , 'N' ,decode (  trx_class , 'ONACC','N', 'Y') ) = 'Y'
	  ),
      applied_credits as
	  (
	     SELECT 'Applied Credit Memo',  ra.org_id, ra.trx_number, ra.trx_date, ra.ps_gl_date, ra.acctd_amount_applied_from as acctd_amount_due_original,ra.customer_id,ra.due_date,ra.transaction_type,ra.invoice_currency_code,
          CASE
            WHEN ra.ps_gl_date      <=  date_from_exclusive
            AND ra.gl_date_closed >  date_from_exclusive
            AND ra.ra_gl_date        >  date_from_exclusive
            THEN -1* ra.acctd_amount_applied_from
          END as acctd_start_bal,
          CASE
            WHEN ra.ps_gl_date      <=  date_to_inclusive
            AND ra.gl_date_closed >  date_to_inclusive
            AND ra.ra_gl_date        >  date_to_inclusive
            THEN -1* ra.acctd_amount_applied_from
          END as acctd_end_bal,
		  CASE
            WHEN ra.ps_gl_date      <=  date_from_exclusive
            AND ra.gl_date_closed >  date_from_exclusive
            AND ra.ra_gl_date        >  date_from_exclusive
            THEN -1* ra.amount_applied
          END as start_bal,
          CASE
            WHEN ra.ps_gl_date      <=  date_to_inclusive
            AND ra.gl_date_closed >  date_to_inclusive
            AND ra.ra_gl_date        >  date_to_inclusive
            THEN -1* ra.amount_applied
          END as end_bal,
		  CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               THEN ra.acctd_tax_remaining
           END as acctd_tax_start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               THEN ra.acctd_tax_remaining
            END as acctd_tax_end_bal,
			 CASE
               WHEN ra.ps_gl_date      <=  date_from_exclusive
               AND ra.gl_date_closed >  date_from_exclusive
               THEN ra.tax_remaining
           END as tax_start_bal,
           CASE
               WHEN ra.ps_gl_date      <=  date_to_inclusive
               AND ra.gl_date_closed >  date_to_inclusive
               THEN ra.tax_remaining
            END as tax_end_bal
        FROM receipt_appln ra
		CROSS JOIN date_range
        WHERE ra.application_type  = 'CM'
        AND ra.RA_PAYMENT_SCHEDULE_ID = ra.PS_PAYMENT_SCHEDULE_ID
        AND decode('Y' , 'Y' ,'Y' , 'N' ,decode ( trx_class , 'ONACC','N', 'Y') ) = 'Y'
	  ),
	  adjustments AS
	  (
	    SELECT 'Adjustements' as current_schedule, ps.org_id, ps.trx_number, ps.trx_date, ps.gl_date, ps.acctd_amount_due_original,ps.customer_id,ps.due_date,'Adjustement' as transaction_type,ps.invoice_currency_code,
          CASE
            WHEN ps.gl_date      <=  date_from_exclusive
            AND ps.gl_date_closed >  date_from_exclusive
            AND adj.gl_date       >  date_from_exclusive
            THEN -1* adj.acctd_amount
          END as acctd_start_bal,
          CASE
            WHEN ps.gl_date      <=  date_to_inclusive
            AND ps.gl_date_closed >  date_to_inclusive
            AND adj.gl_date       >  date_to_inclusive
            THEN -1* adj.acctd_amount
          END as acctd_end_bal,
			CASE
            WHEN ps.gl_date      <=  date_from_exclusive
            AND ps.gl_date_closed >  date_from_exclusive
            AND adj.gl_date       >  date_from_exclusive
            THEN -1* adj.amount
          END as start_bal,
          CASE
            WHEN ps.gl_date      <=  date_to_inclusive
            AND ps.gl_date_closed >  date_to_inclusive
            AND adj.gl_date       >  date_to_inclusive
            THEN -1* adj.amount
          END as end_bal,
		  0 as acctd_tax_start_bal,
		  0 as acctd_tax_end_bal,
		  0 as tax_start_bal,
		  0 as tax_end_bal
      FROM ps_transactions ps
	  JOIN ar_adjustments_all adj
	    ON adj.payment_schedule_id = ps.payment_schedule_id
	  CROSS JOIN date_range
      WHERE NOT EXISTS
        (select 1
	    FROM RA_CUSTOMER_TRX_LINES_ALL trxl, ar_transaction_history_all his
	    where trxl.customer_trx_id       = his.customer_trx_id
            AND his.current_record_flag      = 'Y'
            AND his.event                    = 'CANCELLED'
            AND adj.receivables_trx_id       = '-15'
            AND trxl.BR_REF_CUSTOMER_TRX_ID  = adj.customer_trx_id
            AND trxl.BR_REF_CUSTOMER_TRX_ID is not null
        )
      AND adj.gl_date >  date_from_exclusive
      AND adj.org_id = ps.org_id
      AND adj.org_id               IN (:P_BUSINESS_UNIT /*300000001720626*/)
      AND ps.ps_class IN (  'CB','CM','DEP','DM','GUAR','INV','BR')
      AND adj.status     = 'A'
	  ),
	  unapplied AS
	  (
	    SELECT 'Unapplied and Unidentified' as current_schedule,  ps.org_id, ps.trx_number, ps.trx_date, ra.gl_date, ps.acctd_amount_due_original,ps.customer_id,ps.due_date,'Receipt' as transaction_type,ps.invoice_currency_code,
            CASE
              WHEN ra.gl_date      <=  date_from_exclusive
              AND ps.gl_date_closed >  date_from_exclusive
              THEN -1 * ra.acctd_amount_applied_FROM
            END as acctd_start_bal,
            CASE
              WHEN ps.gl_date      <=  date_to_inclusive
              AND ps.gl_date_closed >  date_to_inclusive
              THEN -1 * ra.acctd_amount_applied_FROM
           END as acctd_end_bal,
		   CASE
              WHEN ra.gl_date      <=  date_from_exclusive
              AND ps.gl_date_closed >  date_from_exclusive
              THEN -1 * ra.amount_applied
            END as start_bal,
            CASE
              WHEN ps.gl_date      <=  date_to_inclusive
              AND ps.gl_date_closed >  date_to_inclusive
              THEN -1 * ra.amount_applied
           END as end_bal,
		   0 as acctd_tax_start_bal,
		   0 as acctd_tax_end_bal,
		   0 as tax_start_bal,
		   0 as tax_end_bal
      FROM  payment_schedules ps
	  JOIN ar_receivable_applications_all ra
	    ON ps.cash_receipt_id = ra.cash_receipt_id
		AND ps.org_id = ra.org_id
	  CROSS JOIN date_range
      WHERE  ra.gl_date    <=  date_to_inclusive
       AND ( case  when 'Y' = 'Y' then  ra.status  end  in ( 'UNAPP', 'UNID',    'OTHER ACC' )
              or case  when 'Y' = 'Y'  then ra.status end in ('ACC') )
       AND  NVL(ra.confirmed_flag, 'Y') = 'Y'
       AND  ps.ps_class = 'PMT'
       AND  ps.gl_date_closed >=  date_from_exclusive
       AND  ra.org_id in (:P_BUSINESS_UNIT /*300000001720626*/)
       AND  NVL( ps.receipt_confirmed_flag, 'Y' ) = 'Y'
	  ),
	  begin_end_bal as
      (
	  SELECT * from invoices
      UNION ALL
      SELECT * from applied_receipts
      UNION ALL
      SELECT * from applied_credits
      UNION ALL
      SELECT * from adjustments
      UNION ALL
      SELECT * from unapplied
      )
	  , vBase as
	  (
    select /*+ parallel*/  
	
	     vOrg.org_name as business_unit,
	     bal.current_schedule,
	     NVL(cust.account_number,'Unspecified') as account_number,
	     nvl(cust.account_name,'Unspecified') as account_name,
		 bal.trx_number,
		 bal.trx_date,
		 bal.gl_date,
		 bal.invoice_currency_code,
		 vOrg.ledger_currency,
	     bal.acctd_amount_due_original,
         bal.acctd_start_bal,
		 bal.acctd_end_bal,
		 NVL((bal.acctd_end_bal),0) - NVL((bal.acctd_start_bal),0) as acctd_mvt_amount,
         
		 NVL(bal.acctd_end_bal,0) - NVL(acctd_tax_end_bal,0) as acctd_net_remaining, 
		 NVL(acctd_tax_end_bal,0) as acctd_tax_remaining,
		 NVL(bal.acctd_end_bal,0) as acctd_gross_remaining,
		 
		 NVL(bal.end_bal,0) - NVL(tax_end_bal,0) as net_remaining,
		 NVL(bal.tax_end_bal,0) as tax_remaining,
		 NVL(bal.end_bal,0) as gross_remaining,
		 
		 case when bal.current_schedule = 'Applied Receipts' and bal.acctd_end_bal <> 0 then 'Invoices'
			else bal.current_schedule
			end as transaction_class,
			
		 bal.transaction_type,
		 bal.customer_id,
		 bal.due_date,
		 date_to_inclusive,
 		 (date_to_inclusive - trunc(due_date)) as days_outstanding
		 
    from begin_end_bal bal
	left outer join hz_cust_accounts cust 
	  on cust.cust_account_id = bal.customer_id
	cross join date_range
	join vOrg
	  on vOrg.org_id = bal.org_id
	where bal.acctd_end_bal is not null
	and bal.acctd_end_bal <> 0 -- remove
	)
	, vBase2 as
	(
	SELECT business_unit
	, current_schedule
	, account_number
	, account_name
	, trx_number
	, trx_date
	, gl_date
	, invoice_currency_code
	, ledger_currency
	, transaction_class
	, transaction_type
	, due_date
	, days_outstanding
	
	, acctd_start_bal
	, acctd_mvt_amount
	, acctd_end_bal
	
	, acctd_net_remaining
	, acctd_tax_remaining
	, acctd_gross_remaining
	
	, net_remaining
	, tax_remaining
	, gross_remaining
	
	/*net amounts in ledger currency*/
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(acctd_net_remaining,0)     else 0 end as acctd_net_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(acctd_net_remaining,0)     else 0 end as acctd_net_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(acctd_net_remaining,0)     else 0 end as acctd_net_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(acctd_net_remaining,0)     else 0 end as acctd_net_bucket_61_90
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(acctd_net_remaining,0)     else 0 end as acctd_net_bucket_90plus

	/*tax amounts in ledger currency*/
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(acctd_tax_remaining,0)    else 0 end as acctd_tax_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(acctd_tax_remaining,0)    else 0 end as acctd_tax_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(acctd_tax_remaining,0)    else 0 end as acctd_tax_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(acctd_tax_remaining,0)    else 0 end as acctd_tax_bucket_61_90
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(acctd_tax_remaining,0)    else 0 end as acctd_tax_bucket_90plus

    /*gross amounts in ledger currency */
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(acctd_gross_remaining,0)  else 0 end as acctd_gross_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(acctd_gross_remaining,0)  else 0 end as acctd_gross_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(acctd_gross_remaining,0)  else 0 end as acctd_gross_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(acctd_gross_remaining,0)  else 0 end as acctd_gross_bucket_61_90 
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(acctd_gross_remaining,0)  else 0 end as acctd_gross_bucket_90plus
	
	/* net amounts in trx currency*/
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(net_remaining,0)    else 0 end as net_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(net_remaining,0)    else 0 end as net_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(net_remaining,0)    else 0 end as net_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(net_remaining,0)    else 0 end as net_bucket_61_90
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(net_remaining,0)    else 0 end as net_bucket_90plus

	/*tax amounts in trx currency*/
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(tax_remaining,0)    else 0 end as tax_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(tax_remaining,0)    else 0 end as tax_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(tax_remaining,0)    else 0 end as tax_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(tax_remaining,0)    else 0 end as tax_bucket_61_90
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(tax_remaining,0)    else 0 end as tax_bucket_90plus

	/*gross amounts in trx currency */
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(gross_remaining,0)  else 0 end as gross_bucket_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(gross_remaining,0)  else 0 end as gross_bucket_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(gross_remaining,0)  else 0 end as gross_bucket_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(gross_remaining,0)  else 0 end as gross_bucket_61_90 
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(gross_remaining,0)  else 0 end as gross_bucket_90plus
	
	/*amounts without tax reallocation*/
	, case when (date_to_inclusive - trunc(due_date)) < 1               then NVL(acctd_end_bal,0)     else 0 end as acctd_end_bal_current
	, case when (date_to_inclusive - trunc(due_date)) between 1 and 30  then NVL(acctd_end_bal,0)     else 0 end as acctd_end_bal_1_30
	, case when (date_to_inclusive - trunc(due_date)) between 31 and 60 then NVL(acctd_end_bal,0)     else 0 end as acctd_end_bal_31_60
	, case when (date_to_inclusive - trunc(due_date)) between 61 and 90 then NVL(acctd_end_bal,0)     else 0 end as acctd_end_bal_61_90
	, case when (date_to_inclusive - trunc(due_date)) > 90              then NVL(acctd_end_bal,0)     else 0 end as acctd_end_bal_90plus

	, SUM(acctd_net_remaining) over () as total_acctd_net_remaining
	, SUM(acctd_gross_remaining) over () as total_acctd_gross_remaining	
	, SUM(acctd_end_bal) over () as total_acctd_end_bal
	
	FROM vBase
	where (trx_number=:P_TRX_NUMBER OR :P_TRX_NUMBER IS NULL)
	and (transaction_class=:P_CLASS OR :P_CLASS IS NULL)
	and (account_number=:P_CUST_NUM OR :P_CUST_NUM IS NULL)
	and (account_name=:P_CUSTOMER OR :P_CUSTOMER IS NULL)
	)
SELECT business_unit
	, current_schedule
	, account_number
	, account_name
	, trx_number
	, trx_date
	, gl_date
	, invoice_currency_code
	, ledger_currency
	, transaction_class
	, transaction_type
	, due_date
	, days_outstanding
	, sum(acctd_start_bal           ) as acctd_start_bal      
	, sum(acctd_mvt_amount          ) as acctd_mvt_amount     
	, sum(acctd_end_bal             ) as acctd_end_bal        
	, sum(acctd_net_remaining       ) as acctd_net_remaining  
	, sum(acctd_tax_remaining       ) as acctd_tax_remaining  
	, sum(acctd_gross_remaining     ) as acctd_gross_remaining
	, sum(net_remaining             ) as net_remaining        
	, sum(tax_remaining             ) as tax_remaining        
	, sum(gross_remaining           ) as gross_remaining      
    , sum(acctd_net_bucket_current	) as acctd_net_bucket_current	
    , sum(acctd_net_bucket_1_30     ) as acctd_net_bucket_1_30     
    , sum(acctd_net_bucket_31_60    ) as acctd_net_bucket_31_60    
    , sum(acctd_net_bucket_61_90    ) as acctd_net_bucket_61_90    
    , sum(acctd_net_bucket_90plus   ) as acctd_net_bucket_90plus   
    , sum(acctd_tax_bucket_current  ) as acctd_tax_bucket_current  
    , sum(acctd_tax_bucket_1_30     ) as acctd_tax_bucket_1_30     
    , sum(acctd_tax_bucket_31_60    ) as acctd_tax_bucket_31_60    
    , sum(acctd_tax_bucket_61_90    ) as acctd_tax_bucket_61_90    
    , sum(acctd_tax_bucket_90plus   ) as acctd_tax_bucket_90plus   
    , sum(acctd_gross_bucket_current) as acctd_gross_bucket_current
    , sum(acctd_gross_bucket_1_30   ) as acctd_gross_bucket_1_30   
    , sum(acctd_gross_bucket_31_60  ) as acctd_gross_bucket_31_60  
    , sum(acctd_gross_bucket_61_90  ) as acctd_gross_bucket_61_90  
    , sum(acctd_gross_bucket_90plus ) as acctd_gross_bucket_90plus 
    , sum(net_bucket_current        ) as net_bucket_current        
    , sum(net_bucket_1_30           ) as net_bucket_1_30           
    , sum(net_bucket_31_60          ) as net_bucket_31_60          
    , sum(net_bucket_61_90          ) as net_bucket_61_90          
    , sum(net_bucket_90plus         ) as net_bucket_90plus         
    , sum(tax_bucket_current        ) as tax_bucket_current        
    , sum(tax_bucket_1_30           ) as tax_bucket_1_30           
    , sum(tax_bucket_31_60          ) as tax_bucket_31_60          
    , sum(tax_bucket_61_90          ) as tax_bucket_61_90          
    , sum(tax_bucket_90plus         ) as tax_bucket_90plus         
    , sum(gross_bucket_current      ) as gross_bucket_current      
    , sum(gross_bucket_1_30         ) as gross_bucket_1_30         
    , sum(gross_bucket_31_60        ) as gross_bucket_31_60        
    , sum(gross_bucket_61_90        ) as gross_bucket_61_90        
    , sum(gross_bucket_90plus       ) as gross_bucket_90plus       
    , sum(acctd_end_bal_current     ) as acctd_end_bal_current     
    , sum(acctd_end_bal_1_30        ) as acctd_end_bal_1_30        
    , sum(acctd_end_bal_31_60       ) as acctd_end_bal_31_60       
    , sum(acctd_end_bal_61_90       ) as acctd_end_bal_61_90       
    , sum(acctd_end_bal_90plus      ) as acctd_end_bal_90plus
from vBase2
group by business_unit
	, current_schedule
	, account_number
	, account_name
	, trx_number
	, trx_date
	, gl_date
	, invoice_currency_code
	, ledger_currency
	, transaction_class
	, transaction_type
	, due_date
	, days_outstanding
having sum(acctd_end_bal) <> 0
order by business_unit, account_number, gl_date desc
