global class orderCreateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts  {
    
    public list<ID> osIds;
    public String query;
    public String idstorage='';
    public orderCreateBatch(list<ID> passOsId) {
        //get parameter from calling class
        osIds = passOsId;
        
        //dynamically make up query parse so you can pass it to start func, 
        //this is because start func can not get the dynamic parameter
        //start func can get the static parameter
        query = 'SELECT Id, ';
        query += 'CreatedBy.email, ';  
        query += 'DIC_Document_Type__c, '; 
        query += 'DIC_Requested_Delivery_Date__c, ';
        query += 'DIC_Sold_To__r.DIC_Currency__c, ';
        query += 'DIC_SoldTo_Account_Number__c, ';
        query += 'DIC_ShipTo_Account_Number__c, ';
        query += 'DIC_Price_Book__r.DIC_User__c, ';	
        query += 'DIC_Price_Book__r.DIC_Unloading_Point__c, ';	
        query += 'name ';                     					
        query += 'FROM  DIC_TemporaryOrderHeader__c ';
        
        //if parameter is not null,this stand for you have to pick up the data to execute batch
        if(osIds!=null){
            //it stand for manual creation
            for(ID oid:osIds){
                idstorage=idstorage+'\''+oid+'\',';
            }
            idstorage=idstorage.removeEnd(',');
            system.debug(idstorage);
            query += 'WHERE id in '+'('+idstorage+')';
        }else{
            //it stand for automatic creation
            //1. status=Before Sales Order
            query += 'WHERE DIC_Status__c =\'1\' ';
            //2. PriceBook.Manual_Flag=false
            query += 'AND DIC_Price_Book__r.DIC_Manual_Flag__c=false ';    
        }
        
        System.debug('Query:'+ query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Query:'+ query);
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<DIC_TemporaryOrderHeader__c> headerList) {
        
        system.debug('000000'+headerList);
        list<ID> newOsIds= new list<ID>();
        if(headerList!=null && headerList.size()!=0){
            for(DIC_TemporaryOrderHeader__c header:headerList){
                newOsIds.add(header.id);
            }
        }
        
        try {
            //To get DIC_TemporaryOrderItem__c data
            String query2 = 'SELECT Id, ';
            query2 += 'Name, ';  
            query2 += 'DIC_Material_Code__c, '; 
            query2 += 'DIC_Quantity__c, ';
            query2 += 'DIC_Sales_Unit__c, ';
            query2 += 'DIC_Delivery_Date__c, ';	
            query2 += 'DIC_Temporary_Order_Header__c, ';	
            query2 += 'DIC_Sold_To_Sales_Org__c ';                     					
            query2 += 'FROM  DIC_TemporaryOrderItem__c ';
            query2 += 'WHERE DIC_Temporary_Order_Header__c in :newOsIds';    
            
            System.debug('Query:'+ query2);
            list<DIC_TemporaryOrderItem__c> Itemlist=Database.query(query2);
            System.debug('Query:'+ Itemlist);
            
            //if there is no item,finish the func
            if(Itemlist==null||Itemlist.size()==0){
                System.debug('Query:'+ Itemlist);
                return;
            }else{
                list<Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>> rlist=new  list<Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>>();
                for(DIC_TemporaryOrderHeader__c header:headerlist){
                    Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>  setMap= new  Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>();   
                    for(DIC_TemporaryOrderItem__c item:Itemlist){
                        if(item.DIC_Temporary_Order_Header__c==header.id){
                            setMap.put(item, header);
                        }
                    }
                    rlist.add(setMap);
                }
                //set up the request value and callout 
                doCallout(rlist);
            }
            
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
        
    }
    
    
    public   static void  doCallout(list<Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>> rlist){
        for(Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c> setMap:rlist){
            
            DIC_sapSalesOrderCreate request = new DIC_sapSalesOrderCreate();
            Integer headerMakerCount=1;
            DIC_TemporaryOrderHeader__c headertemp;
            
            for (DIC_TemporaryOrderItem__c item : setMap.keySet()){
                //1.set header one time
                if(headerMakerCount==1){
                    headertemp=setMap.get(item);
                    // set input parameters
                    // set ORDER_HEADER_IN
                    request.ORDER_HEADER_IN.DIVISION='00';
                    request.ORDER_HEADER_IN.Name=headertemp.CreatedBy.email;
                    //Variable does not exist: DIC_User
                    //request.ORDER_HEADER_IN.DIC_User=headertemp.DIC_Price_Book__r.DIC_User__c;
                    request.ORDER_HEADER_IN.CURR_ISO=headertemp.DIC_Sold_To__r.DIC_Currency__c;
                    request.ORDER_HEADER_IN.DISTR_CHAN='00';
                    request.ORDER_HEADER_IN.SALES_ORG='A000';
                    request.ORDER_HEADER_IN.REQ_DATE_H=headertemp.DIC_Requested_Delivery_Date__c;
                    request.ORDER_HEADER_IN.DOC_TYPE=headertemp.DIC_Document_Type__c;
                    
                    
                    DIC_sapSalesOrderCreate.ORDER_PARTNERS pa1 = new DIC_sapSalesOrderCreate.ORDER_PARTNERS();
                    pa1.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa1.PARTN_ROLE='AG';
                    pa1.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;
                    request.ORDER_PARTNERS.add(pa1);
                    
                    DIC_sapSalesOrderCreate.ORDER_PARTNERS pa2 = new DIC_sapSalesOrderCreate.ORDER_PARTNERS();
                    //DIC_SoldTo_Account_Number__c????? we should use the shio to data after the inteface is completed.
                    pa2.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa2.PARTN_ROLE='WE';
                    pa2.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;                                  
                    request.ORDER_PARTNERS.add(pa2);
                    
                    DIC_sapSalesOrderCreate.ORDER_PARTNERS pa3 = new DIC_sapSalesOrderCreate.ORDER_PARTNERS();
                    pa3.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa3.PARTN_ROLE='BP';
                    pa3.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;                                  
                    request.ORDER_PARTNERS.add(pa3);
                    
                    headerMakerCount+=1;
                }
                
                //2.set item mutiple times
                DIC_sapSalesOrderCreate.ORDER_ITEMS_IN newItem = new DIC_sapSalesOrderCreate.ORDER_ITEMS_IN();
                //newItem.ROUTE=PricebookEntry.DIC_Route__c;
                newItem.ITEM_CATEG=headertemp.DIC_Document_Type__c;
                //REQ_DATE dose not exist    
                //newItem.REQ_DATE=item.DIC_Delivery_Date__c;
                newItem.SALES_UNIT=item.DIC_Sales_Unit__c;
                newItem.TARGET_QTY=item.DIC_Quantity__c;
                newItem.MATERIAL='000000'+item.DIC_Material_Code__c;
                //newItem.ITM_NUMBER=item.Name;
                
                request.ORDER_ITEMS_IN.add(newItem);
                
            }          
            
            
            Continuation cont = new Continuation(60);
            cont.continuationMethod = 'processResponse';
            overcast.Logger logger = new overcast.Logger('DIC_sapSalesOrderCreate');
            
            
            request.runAsync(logger,null,cont);
            
 /*           
            
            overcast.SynchronousHandler sh = overcast.SynchronousHandler.CreateFromName('DIC_sapSalesOrderCreate');
            sh.InputJson = request.serialize();
            sh.NamedCredential = null;
            sh.InputSetName = request.inputSetName;
            if (logger != null) {
                logger.setInputSetName(sh.CorrelationId);
                logger.setIdemId(sh.CorrelationId);
            }
            
            sh.ContinuationWebRequest = new HttpRequest();
            overcast.EpgwController.ExecuteScenarioSynchronously(sh, logger);
  */          

            //HttpResponse response2 = Continuation.getResponse(cont.requestLabel);
            //system.debug(response2);
            //system.debug(response.Z_PSD_SFDC_SALESORDER_CREATE.SALESDOCUMENT);                    
            
            // Log levels are ERROR, WARN, INFO, DEBUG, VERBOSE
            logger.addLog('INFO', 'Custom log');
            // save after callouts completed
            logger.commitToDatabase();
            
        }
        
    }
    
    
    
    
    global void finish(Database.BatchableContext bc) {
        //Do Nothing
    }
    
}