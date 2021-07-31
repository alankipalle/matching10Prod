/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-26-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   07-26-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public with sharing class MATCH_MatchingStudentTest {
    static testMethod void MATCH_StudentAddressProcessOnUpdate_Test(){
        MATCH_Matching_Student__c student = (MATCH_Matching_Student__c)TestDataFactory.createSObject(new MATCH_Matching_Student__c(), 'TestDataFactoryDefaults.MatchingStudentDefaults', false);  
        student.Address__c ='45 Milk Street, Boston, MA';
        insert student;

        Test.startTest();
        student.Address__c ='46 Milk Street, Boston, MA';
        update student;
        Test.stopTest();

        List<MATCH_Matching_Address__c> address=[SELECT Id,Name FROM MATCH_Matching_Address__c];
        System.assert(address.size() == 2,'Address is not Created');
    }

    static testMethod void MATCH_StudentProcessMatchesonUpdate_test() {
       
        MATCH_Matching_Rule__c rule = (MATCH_Matching_Rule__c)TestDataFactory.createSObject(new MATCH_Matching_Rule__c(), 'TestDataFactoryDefaults.MatchingRuleDefaults', true); 
        MATCH_Matching_Student__c student = (MATCH_Matching_Student__c)TestDataFactory.createSObject(new MATCH_Matching_Student__c(), 'TestDataFactoryDefaults.MatchingStudentDefaults', false);
        student.Cohort_Name__c ='January 2021';
        insert student;
        
        MATCH_Matching_Seat__c seat= (MATCH_Matching_Seat__c)TestDataFactory.createSObject(new MATCH_Matching_Seat__c(), 'TestDataFactoryDefaults.MatchingSeatDefaults', false);  
        seat.IWS_Stage__c ='Qualified Prospect';
        insert seat;

        MATCH_Matching_Student__c studentRecord =[SELECT ID,Cohort_Name__c,CurrentCohort__c FROM MATCH_Matching_Student__c LIMIT 1 ];             
        MATCH_Matching_Seat__c seatRecord =[SELECT ID,IWS_Stage__c,Cohort_Name__c,CurrentCohort__c FROM MATCH_Matching_Seat__c LIMIT 1 ];       
       
        System.assertEquals(0,[SELECT Count() FROM MATCH_Matching_Match__c], 'Macthes are not Created properly');

        Test.startTest();
        studentRecord.Cohort_Name__c = 'July 2021';
        update studentRecord;
        Test.stopTest();

       System.assertEquals(1,[SELECT Count() FROM MATCH_Matching_Match__c], 'Macthes are not Created properly');
    }
}