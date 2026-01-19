@IsTest
public class PopulateServiceTerritoryTest {
    
    private static ServiceResource createTestResource() {
        Profile p = [SELECT Id FROM Profile WHERE Name='FSL System Admin'];
        User u = new User(
            Alias = 'tstu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser890@example.com'
        );
        insert u;

        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = u.Id,
            Alt_Phone__c = '19991234567',
            MobilePhone__c = '18881234567'
        );
        insert sr;
        return sr;
    }
    
   /* @IsTest(SeeAllData=true)
    static void testPopulateServiceTerritory() {
        ServiceResource sr = createTestResource();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE IsActive = true LIMIT 1];
        
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'P',
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
        
        Test.startTest();
        ResourceAbsence ra = new ResourceAbsence(
            ResourceId = sr.Id,
            Start = DateTime.now(),
            End = DateTime.now().addHours(5)
        );
        insert ra;
        Test.stopTest();
        
        ra = [SELECT Id, Service_Territory__c FROM ResourceAbsence WHERE Id = :ra.Id];
        System.assertEquals(st.Id, ra.Service_Territory__c, 'Service Territory should be populated');
    }*/
    
 /*   @IsTest(SeeAllData=true)
    static void testPopulateServiceTerritoryUpdate() {
        ServiceResource sr = createTestResource();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE IsActive = true LIMIT 1];
        
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'P',
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
        
        ResourceAbsence ra = new ResourceAbsence(
            ResourceId = sr.Id,
            Start = DateTime.now(),
            End = DateTime.now().addHours(1)
        );
        insert ra;
        
        Test.startTest();
        ra.End = DateTime.now().addHours(2);
        update ra;
        Test.stopTest();
        
        ra = [SELECT Id, Service_Territory__c FROM ResourceAbsence WHERE Id = :ra.Id];
        System.assertNotEquals(null, ra.Service_Territory__c, 'Service Territory should still be populated after update');
    }*/
    
 /*   @IsTest
    static void testNoServiceTerritoryMember() {
        ServiceResource sr = createTestResource();
        
        Test.startTest();
        ResourceAbsence ra = new ResourceAbsence(
            ResourceId = sr.Id,
            Start = DateTime.now(),
            End = DateTime.now().addHours(5)
        );
        insert ra;
        Test.stopTest();
        
        ra = [SELECT Id, Service_Territory__c FROM ResourceAbsence WHERE Id = :ra.Id];
        System.assertEquals(null, ra.Service_Territory__c, 'Service Territory should not be populated');
    }*/
    
    @IsTest(SeeAllData=true)
    static void testNonPrimaryServiceTerritoryMember() {
        ServiceResource sr = createTestResource();
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE IsActive=true LIMIT 1];
        
        ServiceTerritoryMember stmNonPrimary = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'S', // Non-primary territory type
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stmNonPrimary;

        Test.startTest();
        ResourceAbsence raNonPrimary = new ResourceAbsence(
            ResourceId = sr.Id,
            Start = DateTime.now(),
            End = DateTime.now().addHours(1)
        );
        insert raNonPrimary;
        Test.stopTest();

        raNonPrimary = [SELECT Id, Service_Territory__c FROM ResourceAbsence WHERE Id = :raNonPrimary.Id];
        System.assertEquals(null, raNonPrimary.Service_Territory__c, 'Service Territory should not be populated for non-primary STM');
    }
}