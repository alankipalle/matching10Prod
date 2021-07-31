@isTest
public class InternshipCDCTriggerTest {
    @isTest static void testNewAndUpdatedAccount() {
        // Enable all Change Data Capture entities for notifications.
        Test.enableChangeDataCapture();
		Site__c site = TestDataUtility.createSite('NY', 40, false);    
        site.MATCH_Matching_Pilot_Site__c = TRUE;
        site.MATCH_Matching_Group__c ='NY-NJ';
        insert site;

        Site_Mappings__c sm = TestDataUtility.createSiteMapping('NY', 'bos', '231313131', true);
        Cohort__c cohort = TestDataUtility.createCohort('July 2022', System.today(), System.today().addMonths(6), TRUE);        
        
      	String recordtypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Internship Seats').getRecordTypeId();
        Account acc = TestUtility.createAccount('TestAccount','Organization',TRUE);
        Contact contact = TestDataUtility.createContact('foo', 'test', String.valueOf(acc.id), TRUE);
        Engagement__c engagement = TestDataUtility.createEngagement('John7', 'Doe', 'NY', 'Prospect', 'July 2022', 'Application Form', contact.Id, false);
        engagement.Site_Location__c = site.Id;
        engagement.Cohort_sem__c = cohort.Id;
        engagement.Status__c = 'Enrolled'; 
        engagement.APP_Soc_Sec__c ='123560079';	
        insert engagement;

        Opportunity opp = new Opportunity();
        opp.name = 'Test Opportunity';
        opp.AccountId = acc.ID;
        opp.Cohort_sem__c = cohort.id;
        opp.closeDate = System.today();
        opp.StageName = 'Open';
        opp.Corporate_Account__c = acc.Id;
        opp.RecordTypeID = recordtypeID; 
        insert opp;
        
        Internship_Work_Site__c iws = new Internship_Work_Site__c();
        iws.Name ='Test IWS';            
        iws.Opportunity__c = opp.id;
        iws.Stage__c= 'Seats Confirmed';
        iws.TrackFamily__c = 'Information Technology';
        iws.Specialty__c = 'Helpdesk/Desktop Support';
        iws.Site_Located__c = site.id;
        iws.SeatsConfirmed__c = 3;
        iws.Probability__c = 100; 
        iws.FinancialDecisionMaker__c =contact.id;   
        iws.InternshipStartDate__c = System.today(); 
        iws.Partner_to_provide_tech_for_internship__c='Yes';
        insert iws; 
        
        MATCH_Matching_Seat__c seat= (MATCH_Matching_Seat__c)TestDataFactory.createSObject(new MATCH_Matching_Seat__c(), 'TestDataFactoryDefaults.MatchingSeatDefaults', false);  
        seat.IWS_Salesforce_ID__c= iws.id;
        insert seat;
        
        // Call deliver to fire the trigger and deliver the test change event.
        Test.getEventBus().deliver();
        
        Apprenticeship__c internship =[SELECT Id,name,Billing_Address__c FROM Apprenticeship__c LIMIT 1];
        
        Test.startTest();
        internship.Billing_Address__c ='test';
        update internship;
         Test.getEventBus().deliver();
        Test.stopTest();
        
    }    
}