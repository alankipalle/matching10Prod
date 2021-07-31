/**
* Internship Trigger Handler for the Internship object. This class extends the TriggerHandler
* class to help ensure the trigger code is in one place and bulkified.  
*/
public class InternshipTriggerHandlerNew extends TriggerHandler {
    public static Boolean TriggerDisabled = false;
    public static String newRecs, updateRecs;    
    public static final Integer MIN_VALUE= 6000;
    public static final Integer MAX_VALUE= 69999;
    public static Integer minValue = 0;
    public static Integer maxValue = 0;
    public static Integer lastAssignValue = 0;
    public static Boolean isBeforeInsertEntered = false;
    public static Boolean isBeforeUpdateEntered = false;
    static List<Address_Field_Mapping__c> addressFieldMappings = AddressHelper.getRelatedMappingRecords('Apprenticeship__c','child');     
    
    @TestVisible
    protected override String getCustomSettingField() { return 'InternshipTriggerDisabled__c'; }
    
    @TestVisible
    protected override void BeforeInsert(){        
        CohortYearOnInternship((List<Apprenticeship__c>) Trigger.new);        
        siteOnInternship((List<Apprenticeship__c>) Trigger.new); 
        studentContactUpdateOnInternship((List<Apprenticeship__c>) Trigger.new, null, newRecs);
        internshipgenerateABILANumber((List<Apprenticeship__c>) Trigger.new);
        populateSurveyFields((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap);
    }
    
    @TestVisible
    protected override void BeforeUpdate(){
        CohortYearOnInternship((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap);
        siteOnInternship((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap);
        studentContactUpdateOnInternship((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap, updateRecs);        
        internshipgenerateABILANumber((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap);  
        populateSurveyFields((List<Apprenticeship__c>) Trigger.new, (Map<Id,Apprenticeship__c>) Trigger.oldMap);
    } 
    
    @TestVisible
    protected override void AfterInsert(){
        AccountRollupFields.internshipFields((List<Apprenticeship__c>) Trigger.new);           
        
    } 
    
    @TestVisible
    protected override void AfterUpdate(){
        AccountRollupFields.internshipFields((List<Apprenticeship__c>) Trigger.old);         
       
        
    } 
    
    @TestVisible
    protected override void AfterDelete(){
        AccountRollupFields.internshipFields((List<Apprenticeship__c>) Trigger.old);    
        
    } 
    
    @TestVisible
    protected override void AfterUndelete(){
        AccountRollupFields.internshipFields((List<Apprenticeship__c>) Trigger.new);  
       
    } 
    
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   List of internships
* 
*/
    @TestVisible
    private void siteOnInternship(list<Apprenticeship__c> interns) {        
        Set<Id> siteIds = new Set<Id>();        
        for (Apprenticeship__c i : interns) {
            if(String.isNotBlank(i.Site_Location__c)) siteIds.add(i.Site_Location__c);            
        }        
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = InternshipGateway.getSitesMap(siteIds);            
            for (Apprenticeship__c i : interns) {                
                if (String.isNotBlank(i.Site_Location__c))
                    i.Site__c = siteMap.get(i.Site_Location__c).Name;
            }             
        }        
        
    }
    
    
    
    /**
* This method assigns Site value in picklist field from Site Location Lookup field
* 
* @param   Map of internships
* @param   Map of old internships
* 
*/  
    
    @TestVisible
    private void siteOnInternship(List<Apprenticeship__c> interns, Map<Id, Apprenticeship__c> oldItems) {        
        Set<Id> siteIds = new Set<Id>();
        for (Apprenticeship__c i : interns) {
            if(String.IsNotBlank(i.Site_Location__c)){
                Apprenticeship__c oldvol = (Apprenticeship__c)oldItems.get(i.Id);
                if (i.Site_Location__c != oldvol.Site_Location__c) {  
                    siteIds.add(i.Site_Location__c);
                }
            }    
        }
        if(siteIds.size()>0){
            Map<Id,Site__c> siteMap = InternshipGateway.getSitesMap(siteIds);             
            for (Apprenticeship__c i : interns) {               
                if (String.isNotBlank(i.Site_Location__c))
                    i.Site__c = siteMap.get(i.Site_Location__c).Name;
            }             
        }  
    }
    
    
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Internship's
* 
*/
    @TestVisible
    private void CohortYearOnInternship(list<Apprenticeship__c> interns) {        
        Set<Id> cohortIds = new Set<Id>();        
        for (Apprenticeship__c intrn : interns) {
            if(String.isNotBlank(intrn.Cohort_Sem__c)) cohortIds.add(intrn.Cohort_Sem__c);            
        }        
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = InternshipGateway.getCohortsMap(cohortIds);            
            for (Apprenticeship__c i : interns) {                
                if (String.isNotBlank(i.Cohort_Sem__c))
                    i.Cohort__c = cohortMap.get(i.Cohort_Sem__c).Name;
            }             
        }        
        
    }
    
    /**
* This method assigns Cohort value in picklist field from Cohort Lookup field
* 
* @param   List of Internship's
* @param   Map of old Internship's
* 
*/  
    
    @TestVisible
    private void CohortYearOnInternship(List<Apprenticeship__c> interns, Map<Id,Apprenticeship__c> oldItems) {        
        Set<Id> cohortIds = new Set<Id>();
        for (Apprenticeship__c intrn : interns) {
            if(String.IsNotBlank(intrn.Cohort_Sem__c)){
                Apprenticeship__c oldvol = (Apprenticeship__c)oldItems.get(intrn.Id);
                if (intrn.Cohort_Sem__c != oldvol.Cohort_Sem__c) {  
                    cohortIds.add(intrn.Cohort_Sem__c);
                }
            }    
        }
        if(cohortIds.size()>0){
            Map<Id,Cohort__c> cohortMap = InternshipGateway.getCohortsMap(cohortIds);            
            for (Apprenticeship__c i : interns) {                
                if (String.isNotBlank(i.Cohort_Sem__c))
                    i.Cohort__c = cohortMap.get(i.Cohort_Sem__c).Name;
            }             
        }  
    }
    
    
    /**
* This method assigns Student Contact from related engagement student
*  
* @param   List of Internship's
* @param   Map of old Internship's
* 
*/
    @TestVisible
    private void studentContactUpdateOnInternship(List<Apprenticeship__c> interns, Map<Id,Apprenticeship__c> oldItems, String event) {        
        Set<Id> engagementIds = new Set<Id>();
        List<Apprenticeship__c> internsStudentContactList = new List<Apprenticeship__c>();
        
        if(event == 'updateRecs' && olditems.size()>0){
            for (Apprenticeship__c intrn : interns) {
                if(String.IsNotBlank(intrn.Student__c)){
                    Apprenticeship__c oldvol = (Apprenticeship__c)oldItems.get(intrn.Id);
                    if (intrn.Student__c != oldvol.Student__c) {  
                        internsStudentContactList.add(intrn); 
                        engagementIds.add(intrn.Student__c);
                    }
                }    
            }
        }   
        else{
            for(Apprenticeship__c intrn : interns){
                if(String.IsNotBlank(intrn.Student__c)){                     
                    internsStudentContactList.add(intrn); 
                    engagementIds.add(intrn.Student__c);                    
                } 
            }    
        }
        if(engagementIds.size()>0){     
            Map<Id, Engagement__c> allEngagements = InternshipGateway.getEngagementsMap(engagementIds);
            
            for (Apprenticeship__c app : internsStudentContactList){
                if(String.IsNotBlank(app.Student__c) && allEngagements.containsKey(app.Student__c))
                    app.Student_Contact__c = allEngagements.get(app.Student__c).Student__c ; 
            }  
        }               
        
    }
    
    
    
    
    
    /*--------Lines from Previous Trigger Handler----- //Manoj ------*/
    /**
* This method determines which records has to go through generateABILANumber process 
* <p>
* This method calls generateABILANumber method to assign ABILA number to Internship record 
* @param   List of Internship's
* 
*/
    
    public static void internshipgenerateABILANumber(List<Apprenticeship__c> newInternsList) {
        
        if (!isBeforeInsertEntered ) {
            List<Apprenticeship__c> truncInternsList = new List<Apprenticeship__c>();
            for(Apprenticeship__c insObj : newInternsList) {
                // S-328816 - Commented Active_ABILA_Customer_Number__c == null condition - Hemlata
                if (/* insObj.Active_ABILA_Customer_Number__c == null && */ (insObj.Employer__c != null || insObj.Billing_Contact__c != null || insObj.Site__c != null || 
                                                                             (insObj.Site__c != null  && insObj.Billing_Address__c != null && insObj.Billing_City__c != null && insObj.Billing_State__c != null))) {
                                                                                 truncInternsList.add(insObj);
                                                                             }
            }
            if (truncInternsList.size() > 0) {
                generateABILANumber(truncInternsList,null); 
                isBeforeInsertEntered = true;         
            }
            
        }  
        //updateAddressFields(newInternsList,null); /* Added by Jai Gupta - S-332459 - July 29,2015 - Sync address fields*/
    }
    
    /**
* This method determines which records has to go through generateABILANumber process 
* <p>
* This method calls generateABILANumber method to assign ABILA number to Internship record 
* @param   List of Internship's New records
* @param   Map of Internship's Old records
*
*/
    
    public static void internshipgenerateABILANumber(List<Apprenticeship__c> newInternsList, Map<Id,Apprenticeship__c> oldInternsMap) {
        if (!isBeforeUpdateEntered ) {   
            List<Apprenticeship__c> truncInternsList = new List<Apprenticeship__c>();
            for(Apprenticeship__c insObj : newInternsList) {
                if (insObj.Employer__c != oldInternsMap.get(insObj.Id).Employer__c || insObj.Billing_Contact__c != oldInternsMap.get(insObj.Id).Billing_Contact__c ||
                    insObj.Site__c != oldInternsMap.get(insObj.Id).Site__c  || insObj.Billing_Address__c != oldInternsMap.get(insObj.Id).Billing_Address__c || insObj.Billing_City__c != oldInternsMap.get(insObj.Id).Billing_City__c || insObj.Billing_State__c != oldInternsMap.get(insObj.Id).Billing_State__c) {
                        truncInternsList.add(insObj);
                    }
            }
            if (truncInternsList.size() > 0 ) {
                generateABILANumber(truncInternsList,oldInternsMap);
                isBeforeUpdateEntered = true;
            }
            
        }
        //updateAddressFields(newInternsList,oldInternsMap); /* Added by Jai Gupta - S-332459 - July 29,2015 - Sync address fields*/
        
    }
    
    /**
* This method gets minValue and maxValue from custom setting Internship_ABILA_Setting__c
* <p>
* The values are used in below generateABILANumber method 
*
*/
    public static List<Internship_ABILA_Setting__c> getminMaxValue() {
        List<Internship_ABILA_Setting__c> minMaxSetting = Internship_ABILA_Setting__c.getall().values();
        if (minMaxSetting != null && minMaxSetting.size() >0) {
            if (minMaxSetting[0].Min_Value__c != null) {
                minValue = (Integer)minMaxSetting[0].Min_Value__c;
            } else {
                minValue  = MIN_VALUE;
            }     
            if (minMaxSetting[0].Max_Value__c != null) {
                maxValue  = (Integer)minMaxSetting[0].Max_Value__c;
            } else {    
                maxValue  = MAX_VALUE;
            } 
            if (minMaxSetting[0].Last_Assign_Value__c != null) {
                lastAssignValue =(Integer)minMaxSetting[0].Last_Assign_Value__c;
            }
        } else {
            minValue  = MIN_VALUE;
            maxValue  = MAX_VALUE;
        }
        return minMaxSetting;
    }    
    
    
    /**
* This method generate next value to assign to ABILA_Customer_Number_Change__c 
* <p>
* This method calls getminMaxValue method to get minValue and maxValue from custom setting
* @param   List of Internship's New records
* @param   Map of Internship's Old records
*
*/  
    public static void generateABILANumber(List<Apprenticeship__c> internsList, Map<Id,Apprenticeship__c> oldInternsMap) {
        Integer MaxUniqueId;
        List<Internship_ABILA_Setting__c> minMaxSetting = getminMaxValue();
        system.debug('**maxValue***'+maxValue);
        system.debug('**minValue***'+minValue);
        // To get max ABILA number from database
        List<AggregateResult> MaxAbila = [SELECT MAX(ABILA_Customer_Number_Change__c) max from Apprenticeship__c WHERE ABILA_Customer_Number_Change__c != null ];    
        if ( MaxAbila.size() > 0) {
            Integer maxAbilaNumber = Integer.valueOf(MaxAbila[0].get('max')); 
            system.debug('**maxAbilaNumber ***'+maxAbilaNumber );
            if( maxAbilaNumber  == null  || maxAbilaNumber < minValue ) {
                MaxUniqueId = minValue; // should only assign the mon value if the existing is less
            } else {
                MaxUniqueId = maxAbilaNumber+1;
            } 
        } else {
            MaxUniqueId = minValue;
        }
        Integer count = 0;
        system.debug('***MaxUniqueId **'+MaxUniqueId );
        for(Apprenticeship__c insObj : internsList) {
            // S-328816 - Commented below and update previous ABILA in field update of workflow - Hemlata
            //  insObj.Previous_Abilia_Customer_number__c = insObj.Active_ABILA_Customer_Number__c;  
            
            if (MaxUniqueId <= maxValue) {                               
                insObj.ABILA_Customer_Number_Change__c = MaxUniqueId;
                MaxUniqueId++;
            } else if (MaxUniqueId > maxValue) {                
                if (lastAssignValue == null || lastAssignValue < minValue || lastAssignValue> maxValue) {
                    lastAssignValue = minValue;
                    insObj.ABILA_Customer_Number_Change__c = lastAssignValue;  
                } else if (lastAssignValue >= minValue && lastAssignValue <= maxValue)  {
                    insObj.ABILA_Customer_Number_Change__c = lastAssignValue;
                } 
                lastAssignValue++;
                
            }
            system.debug('**insObj.ABILA_Customer_Number_Change__c**'+insObj.ABILA_Customer_Number_Change__c); 
        } // for 
        system.debug('**internsList**'+internsList);
        if (minMaxSetting != null && minMaxSetting.size() >0 && (Integer)minMaxSetting[0].Last_Assign_Value__c != lastAssignValue) {
            minMaxSetting[0].Last_Assign_Value__c = lastAssignValue;
            update minMaxSetting;
        }         
    }
    
  
    
    /**
    * This method populate all survey fields from Survey object
    * 
    * @param   list of internships
    * @param   Map of old internships
    * 
    */  
    
    @TestVisible
    private void populateSurveyFields(List<Apprenticeship__c> interns, Map<Id, Apprenticeship__c> oldItems) {        
        Set<Id> surveyids = new Set<Id>();
        for (Apprenticeship__c intern : interns) {
            switch on Trigger.operationType {
                when BEFORE_INSERT {   
                    if( intern.Seat_Survey_Result__c!=null )
                        surveyids.add(intern.Seat_Survey_Result__c); 
                }
                when BEFORE_UPDATE {
                    if( intern.Seat_Survey_Result__c != oldItems.get(intern.id).Seat_Survey_Result__c )     
                        surveyids.add(intern.Seat_Survey_Result__c);   
                }
            }     
        }
        
        if(surveyids.size()>0){
            String query = getQuery()+' WHERE Id IN:surveyids';
            List<Seat_Survey_Result__c> surveys = Database.query(query);
            Map<Id,Seat_Survey_Result__c> siteMap = new Map<Id,Seat_Survey_Result__c>();  
            siteMap.putAll(surveys);   
            
            for ( Apprenticeship__c intern : interns ){
                if( intern.Seat_Survey_Result__c!=null ){
                    if( siteMap.containsKey(intern.Seat_Survey_Result__c) ){
                        for( Schema.FieldSetMember fld :getFields() ) {
                            intern.put(fld.getFieldPath(),siteMap.get(intern.Seat_Survey_Result__c).get(fld.getFieldPath()));
                        }
                        intern.Secondary_Approver__c    =   siteMap.get(intern.Seat_Survey_Result__c).Secondary_Supervisor__c;
                        intern.Supervisor__c            =   siteMap.get(intern.Seat_Survey_Result__c).Primary_Supervisor__c;
                        intern.Location__c              =   siteMap.get(intern.Seat_Survey_Result__c).Internship_Address__c; 
                    }
                    
                }else{
                    for( Schema.FieldSetMember fld :getFields() ) {
                         intern.put(fld.getFieldPath(),null);
                    }
                    intern.Secondary_Approver__c    =   null;
                    intern.Supervisor__c            =   null;
                    intern.Location__c              =   null;
                }                
            }                      
        }  
    }
    
    
    private static string getQuery(){
        String queryString = 'select id,Secondary_Supervisor__c,Primary_Supervisor__c,Internship_Address__c';
        for(Schema.FieldSetMember fld :getFields()) {
            queryString += ', ' + fld.getFieldPath();
        }
        return queryString += ' from Seat_Survey_Result__c';
    }
    
    private static list<Schema.FieldSetMember> getFields(){
        return SObjectType.Apprenticeship__c.FieldSets.Survey_Fields.getFields();
    }
}