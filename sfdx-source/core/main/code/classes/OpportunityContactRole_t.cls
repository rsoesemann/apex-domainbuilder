public virtual class OpportunityContactRole_t extends DomainBuilder {
	public OpportunityContactRole_t(Opportunity_t o, Contact_t c) {
		super(OpportunityContactRole.SObjectType);
		setParent(OpportunityContactRole.OpportunityId, o);
		setParent(OpportunityContactRole.ContactId, c);
	}

	public OpportunityContactRole_t(Contact_t c) {
		this(new Opportunity_t(), c);
	}
}
