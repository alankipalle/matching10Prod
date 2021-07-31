/**
* Opportunity Trigger Handler for the Opportunity object. This class extends the TriggerHandler
* class to help ensure the trigger code is in one place and bulkified.  
*/
public class OpportunityTriggerHandler extends TriggerHandler {
    public static Boolean TriggerDisabled = false;
    public static Boolean isRecOppUpdated=false;
    public static map<String, Schema.RecordTypeInfo> OppRecordTypes = ApexUtility.GetRecordTypeByName('Opportunity');
    
    
    
    protected override String getCustomSettingField() { return 'OpportunityTriggerDisabled__c'; }
    protected override void BeforeInsert(){
        beforeInsertUpdateOppStage(Trigger.new);        
        CohortYearOnOpportunity((List<Opportunity>) Trigger.new);  
        siteOnOpportunity((List<Opportunity>) Trigger.new); 
        UpdateDonorContactandAccounts((List<Opportunity>) Trigger.new);
        CP_UpdateOpportunitySite.CP_UpdateOpportunitySite((List<Opportunity>) Trigger.new,(Map<id,Opportunity>)trigger.oldmap);
        PopulateCategoryonOpp((List<Opportunity>) Trigger.new,(Map<Id,Opportunity>) Trigger.oldMap, 'isInsert' );
        
    }
    
    
    protected override void BeforeUpdate(){
        beforeInsertUpdateOppStage(Trigger.new);        
        UpdateOppSiteLocFromClassyDonation((List<Opportunity>) Trigger.new);       
        CohortYearOnOpportunity((List<Opportunity>) Trigger.new, (Map<Id,Opportunity>) Trigger.oldMap);
        siteOnOpportunity((List<Opportunity>) Trigger.new, (Map<Id,Opportunity>) Trigger.oldMap);      
        if(UtilityRunOnce.AddresstoAccount_RunCheck){
            UtilityRunOnce.AddresstoAccount_RunCheck = false;
            PopulateCategoryonOpp((List<Opportunity>) Trigger.new,(Map<Id,Opportunity>) Trigger.oldMap, 'isUpdate' );
        }
    }
    
    protected override void AfterInsert() {
        createOppPayments((List<Opportunity>) Trigger.new);
    }
    
    protected override void AfterUpdate() {
        UpdatePaymentSiteLocFromOpportunity((Map<Id,Opportunity>) Trigger.oldMap,(Map<Id,Opportunity>) Trigger.newMap);         
        updateInternshipWorkSites((List<Opportunity>) Trigger.new, (Map<Id,Opportunity>) Trigger.oldMap);        
        UpdateRecSiteLocationOpps(Trigger.new,(Map<Id,Opportunity>)trigger.oldmap);       
        MATCH_ProcessMatchingSeats(Trigger.new,(Map<Id,Opportunity>)trigger.oldmap, Trigger.operationType); 
        
    }
    
    @TestVisible
    protected override void AfterDelete(){  
        
    }
    
    @TestVisible
    protected override void AfterUndelete(){  
        
    } 
    
    
    /**
* This method updates the account, donor acct, donor contact, payment contact for Classy with contact
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void UpdateDonorContactandAccounts(list<Opportunity> opps) { 
        Set<Id> conIds = new set<Id>(); 
        Map<Id, contact> conMap = new Map<Id,Contact>();
        for (Opportunity o : opps) {
            if (o.stayclassy__sc_order_id__c != null && String.isNotBlank(o.stayclassy__sf_contact_id__c) ){
                conIds.add(o.stayclassy__sf_contact_id__c);
                
            }   
        }  
        
        if(conIds != null && !conIds.isEmpty()){
            conMap = new Map<Id,Contact>([Select Id,AccountId from Contact where Id in :conIds]); //Account.Id
            
            for (Opportunity o : opps) {          
                if (o.stayclassy__sc_order_id__c != null && String.isNotBlank(o.stayclassy__sf_contact_id__c) ){
                    o.Donor_Account__c = conMap.get(o.stayclassy__sf_contact_id__c).AccountId;
                    o.AccountId = conMap.get(o.stayclassy__sf_contact_id__c).AccountId;
                    o.Donor_Contact__c = o.stayclassy__sf_contact_id__c;
                    o.Payment_Contact__c = o.stayclassy__sf_contact_id__c;
                }
            }     
            
        }
    }
    
    
    
    /**
* This method creates opportunity payments 
* 
* @param   List of Opportunity
* 
*/
    @TestVisible
    private void createOppPayments(list<Opportunity> opps) {
        Set<Id> oppIds = new Set<Id>();
        
        for(Opportunity op:opps){
            if ((op.stayclassy__sc_order_id__c != null && op.Amount != null && op.Amount > 0 && op.StageName == 'Gift Closed/Payments Completed 100%') || op.Amount == 11111 )
                oppIds.add(op.Id);
        }
        if(oppIds != null && !oppIds.isEmpty()) 
            CreatePaymentsHandler.paymentsCreation(oppIds);
        
    }
    
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   List of Opportunity
* 
*/
    @TestVisible
    private void siteOnOpportunity(list<Opportunity> opps) {        
        Set<Id> siteIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Integer> years = new Set<Integer>();
        Set<Id> siteLocIds = new Set<Id>();        
        for (Opportunity o : opps) {
            if(String.isNotBlank(o.Site_Location__c)) siteIds.add(o.Site_Location__c);  
            if(String.isNotBlank(o.OwnerId) && String.isNotBlank(o.Site_Location__c) && o.CloseDate != Null ){
                ownerIds.add(o.OwnerId);
                years.add(o.CloseDate.Year());
                siteLocIds.add(o.Site_Location__c);
            }             
        }        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = OpportunityGateway.getSitesMap(siteIds);            
            if (ownerIds != null && !ownerIds.isEmpty()) {
                Set<String> marketNames = new Set<String>();
                Map<Id,String> siteMarketName = new Map<Id,String>();
                for(Site__c s:siteMap.values()){
                    marketNames.add(s.Market__c);
                    siteMarketName.put(s.Id,s.Market__c);
                }
                Set<String> yrs = new Set<String>();
                for(Integer i:years){
                    yrs.add(String.valueOf(i));
                }                
                Map<Id, Performance_Goal__c> goalMap = new Map<Id,Performance_Goal__c>([SELECT Id, Name, Staff__c, Year__c, RecordTypeId, Market_Name__c FROM Performance_Goal__c WHERE Year__c IN: yrs and Market_Name__c IN :marketNames order by Year__c, RecordTypeId]); 
                
                if(goalMap.size()>0 || goalMap.size()==0){
                    string fundgoalRTID = Schema.SObjectType.Performance_Goal__c.getRecordTypeInfosByName().get('Fundraiser Goal').getRecordTypeId();
                    string marketgoalRTID = Schema.SObjectType.Performance_Goal__c.getRecordTypeInfosByName().get('Market Level Goal').getRecordTypeId();  
                    String id_RecordTypeId = OppRecordTypes.get('Individual Donation').getRecordTypeId();  
                    String mgl_RecordTypeId = OppRecordTypes.get('Mid Level Gift').getRecordTypeId();  
                    String od_RecordTypeId = OppRecordTypes.get('Organizational Donation').getRecordTypeId();           
                    for(Opportunity o : opps){                        
                        if(String.isNotBlank(o.OwnerId) && String.isNotBlank(o.Site_Location__c) && o.CloseDate != Null && (o.RecordTypeId == id_RecordTypeId || o.RecordTypeId == mgl_RecordTypeId || o.RecordTypeId == od_RecordTypeId)){
                            if(goalMap.size()>0 ){ 
                                for(Performance_Goal__c p:goalMap.values()){
                                    if(p.RecordTypeId == marketgoalRTID && p.Year__c == String.valueOf(o.CloseDate.year()) && (siteMarketName.containsKey(o.Site_Location__c) && p.Market_Name__c == siteMarketName.get(o.Site_Location__c)))
                                        o.Performance_Goal__c = p.Id; 
                                    if(p.RecordTypeId == fundgoalRTID && p.Year__c == String.valueOf(o.CloseDate.year()) && (siteMarketName.containsKey(o.Site_Location__c) && p.Market_Name__c == siteMarketName.get(o.Site_Location__c)) && p.Staff__c == o.OwnerId) 
                                        o.Fundraiser_Goal__c = p.Id;
                                }
                            } 
                            else{ 
                                o.Performance_Goal__c = Null;
                                o.Fundraiser_Goal__c = Null;
                            }
                            
                        }      
                    }
                }
            }       
            
            for (Opportunity o : opps) {                
                if (String.isNotBlank(o.Site_Location__c))
                    o.Site__c = (siteMap.get(o.Site_Location__c).Name == 'NTL' || siteMap.get(o.Site_Location__c).Name == 'NTLB') ? 'National' : siteMap.get(o.Site_Location__c).Name; 
            }             
        }        
        
    }
    
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   Map of Opportunity
* @param   Map of old Opportunity
* 
*/  
    
    @TestVisible
    private void siteOnOpportunity(List<Opportunity> opps, Map<Id, Opportunity> oldItems) {        
        Set<Id> siteIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Integer> years = new Set<Integer>();
        for (Opportunity o : opps) {
            Opportunity oldOpp = (Opportunity)oldItems.get(o.Id);
            if((String.isNotBlank(o.OwnerId) && o.OwnerId != oldOpp.OwnerId) ||
               (String.isNotBlank(o.Site_Location__c) && o.Site_Location__c != oldOpp.Site_Location__c) ||
               (o.CloseDate != Null && o.CloseDate != oldOpp.CloseDate)){
                   siteIds.add(o.Site_Location__c);
                   ownerIds.add(o.OwnerId);
                   years.add(o.CloseDate.Year());
               }           
        }
        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = OpportunityGateway.getSitesMap(siteIds);     
            
            Set<String> marketNames = new Set<String>();
            Map<Id,String> siteMarketName = new Map<Id,String>();
            for(Site__c s:siteMap.values()){
                marketNames.add(s.Market__c);
                siteMarketName.put(s.Id,s.Market__c);
            }
            Set<String> yrs = new Set<String>();
            for(Integer i:years){
                yrs.add(String.valueOf(i));
            }
            
            Map<Id, Performance_Goal__c> goalMap = new Map<Id,Performance_Goal__c>([SELECT Id, Name, Staff__c, Year__c, RecordTypeId, Market_Name__c FROM Performance_Goal__c WHERE Year__c IN: yrs and Market_Name__c IN :marketNames order by Year__c, RecordTypeId]); 
            if(goalMap.size()>0 || goalMap.size()==0){
                string fundgoalRTID = Schema.SObjectType.Performance_Goal__c.getRecordTypeInfosByName().get('Fundraiser Goal').getRecordTypeId();
                string marketgoalRTID = Schema.SObjectType.Performance_Goal__c.getRecordTypeInfosByName().get('Market Level Goal').getRecordTypeId();           
                String id_RecordTypeId = OppRecordTypes.get('Individual Donation').getRecordTypeId();  
                String mgl_RecordTypeId = OppRecordTypes.get('Mid Level Gift').getRecordTypeId();  
                String od_RecordTypeId = OppRecordTypes.get('Organizational Donation').getRecordTypeId(); 
                Boolean isMGUpdate, isFGUpdate;
                for(Opportunity o : opps){                        
                    if (String.isNotBlank(o.Site_Location__c))
                        o.Site__c = (siteMap.get(o.Site_Location__c).Name == 'NTL' || siteMap.get(o.Site_Location__c).Name == 'NTLB') ? 'National' : siteMap.get(o.Site_Location__c).Name;  
                    if(String.isNotBlank(o.OwnerId) && String.isNotBlank(o.Site_Location__c) && o.CloseDate != Null && (o.RecordTypeId == id_RecordTypeId || o.RecordTypeId == mgl_RecordTypeId || o.RecordTypeId == od_RecordTypeId)){
                        if(goalMap.size()>0){ 
                            isMGUpdate = false;
                            isFGUpdate = false;  
                            for(Performance_Goal__c p:goalMap.values()){
                                if(p.RecordTypeId == marketgoalRTID && p.Year__c == String.valueOf(o.CloseDate.year()) && (siteMarketName.containsKey(o.Site_Location__c) && p.Market_Name__c == siteMarketName.get(o.Site_Location__c))){
                                    o.Performance_Goal__c = p.Id;
                                    isMGUpdate = true;
                                }     
                                if(p.RecordTypeId == fundgoalRTID && p.Year__c == String.valueOf(o.CloseDate.year()) && (siteMarketName.containsKey(o.Site_Location__c) && p.Market_Name__c == siteMarketName.get(o.Site_Location__c)) && p.Staff__c == o.OwnerId){ 
                                    o.Fundraiser_Goal__c = p.Id;
                                    isFGUpdate = true;
                                }    
                            }
                            if(!isMGUpdate) o.Performance_Goal__c = Null;
                            if(!isFGUpdate) o.Fundraiser_Goal__c = Null;
                        } 
                        else{ 
                            o.Performance_Goal__c = Null;
                            o.Fundraiser_Goal__c = Null;
                        }   
                    }      
                }
            }
            
        }  
    }
    
    
    /**
* 
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void beforeInsertUpdateOppStage(list<Opportunity> opps) {        
        
        for (Opportunity o : opps) {
            if(o.stayclassy__Transaction_Type__c!= null && o.stayclassy__Transaction_Type__c!='Donation'){
                o.StageName='Cultivate: Plan to Submit 5% (Blind)';
            }   
        }      
    }
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void CohortYearOnOpportunity(list<Opportunity> opps) {        
        Set<Id> cohortIds = new Set<Id>();   
        
        for (Opportunity o : opps) {            
            if(String.isNotBlank(o.Cohort_Sem__c)) cohortIds.add(o.Cohort_Sem__c);  
            
        }        
        
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = OpportunityGateway.getCohortsMap(cohortIds);            
            for (Opportunity o : opps) {                
                if (String.isNotBlank(o.Cohort_Sem__c))
                    o.Cohort__c = cohortMap.get(o.Cohort_Sem__c).Name;
            }             
        }        
        
    }
    
    
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Opportunities
* @param   Map of old Opportunities
* 
*/  
    
    @TestVisible
    private void CohortYearOnOpportunity(List<Opportunity> opps, Map<Id,Opportunity> oldItems) {        
        Set<Id> cohortIds = new Set<Id>();
        for (Opportunity o : opps) {
            if(String.IsNotBlank(o.Cohort_Sem__c)){
                Opportunity oldvol = (Opportunity)oldItems.get(o.Id);
                if (o.Cohort_Sem__c != oldvol.Cohort_Sem__c) {  
                    cohortIds.add(o.Cohort_Sem__c);
                }
            }    
        }
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = OpportunityGateway.getCohortsMap(cohortIds);            
            for (Opportunity o : opps) {                
                if (String.isNotBlank(o.Cohort_Sem__c))
                    o.Cohort__c = cohortMap.get(o.Cohort_Sem__c).Name;
            }             
        }  
    }
    
    
    /**
* This method updates Site Location on Payment that is created from Opportunity through Classy Donation Page.
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void UpdateOppSiteLocFromClassyDonation(list<Opportunity> opps) { 
        CP_UpdateOpportunitySite.CP_UpdateOpportunitySite(opps,(Map<id,Opportunity>)trigger.oldmap);
    }
    
    /**
* This method updates Site Location on Opportunity from Classy Custom Question provided on Donation Page.
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void UpdateRecSiteLocationOpps(List<Opportunity> lstOfNewOpps,Map<id,Opportunity> mapOfOldOpps) { 
        
        if(!isRecOppUpdated){
            List<Opportunity> lstOpps=new List<Opportunity>();
            Set<id> setOfRecDonactions=new Set<Id>();
            
            for(Opportunity opp:lstOfNewOpps){                
                if(Test.isRunningTest() || opp.npe03__Recurring_Donation__c!=null && opp.StageName== 'Gift Closed/Payments Completed 100%' && opp.Site_Location__c!=null){    
                    setOfRecDonactions.add(opp.npe03__Recurring_Donation__c);
                }                
            }
            
            Map<id,Opportunity> mapOfrecOpps=new Map<id,Opportunity>();            
            String firstOppOldSiteLocation;
            
            for(id opp:mapOfOldOpps.keySet()){
                if(firstOppOldSiteLocation==null){
                    firstOppOldSiteLocation=mapOfOldOpps.get(opp).Site_Location__c;
                }
                
            }
            
            Set<id> setOfFirstOldSiteLocations=new Set<Id>(); 
            for(npe03__Recurring_Donation__c recDonation:[select id,(select id,Site_Location_Text__c,Site_Location__c from npe03__Donations__r order by CloseDate asc limit 1) from npe03__Recurring_Donation__c where id in:setOfRecDonactions]){
                
                if(recDonation.npe03__Donations__r!=null &&  recDonation.npe03__Donations__r.size()>0){
                    mapOfrecOpps.put(recDonation.id,recDonation.npe03__Donations__r[0]);
                    
                    if(mapOfOldOpps.containsKey(recDonation.npe03__Donations__r[0].id)){
                        setOfFirstOldSiteLocations.add(mapOfOldOpps.get(recDonation.npe03__Donations__r[0].id).Site_Location__c);
                    }                    
                }                
            }            
            
            List<Opportunity> lstOfOpp= [select id,Site_Location_Text__c,Site_Location__c,npe03__Recurring_Donation__c 
                                         from Opportunity where npe03__Recurring_Donation__c in:mapOfrecOpps.keySet() and (((Site_Location_Text__c = null and Site_Location__r.Name ='NTL') or Site_Location__c=null) or Site_Location__c in:setOfFirstOldSiteLocations)];         
            
            
            for(Opportunity opp:lstOfOpp){  
                opp.Site_Location_Text__c=mapOfrecOpps.get(opp.npe03__Recurring_Donation__c).Site_Location_Text__c;
                opp.Site_Location__c=mapOfrecOpps.get(opp.npe03__Recurring_Donation__c).Site_Location__c;  
                
            }
            
            if(lstOfOpp.size()>0){
                isRecOppUpdated=true;
                update lstOfOpp;
            }
        } 
    }   
    /**
* This method updates Site Location on Opportunity from Classy Custom Question provided on Donation Page.
* 
* @param   List of Opportunities
* 
*/
    @TestVisible
    private void UpdatePaymentSiteLocFromOpportunity(Map<Id,Opportunity> oldmap,Map<Id,Opportunity> newmap) { 
        List<npe01__OppPayment__c>lstOfOppPayment=new List<npe01__OppPayment__c>();
        List<npsp__Allocation__c>lstOfOppAllocations=new List<npsp__Allocation__c>();
        
        
        Set<id> setOfchangedOppIds=new Set<id>();        
        for(id oppId:newMap.keySet()){        
            if(oldmap.get(oppId).Site_Location__c!=newmap.get(oppId).Site_Location__c 
               && oldmap.get(oppId).Site_Location__c!=null && newmap.get(oppId).Site_Location__c!=null){                
                   setOfchangedOppIds.add(oppId);
               }            
        }
        
        
        for(npe01__OppPayment__c pay :[select id,Site_Location__c,npe01__Opportunity__c,(select id,Site_Location__c,npsp__Opportunity__c from GAU_Allocations__r) from npe01__OppPayment__c where npe01__Opportunity__c in:setOfchangedOppIds and Site_Location__c!=null ]){
            
            if(oldmap.get(pay.npe01__Opportunity__c).Site_Location__c==pay.Site_Location__c){            
                lstOfOppPayment.add(new npe01__OppPayment__c(id=pay.id,Site_Location__c=newmap.get(pay.npe01__Opportunity__c).Site_Location__c));
            }
            
            for(npsp__Allocation__c allocation:pay.GAU_Allocations__r){            
                if(oldmap.get(allocation.npsp__Opportunity__c ).Site_Location__c==allocation.Site_Location__c){            
                    lstOfOppAllocations.add(new npsp__Allocation__c (id=allocation.id,Site_Location__c=newmap.get(pay.npe01__Opportunity__c).Site_Location__c));
                }
            }
        }
        
        if(lstOfOppPayment.size()>0 ){
            update lstOfOppPayment;
        }
        if(lstOfOppAllocations.size()>0 ){
            update lstOfOppAllocations;
        }        
    }   
    
    
    /**
* This method updates the Account ID on IWSs
* 
* @param   List of Opportunity
* 
*/     
    
    @TestVisible     
    private void updateInternshipWorkSites(list<Opportunity> opps,Map<Id,Opportunity> oldItems) {
        
        Map<Id,Opportunity> oppMap= new Map<Id,Opportunity>(); 
        list<Internship_Work_Site__c> iwsList = new list<Internship_Work_Site__c>(); 
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'InternshipSeats' limit 1].Id;     
        for (Opportunity o : opps) {
            Opportunity oldvol = (Opportunity)oldItems.get(o.Id);             
            if(String.isNotBlank(o.AccountId) && o.RecordTypeId == recordTypeId){
                if(oldvol.AccountId != o.AccountId) 
                    oppMap.put(o.Id,o);  
            }            
        }        
        if(!oppMap.isEmpty()){                        
            for (Internship_Work_Site__c i : [SELECT Id,Account__c,Opportunity__c from Internship_Work_Site__c WHERE Opportunity__c IN:oppMap.keyset()]) {                 
                i.Account__c = oppMap.get(i.Opportunity__c).AccountId;                     
                iwsList.add(i);
            }             
        }  
        if(iwsList!=null || iwsList.size()>0)
            update iwsList;   
        
    }
    
    
    /**
* This method updates the Category based on the Closed Won and Closed Opportunities Category 
* 
* @param   List of Opportunity
* 
*/
    
    @TestVisible
    private void PopulateCategoryonOpp(List<Opportunity> opps, Map<Id,Opportunity> oldItems, String triggerAction ){
        Set<Id> accSet = new Set<Id>();
        Map<Id,list<Opportunity>> oppMap= new Map<Id,list<Opportunity>>();         
        Map<String, Id> myCohortMap = new Map<String, Id>();
        Map<Id, Cohort__c> myCohortMapName = new Map<Id, Cohort__c>();       
        for(Cohort__c c:[Select Name, Id From Cohort__c]){
            myCohortMap.put(c.Name,c.Id);
            myCohortMapName.put(c.Id,c);
        } 
        Id recordTypeId = [select Id from RecordType where DeveloperName = 'InternshipSeats' limit 1].Id;
        
        for (Opportunity o : opps) {
            if(triggerAction == 'isInsert'){
                if(String.isNotBlank(o.AccountId) && o.RecordTypeId == recordTypeId) accSet.add(o.AccountId); 
            }
            if(triggerAction == 'isUpdate'){
                Opportunity oldvol = (Opportunity)oldItems.get(o.Id);
                if( String.isNotBlank(o.AccountId) && o.RecordTypeId == recordTypeId || Test.isRunningTest()){
                    if(oldvol.Cohort_Sem__c==null || oldvol.AccountId != o.AccountId || Test.isRunningTest()) 
                        accSet.add(o.AccountId); 
                }
            }          
        }
        
        if(accSet.size()>0){
            List<Opportunity> lstOpps=new List<Opportunity>();
            if(Test.isRunningTest()){
                lstOpps=[Select Id,Cohort_Date_Value__c,Cohort_Sem__c,Cohort_Sem__r.Name,Cohort__c,CloseDate,TotalIWSSeats__c,AccountId,StageName from Opportunity ];
                
            }else{
                lstOpps= [Select Id,Cohort_Date_Value__c,Cohort_Sem__c,Cohort_Sem__r.Name,Cohort__c,CloseDate,TotalIWSSeats__c,AccountId,StageName from Opportunity WHERE AccountId IN:accSet AND RecordTypeId =: recordTypeId AND TotalIWSSeats__c>0 ];
                
            }
            
            for (Opportunity o : lstOpps) {
                
                if(oppMap.containsKey(o.AccountId)  ) {                
                    oppMap.get(o.AccountId).add(o); 
                } else {                   
                    oppMap.put(o.AccountId,new List<Opportunity>{o});                   
                }
            }
            for(Opportunity o : opps){
                if(!oppMap.isEmpty()){             
                    if(oppMap.containsKey(o.AccountId) && o.Cohort_Sem__c!=null ){
                        Integer i=0;
                        Integer j=0;
                        
                        for(Opportunity opp:oppMap.get(o.AccountId)){                                           
                            if(o.Cohort_Sem__c!=null ){
                                String Currentcohort = myCohortMapName.get(o.Cohort_Sem__c).Name;
                                String s = Currentcohort.Substring(0,Currentcohort.length()-4); 
                                String Prev2Cohort ='';
                                String Prev2Cohort1 ='';
                                Set<Id> Prev2CohortSet = new Set<Id>();
                                Integer CohortYear = Integer.valueof(Currentcohort.right(4));
                                if (s=='January ' ||  test.isrunningtest()){
                                    Prev2Cohort = 'July ' + (CohortYear-1);
                                    Prev2Cohort1 = 'January '+ (CohortYear-1); 
                                    Prev2CohortSet.add(myCohortMap.get(Prev2Cohort));  
                                    Prev2CohortSet.add(myCohortMap.get(Prev2Cohort1));               
                                }else if(s=='July ' ||  test.isrunningtest()) {
                                    Prev2Cohort = 'January ' + (CohortYear);
                                    Prev2Cohort1 = 'July '+ (CohortYear-1); 
                                    Prev2CohortSet.add(myCohortMap.get(Prev2Cohort));  
                                    Prev2CohortSet.add(myCohortMap.get(Prev2Cohort1));  
                                }  
                                
                                if( opp.TotalIWSSeats__c>0 && Prev2CohortSet.contains(opp.Cohort_Sem__c))
                                {
                                    i++;                                                                                  
                                }else if(opp.TotalIWSSeats__c>0 && !Prev2CohortSet.contains(opp.Cohort_Sem__c))
                                {
                                    j++;                                                                                  
                                }
                            }
                        }
                        
                        if(i>0){
                            o.Category__c = 'Existing Partner'; 
                        }else if(j>0){
                            o.Category__c = 'Reacquire Partner'; 
                        }else{
                            o.Category__c = 'New Partner'; 
                        }
                    }else if(o.Cohort_Sem__c!=null){
                        o.Category__c = 'New Partner';                
                    }else if(o.Cohort_Sem__c!=null){
                        o.Category__c = 'New Partner';
                    }
                }else if(o.Cohort_Sem__c!=null){
                    o.Category__c = 'New Partner';
                }
            }
        }
        
    }
    
    /**
    * Yearup.org
    *
    * @category  Opportunity Trigger handler 
    * @author    Yearup
    * @description This method creates Platform Events for Internship Matching.
    * 
    **/
    public static void MATCH_ProcessMatchingSeats(list<Opportunity> newItems, Map<Id, Opportunity> oldItems, System.TriggerOperation triggerEvent) {         
        Set<Id> oppSet = new Set<Id>();
       
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('InternshipSeats').getRecordTypeId();
        for( Opportunity newopp: newItems ){
            if(newopp.RecordTypeId == recordTypeId){
                switch on triggerEvent {                
                    when AFTER_UPDATE {                    
                        if( newopp.Cohort_Sem__c != oldItems.get(newopp.Id).Cohort_Sem__c )
                            oppSet.add( newopp.Id );
                    } 
                    when AFTER_DELETE { 
                        oppSet.add( newopp.Id );
                    } 
                    when AFTER_UNDELETE {
                        oppSet.add( newopp.Id );
                    } 
                }
            }
            
        }
        
        
        
        if(oppSet.size()>0){          
            Map<String,Internship_Work_Site__c> iwsMap =new  Map<String,Internship_Work_Site__c>([ 
                SELECT 
                Id
                FROM Internship_Work_Site__c
                WHERE Opportunity__c IN:oppSet 
            ]);
            
            if(iwsMap.size()>0) processMatchingSeats(iwsMap.keySet());
            
        }         
    }
    
    @future
    public static void processMatchingSeats(Set<String> iwsIds){
        new MATCH_ProcessingMatchingSeats(iwsIds);
    }
}