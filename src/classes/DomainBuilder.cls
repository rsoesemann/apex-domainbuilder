public abstract class DomainBuilder {

    private static DirectedGraph graph = new DirectedGraph();
    private static Set<DomainBuilder> objects = new Set<DomainBuilder>();

    private Boolean isSetupObject;
    private Map<SObjectField, DomainBuilder> parentByRelationship = new Map<SObjectField, DomainBuilder>();
    private Map<SObjectField, Map<SObjectField, List<DomainBuilder>>> relationshipsToSync
                                                    = new Map<SObjectField, Map<SObjectField, List<DomainBuilder>>>();
    public SObject record;
    public Id id { private set; get {return record.Id;} }
    public SObjectType type;


    // CONSTRUCTORS

    public DomainBuilder(SObjectType type, Boolean isSetupObject) {
        this.type = type;
        this.record = type.newSObject(null, true);
        this.isSetupObject = isSetupObject;

        graph.node(type);
        objects.add(this);
    }


    public DomainBuilder(SObjectType type) {
        this(type, false);
    }


    // PUBLIC

    public SObject persist() {
	    fflib_SObjectUnitOfWork dataUow = unitOfWork();
	    fflib_SObjectUnitOfWork setupUow = unitOfWork();

        for(DomainBuilder obj: objects) {
            fflib_SObjectUnitOfWork uow = (obj.isSetupObject) ? setupUow : dataUow;

            if(obj.record.Id == null) {
                uow.registerNew(obj.record);
            }

            for(SObjectField rel: obj.parentByRelationship.keySet()) {
                DomainBuilder parent = obj.parentByRelationship.get(rel);
                uow.registerRelationship(obj.record, rel, parent.record);
            }
        }

        dataUow.commitWork();

        if(Test.isRunningTest()) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                setupUow.commitWork();
            }
        }
        else {
            System.debug(LoggingLevel.ERROR, 'PermissionSetAssignment can not be inserted (Mixed DML)');
        }

	    dataUow = unitOfWork();
	    setupUow = unitOfWork();

        objects.clear();

        return record;
    }


    public DomainBuilder recordType(String developerName) {
        Id rtId = type.getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
        return set('RecordTypeId', rtId);
    }


    // PROTECTED

    protected DomainBuilder setParent(SObjectField relationship, DomainBuilder parent) {
        // Note: The parent registered last always wins!
        DomainBuilder oldParent = parentByRelationship.get(relationship);

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

        graph.edge(this.type, parent.type);

        // Note: Return parent instead of this as we call this always from the parent
        return parent;
    }


    protected void syncOnChange(SObjectField sourceField, DomainBuilder targetObject, SObjectField targetField) {
        if( !relationshipsToSync.containsKey(sourceField)) {
            relationshipsToSync.put(sourceField, new Map<SObjectField, List<DomainBuilder>>());
        }
        if( !relationshipsToSync.get(sourceField).containsKey(targetField)) {
            relationshipsToSync.get(sourceField).put(targetField, new List<DomainBuilder>());
        }

        relationshipsToSync.get(sourceField).get(targetField).add(targetObject);

        synchronize(sourceField);
    }


    protected DomainBuilder set(String fieldName, Object value) {
        record.put(fieldName, value);
        return this;
    }


    protected DomainBuilder set(SObjectField field, Object value) {
        record.put(field, value);
        return this;
    }


    protected void unregisterIncludingParents() {
        objects.remove(this);

        for(DomainBuilder parent : parentByRelationship.values()) {
            parent.unregisterIncludingParents();
        }
    }


    // PRIVATE

    private void registerIncludingParents() {
        if(record.Id == null) {
            objects.add(this);

            for(DomainBuilder parent: parentByRelationship.values()) {
                parent.registerIncludingParents();
            }
        }
    }


    private void synchronize(SObjectField sourceField) {
        for(SObjectField targetField: relationshipsToSync.get(sourceField).keySet()) {
            for(DomainBuilder obj : relationshipsToSync.get(sourceField).get(targetField)) {

                DomainBuilder parent = parentByRelationship.get(sourceField);
                obj.setParent(targetField, parent);
            }
        }
    }


    private static fflib_SObjectUnitOfWork unitOfWork() {
	    List<SObjectType> insertOrder = new List<SObjectType>();
	    List<SObjectType> sorted = graph.sortTopologically();

	    for(Integer i = sorted.size() - 1; i >= 0; i--){
		    insertOrder.add(sorted[i]);
	    }
        return new fflib_SObjectUnitOfWork(insertOrder);
    }


    // INNER

    // Note: Code adapted from https://codereview.stackexchange.com/questions/177442
    
    @TestVisible
    class DirectedGraph {

        Map<SObjectType, Integer> childCount = new Map<SObjectType, Integer>();
        Set<SObjectType> pureChilds = new Set<SObjectType>();
        Map<SObjectType, Set<SObjectType>> parents = new Map<SObjectType, Set<SObjectType>>();


        @TestVisible
        DirectedGraph node(SObjectType type) {
            if(!parents.containsKey(type)) {
                parents.put(type, new Set<SObjectType>());
            }

            return this;
        }

        @TestVisible
        DirectedGraph edge(SObjectType child, SObjectType parent) {
            parents.get(child).add(parent);
            return this;
        }


        @TestVisible
        List<SObjectType> sortTopologically() {
            List<SObjectType> result = new List<SObjectType>();

            countDependencies();

            if(pureChilds.isEmpty()) {
                throw new CyclicGraphException();
            }

            while(!pureChilds.isEmpty()) {
                SObjectType cur = (SObjectType) pureChilds.iterator().next();
                pureChilds.remove(cur);

                result.add(cur);

                for(SObjectType type : parents.get(cur)) {
                    Integer newCnt = childCount.get(type) - 1;
                    childCount.put(type, newCnt);

                    if(newCnt == 0) {
                        pureChilds.add(type);
                    }
                }
            }

            if(result.size() != parents.size()) {
                throw new CyclicGraphException();
            }

            return result;
        }


        void countDependencies() {
            for(SObjectType type : parents.keySet()) {
                if(!childCount.containsKey(type)) {
                    pureChilds.add(type);
                }

                for(SObjectType parent : parents.get(type)) {
                    pureChilds.remove(parent);

                    if(!childCount.containsKey(parent)) {
                        childCount.put(parent, 1);
                    }
                    else {
                        childCount.put(parent, childCount.get(parent) + 1);
                    }
                }
            }
        }
    }


    public class CyclicGraphException extends Exception {}
}