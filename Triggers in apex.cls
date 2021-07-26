 Triggers conta 



public without sharing class TriggerHandlerConta {
    
    
    public static Boolean ignoreTrigger {get;set;}

	private TriggerHandlerConta() {  }

    public static void atualizaStatusConta(List<Account> listNewAcc, List<Account> listOldAcc){
        if(ignoreTrigger == null || ignoreTrigger == false){
            map<id, User> mapUsers = new map<id, User>();
            for(User user : [SELECT Id, Area_de_Atuacao__c FROM User WHERE isActive = true]){
                mapUsers.put(user.Id, user);
            }
            Account newAcc = listNewAcc[0];
            Account oldAcc = listOldAcc[0];
        try{
            if(newAcc.OwnerId != oldAcc.OwnerId && newAcc.Classificacao_Cliente__c == 'Sem Consumo' && mapUsers.get(newAcc.OwnerId).Area_de_Atuacao__c == 'BDR'){

                List<Opportunity> listOpp1 = [SELECT Id FROM Opportunity WHERE AccountId =: newAcc.Id];

                if(listOpp1.size() <= 0){
				    newAcc.Etapa_Comercial__c = 'BDR';
				    newAcc.Qualifica_o_da_Conta__c = 'Qualificado SEM Oportunidade';

                } else {

                    List<Opportunity> listOpp2 = [SELECT Id FROM Opportunity WHERE AccountId =: newAcc.Id
                                                                             AND isWon = false
                                                                             AND IsClosed = false];
                    if(listOpp2 != null && listOpp2.size() > 0){
                        newAcc.Etapa_Comercial__c = 'BDR';
				        newAcc.Qualifica_o_da_Conta__c = 'Qualificado COM Oportunidade';
                    }                                                    
                }
            } else if(newAcc.OwnerId != oldAcc.OwnerId && newAcc.Classificacao_Cliente__c == 'Sem Consumo' && mapUsers.get(newAcc.OwnerId).Area_de_Atuacao__c == 'Vendedor'){

                List<Opportunity> listOpp3 = [SELECT Id FROM Opportunity WHERE AccountId =: newAcc.Id
                                                                             AND isWon = false
                                                                             AND IsClosed = false];
                if(listOpp3 != null && listOpp3.size() > 0){
                    newAcc.Etapa_Comercial__c = 'VENDAS';
				    newAcc.Qualifica_o_da_Conta__c = 'Em Negociação';

                }  else {

                    List<Opportunity> listOpp4 = [SELECT Id, StageName FROM Opportunity WHERE AccountId =: newAcc.Id
                                                                              AND StageName = 'Negócio Perdido'
                                                                              AND isWon = false
                                                                              AND IsClosed = false];
                    if(listOpp4 != null && listOpp4.size() > 0){
                        newAcc.Etapa_Comercial__c = 'VENDAS';
                        newAcc.Qualifica_o_da_Conta__c = 'Negócio Perdido'; 
                    }                                                         
                }                                                         
            }
            } catch ( Exception ex){
                System.debug('Erro : ' + ex.getMessage());
                System.debug('Motivo: ' + ex.getCause());
                System.debug('Linha : ' + ex.getLineNumber());
            }
        }
    }

    public static void blockAlterarNomeConta(List<Account> listAcc, List<Account> listOldAcc){
        if(ignoreTrigger == null || ignoreTrigger == false){
            Account newAcc = listAcc[0];
            Account oldAcc = listOldAcc[0];

            try{
                if(newAcc.Razao_Social__c != oldAcc.Razao_Social__c && oldAcc.CNPJ__C != null){
                    newAcc.addError('[ERROR] Não é possível alterar a razão social depois de já ter cadastrado o CNPJ. Consulte os dados na receita federal');
                }
                
                if(newAcc.Name != oldAcc.Name && oldAcc.CNPJ__C != null){
                    newAcc.addError('[ERROR] Não é possível alterar o nome da conta depois de já ter cadastrado o CNPJ. Consulte os dados na receita federal');
                }

            } catch ( Exception ex){
                System.debug('Erro : ' + ex.getMessage());
                System.debug('Motivo: ' + ex.getCause());
                System.debug('Linha : ' + ex.getLineNumber());
            }
        }
    }

    
    public static void ajustarDependenciaConta(List<Account> listNewAcc, List<Account> listOldAcc){
        if(ignoreTrigger == null || ignoreTrigger == false){
            Account newAcc = listNewAcc[0];
            Account oldAcc = listOldAcc[0];

                try{
                    if(oldAcc.Classificacao_Cliente__c == 'Sem Consumo'){

                     if(newAcc.Classificacao_Cliente__c == 'Corporate' || newAcc.Classificacao_Cliente__c == 'Enterprise' || newAcc.Classificacao_Cliente__c == 'Key Account'){
                         newAcc.Etapa_Comercial__c = null;
                         newAcc.Qualifica_o_da_Conta__c = null;
                        }
                    } else if(oldAcc.Classificacao_Cliente__c == 'Sem Perfil'){
                        if(newAcc.Classificacao_Cliente__c == 'Corporate' || newAcc.Classificacao_Cliente__c == 'Enterprise' || newAcc.Classificacao_Cliente__c == 'Key Account'){
                            newAcc.Motivo_sem_Perfil__c = null;
                        }
                    }
                } catch ( Exception ex){
                    System.debug('Erro : ' + ex.getMessage());
                    System.debug('Motivo: ' + ex.getCause());
                    System.debug('Linha : ' + ex.getLineNumber());
                }
        }
    }


    triggers oportunidade /////////////////////////////////////////


    public class TriggerHandlerOportunidade {
  
        public static Boolean ignoreTrigger {get;set;}
        
        
        private TriggerHandlerOportunidade() {  }
    
    
        
    
        public static void bloquearCriarOppVendedor(List<Opportunity> listOpp){
            if(ignoreTrigger == null || ignoreTrigger == false){
                User user = [SELECT Id, FirstName, LastName, Area_de_Atuacao__c FROM User WHERE isActive = true AND Area_de_Atuacao__c = 'BDR'];
                
                Opportunity opp = listOpp[0];
    
                List<Opportunity> newOpp = [SELECT Id, CreatedById, OwnerId FROM Opportunity WHERE IsClosed = false AND isWon = false 
                                            AND CreatedById = : user.Id
                                            AND AccountId = : opp.AccountId
                                            AND OwnerId = : UserInfo.getUserId()];
    
                if(newOpp != null && newOpp.size() > 0){
                    opp.addError('[ERRO] Você possui uma oportunidade lançada por pré vendas, para iniciar uma nova oportunidade contate o BDR de origem.');
                }
            }	
        }
    
    
        public static void atualizarStatusConta(List<Opportunity> listNewOpp, List<Opportunity> listOldOpp){
            if (ignoreTrigger == null || ignoreTrigger == false) {
    
                Opportunity oldOpp = listOldOpp[0];
                Opportunity newOpp = listNewOpp[0];
                
                    
                  try{  
                       if(!Test.isRunningTest()){
                           if(newOpp.Liberar_Oportunidade__c == true){
                        
                         
                             List<Account> listAcc = [SELECT Id, Name, Classificacao_Cliente__c , Etapa_Comercial__c, Qualifica_o_da_Conta__c, OwnerId FROM Account WHERE Id = : newOpp.AccountId];
                             for(Account conta: listAcc){
                            
                                  conta.OwnerId = newOpp.OwnerId;
                                  conta.Classificacao_Cliente__c = 'Sem Consumo';
                                  conta.Etapa_Comercial__c = 'VENDAS';
                                  conta.Qualifica_o_da_Conta__c = 'Em Negociação';
    
                                  Database.update(conta);
                               }
                            }
                        }
                    } catch(Exception ex){
                          System.debug('Erro: ' + ex.getMessage());
                          System.debug('Motivo: ' + ex.getCause());
                          System.debug('Linha: ' + ex.getLineNumber());
                        }
                
            }
        }
    
    
        public static void aprovarOportunidade(List<Opportunity> listNewOpp, List<Opportunity> listOldOpp){
            Map<Id, User> mapUsers = new Map<Id, User>();
             for(User user : [SELECT Id, FirstName, LastName, Area_de_Atuacao__c, IsAdmin__c FROM User WHERE isActive = true]){
              mapUsers.put(user.Id, user);
             }
              Opportunity oldOpp = listOldOpp[0];
              Opportunity newOpp = listNewOpp[0];
              
                
    
                  //Alterando proprietário
                if(mapUsers.get( UserInfo.getUserId() ).Area_de_Atuacao__c == 'BDR' &&  mapUsers.get( newOpp.OwnerId ).Area_de_Atuacao__c == 'Vendedor'){
                
                    if( newOpp.OwnerId != oldOpp.OwnerId ){
                
                     // enviar aprovação 	
                
                     String result = '';
                   
    
                     try{
                     Opportunity opp = [SELECT Id, Name, StageName, OwnerId FROM Opportunity WHERE id = :newOpp.Id];
        
                     Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                     req.setComments('Enviando oportunidade para aprovação');
                     req.setObjectId(opp.Id);
                     req.setSubmitterId(opp.OwnerId); 
                     req.setProcessDefinitionNameOrId('Aprovar_Oportunidade');
                     req.setSkipEntryCriteria(false);
                
                     if(!Test.isRunningTest()){
                      Approval.ProcessResult resultApproval = Approval.process(req);
                      }
        
                     result = 'Solicitada aprovação da Oportunidade. Aguarde uma resposta para poder seguir';
            
                     } catch(Exception ex){
                     System.debug('Erro: ' + ex.getCause());
                     System.debug('Mensagem: ' + ex.getMessage());
                     System.debug('Local: ' + ex.getLineNumber());
    
                     result = '[ERRO] ao enviar processo para aprovação. Motivo: ' + ex.getMessage();
                     }
                    }
                }
        }
    
    
        public static void oportunidadeRejeitadaBDR( list<Opportunity> listNewOpp){
            if (ignoreTrigger == null || ignoreTrigger == false) {
    
                Map<Id, User> mapUsers = new Map<Id, User>();
                for(User user : [SELECT Id, FirstName, LastName, Area_de_Atuacao__c, IsAdmin__c, Email FROM User WHERE isActive = true]){
                   mapUsers.put(user.Id, user);
                }
                for(Opportunity opp: listNewOpp){
                  try{
                   if (opp.Oportunidade_Rejeitada__c == true &&  mapUsers.get( opp.OwnerId ).Area_de_Atuacao__c == 'Vendedor') {
                       opp.OwnerId = opp.BDR__c;
    
                   }
                  } catch(Exception ex){
                    System.debug('Erro: ' + ex.getMessage());
                    System.debug('Motivo: ' + ex.getCause());
                    System.debug('Linha: ' + ex.getLineNumber());
                    }
                } 
            }
        }