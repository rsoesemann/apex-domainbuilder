// Note: THIS CLASS IS NOT DELIVERED NOR INSTALLED INTO ORGS AND IS JUST AN EXAMPLE
public inherited sharing class DebugDML extends fflib_SObjectUnitOfWork.SimpleDML {
	public override void dmlInsert(List<SObject> objList) {
		Database.SaveResult[] srList = Database.insert(objList, false);
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				System.debug('Successfully inserted. ID: ' + sr.getId());
			} else {
				for (Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Fields that affected this error: ' + err.getFields());
				}
			}
		}
	}

	public override void dmlUpdate(List<SObject> objList) {
		Database.SaveResult[] srList = Database.update(objList, false);

		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				System.debug('Successfully inserted. ID: ' + sr.getId());
			} else {
				for (Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Fields that affected this error: ' + err.getFields());
				}
			}
		}
	}
}
