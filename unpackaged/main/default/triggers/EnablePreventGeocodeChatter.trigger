trigger EnablePreventGeocodeChatter on ServiceAppointment (before insert) {
    for (ServiceAppointment obj : Trigger.new) {
        // Check if all geolocation fields and assigned technician are populated
        if (obj.GeocodeAccuracy == null && 
            obj.FSL__InternalSLRGeolocation__Latitude__s == null && 
            obj.FSL__InternalSLRGeolocation__Longitude__s == null &&
            obj.Assigned_Technician__c == null) {
            // Enable the "FSL Prevent Geocoding For Chatter Actions" field
            obj.FSL__Prevent_Geocoding_For_Chatter_Actions__c = true;
        }
    }
}