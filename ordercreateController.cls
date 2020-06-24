public class ordercreateController {
    public list<DIC_TemporaryOrderHeader__c> os;
    public list<string> msglist{get;set;}
    public  Integer osCount{get;set;}
    public list<ID> osIds;

    
    public  PageReference listView() {
           Schema.DescribeSObjectResult destination = DIC_TemporaryOrderHeader__c.sObjectType.getDescribe();
           PageReference pageRef = new PageReference('/' + destination.getKeyPrefix() );
           pageRef.setRedirect(true);
           return pageRef;
    }
	public  ordercreateController(ApexPages.StandardSetController controller) {        
		 os=controller.getSelected();  
        if(os==null){
           osCount=0;
        }else{
           osCount=os.size(); 
        }
         
         system.debug(os);
    }
    
    public   void   create(){
        system.debug('123');
        system.debug(os);
        if(os==null){
            return;
        }
        osIds = new list<ID>();
        msglist= new list<string>();
        for(DIC_TemporaryOrderHeader__c he:os){
            osIds.add(he.Id);
            system.debug(he);
        }
        
       prepareData(osIds);
    }
    
     public   void  prepareData(list<ID> osIds){
         //To get DIC_TemporaryOrderHeader__c data
             String query = 'SELECT Id, ';
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
               	query += 'WHERE id in :osIds';           
         
               	System.debug('Query:'+ query);
        	   	list<DIC_TemporaryOrderHeader__c> headerlist=Database.query(query);
         		System.debug('Query:'+ headerlist);
         
         	 	//1.if there is no header,finish the func
         	 	//2.coz there is a governer limit ,and a trasaction can only do 100 times callout
                 if(headerlist==null || headerlist.size()>=100){
                     return;
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
               	query2 += 'WHERE DIC_Temporary_Order_Header__c in :osIds';    
                
         		System.debug('Query:'+ query2);
        	   	list<DIC_TemporaryOrderItem__c> Itemlist=Database.query(query2);
         		System.debug('Query:'+ Itemlist);
         
         		//if there is no item,finish the func
                if(Itemlist==null){
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
         
     }

    public   void  doCallout(list<Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>> rlist){
        DIC_MultipleOrderCreate request = new DIC_MultipleOrderCreate();
                for(Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c> setMap:rlist){
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
                    

                }
        //3.execute web service call
        overcast.Logger logger = new overcast.Logger('DIC_MultipleOrderCreate');
        DIC_MultipleOrderCreate response = request.run(logger,null);
        system.debug(response.ET_RETURN[0].SALESDOCUMENT);
        for(DIC_MultipleOrderCreate.ET_RETURN en:response.ET_RETURN){
            if(en.SALESDOCUMENT!=null){
                msglist.add('success');
            }else{
                msglist.add('fail');
            }
        }
        // Log levels are ERROR, WARN, INFO, DEBUG, VERBOSE
        logger.addLog('INFO', 'Custom log');
        // save after callouts completed
        logger.commitToDatabase();

    }
    

    
}