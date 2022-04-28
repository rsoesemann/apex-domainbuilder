public class AccountExtra_t extends Account_t {
	public virtual Account_t contact(Contact_t c) {
		setParent(Account.MainContact__c, c);
		return this;
	}

	public override Account_t add(Contact_t c) {
		return (AccountExtra_t) c.setParent(Contact.AccountId, this);
	}
}
