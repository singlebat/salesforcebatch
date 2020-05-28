global class EDIDataConversionBatch implements Database.Batchable<sObject>, Database.Stateful {

    private static String statusBeforeTran         = '1';
    private static String statusSoldToTranError    = '2';
    private static String statusShipToTranError    = '3';
    private static String statusMaterialTranError  = '4';
    private static String statusPriceBookTranError = '5';
    private static String statusTranslated         = '6';
    private static String statusTempOrderError     = '7';
    private static String statusTempOrderCreated   = '8';

    //add by tian
    private static string mailErrorTypeSold        = 'Sold To Translation Error';
    private static string mailErrorTypeShip        = 'Ship To Translation Error';
    private static string mailErrorTypeMaterial    = 'Material Translation Error';
    private static string mailErrorTypePricebook   = 'Pricebook Translation Error';
    private static string mailErrorTypeTempSuc     = 'Temp Order Entry';
    private static string mailErrorTypeTempError   = 'Temp Order Entry Error';
    
    private static string DIC_EDIId;
    private static string Temp_OrderId;

    private Set<string> pbeRecordKeySet;              //PriceBookEntry抽出用キーセット
    private map<string, string> soldToTransMap;       //SoldTo翻訳マスタ一覧
    private map<string, string> shipToTransMap;       //ShipTo翻訳マスタ一覧
    private map<string, string> materialTransMap;     //Material翻訳マスタ一覧
    private map<string, string> priceBookTransMap;    //PriceBook翻訳マスタ一覧
	private map<string, string> fileIDTransMap;       //fileIDマスタ一覧
    
    //-----add by tian
    private List<DIC_MailSender__c> mailsenderList;//collect error message for mailing
    private map<string,DIC_MailSender__c> countErrorMap;//countErrorMap
    private List<DIC_EDIData__c> newEdiDataList;//collect the sorted data

    global Database.QueryLocator start(Database.BatchableContext bc) {

        String query = 'SELECT Id, ';
               query += 'DIC_Sold_To_Sales_Org__c, ';         //information for org
			   query += 'DIC_FileID__c, ';                    //information for sys
        
               query += 'Name, ';                             //採番番号
               query += 'DIC_SoldToCondKey__c, ';             //受注先判定条件
               query += 'DIC_ShipToCondKey__c, ';             //出荷先判定条件
               query += 'DIC_MaterialCondKey__c, ';           //品目判定条件
               query += 'DIC_PriceBookCondKey__c, ';          //価格表判定条件
               query += 'DIC_Item_Requested_Delivery_Date__c, ';   //納期
               query += 'DIC_Sold_To__c, ';                   //受注先
               query += 'DIC_Quantity__c, ';                  //数量
               query += 'DIC_PO_Number__c, ';                 //PO番号
               query += 'DIC_PO_Date__c, ';                   //PO日付
               query += 'DIC_Status__c ';                     //ステータス
               query += 'FROM  DIC_EDIData__c ';              //注文素データ
               query += 'WHERE DIC_Status__c = :statusBeforeTran ';           //仮受注未作成分を対象
               query += 'ORDER BY DIC_Sold_To__c,DIC_Ship_To__c,DIC_Price_Book__c,Name';//sort

        System.debug('Query:'+ query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<DIC_EDIData__c> ediDataList) {

        if(ediDataList.isEmpty()){
           System.debug('No conversion target data exists');
           return;
        }

        System.debug('ediDataList:' + ediDataList);

        pbeRecordKeySet    = new Set<String>();
        soldToTransMap     = new Map<string, string>();
        shipToTransMap     = new Map<string, string>();
        materialTransMap   = new Map<string, string>();
        priceBookTransMap  = new Map<string, string>();
		fileIDTransMap     = new Map<string, string>();
        //-----add by tian
        newEdiDataList     = new List<DIC_EDIData__c>();
        countErrorMap      = new map<string,DIC_MailSender__c>();
        //loop countErrorMap convert to list
        mailsenderList     = new List<DIC_MailSender__c>();

        
        RecordType re1 = [Select Id From RecordType where sobjecttype = 'DIC_MailSender__c' and DeveloperName ='DIC_EDI'];
        DIC_EDIId      = re1.id;
        RecordType re2 = [Select Id From RecordType where sobjecttype = 'DIC_MailSender__c' and DeveloperName ='Temp_Order'];
		Temp_OrderId   = re2.id;    
        
        //Convert 
        convertData(ediDataList,newEdiDataList);


        //add by tian
        System.debug('tian:' + countErrorMap);
        for(DIC_MailSender__c senderTemp:countErrorMap.values()){
            mailsenderList.add(senderTemp);
        }

        //Create Temporary order object record
        if(newEdiDataList != null){
            createTemporaryOrder(newEdiDataList);
        }
        
/*
		System.debug('tian:this is  all data' + ediDataList);
        for(DIC_EDIData__c edi:ediDataList){
            system.debug(edi);
        }
        System.debug('tian:this is  converted data' + newEdiDataList);
        for(DIC_EDIData__c edi:newEdiDataList){
            system.debug(edi);
        }
        
        System.debug('tian:this is  error data' + mailsenderList);
        for(DIC_MailSender__c edi:mailsenderList){
            system.debug(edi);
        }
*/        
        try {
            //-----add by tian
            insert mailsenderList;
            update ediDataList;
            
        } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());
        }

    }


    global void finish(Database.BatchableContext bc) {
        //Do Nothing
    }
    

    private void convertData(List<DIC_EDIData__c> ediDataList,List<DIC_EDIData__c> newEdiDataList) {

        //Get File ID translation master record
        for (DIC_TranslationMaster__c tm : [SELECT DIC_FileID__c, DIC_SoldToAccount__c
                                              FROM DIC_TranslationMaster__c]){
            System.debug('Sold To Cond Key:' + tm.DIC_FileID__c);
            if(tm.DIC_FileID__c!=null && tm.DIC_FileID__c!=''){
                 fileIDTransMap.put(tm.DIC_FileID__c, tm.DIC_SoldToAccount__c);
            }
        }
        
        
        //Get sold-to translation master record
        for (DIC_TranslationMaster__c tm : [SELECT DIC_FileID__c,DIC_SoldToCondKey__c, DIC_SoldToAccount__c
                                              FROM DIC_TranslationMaster__c
                                             WHERE RecordType.DeveloperName = 'DIC_Sold_To']){
            System.debug('Sold To Cond Key:' + tm.DIC_SoldToCondKey__c);
            soldToTransMap.put(tm.DIC_FileID__c+tm.DIC_SoldToCondKey__c, tm.DIC_SoldToAccount__c);
        }

        //Get ship-to translation master record
        for (DIC_TranslationMaster__c tm : [SELECT DIC_FileID__c,DIC_ShipToCondKey__c, DIC_ShipToAccount__c
                                              FROM DIC_TranslationMaster__c
                                             WHERE RecordType.DeveloperName = 'DIC_Ship_To']){
            shipToTransMap.put(tm.DIC_FileID__c+tm.DIC_ShipToCondKey__c, tm.DIC_ShipToAccount__c);
        }

        //Get material translation master record
        for (DIC_TranslationMaster__c tm : [SELECT DIC_FileID__c,DIC_MaterialCondKey__c, DIC_Material__c
                                                FROM DIC_TranslationMaster__c
                                                WHERE  RecordType.DeveloperName = 'DIC_Material']){
            materialTransMap.put(tm.DIC_FileID__c+tm.DIC_MaterialCondKey__c, tm.DIC_Material__c);
        }

        //Get pricebook translation master record
        for (DIC_TranslationMaster__c tm : [SELECT DIC_FileID__c,DIC_PriceBookCondKey__c, DIC_PriceBook__c
                                                FROM DIC_TranslationMaster__c
                                                WHERE RecordType.DeveloperName = 'DIC_Price_Book']){
            priceBookTransMap.put(tm.DIC_FileID__c+tm.DIC_PriceBookCondKey__c, tm.DIC_PriceBook__c);
        }

        for(DIC_EDIData__c ediData : ediDataList){
            
            //Translation step0 : Check  File ID 
            String fileID =fileIDTransMap.get(ediData.DIC_FileID__c);
            system.debug(fileIDTransMap);
            system.debug(fileID);
            system.debug(ediData.DIC_FileID__c);
            if(fileID == null){
                DIC_MailSender__c sender = new DIC_MailSender__c();
                sender.DIC_Mail_Type__c  = mailErrorTypeTempError;
                sender.DIC_Sold_To__c    = ediData.DIC_Sold_To__c;
                mailsenderList.add(sender);
                //dont forget to modify the status of edi record
                ediData.DIC_Status__c = statusTempOrderError;
                continue;
            }

            //Translation step1 : Sold-to
            String soldToId = soldToTransMap.get(ediData.DIC_FileID__c+ediData.DIC_SoldToCondKey__c);
            System.debug('ediData:' + ediData);
            System.debug('Sold To Trans Map:' + soldToTransMap);
            System.debug('Sold To Cond Key:' + ediData.DIC_SoldToCondKey__c);
            if(soldToId != null){
                ediData.DIC_Sold_To__c = soldToId;
            }else{
                ediData.DIC_Status__c = statusSoldToTranError; //Sold-to Translation Error
                 //-----add by tian
                DIC_MailSender__c oldsender = countErrorMap.get(mailErrorTypeSold + ediData.DIC_Sold_To__c);
                if(oldsender!= null){
                    if(oldsender.DIC_Number_of_Error__c!=null){
                        Integer temp = Integer.valueof(oldsender.DIC_Number_of_Error__c.trim())  + 1;
                        oldsender.DIC_Number_of_Error__c = String.valueOf(temp);
                    }
                    countErrorMap.put(mailErrorTypeSold + ediData.DIC_Sold_To__c,oldsender);
                }else{
                    DIC_MailSender__c sender = new DIC_MailSender__c();
                    sender.DIC_Mail_Type__c  = mailErrorTypeSold;
                    sender.DIC_Sales_Org__c  = ediData.DIC_Sold_To_Sales_Org__c;
                    sender.DIC_Sold_To__c    = ediData.DIC_Sold_To__c;
                    sender.RecordTypeId  = DIC_EDIId;  
                    sender.DIC_Number_of_Error__c  = '1';
                    countErrorMap.put(mailErrorTypeSold + sender.DIC_Sold_To__c,sender);
                }

                continue;//because there is an error has happened,the following steps shall be skipped
                /*
                  ＜--------SoldTo変換エラー対象に追加する処理-------------＞
                  最終的に販売組織単位でエラー件数をまとめてMailSenderにレコードを登録するようにする
                */
            }

            //Translation step2 : Ship-to
            system.debug('tian'+shipToTransMap);
            system.debug('tian'+soldToId + ediData.DIC_ShipToCondKey__c);
            String shipToId = shipToTransMap.get(ediData.DIC_FileID__c+soldToId + ediData.DIC_ShipToCondKey__c);
            system.debug('tian'+shipToId);
            if(shipToId != null){
                ediData.DIC_Ship_To__c = shipToId;
            }else{
                ediData.DIC_Status__c = statusShipToTranError; //Ship-to Translation Error
                 
                //-----add by tian
                 DIC_MailSender__c oldsender = countErrorMap.get(mailErrorTypeShip + ediData.DIC_Sold_To__c);
                if(oldsender!= null){
                    if(oldsender.DIC_Number_of_Error__c!=null){
                        Integer temp = Integer.valueof(oldsender.DIC_Number_of_Error__c.trim())  + 1;
                        oldsender.DIC_Number_of_Error__c = String.valueOf(temp);
                    }
                    countErrorMap.put(mailErrorTypeShip + ediData.DIC_Sold_To__c,oldsender);
                }else{
                    DIC_MailSender__c sender = new DIC_MailSender__c();
                    sender.DIC_Mail_Type__c  = mailErrorTypeShip;
                    sender.DIC_Sales_Org__c  = ediData.DIC_Sold_To_Sales_Org__c;
                    sender.DIC_Sold_To__c    = ediData.DIC_Sold_To__c;
                    sender.RecordTypeId  = DIC_EDIId;  
                    sender.DIC_Number_of_Error__c  = '1' ;
                    countErrorMap.put(mailErrorTypeShip + sender.DIC_Sold_To__c,sender);
                }
                 continue;//because there is an error has happened,the following steps shall be skipped
                /*
                  ＜--------ShipTo変換エラー対象に追加する処理-------------＞
                  最終的にSoldTo単位でエラー件数をまとめてMailSenderオブジェクトにレコードを登録するようにする
                */
            }

            //Translation step3 : Material
            system.debug('tian'+materialTransMap);
            system.debug('tian'+ediData.DIC_Sold_To__c + ediData.DIC_MaterialCondKey__c);
            String productId = materialTransMap.get(ediData.DIC_FileID__c+ediData.DIC_Sold_To__c + ediData.DIC_MaterialCondKey__c);
            system.debug('tian'+productId);
            if(productId != null){
                ediData.DIC_Material__c = productId;
            }else{
                ediData.DIC_Status__c = statusMaterialTranError; //Material Translation Error
                
                //-----add by tian                
                DIC_MailSender__c oldsender = countErrorMap.get(mailErrorTypeMaterial + ediData.DIC_Sold_To__c);
                if(oldsender!= null){
                    if(oldsender.DIC_Number_of_Error__c!=null){
                        Integer temp = Integer.valueof(oldsender.DIC_Number_of_Error__c.trim())  + 1;
                        oldsender.DIC_Number_of_Error__c = String.valueOf(temp);
                    }
                    countErrorMap.put(mailErrorTypeMaterial + ediData.DIC_Sold_To__c,oldsender);
                }else{
                    DIC_MailSender__c sender = new DIC_MailSender__c();
                    sender.DIC_Mail_Type__c  = mailErrorTypeMaterial;
                    sender.DIC_Sales_Org__c  = ediData.DIC_Sold_To_Sales_Org__c;
                    sender.DIC_Sold_To__c    = ediData.DIC_Sold_To__c;
                    sender.RecordTypeId  = DIC_EDIId;  
                    sender.DIC_Number_of_Error__c  ='1';
                    countErrorMap.put(mailErrorTypeMaterial + sender.DIC_Sold_To__c,sender);
                }

                continue;//because there is an error has happened,the following steps shall be skipped
                /*
                    ＜--------Material変換エラー対象に追加する処理-------------＞
                    最終的にSoldTo単位でエラー件数をまとめてMailSenderオブジェクトにレコードを登録するようにする
                */
            }


            //Translation step4 : Pricebook
            system.debug('tian'+priceBookTransMap);
            String key = ediData.DIC_FileID__c+ediData.DIC_Sold_To__c + '/' + productId + ediData.DIC_PriceBookCondKey__c;
            system.debug('tian'+key);
            String pricebookId = priceBookTransMap.get(key);
			system.debug('tian'+pricebookId);
            
            if(pricebookId != null){
                ediData.DIC_Price_Book__c = pricebookId;
                ediData.DIC_Status__c = statusTranslated; //Translated
                ediData.DIC_Sort_Key__c = ediData.DIC_Sold_To__c + '/' +
                                        ediData.DIC_Ship_To__c + '/' +
                                        ediData.DIC_Price_Book__c + '/' +
                                        ediData.Name;

                //Create pricebook entry search key
                String pbeKey = String.valueOf(ediData.DIC_Price_Book__c).substring(0, 15)
                                    + '/' + String.valueOf(ediData.DIC_Material__c).substring(0, 15);
                pbeRecordKeySet.add(pbeKey);

                //add by tian
                //when you get to fourth step,you can prepare for creating the header
                newEdiDataList.add(ediData);

            }else{
                ediData.DIC_Status__c = statusPriceBookTranError; //Pricebook Translation Error

                //-----add by tian                
                DIC_MailSender__c oldsender = countErrorMap.get(mailErrorTypePricebook + ediData.DIC_Sold_To__c);
                if(oldsender!= null){
                    if(oldsender.DIC_Number_of_Error__c!=null){
                        Integer temp = Integer.valueof(oldsender.DIC_Number_of_Error__c.trim())  + 1;
                        oldsender.DIC_Number_of_Error__c = String.valueOf(temp);
                    }
                    countErrorMap.put(mailErrorTypePricebook + ediData.DIC_Sold_To__c,oldsender);
                }else{
                    DIC_MailSender__c sender = new DIC_MailSender__c();
                    sender.DIC_Mail_Type__c  = mailErrorTypePricebook;
                    sender.DIC_Sales_Org__c  = ediData.DIC_Sold_To_Sales_Org__c;
                    sender.DIC_Sold_To__c    = ediData.DIC_Sold_To__c;
                    sender.RecordTypeId  = DIC_EDIId;  
                    sender.DIC_Number_of_Error__c  ='1';
                    countErrorMap.put(mailErrorTypePricebook + sender.DIC_Sold_To__c,sender);
                }

                continue;//because there is an error has happened,the following steps shall be skipped
                //PriceBook割当エラー対象に追加する処理
                /*
                ＜--------Pricebook変換エラー対象に追加する処理-------------＞
                最終的にSoldTo単位でエラー件数をまとめてMailSenderオブジェクトにレコードを登録するようにする
                */
            }

        }
    }

    private void createTemporaryOrder(List<DIC_EDIData__c> newEdiDataList) {

        String bkSoldTo = '', bkShipTo = '', bkPriceBook = '';
        List<DIC_TemporaryOrderItem__c>   orderItems   = new List<DIC_TemporaryOrderItem__c>();
        List<DIC_TemporaryOrderHeader__c> orderHeaders = new List<DIC_TemporaryOrderHeader__c>();
        DIC_TemporaryOrderHeader__c orderHeaderReference;
        Map<String, String> pricebookEntryMap = new Map<String, String>();

        Integer headerCount = 1;
        Integer itemCount = 1;
        String timeStamp = Datetime.now().getTime().format();
        String externalId;

        System.debug('PbeRecordKeySet :' + pbeRecordKeySet);

        //Get pricebook entry record
        for (PricebookEntry pbe : [
            SELECT
                Id,
                DIC_RelationKey__c,
                DIC_Sales_Unit__c
            FROM PricebookEntry
            WHERE DIC_RelationKey__c IN :pbeRecordKeySet
            ]) {
            pricebookEntryMap.put(pbe.DIC_RelationKey__c, pbe.DIC_Sales_Unit__c);
          }

        System.debug('Entries :' + pricebookEntryMap);

        for(DIC_EDIData__c edi : newEdiDataList){

            if(edi.DIC_Status__c != statusTranslated){
                continue;
            }

            //Check if header field value matches previous record
            if( !bkSoldTo.equals(edi.DIC_Sold_To__c)
                || !bkShipTo.equals(edi.DIC_Ship_To__c)
                || !bkPriceBook.equals(edi.DIC_Price_Book__c) ){

                //Holds the header field value for checking in the next record
                bkSoldTo = edi.DIC_Sold_To__c;
                bkShipTo = edi.DIC_Ship_To__c;
                bkPriceBook = edi.DIC_Price_Book__c;

                externalId = timeStamp + '-' + headerCount.format();

                //Create temporary order header record
                DIC_TemporaryOrderHeader__c orderHeader = new DIC_TemporaryOrderHeader__c();
                orderHeader.DIC_Sold_To__c = bkSoldTo;
                orderHeader.DIC_Ship_To__c = bkShipTo;
                orderHeader.DIC_Price_Book__c = bkPriceBook;
                orderHeader.DIC_Data_Source__c = '1';
//                orderHeader.DIC_Status__c = '';
                orderHeader.DIC_External_ID__c = externalId;
                orderHeaders.add(orderHeader);

                orderHeaderReference = new DIC_TemporaryOrderHeader__c(DIC_External_ID__c = externalId);

                headerCount += 1;
//                itemCount = 1;
            }

            //Create Temporary order item record
            DIC_TemporaryOrderItem__c orderItem = new DIC_TemporaryOrderItem__c();
            orderItem.DIC_Material__c = edi.DIC_Material__c;
            orderItem.DIC_Delivery_Date__c = edi.DIC_Item_Requested_Delivery_Date__c;
            orderItem.DIC_Quantity__c = edi.DIC_Quantity__c;
            orderItem.DIC_EDI_Data__c = edi.Id;
//            orderItem.DIC_Sequence__c = itemCount;
            system.debug(orderHeaderReference);
            orderItem.DIC_Temporary_Order_Header__r = orderHeaderReference;
			system.debug(orderItem.DIC_Temporary_Order_Header__r);
            String key = bkPriceBook.substring(0, 15) + '/' + String.valueOf(edi.DIC_Material__c).substring(0, 15);
            orderItem.DIC_Sales_Unit__c = pricebookEntryMap.get(key);

            orderItems.add(orderItem);
//            itemCount += 1;

            //Prepare status change
            edi.DIC_Status__c = statusTempOrderCreated;
        }

         
        List<String> statusChangeEDIList = new List<String>();
        
        system.debug( UserInfo.getUserName());
        system.debug(orderHeaders);
        system.debug(orderItems);
        
        //Insert Temporary Order Header records
        List<Database.SaveResult> saveOrderHeadersList = Database.insert(orderHeaders, false);
        // Iterate through saveResultList based on isSuccess capture the failed records
        for(Integer i=0;i<saveOrderHeadersList.size();i++){
            if (!saveOrderHeadersList.get(i).isSuccess()){
                system.debug(saveOrderHeadersList.get(i).getErrors().get(0).getMessage());
                //-----add by tian
                //we need to count ,and the amount of the temperror is equal to 
                
                DIC_MailSender__c sender = new DIC_MailSender__c();
                sender.DIC_Mail_Type__c  = mailErrorTypeTempError;
                sender.DIC_Sold_To__c    = orderHeaders.get(i).DIC_Sold_To__c;
				sender.RecordTypeId  = DIC_EDIId;                
                Integer temp =0;
                //we shall find the edi id whose status need to be changed
                for(DIC_TemporaryOrderItem__c item : orderItems){
                     system.debug(item.DIC_Temporary_Order_Header__r.DIC_External_ID__c);
                     system.debug(orderHeaders.get(i).DIC_External_ID__c);
                    //this is a OrderItem which is related to the header
                    if(item.DIC_Temporary_Order_Header__r.DIC_External_ID__c == orderHeaders.get(i).DIC_External_ID__c){
                        statusChangeEDIList.add(item.DIC_EDI_Data__c);
                        temp=temp+1;
                    }
                }
                sender.DIC_Number_of_Error__c=String.valueOf(temp);
				mailsenderList.add(sender);
            }else{
                //-----add by tian
                //success,we dont need to count,but its amount is equal to temp headers' amount.
                DIC_MailSender__c sender = new DIC_MailSender__c();
                sender.RecordTypeId  = Temp_OrderId;
                sender.DIC_Mail_Type__c  = mailErrorTypeTempSuc;
                sender.DIC_Ship_To__c    = orderHeaders.get(i).DIC_Ship_To__c;
                sender.DIC_Sold_To__c    = orderHeaders.get(i).DIC_Sold_To__c;
                sender.DIC_Temp_Order_Header_Number__c    = orderHeaders.get(i).id;
                mailsenderList.add(sender);
            }
        }

        system.debug(statusChangeEDIList);
        system.debug(newEdiDataList);
        if(statusChangeEDIList!=Null){
            for(DIC_EDIData__c edi :newEdiDataList){
                for(string EDIid:statusChangeEDIList){
                    if(edi.id==EDIid){
                        edi.DIC_Status__c = statusTempOrderError;
                    }
                }
            }
        }
        //Insert Temporary Order Item records
        List<Database.SaveResult> saveOrderItemsList = Database.insert(orderItems, false);

    }

}