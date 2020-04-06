//+------------------------------------------------------------------+
//|                                                    my_expert.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//|                       algoritmo che usa le bande di bollinger e  |
//                                       l'accumultaion distribution |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//

#define EXPERT_MAGIC 025896 //magic number dell'expert
//indicatori bande di bollinger
double MiddleBandArray[];
double UpperBandArray[];
double LowerBandArray[];
//indicatori AD
double myPriceArray[];

//variabili usate per leggere gli indicatori
int BollingerBandsDefintion;
int ADdefinition;

string lastSignal="null";


//+------------------------------------------------------------------+
//|   Expert initialization function
//+------------------------------------------------------------------+
int OnInit()
  {

   ArraySetAsSeries(MiddleBandArray,true);
   ArraySetAsSeries(UpperBandArray,true);
   ArraySetAsSeries(LowerBandArray,true);
   ArraySetAsSeries(myPriceArray,true);
   
   //definiamo bollinger
   BollingerBandsDefintion=iBands(_Symbol,_Period,20,0,2,PRICE_CLOSE);
   //definiamo AD
   ADdefinition=iAD(_Symbol,_Period,VOLUME_TICK);
   
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
  string signal="";
  
//otteniamo i valori da questo indice
   CopyBuffer(BollingerBandsDefintion,0,0,3,MiddleBandArray);
   CopyBuffer(BollingerBandsDefintion,1,0,3,UpperBandArray);
   CopyBuffer(BollingerBandsDefintion,2,0,3,LowerBandArray);
   CopyBuffer(ADdefinition,0,0,11,myPriceArray);
   
   double MiddleValue=MiddleBandArray[0];
   double UpperValue=UpperBandArray[0];
   double LowerValue=LowerBandArray[0];
   double differenzaBande=UpperValue-LowerValue;
   
   //valore candela corrente
   double IADValue=myPriceArray[0];
   //calcola il valore delle ultime 10 candele
   double lastValue=myPriceArray[10];
   
   if((IADValue>lastValue)&&(differenzaBande<=0.000250)){
        signal="buy";
        Print(signal);
        if(lastSignal=="null"){
            GoTotheMarket(signal);
            lastSignal=signal;  
        }
        else{
           if(lastSignal!=signal){
               ExitMarket();
               GoTotheMarket(signal);
               lastSignal=signal;
           }
        }
    }
   
   if((IADValue<lastValue)&&(differenzaBande<=0.000250)){
       signal="sell";
       Print(signal);
        if(lastSignal=="null"){
            GoTotheMarket(signal);
            lastSignal=signal;  
        }
        else{
           if(lastSignal!=signal){
               ExitMarket();
               GoTotheMarket(signal);
               lastSignal=signal;
           }
        }      
   }
}
//+------------------------------------------------------------------+
//|                            funzione usata per entrare nel mercato|
//+------------------------------------------------------------------+
void GoTotheMarket(string s){
    //struttura che descrive le attività del cliente
    MqlTradeRequest request={0};
    //descrive i risultati delle operazioni del cliente
    MqlTradeResult result={0};
    
    request.action=TRADE_ACTION_DEAL;
    request.symbol=Symbol();
    request.volume=2.0;
    request.magic=EXPERT_MAGIC;
    
    //otteniamo prezzo di apertura in caso di ribasso o rialzo
    if(s=="buy"){
        request.type=ORDER_TYPE_BUY; 
        request.price =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
    }
    if(s=="sell"){
        request.type=ORDER_TYPE_SELL; 
        request.price =SymbolInfoDouble(Symbol(),SYMBOL_BID);
    }
    
    bool esito=OrderSend(request,result);
    if(esito){
       Print("ORDINE PIAZZATO");
    }
    else{
       Print("ORDINE  NON PIAZZATO");
    }
}
//+------------------------------------------------------------------+
//|                            funzione usata per uscire nel mercato|
//+------------------------------------------------------------------+
void ExitMarket(){
     //otteniamo il totale degli ordini
     int total=PositionsTotal();
     //settiamo i campi per effettuare la chiusura delle posizioni
     MqlTradeRequest closedRequest={0};
     MqlTradeResult closedResult={0};
     for(int i=total-1;i>=0;i--){
        //parametri per l'ordine piazzato
        ulong position_ticket = PositionGetTicket(i);//otteniamo il ticket i-esimo
        string position_symbol = PositionGetString(POSITION_SYMBOL);//otteniamo la valuta
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
            
            if(lastSignal=="buy"){
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
}
//+------------------------------------------------------------------+
