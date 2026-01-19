/**
* @author Tal Licht
* @date 2020-08-19
* @description JSON creator for the message body
*/
global with sharing class JsonMessageCreator implements MessageCreatorInterface{

    public String createMessage(Outgoing_Message__c masterOgm, Set<Id> childOgms, String groupName, String param2) {
        Id objId = masterOgm.Id;
        return serializeMessage(objId, objId.getSObjectType().getDescribe().getName(), groupName);
    }

    public String createMessage(Id objId, String objType, Set<Id> childOgms, String groupName, String param2) {
        return serializeMessage(objId, objType, groupName);
    }

    public String serializeMessage(Id objId, String objType, String groupName) {
        String fieldsToQuery = String.valueOf([SELECT SelectFields__c FROM Group__mdt WHERE Object__r.ObjectName__c = :objType AND DeveloperName = :groupName][0].SelectFields__c );
        String q = 'SELECT ' + fieldsToQuery + ' FROM ' + objType + ' WHERE id = \'' + objId + '\'';
        List<SObject> sobjList = Database.query(q);
        if (sobjList.size() > 0) {
            return JSON.serialize(sobjList.get(0));
        }
        return null;
    }
}