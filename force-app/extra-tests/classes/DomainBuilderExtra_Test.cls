@IsTest
private class DomainBuilderExtra_Test {
	// Note: the below test method would introduce dependancy on dummy apex class DebugDML
	@IsTest
	private static void happyPathWithDebugDML() {
		// Setup & Exercise
		Contact_t ron = new Contact_t().first('Ron').last('Harris');

		new Account_t()
			.name('Acme Corp')
			.add(ron)
			.add(new Opportunity_t().amount(1000).closes(2019, 12).contact(ron))
			.persist(new DebugDML());

		// Verify
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
		System.assertEquals(1, [SELECT COUNT() FROM Contact]);
		System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole]);
	}

	// Note: the below test method would introduce dependancy on dummy custom field MainContact__c
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
