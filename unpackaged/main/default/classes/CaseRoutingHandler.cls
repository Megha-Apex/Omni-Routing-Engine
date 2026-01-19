public class CaseRoutingHandler {
    
    // Recursion guard
    public static Boolean isFirstRun = true;
    
    public static void processAndRoute(List<Case> newCases, Map<Id, Case> oldMap) {
        
        if (!isFirstRun) return;
        isFirstRun = false;
        
        if (newCases == null || newCases.isEmpty()) return;
        
        try {
            // Collect case Ids
            Set<Id> caseIds = new Set<Id>();
            for (Case c : newCases) {
                caseIds.add(c.Id);
            }
            
            // Get active routing groups + child rules, sorted by priority (lowest number = highest priority)
            List<Routing_Rule_Group__c> ruleGroups = [
                SELECT Id, Name, Logic_Type__c, Priority__c,
                    (SELECT Id, Name, Criteria__c, Operator__c, Value__c, Domain__c,
                            Queue_Type__c, SubCustomer__c, SubCustomer__r.Name,
                            Active__c, Routing_Rule_Group__c
                     FROM Routing_Rules__r
                     WHERE Active__c = TRUE
                     ORDER BY Priority__c ASC NULLS LAST)
                FROM Routing_Rule_Group__c
                WHERE Active__c = TRUE
                ORDER BY Priority__c ASC NULLS LAST
            ];
            
            // Get related Email Messages
            Map<Id, List<EmailMessage>> caseEmailMap = new Map<Id, List<EmailMessage>>();
            for (EmailMessage em : [
                SELECT Id, ParentId, FromAddress, ToAddress, CcAddress, 
                       Subject, TextBody, HtmlBody, Headers
                FROM EmailMessage
                WHERE ParentId IN :caseIds
                ORDER BY CreatedDate DESC
            ]) {
                if (!caseEmailMap.containsKey(em.ParentId)) {
                    caseEmailMap.put(em.ParentId, new List<EmailMessage>());
                }
                caseEmailMap.get(em.ParentId).add(em);
            }
            
            List<Case> casesToUpdate = new List<Case>();
            
            for (Case c : newCases) {
                
                Boolean matchFound = false;
                Set<String> matchedKeywords  = new Set<String>();
                Set<String> matchedRuleNames = new Set<String>();
                Set<String> matchedQueues    = new Set<String>();
                Set<String> matchedRuleLinks = new Set<String>();
                
                String determinedQueueType = null;
                Id matchedSubCustomerId = null;
                String matchedSubCustomerName = null;
                
                List<EmailMessage> caseEmails = caseEmailMap.get(c.Id) != null 
                    ? caseEmailMap.get(c.Id) 
                    : new List<EmailMessage>();
                
                // Evaluate groups in priority order
                for (Routing_Rule_Group__c groupRule : ruleGroups) {
                    
                    if (groupRule.Routing_Rules__r == null || groupRule.Routing_Rules__r.isEmpty()) {
                        continue;
                    }
                    
                    Boolean groupMatched = false;
                    Set<String> tempKeywords = new Set<String>();
                    List<String> groupMatchedRuleLinks = new List<String>();
                    
                    String logicType = String.isBlank(groupRule.Logic_Type__c) 
                        ? 'AND' 
                        : groupRule.Logic_Type__c.trim().toUpperCase();
                    
                    if (logicType == 'OR') {
                        // OR logic: at least one rule must match
                        for (Routing_Rule__c rule : groupRule.Routing_Rules__r) {
                            if (evaluateRule(rule, c, caseEmails)) {
                                groupMatched = true;
                                
                                if (String.isNotBlank(rule.Value__c)) tempKeywords.add(rule.Value__c);
                                if (String.isNotBlank(rule.Domain__c)) tempKeywords.add(rule.Domain__c);
                                
                                groupMatchedRuleLinks.add('<a href="/' + rule.Id + '">' + rule.Name + '</a>');
                                
                                if (String.isNotBlank(rule.Queue_Type__c)) {
                                    matchedQueues.add(rule.Queue_Type__c);
                                    determinedQueueType = rule.Queue_Type__c;
                                }
                                if (rule.SubCustomer__c != null) {
                                    matchedSubCustomerId = rule.SubCustomer__c;
                                    matchedSubCustomerName = rule.SubCustomer__r?.Name;
                                }
                            }
                        }
                    } else {
                        // AND logic: all rules must match
                        groupMatched = true;
                        for (Routing_Rule__c rule : groupRule.Routing_Rules__r) {
                            if (!evaluateRule(rule, c, caseEmails)) {
                                groupMatched = false;
                                break;
                            }
                            
                            if (String.isNotBlank(rule.Value__c)) tempKeywords.add(rule.Value__c);
                            if (String.isNotBlank(rule.Domain__c)) tempKeywords.add(rule.Domain__c);
                            
                            groupMatchedRuleLinks.add('<a href="/' + rule.Id + '">' + rule.Name + '</a>');
                            
                            if (String.isNotBlank(rule.Queue_Type__c)) {
                                matchedQueues.add(rule.Queue_Type__c);
                                determinedQueueType = rule.Queue_Type__c;
                            }
                            if (rule.SubCustomer__c != null) {
                                matchedSubCustomerId = rule.SubCustomer__c;
                                matchedSubCustomerName = rule.SubCustomer__r?.Name;
                            }
                        }
                    }
                    
                    // If this group matched → take its results and STOP (highest priority wins)
                    if (groupMatched) {
                        matchFound = true;
                        matchedKeywords.addAll(tempKeywords);
                        matchedRuleNames.add(groupRule.Name);
                        matchedRuleLinks.addAll(groupMatchedRuleLinks);
                        
                        // Break here - we take the first (highest priority) matching group
                        break;
                    }
                }
                
                // Prepare update
                Case caseUpdate = new Case(Id = c.Id);
                Boolean hasChanges = false;
                
                if (c.Match_Found__c != matchFound) {
                    caseUpdate.Match_Found__c = matchFound;
                    hasChanges = true;
                }
                
                String keywordsText = matchedKeywords.isEmpty() ? 'No Keyword Found' 
                                    : String.join(new List<String>(matchedKeywords), ', ');
                if (c.Keywords_Found__c != keywordsText) {
                    caseUpdate.Keywords_Found__c = keywordsText;
                    hasChanges = true;
                }
                
                String rulesText = String.join(new List<String>(matchedRuleNames), ', ');
                if (rulesText.length() > 255) rulesText = rulesText.substring(0, 255);
                if (c.Rule_Found__c != rulesText) {
                    caseUpdate.Rule_Found__c = rulesText;
                    hasChanges = true;
                }
                
                String linksText = String.join(new List<String>(matchedRuleLinks), ' | ');
                if (c.Routing_Rule_Link__c != linksText) {
                    caseUpdate.Routing_Rule_Link__c = linksText;
                    hasChanges = true;
                }
                
                String queuesText = String.join(new List<String>(matchedQueues), ', ');
                if (c.Matched_Queues__c != queuesText) {
                    caseUpdate.Matched_Queues__c = queuesText;
                    hasChanges = true;
                }
                
                if (determinedQueueType != null && c.Queue_Type__c != determinedQueueType) {
                    caseUpdate.Queue_Type__c = determinedQueueType;
                    hasChanges = true;
                }
                
                // Sub-customer logic
                if (matchedSubCustomerId != null && String.isNotBlank(matchedSubCustomerName)) {
                    if (c.SubCustomer_Name__c != matchedSubCustomerName) {
                        caseUpdate.SubCustomer_Name__c = matchedSubCustomerName;
                        hasChanges = true;
                    }
                    
                    if (c.AccountId == null) {
                        caseUpdate.AccountId = matchedSubCustomerId;
                        caseUpdate.SubCustomer_Match__c = true;
                        hasChanges = true;
                    } else if (c.AccountId == matchedSubCustomerId) {
                        if (c.SubCustomer_Match__c != true) {
                            caseUpdate.SubCustomer_Match__c = true;
                            hasChanges = true;
                        }
                    } else {
                        if (c.SubCustomer_Match__c != false) {
                            caseUpdate.SubCustomer_Match__c = false;
                            hasChanges = true;
                        }
                    }
                }
                
                if (hasChanges) {
                    casesToUpdate.add(caseUpdate);
                }
            }
            
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
            
        } catch (Exception e) {
            System.debug('Routing Handler Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    // Case-insensitive rule evaluation
    private static Boolean evaluateRule(Routing_Rule__c rule, Case c, List<EmailMessage> emails) {
        if (rule == null) return false;
        
        String criteria = rule.Criteria__c;
        String operator = rule.Operator__c;
        String value = rule.Value__c != null ? rule.Value__c.toLowerCase() : '';
        String domainValue = rule.Domain__c != null ? rule.Domain__c.toLowerCase() : '';
        
        List<String> textsToCheck = new List<String>();
        
        if (criteria == 'Subject') {
            if (c.Subject != null) textsToCheck.add(c.Subject);
            for (EmailMessage em : emails) if (em.Subject != null) textsToCheck.add(em.Subject);
        }
        else if (criteria == 'From Address') {
            if (c.SuppliedEmail != null) textsToCheck.add(c.SuppliedEmail);
            for (EmailMessage em : emails) if (em.FromAddress != null) textsToCheck.add(em.FromAddress);
        }
        else if (criteria == 'To Address') {
            for (EmailMessage em : emails) if (em.ToAddress != null) textsToCheck.add(em.ToAddress);
        }
        else if (criteria == 'CC Address') {
            for (EmailMessage em : emails) if (em.CcAddress != null) textsToCheck.add(em.CcAddress);
        }
        else if (criteria == 'Text Body' || criteria == 'Body') {
            if (c.Description != null) textsToCheck.add(c.Description);
            for (EmailMessage em : emails) if (em.TextBody != null) textsToCheck.add(em.TextBody);
        }
        else if (criteria == 'Domain') {
            if (c.SuppliedEmail != null) textsToCheck.add(parseDomain(c.SuppliedEmail));
            for (EmailMessage em : emails) if (em.FromAddress != null) textsToCheck.add(parseDomain(em.FromAddress));
            value = domainValue;
        }
        
        for (String text : textsToCheck) {
            if (String.isBlank(text)) continue;
            String lowerText = text.toLowerCase().trim();
            
            if (operator == 'Equals')              { if (lowerText == value) return true; }
            else if (operator == 'Not Equal To')   { if (lowerText != value) return true; }
            else if (operator == 'Contains')       { if (lowerText.contains(value)) return true; }
            else if (operator == 'Does Not Contain'){ if (!lowerText.contains(value)) return true; }
            else if (operator == 'Starts With')    { if (lowerText.startsWith(value)) return true; }
            else if (operator == 'Ends With')      { if (lowerText.endsWith(value)) return true; }
        }
        
        return false;
    }
    
    private static String parseDomain(String email) {
        if (String.isBlank(email) || !email.contains('@')) return '';
        return email.substringAfter('@').toLowerCase().trim();
    }
}