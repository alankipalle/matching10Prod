public class MATCH_StudentUpdateMatchesAddKeyonUpdate implements TriggerAction.AfterUpdate{
    public void afterUpdate(List<MATCH_Matching_Student__c> newList, List<MATCH_Matching_Student__c> oldList) {  
        Map<Id,MATCH_Matching_Student__c> oldMap = new Map<Id,MATCH_Matching_Student__c>(oldList);        
        Set<Id> studentIds = new Set<Id>();
        for( MATCH_Matching_Student__c newRecord: newList ){
            if( String.isNotBlank( newRecord.Address__c) &&  oldMap.get(newRecord.Id).Address__c != newRecord.Address__c ){              
                studentIds.add( newRecord.Id);
            }
        } 
        
        if(studentIds.size()>0) MATCH_Utilities.processMatches(studentIds, 'STUDENT' );
    }
}