public class MATCH_ProcessMatchingStudentsEngagements {
    public User batchApexuser;
    public List<Engagement__c> engagementList;
    public string dmlType;
    public Set<String> engIds;
    private static final Set<String> engagementStatus= new Set<String>{'Enrolled','Fired','Deceased','Did Not Enroll'};
    
    public MATCH_ProcessMatchingStudentsEngagements(List<Engagement__ChangeEvent> engagements){  
        this.batchApexuser = MATCH_Utilities.getUser(); 
        this.engIds = new Set<String>();
        this.engagementList = new List<Engagement__c>();
        for (Engagement__ChangeEvent change : engagements) { 
            this.dmlType = change.ChangeEventHeader.getchangeType();          
            this.engIds.addAll(change.ChangeEventHeader.getRecordIds());
        }         
        this.engagementList = getEngagements();
       
        processEngagements();
    } 
    
    private void processEngagements(){
        Map<String,MATCH_Matching_Student__c> oldStudentsMap= getOldStudents();      
        
        List<MATCH_Matching_Student__c> studentstoUpsert = new List<MATCH_Matching_Student__c>();
        Map<string,Site_Cohort__c> sitecohorts = getSiteCohorts();
        Map<String,ENG_MathingStudent_Field_Mapping__mdt> fieldMaps = ENG_MathingStudent_Field_Mapping__mdt.getAll();
        
        for(Engagement__c engagement: this.engagementList){            
            studentstoUpsert.add( getStudent(engagement, oldStudentsMap?.get(engagement.id), sitecohorts,fieldMaps) );            
        }
    	
        new MATCH_Utilities().upsertDML(studentstoUpsert);        
    }
    
    private MATCH_Matching_Student__c getStudent(Engagement__c newEngagement, MATCH_Matching_Student__c oldStudent, Map<string,Site_Cohort__c> sitecohorts, Map<String,ENG_MathingStudent_Field_Mapping__mdt> fieldMaps){       
      
        MATCH_Matching_Student__c student = new MATCH_Matching_Student__c(); 
        if(oldStudent!=null) student.id = oldStudent.id;  
        student.ownerId = this.batchApexuser.Id;      
        student.Site_Cohort_External_ID__c=sitecohorts?.get(newEngagement.Cohort_Sem__r.MATCH_Cohort_Id_Auto__c + newEngagement.Site_Location__r.MATCH_Site_Id_Auto__c)?.MATCH_External_ID__c;
        student.Survey_Date__c=sitecohorts?.get(newEngagement.Cohort_Sem__r.MATCH_Cohort_Id_Auto__c + newEngagement.Site_Location__r.MATCH_Site_Id_Auto__c)?.Survey_Date__c;
        
        for(ENG_MathingStudent_Field_Mapping__mdt field:fieldMaps.values()){         
            student.put(field.Matching_Student_Field_API__c, MATCH_Utilities.recursiveGet(newEngagement,field.Engagement_Field__c));
        }               
        
        return student;
    }
    
    private List<Engagement__c> getEngagements(){
        Set<String> engagementIds = this.engIds;       
        String query ='SELECT '+String.join(getEngagementFields(), ',')+' FROM Engagement__c WHERE Track_Family_Assignment__c!=null AND Track_Family_Assignment__c!=\'--None--\' AND Site_Location__r.MATCH_Matching_Group__c!=null AND Site_Location__r.MATCH_Matching_Pilot_Site__c=TRUE AND Status__c IN:engagementStatus AND Id IN:engagementIds';
      
        return Database.query(query);
    }
    
    private List<String> getEngagementFields(){
        List<String> fields = new List<String>();
        Map<String,ENG_MathingStudent_Field_Mapping__mdt> fieldMaps = ENG_MathingStudent_Field_Mapping__mdt.getAll();
      
        for(ENG_MathingStudent_Field_Mapping__mdt mapField:fieldMaps.values()){
            fields.add(mapField.Engagement_Field__c);
        }       
        return fields;
    } 
    
    private Map<String,MATCH_Matching_Student__c> getOldStudents(){       
        Map<String,MATCH_Matching_Student__c> students = new Map<String,MATCH_Matching_Student__c>();  
        Set<String> recordIds = this.engIds;
        String query = getQuery();
        query+=' WHERE Engagement_Salesforce_Id__c IN:recordIds';     
       
        for(MATCH_Matching_Student__c student: Database.query( query )){           
            students.put(student.Engagement_Salesforce_Id__c,student);          
        }
        
        return students;        
    }
    
    private static String getQuery(){
        DescribeSObjectResult describeResult = MATCH_Matching_Student__c.getSObjectType().getDescribe();      
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        
        return ' SELECT ' + string.join (fieldNames, ',') + ' FROM ' + describeResult.getName();
    }  
    
    private Map<string,Site_Cohort__c> getSiteCohorts(){
        Set<String> cohortIds = new Set<String>();
        Set<String> siteIds = new Set<String>();
        
        for(Engagement__c engagegement:this.engagementList ){
            CohortIds.add(engagegement.Cohort_Sem__r.MATCH_Cohort_Id_Auto__c);
            siteIds.add(engagegement.Site_Location__r.MATCH_Site_Id_Auto__c	);
        }
        
        Map<String,Site_Cohort__c> siteCohortMap = new  Map<String,Site_Cohort__c>();
        for( Site_Cohort__c sitecohort: [SELECT Id,Survey_Date__c,MATCH_External_ID__c, Cohort__r.MATCH_Cohort_Id_Auto__c,Site_Location__r.MATCH_Site_Id_Auto__c FROM Site_Cohort__c WHERE Cohort__r.MATCH_Cohort_Id_Auto__c IN:cohortIds AND Site_Location__r.MATCH_Site_Id_Auto__c IN: siteIds]){
            String key = sitecohort.Cohort__r.MATCH_Cohort_Id_Auto__c+sitecohort.Site_Location__r.MATCH_Site_Id_Auto__c;
            siteCohortMap.put(key,sitecohort);
        }
        
        return siteCohortMap;
    }    
    
}