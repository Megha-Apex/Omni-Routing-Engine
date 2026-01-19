/**
 * @author Daniel Segal
 * @date 2020-07-29
 * @description New API endpoint applied with ‘GET’ functionality, for retrieving requested records
 * by SObject and related Group
 */
@RestResource(UrlMapping = '/query/*/group/*')
global with sharing class QueryMessageAPI {
    static final Integer QUERY_LIMIT_NUMBER = 2000;

    public static String sObjectName;
    public static String groupName;
    public static Integer offset = 0;
    public static Id lastId;
    public static String countQuery;
    public static Integer groupSize = QUERY_LIMIT_NUMBER;

    @HttpGet
    global static void HttpGet() {
        RestRequest restRequest = RestContext.request;
        sObjectName = APIUtils.getUrlParamByKey(restRequest.requestURI, 'query');
        groupName = APIUtils.getUrlParamByKey(restRequest.requestURI, 'group');
        String offsetString = APIUtils.getUrlParamByKey(restRequest.requestURI, 'offset');

        if(!String.isEmpty(offsetString)) {
            List<String> offsetParams = offsetString.split('-');
            lastId = Id.valueOf(offsetParams[0]);
            offset = Integer.valueOf(offsetParams[1]);
        }

        queryHandler();
    }

    /**
     * @description Responsible of all query logic.
     */
    public static void queryHandler() {
        try {
            validateParams();
            String query = queryAssembler();
            String nextRecordsUrl;
            Integer totalSize;
            Boolean done = false;
            if (String.isBlank(query)) {
                throw new APIExceptions.InvalidInputException(new APIExceptions.Error('query', 'Metadata was not configured correctly'));
            }
            List<sObject> sObjects = Database.query(query);
            totalSize = Database.countQuery(countQuery);
            if (offset + sObjects.size() == totalSize) {
                done = true;
            }
            else {
                lastId = sObjects[sObjects.size()-1].Id;
                nextRecordsUrl = urlAssembler();
            }
            QueryObject queryObject = new QueryObject(sObjects, nextRecordsUrl, done, totalSize);
            String responseJson = JSON.serialize(queryObject, true);
            APIUtils.responseMessage(responseJson, 200);


        }
        catch(APIExceptions.InvalidInputException e) {
            APIUtils.handleError(e.errors, 404);
        }
    }

    /**
     * @description Checks that the SObject and Group are specified and valid.
     * @return Throws a suitable exception, according to validation
     */
    private static void validateParams() {
        if (String.isBlank(sObjectName)) {
            throw new APIExceptions.InvalidInputException(new APIExceptions.Error('query', 'SObject was not specified'));
        }
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            throw new APIExceptions.InvalidInputException(new APIExceptions.Error('query', 'SObject specified does not exists'));
        }
        if (String.isBlank(groupName)) {
            throw new APIExceptions.InvalidInputException(new APIExceptions.Error('group', 'Group was not specified'));
        }
    }

    /**
     * @description Responsible of assembling the query according to the
     * specified SObject & Group.
     * @return Query string
     */
    private static String queryAssembler() {
        String query='';
        String uniqueGroupName = groupName;
        List<Group__mdt> groups = [SELECT Id, DeveloperName, SelectFields__c, WhereClause__c, Group_Size_Inbound__c FROM Group__mdt WHERE DeveloperName = :uniqueGroupName AND Object__r.ObjectName__c = :sObjectName];

        if (groups.isEmpty()) {
            throw new APIExceptions.InvalidInputException(new APIExceptions.Error('group', 'Group does not exists'));
        }

        Group__mdt gr = groups.get(0);

        // Get selected fields
        if(gr.Group_Size_Inbound__c != null) {
            groupSize = Integer.valueOf(gr.Group_Size_Inbound__c);
        }

        // Get selected fields
        String fields = gr.SelectFields__c;
        if (String.isBlank(fields)) {
            fields = 'Id';
        }

        // Get where clause
        List<String> conditionList = new List<String>();
        String groupCondition = gr.WhereClause__c;
        if(!String.isEmpty(groupCondition)) {
            conditionList.add(groupCondition);
        }

        // set offset
        if(offset != 0) {
            conditionList.add('Id >: lastId');
        }

        // Build where statement
        String allConditions = '';
        if(!conditionList.isEmpty()) {
            allConditions = ' WHERE ' + String.join(conditionList, ' AND ');
        }

        countQuery = String.isBlank(groupCondition) ?  'SELECT COUNT() FROM ' + sObjectName : 'SELECT COUNT() FROM ' + sObjectName + ' WHERE ' + groupCondition;

        query = 'SELECT ' + fields + ' FROM ' + sObjectName + allConditions + ' ORDER BY Id LIMIT ' + groupSize;

        System.debug('query: ' + query);
        return query;
    }

    /**
     * @description Responsible of assembling the url according to the offset
     * @param sObjects the list of queried records
     * @return URL string representation
     */
    public static String urlAssembler() {
        return  '/services/apexrest/query/' + sObjectName + '/group/' + groupName + '/offset/' + lastId+'-'+String.valueOf(offset + groupSize);
    }
}