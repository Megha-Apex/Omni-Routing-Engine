/**
* @author Tal Licht
* @date 2020-08-19
* @description Message creator interface
*/
global interface MessageCreatorInterface {

    String createMessage(Id objId, String objType, Set<Id> childOgms, String param1, String param2);
    String createMessage(Outgoing_Message__c masterOgm, Set<Id> childOgms, String param1, String param2);
}