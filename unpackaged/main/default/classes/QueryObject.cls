/**
 * @author Daniel Segal
 * @date 2020-07-30
 * @description Wrapper class for the Query API response
 */
public with sharing class QueryObject {
    public Integer totalSize;
    public String nextRecordsUrl;
    public List<SObject> records;
    public Boolean done;

    public QueryObject(List<SObject> records, String nextRecordsUrl, Boolean done, Integer totalSize) {
        this.totalSize = totalSize;
        this.nextRecordsUrl = nextRecordsUrl;
        this.records = records;
        this.done = done;

    }

}