public class MATCH_StudentCurrentCohortOnUpdate implements TriggerAction.BeforeUpdate{
    public void beforeUpdate(List<MATCH_Matching_Student__c> newList, List<MATCH_Matching_Student__c> oldList) {  
        Set<String> groupCohortTracks = new Set<String>();
        List<MATCH_Matching_Student__c> students = new List<MATCH_Matching_Student__c>();
       
        for( MATCH_Matching_Student__c matchStudent: newList ){  
            if( isChanged(matchStudent,new Map<Id,MATCH_Matching_Student__c>(oldList).get(matchStudent.id))){   
                groupCohortTracks.add( matchStudent.GroupCohortTrackKey__c );
                students.add(matchStudent);
            }
        } 
        
        if(students.size()>0){
            Map<String,MATCH_Matching_Rule__c> studentRules=MATCH_StudentCurrentCohortOnInsert.getStudentsAndRules( groupCohortTracks );
            
            for( MATCH_Matching_Student__c matchStudent: newList ){ 
                if( studentRules.containsKey(matchStudent.GroupCohortTrackKey__c) ){                 
                    matchStudent.CurrentCohort__c = TRUE;
                }else{
                    matchStudent.CurrentCohort__c = FALSE;  
                }
                
            }
        }
        
    } 
    
    private Boolean isChanged(MATCH_Matching_Student__c newStudent,MATCH_Matching_Student__c oldStudent){  
        
        return newStudent.GroupCohortTrackKey__c !=null
            && String.isNotBlank(newStudent.Engagement_Status__c) 
            && String.isNotBlank(newStudent.Cohort_Name__c) 
            && String.isNotBlank(newStudent.Matching_Group__c) 
            && String.isNotBlank(newStudent.Track_Family_Name__c) 
            && (oldStudent.Matching_Group__c != newStudent.Matching_Group__c 
                || oldStudent.Cohort_Name__c != newStudent.Cohort_Name__c 
                || oldStudent.Track_Family_Name__c != newStudent.Track_Family_Name__c);
    }
}