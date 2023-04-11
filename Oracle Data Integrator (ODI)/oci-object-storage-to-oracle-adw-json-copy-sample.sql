DECLARE
  uri_list CLOB;
  staging_table_name varchar2(200);
BEGIN
   uri_list := 'https://objectstorage.uk-london-1.oraclecloud.com/n/{tenant}/b/{bucket}/o/{filename}.json.gz';
  staging_table_name := 'WL_POSITION_Columns';
  dbms_output.put_line('starting at '||to_char(sysdate,'HH24:MI:SS'));
  dbms_cloud.copy_data(
    schema_name => 'OLAP',
    table_name => staging_table_name,
    file_uri_list => uri_list,
    credential_name =>'ODI_API',
    format => json_object(
    'type' VALUE 'json',
    'compression' VALUE 'gzip',
    'characterset' VALUE 'UTF8',
    'columnpath' VALUE '[ "$.id",
    "$.snapshot",
    "$.snapshotDate",
    "$.asset"
    ,"$.assetCategory","$.assetClass","$.assetGroup1","$.assetGroup2","$.assetGroup3","$.assetGroup4","$.assetGroup5","$.period",
    "$.deliveryStartDate","$.deliveryEndDate","$.deliveryPeriod","$.paymentDate","$.pricingStartDate","$.pricingEndDate","$.pricingPeriod","$.counterpartCompany","$.book","$.instrument",
    "$.buySell","$.sectionId","$.internalCompany","$.tradeId",
    "$.USER",
    "$.location","$.costType","$.incoterms","$.exchange","$.userGroup","$.marketCurve","$.marketLocation" ,"$.marketCurveType" ,"$.market" ,"$.putCall" ,"$.expirationDate" ,
    "$.exchangeContract" ,"$.lotSize" ,"$.lotUom" ,"$.baseCurrency" ,"$.settleCurrency","$.notionalAmount" ,"$.pl" ,"$.npvFactor" ,"$.rho" ,"$.theta" ,
    "$.delta","$.gamma","$.uom","$.qty","$.fxExposure","$.fxExposureCurrency","$.conversionFactorForMMBTU","$.conversionFactorForMWh","$.conversionFactorForMT",
    "$.conversionFactorForBBL","$.conversionFactorForMW","$.fxMarketSettleRate","$.fxTradeSettleRate","$.tradePrice","$.marketPrice","$.tradingStatus","$.accountingStatus","$.deliveryId",
   "$.indexLocation","$.positionType","$.tradeType","$.priceUnprice","$.payableReceivable","$.modeOfTransfer","$.deliverySchedule","$.timeGranularity","$.deliveryType",
   "$.deliveryStatus","$.peakType","$.tradeDate","$.tradeInputDate","$.sourceSystem","$.riskComponentType"
   ]'
    )   
);
dbms_output.put_line('ending at '||to_char(sysdate,'HH24:MI:SS'));
END
;
