@IsTest
public class Account_t extends DomainBuilder {

	public Account_t() {
		super(Account.SObjectType);

		name('Acme Corp');
	}

	public Account_t name(String value) {
		return (Account_t) set(Account.Name, value);
	}

	public Account_t add(Opportunity_t opp) {
		return (Account_t) opp.setParent(Opportunity.AccountId, this);
	}

	public Account_t add(Contact_t opp) {
		return (Account_t) opp.setParent(Contact.AccountId, this);
	}
}