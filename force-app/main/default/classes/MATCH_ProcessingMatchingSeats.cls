public class MATCH_ProcessingMatchingSeats {
    public List<Internship_Work_Site__c> newList ;  
    public string dmlType{get; set;}
    
    public MATCH_ProcessingMatchingSeats(List<Internship_Work_Site__ChangeEvent> iwsRecords, List<Apprenticeship__ChangeEvent> intRecords){  
        Set<String> iwsids=new Set<String>();
        
        for (Internship_Work_Site__ChangeEvent change : iwsRecords) { 
            this.dmlType = change.ChangeEventHeader.getchangeType();          
            iwsids.addAll(change.ChangeEventHeader.getRecordIds());
        }    
        
        this.newList = new List<Internship_Work_Site__c>(getIWSRecords(iwsIds)); 
       
        // Process Seat records from IWSs
        new MATCH_Utilities()
            .upsertDML(new List<MATCH_Matching_Seat__c>(processMatchingSeats()));
        
        // Process Seat records from Internships
        if(intRecords.size()>0) {
            new MATCH_ProcessingMatchingSeatsInternship(intRecords);
        }
    } 
    
    // This is from Opportunity
    public MATCH_ProcessingMatchingSeats(Set<String> iwsids){ 
        this.dmlType = 'UPDATE';
        this.newList = new List<Internship_Work_Site__c>(getIWSRecords(iwsIds)); 
        new MATCH_Utilities().upsertDML(new List<MATCH_Matching_Seat__c>(processMatchingSeats())); 
    }
    
    private MATCH_Matching_Seat__c getSeat(Internship_Work_Site__c iws, List<IWS_to_Matching_Seat_Field_Mapping__mdt> fieldList, String batchApexuserId, Integer seatNumber){    
        
        MATCH_Matching_Seat__c seat = new MATCH_Matching_Seat__c();
        seat.Seat_Status__c = 'IWS_'+this.dmlType;
        seat.ownerId = batchApexuserId;       
        if(seatNumber!=null) seat.seat_number__c = seatNumber;
        
        for(IWS_to_Matching_Seat_Field_Mapping__mdt field:fieldList){
            if(iws.Stage__c=='Seats Confirmed' && isSurveyField(field.IWS_Field_API__c)){
                seat.put(field.Matching_Seat_Field_API__c, MATCH_Utilities.recursiveGet(iws,field.IWS_Field_API__c)); 
            }else{
                seat.put(field.Matching_Seat_Field_API__c, MATCH_Utilities.recursiveGet(iws,field.IWS_Field_API__c)); 
            }                  
        }        
        
        return seat;
    }
    
    private static boolean isSurveyField(String field){
        if(field.contains('.')) {
            Integer firstPeriod = field.indexOf('.');
            String nextObjectName = field.subString(0, firstPeriod);
            
            if(nextObjectName == 'Seat_Survey_Result__r') {
                return true;
            } 
        }
        
        return false;
    }
    
    private List<MATCH_Matching_Seat__c> processMatchingSeats(){    
        List<IWS_to_Matching_Seat_Field_Mapping__mdt> fieldList= IWS_to_Matching_Seat_Field_Mapping__mdt.getAll().values();
        List<MATCH_Matching_Seat__c> seatstobeUpserted = new List<MATCH_Matching_Seat__c>();
        Map<String,List<MATCH_Matching_Seat__c>> seatsByIWS = matchingSeatsByIWS();
        String batchApexuser = MATCH_Utilities.getUser()?.Id; 
        
        for(Internship_Work_Site__c iws:this.newList){
            
            //No records found, create Seat Records
            if( !seatsByIWS.containsKey(iws.id) ){
                for(integer i=0; i<iws.SeatsConfirmed__c; i++){
                    seatstobeUpserted.add(getSeat(iws,fieldList,batchApexuser,i+1));
                }
                
            }else{
                List<MATCH_Matching_Seat__c> oldSeats = seatsByIWS.get(iws.id);
                // if seat count same as IWS seat count update the records
                if( oldSeats.size() == iws.SeatsConfirmed__c ){  
                    for(MATCH_Matching_Seat__c oldSeat: oldSeats) {
                        MATCH_Matching_Seat__c seat = getSeat(iws,fieldList,batchApexuser,null);
                        seat.id = oldSeat.id;
                        seatstobeUpserted.add( seat );
                    } 
                // if Seat records for the IWS is less than IWS seat count, then create new seats.
                }else if( oldSeats.size() < iws.SeatsConfirmed__c ){
                    Integer newSeatsCount =  Integer.valueOf(iws.SeatsConfirmed__c - oldSeats.size());
                    Integer counter = oldSeats.size();
                    
                    for(integer i=0; i<newSeatsCount; i++){
                        seatstobeUpserted.add(getSeat(iws,fieldList,batchApexuser, oldSeats.size()+1));                    
                        counter++;
                    }
                    
                    for(MATCH_Matching_Seat__c oldSeat: oldSeats) {
                        MATCH_Matching_Seat__c seat = getSeat(iws,fieldList,batchApexuser,null);
                        seat.id = oldSeat.id;
                        seatstobeUpserted.add( seat );
                    } 
                // if Seat records for the IWS is more than IWS seat count, then mark them as Seat lost.
                }else if ( oldSeats.size() > iws.SeatsConfirmed__c ){
                    
                    Integer seatsLostCount = Integer.valueOf( oldSeats.size() - iws.SeatsConfirmed__c );
                    
                    for( integer i=0; i<oldSeats.size(); i++ ){                    
                        MATCH_Matching_Seat__c seat = getSeat(iws,fieldList,batchApexuser,null);
                        seat.id = oldSeats[i].id;
                        
                        if( i+1 > iws.SeatsConfirmed__c ) {
                            seat.Seat_Status__c ='IWS_SEAT_LOST';
                        }
                        
                        seatstobeUpserted.add( seat );
                    } 
                    
                }            
            }            
        }
        
        return seatstobeUpserted;
    }
    
    private Map<String,List<MATCH_Matching_Seat__c>> matchingSeatsByIWS(){        
        Map<String,List<MATCH_Matching_Seat__c>> seatsByIWS = new Map<String,List<MATCH_Matching_Seat__c>>();  
        
        for( MATCH_Matching_Seat__c seat: getSeatRecords('MATCH_Matching_Seat__c', 'IWS_SeatsMap') ){           
            if( !seatsByIWS.containsKey(seat.IWS_Salesforce_ID__c) )
                seatsByIWS.put(seat.IWS_Salesforce_ID__c,new List<MATCH_Matching_Seat__c>{ seat });
            else
                seatsByIWS.get(seat.IWS_Salesforce_ID__c).add( seat );
        }
        
        return seatsByIWS;  
    }
    
    
    public List<Internship_Work_Site__c> getIWSRecords(Set<String> iwsIds){
        String query ='SELECT '+ String.escapeSingleQuotes(getIWSFields())+' FROM Internship_Work_Site__c WHERE Site_Located__r.MATCH_Matching_Pilot_Site__c=TRUE AND Probability__c>=75 AND Id IN:iwsIds';
        return Database.query(query);
    }
    
    private static String getIWSFields(){
        Map<String,IWS_to_Matching_Seat_Field_Mapping__mdt> iwsSeatFieldMapping = IWS_to_Matching_Seat_Field_Mapping__mdt.getAll();
        Set<String> fields = new Set<String>();
        for(IWS_to_Matching_Seat_Field_Mapping__mdt mapField:iwsSeatFieldMapping.values()){
            fields.add(mapField.IWS_Field_API__c);
        }  
        
        return String.join(new List<String>(fields), ',');
    }
    
    public MATCH_Matching_Seat__c[] getSeatRecords(String fsObject, String fsName) {
        Set<Id> iwsids = new Map<Id,Internship_Work_Site__c>(this.newList).keySet();
        String query ='SELECT '+ String.escapeSingleQuotes(getSeatFields())+' FROM MATCH_Matching_Seat__c WHERE IWS_Salesforce_ID__c IN:iwsIds ORDER BY IWS_Salesforce_ID__c DESC';        
        return Database.query(query);
    }
    
    private static String getSeatFields(){
        Map<String,IWS_to_Matching_Seat_Field_Mapping__mdt> iwsSeatFieldMapping = IWS_to_Matching_Seat_Field_Mapping__mdt.getAll();
        Set<String> fields = new Set<String>();
        for(IWS_to_Matching_Seat_Field_Mapping__mdt mapField:iwsSeatFieldMapping.values()){
            fields.add(mapField.Matching_Seat_Field_API__c);
        }   
        
        return String.join(new List<String>(fields), ',');
    }
    
}