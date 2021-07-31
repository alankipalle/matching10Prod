public class MATCH_StudentProcessAddressOnInsert implements TriggerAction.AfterInsert{
    public void afterInsert(List<MATCH_Matching_Student__c> newList) {  
        Set<Id> newStudentsIds = new Set<Id>();
        for( MATCH_Matching_Student__c matchStudent: newList ){  
            if( String.isNotBlank(matchStudent.Address__c) ){
                newStudentsIds.add( matchStudent.Id );  
            }
        } 
        
        if(newStudentsIds.size()>0) new MATCH_ProcessAddresses(newStudentsIds);        
    } 
}