public with sharing class MaintenanceRequestHelper {
    //Quando for fechada uma manutenção. Adicionar uma nova manutenção com vinculo dos equipamentos e veiculo
    //tipo deve ser routine
    //subject colocar qualquer coisa
    //data reported preencher com a data que foi fechado
    //date due precisa ser preenchido com o equipament com o vencimento mais proximo
    //ProductId
    
    public static void handleAfterUpdateMaintenances(List<Case> newRecords, Map<Id, Case> oldMap){
        List<Case> casesClosed = new List<Case>();
        List<Id> idMaintenance = new List<Id>();
        List<Product2> equipamentList = new List<Product2>();
        Date todayDate = Date.today();
        List<Case> oldCases = new List<Case>();
        Decimal minCycle = null;
        Integer minCycleInt = null;
        
        for(Case oldcs : oldMap.values()){
            oldCases.add(oldcs);
            System.debug('Caso antigo------------------>'+oldCases);
            
            if(oldcs.Type == 'Repair' || oldcs.Type == 'Routine Maintenance'){
                
                for(Case cs : newRecords){
                    
                    if(cs.Status != oldMap.get(cs.Id).status){
                        System.debug('entrou no primeiro if');
                        if(cs.Status == 'Closed'){
                            System.debug('entrou no segundo  if');
                            casesClosed.add(cs);
                            idMaintenance.add(cs.Id);
                            if(casesClosed.size() > 0){
                                Case newmaintenance = new Case();
                                System.debug('entrou no terceiro if');
                                
                                List<Equipment_Maintenance_Item__c> equipament =
                                    [select id, Name,Equipment__c, Equipment__r.Maintenance_Cycle__c from Equipment_Maintenance_Item__c 
                                where Maintenance_Request__c in:idMaintenance];
                                
                                System.debug('equipamentos'+ equipament);
                                for(Equipment_Maintenance_Item__c item : equipament){
                                    System.debug('veio até aqui ');
                                    
                                    newmaintenance.ProductId = item.Equipment__c;
                                    
                                    Decimal currencyCycle = item.Equipment__r.Maintenance_Cycle__c;
                                    
                                    if(minCycle == null || currencyCycle < minCycle){
                                        minCycle = currencyCycle;
                                        minCycleInt = minCycle.intValue();
                                        System.debug(minCycleInt + 'minCycleInt');
                                    }
                                }
                                
                                newmaintenance.Type = 'Routine Maintenance';
                                newmaintenance.Subject = 'Do a new maintenance';
                                newmaintenance.Date_Reported__c = todayDate;
                                newmaintenance.Status = 'New';
                                if(minCycleInt != null){
                                    newmaintenance.Date_Due__c = todayDate.addDays(minCycleInt);
                                    
                                }else{
                                    newmaintenance.Date_Due__c = todayDate.addDays(10);
                                }
                                Case correspondingOldCase = oldMap.get(cs.Id);
                                if (correspondingOldCase != null) {
                                    newmaintenance.Vehicle__c = correspondingOldCase.Vehicle__c;
                                }
                                insert newmaintenance;
                                System.debug('Novo Case     ----------------------->'+newmaintenance);
                            }
                        }
                    }
                }
            }
        }
    }
} sd