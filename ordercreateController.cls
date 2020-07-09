public class ordercreateController {
    public  list<DIC_TemporaryOrderHeader__c> os{get;set;}
    public  list<string> msglist{get;set;}
    public  Integer osCount{get;set;}
    public  list<ID> osIds;
    public Id jobId { get; set; }
    public Boolean keepPolling { get; set; }


    public  PageReference listView() {
           Schema.DescribeSObjectResult destination = DIC_TemporaryOrderHeader__c.sObjectType.getDescribe();
           //here is the explanation
           //every sobject has a code to stand for itself,like account is 001
           //so when you get the code for Sobject,you can give the code to PageReference
           PageReference pageRef = new PageReference('/' + destination.getKeyPrefix() );
           pageRef.setRedirect(true);
           return pageRef;
    }
	public  ordercreateController(ApexPages.StandardSetController controller) {        
        //you can get the selected data from previous page
		 os=controller.getSelected();  
        if(os==null){
           osCount=0;
           return;
        }else{
           osCount=os.size(); 
        }

        osIds = new list<ID>();
        msglist= new list<string>();
        for(DIC_TemporaryOrderHeader__c he:os){
            osIds.add(he.Id);
            system.debug(he);
        }
		os=[select id,name,DIC_Sold_To__r.name,DIC_Status__c from DIC_TemporaryOrderHeader__c where id in :osIds];         
         system.debug(os);
    }
    
    //here is the func,which called from action poller every 5s to check the process of batch
     public void actionPollAction() {
        AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id = :jobId];
        if(job.Status == 'Queued' || job.Status == 'Holding' || job.Status == 'Preparing') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'We are in the '+job.Status.toLowerCase()+' status...'));
        } else if(job.Status != 'Completed' && job.Status != 'Aborted') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'We are in '+job.Status.toLowerCase()+' status: '+Math.floor(100.0*job.JobItemsProcessed/job.TotalJobItems)+'%...')); 
        } else {
            //when batch is completed,we update the statue for refreshing page
            os=[select id,name,DIC_Sold_To__r.name,DIC_Status__c from DIC_TemporaryOrderHeader__c where id in :osIds];
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The job is now '+job.Status.toLowerCase()+'.'));
            keepPolling = false;
        }
    }
    
    
    
    public   void   create(){
       //prepareData(osIds);
        orderCreateBatch oBatch=new orderCreateBatch(osIds);
        jobId=Database.executeBatch(oBatch);     

        keepPolling = true;
        actionPollAction();

    }

}