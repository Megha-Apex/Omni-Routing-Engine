trigger trac_ContentDocumentLink on ContentDocumentLink (after insert) {
    ContentDocumentLinkHelper.processAfterInsert(Trigger.newMap);
}