public class MATCH_StudentProcessAddressOnUpdate implements TriggerAction.AfterUpdate{
    public void afterUpdate(List<MATCH_Matching_Student__c> newList, List<MATCH_Matching_Student__c> oldList) {  
        Set<Id> newStudentsIds = new Set<Id>();
        Map<Id,MATCH_Matching_Student__c> oldMap = new Map<Id,MATCH_Matching_Student__c>(oldList);
        for( MATCH_Matching_Student__c matchStudent: newList ){  
            if( String.isNotBlank(matchStudent.Address__c) && oldMap.get(matchStudent.Id).Address__c != matchStudent.Address__c){
                newStudentsIds.add( matchStudent.Id );  
            }
        } 
        
        if(newStudentsIds.size()>0) new MATCH_ProcessAddresses(newStudentsIds);        
    } 
}