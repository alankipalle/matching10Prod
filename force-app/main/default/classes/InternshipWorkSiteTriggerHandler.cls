/**
* @author       Ajay Kumar Lankipalle
* @date         03/14/2017
* @description  Class for Internship Work Site Triggers New test
*
*    -----------------------------------------------------------------------------
*    Developer                  Date                Description
*    -----------------------------------------------------------------------------
*
*    Ajay Kumar                 03/14/2017          Initial creation
*/
public class InternshipWorkSiteTriggerHandler extends TriggerHandler {   
    
    
    @TestVisible
    protected override String getCustomSettingField() { return 'IsIWSTriggerEnabled__c'; }
    
    @TestVisible
    protected override void BeforeInsert(){        
        
        StageAndCloseDateOnIWSInsert(
            (list<Internship_Work_Site__c>)     Trigger.new); 
        pricePerSeatOnIWSInsert(
            (list<Internship_Work_Site__c>)     Trigger.new);
        populateAccountOnIWSInsert(
            (list<Internship_Work_Site__c>)     Trigger.new);
        
        if(UtilityRunOnce.IWSTriggerSkip){
            CategoryOnIWS(
                (list<Internship_Work_Site__c>)     Trigger.new,
                (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap, 'isInsert');
        }        
    }
    
    @TestVisible
    protected override void BeforeUpdate(){ 
        
        StageAndCloseDateOnIWSUpdate(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap);
        pricePerSeatOnIWSSUpdate(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap);
        populateAccountOnIWSUpdate(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap);
        CategoryOnIWS(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap, 'isUpdate');
    } 
    
    
    
    @TestVisible
    protected override void AfterInsert(){  
        
        UpdateOpportunityStage(
            (list<Internship_Work_Site__c>)     Trigger.new); 
        createInternshipInsert(
            (list<Internship_Work_Site__c>)     Trigger.new); 
        
        
    } 
    
    @TestVisible
    protected override void AfterUpdate(){
        
        UpdateOpportunityStage(
            (list<Internship_Work_Site__c>)     Trigger.new); 
        createInternship(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap);
        
        updateInternships(
            (list<Internship_Work_Site__c>)     Trigger.new, 
            (Map<Id,Internship_Work_Site__c>)   Trigger.oldMap);        
        
      
        
    } 
    
    
    @TestVisible
    protected override void AfterDelete(){
        
    } 
    
    @TestVisible
    protected override void AfterUndelete(){   
               
    } 
    
    /**
* @author       Ajay Kumar
* @date         03/14/2017
* @description  When IWS gets created/updated, populate category based on Opportunity Category.
*/
    
    private void CategoryOnIWS(list<Internship_Work_Site__c> iwss, Map<Id,Internship_Work_Site__c> iwsOldMap,String triggerAction) {
        Set<id> oppids = new Set<id>();        
        for (Internship_Work_Site__c i : iwss) {
            if (String.IsNotBlank(i.Opportunity__c)) {
                if(triggerAction == 'isInsert')
                    oppids.add(i.Opportunity__c);
                if(triggerAction == 'isUpdate'){
                    Internship_Work_Site__c oldIws = iwsOldMap.get(i.id);
                    if((oldIws.Opportunity__c != i.Opportunity__c) || oldIws.Account__c != i.Account__c ){
                        oppids.add(i.Opportunity__c);
                    }
                }
            }
        }
        
        if(oppids.size()>0){
            Map<id,Opportunity> OppList = new Map<ID, Opportunity>([SELECT Id, Name,Category__c,Account.Name FROM Opportunity where ID in :oppids]);
            
            for (Internship_Work_Site__c i : iwss) {
                String category = OppList.get(i.Opportunity__c).Category__c;
                if(category == 'New Partner'){
                    i.Category__c = 'New Seats';
                } else if(category == 'Existing Partner'){
                    i.Category__c = 'Growth Seats';
                }else if(category == 'Reacquire Partner'){
                    i.Category__c = 'Reacquire Seats';
                }
                
            }
        }      
    }//end of method
    
    /**
* @author       Ajay Kumar
* @date         11/15/2017
* @description  When IWS gets created, populate Price Per Seat based on IWS Site.
*/
    private void pricePerSeatOnIWSInsert(list<Internship_Work_Site__c> iwss) {       
        Set<Id> siteIds = new Set<Id>();        
        for (Internship_Work_Site__c i : iwss) {
            if(String.isNotBlank(i.Site_Located__c)) siteIds.add(i.Site_Located__c);            
        }        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = InternshipWorkSiteGateway.getSitesMap(siteIds);      
            for ( Internship_Work_Site__c i : iwss ) {
                if ( i.Site_Located__c != null ) {
                    i.Price_Per_Seat__c = siteMap.get(i.Site_Located__c).Price_Per_Seat__c;
                }
            }        
        }
        
    }//end of method
    
    /**
* @author       Ajay Kumar
* @date         11/15/2017
* @description  When IWS gets created, populate Account based on IWS's Opportunity.
*/
    private void populateAccountOnIWSInsert(list<Internship_Work_Site__c> iwss) {       
        Set<Id> oppIds = new Set<Id>();        
        for (Internship_Work_Site__c i : iwss) {
            if(String.isNotBlank(i.Opportunity__c)) oppIds.add(i.Opportunity__c);            
        }        
        if(oppIds.size()>0){
            Map<Id,Opportunity> oppMap = InternshipWorkSiteGateway.getOppMap(oppIds);      
            for ( Internship_Work_Site__c i : iwss ) {
                if ( i.Opportunity__c != null ) {
                    i.Account__c = oppMap.get(i.Opportunity__c).Accountid;
                }
            }        
        }
    }//end of method
    
    /**
* @author       Ajay Kumar
* @date         11/15/2017
* @description  When IWS gets updated, populate Account based on IWS's Opportunity..
*/
    private void populateAccountOnIWSUpdate(list<Internship_Work_Site__c> iwss, Map<Id,Internship_Work_Site__c> iwsOldMap) {
        Set<Id> oppIds = new Set<Id>();        
        for (Internship_Work_Site__c i : iwss) {
            if(String.isNotBlank(i.Opportunity__c)) oppIds.add(i.Opportunity__c);            
        }       
        if(oppIds.size()>0){
            Map<Id,Opportunity> oppMap = InternshipWorkSiteGateway.getOppMap(oppIds);      
            for (Internship_Work_Site__c i : iwss) {
                Internship_Work_Site__c iwsOld = iwsOldMap.get(i.id);  
                if (i.Opportunity__c != null && i.Opportunity__c != iwsOld.Opportunity__c) {
                    i.Account__c = oppMap.get(i.Opportunity__c).Accountid;
                }
            }        
        }
    }//end of method
    
    /**
* @author       Ajay Kumar
* @date         11/15/2017
* @description  When IWS gets updated, populate Price Per Seat based on IWS Site..
*/
    private void pricePerSeatOnIWSSUpdate(list<Internship_Work_Site__c> iwss, Map<Id,Internship_Work_Site__c> iwsOldMap) {
        Set<Id> siteIds = new Set<Id>();        
        for (Internship_Work_Site__c i : iwss) {
            if(String.isNotBlank(i.Site_Located__c)) siteIds.add(i.Site_Located__c);            
        }        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = InternshipWorkSiteGateway.getSitesMap(siteIds);      
            for (Internship_Work_Site__c i : iwss) {
                Internship_Work_Site__c iwsOld = iwsOldMap.get(i.id);  
                if (i.Site_Located__c != null && i.Site_Located__c != iwsOld.Site_Located__c) {
                    i.Price_Per_Seat__c = siteMap.get(i.Site_Located__c).Price_Per_Seat__c;
                }
            }        
        }
    }//end of method
    
    /**
* @author       Ajay Kumar
* @date         03/14/2017
* @description  When IWS gets created, populate Probability based on IWS Satge.
*/
    private void StageAndCloseDateOnIWSInsert(list<Internship_Work_Site__c> iwss) {
        Set<id> oppids = new Set<id>();
        
        for (Internship_Work_Site__c i : iwss) {  
            if (i.Probability__c == 100 ) {
                i.closeDate__c = System.today();               
                i.Stage__c = 'Seats Confirmed';
            }  
            if (i.Stage__c == 'Seats Confirmed') {                
                i.Probability__c = 100;
                i.closeDate__c = System.today();
            }else if(i.Stage__c == 'IWSUnserviceable' || i.Stage__c == 'Pushed to Future' || i.Stage__c == 'Seats Lost'){                
                i.Probability__c = 0;
                i.closeDate__c = System.today();
            }
        }
    }//end of method
    
    
    /**
* @author       Ajay Kumar
* @date         03/14/2017
* @description  When IWS gets updated, populate Probability based on IWS Satge.
*/
    private void StageAndCloseDateOnIWSUpdate(list<Internship_Work_Site__c> iwss, Map<Id,Internship_Work_Site__c> iwsOldMap) {
        Set<id> oppids = new Set<id>();
        
        for (Internship_Work_Site__c i : iwss) {
            Internship_Work_Site__c iwsOld = iwsOldMap.get(i.id);  
            if (i.Stage__c == 'Seats Confirmed') {
                if(iwsOld.Stage__c!=i.Stage__c){
                    i.closeDate__c = System.today();               
                    i.Probability__c = 100;
                }
            }else if(i.Stage__c == 'IWSUnserviceable' || i.Stage__c == 'Pushed to Future' || i.Stage__c == 'Seats Lost' ){                
                if(iwsOld.Stage__c!=i.Stage__c){
                    i.Probability__c = 0;
                    i.closeDate__c = System.today();
                }
            }
            if (i.Probability__c == 100 && (i.Stage__c != 'IWSUnserviceable' || i.Stage__c != 'Pushed to Future' || i.Stage__c != 'Seats Lost') ) {
                if(iwsOld.Probability__c!=i.Probability__c){
                    i.closeDate__c = System.today(); 
                    i.Stage__c = 'Seats Confirmed';
                }
            }
            
        }
    }//end of method
    
    
    /**
* @author       Ajay Kumar
* @date         03/14/2017
* @description  When IWS gets updated, update the Opportunity stage based on IWS Satge.
*/
    public void UpdateOpportunityStage(List<Internship_Work_Site__c> newList) {
        List<Opportunity> updateList = new List<Opportunity>();
        Map<id,List<Internship_Work_Site__c>> mapParentIDAndChild = new Map<id,List<Internship_Work_Site__c>>();        
        set<Id> OppIds = new set<Id>();
        for(Internship_Work_Site__c objChild : newList) {
            OppIds.add(objChild.Opportunity__c);
        }
        for(Internship_Work_Site__c objChild : [select id , Reason__c, Stage__c , Opportunity__c from Internship_Work_Site__c where Opportunity__c IN: OppIds ] ){
            if(mapParentIDAndChild.containsKey(objChild.Opportunity__c)) {
                mapParentIDAndChild.get(objChild.Opportunity__c).add(objChild);
            } else {
                mapParentIDAndChild.put(objChild.Opportunity__c,new List<Internship_Work_Site__c>{objChild});
            }
        }
        for(Id objId : mapParentIDAndChild.keySet()) {            
            integer OpenCount = 0;
            integer IWSLostClount = 0;
            integer SeatsConfirmedCount = 0;
            integer PushedtoFutureCount = 0;
            integer UnserviceableSeatCount = 0;
            integer UnserviceableSiteCount = 0;            
            
            for(Internship_Work_Site__c objChild : mapParentIDAndChild.get(objId)) {               
                if(objChild.Stage__c == 'Seats Lost'){                   
                    IWSLostClount++;                   
                }else if(objChild.Stage__c == 'Seats Confirmed'){                   
                    SeatsConfirmedCount++;                   
                }
                else if(objChild.Stage__c == 'Pushed to Future'){                   
                    PushedtoFutureCount++;                    
                }
                else if(objChild.Stage__c == 'IWSUnserviceable' && objChild.Reason__c == 'Could not fill the seat' ){                   
                    UnserviceableSeatCount++;                  
                }
                else if(objChild.Stage__c == 'IWSUnserviceable' && (objChild.Reason__c == 'Site Unserviceable' || objChild.Reason__c == 'Specialty Unserviceable') ){                 
                    UnserviceableSiteCount++;    
                }
                else if(objChild.Stage__c == 'Qualified Prospect' || objChild.Stage__c == 'Proposal Under Review' || objChild.Stage__c == 'In Conversation' ){   
                    OpenCount++;
                }
                
            }
            String OppStage = OpportunityStage(OpenCount,IWSLostClount,SeatsConfirmedCount,PushedtoFutureCount,UnserviceableSiteCount,UnserviceableSeatCount);
            
            if(mapParentIDAndChild.get(objId).size()>0){
                Opportunity opp = new Opportunity();
                opp.id = objId;                             
                opp.StageName = OppStage;  
                updateList.add(opp); 
            }
        }
        
        
        try{
            if(!updateList.isEmpty())            
                update updateList;         
        }catch (DMLException e){
            for(Internship_Work_Site__c iws : newList){
                iws.addError(e.getDMLMessage(0)); 
            }               
        }  
        
    }// end of UpdateFields   
    
    public String OpportunityStage(Integer open, Integer lost,Integer confirm, Integer future, Integer unserviceSite,Integer unserviceSeats){
        String stage = '';
        
        if ( open>0 && ((confirm + lost + future + unserviceSite + unserviceSeats ) ==0)){
            stage ='Open';
            return stage;
        }else if(open==0 && (confirm + future + unserviceSeats ) ==0 && (lost + unserviceSite )>0){
            stage ='Closed Lost';
            return stage;
        }else if((confirm + unserviceSeats ) >0 && (lost + unserviceSite + future + open)==0){
            stage ='Closed Won';
            return stage;
        }
        else if(open==0 && (confirm + unserviceSeats ) >0 && (lost + unserviceSite + future )>0){
            stage ='Closed';
            return stage;
        }else if(open==0 && (confirm + unserviceSeats ) ==0 && (lost + unserviceSite + future )>0){
            stage ='Closed';
            return stage;
        }
        else if(open>0 && ((confirm + lost + future + unserviceSite + unserviceSeats ) >0)){
            stage ='Partial Closed';
            return stage;
        }else if((open + unserviceSite)>0 && (confirm + lost + future + unserviceSeats ) ==0){
            stage ='Partial Closed';
            return stage;
        }
        return null;
    }   
    
    
    /**
    * @author       Ajay Kumar
    * @date         07/28/2017
    * @description  When IWS Stage is changed to "Seats Confirmed", this method will create a Internship Records based on seats entered.
    */
    public void createInternship(List<Internship_Work_Site__c> newList, Map<Id,Internship_Work_Site__c> iwsOldMap){
        
        //List of Internships to insert.
        List<Apprenticeship__c> internshipList = new List<Apprenticeship__c> (); 
        for(Internship_Work_Site__c iws: [SELECT Id,Seat_Survey_Result__c,InternshipStartDate__c,Opportunity__c,SeatsConfirmed__c,Stage__c,Opportunity__r.Cohort_Sem__c,Site_Located__c,Account__c,TrackFamily__c,Specialty__c FROM Internship_Work_Site__c WHERE ID IN:newList]){    		
            
            //Check if the IWS stage is changed and Stage is "Seats Confirmed"
            if((iwsOldMap != null && 'Seats Confirmed' != iwsOldMap.get(iws.Id).stage__c) && iws.stage__c == 'Seats Confirmed'){
                
                //Create Internship records 
                for(integer i=0; i<iws.SeatsConfirmed__c; i++){                   
                    internshipList.add
                        (   new Apprenticeship__c
                         (
                             InternshipWorkSite__c   =   iws.id,
                             Opportunity__c          =   iws.Opportunity__c,
                             Cohort_Sem__c           =   iws.Opportunity__r.Cohort_Sem__c,
                             Site_Location__c        =   iws.Site_Located__c,
                             Employer__c             =   iws.Account__c,
                             Track__c                =   iws.TrackFamily__c,
                             Job_Category__c         =   iws.Specialty__c,                            
                             Start_Date__c           =   iws.InternshipStartDate__c,
                             Seat_Survey_Result__c	 =	 iws.Seat_Survey_Result__c
                         )
                        ); 
                }			
            }
        }
        
        //Check the list is not empty and insert Internship records.
        if(internshipList.size() >0) insert internshipList;
    }
    
    
    /**
    * @author       Ajay Kumar
    * @date         12/07/2017
    * @description  When IWS Stage is inserted with stage "Seats Confirmed", this method will create a Internship Records based on seats entered.
    */
    public void createInternshipInsert(List<Internship_Work_Site__c> newList){
       
        //List of Internships to insert.
        List<Apprenticeship__c> internshipList = new List<Apprenticeship__c> ();  
        for(Internship_Work_Site__c iws: [SELECT 
                                              Id,
                                              Seat_Survey_Result__c,
                                              InternshipStartDate__c,
                                              Opportunity__c,SeatsConfirmed__c,
                                              Stage__c,Opportunity__r.Cohort_Sem__c,
                                              Site_Located__c,Account__c,
                                              TrackFamily__c,Specialty__c 
                                          FROM Internship_Work_Site__c 
                                          WHERE ID IN:newList]){            
            
            //Check if the IWS stage is is "Seats Confirmed"
            if(iws.stage__c == 'Seats Confirmed'){
                
                //Create Internship records 
                for(integer i=0; i<iws.SeatsConfirmed__c; i++){   
                    internshipList.add
                        (   new Apprenticeship__c
                         (
                             InternshipWorkSite__c   =   iws.id,
                             Opportunity__c          =   iws.Opportunity__c,
                             Cohort_Sem__c           =   iws.Opportunity__r.Cohort_Sem__c,
                             Site_Location__c        =   iws.Site_Located__c,
                             Employer__c             =   iws.Account__c,
                             Track__c                =   iws.TrackFamily__c,
                             Job_Category__c         =   iws.Specialty__c,                            
                             Start_Date__c           =   iws.InternshipStartDate__c,
                             Seat_Survey_Result__c	 =	 iws.Seat_Survey_Result__c
                         )
                        ); 
                }           
            }
        }
        
        //Check the list is not empty and insert Internship records.
        if(internshipList.size() >0) insert internshipList;
    }
    
    /**
    * @author       Ajay Kumar
    * @date         03/01/2018
    * @description  When IWS Price per seat is changed, this method will update Internship Records Credit calculation.
    */
    public void updateInternships(List<Internship_Work_Site__c> newList, Map<Id,Internship_Work_Site__c> iwsOldMap){
        
        // List of Internships to Update.
        List<Apprenticeship__c> internshipList = new List<Apprenticeship__c> ();  
        
        // Map of Internhsip Work Sites
        Map<Id,Internship_Work_Site__c> iwsMap = new Map<Id,Internship_Work_Site__c>();
        
        for(Internship_Work_Site__c iws: newList){
            // Check if the IWS Price Per Seats is changed and it is not NULL or 0"
            if(iwsOldMap != null && iwsOldMap.get(iws.Id).Price_Per_Seat__c != iws.Price_Per_Seat__c && iws.Price_Per_Seat__c != null && iws.Price_Per_Seat__c != 0){       
                iwsMap.put(iws.id,iws);                     
            }
        }
        
        // Loop through the Internships
        for(Apprenticeship__c intern: [SELECT Id,Billing_Preference__c, Actual_End_date__c, Free_Seat__c,Credit_Weeks__c,Credit_Weekly_Rate__c FROM Apprenticeship__c WHERE InternshipWorkSite__c IN: iwsMap.keySet()]){
            
            Apprenticeship__c internship = new Apprenticeship__c(Id=intern.id);
            
            // If Actual End Date Date is NULL then set Credit to NULL
            if(intern.Actual_End_date__c==null){
                internship.Credit__c = NULL;
            }
            // If Actual End Date Date is NOT NULL and Free Seat checked OR Billing Frequency is "Cash Sale", then set Credit to 0
            else if(intern.Actual_End_date__c!=null && (intern.Free_Seat__c == TRUE || intern.Billing_Preference__c == 'Cash Sale' )){
                internship.Credit__c = 0;
            }
            
            // If Actual End Date Date is NOT NULL and Free Seat Not checked OR Billing Frequency is Not "Cash Sale", then calculate Credit
            else if(intern.Actual_End_date__c!=null && intern.Free_Seat__c == FALSE && intern.Billing_Preference__c != 'Cash Sale' ){
                internship.Credit__c = intern.Credit_Weekly_Rate__c * intern.Credit_Weeks__c;
            }
            internshipList.add(internship);
        }
        
        // Check the list is not empty and update Internship records.
        if(internshipList.size() >0) update internshipList;
    }
    
  
    
}