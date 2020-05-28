@isTest
public class EDIDataConversionScheduleTest {

        @testSetup static void setup() {
            // Test data setup
            // Create  data 
            createPrepareData();
        }
    
        @isTest static void EDIDataConversionScheduleTest() {
            // Perform test
            Test.startTest();
            EDIDataConversionSchedule s=new EDIDataConversionSchedule();
            String CRON_EXP = '0 0 13 * * ?';
            String jobId =system.schedule('EDIDataConversionSchedule', CRON_EXP, s);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
			system.debug(ct.NextFireTime);
            Test.stopTest();

        }    
    
        @isTest static void TestSoldError() {
            Account ac = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            //create edi data-------sold error
            DIC_EDIData__c ediData1 = new DIC_EDIData__c();
            ediData1.DIC_Ship_To__c = ac.id;
            ediData1.DIC_Sold_To__c = ac.id;
            ediData1.DIC_Price_Book__c = pri.id;
            ediData1.DIC_Status__c='1';
            ediData1.DIC_Sold_To_Data_Field1__c = 'Sold2';
            ediData1.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData1.DIC_Material_Data_Field1__c = 'Material1';
            ediData1.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData1.DIC_Quantity__c=1;
            ediData1.DIC_FileID__c='001';
            ediData1.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData1;
            
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Sold To Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('1' , MailSender.DIC_Number_of_Error__c,'Sold To Translation Error：if num does not equal 1 you will see this msg');
                }
            }

        }   

       @isTest static void TestCountSoldError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            //create edi data-------sold error
            DIC_EDIData__c ediData1 = new DIC_EDIData__c();
            ediData1.DIC_Ship_To__c = acc.id;
            ediData1.DIC_Sold_To__c = acc.id;
            ediData1.DIC_Price_Book__c = pri.id;
            ediData1.DIC_Status__c='1';
            ediData1.DIC_Sold_To_Data_Field1__c = 'Sold2';
            ediData1.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData1.DIC_Material_Data_Field1__c = 'Material1';
            ediData1.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData1.DIC_Quantity__c=1;
            ediData1.DIC_FileID__c='001';
            ediData1.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData1;
           
            //test for count error(2)
            //create edi data-------sold error
            DIC_EDIData__c ediData11 = new DIC_EDIData__c();
            ediData11.DIC_Ship_To__c = acc.id;
            ediData11.DIC_Sold_To__c = acc.id;
            ediData11.DIC_Price_Book__c = pri.id;
            ediData11.DIC_Status__c='1';
            ediData11.DIC_Sold_To_Data_Field1__c = 'Sold2';
            ediData11.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData11.DIC_Material_Data_Field1__c = 'Material1';
            ediData11.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData11.DIC_Quantity__c=1;
            ediData11.DIC_FileID__c='001';
            ediData11.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData11;
            
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Sold To Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('2' , MailSender.DIC_Number_of_Error__c,'Sold To Translation Error：if num does not equal 2 you will see this msg');
                }
            }

        }   
    
    
       @isTest static void TestShipError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
            //create edi data-------ship error
            DIC_EDIData__c ediData2 = new DIC_EDIData__c();
            ediData2.DIC_Ship_To__c = acc.id;
            ediData2.DIC_Sold_To__c = acc.id;
            ediData2.DIC_Price_Book__c = pri.id;
            ediData2.DIC_Status__c='1';
            ediData2.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData2.DIC_Ship_To_Data_Field1__c = 'Ship2';
            ediData2.DIC_Material_Data_Field1__c = 'Material1';
            ediData2.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData2.DIC_Quantity__c=1;
            ediData2.DIC_FileID__c='001';
            ediData2.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData2;
           
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Ship To Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('1' , MailSender.DIC_Number_of_Error__c,'Ship To Translation Error：if num does not equal 1 you will see this msg');
                }
            }

        }  
       @isTest static void TestCountShipError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
           
            //create edi data-------ship error
            DIC_EDIData__c ediData2 = new DIC_EDIData__c();
            ediData2.DIC_Ship_To__c = acc.id;
            ediData2.DIC_Sold_To__c = acc.id;
            ediData2.DIC_Price_Book__c = pri.id;
            ediData2.DIC_Status__c='1';
            ediData2.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData2.DIC_Ship_To_Data_Field1__c = 'Ship2';
            ediData2.DIC_Material_Data_Field1__c = 'Material1';
            ediData2.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData2.DIC_Quantity__c=1;
            ediData2.DIC_FileID__c='001';
            ediData2.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData2;
           
  			//test for count error(3)
            //create edi data-------ship error
            DIC_EDIData__c ediData21 = new DIC_EDIData__c();
            ediData21.DIC_Ship_To__c = acc.id;
            ediData21.DIC_Sold_To__c = acc.id;
            ediData21.DIC_Price_Book__c = pri.id;
            ediData21.DIC_Status__c='1';
            ediData21.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData21.DIC_Ship_To_Data_Field1__c = 'Ship2';
            ediData21.DIC_Material_Data_Field1__c = 'Material1';
            ediData21.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData21.DIC_Quantity__c=1;
            ediData21.DIC_FileID__c='001';
            ediData21.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData21;
        
            DIC_EDIData__c ediData22 = new DIC_EDIData__c();
            ediData22.DIC_Ship_To__c = acc.id;
            ediData22.DIC_Sold_To__c = acc.id;
            ediData22.DIC_Price_Book__c = pri.id;
            ediData22.DIC_Status__c='1';
            ediData22.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData22.DIC_Ship_To_Data_Field1__c = 'Ship2';
            ediData22.DIC_Material_Data_Field1__c = 'Material1';
            ediData22.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData22.DIC_Quantity__c=1;
            ediData22.DIC_FileID__c='001';
            ediData22.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData22;
            
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Ship To Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('3' , MailSender.DIC_Number_of_Error__c,'Ship To Translation Error：if num does not equal 3 you will see this msg');
                }
            }

        }  
    
     @isTest static void TestMaterialError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
            //create edi data-------Material error
            DIC_EDIData__c ediData3 = new DIC_EDIData__c();
            ediData3.DIC_Ship_To__c = acc.id;
            ediData3.DIC_Sold_To__c = acc.id;
            ediData3.DIC_Price_Book__c = pri.id;
            ediData3.DIC_Status__c='1';
            ediData3.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData3.DIC_Ship_To_Data_Field1__c = 'Ship1';
         	ediData3.DIC_Material_Data_Field1__c = 'Material2';
            ediData3.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData3.DIC_Quantity__c=1;
            ediData3.DIC_FileID__c='001';
            ediData3.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData3;
           
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Material Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('1' , MailSender.DIC_Number_of_Error__c,'Material Translation Error：if num does not equal 1 you will see this msg');
                }
            }

        }  
    
    	@isTest static void TestCountMaterialError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
            //create edi data-------Material error
            DIC_EDIData__c ediData3 = new DIC_EDIData__c();
            ediData3.DIC_Ship_To__c = acc.id;
            ediData3.DIC_Sold_To__c = acc.id;
            ediData3.DIC_Price_Book__c = pri.id;
            ediData3.DIC_Status__c='1';
            ediData3.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData3.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData3.DIC_Material_Data_Field1__c = 'Material2';
            ediData3.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData3.DIC_Quantity__c=1;
            ediData3.DIC_FileID__c='001';
            ediData3.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData3;
           
            //test for count error(2)
            //create edi data-------Material error
            DIC_EDIData__c ediData31 = new DIC_EDIData__c();
            ediData31.DIC_Ship_To__c = acc.id;
            ediData31.DIC_Sold_To__c = acc.id;
            ediData31.DIC_Price_Book__c = pri.id;
            ediData31.DIC_Status__c='1';
            ediData31.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData31.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData31.DIC_Material_Data_Field1__c = 'Material2';
            ediData31.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData31.DIC_Quantity__c=1;
            ediData31.DIC_FileID__c='001';
            ediData31.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData31;
            
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Material Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('2' , MailSender.DIC_Number_of_Error__c,'Material Translation Error：if num does not equal 2 you will see this msg');
                }
            }

        }  
    
    @isTest static void TestPricebookError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
             //create edi data-------pricebook error
             DIC_EDIData__c ediData4 = new DIC_EDIData__c();
             ediData4.DIC_Ship_To__c = acc.id;
             ediData4.DIC_Sold_To__c = acc.id;
             ediData4.DIC_Price_Book__c = pri.id;
             ediData4.DIC_Status__c='1';
             ediData4.DIC_Sold_To_Data_Field1__c = 'Sold1';
             ediData4.DIC_Ship_To_Data_Field1__c = 'Ship1';
             ediData4.DIC_Material_Data_Field1__c = 'Material1';
         	 ediData4.DIC_Pricebook_Data_Field1__c = 'Pricebook2';
             ediData4.DIC_Quantity__c=1;
             ediData4.DIC_FileID__c='001';
             ediData4.DIC_Requested_Delivery_Date__c=Date.today();
             insert ediData4;   
           
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Pricebook Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('1' , MailSender.DIC_Number_of_Error__c,'Pricebook Translation Error：if num does not equal 1 you will see this msg');
                }
            }

        }  
    
     @isTest static void TestCountPricebookError() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
             //create edi data-------pricebook error
             DIC_EDIData__c ediData4 = new DIC_EDIData__c();
             ediData4.DIC_Ship_To__c = acc.id;
             ediData4.DIC_Sold_To__c = acc.id;
             ediData4.DIC_Price_Book__c = pri.id;
             ediData4.DIC_Status__c='1';
             ediData4.DIC_Sold_To_Data_Field1__c = 'Sold1';
             ediData4.DIC_Ship_To_Data_Field1__c = 'Ship1';
             ediData4.DIC_Material_Data_Field1__c = 'Material1';
             ediData4.DIC_Pricebook_Data_Field1__c = 'Pricebook2';
             ediData4.DIC_Quantity__c=1;
             ediData4.DIC_FileID__c='001';
             ediData4.DIC_Requested_Delivery_Date__c=Date.today();
             insert ediData4;   
         
             //test for count error(2)
             //create edi data-------pricebook error
             DIC_EDIData__c ediData41 = new DIC_EDIData__c();
             ediData41.DIC_Ship_To__c = acc.id;
             ediData41.DIC_Sold_To__c = acc.id;
             ediData41.DIC_Price_Book__c = pri.id;
             ediData41.DIC_Status__c='1';
             ediData41.DIC_Sold_To_Data_Field1__c = 'Sold1';
             ediData41.DIC_Ship_To_Data_Field1__c = 'Ship1';
             ediData41.DIC_Material_Data_Field1__c = 'Material1';
             ediData41.DIC_Pricebook_Data_Field1__c = 'Pricebook2';
             ediData41.DIC_Quantity__c=1;
             ediData41.DIC_FileID__c='001';
             ediData41.DIC_Requested_Delivery_Date__c=Date.today();
             insert ediData41; 
           
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Pricebook Translation Error'){
                    system.debug(MailSender.DIC_Number_of_Error__c);
                    System.assertEquals('2' , MailSender.DIC_Number_of_Error__c,'Pricebook Translation Error：if num does not equal 2 you will see this msg');
                }
            }

        }  
    
    @isTest static void TestTemporaryOrderSuccess() {
            Account acc = [select id from Account limit 1];
            Pricebook2 pri=[select id from Pricebook2 limit 1];
            
            //create edi data-------Temporary Order success
            DIC_EDIData__c ediData5 = new DIC_EDIData__c();
            ediData5.DIC_Ship_To__c = acc.id;
            ediData5.DIC_Sold_To__c = acc.id;
            ediData5.DIC_Price_Book__c = pri.id;
            ediData5.DIC_Status__c='1';
            ediData5.DIC_Sold_To_Data_Field1__c = 'Sold1';
            ediData5.DIC_Ship_To_Data_Field1__c = 'Ship1';
            ediData5.DIC_Material_Data_Field1__c = 'Material1';
            ediData5.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            ediData5.DIC_Quantity__c=1;
            ediData5.DIC_FileID__c='001';
            ediData5.DIC_Requested_Delivery_Date__c=Date.today();
            insert ediData5;  
           
            Test.startTest();
            //run as system admin
 			EDIDataConversionBatch eb= new EDIDataConversionBatch();
            database.executeBatch(eb);
            System.debug('Current User: ' + UserInfo.getUserName());
            Test.stopTest();
            
            //check the result for test
            List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
            system.debug(MailSenderList);
            for (DIC_MailSender__c MailSender : MailSenderList) {
                if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Temp Order Entry'){
                    //we don't count Temp Order Registration
                    system.debug(MailSender.DIC_Number_of_Error__c);
                }
            }

        }  
    
    
    	//test for Temporary Order error
    	@isTest
        static void TemporaryOrderError(){
                //create user
                Profile p = [SELECT Id FROM Profile WHERE Name='DIC_SalesUser']; 
                User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                  DIC_Sales_Org__c ='E300',
                                  TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US', ProfileId = p.Id, 
                                  UserName='99999999standarduser@testorg.com');
                
                Account acc = [select id from Account limit 1];
            	Pricebook2 pri=[select id from Pricebook2 limit 1];
                //create edi data-------Temporary Order error
                DIC_EDIData__c ediData5 = new DIC_EDIData__c();
                ediData5.DIC_Ship_To__c = acc.id;
                ediData5.DIC_Sold_To__c = acc.id;
                ediData5.DIC_Price_Book__c = pri.id;
                ediData5.DIC_Status__c='1';
                ediData5.DIC_Sold_To_Data_Field1__c = 'Sold1';
                ediData5.DIC_Ship_To_Data_Field1__c = 'Ship1';
                ediData5.DIC_Material_Data_Field1__c = 'Material1';
                ediData5.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
                ediData5.DIC_Quantity__c=1;
                ediData5.DIC_FileID__c='001';
                ediData5.DIC_Requested_Delivery_Date__c=Date.today();
                insert ediData5;  
            
                System.runAs(u) {
                    Test.startTest();
                    EDIDataConversionBatch eb= new EDIDataConversionBatch();
                    database.executeBatch(eb);
                    System.debug('Current User: ' + UserInfo.getUserName());
                    Test.stopTest();
                }
            
              	//check the result for test
                List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
                system.debug(MailSenderList);
                for (DIC_MailSender__c MailSender : MailSenderList) {
                    if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Temp Order Entry Error'){
                        //we don't count Temp Order Registration Error
                        system.debug(MailSender.DIC_Number_of_Error__c);
                    }
                }
            	
        }

    	//count for Temporary Order error
    	@isTest
        static void CountTemporaryOrderError(){
                //create user
                Profile p = [SELECT Id FROM Profile WHERE Name='DIC_SalesUser']; 
                User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                  DIC_Sales_Org__c ='E300',
                                  TimeZoneSidKey='America/Los_Angeles',LocaleSidKey='en_US', ProfileId = p.Id, 
                                  UserName='99999999standarduser@testorg.com');
                
                Account acc = [select id from Account limit 1];
            	Pricebook2 pri=[select id from Pricebook2 limit 1];
                //create edi data-------Temporary Order error
                DIC_EDIData__c ediData5 = new DIC_EDIData__c();
                ediData5.DIC_Ship_To__c = acc.id;
                ediData5.DIC_Sold_To__c = acc.id;
                ediData5.DIC_Price_Book__c = pri.id;
                ediData5.DIC_Status__c='1';
                ediData5.DIC_Sold_To_Data_Field1__c = 'Sold1';
                ediData5.DIC_Ship_To_Data_Field1__c = 'Ship1';
                ediData5.DIC_Material_Data_Field1__c = 'Material1';
                ediData5.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
                ediData5.DIC_Quantity__c=1;
                ediData5.DIC_FileID__c='001';
                ediData5.DIC_Requested_Delivery_Date__c=Date.today();
                insert ediData5;  

				 //create edi data-------Temporary Order error
                DIC_EDIData__c ediData6 = new DIC_EDIData__c();
                ediData6.DIC_Ship_To__c = acc.id;
                ediData6.DIC_Sold_To__c = acc.id;
                ediData6.DIC_Price_Book__c = pri.id;
                ediData6.DIC_Status__c='1';
                ediData6.DIC_Sold_To_Data_Field1__c = 'Sold1';
                ediData6.DIC_Ship_To_Data_Field1__c = 'Ship1';
                ediData6.DIC_Material_Data_Field1__c = 'Material1';
                ediData6.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
                ediData6.DIC_Quantity__c=1;
                ediData6.DIC_FileID__c='001';
                ediData6.DIC_Requested_Delivery_Date__c=Date.today();
                insert ediData6;  
				            
                System.runAs(u) {
                    Test.startTest();
                    EDIDataConversionBatch eb= new EDIDataConversionBatch();
                    database.executeBatch(eb);
                    System.debug('Current User: ' + UserInfo.getUserName());
                    Test.stopTest();
                }
            
              	//check the result for test
                List<DIC_MailSender__c> MailSenderList = [SELECT Id,name,DIC_Mail_Type__c,DIC_Sold_To__c,DIC_Number_of_Error__c FROM DIC_MailSender__c];
                system.debug(MailSenderList);
                for (DIC_MailSender__c MailSender : MailSenderList) {
                    if(String.valueOf(MailSender.DIC_Mail_Type__c) == 'Temp Order Entry Error'){
                        system.debug(MailSender.DIC_Number_of_Error__c);
                    }
                }
            	
        }
    
    
        static void createPrepareData(){
            
            //create account
            Account acc = new Account();
            acc.Name='testAccount1';
            acc.DIC_Partner_Function__c='AG';
            acc.DIC_Sales_Org__c='EA00';
            insert acc;
            
            //create product
            Product2 pro = new Product2();
            pro.Name='testProduct1';
            insert pro;

            //create price book
            Pricebook2 pri = new Pricebook2();
            pri.Name='testPriceBook1';
            pri.DIC_Document_Type__c='ZKB';
            pri.DIC_Sold_To__c=acc.id;
            insert pri;

            //get RecordType for DIC_TranslationMaster__c
            RecordType re1 = [Select Id From RecordType where sobjecttype = 'DIC_TranslationMaster__c' and DeveloperName ='DIC_Sold_To'];
            RecordType re2 = [Select Id From RecordType where sobjecttype = 'DIC_TranslationMaster__c' and DeveloperName ='DIC_Ship_To'];
            RecordType re3 = [Select Id From RecordType where sobjecttype = 'DIC_TranslationMaster__c' and DeveloperName ='DIC_Material'];
            RecordType re4 = [Select Id From RecordType where sobjecttype = 'DIC_TranslationMaster__c' and DeveloperName ='DIC_Price_Book'];
            
            //create DIC_TranslationMaster__c
            DIC_TranslationMaster__c master1 = new DIC_TranslationMaster__c();
            master1.RecordTypeId = re1.id;
            master1.DIC_Sold_To_Data_Field1__c = 'Sold1';
            master1.DIC_SoldToAccount__c = acc.id;
            master1.DIC_FileID__c='001';
            insert master1;

            DIC_TranslationMaster__c master2 = new DIC_TranslationMaster__c();
            master2.RecordTypeId = re2.id;
            master2.DIC_Ship_To_Data_Field1__c = 'Ship1';
            master2.DIC_SoldToAccount__c = acc.id;
            master2.DIC_ShipToAccount__c = acc.id;
            master2.DIC_FileID__c='001';
            insert master2;

            DIC_TranslationMaster__c master3 = new DIC_TranslationMaster__c();
            master3.RecordTypeId = re3.id;
            master3.DIC_Material_Data_Field1__c = 'Material1';
            master3.DIC_SoldToAccount__c = acc.id;
            master3.DIC_Material__c = pro.id;
            master3.DIC_FileID__c='001';
            insert master3;

            DIC_TranslationMaster__c master4 = new DIC_TranslationMaster__c();
            master4.RecordTypeId = re4.id;
            master4.DIC_Pricebook_Data_Field1__c = 'Pricebook1';
            master4.DIC_SoldToAccount__c = acc.id;
            master4.DIC_PriceBook__c = pri.id;
            master4.DIC_Material__c = pro.id;
            master4.DIC_FileID__c='001';
            insert master4;

        }

}