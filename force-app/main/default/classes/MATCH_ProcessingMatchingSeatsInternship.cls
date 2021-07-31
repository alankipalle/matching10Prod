public class MATCH_ProcessingMatchingSeatsInternship {
    public User batchApexuser;
    public List<Apprenticeship__c> internshipList;
    public Set<String> internIds;
    public Map<String,INT_to_Matching_Seat_Field_Mapping__mdt> fieldMap;
    public string dmlType;
    
    public MATCH_ProcessingMatchingSeatsInternship(List<Apprenticeship__ChangeEvent> intRecords){  
        System.debug('Internship Updated:');
        this.internIds = new Set<String>();
        this.internshipList = new List<Apprenticeship__c>();
        this.fieldMap = new Map<String,INT_to_Matching_Seat_Field_Mapping__mdt>();       
        for (Apprenticeship__ChangeEvent change : intRecords) { 
            this.dmlType = change.ChangeEventHeader.getchangeType();          
            this.internIds.addAll(change.ChangeEventHeader.getRecordIds());
        }  
        this.batchApexuser = MATCH_Utilities.getUser();
        this.internshipList = getInternships(this.internIds); 
        this.fieldMap=INT_to_Matching_Seat_Field_Mapping__mdt.getAll();
        
        processInternshipEvents();
    } 
    
    public List<Apprenticeship__c> getInternships(Set<String> internshipIds){
        String query ='SELECT '+getInternshipFields()+' FROM Apprenticeship__c WHERE Site_Location__r.MATCH_Matching_Pilot_Site__c=TRUE AND Id IN:internshipIds';
        return Database.query(query);
    }
    
    private static String getInternshipFields(){
        Map<String,INT_to_Matching_Seat_Field_Mapping__mdt> intSeatFieldMapping = INT_to_Matching_Seat_Field_Mapping__mdt.getAll();
        Set<String> fields = new Set<String>();
        for(INT_to_Matching_Seat_Field_Mapping__mdt mapField:intSeatFieldMapping.values()){
            fields.add(mapField.Internship_Field__c);
        }       
        return string.join (new List<String>(fields), ',');
    }  
    
    private void processInternshipEvents(){  
        List<MATCH_Matching_Seat__c> seatstobeUpserted = new List<MATCH_Matching_Seat__c>();
        Map<String, List<Apprenticeship__c>> eventsMapbyIWS = new Map<String, List<Apprenticeship__c>>();
        Set<String> internshipsIds = new Set<String>();
        
        for( Apprenticeship__c seatEvent: this.internshipList ){  
            if( this.dmlType == 'AFTER_INSERT' || this.dmlType == 'CREATE' ) {
                if(!eventsMapbyIWS.containsKey(seatEvent.InternshipWorkSite__c)){
                    eventsMapbyIWS.put( seatEvent.InternshipWorkSite__c, new List<Apprenticeship__c>{ seatEvent } ); 
                }else {
                    eventsMapbyIWS.get( seatEvent.InternshipWorkSite__c).add( seatEvent ); 
                }
            }else {
                internshipsIds.add( seatEvent.Id);
            }       
        }
        
        if(eventsMapbyIWS.size()>0) {
            seatstobeUpserted.addAll(processEventsInsert(eventsMapbyIWS));
        }
        if(internshipsIds.size()>0 || this.dmlType =='DELETE') {
            seatstobeUpserted.addAll(processEventsUpdate(internshipsIds));
        }
        System.debug('Internship Updated: seatstobeUpserted'+seatstobeUpserted);
        new MATCH_Utilities().upsertDML(seatstobeUpserted);
    }
    
    
    private List<MATCH_Matching_Seat__c> processEventsInsert(Map<String, List<Apprenticeship__c>> eventsMapbyIWS){       
        
        List<MATCH_Matching_Seat__c> seatstoInsert = new List<MATCH_Matching_Seat__c>();
        Map<String,List<MATCH_Matching_Seat__c>> oldSeatsMap = new Map<String,List<MATCH_Matching_Seat__c>>();
        oldSeatsMap = getOldSeats(eventsMapbyIWS.keySet());
        
        for(String internshipSaleId: eventsMapbyIWS.keySet()){          
            seatstoInsert.addAll(processSeats( oldSeatsMap.get(internshipSaleId) ));
        }  
        
        return seatstoInsert;        
    }
    
    
    private List<MATCH_Matching_Seat__c> processEventsUpdate(Set<String> internshipsIds){
        System.debug('Internship Updated: method'+internshipsIds);
        List<MATCH_Matching_Seat__c> seats = new List<MATCH_Matching_Seat__c>();
        Map<String,MATCH_Matching_Seat__c> oldSeatsMap = new Map<String,MATCH_Matching_Seat__c>();
        Set<String> interIds = internshipsIds.size()>0 ? internshipsIds : this.internIds;
        for( MATCH_Matching_Seat__c seat: [ SELECT Id,Internship_Salesforce_ID__c FROM MATCH_Matching_Seat__c WHERE Internship_Salesforce_ID__c IN: interIds] ){
            oldSeatsMap.put(seat.Internship_Salesforce_ID__c, seat);   
        }      
        
        for( Apprenticeship__c seatEvent: this.internshipList )  {
            if(oldSeatsMap.containsKey(seatEvent.id)) {               
                seats.add( getSeat(seatEvent,oldSeatsMap.get(seatEvent.id),null) );
            }else{
                seats.add( getSeat(seatEvent,null,null) );
            }            
        }
        
        if(this.dmlType=='DELETE') {
            for(String internid:this.internIds){ 
                
                if(oldSeatsMap.containsKey(internid)){
                    MATCH_Matching_Seat__c seat=oldSeatsMap.get(internid);
                    seat.Seat_Status__c =  'INTERNSHIP_'+this.dmlType;                  
                    seat.internship_id__c = ''; 
                    seat.Internship_External_ID__c = '';
                    seat.Internship_Salesforce_ID__c = '';
                    seat.Name = seat.id;
                    
                    seats.add( seat );
                }
            } 
        }
        
        System.debug('Internship Updated: seats'+seats);
        
        return seats;     
        
    }
    
    
    /*private Map<String, List<Apprenticeship__c>> internshipsbyIWS(){  
        Map<String, List<Apprenticeship__c>> eventsMapbyIWS = new Map<String, List<Apprenticeship__c>>();
        
        for( Apprenticeship__c seatEvent: this.internshipList ) { 
            
            if(!eventsMapbyIWS.containsKey(seatEvent.InternshipWorkSite__c)){
                eventsMapbyIWS.put( seatEvent.InternshipWorkSite__c, new List<Apprenticeship__c>{ seatEvent } );  
            }else {
                eventsMapbyIWS.get( seatEvent.InternshipWorkSite__c).add( seatEvent ); 
            }      
        }
        return eventsMapbyIWS;
    }*/
    
    private static Map<String,List<MATCH_Matching_Seat__c>> getOldSeats(Set<String> recordIds){       
        Map<String,List<MATCH_Matching_Seat__c>> seatsByIWS = new Map<String,List<MATCH_Matching_Seat__c>>();   
        String query = getQuery();
        query+=' WHERE IWS_Salesforce_ID__c IN:recordIds ORDER BY IWS_Salesforce_ID__c';  
        
        for(MATCH_Matching_Seat__c seat: Database.query( query )){
            String key =seat.IWS_Salesforce_ID__c;
            if( !seatsByIWS.containsKey(key) )
                seatsByIWS.put(key,new List<MATCH_Matching_Seat__c>{ seat });
            else
                seatsByIWS.get(key).add( seat );
        }
        
        return seatsByIWS;        
    }
    
    private List<MATCH_Matching_Seat__c> processSeats( List<MATCH_Matching_Seat__c> oldseats){
        List<MATCH_Matching_Seat__c> seats = new List<MATCH_Matching_Seat__c>();
        List<Apprenticeship__c> newEvents = this.internshipList;        
        List<MATCH_Matching_Seat__c> seatsNotMapped = seatsNotMapped( oldseats );
                
        if(seatsNotMapped!=null && seatsNotMapped.size()>0){          
            if( seatsNotMapped.size() == newEvents.size() ){
                for( integer i=0; i<newEvents.size(); i++ ) {
                    seats.add( getSeat(newEvents[i],seatsNotMapped[i],null) );   
                }
            }else if( seatsNotMapped.size() < newEvents.size() ){
                Integer newSeatCount = newEvents.size() - seatsNotMapped.size();
                Set<String> mappedSeats = new Set<String>();
                for(Apprenticeship__c newEvent: newEvents){  
                    mappedSeats.add(newEvent.Name);                  
                    for(integer i=0; i<seatsNotMapped.size()-newSeatCount; i++) {
                        seats.add(getSeat(newEvent,seatsNotMapped[i],null));
                    }
                }                             
                for(Apprenticeship__c newEvent: newEvents){  
                    if(mappedSeats.contains(newEvent.Name)) continue;                  
                    for(integer i=0; i<newSeatCount; i++) {
                        seats.add(getSeat(newEvent,null,oldseats.size()+i+1));
                    }
                } 
            } else if( seatsNotMapped.size() > newEvents.size() )
                for(integer i=0; i<newEvents.size(); i++) {
                    seats.add(getSeat(newEvents[i],seatsNotMapped[i],null));
                }
        }else{          
            for(integer i=0; i<newEvents.size(); i++) {
                seats.add(getSeat(newEvents[i],null,i+1)); 
            }
        }
        
        
        return seats;
    }
    
    private MATCH_Matching_Seat__c getSeat(Apprenticeship__c event, MATCH_Matching_Seat__c oldSeat, Integer seatNumber){       
        
        MATCH_Matching_Seat__c seat = new MATCH_Matching_Seat__c(); 
        if(oldSeat!=null) seat.id = oldSeat.id;  
        seat.ownerId = this.batchApexuser.Id;       
        if(seatNumber!=null) seat.seat_number__c = seatNumber;
        
        for(INT_to_Matching_Seat_Field_Mapping__mdt field:this.fieldMap.values()){
            if( this.dmlType == 'UPDATE')
                seat.put(field.Matching_Seat_Field_API__c, MATCH_Utilities.recursiveGet(event,field.Internship_Field__c));
            else if( MATCH_Utilities.recursiveGet(event,field.Internship_Field__c)!=null )
                seat.put(field.Matching_Seat_Field_API__c, MATCH_Utilities.recursiveGet(event,field.Internship_Field__c));
        }
        
        seat.Seat_Status__c ='INTERNSHIP_'+ this.dmlType;         
        
        return seat;
    }
    
    private static List<MATCH_Matching_Seat__c> seatsNotMapped( List<MATCH_Matching_Seat__c> oldseats ){
        List<MATCH_Matching_Seat__c> seats = new List<MATCH_Matching_Seat__c>();
        if(oldseats!=null && oldseats.size()>0) {
            for(MATCH_Matching_Seat__c oldSeat: oldseats) {              
                if(oldSeat.Is_Available__c == False || oldSeat.Internship_Id__c== null) {
                    seats.add(oldSeat);  
                }
            }
        }
        return seats;
    }
    
    private static String getQuery(){
        DescribeSObjectResult describeResult = MATCH_Matching_Seat__c.getSObjectType().getDescribe();      
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        Set<String> seatFields = new Set<String>{};
        for(Schema.SObjectField fieldApiName: fieldMap.values()) {
            seatFields.add(String.valueOf(fieldApiName)); 
        }        
        
        return ' SELECT ' + string.join (new List<String>(seatFields), ',') + ' FROM ' + describeResult.getName();
    }   
}