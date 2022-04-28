public virtual class Contact_t extends DomainBuilder {
	public Contact_t(Account_t a) {
		super(Contact.SObjectType);
		setParent(Contact.AccountId, a);

		last(new Random().string());
	}

	public Contact_t() {
		this(new Account_t());
	}

	public virtual Contact_t first(String value) {
		return (Contact_t) set(Contact.FirstName, value);
	}

	public virtual Contact_t last(String value) {
		return (Contact_t) set(Contact.LastName, value);
	}

	public virtual Contact_t email(String value) {
		return (Contact_t) set(Contact.Email, value);
	}

	public virtual Contact_t reports(Contact_t c) {
		return (Contact_t) setParent(Contact.ReportsToId, c);
	}
}
