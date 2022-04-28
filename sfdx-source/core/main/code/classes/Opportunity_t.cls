public virtual class Opportunity_t extends DomainBuilder {
	public Opportunity_t(Account_t a) {
		super(Opportunity.SObjectType);
		setParent(Opportunity.AccountId, a);

		name('Opp1');
		stage('Open');
		closes(System.today().year() + 1, 1);
	}

	public Opportunity_t() {
		this(new Account_t());
	}

	public virtual Opportunity_t name(String value) {
		return (Opportunity_t) set(Opportunity.Name, value);
	}

	public virtual Opportunity_t amount(Decimal value) {
		return (Opportunity_t) set(Opportunity.Amount, value);
	}

	public virtual Opportunity_t stage(String value) {
		return (Opportunity_t) set(Opportunity.StageName, value);
	}

	public virtual Opportunity_t contact(Contact_t c) {
		new OpportunityContactRole_t(this, c);
		return this;
	}

	public virtual Opportunity_t closes(Integer y, Integer m) {
		return (Opportunity_t) set(Opportunity.CloseDate, Date.newInstance(y, m, 1));
	}

	public virtual Opportunity_t add(Contact_t c) {
		new OpportunityContactRole_t(this, c);
		return this;
	}
}
