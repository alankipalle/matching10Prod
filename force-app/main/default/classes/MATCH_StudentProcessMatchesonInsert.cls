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
public class MATCH_StudentProcessMatchesonInsert implements TriggerAction.AfterInsert{
    public void afterInsert(List<MATCH_Matching_Student__c> newList) { 
        List<MATCH_Matching_Student__c> selectedStudents = new List<MATCH_Matching_Student__c>();
        Set<String> groupCohortTracks = new Set<String>();
        
        for( MATCH_Matching_Student__c matchStudent: newList ){
            if( matchStudent.CurrentCohort__c 
            	&& String.isNotBlank(matchStudent.Cohort_Name__c) 
            	&& String.isNotBlank(matchStudent.Matching_Group__c) 
            	&& String.isNotBlank(matchStudent.Track_Family_Name__c) 
               	&& matchStudent.GroupCohortTrackKey__c !=null ){
                selectedStudents.add( matchStudent );
                groupCohortTracks.add( matchStudent.GroupCohortTrackKey__c );
            }
        }
        
        
        if( selectedStudents.size()>0 ) insertMatchRecords( selectedStudents, groupCohortTracks);
    } 
    
    public void insertMatchRecords(List<MATCH_Matching_Student__c> selectedStudents, Set<String> groupCohortTracks){
        wrapperClass wrapper = getSeatsAndRules( groupCohortTracks );
        List<MATCH_Matching_Match__c>  matchesToInsert= new List<MATCH_Matching_Match__c>();
        
        for( MATCH_Matching_Student__c student:selectedStudents ){
            for( MATCH_Matching_Seat__c seat: wrapper.seats ){
                String addressId = MATCH_Utilities.removeSpecialCharcters(student.Address__c)+MATCH_Utilities.removeSpecialCharcters(seat.Address__c).toUppercase();
                String ruleKey = student.GroupCohortTrackKey__c+seat.GroupCohortTrackKey__c;
                if(wrapper.rulesMap.containsKey(ruleKey)){
                    matchesToInsert.add(
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
        
        if( matchesToInsert.size()>0 && matchesToInsert.size()<9000 ) {
            new MATCH_Utilities().upsertDML(matchesToInsert);            
            
        }else if( matchesToInsert.size()>0 && !system.isBatch() ){
            Database.executebatch(new MATCH_ProcessMatchRecordsJob(matchesToInsert));
        }
        
    }
    
    public static wrapperClass getSeatsAndRules( Set<String> groupCohortTracks ){
        
        Map<String,MATCH_Matching_Rule__c> matchRuleMap = new Map<String,MATCH_Matching_Rule__c>();   
        List<MATCH_Matching_Rule__c> rules =[SELECT Id,Student_Seat_Group_Cohort_Track_Key__c,Student_Group_Cohort_Track__c,Seat_Group_Cohort_Track__c FROM MATCH_Matching_Rule__c WHERE Is_Active__c = TRUE AND Current_Cohort__c=TRUE AND Student_Group_Cohort_Track__c IN: groupCohortTracks];
        Set<String> seatRuleKeys = new Set<String>();
        
        for( Integer i=0; i<rules.size(); i++ ){            
            matchRuleMap.put(rules[i].Student_Seat_Group_Cohort_Track_Key__c, rules[i] ); 
            seatRuleKeys.add(rules[i].Seat_Group_Cohort_Track__c);
        }
        
        return new wrapperClass(matchRuleMap, [Select id,name,GroupCohortTrackKey__c,Address__c FROM MATCH_Matching_Seat__c WHERE GroupCohortTrackKey__c IN:seatRuleKeys AND Is_Available__c=True]);
        
    }
    
    public class wrapperClass{
        public Map<String,MATCH_Matching_Rule__c> rulesMap{get;set;}
        public List<MATCH_Matching_Seat__c> seats{get;set;}
        public wrapperClass(Map<String,MATCH_Matching_Rule__c> rules, List<MATCH_Matching_Seat__c> seatsFound){
            this.rulesMap = rules;
            this.seats = seatsFound;
        }
    }
}