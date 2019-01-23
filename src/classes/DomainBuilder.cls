public virtual class DomainBuilder {

    public SObjectType type;
    public SObject record;
    public Id id { private set; get {return record.Id;} }

    private Boolean isSetupObject;
    
    private Map<SObjectField, TestBuilder> parentByRelationship = new Map<SObjectField, TestBuilder>();
    private Map<SObjectField, Map<SObjectField, List<TestBuilder>>> relationshipsToSync = new Map<SObjectField, Map<SObjectField, List<TestBuilder>>>();
    
    private static fflib_SObjectUnitOfWork uow = initUnitOfWork();
    private static fflib_SObjectUnitOfWork mixedDmlUow = initUnitOfWork();
    private static Set<TestBuilder> objects = new Set<TestBuilder>();
    

    // CONSTRUCTORS

    public TestBuilder(SObjectType type, Boolean isSetupObject) {
        this.type = type;
        this.record = type.newSObject(null, true);
        this.isSetupObject = isSetupObject;
        
        objects.add(this);
    }

    
    public TestBuilder(SObjectType type) {
        this(type, false);
    }

    
    public TestBuilder(DescribeSObjectResult describe) {
        this(describe.getSObjectType(), false);
    }
    
    
    // PUBLIC
    
    public virtual SObject persist() {
        for(TestBuilder obj: objects) {
            fflib_SObjectUnitOfWork tempUow = (obj.isSetupObject) ? mixedDmlUow : uow;
            
            if(obj.record.Id == null) {
                tempUow.registerNew(obj.record);
            }
            
            for(SObjectField rel: obj.parentByRelationship.keySet()) {
                TestBuilder parent = obj.parentByRelationship.get(rel);
                tempUow.registerRelationship(obj.record, rel, parent.record);
            }
        }

        uow.commitWork();
        
        if(Test.isRunningTest()) {
            System.runAs(new User(Id = UserInfo.getUserId())) {      
                mixedDmlUow.commitWork();
            }
        }
        else {
            System.debug(LoggingLevel.ERROR, 'PermissionSetAssignment can not be inserted (Mixed DML)');
        }
        
        uow = initUnitOfWork();
        mixedDmlUow = initUnitOfWork();

        objects.clear();
        
        return record;
    }


    public TestBuilder recordType(String developerName) {
        Id rtId = type.getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
        return set('RecordTypeId', rtId);
    }


    // PROTECTED
    
    protected TestBuilder setParent(SObjectField relationship, TestBuilder parent) {
        
        // Note: The parent registered last always wins!
        TestBuilder oldParent = parentByRelationship.get(relationship);

        // Note: Sometime we manually unregister parent that are set by default constructor
        if(parent != null) {
            parentByRelationship.put(relationship, parent);
        }
        
        if(oldParent != null && oldParent != parent) {
            oldParent.unregisterIncludingParents();
        }
        
        if(parent != null && !objects.contains(parent)) {
            parent.registerIncludingParents();
        }
        
        if(relationshipsToSync.containsKey(relationship)) {
            synchronize(relationship);
        }
        
        // Note: Return parent instead of this as we call this always from the parent
        return parent;
    }
    
    
    protected TestBuilder setParent(DescribeFieldResult relationship, TestBuilder parent) {
    	return setParent(relationship.getSObjectField(), parent);
    }
    
    
    protected void syncOnChange(SObjectField sourceField, TestBuilder targetObject, SObjectField targetField) {
        if( !relationshipsToSync.containsKey(sourceField)) {
            relationshipsToSync.put(sourceField, new Map<SObjectField, List<TestBuilder>>());
        }
        if( !relationshipsToSync.get(sourceField).containsKey(targetField)) {
            relationshipsToSync.get(sourceField).put(targetField, new List<TestBuilder>());
        }
        
        relationshipsToSync.get(sourceField).get(targetField).add(targetObject);
        
        synchronize(sourceField);
    }
    
    
    protected void syncOnChange(DescribeFieldResult sourceField, TestBuilder targetObject, DescribeFieldResult targetField) {
    	syncOnChange(sourceField.getSObjectField(), targetObject, targetField.getSObjectField());
    }
    
    
    protected TestBuilder set(String fieldName, Object value) {
        record.put(fieldName, value);
        return this;
    }
    
    
    protected TestBuilder set(SObjectField field, Object value) {
        record.put(field, value);
        return this;
    }
    
    
    protected TestBuilder set(DescribeFieldResult field, Object value) {
    	return set(field.getSObjectField(), value);
    }
    
    
    protected String fieldNo(Integer no) {
        String result = (no<10) ? '0' + no : '' + no;
        return result;
    }


    protected virtual void unregisterIncludingParents() {
        objects.remove(this);

        for(TestBuilder parent : parentByRelationship.values()) {
            parent.unregisterIncludingParents();
        }
    }

    
    // PRIVATE
    
    private void registerIncludingParents() {
        if(record.Id == null) {
            objects.add(this);
            
            for(TestBuilder parent: parentByRelationship.values()) {
                parent.registerIncludingParents();
            }
        }
    }
    
    
    private void synchronize(SObjectField sourceField) {
        for(SObjectField targetField: relationshipsToSync.get(sourceField).keySet()) {
            for(TestBuilder obj : relationshipsToSync.get(sourceField).get(targetField)) {
                
                TestBuilder parent = parentByRelationship.get(sourceField);
                obj.setParent(targetField, parent);
            }
        }
    }
    
    
    private static fflib_SObjectUnitOfWork initUnitOfWork() {
        return new fflib_SObjectUnitOfWork(new List<Schema.SObjectType>{
                                                        User.SObjectType,
                                                        Contact.SObjectType,
                                                        PermissionSetAssignment.SObjectType

                                                        
                                                    });
    }
}
