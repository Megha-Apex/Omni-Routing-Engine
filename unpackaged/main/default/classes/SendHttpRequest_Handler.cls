/**
* @author Tal Licht
* @date 2020-08-19
* @description New API applied with ‘POST’ functionality, for sending messages by SObject
 */
global class SendHttpRequest_Handler
{
    static Integer batchSize = 100;
    static Integer minimumSizeForBatch = 40;
    static public Map<string, GroupSetting> groupsSettingsMap;
    static private Map<Id,Outgoing_Message__c> outgoingMessageMap;
    public class GroupSetting{
        Integer groupSize {get; set;}
        String className {get; set;}
        public groupSetting(Integer groupSize, String className) {
            this.groupSize = groupSize;
            this.className = className;
        }
    }

    public static void afterInsert(List<Outgoing_Message__c> newObjs) {
        List<Outgoing_Message__c> ogmsList = new List<Outgoing_Message__c>();

        for (Outgoing_Message__c ogm : newObjs) {
            if (!ogm.IsMaster__c && ogm.Status__c == 'Queued') {
                ogmsList.add(ogm);
            }
        }

        if(ogmsList.size() == 0) {
            return;
        }

        SendHttpRequest_Helper.validateMessage(ogmsList);
        getSettings(ogmsList);
        sendMessages(ogmsList);
    }

    public static void afterUpdate(List<Outgoing_Message__c> newObjs, Map<Id, Outgoing_Message__c> oldMap){
        SendHttpRequest_Helper.validateMessage(newObjs);
        List<Outgoing_Message__c> outgoingMessageList = new List<Outgoing_Message__c>();
        for(Outgoing_Message__c outgoingMessage : newObjs) {
            Outgoing_Message__c oldMission = oldMap.get(outgoingMessage.Id);
            if(!outgoingMessage.IsMaster__c && oldMission.Status__c != 'Queued' && outgoingMessage.Status__c == 'Queued') {
                outgoingMessageList.add(outgoingMessage);
            }
        }

        if(outgoingMessageList.size() == 0) {
            return;
        }

        SendHttpRequest_Helper.validateMessage(outgoingMessageList);
        getSettings(outgoingMessageList);
        sendMessages(outgoingMessageList);
    }

    /**
     * @description Responsible for creating the callouts bulk
     * @param newObjs the list of new outgoing message objects
     * @param futureCall if this should be called in future call or not
     */
    public static void createBulkCallouts(List<Outgoing_Message__c> newObjs, Boolean futureCall) {
        List<Outgoing_Message__c> ogmsToCreate = new List<Outgoing_Message__c>();
        Map<string, List<Outgoing_Message__c>> groupMessagesMap = new Map<string, List<Outgoing_Message__c>>();
        Map<Set<Id>, Outgoing_Message__c> mapMasterAndOther = new Map<Set<Id>,Outgoing_Message__c>();

        if(groupsSettingsMap == null) {
            getSettings(newObjs);
        }

        outgoingMessageMap = new Map<Id,Outgoing_Message__c>([SELECT Id, IsMaster__c, Message_Type__c, Number_Of_Tries__c, RecordTypeId, URL__c, Method__c, Content_Type__c, URL_Parameters__c,
                File_Name__c, Body__c, Class_Name__c, Object_Id__c, Object_Type_Name__c, Additional_Headers__c, Param1__c, Param2__c, Group__c, Parent_Outgoing_Message__c, With_Authentication__c, Named_Credential_Key__c
        FROM Outgoing_Message__c
        WHERE Id IN: newObjs]);
        groupMessagesMap = createGroupsMapping(outgoingMessageMap.values(), groupMessagesMap);
        mapMasterAndOther = craeteMasterAndOtherMapPerGroupType(groupMessagesMap, mapMasterAndOther);

        // Get the list of all the master outgoing messages
        for (Set<Id> masterOgmChildren : mapMasterAndOther.keySet()) {
            Outgoing_Message__c outgoingMessage = mapMasterAndOther.get(masterOgmChildren);
            if (outgoingMessage.Id == null) {
                ogmsToCreate.add(outgoingMessage);
            }
        }

        // if it is future call we should insert the masters ogm before the callout
        if(futureCall && !ogmsToCreate.isEmpty()) {
            insert ogmsToCreate;
        }

        // Create call outs to the outgoing messages
        List<Outgoing_Message__c> childMessagesToUpdate = createCalloutForMessages(mapMasterAndOther, futureCall);

        // update all the other OGMs (OGMs without master)
        if(childMessagesToUpdate.size() > 0 && !childMessagesToUpdate.isEmpty()) {
            update childMessagesToUpdate;
        }

        // Insert master OGMs here only when it is batch
        if(!futureCall && !ogmsToCreate.isEmpty()) {
            insert ogmsToCreate;
        }

        // Update the master with its object id
        for(Outgoing_Message__c masterOgmToUpdate : ogmsToCreate){
            masterOgmToUpdate.Object_Id__c = masterOgmToUpdate.Id;
        }
        List<Database.SaveResult> resultList = Database.update(ogmsToCreate, false);
        handleUpdateErrors(resultList, ogmsToCreate);

        update updateChildAfterCallout(mapMasterAndOther);
    }

    /**
    * @description Responsible for handling errors in OGMs update and updating the relevant message with the error if there is one
    * @param resultList the list of results from OGMs update
    * @param masterOgmsToSend the list of the OGMs that should have been updated
    */
    static void handleUpdateErrors(List<Database.SaveResult> resultList, List<Outgoing_Message__c> masterOgmsToSend) {
        List<Outgoing_Message__c> errorsList = new List<Outgoing_Message__c>();
        for(Integer i=0 ; i<resultList.size() ; i++) {
            Database.SaveResult result = resultList[i];

            if(!result.success) {
                Outgoing_Message__c outgoingMessage = masterOgmsToSend[i];
                outgoingMessage.Status__c = 'Fail';
                outgoingMessage.Class_Name__c = 'JsonMessageCreator';

                for(Database.Error err : result.errors) {
                    outgoingMessage.Response_Body__c += err.message + ' \n';
                }

                errorsList.add(outgoingMessage);
            }
        }

        if(errorsList.size() > 0) {
            update errorsList;
        }
    }

    /**
    * @description Responsible for creating the OGM callout
    * @param outgoingMessage the OGMs to send
    * @param futureCall indicates whether the message should be sent in future call or not
    * @param childOgms set of ids of childrem messages if this is a master message, if it's a single message the id would be of the message itself
    */
    public static void createCallout(Outgoing_Message__c outgoingMessage, Boolean futureCall, Set<Id> childOgms) {
        Id outgoingMessageId = outgoingMessage.Id;
        string endpoint = outgoingMessage.URL__c;
        string method = outgoingMessage.Method__c;
        string contentType = outgoingMessage.Content_Type__c;
        string parameters = outgoingMessage.URL_Parameters__c;
        string fileName = outgoingMessage.File_Name__c;
        string additionalHeadersStr = outgoingMessage.Additional_Headers__c;

        Map<string,string> additionalHeaders = new Map<string,string>();
        if(!string.isEmpty(outgoingMessage.Additional_Headers__c)) {
            additionalHeaders = (Map<string,string>) JSON.deserialize(additionalHeadersStr, Map<string,string>.class);
        }

        if(futureCall) {
            SendHttpRequest_Helper.messageCalloutFuture(outgoingMessageId, endpoint, method, contentType, parameters, fileName, additionalHeaders, childOgms);
        }
        else {
            SendHttpRequest_Helper.messageCallout(outgoingMessage, endpoint, method, contentType, parameters, fileName, additionalHeaders, childOgms);
        }
    }

    /**
    * @description Responsible for getting the setting data from metadata
    */
    private static void getSettings(List<Outgoing_Message__c> ogmsList) {
        Set<String> objectsToQuery = new Set<String>();
        Set<String> groupsToQuery = new Set<String>();
        string groupTypeName = 'Other';
        Integer groupSize = 1;
        string groupClassName = null;
        groupsSettingsMap = new Map<String, GroupSetting>();

        for(Outgoing_Message__c ogm: ogmsList){
            objectsToQuery.add(ogm.Object_Type_Name__c);
            groupsToQuery.add(ogm.Group__c);
        }

        buildGroupsSettingsMap(groupSize, groupTypeName);
        Outgoing_Message_Settings__mdt settings = [SELECT Id, Batch_Size__c, Minimum_Size_For_Batch__c FROM Outgoing_Message_Settings__mdt WHERE DeveloperName =: 'Org_Defaults'];
        minimumSizeForBatch = Integer.valueOf(settings.Minimum_Size_For_Batch__c);
        batchSize = Integer.valueOf(settings.Batch_Size__c);
        if(settings!= null) {
            List<Group__mdt> groupSettings = [SELECT Group_Size__c, Object__r.ObjectName__c, DeveloperName FROM Group__mdt WHERE Object__r.ObjectName__c IN :objectsToQuery AND DeveloperName IN :groupsToQuery];
            for (Group__mdt groupset : groupSettings) {
                groupSize = groupset.Group_Size__c != null ? Integer.valueOf(groupset.Group_Size__c) : 1;
                groupTypeName = groupset.DeveloperName;
                groupClassName = groupset.Object__r.ObjectName__c;
                buildGroupsSettingsMap(groupSize, groupTypeName);
            }
        }
    }

    /**
    * @description Responsible for building the group settings map
    * @param groupSize the group size
    * @param groupClassName the group name
    */
    private static void buildGroupsSettingsMap(Integer groupSize, string groupClassName) {
        SendHttpRequest_Handler.GroupSetting groupSettingsClass = new SendHttpRequest_Handler.GroupSetting(groupSize, groupClassName);
        groupsSettingsMap.put(groupClassName, groupSettingsClass);
    }

    /**
    * @description Responsible for building the group settings map
    * @param mapMasterAndOther the map of masters which it's children should be sent and single messages
    * @param futureCall indicates whether the message should be sent in future call or not
    * @return List<Outgoing_Message__c> the list of OGMs which needs to be updated after the callout creation
    */
    private static List<Outgoing_Message__c> createCalloutForMessages(Map<Set<Id>, Outgoing_Message__c> mapMasterAndOther, boolean futureCall){
        List<Outgoing_Message__c> childMessagesToUpdate = new List<Outgoing_Message__c>();
        for (Set<Id> masterOgmChildren : mapMasterAndOther.keySet()) {
            Outgoing_Message__c outgoingMessage = mapMasterAndOther.get(masterOgmChildren);
            try {
                createCallout(outgoingMessage, futureCall, masterOgmChildren);
                if(!outgoingMessage.IsMaster__c) {
                    childMessagesToUpdate.add(outgoingMessage);
                }
            }
            catch (Exception ex) {
                outgoingMessage.Status__c = 'Fail';
                outgoingMessage.Response_Body__c = ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString();
            }
        }
        return  childMessagesToUpdate;
    }

    /**
    * @description Responsible for updating the child records and link them to the master
    * @param mapMasterAndOther the map of masters which it's children should be updated and linked
    * @return List<Outgoing_Message__c> the list of children messages linked to their master
    */
    private static List<Outgoing_Message__c> updateChildAfterCallout(Map<Set<Id>, Outgoing_Message__c> mapMasterAndOther){
        List<Outgoing_Message__c> childrenOgmsToUpdate = new List<Outgoing_Message__c>();
        for (Set<Id> childrenOutgoingMessageToUpdate: mapMasterAndOther.keySet()) {
            Outgoing_Message__c masterOutgoingMessage = mapMasterAndOther.get(childrenOutgoingMessageToUpdate);
            if (childrenOutgoingMessageToUpdate != null && masterOutgoingMessage.IsMaster__c) {
                for (Id childToUpdate : childrenOutgoingMessageToUpdate) {
                    Outgoing_Message__c updateChild = outgoingMessageMap.get(childToUpdate);
                    updateChild.Parent_Outgoing_Message__c = masterOutgoingMessage.Id;
                    updateChild.Status__c = masterOutgoingMessage.Status__c;
                    Decimal numOfTries = updateChild.Number_Of_Tries__c;
                    updateChild.Number_Of_Tries__c = numOfTries != null ? ++numOfTries : 0;
                    updateChild.Last_Try__c = Datetime.now();
                    childrenOgmsToUpdate.add(updateChild);
                }
            }
        }
        return childrenOgmsToUpdate;
    }

    /**
    * @description Responsible for creating groups map based on the group field on the OGM, if non is provided the message is added to a general group
    * @param outgoingMessageList list of all new or updated messages
    * @param groupMessagesMap the map of messages lists per group type
    * @return Map<string,List<Outgoing_Message__c>> the map of messages lists per group type
    */
    private static Map<string, List<Outgoing_Message__c>> createGroupsMapping(List<Outgoing_Message__c> outgoingMessageList, Map<string, List<Outgoing_Message__c>> groupMessagesMap){
        string groupType;
        for(Outgoing_Message__c outgoingMessage : outgoingMessageList){
            if(outgoingMessage.Group__c == null){
                groupType = 'Other';
            }
            else{
                groupType = outgoingMessage.Group__c;
            }
            List<Outgoing_Message__c > msgsListPerGroup = groupMessagesMap.get(groupType);
            if(msgsListPerGroup == null) {
                msgsListPerGroup = new List<Outgoing_Message__c>();
            }
            msgsListPerGroup.add(outgoingMessage);
            groupMessagesMap.put(groupType, msgsListPerGroup);
        }
        return groupMessagesMap;
    }

    /**
    * @description Responsible for deciding how to sending the messages
    * @param outgoingMessageList the list of messages to send
    */
    private static void sendMessages(List<Outgoing_Message__c> outgoingMessageList){
        if (system.isBatch()) {
            createBulkCallouts(outgoingMessageList, false);
        } else if ((Trigger.isInsert && outgoingMessageList.size() > minimumSizeForBatch)) {
            Database.executeBatch(new Outgoing_Message_Batch(outgoingMessageList), batchSize);
        } else {
            createBulkCallouts(outgoingMessageList, true);
        }
    }

    /**
    * @description Responsible for creating the master and single OGMs map per group type
    * @param groupMessagesMap the map of messages lists per group type
    * @param mapMasterAndOther the map of messages and their children ids set or single messages and their ids
    * @return Map<string,List<Outgoing_Message__c>> the map of messages and their children ids set or single messages and their ids
    */
    private static Map<Set<Id>,Outgoing_Message__c> craeteMasterAndOtherMapPerGroupType(Map<string, List<Outgoing_Message__c>> groupMessagesMap, Map<Set<Id>,Outgoing_Message__c> mapMasterAndOther){
        Integer count;
        Integer qty;
        Set<String> groupTypes = groupMessagesMap.keySet();
        for (String groupType : groupTypes) {
            List<Outgoing_Message__c> groupMessages = groupMessagesMap.get(groupType);
            qty = groupMessages.size();
            count = groupsSettingsMap.get(groupType).groupSize;
            mapMasterAndOther = createMasterAndOtherMap(groupType, count, qty, mapMasterAndOther, groupMessages);
        }
        return mapMasterAndOther;
    }

    /**
    * @description Responsible for adding the single OGMs to the map itself
    * @param groupType group type
    * @param count count of messages per group based on the group settings
    * @param qty qty of messages under the group type
    * @param mapMasterAndOther the map of messages and their children ids set or single messages and their ids
    * @param groupMessages list of messages for the group
    * @return Map<string,List<Outgoing_Message__c>> the map of messages and their children ids set or single messages and their ids
    */
    private static Map<Set<Id>,Outgoing_Message__c> createMasterAndOtherMap(String groupType, Integer count, Integer qty, Map<Set<Id>,Outgoing_Message__c> mapMasterAndOther, List<Outgoing_Message__c>  groupMessages){
        if (groupType == 'Other' || count == 1 || qty < count) { // we don't need to create masters
            for (Outgoing_Message__c msg : groupMessages) {
                Set<Id> singleOgmList = new Set<Id>();
                singleOgmList.add(msg.Id);
                mapMasterAndOther.put(singleOgmList, msg);
            }
        }
        else {
            mapMasterAndOther= createMastersForMap(groupType, count, qty, mapMasterAndOther, groupMessages);
        }
        return mapMasterAndOther;
    }

    /**
    * @description Responsible for adding the master OGMs to the map itself
    * @param groupType group type
    * @param count count of messages per group based on the group settings
    * @param qty qty of messages under the group type
    * @param mapMasterAndOther the map of messages and their children ids set or single messages and their ids
    * @param groupMessages list of messages for the group
    * @return Map<string,List<Outgoing_Message__c>> the map of messages and their children ids set or single messages and their ids
    */
    private static Map<Set<Id>,Outgoing_Message__c> createMastersForMap(String groupType, Integer count, Integer qty, Map<Set<Id>,Outgoing_Message__c> mapMasterAndOther, List<Outgoing_Message__c>  groupMessages){
        List<Outgoing_Message__c> masterOgmList = new List<Outgoing_Message__c>();
        for (Integer i = 0; i < Math.ceil(qty / count); i++) {
            masterOgmList.add(createMasterOgm(groupMessages, groupType));
        }
        // connect the children to the master
        mapMasterAndOther = linkChildrenToMaster(masterOgmList, count, mapMasterAndOther, groupMessages);
        // add the single OGMs not linked to master due to group size
        for (Integer i = masterOgmList.size() * count; i < groupMessages.size(); i++) {
            Set<Id> singleOgmList = new Set<Id>();
            singleOgmList.add(groupMessages[i].Id);
            mapMasterAndOther.put(singleOgmList, groupMessages[i]);
        }
        return mapMasterAndOther;
    }

    /**
    * @description Responsible for creating the master outgoing message itself
    * @param groupMessages list of child messages
    * @param groupType group type
    * @return Map<string,List<Outgoing_Message__c>> the map of messages and their children ids set or single messages and their ids
    */
    private static Outgoing_Message__c createMasterOgm(List<Outgoing_Message__c> groupMessages, String groupType){
        Outgoing_Message__c masterOgm = new Outgoing_Message__c();
        masterOgm.Message_Type__c = groupMessages[0].Message_Type__c;
        masterOgm.URL__c = groupMessages[0].URL__c;
        masterOgm.Method__c = groupMessages[0].Method__c;
        masterOgm.Additional_Headers__c = groupMessages[0].Additional_Headers__c;
        masterOgm.URL_Parameters__c = groupMessages[0].URL_Parameters__c;
        masterOgm.Content_Type__c = groupMessages[0].Content_Type__c;
        masterOgm.Object_Type_Name__c = 'Outgoing_Message__c';
        masterOgm.Class_Name__c = groupsSettingsMap.get(groupType).className;
        masterOgm.Number_Of_Tries__c = 0;
        masterOgm.IsMaster__c = true;
        return masterOgm;
    }

    /**
    * @description Responsible for linking the child messages to their master
    * @param masterOgmList list of master messages
    * @param count count of messages per group based on the group settings
    * @param mapMasterAndOther the map of messages and their children ids set or single messages and their ids
    * @param groupMessages list of messages for the group
    * @return Map<string,List<Outgoing_Message__c>> the map of messages and their children ids set or single messages and their ids
    */
    private static Map<Set<Id>,Outgoing_Message__c> linkChildrenToMaster(List<Outgoing_Message__c> masterOgmList, Integer count, Map<Set<Id>,Outgoing_Message__c> mapMasterAndOther, List<Outgoing_Message__c>  groupMessages){
        for (Integer i = 0 ; i < masterOgmList.size(); i++) {
            Set<Id> childrenOgmPerMasterList = new Set<Id>();
            for (Integer j = i * count; j <= (i * count + (count - 1)); j++) {
                childrenOgmPerMasterList.add(groupMessages[j].Id);
                if(groupMessages.size() < (i * count + (count - 1)) && count == (j-1)){
                    continue;
                }
            }
            mapMasterAndOther.put(childrenOgmPerMasterList, masterOgmList[i]);
        }
        return mapMasterAndOther;
    }
}