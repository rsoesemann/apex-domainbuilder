@IsTest
private class DomainBuilderExtra_Test {
	@IsTest
	private static void doesntAllowCircularRelations() {
		// Setup & Exercise
		Contact_t c = new Contact_t();

		((AccountExtra_t) new AccountExtra_t().add(c)).contact(c).persist();

		// Verify
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE MainContact__c != NULL]);
		System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE AccountId != NULL]);
	}
}
