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
  double quotaStopLim=0;
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
   
   if(IADValue>lastValue){
        signal="buy";
        quotaStopLim=MiddleValue;
   }
   
   if((IADValue<lastValue)){
       signal="sell";   
       quotaStopLim=LowerValue;
   }
   
   Print("VALORE ",signal," QUOTA ",quotaStopLim);
   
   GoTotheMarket(signal,quotaStopLim);
   
}
//+------------------------------------------------------------------+
//|                            funzione usata per entrare nel mercato|
//+------------------------------------------------------------------+
void GoTotheMarket(string s,double quotaStopLimit){
    //struttura che descrive le attività del cliente
    MqlTradeRequest request={0};
    //descrive i risultati delle operazioni del cliente
    MqlTradeResult result={0};
    
    request.action=TRADE_ACTION_DEAL;
    request.symbol=Symbol();
    request.volume=2.5;
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
    
    if(quotaStopLimit>request.price){
        quotaStopLimit=request.price+0.00100;
    }
    if(quotaStopLimit<request.price){
       quotaStopLimit=request.price-0.00100;
    }
    if((quotaStopLimit==request.price)&&(s=="sell")){
           quotaStopLimit=quotaStopLimit-0.00100;
    }
    if((quotaStopLimit==request.price)&&(s=="buy")){
         quotaStopLimit=quotaStopLimit+0.00100;  
    }
     
    if((StringFind(request.symbol,"JPY",0))>0){
        if(s=="buy"){
           quotaStopLimit=request.price+0.080; 
        }
        if(s=="sell"){
           quotaStopLimit=request.price-0.080; 
        }
        
    }
    request.tp=quotaStopLimit;
    bool esito=OrderSend(request,result);
    if(esito){
       Print("ORDINE PIAZZATO");
    }
    else{
       Print("ORDINE  NON PIAZZATO");
    }
}