/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-27-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-27-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class MATCH_StudentProcessMatchesonUpdate implements TriggerAction.AfterUpdate{
    public void afterUpdate(List<MATCH_Matching_Student__c> newList, List<MATCH_Matching_Student__c> oldList) {  
        List<MATCH_Matching_Student__c> selectedStudents = new List<MATCH_Matching_Student__c>();
        Set<String> groupCohortTracks = new Set<String>();
        
        Map<Id,MATCH_Matching_Student__c> oldMap = new Map<Id,MATCH_Matching_Student__c>(oldList);
        for( MATCH_Matching_Student__c matchStudent: newList ){  
            if( isChanged(matchStudent,oldMap.get(matchStudent.Id)) ){                        
                selectedStudents.add( matchStudent );
                groupCohortTracks.add( matchStudent.GroupCohortTrackKey__c );
            }
        } 
        
        if( selectedStudents.size()>0 ) processMatchRecords(selectedStudents, groupCohortTracks);       
    } 
    
    private Boolean isChanged(MATCH_Matching_Student__c newStudent,MATCH_Matching_Student__c oldStudent){  
        
        return newStudent.GroupCohortTrackKey__c !=null
            && String.isNotBlank(newStudent.Engagement_Status__c) 
            && String.isNotBlank(newStudent.Cohort_Name__c) 
            && String.isNotBlank(newStudent.Matching_Group__c) 
            && String.isNotBlank(newStudent.Track_Family_Name__c) 
         
            && ( oldStudent.Matching_Group__c != newStudent.Matching_Group__c 
                 || oldStudent.Cohort_Name__c != newStudent.Cohort_Name__c 
                 || oldStudent.Track_Family_Name__c != newStudent.Track_Family_Name__c);
    }
    
    public static void processMatchRecords(List<MATCH_Matching_Student__c> selectedStudents, Set<String> groupCohortTracks){
        MATCH_StudentProcessMatchesonInsert.wrapperClass wrapper = MATCH_StudentProcessMatchesonInsert.getSeatsAndRules( groupCohortTracks );
        List<MATCH_Matching_Match__c>  matchesToUpsert= new List<MATCH_Matching_Match__c>();      
        Map<String,MATCH_Matching_Match__c> matches=getMatches(new Map<Id,MATCH_Matching_Student__c>( selectedStudents ).keySet());
       
        for( MATCH_Matching_Student__c student:selectedStudents ){
            for( MATCH_Matching_Seat__c seat: wrapper.seats ){
               
                String matchFinderKey = String.valueOf(student.id)+String.valueOf(seat.id); 
                if( !matches.containsKey( matchFinderKey )){                                  
                    /*String ruleKey = student.GroupCohortTrackKey__c+seat.GroupCohortTrackKey__c;
                    if( matches.get(matchFinderKey).Matching_Rule__c != wrapper.rulesMap.get(ruleKey).Id){
                        matchesToUpsert.add(
                                new MATCH_Matching_Match__c(   
                                    Id= matches.get(matchFinderKey).id,
                                    MATCH_Track_Family_Rule__c      =   wrapper.rulesMap.get(ruleKey).Id                                   
                                )
                    	);
                    }*/
                    String addressId = MATCH_Utilities.removeSpecialCharcters(student.Address__c)+MATCH_Utilities.removeSpecialCharcters(seat.Address__c).toUppercase();
                    String ruleKey = student.GroupCohortTrackKey__c+seat.GroupCohortTrackKey__c;
                    if(wrapper.rulesMap.containsKey(ruleKey)){
                        matchesToUpsert.add(
                                new MATCH_Matching_Match__c(
                                    Matching_Student__c             =   student.Id,
                                    Matching_Seat__c                =   seat.Id,
                                    MATCH_Track_Family_Rule__c      =   wrapper.rulesMap.get(ruleKey).Id,
                                    Address_Unique_Id__c            =   addressId.length()>255 ? addressId.SubString(0,255) : addressId
                                   
                                )
                    );
                    } 
                }
                                
            }
        }
        
        System.debug('************Rules are updated: ' + matchesToUpsert.size());
        
        if( matchesToUpsert.size()>0 && matchesToUpsert.size()<9000 ) {
            new MATCH_Utilities().upsertDML(matchesToUpsert);            
            
        }else if( matchesToUpsert.size()>0 && !system.isBatch() ){
            Database.executebatch(new MATCH_ProcessMatchRecordsJob(matchestoUpsert));
        }
        
    }
    
    private static Map<String,MATCH_Matching_Match__c> getMatches(Set<Id> studentIds){      
        
        Map<String,MATCH_Matching_Match__c> matchingMatches = new Map<String,MATCH_Matching_Match__c>();        
        List<MATCH_Matching_Match__c> matches = [SELECT Id,Matching_Rule__c,Match_Finder_Key__c,MATCH_Track_Family_Rule__c FROM MATCH_Matching_Match__c WHERE Finalize_Match__c=False AND Matching_Student__c IN: studentIds];
              
        for( Integer i=0; i<matches.size(); i++ ){ 
             matchingMatches.put(matches[i].Match_Finder_Key__c, matches[i] );
        } 
        
        return matchingMatches;
    }
}