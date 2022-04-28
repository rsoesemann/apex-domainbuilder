@IsTest
private class DomainBuilder_Test {
	@IsTest
	private static void noUnneededRecords() {
		// Setup & Exercise
		Contact_t con = new Contact_t(); // 1x insert
		Opportunity_t opp = new Opportunity_t(); // 1x insert

		new Account_t() // 1x insert
			.add(new Contact_t()) // 1x insert
			.add(con) // 0x insert
			.add(
				opp // 0x insert
					.add(con) // 1x insert OpportunityContactRole
			)
			.persist(); // 1x setSavepoint

		// Verify
		System.assertEquals(6, Limits.getDmlRows());
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
		System.assertEquals(2, [SELECT COUNT() FROM Contact]);
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
		System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole]);
	}

	@IsTest
	private static void happyPath() {
		// Setup & Exercise
		Contact_t ron = new Contact_t().first('Ron').last('Harris');

		new Account_t()
			.name('Acme Corp')
			.add(ron) // .add( new Contact_t() )
			.add(new Opportunity_t().amount(1000).closes(2019, 12).contact(ron))
			.persist();

		// Verify
		// Note: below commented assert is wrong, because when persisting Contact_t ron, the default Contact_t constructor also creates one Account_t, and since we are not adding it as a child of Acme Corp, they default account is created as well
		// Note: should really Contact_t have a default parent Account? It can be an independant entity itself
		// System.assertEquals(2, [SELECT Count() FROM Account]); // TODO: Should be 1 actually.
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
		// Note: below commented assert is no longer true since we are adding ron in Account_t rather than creating a new Contact_t
		// System.assertEquals(2, [SELECT Count() FROM Contact]);
		System.assertEquals(1, [SELECT COUNT() FROM Contact]);
		System.assertEquals(1, [SELECT COUNT() FROM OpportunityContactRole]);
	}

	@IsTest
	private static void autoPopulatesRequiredButIrrelevantFields() {
		// Setup & Exercise
		new Account_t().add(new Contact_t()).add(new Opportunity_t()).persist();

		// Verify
		System.assertNotEquals(null, [SELECT Name FROM Account]);
		System.assertNotEquals(null, [SELECT LastName FROM Contact]);
		System.assertNotEquals(null, [SELECT StageName FROM Opportunity]);
	}

	@IsTest
	private static void autoGeneratesRequiredButIrrelevantRelations() {
		// Setup & Exercise
		new Opportunity_t().amount(1000).persist();

		// Verify
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
		System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
		System.assertNotEquals(null, [SELECT AccountId FROM Opportunity]);
	}

	@IsTest
	private static void allowNicerFieldSetters() {
		// Setup & Exercise
		new Opportunity_t().closes(2019, 7).persist();

		// Verify
		System.assertEquals(Date.newInstance(2019, 7, 1), [SELECT CloseDate FROM Opportunity].CloseDate);
	}

	@IsTest
	private static void addChildrenOfArbitraryDepth() {
		// Setup & Exercise
		new Account_t()
			.add(new Contact_t())
			.add(new Contact_t())
			.add(new Opportunity_t())
			.add(new Opportunity_t())
			.persist();

		// Verify
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
		System.assertEquals(2, [SELECT COUNT() FROM Opportunity]);
		System.assertEquals(2, [SELECT COUNT() FROM Contact]);
	}

	@IsTest
	private static void allowsSetupObjects() {
		// Setup & Exercise
		try {
			System.runAs(User_t.standard()) {
				new Account_t().persist();
			}
		} catch (Exception ex) {
			System.assert(false);
		}

		// Verify
		System.assertEquals(1, [SELECT COUNT() FROM Account]);
	}

	@IsTest
	private static void allowsSelfReferences() {
		// Setup & Exercise
		Contact_t boss = new Contact_t();
		new Contact_t().reports(boss).persist();

		// Verify
		System.assertEquals(2, [SELECT COUNT() FROM Contact]);
		System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE ReportsToId != NULL]);
	}

	@IsTest
	private static void allowsJunctionObjects() {
		// Setup & Exercise
		Opportunity_t o = new Opportunity_t();
		Contact_t c = new Contact_t();
		new OpportunityContactRole_t(o, c).persist();

		// Verify
		System.assertEquals(
			1,
			[SELECT COUNT() FROM OpportunityContactRole WHERE ContactId = :c.Id AND OpportunityId = :o.Id]
		);
	}

	@IsTest
	private static void hideLinkerComplexity() {
		// Setup & Exercise
		new Opportunity_t().contact(new Contact_t()).persist();

		// Verify
		System.assertEquals(
			1,
			[SELECT COUNT() FROM OpportunityContactRole WHERE ContactId != NULL AND OpportunityId != NULL]
		);
	}

	@IsTest
	private static void accessRecordFromBuilder() {
		// Setup & Exercise
		Account_t a = new Account_t().name('Salesforce.com');
		a.persist();

		// Verify
		System.assertEquals(Account.SObjectType, a.record.getSObjectType());
	}

	@IsTest
	private static void accessIdFromBuilder() {
		// Setup & Exercise
		Account_t a = new Account_t();
		a.persist();

		// Verify
		System.assertEquals(a.Id, [SELECT Id FROM Account].Id);
	}

	@IsTest
	private static void insertOrder() {
		// Setup & Exercise
		DomainBuilder.DirectedGraph graph = new DomainBuilder.DirectedGraph()
			.node(Account.SObjectType)
			.node(Contact.SObjectType)
			.node(Opportunity.SObjectType)
			.node(OpportunityContactRole.SObjectType)
			.edge(Contact.SObjectType, Account.SObjectType)
			.edge(Contact.SObjectType, Opportunity.SObjectType)
			.edge(Opportunity.SObjectType, Account.SObjectType)
			.edge(OpportunityContactRole.SObjectType, Contact.SObjectType)
			.edge(OpportunityContactRole.SObjectType, Opportunity.SObjectType);

		// Verify
		List<SObjectType> expectedOrder = new List<SObjectType>{
			OpportunityContactRole.SObjectType,
			Contact.SObjectType,
			Opportunity.SObjectType,
			Account.SObjectType
		};
		System.assertEquals(expectedOrder, graph.sortTopologically());
	}
}
