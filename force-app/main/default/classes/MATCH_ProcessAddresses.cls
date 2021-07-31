/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This class is used to handle process Address records for both Student and Seat records.
* this is called from both Student and Seat trigger handler. This will create new address and
* deactivate old address if any address changes on seat or student record.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ajay Lankipalle   <alankipalle@yearup.org>
* @modifiedBy     Ajay Lankipalle   <alankipalle@yearup.org>
* @maintainedBy   Ajay Lankipalle   <alankipalle@yearup.org>
* @version        1.0
* @created        2020-05-12
* @modified       YYYY-MM-DD
* @systemLayer    Invocation | Service | Utility | Selector | Domain | Test
* @see            ????
* @see            ????
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0            alankipalle@yearup.org
* 2020-05-12      Initial Version.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class MATCH_ProcessAddresses {
    private static Set<Id> sObjectIds{get;set;}
    private static String objectType{get;set;}

    public MATCH_ProcessAddresses(Set<Id> sObjectRecordIds) {
        sObjectIds = sObjectRecordIds; 
        Id recordId = new List<Id> (sObjectRecordIds).get(0);
        objectType = String.valueOf(recordId.getsobjecttype()); 
        run();       
    }

    private static void run(){  
        List<MATCH_Matching_Address__c> addressToUpsert= new List<MATCH_Matching_Address__c>();         
        for( sObject parentRecord: Database.query(getQuery()) ){
            
            //If addresses existing deactivate them
            if( parentRecord.getSObjects('Matching_Addresses__r' ) <> null ){
                for( MATCH_Matching_Address__c address: (List<MATCH_Matching_Address__c>) parentRecord.getSObjects('Matching_Addresses__r') ){
                    addressToUpsert.add(
                        new MATCH_Matching_Address__c(
                            Id = address.Id,
                            Is_Active__c = FALSE,
                            End_Date__c = System.Today()
                        )
                    );
                }
            }

            //Create new Address and activate them
            MATCH_Matching_Address__c newAddress= new MATCH_Matching_Address__c();
            newAddress.put(objectType.replace('MATCH_',''), parentRecord.Id);
            newAddress.Address__c = String.valueOf(parentRecord.get('Address__c'));
            newAddress.Is_Active__c = TRUE;
            newAddress.Start_Date__c = System.Today();

            addressToUpsert.add(newAddress);
        } 
        
        if( addressToUpsert.size()>0 ) Database.upsert(addressToUpsert);
    }

    private static String getQuery(){        
        String query = 'SELECT Id, Address__c, (SELECT Id, Address__c,Is_Active__c FROM Matching_Addresses__r WHERE Is_Active__c=TRUE) FROM ';   
               query+= objectType=='MATCH_Matching_Student__c' ? ' MATCH_Matching_Student__c WHERE Id IN: sObjectIds' : ' MATCH_Matching_Seat__c WHERE Id IN: sObjectIds';
        return query;
    }
}