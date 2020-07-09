global class orderCreateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {

public  String query;
public  List<String> resultList;
public  List<ID> newosIds= new list<ID>();
global  orderCreateBatch(list<ID> osIds) {

    newosIds=osIds;
    resultList=new List<String>(); 
    //dynamically make up query parse so you can pass it to start func, 
    //this is because start func can not get the dynamic parameter
    //start func can get the static parameter
    query = 'SELECT Id, ';
    //query += 'CreatedBy.email, ';  
    query += 'DIC_PO_Number__c, ';
    query += 'DIC_PO_Date__c, ';
    query += 'DIC_Sold_To_Sales_Org__c, ';
    query += 'DIC_Document_Type__c, '; 
    query += 'DIC_Requested_Delivery_Date__c, ';
    query += 'DIC_Sold_To__r.DIC_Currency__c, ';
    query += 'DIC_Sold_To__r.DIC_Language__c, ';
    query += 'DIC_Sold_To__r.BillingCountry, ';
    query += 'DIC_Sold_To__r.BillingState, ';
    query += 'DIC_Sold_To__r.BillingCity, ';
    query += 'DIC_Sold_To__r.BillingStreet, ';
    query += 'DIC_SoldTo_Account_Number__c, ';
    query += 'DIC_ShipTo_Account_Number__c, ';
    query += 'DIC_Price_Book__r.DIC_User__c, ';	
    query += 'DIC_Price_Book__r.DIC_Collective_Delivery__c, ';	
    query += 'DIC_Price_Book__r.DIC_Delivery_Block_Header__c, ';	
    query += 'DIC_Price_Book__r.DIC_Billing_Block_Header__c, ';	
    query += 'DIC_Price_Book__r.DIC_Sales_Representative__c, ';
    query += 'DIC_One_Time_Ship_To_Name__c, ';
    query += 'DIC_One_Time_Ship_To_Postal_Code__c, ';
    query += 'DIC_One_Time_Ship_To_Telephone__c, ';
    
    query += 'DIC_Price_Book__r.DIC_Unloading_Point__c, ';	
    query += 'name ';                     					
    query += 'FROM  DIC_TemporaryOrderHeader__c ';
    if(newosIds!=null && newosIds.size()!=0){
        String condition='';
        for(ID headerId:newosIds){
            condition=condition+'\''+headerId+'\',';
        }
        condition = condition.removeEnd(',');
        system.debug('45'+condition);

        //it stand for manual creation
        query += 'WHERE id in '+'('+condition+')';  
    }else{
        //it stand for automatic creation
        //1. status=Before Sales Order
        query += 'WHERE DIC_Status__c =\'1\' ';
        //2. PriceBook.Manual_Flag=false
        query += 'AND DIC_Price_Book__r.DIC_Manual_Flag__c=false ';     
    }
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
    query2 += 'DIC_Material__c, ';
    query2 += 'DIC_Quantity__c, ';
    query2 += 'DIC_Sales_Unit__c, ';
    query2 += 'DIC_Delivery_Date__c, ';	
    query2 += 'DIC_Temporary_Order_Header__c, ';
    query2 += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__c, ';	
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
            list<ID> productIdList= new list<ID>();
            list<ID> priceBookIdList= new list<ID>();
            for(DIC_TemporaryOrderItem__c item:Itemlist){
                productIdList.add(item.DIC_Material__c);
                priceBookIdList.add(item.DIC_Temporary_Order_Header__r.DIC_Price_Book__c);
            }

            //To get PricebookEntry data
            //item(child)-------material(parent)--------PricebookEntries(child)
            String query3 = 'SELECT Id, ';
            query3 += 'Name, ';  
            query3 += 'Product2Id, ';
            query3 += 'Pricebook2Id, ';
            query3 += 'DIC_Delivery_Block_Item__c, ';
            query3 += 'DIC_I_Shipping_Instruction_Message__c, ';
            query3 += 'DIC_I_Product_type__c, ';
            query3 += 'DIC_I_Packing_information__c, ';
            query3 += 'DIC_I_Order_Message__c, ';
            query3 += 'DIC_I_Invoice_Message__c, ';
            query3 += 'DIC_I_Hazard_information__c, ';
            query3 += 'DIC_I_Delivery_Note_Message__c, ';
            query3 += 'DIC_I_Country_of_origin__c, ';
            query3 += 'DIC_I_Common_Message__c, ';
            query3 += 'DIC_Item_Category__c, ';
            query3 += 'DIC_Partial_Delivery__c, ';
            query3 += 'DIC_Billing_Block_Item__c, ';
            query3 += 'DIC_Sold_To_Unique_Material_Number__c, ';
            query3 += 'DIC_Shipping_Point__c, ';
            query3 += 'DIC_Storage_Location__c, ';
            query3 += 'DIC_Material_group_1__c, ';
            query3 += 'DIC_Material_group_2__c, ';
            query3 += 'DIC_Material_group_3__c, ';
            query3 += 'DIC_Route__c, ';
            query3 += 'DIC_Plant__c, ';



            query3 += 'DIC_Usage__c ';                  					
            query3 += 'FROM  PricebookEntry ';
            query3 += 'WHERE Product2Id in :productIdList ';    
            query3 += 'AND   Pricebook2Id in :priceBookIdList ';   
            list<PricebookEntry> entrylist=Database.query(query3);
            
            list<PricebookEntry> newEntrylist=new list<PricebookEntry>();
            for(DIC_TemporaryOrderItem__c item:Itemlist){
                for(PricebookEntry entry:entrylist){
                    if(item.DIC_Temporary_Order_Header__r.DIC_Price_Book__c==entry.Pricebook2Id &&
                    item.DIC_Material__c==entry.Product2Id){
                        newEntrylist.add(entry);
                        break;
                    }
                }
            }
            //newEntrylist.size()==Itemlist.size()
            system.debug(newEntrylist.size());
            system.debug(Itemlist.size());

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
            doCallout(rlist,newEntrylist);
        }
        
    } catch(DmlException e) {
        System.debug('An unexpected error has occurred: ' + e.getMessage());
    }
    
}


public    void  putinto(DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress,DIC_TemporaryOrderHeader__c headertemp,
                String code){

                    paaddress.ADDR_NO= code;
                    paaddress.NAME= headertemp.DIC_One_Time_Ship_To_Name__c;
                    paaddress.POSTL_COD1= headertemp.DIC_One_Time_Ship_To_Postal_Code__c;
                    //when country is japan
                    if(headertemp.DIC_Sold_To__r.BillingCountry=='JP'){
                        paaddress.STREET= headertemp.DIC_Sold_To__r.BillingState;
                        String combinead=headertemp.DIC_Sold_To__r.BillingCity+headertemp.DIC_Sold_To__r.BillingStreet;
                        if(combinead==''||combinead==null){
                            return;
                         }
                        if(combinead.length()<=40){
                            paaddress.CITY= combinead;
                        }else if(combinead.length()>40 && combinead.length()<=80){
                            paaddress.CITY= combinead.substring(0,40);
                            paaddress.STR_SUPPL3= combinead.substring(41);
                        }else if(combinead.length()>80){
                            paaddress.CITY= combinead.substring(0,40);
                            paaddress.STR_SUPPL3= combinead.substring(41,80);
                            paaddress.LOCATION= combinead.substring(81);
                        }
                    }else{
                        //not japan
                        String combinead=headertemp.DIC_Sold_To__r.BillingState
                        +headertemp.DIC_Sold_To__r.BillingCity;
                        paaddress.CITY= combinead;
                        String street=headertemp.DIC_Sold_To__r.BillingStreet;
                        if(street==''||street==null){
                            return;
                         }
                         if(street.length()<=60){
                             paaddress.STREET= street;
                         }else if(street.length()>60 && street.length()<=100){
                             paaddress.STREET= street.substring(0,60);
                             paaddress.STR_SUPPL3= street.substring(61);
                         }else if(street.length()>100){
                             paaddress.STREET= street.substring(0,60);
                             paaddress.STR_SUPPL3= street.substring(61,100);
                             paaddress.LOCATION= street.substring(101);
                         }
                    }

                    paaddress.TEL1_NUMBR= headertemp.DIC_One_Time_Ship_To_Telephone__c;
}



public    void  doCallout(list<Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c>> rlist,list<PricebookEntry> newEntrylist){
    DIC_MultipleOrderCreate request = new DIC_MultipleOrderCreate();
    
    for(Map<DIC_TemporaryOrderItem__c,DIC_TemporaryOrderHeader__c> setMap:rlist){
        //when headerMakerCount=1,it stands for we should give order a header. multiple items ====>one header
        Integer headerMakerCount=1;
        DIC_TemporaryOrderHeader__c headertemp;
        //count for inner loop
        //coz the Itemlist.size==newEntrylist.size
        Integer countIterator=0;
        Integer ITMNUMBER=10;
        for (DIC_TemporaryOrderItem__c item : setMap.keySet()){
            String ITMSNUMBER='0000'+ITMNUMBER;
            ITMSNUMBER=ITMSNUMBER.substring(ITMSNUMBER.length()-6);
            system.debug(ITMSNUMBER);
            //1.set header one time
            if(headerMakerCount==1){
                headertemp=setMap.get(item);
                // set input parameters
                // set ORDER_HEADER_IN
                
                DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN newHeader = new DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN();        
                newHeader.REFOBJKEY = headertemp.id;
                newHeader.DIVISION='00';
                newHeader.COMPL_DLV=headertemp.DIC_Price_Book__r.DIC_Collective_Delivery__c;
                String userid=UserInfo.getUserId();
                //if login user id's length between 1 and 35 then
                if(userid.length()<=35){
                    newHeader.Name=userid;
                //if login user id's length between 36 and 75 then
                }else if(userid.length()>35&& userid.length()<=75){
                    newHeader.Name=userid.substring(0,35);
                    newHeader.PP_SEARCH=userid.substring(36);
                //if login user id's length between 36 and 75 then
                }else if(userid.length()>75&& userid.length()<=80){
                    newHeader.Name=userid.substring(0,35);
                    newHeader.PP_SEARCH=userid.substring(36,75);
                    newHeader.REF_1_S=userid.substring(76);
                }

                //newHeader.CURR_ISO=headertemp.DIC_Sold_To__r.DIC_Currency__c;
                newHeader.DISTR_CHAN='00';
                newHeader.SALES_ORG=headertemp.DIC_Sold_To_Sales_Org__c;
                newHeader.REQ_DATE_H=headertemp.DIC_Requested_Delivery_Date__c;
                newHeader.DOC_TYPE=headertemp.DIC_Document_Type__c;
                newHeader.PURCH_NO_C=headertemp.DIC_PO_Number__c;
                newHeader.PURCH_DATE=headertemp.DIC_PO_Date__c;
                newHeader.DLV_BLOCK=headertemp.DIC_Price_Book__r.DIC_Delivery_Block_Header__c;
                newHeader.BILL_BLOCK=headertemp.DIC_Price_Book__r.DIC_Billing_Block_Header__c;


                request.IT_ORDER_HEADER_IN.add(newHeader);
                
                
                DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa1 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                pa1.REFOBJKEY = headertemp.id;
                pa1.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;
                pa1.PARTN_NUMB=headertemp.DIC_SoldTo_Account_Number__c;
                pa1.PARTN_ROLE='AG';
                request.IT_ORDER_PARTNERS.add(pa1);
                
                DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa2 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                pa2.REFOBJKEY = headertemp.id;
                pa2.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                pa2.PARTN_NUMB=headertemp.DIC_ShipTo_Account_Number__c;
                pa2.PARTN_ROLE='WE';
                request.IT_ORDER_PARTNERS.add(pa2);
                
                //one time record  the first one
                //condition is: there is a record
                if(headertemp.DIC_Price_Book__r.DIC_User__c!=null &&
                headertemp.DIC_Price_Book__r.DIC_User__c!=''){
                    DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa3 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                    pa3.REFOBJKEY = headertemp.id;
                    pa3.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                    pa3.PARTN_NUMB=headertemp.DIC_Price_Book__r.DIC_User__c;
                    pa3.PARTN_ROLE='Z1';
                    pa3.ADDR_LINK='1002';
                    request.IT_ORDER_PARTNERS.add(pa3);


                    DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress3= new DIC_MultipleOrderCreate.IT_PARTNERADDRESSES();
                    //put the right data into paaddress3
                    putinto(paaddress3,headertemp,'1002');

                    request.IT_PARTNERADDRESSES.add(paaddress3);

                }

                //one time record  the second one
                //condition is: there is a record
                if(headertemp.DIC_Price_Book__r.DIC_Sales_Representative__c!=null &&
                headertemp.DIC_Price_Book__r.DIC_Sales_Representative__c!=''){
                    DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa4 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                    pa4.REFOBJKEY = headertemp.id;
                    pa4.UNLOAD_PT=headertemp.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                    pa4.PARTN_NUMB=headertemp.DIC_Price_Book__r.DIC_Sales_Representative__c;
                    pa4.PARTN_ROLE='SR';
                    pa4.ADDR_LINK='1001';
                    request.IT_ORDER_PARTNERS.add(pa4);


                    DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress4= new DIC_MultipleOrderCreate.IT_PARTNERADDRESSES();

                    //put the right data into paaddress4
                    putinto(paaddress4,headertemp,'1001');

                    request.IT_PARTNERADDRESSES.add(paaddress4);

                }

                headerMakerCount+=1;
            }
            
            //2.set item mutiple times
            DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN newItem = new DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN();
            newItem.REFOBJKEY=headertemp.id;
            
            newItem.ROUTE=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Route__c:null);
            newItem.PLANT=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Plant__c:null);
            newItem.ITEM_CATEG=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Item_Category__c:null);
               
            //REQ_DATE dose not exist    
            //newItem.REQ_DATE=item.DIC_Delivery_Date__c;
            newItem.SALES_UNIT=item.DIC_Sales_Unit__c;
            newItem.TARGET_QTY=item.DIC_Quantity__c;
            newItem.MATERIAL='000000'+item.DIC_Material_Code__c;
            newItem.ITM_NUMBER=ITMSNUMBER;
            newItem.PART_DLV=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Partial_Delivery__c:null);
            newItem.BILL_BLOCK=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Billing_Block_Item__c:null);
            newItem.CUST_MAT35=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Sold_To_Unique_Material_Number__c:null);
            newItem.SHIP_POINT=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Shipping_Point__c:null);
            newItem.STORE_LOC=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Storage_Location__c:null);
            newItem.PRC_GROUP1=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Material_group_1__c:null);
            newItem.PRC_GROUP2=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Material_group_2__c:null);
            newItem.PRC_GROUP3=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Material_group_3__c:null);
            newItem.USAGE_IND=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Usage__c:null);

            request.IT_ORDER_ITEMS_IN.add(newItem);      
            
             
             //3.set the IT_ORDER_SCHEDULES_IN
             DIC_MultipleOrderCreate.IT_ORDER_SCHEDULES_IN newSche = new DIC_MultipleOrderCreate.IT_ORDER_SCHEDULES_IN();
             newSche.REFOBJKEY=headertemp.id;
             newSche.REQ_DLV_BL=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Delivery_Block_Item__c:null);
             newSche.REQ_DATE=item.DIC_Delivery_Date__c;
             newSche.REQ_QTY=item.DIC_Quantity__c;
             newSche.SCHED_LINE='0001';
             newSche.ITM_NUMBER=ITMSNUMBER;
      
             request.IT_ORDER_SCHEDULES_IN.add(newSche);    

            //4.set the IT_ORDER_TEXT
            String temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Shipping_Instruction_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y001',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Product_type__c:null);
            setIT_ORDER_TEXT(temp, request,'Z005',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Packing_information__c:null);
            setIT_ORDER_TEXT(temp, request,'Z004',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Order_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y004',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Invoice_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Z001',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Hazard_information__c:null);
            setIT_ORDER_TEXT(temp, request,'Z003',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Delivery_Note_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y002',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Country_of_origin__c:null);
            setIT_ORDER_TEXT(temp, request,'Z002',headertemp,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Common_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y003',headertemp,ITMSNUMBER);

            //5
            countIterator=countIterator+1;  
            ITMNUMBER=ITMNUMBER+10;      
        }          
    }

            //3.execute web service call
            overcast.Logger logger = new overcast.Logger('DIC_MultipleOrderCreate');
        
            if (Test.isRunningTest()) {
                if (request.testResponse == null) 
                    request.testResponse += '{"output":{"ET_RETURN":[{"REFOBJKEY":"a0h0l0000029NjaAAE","RESULT":"W","SALESDOCUMENT":"0004856297","ID":"","NUMBER_x":"000","MESSAGE":""}],';
                    request.testResponse += '"IT_ORDER_HEADER_IN":[{"REFOBJTYPE":"","REFOBJKEY":"a0h0l0000029NjaAAE","REFDOCTYPE":"","DOC_TYPE":"YJ20"}]}}';
            }
            DIC_MultipleOrderCreate response = request.run(logger,null);
            for(DIC_MultipleOrderCreate.ET_RETURN en:response.ET_RETURN){
                if(en.SALESDOCUMENT!=null){
                    resultList.add('success');
                }else{
                    resultList.add('fail');
                }
            }
			system.debug(response.ET_RETURN);
    		system.debug(resultList);
            system.debug(response.testResponse);
            // Log levels are ERROR, WARN, INFO, DEBUG, VERBOSE
            logger.addLog('INFO', 'Custom log');
            // save after callouts completed
            logger.commitToDatabase();
    
}

public   void  setIT_ORDER_TEXT(String OderText,DIC_MultipleOrderCreate request,String TID,
        DIC_TemporaryOrderHeader__c headertemp,String ITMSNUMBER){
            //4.set the IT_ORDER_TEXT
            if(OderText!=null&&OderText!=''){
                DIC_MultipleOrderCreate.IT_ORDER_TEXT newOtext = new DIC_MultipleOrderCreate.IT_ORDER_TEXT();
                newOtext.REFOBJKEY=headertemp.id;
                newOtext.ITM_NUMBER=ITMSNUMBER;
                newOtext.LANGU=headertemp.DIC_Sold_To__r.DIC_Language__c;
                newOtext.TEXT_LINE=OderText;
                newOtext.TEXT_ID=TID;
                request.IT_ORDER_TEXT.add(newOtext); 
            }
}

global void finish(Database.BatchableContext bc) {
    //Do Nothing
    //
    system.debug(resultList);
    system.debug(newosIds);

    if(resultList!=null && newosIds!=null){
		List<DIC_TemporaryOrderHeader__c>  hlist=[select id,name,DIC_Status__c from DIC_TemporaryOrderHeader__c where id in :newosIds];
        Integer cout=0;
        for(DIC_TemporaryOrderHeader__c header:hlist){
            if(resultList[cout]=='success'){
                header.DIC_Status__c='3';
            }else{
                header.DIC_Status__c='2';
            } 
            cout=cout+1;
        }
        update hlist;
    }

}

}