global class orderCreateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts  {
    
    public String query;
    public orderCreateBatch() {
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
        
        //it stand for automatic creation
        //1. status=Before Sales Order
        query += 'WHERE DIC_Status__c =\'1\' ';
        //2. PriceBook.Manual_Flag=false
        query += 'AND DIC_Price_Book__r.DIC_Manual_Flag__c=false ';         
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
        
        try {
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
        DIC_MultipleOrderCreate request = new DIC_MultipleOrderCreate();
        for(Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c> setMap:rlist){
			//when headerMakerCount=1,it stands for we should give order a header. multiple items ====>one header
            Integer headerMakerCount=1;
            DIC_TemporaryOrderHeader__c headertemp;
            
            for (DIC_TemporaryOrderItem__c item : setMap.keySet()){
                //1.set header one time
                if(headerMakerCount==1){
                    headertemp=setMap.get(item);
                    // set input parameters
                    // set ORDER_HEADER_IN
                    
                    DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN newHeader = new DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN();        
                    newHeader.REFOBJKEY = headertemp.id;
                    
                    newHeader.DIVISION='00';
                    newHeader.Name=headertemp.CreatedBy.email;
                    //Variable does not exist: DIC_User
                    //request.ORDER_HEADER_IN.DIC_User=headertemp.DIC_Price_Book__r.DIC_User__c;
                    newHeader.CURR_ISO=headertemp.DIC_Sold_To__r.DIC_Currency__c;
                    newHeader.DISTR_CHAN='00';
                    newHeader.SALES_ORG='A000';
                    newHeader.REQ_DATE_H=headertemp.DIC_Requested_Delivery_Date__c;
                    newHeader.DOC_TYPE=headertemp.DIC_Document_Type__c;
                    
                    request.IT_ORDER_HEADER_IN.add(newHeader);
                    
                    
                    DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa1 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                    pa1.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa1.PARTN_ROLE='AG';
                    pa1.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;
                    pa1.REFOBJKEY = headertemp.id;
                    request.IT_ORDER_PARTNERS.add(pa1);
                    
                    DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa2 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                    //DIC_SoldTo_Account_Number__c????? we should use the shio to data after the inteface is completed.
                    pa2.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa2.PARTN_ROLE='WE';
                    pa2.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                    pa2.REFOBJKEY = headertemp.id;
                    request.IT_ORDER_PARTNERS.add(pa2);
                    
                    DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa3 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                    pa3.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                    pa3.PARTN_ROLE='BP';
                    pa3.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;       
                    pa3.REFOBJKEY = headertemp.id;
                    request.IT_ORDER_PARTNERS.add(pa3);
                    
                    headerMakerCount+=1;
                }
                
                //2.set item mutiple times
                DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN newItem = new DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN();
                newItem.REFOBJKEY=headertemp.id;
                //newItem.ROUTE=PricebookEntry.DIC_Route__c;
                newItem.ITEM_CATEG=headertemp.DIC_Document_Type__c;
                //REQ_DATE dose not exist    
                //newItem.REQ_DATE=item.DIC_Delivery_Date__c;
                newItem.SALES_UNIT=item.DIC_Sales_Unit__c;
                newItem.TARGET_QTY=item.DIC_Quantity__c;
                newItem.MATERIAL='000000'+item.DIC_Material_Code__c;
                //newItem.ITM_NUMBER=item.Name;
                
                request.IT_ORDER_ITEMS_IN.add(newItem);                
            }          
            
            
    		//3.execute web service call
            overcast.Logger logger = new overcast.Logger('DIC_MultipleOrderCreate');
            
            if (Test.isRunningTest()) {
                if (request.testResponse == null) 
                    request.testResponse += '{"output":{"ET_RETURN":[{"REFOBJKEY":"a0h0l0000029NjaAAE","RESULT":"W","SALESDOCUMENT":"0004856297","ID":"","NUMBER_x":"000","MESSAGE":""}],';
                	request.testResponse += '"IT_ORDER_HEADER_IN":[{"REFOBJTYPE":"","REFOBJKEY":"a0h0l0000029NjaAAE","REFDOCTYPE":"","DOC_TYPE":"YJ20"}]}}';
            }
            DIC_MultipleOrderCreate response = request.run(logger,null);
            system.debug(response.testResponse);
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