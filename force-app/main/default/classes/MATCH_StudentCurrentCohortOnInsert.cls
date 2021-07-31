public class MATCH_StudentCurrentCohortOnInsert implements TriggerAction.BeforeInsert{
    public void beforeInsert(List<MATCH_Matching_Student__c> newList) {  
        Set<String> groupCohortTracks = new Set<String>();
        List<MATCH_Matching_Student__c> students = new List<MATCH_Matching_Student__c>();
        for( MATCH_Matching_Student__c matchStudent: newList ){  
            if( String.isNotBlank(matchStudent.Cohort_Name__c) 
            && String.isNotBlank(matchStudent.Matching_Group__c) 
            && String.isNotBlank(matchStudent.Track_Family_Name__c) 
            && matchStudent.GroupCohortTrackKey__c !=null ){               
                groupCohortTracks.add( matchStudent.GroupCohortTrackKey__c );
                students.add(matchStudent);
            }
        } 
        
        Map<String,MATCH_Matching_Rule__c> studentRules=getStudentsAndRules( groupCohortTracks );
        
        for( MATCH_Matching_Student__c matchStudent: newList ){  
           if( studentRules.containsKey(matchStudent.GroupCohortTrackKey__c) )
               matchStudent.CurrentCohort__c = TRUE;
        }   
    }
    
     public static Map<String,MATCH_Matching_Rule__c> getStudentsAndRules( Set<String> groupCohortTracks ){
        
        Map<String,MATCH_Matching_Rule__c> matchRuleMap = new Map<String,MATCH_Matching_Rule__c>();   
        List<MATCH_Matching_Rule__c> rules =[SELECT Id, Student_Group_Cohort_Track__c FROM MATCH_Matching_Rule__c WHERE Is_Active__c = TRUE AND Current_Cohort__c=TRUE AND Seat_Group_Cohort_Track__c IN: groupCohortTracks];
              
        for( Integer i=0; i<rules.size(); i++ ){            
            matchRuleMap.put(rules[i].Student_Group_Cohort_Track__c, rules[i] );
        }
        
        return matchRuleMap;
        
    }
}