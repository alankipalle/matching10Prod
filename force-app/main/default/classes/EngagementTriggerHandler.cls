/**
* Engagement Trigger Handler for the Engagement object. This class extends the TriggerHandler
* class to help ensure the trigger code is in one place and bulkified.  Changing
*/

public class EngagementTriggerHandler extends TriggerHandler {
    public static Boolean TriggerDisabled = false;
    
    protected override String getCustomSettingField() { return 'EngagementTriggerDisabled__c'; }
    
    protected override void BeforeInsert(){
        CohortYearOnEngagement((List<Engagement__c>) Trigger.new); 
        siteOnEngagement((List<Engagement__c>) Trigger.new); 
        AppendCohortToName((List<Engagement__c>) Trigger.new);       
    }
    
    
    protected override void BeforeUpdate(){
        CohortYearOnEngagement((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        siteOnEngagement((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        AppendCohortToName((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        SetGenerateYearUpStudentIDFlag((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        SetSyncOffice365Flag((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        SetSyncSchoologyFlag((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        
    }
    
    protected override void AfterInsert() {
        UpdateContact((List<Engagement__c>) Trigger.new);
        //This is for Matching project
        //MATH_createStudentEvents((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap, Trigger.operationType); 
        createTestResults((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
    }
    
    protected override void AfterUpdate() {     
        createTestResults((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        UpdateContact((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);     
        GeneratePDFEngagements((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap);
        //This is for Matching project
        //MATH_createStudentEvents((List<Engagement__c>) Trigger.new, (Map<Id,Engagement__c>) Trigger.oldMap, Trigger.operationType); 
    }
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   List of Engagement
* 
*/
    @TestVisible
    private void siteOnEngagement(list<Engagement__c> engs) {        
        Set<Id> siteIds = new Set<Id>();        
        for (Engagement__c e : engs) {
            if(String.isNotBlank(e.Site_Location__c)) siteIds.add(e.Site_Location__c);            
        }        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = EngagementGateway.getSitesMap(siteIds);            
            for (Engagement__c e : engs) {                
                if (String.isNotBlank(e.Site_Location__c))
                    e.Site__c = siteMap?.get(e.Site_Location__c)?.Name;
            }             
        }        
        
    }
    
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   Map of Engagement
* @param   Map of old Engagement
* 
*/  
    
    @TestVisible
    private void siteOnEngagement(List<Engagement__c> engs, Map<Id, Engagement__c> oldItems) {        
        Set<Id> siteIds = new Set<Id>();
        for (Engagement__c e : engs) {
            if(String.IsNotBlank(e.Site_Location__c)){
                Engagement__c oldvol = (Engagement__c)oldItems.get(e.Id);
                if (e.Site_Location__c != oldvol.Site_Location__c) {  
                    siteIds.add(e.Site_Location__c);
                }
            }    
        }
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = EngagementGateway.getSitesMap(siteIds);             
            for (Engagement__c e : engs) {               
                if (String.isNotBlank(e.Site_Location__c))
                    e.Site__c = siteMap?.get(e.Site_Location__c)?.Name;
            }             
        }  
    }
    
    
    
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Engagement's
* 
*/
    @TestVisible
    private void CohortYearOnEngagement(list<Engagement__c> engmts) {        
        Set<Id> cohortIds = new Set<Id>();        
        for (Engagement__c e : engmts) {
            if(String.isNotBlank(e.Cohort_Sem__c)) cohortIds.add(e.Cohort_Sem__c);            
        }        
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = EngagementGateway.getCohortsMap(cohortIds);            
            for (Engagement__c e : engmts) {                
                if (String.isNotBlank(e.Cohort_Sem__c) && cohortMap.containsKey(e.Cohort_Sem__c))
                    e.Cohort__c = cohortMap.get(e.Cohort_Sem__c).Name;
            }             
        }        
        
    }
    
    
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Engagement's
* @param   Map of old Engagement's
* 
*/  
    
    @TestVisible
    private void CohortYearOnEngagement(List<Engagement__c> engmts, Map<Id,Engagement__c> oldItems) {        
        Set<Id> cohortIds = new Set<Id>();
        for (Engagement__c e : engmts) {
            if(String.IsNotBlank(e.Cohort_Sem__c)){
                Engagement__c oldvol = (Engagement__c)oldItems.get(e.Id);
                if (e.Cohort_Sem__c != oldvol.Cohort_Sem__c) {  
                    cohortIds.add(e.Cohort_Sem__c);
                }
            }    
        }
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = EngagementGateway.getCohortsMap(cohortIds);            
            for (Engagement__c e : engmts) {                
                if (String.isNotBlank(e.Cohort_Sem__c) && cohortMap.containsKey(e.Cohort_Sem__c))
                    e.Cohort__c = cohortMap.get(e.Cohort_Sem__c).Name;
            }             
        }  
    } 
    
    
    
    private void AppendCohortToName(list<Engagement__c> engmts) {
        for (Engagement__c e : engmts) {
            if (String.IsNotBlank(e.Cohort__c)) {
                e.Name = e.Name + ' - ' + e.Cohort__c;
            }
        }
    }
    
    private void AppendCohortToName(List<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        for (Engagement__c e : engmts) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if (e.Cohort__c != oldEngmt.Cohort__c) {                
                if (String.IsNotBlank(e.Cohort__c)) {                    
                    e.Name =  e.Name.split('-')[0] + ' - ' + e.Cohort__c;
                }
            }
        }
    }
    
    
    /**
    * This method updates accountId on contacts related to engagements when there is a Site
    * <p>
    * This method calls UpdateStudentContact method to update info on contact based on info in Engagement
    * @param   List of Engagement's
    * 
    */
    
    
    private void UpdateContact(list<Engagement__c> engmts) {
        set<Id> eIds = new set<Id>();
        Set<Id> contactIds = new Set<Id>();
        list<Contact> cntcts = new list<Contact>();
        Map<Id,Contact> updateConMap = new Map<Id,Contact>();
        map<String, String> siteStudentAccountMap = ApexUtility.GetSiteMappings(ApexUtility.SiteStudentAccountMapping);
        for (Engagement__c e : engmts) { 
            eIds.add(e.Id); 
            contactIds.add(e.Student__c);
        } 
        
        List<Engagement__c> engmtList = EngagementGateway.getEngagementsList(eIds); 
        
        updateConMap = UpdateStudentContact(engmtList, contactIds);
        
        
        for (Engagement__c e : engmtList) {
            if (String.isNotBlank(e.Student__c) && e.Site__c != '') {
                Contact c = new Contact();
                c.Id = e.Student__r.Id;
                if (!Test.isRunningTest()) {
                    c.AccountId = siteStudentAccountMap.get(ApexUtility.NationalSiteCode);
                    if (String.IsNotBlank(e.Site__c) && siteStudentAccountMap.containsKey(e.Site__c)) {
                        c.AccountId = siteStudentAccountMap.get(e.Site__c);
                    }
                    if(updateConMap.containsKey(e.Student__c)){
                        updateConMap.get(e.Student__c).AccountId = c.AccountId;
                        cntcts.add(c);
                    } 
                    else
                        updateConMap.put(e.Student__c,c);    
                }
            }
        }
        
        if(updateConMap.size()>0) update updateConMap.values();  
    }
    
    
    
    
    /**
* This method updates accountId on contacts related to engagements when there a Site is changed
* <p>
* This method calls UpdateStudentContact method to update info on contact based on info in Engagement
* @param   List of Engagement's
* @param   Map of OLD Engagements
* 
*/
    
    private void UpdateContact(list<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        set<Id> eIds = new set<Id>();
        Set<Id> contactIds = new Set<Id>();
        list<Contact> cntcts = new list<Contact>();
        Map<Id,Contact> updateConMap = new Map<Id,Contact>();
        map<String, String> siteStudentAccountMap = ApexUtility.GetSiteMappings(ApexUtility.SiteStudentAccountMapping);
        for (Engagement__c e : engmts) { 
            eIds.add(e.Id); 
            contactIds.add(e.Student__c);
        }
        
        List<Engagement__c> engmtList = EngagementGateway.getEngagementsList(eIds); 
        updateConMap = UpdateStudentContact(engmtList, contactIds);
        
        for (Engagement__c e : engmtList) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if (String.isNotBlank(e.Student__c) && e.site__c != Null && e.Site__c != oldEngmt.Site__c) {
                Contact c = new Contact();
                c.Id = e.Student__r.Id;
                if (!Test.isRunningTest()) {
                    c.AccountId = siteStudentAccountMap.get(ApexUtility.NationalSiteCode);
                    if (String.IsNotBlank(e.Site__c) && siteStudentAccountMap.containsKey(e.Site__c)) {
                        c.AccountId = siteStudentAccountMap.get(e.Site__c);
                    }
                    if(updateConMap.containsKey(e.Student__c)){
                        updateConMap.get(e.Student__c).AccountId = c.AccountId;
                        cntcts.add(c);
                    } 
                    else
                        updateConMap.put(e.Student__c,c);
                    cntcts.add(c);
                }
            }
        }
        
        if(updateConMap.size()>0) update updateConMap.values();       
    }
    
    
    /**
* Logic to assign engagement info to related contact record 
* <p>
* Assigns recordtype to contact based on engagement status and also Site, Cohort, most recent status on contact 
*
* @param   List of Engagement's
* @param   Set of Contact Ids
* @return  Map of Id and Contact
*/  
    
    
    Private Map<Id,Contact> UpdateStudentContact(list<Engagement__c> engmtList, Set<Id> contactIds){
        
        Map<Id,Contact> updateConMap = new Map<Id,Contact>();
        List<Contact> contacts = new List<Contact>();
        
        String recordTypeIdParticipant = ApexUtility.GetRecordTypesForObject('Contact').get('Participant').RecordTypeId;
        
        Map <Id, List<Integer>> engmap = new Map<Id, List<Integer>>();
        for (Integer q = 0; q < engmtList.size(); q++) {
            if (engmap.containsKey(engmtList[q].Student__c)){
                List<Integer> englist = engmap.get(engmtList[q].Student__c);
                englist.add(q);
                engmap.put(engmtList[q].Student__c, englist);
            }
            else {
                List<Integer> englist = new List<Integer>();
                englist.add(q);
                engmap.put(engmtList[q].Student__c, englist);  
            }
        }
        
        for (Contact d : ContactGateway.getContacts(contactIds)) {     
            Date maxcohort = Date.newInstance(1, 1, 1999);
            Integer maxindex = 0;
            
            // for each contact, take the list of engagements belonging to this contact  
            List<Integer> englist = engmap.get(d.Id);
            for(Integer i = 0; i < englist.size(); i++) {
                if (engmtList[englist[i]].student__c == d.id) {
                    // if engagement status=enrolled, update contact record type to participant
                    if (engmtList[englist[i]].status__c == 'Enrolled'){
                        d.recordTypeId = recordTypeIdParticipant;
                    }
                    
                    // find the most recent engagement from the set of this contact's engagements
                    if (engmtList[englist[i]].cohort_value__c > maxcohort) {
                        maxcohort = engmtList[englist[i]].cohort_value__c;
                        maxindex = englist[i];
                    }
                }
                // outside of the loop, push the most recent engagement info up to the contact
                d.site__c = engmtList[maxindex].site__c;
                d.cohort__c = engmtList[maxindex].cohort__c;
                d.most_recent_status__c = engmtList[maxindex].status__c;  
            }
            contacts.add(d);
            updateConMap.put(d.Id,d); 
        }  
        
        return updateConMap;  
        
    } 
    
    
    /**
* This method generates EngagementsPDF
* 
* @param   List of Engagement's
* @param   Map of OLD Engagements
* 
*/
    
    private void GeneratePDFEngagements(list<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        
        for (Engagement__c e : engmts) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if(e.Date_Online_App_Completed__c != Null && oldEngmt.Date_Online_App_Completed__c == Null){
                EngagementPDFGenerator.generateEngagementPDF(e);
            }
        }        
    }
    
    private void SetGenerateYearUpStudentIDFlag(List<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        for (Engagement__c e : engmts) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if (e.Status__c != oldEngmt.Status__c) {
                if (e.Status__c == 'Enrolled' && String.IsBlank(e.Year_Up_Student_ID__c)) {
                    e.Generate_Year_Up_Student_ID__c = true;
                } else {
                    e.Generate_Year_Up_Student_ID__c = false;
                }
            }
        }
    }
    
    private void SetSyncOffice365Flag(List<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        set<Id> cIds = new set<Id>();
        map<Id, String> cntctEmailMap = new map<Id, String>();
        for (Engagement__c e: engmts) {
            cIds.add(e.Student__c);
        }
        for (Contact c: [select Id, Email3__c from Contact where Id in :cIds]) {
            cntctEmailMap.put(c.Id, c.Email3__c);
        }
        for (Engagement__c e : engmts) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if (oldEngmt.Status__c != e.Status__c) {
                if (String.IsBlank(cntctEmailMap.get(e.Student__c)) && e.Status__c == 'Enrolled' && !e.Skip_Office_365_Account_Creation__c) {
                    e.Sync_Office365__c = true;
                } else if (String.IsNotBlank(cntctEmailMap.get(e.Student__c)) && e.Status__c == 'Enrolled' && !e.Skip_Office_365_Account_Creation__c) { // Commented for CA-07384 e.Status__c == 'Fired' || 
                    e.Sync_Office365__c = !oldEngmt.Sync_Office365__c;
                } else { e.Sync_Office365__c = false; }
            }
        }
    }
    
    private void SetSyncSchoologyFlag(List<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        set<Id> cIds = new set<Id>();
        map<Id, String> cntctEmailMap = new map<Id, String>();
        for (Engagement__c e : engmts) {
            Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);
            if (e.Status__c != oldEngmt.Status__c) {
                if (String.IsBlank(e.Schoology_ID__c) && e.Status__c == 'Enrolled' && !e.Skip_Schoology_Sync__c) {
                    e.Sync_Schoology__c = true;
                } else if (String.IsNotBlank(e.Schoology_ID__c) && oldEngmt.Status__c == 'Enrolled' && !e.Skip_Schoology_Sync__c) { // Commented for CA-07384 e.Status__c == 'Fired' ||
                    e.Sync_Schoology__c = true;
                } else { e.Sync_Schoology__c = false; }
            }
        }
    }
    
    public static void GenerateUniqueStudentID(set<Id> eIds) {
        
        set<String> sites = new set<String>();
        set<String> cohorts = new set<String>();
        map<String, String> maxIDMap = new map<String, String>();
        list<Engagement__c> engagements = [Select Id, Name, Site__c, Cohort__c, Learning_Community__r.Cohort_Type__c, Year_Up_Student_ID__c from Engagement__c where Id in :eIds and Site__c != null and Cohort__c != null and Learning_Community__c != null order by Name asc];
        for(Engagement__c e: engagements) {
            sites.add(e.Site__c);
            cohorts.add(e.Cohort__c);
        }
        list<AggregateResult> lAR = [select Site__c site, Cohort__c cohort, MAX(Year_Up_Student_ID__c) maxYUSID from Engagement__c where Site__c =: sites and Cohort__c =: cohorts group by Site__c, Cohort__c];    
        for (AggregateResult ar : lAR) {
            maxIDMap.put((String.valueOf(ar.get('site')) + String.valueOf(ar.get('cohort'))), String.valueOf(ar.get('maxYUSID')));
        }
        
        for(Engagement__c e: engagements) {
            String yuStudentID = '';
            String maxYUStudentID = maxIDMap.get(e.Site__c + e.Cohort__c);
            if (string.IsNotEmpty(maxYUStudentID)) {
                yuStudentID = maxYUStudentID.left(maxYUStudentID.length()-5) + String.valueOf((Integer.valueOf(maxYUStudentID.right(5)) + 1)).leftPad(5).replace(' ','0');
            } else {
                yuStudentID = e.Site__c.leftPad(5).replace(' ','0') + e.Learning_Community__r.Cohort_Type__c + e.Cohort__c.right(2) + (e.Cohort__c.left(3) == 'Jan' ? 'SP' : 'FA') + '00001';
            }
            e.Year_Up_Student_ID__c = yuStudentID;            
            e.Generate_Year_Up_Student_ID__c = false;
            maxIDMap.put(e.Site__c + e.Cohort__c, yuStudentID);
        }
        
        if(engagements.size()>0){
            try{
                update engagements;
            }
            catch (Exception ex) {    
                ApexLogging.logMessage('Generate Year Up Student ID', 'UniqueStudentID', ex.getMessage(), ApexLogging.ERROR, '', '');
            } 
        }          
    }
    
    
    public static void SyncOffice365Account(set<Id> eIds) {
        
        String accessToken, numberToAppend, uPN;
        list<Contact> cntcts = new list<Contact>();
        list<Engagement__c> engmts = new list<Engagement__c>();
        accessToken = Office365Handler.GetAccessToken();
        if (String.IsNotBlank(accessToken)) {
            for (Engagement__c e: [Select Id, Site__c, Status__c, Student__r.Id, Student__r.FirstName, Student__r.LastName, Student__r.Email3__c from Engagement__c where id in :eIds and Site__c != null]) {                
                if (e.Status__c == 'Enrolled' && String.IsBlank(e.Student__r.Email3__c)) {
                    numberToAppend = Office365Handler.GetNumberToAppendForDuplicateUPN(accessToken, e.Student__r.FirstName, e.Student__r.LastName, e.Site__c, 'Engagement', e.Id);
                    uPN = Office365Handler.CreateUser(accessToken, e.Student__r.FirstName, e.Student__r.LastName, e.Site__c, numberToAppend, 'Engagement', e.Id);
                    if (String.IsNotBlank(uPN)) {
                        Office365Handler.AssignLicense(accessToken, uPN, Office365Handler.Add, 'Engagement', e.Id);
                        cntcts.add(new Contact(Id = e.Student__r.Id, Email3__c = uPN, npe01__Preferred_Email__c = 'Year Up'));
                        engmts.add(new Engagement__c(Id = e.Id, Sync_Office365__c = false,Year_Up_email__c = uPN));
                    }
                }
                if (e.Status__c == 'Fired' && String.IsNotBlank(e.Student__r.Email3__c)) {
                    Office365Handler.DeleteUser(accessToken, e.Student__r.Email3__c, 'Engagement', e.Id);
                    cntcts.add(new Contact(Id = e.Student__r.Id, npe01__Preferred_Email__c = 'Personal'));
                    engmts.add(new Engagement__c(Id = e.Id, Sync_Office365__c = false));
                }
            }
            
            if (!engmts.isEmpty()) update engmts;
            if (!cntcts.isEmpty()) update cntcts;
        }
    }
    
    public static void SyncSchoologyAccount(set<id> eIds) {
        
        String sId;
        list<Contact> cntcts = new list<Contact>();
        list<Engagement__c> engmts = new list<Engagement__c>();
        for (Engagement__c e: [Select Id, Site__c, Sync_Schoology__c, Cohort__c, Status__c, Year_Up_Student_ID__c, Schoology_ID__c, Student__r.Id, Student__r.FirstName, Student__r.LastName, Student__r.Email3__c, Student__r.Gender__c, Student__r.Birthdate from Engagement__c where id in :eIds and Student__r.Email3__c != null and Year_Up_Student_ID__c != null]) {
            if (e.Status__c == 'Enrolled' && e.Sync_Schoology__c == true && String.IsBlank(e.Schoology_ID__c) && String.IsNotBlank(e.Student__r.Email3__c) && String.IsNotBlank(e.Year_Up_Student_ID__c)) {
                sId = SchoologyHandler.CreateUser(e.Year_Up_Student_ID__c, e.Site__c, e.Cohort__c, e.Student__r.FirstName, e.Student__r.LastName, e.Student__r.Email3__c, e.Student__r.Gender__c, e.Student__r.Birthdate, 'Engagement', e.Id); 
                if (String.IsNotBlank(sId)) {
                    engmts.add(new Engagement__c(Id = e.Id, Schoology_ID__c = sId, Sync_Schoology__c = false));
                }
            }
            
            if (e.Status__c == 'Alumni' && String.IsNotBlank(e.Schoology_ID__c)) {
                SchoologyHandler.UpdateUser(e.Schoology_ID__c, e.Year_Up_Student_ID__c, e.Student__r.Email3__c, true, 'Engagement', e.Id);
                engmts.add(new Engagement__c(Id = e.Id, Sync_Schoology__c = false));
                cntcts.add(new Contact(Id = e.Student__r.Id, npe01__Preferred_Email__c = 'Personal'));
            }
        }
        
        if (!engmts.isEmpty()) update engmts;
        if (!cntcts.isEmpty()) update cntcts;
    }
    
    /**
* Yearup.org
*
* @category  Engagement Trigger handler 
* @author    Yearup
* @description This method creates Test Info records.
* 
**/
    public static void createTestResults(list<Engagement__c> engmts, Map<Id, Engagement__c> oldItems) {
        
        List<Test_Info__c> testInfoList = new List<Test_Info__c>();
        
        for ( Engagement__c e : engmts ) {
            switch on Trigger.operationType {
                when AFTER_INSERT {                    
                    if( String.isNotBlank(e.Type_of_Test__c) && e.Type_of_Test__c != '' && String.isNotBlank(e.Client_Num__c)){
                        Test_Info__c t = new Test_Info__c();
                        t.Engagement__c = e.Id;
                        t.Test_Type__c = e.Type_of_Test__c;
                        
                        testInfoList.add(t);               
                    }
                }
                when AFTER_UPDATE {
                    Engagement__c oldEngmt = (Engagement__c)oldItems.get(e.Id);             
                    if( String.isNotBlank(e.Type_of_Test__c) && e.Type_of_Test__c != '' && oldEngmt.Type_of_Test__c != e.Type_of_Test__c && 
                       String.isNotBlank(e.Client_Num__c)){
                           Test_Info__c t = new Test_Info__c();
                           t.Engagement__c = e.Id;
                           t.Test_Type__c = e.Type_of_Test__c;
                           
                           testInfoList.add(t);               
                       }
                    // If the record is selcted for Random Screening, then create another Test Info record.
                    if( e.Random_Selected__c && oldEngmt.Random_Selected__c != e.Random_Selected__c && 
                       String.isNotBlank(e.Client_Num__c) ){
                           Test_Info__c t = new Test_Info__c();
                           t.Engagement__c = e.Id;
                           t.Test_Type__c = 'Additional Drug Screening';
                           testInfoList.add(t);
                       }
                }
            } 
            
        }
        
        if(testInfoList.size()>0) {
            insert testInfoList;
        }
    }
    
  
    
}