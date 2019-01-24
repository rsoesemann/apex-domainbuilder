@IsTest
public class Contact_t extends DomainBuilder {

	public Contact_t() {
		super(Contact.SObjectType);

		last(new Random().string());
	}

	public Contact_t(Account_t a) {
		super(Contact.SObjectType);
		setParent(Contact.AccountId, a);
	}

	public Contact_t first(String value) {
		return (Contact_t) set(Contact.FirstName, value);
	}

	public Contact_t last(String value) {
		return (Contact_t) set(Contact.LastName, value);
	}
}