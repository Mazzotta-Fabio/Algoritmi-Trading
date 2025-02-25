//+------------------------------------------------------------------+
//|                                             testStocastistic.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define EXPERT_MAGIC 123456 //magic number dell'expert
string lastsignal="null";
//utilizzato per tenere traccia delle infromazioni sulle linee dello stocastico
double KArray[];
double DArray[];
int StocaticDefinition;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //settiamo gli array per farne una timeseries 
   ArraySetAsSeries(KArray,true);
   ArraySetAsSeries(DArray,true);
   
   //definiamo lo stocastico
   //K-PERIOD,D-PERIOD,slittamento finale,media semplice,prezzo basato su inferiore e superiore
   StocaticDefinition=iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  /*
    do nothing
  */
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //utilizzata per tenere traccia del segnale
   string signal="";
   
   //otteniamo i dati dello stocastico e li inseriamo nell'array
   CopyBuffer(StocaticDefinition,0,0,3,KArray);
   CopyBuffer(StocaticDefinition,1,0,3,DArray);
   
   //valore iniziale stocastico
   double KValue0=KArray[0];
   double DValue0=DArray[0];
   
   //valore finale stocastico
   double KValue1=KArray[1];
   double DValue1=DArray[1];
   
   //segnale di acquisto
   if((KValue0<20)&&(DValue0<20)){
   //ora vediamo se i segnali sono incrociati
      if((KValue0>DValue0)&&(KValue1<DValue1)){
         signal="buy";
      }
   }
    
   //segnale di vendita
   if((KValue0>80)&&(DValue0>80)){
   //ora vediamo se i segnali sono incrociati
      if((KValue0<DValue0)&&(KValue1>DValue1)){
         signal="sell";
      }
   }
   //stampa il segnale calcolato
   Print("SEGNALE: ",signal);
   if(signal!=""){
      GoTotheMarket(signal);
   } 
}

void GoTotheMarket(string signal){
    //struttura che descrive le attività del cliente
    MqlTradeRequest request={0};
    //descrive i risultati delle operazioni del cliente
    MqlTradeResult result={0};
    
    request.action=TRADE_ACTION_DEAL;
    request.symbol=Symbol();
    request.volume=1.0;
    request.magic=EXPERT_MAGIC;
    
    //otteniamo prezzo di apertura in caso di ribasso o rialzo
    if(signal=="buy"){
        request.type=ORDER_TYPE_BUY; 
        request.price =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
    }
    if(signal=="sell"){
        request.type=ORDER_TYPE_SELL; 
        request.price =SymbolInfoDouble(Symbol(),SYMBOL_BID);
    }
    
    if(lastsignal=="null"){
        bool esito=OrderSend(request,result);
        if(esito){
           Print("ORDINE PRIMO PIAZZATO");
        }
        else{
           Print("ORDINE PRIMO NON PIAZZATO");
        }
    }
    else{
       if((signal!=lastsignal)&&(signal!="")){
         //otteniamo il totale degli ordini
         int total=PositionsTotal();
         //settiamo i campi per effettuare la chiusura delle posizioni
         MqlTradeRequest closedRequest={0};
         MqlTradeResult closedResult={0};
         for(int i=total-1;i>=0;i--){
            //parametri per l'ordine piazzato
            ulong position_ticket=PositionGetTicket(i);//otteniamo il ticket i-esimo
            string position_symbol=PositionGetString(POSITION_SYMBOL);//otteniamo la valuta
            Print("POSIZIONE APERTA: ", position_ticket, " VALUTA ",position_symbol);
            ulong magic=PositionGetInteger(POSITION_MAGIC);//otteniamo il numero magico
            double volume = PositionGetDouble(POSITION_VOLUME);//otteniamo i lotti
            
            if(magic==EXPERT_MAGIC){
                //azzeriamo la richiesta e i risultati
                ZeroMemory(closedRequest);
                ZeroMemory(closedResult);
                //impostiamo i parametri dell'operazione
                closedRequest.action=TRADE_ACTION_DEAL;
                closedRequest.position=position_ticket;
                closedRequest.magic=EXPERT_MAGIC;
                closedRequest.volume=volume;
                closedRequest.symbol=position_symbol;
                
                if(lastsignal=="buy"){
                   closedRequest.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
                   closedRequest.type=ORDER_TYPE_SELL;
                }
                else{
                   closedRequest.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
                   closedRequest.type=ORDER_TYPE_BUY;
                }
            }  
            //inviamo l'ordine di chiusura
            bool esitoChiusura=OrderSend(closedRequest,closedResult);
            if(esitoChiusura){
               Print("ORDINE CHIUSO");
            }
            else{
               Print("ORDINE NON CHIUSO");
            }
         } 
         //settiamo l'ordine nuovo di apertura       
         bool esito=OrderSend(request,result);
         if(esito){
            Print("ORDINE PIAZZATO");
         }
         else{
           Print("ORDINE NON PIAZZATO");
         }
      }
    }
    
    if(signal!=""){
       lastsignal=signal;
    }
    
 }
 