//+------------------------------------------------------------------+
//|                                                    my_expert.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define EXPERT_MAGIC 123456 //magic number dell'expert

int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
  double MiddleBandArray[];
  double UpperBandArray[];
  double LowerBandArray[];
  
  //settiamo gli array per farne una timeseries 
  ArraySetAsSeries(MiddleBandArray,true);
  ArraySetAsSeries(UpperBandArray,true);
  ArraySetAsSeries(LowerBandArray,true);
  
  //definiamo bollinger
  int BollingerBandsDefintion=iBands(_Symbol,_Period,20,0,2,PRICE_CLOSE);
  
  //otteniamo i valori da questo indice
   CopyBuffer(BollingerBandsDefintion,0,0,3,MiddleBandArray);
   CopyBuffer(BollingerBandsDefintion,1,0,3,UpperBandArray);
   CopyBuffer(BollingerBandsDefintion,2,0,3,LowerBandArray);
   
   double MiddleValue=MiddleBandArray[0];
   double UpperValue=UpperBandArray[0];
   double LowerValue=LowerBandArray[0];
   Print("VALORE: ",MiddleValue);
   
   
  }
//+------------------------------------------------------------------+
