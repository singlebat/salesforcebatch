@isTest
public class orderCreateBatchTest {

    
    static testMethod void describeTest() {
        createPrepareData();
        orderCreateBatchTest();
    }
    
    @isTest(SeeAllData=true)
    static void orderCreateBatchTest(){
        Test.startTest();
        Test.SetMock(HttpCallOutMock.class, new orderCreateBatchMockTest());
        orderCreateBatch eb= new orderCreateBatch(null);
        database.executeBatch(eb,8);
        Test.stopTest();
    }
    
    static void createPrepareData(){
        
        //create account
        Account acc = new Account();
        acc.Name='testAccount1';
        acc.DIC_Partner_Function__c='AG';
        acc.DIC_Sales_Org__c='EA00';
        acc.DIC_Currency__c='JP';
        acc.AccountNumber='0012';
        insert acc;
        
        //create price book
        Pricebook2 pri = new Pricebook2();
        pri.Name='testPriceBook1';
        pri.DIC_Document_Type__c='ZKB';
        pri.DIC_Sold_To__c=acc.id;
        pri.DIC_Unloading_Point__c='123';
        pri.DIC_User__c='user1';
        pri.DIC_Manual_Flag__c=false;
        insert pri;
        
        Pricebook2 pri2 = new Pricebook2();
        pri2.Name='testPriceBook2';
        pri2.DIC_Document_Type__c='ZKB';
        pri2.DIC_Sold_To__c=acc.id;
        pri2.DIC_Unloading_Point__c='123';
        pri2.DIC_User__c='user2';
        pri2.DIC_Manual_Flag__c=true;
        insert pri2;
        
        DIC_TemporaryOrderHeader__c header1=new DIC_TemporaryOrderHeader__c();
        header1.DIC_Requested_Delivery_Date__c=Date.today();
        header1.DIC_Sold_To__c=acc.id;
        header1.DIC_Ship_To__c=acc.id;
        header1.DIC_Price_Book__c=pri.id;
        header1.DIC_Data_Source__c='1';
        header1.DIC_Status__c='1';
        insert header1;
        
        
        DIC_TemporaryOrderHeader__c header2=new DIC_TemporaryOrderHeader__c();
        header2.DIC_Requested_Delivery_Date__c=Date.today();
        header2.DIC_Sold_To__c=acc.id;
        header2.DIC_Ship_To__c=acc.id;
        header2.DIC_Price_Book__c=pri2.id;
        header2.DIC_Data_Source__c='1';
        header2.DIC_Status__c='1';
        insert header2;
        
        
        DIC_TemporaryOrderItem__c item1=new DIC_TemporaryOrderItem__c();
        item1.DIC_Quantity__c=12;
        item1.DIC_Sales_Unit__c=null;
        item1.DIC_Delivery_Date__c=Date.today();
        item1.DIC_Temporary_Order_Header__c=header1.id;
        insert item1;
        
        

        
        overcast__ConnectionType__c conType= new overcast__ConnectionType__c();
        conType.Name='SAP';   
        insert conType;
        
        overcast__Connection_String__c con=new overcast__Connection_String__c();
        con.Name='SAP';
        con.overcast__ConnectionType__c=conType.id;
        con.overcast__ConnectionString2__c='ASHOST=159.211.182.43 SYSNR=00 CLIENT=220 USER=OCREMOTE_EN IDLE_CHECK_TIME=60 IDLE_TIMEOUT=60';
        con.overcast__Sensitive__c='dyo8qz5pWT+rTQDw9/fF/+a8Vi+8NgbLoTwVZJSJfno=';
        con.overcast__NamedCredential__c='SAPLogin';
        insert con;
        
        overcast__SecureAgent__c agent=new overcast__SecureAgent__c();
        agent.overcast__Hostname__c='VMTQX003';
        agent.overcast__GlobalIP__c='159.211.248.250';
        agent.overcast__LocalIP__c='159.211.182.58';
        agent.name='VMTQX003'; 
        agent.overcast__AgentID__c='edda4e9c-4e4c-4dbd-9c44-7104f36fb68f';
        insert agent;
		
		overcast__SecureAgentRelationship__c aship= new overcast__SecureAgentRelationship__c();
        aship.overcast__SecureAgent__c=agent.id;
        aship.overcast__ConnectionString__c=con.id;
        insert aship;
        
        
        RecordType re1 = [Select Id,DeveloperName  From RecordType where sobjecttype = 'overcast__Scenario__c' and DeveloperName ='realtime'];

        overcast__Scenario__c s1= new overcast__Scenario__c();
        s1.Name='DIC_sapSalesOrderCreate';
        s1.overcast__Connection_String__c=con.id;
        s1.RecordTypeId=re1.id;
        s1.overcast__Active__c=true;
        insert s1;
        

        
        
        
    }
    
    
}