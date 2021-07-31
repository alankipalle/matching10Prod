@isTest
public class MATCH_UtilitiesTest {
    @testSetup    
    static void createStudents() {
        
        // Create common test accounts        
        List<MATCH_Matching_Student__c> testStudents = new List<MATCH_Matching_Student__c>();
        
        for(Integer i=0;i<20;i++) {            
            testStudents.add(new MATCH_Matching_Student__c(Name = 'TestAcct'+i));            
        }
        
        insert testStudents;   
    }
    
    @isTest static void abbreviateWithinFieldLengthTest(){
        MATCH_Utilities.abbreviateWithinFieldLength('Sample Text', Account.Description);
    }
    
    testMethod static void listViewtestCallout() {      
        List<MATCH_Utilities.fieldWrapper> fieldWrappers = new List<MATCH_Utilities.fieldWrapper>();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MATCH_ListViewMockCallout());
        
        Test.startTest();
        fieldWrappers = MATCH_Utilities.readListViewMD('00B38000007aDSFEA2');
        Test.stopTest();
        
    }
    
    testMethod static void getListTest() {
        List <MATCH_Matching_Student__c> testStudents = [SELECT ID,Name FROM MATCH_Matching_Student__c];
        Map<Id,MATCH_Matching_Student__c> studentsMap = new Map<Id,MATCH_Matching_Student__c>(testStudents);
        Set<String> students = new Set<String>();
        
        for(String s: studentsMap.keySet()){
            students.add(s);
        }
        List<MATCH_Utilities.fieldWrapper> fieldWrappers = new List<MATCH_Utilities.fieldWrapper>();
        MATCH_Utilities.fieldWrapper wrapper= new MATCH_Utilities.fieldWrapper();
        wrapper.fieldName = 'Address__c';
        wrapper.fieldLabel = 'Address';                  
        fieldWrappers.add(wrapper);
        Test.startTest();
        MATCH_Utilities.getRecordList(students, 'MATCH_Matching_Student__c', fieldWrappers);
        Test.stopTest();
        
    }
    
    
    
    testMethod static void processCommuteTest() {
        MATCH_Matching_Rule__c matchingRule = new MATCH_Matching_Rule__c(
            Market_Name__c = 'YUBOS',                          // Market Name
            Student_Track_Family__c = 'Software Development & Support',  // Student Track Family
            Cohort_Name__c = 'July 2021',                        // Cohort Name
            Seat_Track_Family__c = 'Information Technology',        // Seat Track Family
            
            Is_Active__c = true                                 // Is Active
        );
        insert matchingRule;
        
        MATCH_Matching_Student__c student = new MATCH_Matching_Student__c( 
            Cohort_Name__c = 'July 2021',                         // Cohort Name
            site_name__c = 'MA',                                  // Site Name
            market_name__c = 'YUBOS',                             // Market Name
            Track_Family_Name__c = 'Software Development & Support',         // Track Family Name  
            Address__c ='44 Milk Street'
            
        );
        insert student;
        
        List<MATCH_Matching_Address__c> address = [SELECT Id,Name FROM MATCH_Matching_Address__c];
        System.assertEquals(1, address.size());
        
        MATCH_Matching_Seat__c seat = new MATCH_Matching_Seat__c(
            Name = 'Marc Anthony Reyes',                                   // Matching Student
            Cohort_Name__c = 'July 2021',                    			 // Cohort Date
            Site_Name__c = 'PHX',                                            // Site Name
            Market_Name__c = 'YUBOS',                                         // Market Name
            Track_Family_Name__c = 'Information Technology',
            Address__c ='45 Milk Street'
        );
        insert seat; 
       
        
        List<MATCH_Matching_Address__c> addresses = [SELECT Id,Name,Address__c FROM MATCH_Matching_Address__c];
        System.assertEquals(2, addresses.size());
        
        List<MATCH_Matching_Match__c> matches = [SELECT Id,Name FROM MATCH_Matching_Match__c];
        //System.assertEquals(1, matches.size());
       
         
        MATCH_Commute__c commute = new MATCH_Commute__c(
          Original_Address__c = addresses[0].Id,                                                                                                                                         // Origin Address
          Destination_Address__c = addresses[1].Id                                                                                                                                 // Destination Address
                                                                                                      
        );
        insert commute;     
        
        List<MATCH_Matching_Address__c> newaddresses = [SELECT Id,Name,Address__c FROM MATCH_Matching_Address__c];                
        List<MATCH_Commute__c> commutes = [SELECT Id,Name,Destination_Address__r.Google_Place_Id__c,Original_Address__r.Google_Place_Id__c,Destination_Address__r.Address__c,Original_Address__r.Address__c FROM MATCH_Commute__c];
        
        Test.startTest();
        	//MATCH_Utilities.processCommutes(new Set<Id>{newaddresses[0].Id, newaddresses[1].Id}, new Set<id> {student.Id}, 'Matching_Student__c');
        Test.stopTest();
    }
    
    testMethod static void processCommuteNoCommutesTest() {
        MATCH_Matching_Rule__c matchingRule = new MATCH_Matching_Rule__c(
            Market_Name__c = 'YUBOS',                          // Market Name
            Student_Track_Family__c = 'Software Development & Support',  // Student Track Family
            Cohort_Name__c = 'July 2021',                        // Cohort Name
            Seat_Track_Family__c = 'Information Technology',        // Seat Track Family
            
            Is_Active__c = true                                 // Is Active
        );
        insert matchingRule;
        
        MATCH_Matching_Student__c student = new MATCH_Matching_Student__c( 
            Cohort_Name__c = 'July 2021',                         // Cohort Name
            site_name__c = 'MA',                                  // Site Name
            market_name__c = 'YUBOS',                             // Market Name
            Track_Family_Name__c = 'Software Development & Support',         // Track Family Name  
            Address__c ='44 Milk Street'
            
        );
        insert student;
        
        List<MATCH_Matching_Address__c> address = [SELECT Id,Name FROM MATCH_Matching_Address__c];
        //System.assertEquals(1, address.size());
        
        MATCH_Matching_Seat__c seat = new MATCH_Matching_Seat__c(
            Name = 'Marc Anthony Reyes',                                   // Matching Student
            Cohort_Name__c = 'July 2021',                    			 // Cohort Date
            Site_Name__c = 'PHX',                                            // Site Name
            Market_Name__c = 'YUBOS',                                         // Market Name
            Track_Family_Name__c = 'Information Technology',
            Address__c ='45 Milk Street'
        );
        insert seat; 
       
        
        List<MATCH_Matching_Address__c> addresses = [SELECT Id,Name,Address__c FROM MATCH_Matching_Address__c];
        System.assertEquals(2, addresses.size());
        
        List<MATCH_Matching_Match__c> matches = [SELECT Id,Name FROM MATCH_Matching_Match__c];
        //System.assertEquals(1, matches.size());
       
        
        List<MATCH_Matching_Address__c> newaddresses = [SELECT Id,Name,Address__c FROM MATCH_Matching_Address__c];                
        
        Test.startTest();
        	//MATCH_Utilities.processCommutes(new Set<Id>{newaddresses[0].Id, newaddresses[1].Id}, new Set<id> {student.Id}, 'Matching_Student__c');
        Test.stopTest();
    }
    
    testMethod static void picklistTest(){
        MATCH_Utilities.picklistValues('Engagement__c', 'Site__c');
    }
    
    
}