trigger MaintenanceRequest on Case (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){
        MaintenanceRequestHelper.handleAfterUpdateMaintenances(Trigger.New, Trigger.oldMap);
    }
}  