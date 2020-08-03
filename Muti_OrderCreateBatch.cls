global class Muti_OrderCreateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
    
    //store the written data in request
    public  String requestSize;
    //dynamic query 
    public  String query;
    //the maximum to create a report every loop in execute
    public  Integer executeItemCnt;
    //store the executed result of reponse to update the header status
    public  List<String> resultList;
    public  List<ID> newosIds= new list<ID>();
    //store the last header data every loop in execute
    public  List<DIC_TemporaryOrderItem__c> storeItemList= new list<DIC_TemporaryOrderItem__c>();
    
    
    global  Muti_OrderCreateBatch(list<ID> osIds) {
        resultList=new List<String>(); 
        //dynamically make up query parse so you can pass it to start func, 
        //because start func can not get the dynamic parameter
        //start func can get the static parameter
        
        //To get DIC_TemporaryOrderItem__c data
        query = 'SELECT Id, ';
        query += 'Name, ';  
        query += 'DIC_Material_Code__c, '; 
        query += 'DIC_Material__c, ';
        query += 'DIC_Quantity__c, ';
        query += 'DIC_Sales_Unit__c, ';
        query += 'DIC_Delivery_Date__c, ';	
        query += 'DIC_Temporary_Order_Header__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__c, ';	
        query += 'DIC_Sold_To_Sales_Org__c,';   
        
        //To get DIC_TemporaryOrderHeader__c data
        query += 'DIC_Temporary_Order_Header__r.DIC_PO_Number__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_PO_Date__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To_Sales_Org__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Document_Type__c, '; 
        query += 'DIC_Temporary_Order_Header__r.DIC_Requested_Delivery_Date__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.DIC_Currency__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.DIC_Language__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingCountry, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingState, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingCity, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingStreet, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_SoldTo_Account_Number__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_ShipTo_Account_Number__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_User__c, ';	
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Collective_Delivery__c, ';	
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Delivery_Block_Header__c, ';	
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Billing_Block_Header__c, ';	
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Sales_Representative__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Name__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Postal_Code__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Telephone__c, ';
        query += 'DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Unloading_Point__c ';	
        
        //main table is DIC_TemporaryOrderItem__c
        query += 'FROM  DIC_TemporaryOrderItem__c ';
        
        
        if(osIds!=null && osIds.size()!=0){
            //sort out the header id 
            String condition='';
            for(ID headerId:osIds){
                condition=condition+'\''+headerId+'\',';
            }
            condition = condition.removeEnd(',');
            
            //it stand for manual creation
            query += 'WHERE DIC_Temporary_Order_Header__c in '+'('+condition+')';  
        }else{
            //it stand for automatic creation
            //1. status=Before Sales Order
            query += 'WHERE DIC_Temporary_Order_Header__r.DIC_Status__c =\'1\' ';
            //2. PriceBook.Manual_Flag=false
            query += 'AND DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Manual_Flag__c=false ';     
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Query:'+ query);
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<DIC_TemporaryOrderItem__c> Itemlist) {
        
        system.debug('QueryResult'+Itemlist);
        if(executeItemCnt==null){
            executeItemCnt=100;
            system.debug(executeItemCnt);
        }
        try{
            //if there is no item,finish the func
            if(Itemlist==null||Itemlist.size()==0){
                System.debug('Query:'+ Itemlist);
                return;
            }else{
                //1.at first ,we clean the itemlist
                list<DIC_TemporaryOrderItem__c> newItemlist=new list<DIC_TemporaryOrderItem__c>();
                
                if(storeItemList!=null && storeItemList.size()!=0){
                    //put the previous saved data into current list
                    for(DIC_TemporaryOrderItem__c item:storeItemList){
                        newItemlist.add(item);
                    }
                    //clear out the previous data list
                    storeItemList.clear();
                }
                
                if(Itemlist.size()<executeItemCnt){
                    system.debug(Itemlist.size());
                    for(DIC_TemporaryOrderItem__c item:Itemlist){
                        newItemlist.add(item);
                    }
                }else{
                    for(Integer i=0;I<Itemlist.size();i++){
                        
                        if(Itemlist[i].DIC_Temporary_Order_Header__c!=Itemlist[Itemlist.size()-1].DIC_Temporary_Order_Header__c){
                            // not the last header
                            system.debug(newItemlist.size());
                            newItemlist.add(Itemlist[i]);
                        }else{
                            //when last header
                            storeItemList.add(Itemlist[i]);
                        }
                    }
                }
                
                
                //newEntrylist.size()==Itemlist.size()
                //for(DIC_TemporaryOrderItem__c item:newItemlist){
                //    system.debug(item);
                //}
                
                
                //2.secondly ,we use the  newitemlist to get price entry
                //coz the size of the newItemlist is not 100,
                //use the newItemlist to get the same size newEntrylist
                list<PricebookEntry> newEntrylist=getPriceEntry(newItemlist);
                system.debug(newEntrylist.size());
                system.debug(Itemlist.size());
                system.debug('The Execution in execute,the count of records is: '+newItemlist.size());
                system.debug(storeItemList.size());
                //set up the request value and callout 
                doCallout(newItemlist,newEntrylist);
            }
            
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }
        
    }
    
    
    public list<PricebookEntry> getPriceEntry(list<DIC_TemporaryOrderItem__c> newItemlist){
        list<PricebookEntry> newEntrylist=new list<PricebookEntry>();
        try{
            list<ID> productIdList= new list<ID>();
            list<ID> priceBookIdList= new list<ID>();
            for(DIC_TemporaryOrderItem__c item:newItemlist){
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
            
            //coz the query3 use two 'in' mark ,they could not confirm the unique pricebookentry
            //we use the following check to clear the wrong record
            //we should keep the rules:pricebook ==pricebook and product==product
            
            for(DIC_TemporaryOrderItem__c item:newItemlist){
                system.debug(item);
                for(PricebookEntry entry:entrylist){
                    if(item.DIC_Temporary_Order_Header__r.DIC_Price_Book__c==entry.Pricebook2Id &&
                       item.DIC_Material__c==entry.Product2Id){
                           newEntrylist.add(entry);
                           break;
                       }
                }
            }
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
            
        }
        return newEntrylist;
        
    }
    
    
    //this func is to arrange the address by different country: JP or not JP
    public    void  putinto(DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress,DIC_TemporaryOrderItem__c item,
                            String code){
                                
                                paaddress.ADDR_NO= code;
                                paaddress.NAME= item.DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Name__c;
                                paaddress.POSTL_COD1= item.DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Postal_Code__c;
                                //when country is japan
                                if(item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingCountry=='JP'){
                                    paaddress.STREET= item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingState;
                                    String combinead=item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingCity
                                        +item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingStreet;
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
                                    String combinead=item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingState
                                        +item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingCity;
                                    paaddress.CITY= combinead;
                                    String street=item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.BillingStreet;
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
                                
                                paaddress.TEL1_NUMBR= item.DIC_Temporary_Order_Header__r.DIC_One_Time_Ship_To_Telephone__c;
                                
                                
                                //---------------------------------------------------------count size
                                requestSize=requestSize+ paaddress.ADDR_NO+
                                    paaddress.NAME+
                                    paaddress.POSTL_COD1+
                                    paaddress.CITY+
                                    paaddress.STREET+
                                    paaddress.STR_SUPPL3+
                                    paaddress.LOCATION+
                                    paaddress.TEL1_NUMBR;
                            }
    
    
    
    public    void  doCallout(list<DIC_TemporaryOrderItem__c> Itemlist,list<PricebookEntry> newEntrylist){
        
        //every item must have a entry data
        DIC_MultipleOrderCreate request = new DIC_MultipleOrderCreate();
        if(Itemlist.size()!=newEntrylist.size()){
            return;
        }
        
        
        //previousHeaderId, when previous id is not equal to current id .it means header has changed
        Id previousHeaderId;
        //count for inner loop
        //coz the Itemlist.size==newEntrylist.size
        Integer countIterator=0;
        //this is for one field and add 10 every time
        Integer ITMNUMBER=10;
        for (DIC_TemporaryOrderItem__c item : Itemlist){

            //1.if header has changed
            if(previousHeaderId!=item.DIC_Temporary_Order_Header__c){
                //save the valid save the header id (be cautious:you do this  to declude the invalide header id  which does not have item) 
                newosIds.add(item.DIC_Temporary_Order_Header__c);
                // set input parameters
                // set ORDER_HEADER_IN
                
                DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN newHeader = new DIC_MultipleOrderCreate.IT_ORDER_HEADER_IN();        
                newHeader.REFOBJKEY = item.DIC_Temporary_Order_Header__c;
                newHeader.DIVISION='00';
                newHeader.COMPL_DLV=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Collective_Delivery__c;
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
                //---------------------------------------------------------count size
                requestSize=requestSize+newHeader.DISTR_CHAN+
                    newHeader.REFOBJKEY+
                    newHeader.DIVISION+
                    newHeader.COMPL_DLV+
                    newHeader.Name+
                    newHeader.PP_SEARCH+
                    newHeader.REF_1_S;
                
                //newHeader.CURR_ISO=headertemp.DIC_Sold_To__r.DIC_Currency__c;
                newHeader.DISTR_CHAN='00';
                newHeader.SALES_ORG=item.DIC_Temporary_Order_Header__r.DIC_Sold_To_Sales_Org__c;
                newHeader.REQ_DATE_H=item.DIC_Temporary_Order_Header__r.DIC_Requested_Delivery_Date__c;
                newHeader.DOC_TYPE=item.DIC_Temporary_Order_Header__r.DIC_Document_Type__c;
                newHeader.PURCH_NO_C=item.DIC_Temporary_Order_Header__r.DIC_PO_Number__c;
                newHeader.PURCH_DATE=item.DIC_Temporary_Order_Header__r.DIC_PO_Date__c;
                newHeader.DLV_BLOCK=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Delivery_Block_Header__c;
                newHeader.BILL_BLOCK=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Billing_Block_Header__c;
                //---------------------------------------------------------count size
                requestSize=requestSize+newHeader.DISTR_CHAN+
                    newHeader.SALES_ORG+
                    newHeader.REQ_DATE_H+
                    newHeader.DOC_TYPE+
                    newHeader.PURCH_NO_C+
                    newHeader.PURCH_DATE+
                    newHeader.DLV_BLOCK+
                    newHeader.BILL_BLOCK;
                
                request.IT_ORDER_HEADER_IN.add(newHeader);
                
                
                DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa1 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                pa1.REFOBJKEY = item.DIC_Temporary_Order_Header__c;
                pa1.UNLOAD_PT=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Unloading_Point__c;
                pa1.PARTN_NUMB=item.DIC_Temporary_Order_Header__r.DIC_SoldTo_Account_Number__c;
                pa1.PARTN_ROLE='AG';
                request.IT_ORDER_PARTNERS.add(pa1);
                //---------------------------------------------------------count size
                requestSize=requestSize+pa1.REFOBJKEY+pa1.UNLOAD_PT+pa1.PARTN_NUMB+pa1.PARTN_ROLE;
                
                DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa2 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                pa2.REFOBJKEY = item.DIC_Temporary_Order_Header__c;
                pa2.UNLOAD_PT=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                pa2.PARTN_NUMB=item.DIC_Temporary_Order_Header__r.DIC_ShipTo_Account_Number__c;
                pa2.PARTN_ROLE='WE';
                request.IT_ORDER_PARTNERS.add(pa2);
                //---------------------------------------------------------count size
                requestSize=requestSize+pa1.REFOBJKEY+pa1.UNLOAD_PT+pa1.PARTN_NUMB+pa1.PARTN_ROLE;
                
                //one time record  the first one
                //condition is: there is a record
                if(item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_User__c!=null &&
                   item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_User__c!=''){
                       DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa3 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                       pa3.REFOBJKEY = item.DIC_Temporary_Order_Header__c;
                       pa3.UNLOAD_PT=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                       pa3.PARTN_NUMB=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_User__c;
                       pa3.PARTN_ROLE='Z1';
                       pa3.ADDR_LINK='1002';
                       request.IT_ORDER_PARTNERS.add(pa3);
                       //---------------------------------------------------------count size
                       requestSize=requestSize+pa3.REFOBJKEY+pa3.UNLOAD_PT+pa3.PARTN_NUMB+pa3.PARTN_ROLE+pa3.ADDR_LINK;
                       
                       
                       DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress3= new DIC_MultipleOrderCreate.IT_PARTNERADDRESSES();
                       //put the right data into paaddress3
                       putinto(paaddress3,item,'1002');
                       
                       request.IT_PARTNERADDRESSES.add(paaddress3);
                   }
                
                //one time record  the second one
                //condition is: there is a record
                if(item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Sales_Representative__c!=null &&
                   item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Sales_Representative__c!=''){
                       DIC_MultipleOrderCreate.IT_ORDER_PARTNERS pa4 = new DIC_MultipleOrderCreate.IT_ORDER_PARTNERS();
                       pa4.REFOBJKEY = item.DIC_Temporary_Order_Header__r.id;
                       pa4.UNLOAD_PT=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Unloading_Point__c;     
                       pa4.PARTN_NUMB=item.DIC_Temporary_Order_Header__r.DIC_Price_Book__r.DIC_Sales_Representative__c;
                       pa4.PARTN_ROLE='SR';
                       pa4.ADDR_LINK='1001';
                       request.IT_ORDER_PARTNERS.add(pa4);
                       //---------------------------------------------------------count size
                       requestSize=requestSize+pa4.REFOBJKEY+pa4.UNLOAD_PT+pa4.PARTN_NUMB+pa4.PARTN_ROLE+pa4.ADDR_LINK;
                       
                       DIC_MultipleOrderCreate.IT_PARTNERADDRESSES paaddress4= new DIC_MultipleOrderCreate.IT_PARTNERADDRESSES();
                       
                       //put the right data into paaddress4
                       putinto(paaddress4,item,'1001');
                       
                       request.IT_PARTNERADDRESSES.add(paaddress4);
                       
                   }
                //initiate data
                previousHeaderId=item.DIC_Temporary_Order_Header__c;
                ITMNUMBER=10;
            }

            //keep the format with 0 in the front 
            String ITMSNUMBER='0000'+ITMNUMBER;
            ITMSNUMBER=ITMSNUMBER.substring(ITMSNUMBER.length()-6);
            system.debug(ITMSNUMBER);
            /////-----------------------------------------777777777777
            
            //2.set item mutiple times
            DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN newItem = new DIC_MultipleOrderCreate.IT_ORDER_ITEMS_IN();
            newItem.REFOBJKEY=item.DIC_Temporary_Order_Header__c;

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
            //---------------------------------------------------------count size
            requestSize=requestSize+newItem.SALES_UNIT+newItem.TARGET_QTY+newItem.MATERIAL+newItem.ITM_NUMBER+newItem.PART_DLV+newItem.BILL_BLOCK+ newItem.CUST_MAT35+newItem.SHIP_POINT+newItem.STORE_LOC
            +newItem.PRC_GROUP1+newItem.PRC_GROUP2+newItem.PRC_GROUP3+newItem.USAGE_IND+newItem.REFOBJKEY+ newItem.ROUTE+newItem.PLANT+newItem.ITEM_CATEG;

            //3.set the IT_ORDER_SCHEDULES_IN
            DIC_MultipleOrderCreate.IT_ORDER_SCHEDULES_IN newSche = new DIC_MultipleOrderCreate.IT_ORDER_SCHEDULES_IN();
            newSche.REFOBJKEY=item.DIC_Temporary_Order_Header__c;
            newSche.REQ_DLV_BL=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_Delivery_Block_Item__c:null);
            newSche.REQ_DATE=item.DIC_Delivery_Date__c;
            newSche.REQ_QTY=item.DIC_Quantity__c;
            newSche.SCHED_LINE='0001';
            newSche.ITM_NUMBER=ITMSNUMBER;

            request.IT_ORDER_SCHEDULES_IN.add(newSche);    
            //---------------------------------------------------------count size
            requestSize=requestSize+item.DIC_Temporary_Order_Header__c+item.DIC_Delivery_Date__c+item.DIC_Quantity__c+newSche.REQ_DLV_BL+'0001'+ITMSNUMBER;



            //4.set the IT_ORDER_TEXT
            String temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Shipping_Instruction_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y001',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Product_type__c:null);
            setIT_ORDER_TEXT(temp, request,'Z005',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Packing_information__c:null);
            setIT_ORDER_TEXT(temp, request,'Z004',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Order_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y004',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Invoice_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Z001',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Hazard_information__c:null);
            setIT_ORDER_TEXT(temp, request,'Z003',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Delivery_Note_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y002',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Country_of_origin__c:null);
            setIT_ORDER_TEXT(temp, request,'Z002',item,ITMSNUMBER);
            temp=newEntrylist==null?null:(newEntrylist.size()>countIterator?newEntrylist[countIterator].DIC_I_Common_Message__c:null);
            setIT_ORDER_TEXT(temp, request,'Y003',item,ITMSNUMBER);

            //5
            countIterator=countIterator+1;  
            ITMNUMBER=ITMNUMBER+10;   
        }          
        
        
        //3.execute web service call
        overcast.Logger logger = new overcast.Logger('DIC_MultipleOrderCreate');
        
        if (Test.isRunningTest()) {
            if (request.testResponse == null) 
            	system.debug(newosIds.size());
                
                    request.testResponse += '{"output":';
                    request.testResponse += '{"ET_RETURN":[{"REFOBJKEY":"a0h0l0000029NjaAAE","RESULT":"W","SALESDOCUMENT":"00048562","ID":"","NUMBER_x":"000","MESSAGE":""}],';
                    request.testResponse += '"IT_ORDER_HEADER_IN":[{"REFOBJTYPE":"","REFOBJKEY":"a0h0l0000029NjaAAE","REFDOCTYPE":"","DOC_TYPE":"YJ20"}]}';
                    request.testResponse += '}';
                
        }
        
        system.debug(requestSize.length());
        system.debug(Blob.valueOf(requestSize).size());
        
        
        DIC_MultipleOrderCreate response = request.run(logger,null);
        if (Test.isRunningTest()) {
        for(Integer i=0;i<newosIds.size();i++){
            resultList.add('success');
        }
        }else{
            for(DIC_MultipleOrderCreate.ET_RETURN en:response.ET_RETURN){
                if(en.SALESDOCUMENT!=null&&en.SALESDOCUMENT!=''){
                    resultList.add('success');
                }else{
                    //when failed
                    resultList.add(en.MESSAGE);
                    //system.debug(en.MESSAGE);
                }
            }
        }
        system.debug(response.ET_RETURN);
        system.debug(resultList);
        
        // Log levels are ERROR, WARN, INFO, DEBUG, VERBOSE
        logger.addLog('INFO', 'Custom log');
        // save after callouts completed
        logger.commitToDatabase();
        
    }
    
    public   void  setIT_ORDER_TEXT(String OderText,DIC_MultipleOrderCreate request,String TID,
    DIC_TemporaryOrderItem__c item,String ITMSNUMBER){
                                        //4.set the IT_ORDER_TEXT
                                        if(OderText!=null&&OderText!=''){
                                            DIC_MultipleOrderCreate.IT_ORDER_TEXT newOtext = new DIC_MultipleOrderCreate.IT_ORDER_TEXT();
                                            newOtext.REFOBJKEY=item.DIC_Temporary_Order_Header__c;
                                            newOtext.ITM_NUMBER=ITMSNUMBER;
                                            newOtext.LANGU=item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.DIC_Language__c;
                                            newOtext.TEXT_LINE=OderText;
                                            newOtext.TEXT_ID=TID;
                                            request.IT_ORDER_TEXT.add(newOtext); 
                                            //---------------------------------------------------------count size
                                            requestSize=requestSize+item.DIC_Temporary_Order_Header__c
                                            +ITMSNUMBER+item.DIC_Temporary_Order_Header__r.DIC_Sold_To__r.DIC_Language__c+OderText+TID;
                                        }
                                    }
    
    global void finish(Database.BatchableContext bc) {
		system.debug('The Execution in finish,the count of records is: '+storeItemList.size());
        if(storeItemList!=null && storeItemList.size()!=0){
            list<PricebookEntry> newEntrylist=getPriceEntry(storeItemList);
            //set up the request value and callout 
            doCallout(storeItemList,newEntrylist);
        }
        system.debug(resultList);
        system.debug(newosIds.size());
        
        if(resultList!=null && newosIds!=null){
            List<DIC_TemporaryOrderHeader__c>  hlist=[select id,name,DIC_Status__c,DIC_Error_Message__c from DIC_TemporaryOrderHeader__c where id in :newosIds];
            Integer cout=0;
            for(DIC_TemporaryOrderHeader__c header:hlist){
                if(resultList[cout]=='success'){
                    header.DIC_Status__c='3';
                    header.DIC_Error_Message__c=null;
                }else{
                    header.DIC_Status__c='2';
                    header.DIC_Error_Message__c=resultList[cout];
                } 
                cout=cout+1;
            }
            update hlist;
        }
        
    }
    
    
}