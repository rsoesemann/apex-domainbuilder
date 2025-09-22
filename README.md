# Apex Domain Builder [![Codacy Badge](https://api.codacy.com/project/badge/Grade/3814b20244d14e3d846ff05dfd3c2e2a)](https://www.codacy.com/app/rsoesemann/apex-domainbuilder?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=rsoesemann/apex-unified-logging&amp;utm_campaign=Badge_Grade)

Test Data Builder framework to setup test data for complex Apex integration tests in a concise, readable and flexible way.

**TL;DR; Watch my a Youtube Code Live with Salesforce about the apex-domainbuilder**

[![](http://img.youtube.com/vi/Kc0q8pfD3Ic/hqdefault.jpg)](https://youtu.be/Kc0q8pfD3Ic?t=279 "")

<a href="https://githubsfdeploy.herokuapp.com?owner=rsoesemann&repo=apex-domainbuilder">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Setting up test data for complex Apex integration tests is not easy, because you need to..:

 - set required fields even if irrelevant for the test
 - insert the objects in the right order
 - create relationships by setting Lookup fields
 - put ugly `__c` all over the place
 - clutter your code with `Map<Id, SObject>` to keep track of related records
 - reduce the DML statements to not hit Governor Limits
 
TestFactories as used by many developers and recommended by Salesforce.com can help to minimize ugly setup code by moving it to seperate classes. But over time those classes tend to accumulate complexity and redundant spaghetti code.

In the world of Enterprise software outside of Salesforce.com there are experts that have created patterns for flexible and readable (fluent, concise) test data generation. Among them, the most notable is Nat Pryce who wrote a great book about testing and somewhat invented the [Test Data Builder](http://www.natpryce.com/articles/000714.html) pattern. It's based on the more general [Builder Pattern](https://refactoring.guru/design-patterns/builder) which simplifies the construction of objects by moving variations from complex constructors to separate objects that only construct parts of the whole.

**apex-domainbuilder** brings those ideas to Apex testing:
1. By incorporating a simple small Builder class for each test-relevant Domain SObject we centralize all the creation knowledge and eliminate redundancy.

```java
@IsTest
public class Account_t extends DomainBuilder {

    // Construct the object

    public Account_t() {
        super(Account.SObjectType);

        name('Acme Corp');
    }

    // Set Properties

    public Account_t name(String value) {
        return (Account_t) set(Account.Name, value);
    }

    // Relate it to other Domain Objects 

    public Account_t add(Opportunity_t opp) {
        return (Account_t) opp.setParent(Opportunity.AccountId, this);
    }

    public Account_t add(Contact_t con) {
        return (Account_t) con.setParent(Contact.AccountId, this);
    }
}
```

2. By internally leveraging the [`fflib_SObjectUnitOfWork`](https://github.com/financialforcedev/fflib-apex-common/blob/master/fflib/src/classes/fflib_SObjectUnitOfWork.cls) for the DML all tests run dramatically faster.

3. The **[Fluent Interface](https://martinfowler.com/bliki/FluentInterface.html)** style of the Builder pattern combined with having all the database wiring encapsulated in the Unit of work made each test much more understandable.

```java
    @IsTest
    private static void easyTestDataCreation() {

        // Setup
        Contact_t jack = new Contact_t().first('Jack').last('Harris');h

        new Account_t()
                .name('Acme Corp')
                .add( new Opportunity_t()
                                .amount(1000)
                                .closes(2019, 12)
                                .contact(jack))
                .persist();
        
        // Exercise
        ...
	
	
	// Verify
	...
    }
```

4. Using **Graph algorithms** to autodetect the correct insert order in the Unit Of Work.
5. Is able to **handle self-reference fields** (e.g. Manager Contact Lookup on Contact) by using a patched **fflib Unit of Work**.
