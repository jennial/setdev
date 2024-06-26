public with sharing class MaintenanceRequestHelper {
    
    public static void handleAfterUpdateMaintenances(List<Case> newRecords, Map<Id, Case> oldMap) {
        List<Case> casesToInsert = new List<Case>();
        List<Id> closedCaseIds = new List<Id>();
        Map<Id, List<Equipment_Maintenance_Item__c>> equipmentMap = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        Date todayDate = Date.today();
        
        
        for (Case cs : newRecords) {
            Case oldCase = oldMap.get(cs.Id);
            if (cs.Status == 'Closed' && oldCase != null && oldCase.Status != 'Closed' && oldCase.Type == 'Repair' || oldCase.Type == 'Routine Maintenance') {
                closedCaseIds.add(cs.Id);
            }
        }
        
        if (!closedCaseIds.isEmpty()) {
            List<Equipment_Maintenance_Item__c> equipmentItems = [
                SELECT Id, Name, Equipment__c, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c
                FROM Equipment_Maintenance_Item__c
                WHERE Maintenance_Request__c IN :closedCaseIds
            ];
            
            
            for (Equipment_Maintenance_Item__c item : equipmentItems) {
                if (item.Equipment__r != null) {
                    if (!equipmentMap.containsKey(item.Maintenance_Request__c)) {
                        equipmentMap.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>());
                    }
                    equipmentMap.get(item.Maintenance_Request__c).add(item);
                }
            }
        }
        
        // Criar novos casos de manutenção
        for (Id closedCaseId : closedCaseIds) {
            Case oldCase = oldMap.get(closedCaseId);
            if (oldCase != null) {
                Decimal minCycle = findMinCycle(equipmentMap.get(closedCaseId));
                
                Case newCase = new Case(
                    Type = 'Routine Maintenance',
                Subject = 'Scheduled maintenance follow-up',
                Date_Reported__c = todayDate,
                Status = 'New',
                Vehicle__c = oldCase.Vehicle__c,
                Date_Due__c = (minCycle != null) ? todayDate.addDays(minCycle.intValue()) : todayDate.addDays(10)
                    );
                casesToInsert.add(newCase);
            }
        }
        
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }
        List<Equipment_Maintenance_Item__c> itemsToInsert = new List<Equipment_Maintenance_Item__c>();
        for (Integer i = 0; i < casesToInsert.size(); i++) {
            Case newCase = casesToInsert[i];
            List<Equipment_Maintenance_Item__c> relatedEquipment = equipmentMap.get(closedCaseIds[i]);
            
            if (relatedEquipment != null) { 
                for (Equipment_Maintenance_Item__c item : relatedEquipment) {
                    Equipment_Maintenance_Item__c newItem = item.clone(false, true); 
                    newItem.Maintenance_Request__c = newCase.Id;
                    itemsToInsert.add(newItem);
                }
            }
        }
        
        
        if (!itemsToInsert.isEmpty()) {
            insert itemsToInsert;
        }
    }
    private static Decimal findMinCycle(List<Equipment_Maintenance_Item__c> equipmentItems) {
        Decimal minCycle = null;
        if (equipmentItems != null) {
            for (Equipment_Maintenance_Item__c item : equipmentItems) {
                if (item.Equipment__r.Maintenance_Cycle__c != null && (minCycle == null || item.Equipment__r.Maintenance_Cycle__c < minCycle)) {
                    minCycle = item.Equipment__r.Maintenance_Cycle__c;
                }
            }
        }
        return minCycle;
    }
}