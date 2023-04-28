 

--------------Invoices Extract ------------------------------------ 

-------Payable invoice summary extract ----------------------------  

------selected information from headers table ap_invoices_all------ 

 

 

--Summary extract---- 

select  

     'Payables' Subledger,  

     'Invoices' Transaction_Type, 

      hou.name organisatin_name , 

      count(distinct ai.invoice_id) Headers_Count, 

     count(*)  Lines_Count 

from ap_invoices_all ai, 

     ap_invoice_lines_all ail, 

     hr_operating_units hou 

where 

        ai.invoice_id  = ail.invoice_id(+) 

    and hou.organization_id =ai.org_id   

    and trunc(ai.creation_date) between '01-FEB-2015' and '28-FEB-2015'   

group by 

     hou.name 

 

---Detail Extract ------- 

select distinct 

hou.name organisation_name, 

ai.creation_date, 

aps.vendor_name, 

ai.invoice_num, 

ai.invoice_amount 

from  

ap_invoices_all ai, 

ap_invoice_lines_all ail, 

hr_operating_units hou, 

ap_suppliers aps 

where trunc(ai.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

and  ai.invoice_id  = ail.invoice_id(+) 

and ai.org_id = hou.organization_id 

and ai.vendor_id = aps.vendor_id 

 

 

 

--------------Invoice Payments Extract -------------------- 

 

------Summary ---- 

select      

     'Payables' Subledger,  

     'Payments' Transaction_Type, 

      hou.name organisation_name,   

     count(distinct ac.check_id) Headers_Count, 

     count(*) Lines_Count 

from ap_checks_all ac, 

     ap_invoice_payments_all aip, 

     hr_operating_units hou 

where trunc(aip.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

    and ac.check_id = aip.check_id 

    and hou.organization_id =ac.org_id   

group by 

     hou.name 

 

 

----Invoice Payment and check details -----     

select ai.invoice_num, 

ai.creation_date invoice_creation_date, 

ai.invoice_amount,  

ai.payment_status_flag, 

aip.amount payment_amount, 

aip.remit_to_supplier_name supplier_name, 

hou.name organisation_name, 

aip.payment_num, 

ac.check_date payment_date, 

ac.check_number 

from ap_invoices_all ai 

,ap_invoice_payments_all aip 

,hr_operating_units hou 

,ap_checks_all ac 

where trunc(aip.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

and ai.invoice_id = aip.invoice_id 

and ai.org_id = hou.organization_id 

and ac.check_id = aip.check_id  

order by ai.invoice_num 

     

      

 

 

      

------------------Purchase Orders-------------------------------------- 

 

---Standard PO Summary extract ----------- 

select      

     'Purchasing' Subledger,  

     'Purchase Orders' Transaction_Type, 

       hou.name organisation_name,   

     count(distinct pha.po_header_id ) Headers_Count, 

     count(*)  Lines_Count 

from po_headers_all  pha, 

     po_lines_all  pla, 

     hr_operating_units hou 

where trunc(pha.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

    and pha.po_header_id = pla.po_header_id 

    and hou.organization_id =pha.org_id  

    and pha.type_lookup_code = 'STANDARD' 

group by 

     hou.name 

 

---- Extract Standard PO line details ---------------- 

 

select  

pha.segment1 po_number 

,pha.creation_date 

,aps.vendor_name  

,hou.name organisation_name 

,pla.line_num 

,pla.quantity po_quantity 

,pla.unit_price  

,( pla.unit_price*pla.quantity) po_line_amount 

,pla.item_description 

from  

po_headers_all pha, 

po_lines_all pla, 

ap_suppliers aps, 

hr_operating_units hou 

where  trunc(pha.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

and pha.po_header_id = pla.po_header_id 

and pha.vendor_id = aps.vendor_id 

and pha.org_id = hou.organization_id 

and pha.type_lookup_code = 'STANDARD' 

 

 

 

----------------PO Requisitions--------------- 

 

---Requisition Summary extract --------- 

select  

     hou.name Company,     

     'Purchasing' Subledger,  

     'Requisitions' Transaction_Type, 

     count(distinct prh.requisition_header_id) Headers_Count, 

     count(*)  Lines_Count 

from po_requisition_headers_all  prh, 

     po_requisition_lines_all  prl, 

     hr_operating_units hou 

where 

    prh.requisition_header_id = prl.requisition_header_id 

    and hou.organization_id =prh.org_id    

    and trunc(prh.creation_date) between '01-FEB-2015' and '28-FEB-2015'    

group by 

     hou.name 

 

 

---- PO Requisitions detail extract ------------ 

select prh.creation_date 

,prh.segment1 requisition_number  

,hou.name organisation_name  

,pap.full_name requisition_preparer 

,prl.line_num 

,prl.unit_price 

,prl.quantity 

,item_description 

,hl.location_code deliver_to_location 

 from po_requisition_headers_all  prh, 

     po_requisition_lines_all  prl, 

     hr_operating_units hou, 

     hr_locations hl, 

     per_all_people_f pap 

 where prh.requisition_header_id = prl.requisition_header_id 

    and hou.organization_id =prh.org_id    

    and prl.deliver_to_location_id = hl.location_id(+) 

    and pap.person_id = prh.preparer_id 

    and trunc(prh.creation_date) between pap.effective_start_date and pap.effective_end_date 

    and trunc(prh.creation_date) between '01-FEB-2015' and '28-FEB-2015'   

 

 

 

 

-----------------PO Receipts ---------------  

 

-----Summary receipts count-------------- 

select      

     'Purchasing' Subledger,  

     'Receipts' Transaction_Type, 

      hou.name organisation_name,   

     count(distinct rsh.shipment_header_id) Headers_Count, 

     count(*)  Lines_Count 

from rcv_shipment_headers rsh, 

     rcv_shipment_lines rsl, 

     hr_operating_units  hou, 

     po_headers_all poh 

where  trunc(rsh.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

    and  rsh.shipment_header_id = rsl.shipment_header_id 

    and poh.po_header_id = rsl.po_header_id  

    and hou.organization_id(+) = poh.org_id 

group by 

     hou.name 

 

 

----------PO Receipts detail ---------------- 

 

     select rsh.receipt_num 

     ,aps.vendor_name 

     ,hou.name orgnisation_name 

     ,(rsl.quantity_received*pla.unit_price) amount_received 

     ,rsl.quantity_received 

     , poh.segment1 po_number  

     , pla.line_num po_line_num 

     from rcv_shipment_headers rsh, 

     ap_suppliers aps, 

     rcv_shipment_lines rsl, 

     po_headers_all poh, 

     po_lines_all pla, 

     hr_operating_units hou 

     where trunc(rsh.creation_date) between '01-FEB-2015' and '28-FEB-2015' 

     and rsh.vendor_id = aps.vendor_id  

     and rsh.shipment_header_id = rsl.shipment_header_id 

     and rsl.po_header_id = poh.po_header_id 

     and rsl.po_line_id = pla.po_line_id 

     and poh.org_id = hou.organization_id 

      

  

      

      

------------------------ AR Invoices ---------------- 

    

 ------ Count of AR Transactions (AR Invoices and Credit Memos)----------   

    

   select          

     'Receivables' Subledger,  

     'Transactions' Transaction_Type, 

    hou.name  organisation_name,  

     count(distinct rct.customer_trx_id) Headers_Count, 

     count(*)  Lines_Count 

from ra_customer_trx_all rct, 

     ra_customer_trx_lines_all rctl, 

     hr_operating_units hou 

where 

    rct.customer_trx_id = rctl.customer_trx_id 

    and hou.organization_id = rct.org_id  

    and trunc(rct.creation_date) between '01-FEB-2015' AND '28-FEB-2015'     

group by 

     hou.name 

     order by 2,3 

   

   

  -----Summary by transaction class -------------- 

    select          

     'Receivables' Subledger,  

     'Transactions' Transaction_Type, 

  --   ctt.name Transaction_class, 

  decode(aps.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',aps.CLASS) Transaction_Class, 

      hou.name  organisation_name,  

     count(distinct rct.customer_trx_id) Headers_Count, 

     count(*)  Lines_Count 

from ra_customer_trx_all rct, 

     ra_customer_trx_lines_all rctl, 

     hr_operating_units hou, 

     ra_cust_trx_types_all ctt, 

     ar_payment_schedules_all aps 

where 

    rct.customer_trx_id = rctl.customer_trx_id 

    and hou.organization_id = rct.org_id  

    and rct.cust_trx_type_id = ctt.cust_trx_type_id 

    and ctt.org_id = rct.org_id 

    and aps.customer_trx_id = rct.customer_trx_id 

    and trunc(rct.creation_date) between '01-FEB-2015' AND '28-FEB-2015'     

group by 

     hou.name, 

     decode(aps.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',aps.CLASS)  

     --, ctt.name 

     order by 2,3 

 

    

---------------------AR Invoice Detail extract ------------------ 

select rct.trx_number,  

rct.creation_date, 

rct.trx_date, 

rct.invoice_currency_code, 

hp.party_name customer_name, 

hou.name organisation_name, 

ctt.name transaction_type 

,decode(aps.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',aps.CLASS) Transaction_Class 

,rctl.line_number,line_type 

,rctl.extended_amount line_amount 

,aps.status 

,aps.due_date 

,aps.amount_due_remaining 

from ra_customer_trx_all rct, 

     ra_customer_trx_lines_all rctl, 

     hr_operating_units hou, 

     ra_cust_trx_types_all ctt, 

     hz_cust_accounts hc, 

     hz_parties hp, 

     ar_payment_schedules_all aps 

where 

    rct.customer_trx_id = rctl.customer_trx_id 

    and hou.organization_id = rct.org_id  

    and rct.cust_trx_type_id = ctt.cust_trx_type_id 

    and ctt.org_id = rct.org_id 

    and rct.bill_to_customer_id = hc.cust_account_id 

    and hp.party_id = hc.party_id 

    and trunc(rct.creation_date) between '01-FEB-2015' AND '28-FEB-2015'  

    and aps.customer_trx_id = rct.customer_trx_id 

    

 

      

      

---------------------AR Receipts ----------------------------------------------------------- 

 

--AR Receipts Summary -------- 

 select  

     'Receivables' Subledger,  

     'Receipts' Transaction_Type, 

         hou.name organisation_name, 

     count(distinct acr.cash_receipt_id) Headers_Count, 

     count(*)  Lines_Count 

from AR_CASH_RECEIPTS_ALL acr,      

     hr_operating_units hou 

where 

     hou.organization_id = acr.org_id    

    and trunc(acr.creation_date) between '01-FEB-2015' AND '28-FEB-2015'    

group by 

     hou.name 

     

    -----AR Receipts Details -------------- 

      

     select hou.name organisation_name  

     , acr.creation_date 

     ,acr.receipt_number 

     ,acr.receipt_date 

     ,acr.status 

     ,acr.type 

     ,acr.amount 

     from ar_cash_receipts_all acr ,      

     hr_operating_units hou 

     where trunc(acr.creation_date) between '01-FEB-2015' AND '28-FEB-2015'  

     and  hou.organization_id = acr.org_id   

      

     

 

--------------------AR Receipt detail with Applied Trx numbers   -------------------------------------- 

 -----This will have mutiple rows for a receipt, as a receipt can be applied to muultiple invoices -------------     

      

 SELECT cr.cash_receipt_id,ct.CUSTOMER_TRX_ID, 

ps_inv.TRX_NUMBER, 

(select sum(extenDed_amount) from ra_customer_trx_lines_all 

where customer_trx_id = ct.CUSTOMER_TRX_ID) Invoice_Amount, 

cr.RECEIPT_NUMBER, 

cr.STATUS, 

cr.AMOUNT total_Receipt_amount 

FROM ar_receivable_applications_all app, 

ar_cash_receipts_all cr, 

ar_payment_schedules_all ps_inv, 

ra_customer_trx_all ct, 

ar_receivables_trx_all art 

WHERE 1=1 

AND app.cash_receipt_id = cr.cash_receipt_id 

AND ct.customer_trx_id(+) = ps_inv.customer_trx_id 

AND app.applied_payment_schedule_id = ps_inv.payment_schedule_id 

AND art.receivables_trx_id(+) = app.receivables_trx_id 

and trunc(cr.creation_date) between '01-FEB-2015' AND '28-FEB-2015'  

 

 

     

      

-------------AR Adjustments ------------------ 

 

 

select        

     'Receivables' Subledger,  

     'Adjustments' Transaction_Type, 

       hou.name organisation_name,   

     count(distinct aaa.adjustment_id) Headers_Count, 

     count(*)  Lines_Count 

from AR_ADJUSTMENTS_ALL aaa,      

     hr_operating_units hou 

where     hou.organization_id = aaa.org_id  

    and trunc(aaa.creation_date) between '01-FEB-2015' AND '28-FEB-2015'      

group by 

     hou.name 

      

   

      

 select hou.name organisation_name  

 ,adj.ADJUSTMENT_NUMBER 

 ,ADJ.GL_DATE 

 ,ADJ.APPLY_DATE 

 ,NVL(ADJ.LINE_ADJUSTED,0) Adjusted_Line_Amount 

 ,ADJ.AMOUNT Adjustment_Amount 

 ,decode(ATRX.TYPE,'ADJUST','Adjustments',ATRX.TYPE) Adjustment_Activity_Type 

, decode(PAYS.CLASS,'BR','Bills Receivable','CB','Chargeback','CM','Credit Memo','DEP','Deposit','DM','Debit Memo','GUAR','Guarantee','INV','Invoice','PMT','Payment',PAYS.CLASS) Transaction_Class 

,RCT.TRX_NUMBER  

     from AR_ADJUSTMENTS_ALL ADJ, 

         RA_CUSTOMER_TRX_ALL RCT, 

          AR_RECEIVABLES_TRX_ALL ATRX, 

          AR_PAYMENT_SCHEDULES_ALL PAYS, 

          hr_operating_units hou 

     where trunc(adj.creation_date) between '01-FEB-2015' AND '28-FEB-2015' 

     and  hou.organization_id = adj.org_id  

     AND ADJ.CUSTOMER_TRX_ID=RCT.CUSTOMER_TRX_ID 

     AND ATRX.RECEIVABLES_TRX_ID(+)=ADJ.RECEIVABLES_TRX_ID 

     AND ADJ.PAYMENT_SCHEDULE_ID=PAYS.PAYMENT_SCHEDULE_ID 

 

-------------------------gl journals----------------- 

 

  select  

     'General Ledger' Subledger,  

     'Journals' Transaction_Type,   

     gl.name, 

      count(distinct gjh.je_header_id) Headers_Count, 

     count(*)  Lines_Count 

from gl_je_headers gjh, 

     gl_je_lines gjl, 

     gl_ledgers gl 

where    gjh.je_header_id = gjl.je_header_id 

    and gjl.ledger_id = gl.ledger_id 

    and trunc(gjh.creation_date) between '15-APR-2015' and '14-MAY-2015'   

group by 

    gl.name  

    order by gl.name 
