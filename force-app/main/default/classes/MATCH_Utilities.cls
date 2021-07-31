public class MATCH_Utilities {
    
    
    /**
    * Returns an abbreviated string value no longer than max allowable length for the field.
    * If string value is empty or null then returns an empty string.
    * @see String.abbreviate
    */
    public static String abbreviateWithinFieldLength( String value, SObjectField field ) {
        return abbreviate( value, field.getDescribe().getLength() );
    }
    
    /**
    * Returns an abbreviated string value no longer than `maxWidth`.
    * If string value is empty or null then returns empty string.
    * @see String.abbreviate
    */
    public static String abbreviate( String value, Integer maxWidth ) {
        return ( String.isBlank( value ) ? '' : value.abbreviate( maxWidth ) );
    }
    
    public static String removeSpecialCharcters(String value){       
        return ( String.isBlank( value ) ? '' : value.replaceAll('[^a-zA-Z0-9\\s+]', '') ).deleteWhitespace();
    }
    
    public static user getUser(){
        return [SELECT ID FROM USER WHERE Alias ='buser'];
    }
    
    
      
    
    
    public static void commitWork(list<sObject> sObjectList, String className, String methodName, String objectName, string dmlType ){
        if(sObjectList.size()==0) return;
        ApexLogging LOG = ApexLogging.create(true);
        try{    
            Database.SaveResult[] lsr;
            if(dmlType == 'insert')
                lsr = Database.insert(sObjectList,false); 
            else if(dmlType == 'update')
                lsr = Database.update(sObjectList,false); 
                        
            
            Integer recordid = 0;
            
            for (Database.SaveResult SR : lsr) {
                if (!SR.isSuccess()) {                     
                    LOG.log(className, methodName, SR.getErrors()[0].getMessage(), ApexLogging.WARNING,sObjectList[recordid].Id);	
                }
                recordid++;
            }
            
        }catch (DMLException e ){
            LOG.log(className, methodName, e.getMessage(), ApexLogging.WARNING,null);	
            //ApexLogging.logMessage(className, methodName, e.getMessage(), ApexLogging.WARNING); 
        }  
        
        LOG.flush();  
    }
    
    
    
    public static List<fieldWrapper> readListViewMD(String devlName) {
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String endPoinURL = baseUrl+'/services/data/v48.0/ui-api/list-ui/'+devlName;
        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HTTPResponse response = http.send(req);
        List<fieldWrapper> fieldWrappers = new List<fieldWrapper>();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) { 
            System.debug(response.getBody());
            String res=response.getBody();
            MATCH_ListViewJSONParser JSONDetails=(MATCH_ListViewJSONParser) System.JSON.deserialize(res, MATCH_ListViewJSONParser.class);            
            for(MATCH_ListViewJSONParser.DisplayColumns column: JSONDetails.Info.displayColumns) {                
                if(column.fieldApiName!=null && column.label!=null && column.fieldApiName!='Name'){                 
                    fieldWrapper wrapper= new fieldWrapper();
                    wrapper.fieldName = column.fieldApiName;
                    wrapper.fieldLabel = column.label;                  
                    fieldWrappers.add(wrapper);
                } 
            }
        }
        return fieldWrappers;
    }
    
    public class fieldWrapper{
        public String fieldName { get; set;}
        public String fieldLabel { get; set;}
    }
    
    public static List<sObject> getRecordList(Set<String> recordIds, String objectName, List<fieldWrapper> fieldWrappers ) {
        List<String> fields = new List<String>();
        for(MATCH_Utilities.fieldWrapper wrapper:fieldWrappers ){
            fields.add(wrapper.fieldName);
        }
        String fieldString = String.join(fields, ', ');
        String query = 'SELECT Id,Name, '+fieldString+' FROM '+objectName+' WHERE ID IN:recordIds';
        return Database.query(query);
    }
    
    
    public static Set<String> picklistValues(String objectName, String fieldName){
        Set<String> picklistvalues = new Set<String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();       

        for( Schema.PicklistEntry pickListVal : ple){
          picklistvalues.add(pickListVal.getLabel()); 
        } 
        
        return picklistvalues;
    } 
    
    public static void processMatches(Set<id> recordsIds, String objectName){
        
        Map<Id,MATCH_Matching_Match__c> matchesToUpdate = new Map<Id,MATCH_Matching_Match__c>();  
        
        String sQuery =' SELECT Id,Matching_Student__r.CurrentCohort__c,Matching_Student__r.Address__c,Matching_Seat__r.Address__c FROM MATCH_Matching_Match__c'; 
        sQuery+= objectName=='STUDENT' ? ' WHERE Matching_Student__c IN:recordsIds' : ' WHERE Matching_Seat__c IN:recordsIds';
        sQuery+= ' AND Finalize_Match__c=False';
        
        for(MATCH_Matching_Match__c match: Database.query(sQuery) ){ 
            String addressId = match.Matching_Student__r.Address__c !=null && match.Matching_Seat__r.Address__c!=null ? MATCH_Utilities.removeSpecialCharcters(match.Matching_Student__r.Address__c + match.Matching_Seat__r.Address__c).toUppercase() : '';			
            
            if(String.isNotBlank(addressId)){
                matchesToUpdate.put(match.Id,new MATCH_Matching_Match__c(
                    Id=match.Id,
                    Address_Unique_Id__c = addressId.length()>255 ? addressId.SubString(0,255) : addressId,
                    Address_Validated_Status_Google_API__c = False
                ));
            }            
        }

        if(matchestoUpdate.size()>0){
            commitWork(matchestoUpdate.values(),'MATCH_Utitlities','processMatches','MATCH_Matching_Match__c','update'); 
        } 
    }
    
     public static final Integer MAX_SCHEDULED_JOBS = 10;
    // Determine whether the maximum number
    // of Scheduled Jobs has been reached
    public static Boolean MaxScheduledJobsReached() {
        return (GetScheduledJobs().size() >= MAX_SCHEDULED_JOBS) ;
    }
    
    // Returns all Scheduled Apex jobs that have not been started yet 
    public static List<CronTrigger> GetScheduledJobs() {
        return [select Id, NextFireTime 
                from CronTrigger 
                where State in ('WAITING','ACQUIRED','EXECUTING')
                or NextFireTime != NULL];
    }
    
    // Builds a CRON Expression out of a Datetime
    public static String GetCRONExpression(Datetime dt) {
        return ('' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year());
    }
    
    public static boolean isSandbox(){
        //return false;
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    
    public static Set<String> pilotSites(){
        Set<String> siteExternalIds = new Set<String>();
        
        for(Site__c site: [SELECT Id,Name,MATCH_Site_Id_Auto__c FROM Site__c WHERE MATCH_Matching_Pilot_Site__c=TRUE]){
            siteExternalIds.add(site.MATCH_Site_Id_Auto__c);
        }
        
        return siteExternalIds;
    }
    
    public static List<MATCH_Matching_Seat_FieldMap__mdt> getfiledmap(String sObjectType){
        List<MATCH_Matching_Seat_FieldMap__mdt> fieldMaps = new List<MATCH_Matching_Seat_FieldMap__mdt>();
        for( MATCH_Matching_Seat_FieldMap__mdt filedMap: [SELECT Id,Event_Field__c,Event_From__c,Seat_Field__c FROM MATCH_Matching_Seat_FieldMap__mdt WHERE Event_From__c=:sObjectType] ){
             fieldMaps.add(filedMap);           
        }
        
        return fieldMaps;
    } 
    
    public void upsertDML(List<sObject> upsertRecords){
        List<Database.upsertResult> upsertResults = Database.upsert(upsertRecords, false);
        ApexLogging LOG = ApexLogging.create(true);
        for(Integer i=0;i<upsertResults.size();i++){
           if (!upsertResults.get(i).isSuccess()){
               
                Database.Error error = upsertResults.get(i).getErrors().get(0);
                String failedDML = error.getMessage();
                upsertRecords.get(i);
               System.debug('Not Successfully Created Record: '+upsertRecords.get(i));
                LOG.log('MATCH_Utilities', 'upsertDML', error.getMessage(), ApexLogging.ERROR,upsertRecords[i].Id);	
           }else{
               System.debug('Successfully Created Record: '+upsertRecords.get(i));
           }
        }
        
        LOG.flush();  
    }
    
     public static String getFieldSetSOQL(FieldSet source) {
        String[] fields = new String[0];
        for(FieldSetMember field: source.getFields()) {
            fields.add(field.getFieldPath());
        }
        return 'SELECT '+String.join(fields,',')+' FROM '+String.valueOf(source.getSObjectType());
    }
    
     public static FieldSet getFields(String fsObject, String fsName) {      
        return Schema.getGlobalDescribe().get(fsObject).getDescribe().fieldSets.getMap().get(fsName);
    }
    
     public static Object recursiveGet(sObject record, String field) {
		if(field.contains('.')) {
			Integer firstPeriod = field.indexOf('.');
			String nextObjectName = field.subString(0, firstPeriod);
			String remainingfieldName = field.subString(firstPeriod + 1, field.length());
			sObject nextObject = record.getSObject(nextObjectName);
			if(nextObject == null) {
				return null;
			} else {
				return recursiveGet(nextObject, remainingfieldName);
			}
		} else {
			return record.get(field);	
		}
	}
    
    public static Integer getCurrentLineNumber(Exception e)
    {
       
            String line2 = e.getStackTraceString()?.split('\n')[1];
            Pattern patt = Pattern.compile('([A-Za-z0-9_.<>]+): line (\\d+)');
            Matcher match = patt.matcher(line2);
            match.find();
            return Integer.valueOf(match.group(2));
       
    }
    
}