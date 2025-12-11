//+------------------------------------------------------------------+
//|                                                       RREA.mq5   |
//|                        Copyright 2024, RREA                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, RREA"
#property version   "2.00"
#property description "Manual scalping EA with previous bar orders"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                |
//+------------------------------------------------------------------+
input double   StopLossPrice = 0.0;           // Stop Loss Price (MUST BE SET)
input double   PreferredRisk = 50.0;          // Preferred Risk ($)
input double   RiskMultiplier = 2.0;          // Risk Multiplier for TP (e.g., 2.0 for 1:2)
input double   MaxSpreadPercent = 10.0;       // Max Spread % of TP
input int      MagicNumber = 000003;          // Magic Number
input string   TradeComment = "RREA";         // Trade Comment

//+------------------------------------------------------------------+
//| Global Variables                                                |
//+------------------------------------------------------------------+
CTrade          trade;
CPositionInfo   positionInfo;
COrderInfo      orderInfo;

double          previousBarHigh = 0.0;
double          previousBarLow = 0.0;

// Panel dimensions and position
int panelX = 10;
int panelY = 20;
int panelWidth = 250;  // Increased width for better text display
int panelHeight = 240; // Increased height to cover all labels
color panelBgColor = C'240,240,240';  // Light gray
color textColor = clrBlack;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set magic number for trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(Symbol());
   
   // Create UI
   CreateUI();
   
   Print("RREA initialized");
   Print("Symbol: ", Symbol(), ", Point: ", _Point, ", Digits: ", _Digits);
   Print("Stop Loss Price: ", StopLossPrice);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up UI objects
   ObjectDelete(0, "PanelBackground");
   ObjectDelete(0, "btnBuyLimit");
   ObjectDelete(0, "btnSellLimit");
   ObjectDelete(0, "btnBuyStop");
   ObjectDelete(0, "btnSellStop");
   ObjectDelete(0, "lblStatus");
   ObjectDelete(0, "lblSpread");
   ObjectDelete(0, "lblPosition");
   ObjectDelete(0, "lblStopLoss");
   ObjectDelete(0, "lblPrevBar");
   
   Print("RREA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update display every tick
   UpdateDisplay();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Handle button clicks
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == "btnBuyLimit")
      {
         Print("Buy Limit button clicked");
         PlaceBuyLimitOrder();
      }
      else if(sparam == "btnSellLimit")
      {
         Print("Sell Limit button clicked");
         PlaceSellLimitOrder();
      }
      else if(sparam == "btnBuyStop")
      {
         Print("Buy Stop button clicked");
         PlaceBuyStopOrder();
      }
      else if(sparam == "btnSellStop")
      {
         Print("Sell Stop button clicked");
         PlaceSellStopOrder();
      }
   }
}

//+------------------------------------------------------------------+
//| Create UI elements                                              |
//+------------------------------------------------------------------+
void CreateUI()
{
   int x = panelX;
   int y = panelY;
   int width = panelWidth - 10;
   int height = 25;
   int spacing = 30;
   
   // Create panel background
   ObjectCreate(0, "PanelBackground", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_BGCOLOR, panelBgColor);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_BACK, false);
   ObjectSetInteger(0, "PanelBackground", OBJPROP_SELECTABLE, false);
   
   // Create Buy Limit button
   ObjectCreate(0, "btnBuyLimit", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_YSIZE, height);
   ObjectSetString(0, "btnBuyLimit", OBJPROP_TEXT, "BUY LIMIT");
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "btnBuyLimit", OBJPROP_FONTSIZE, 9);
   
   y += spacing;
   
   // Create Sell Limit button
   ObjectCreate(0, "btnSellLimit", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_YSIZE, height);
   ObjectSetString(0, "btnSellLimit", OBJPROP_TEXT, "SELL LIMIT");
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_BGCOLOR, clrRed);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "btnSellLimit", OBJPROP_FONTSIZE, 9);
   
   y += spacing;
   
   // Create Buy Stop button
   ObjectCreate(0, "btnBuyStop", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_YSIZE, height);
   ObjectSetString(0, "btnBuyStop", OBJPROP_TEXT, "BUY STOP");
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "btnBuyStop", OBJPROP_FONTSIZE, 9);
   
   y += spacing;
   
   // Create Sell Stop button
   ObjectCreate(0, "btnSellStop", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_YSIZE, height);
   ObjectSetString(0, "btnSellStop", OBJPROP_TEXT, "SELL STOP");
   ObjectSetInteger(0, "btnSellStop", OBJPROP_BGCOLOR, clrOrange);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "btnSellStop", OBJPROP_FONTSIZE, 9);
   
   y += 20;
   
   // Create status label
   ObjectCreate(0, "lblStatus", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "lblStatus", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "lblStatus", OBJPROP_YDISTANCE, y + 5);
   ObjectSetString(0, "lblStatus", OBJPROP_TEXT, "Status: Ready");
   ObjectSetInteger(0, "lblStatus", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "lblStatus", OBJPROP_FONTSIZE, 9);
   
   y += 20;
   
   // Create spread label
   ObjectCreate(0, "lblSpread", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "lblSpread", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "lblSpread", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "lblSpread", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "lblSpread", OBJPROP_FONTSIZE, 9);
   
   y += 20;
   
   // Create stop loss label
   ObjectCreate(0, "lblStopLoss", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "lblStopLoss", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "lblStopLoss", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "lblStopLoss", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "lblStopLoss", OBJPROP_FONTSIZE, 9);
   
   y += 20;
   
   // Create previous bar label
   ObjectCreate(0, "lblPrevBar", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "lblPrevBar", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "lblPrevBar", OBJPROP_YDISTANCE, y + 5);
   ObjectSetInteger(0, "lblPrevBar", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "lblPrevBar", OBJPROP_FONTSIZE, 9);
   
   y += 20;
   
   // Create position label
   ObjectCreate(0, "lblPosition", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "lblPosition", OBJPROP_XDISTANCE, x + 5);
   ObjectSetInteger(0, "lblPosition", OBJPROP_YDISTANCE, y + 5);
   ObjectSetString(0, "lblPosition", OBJPROP_TEXT, "Position: None");
   ObjectSetInteger(0, "lblPosition", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "lblPosition", OBJPROP_FONTSIZE, 9);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update display information                                       |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
   // Get previous bar data
   previousBarHigh = iHigh(Symbol(), PERIOD_CURRENT, 1);
   previousBarLow = iLow(Symbol(), PERIOD_CURRENT, 1);
   
   // Calculate current spread in points
   int spreadPoints = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   double spreadPrice = spreadPoints * _Point;
   
   // Update spread display
   string spreadText = StringFormat("Spread: %d pts (%.5f)", spreadPoints, spreadPrice);
   ObjectSetString(0, "lblSpread", OBJPROP_TEXT, spreadText);
   
   // Update stop loss display
   string slText = StringFormat("Stop Loss: %s", 
                                StopLossPrice > 0 ? DoubleToString(StopLossPrice, _Digits) : "NOT SET");
   ObjectSetString(0, "lblStopLoss", OBJPROP_TEXT, slText);
   
   // Update previous bar display
   string prevBarText = StringFormat("Prev Bar: H=%.5f L=%.5f", previousBarHigh, previousBarLow);
   ObjectSetString(0, "lblPrevBar", OBJPROP_TEXT, prevBarText);
   
   // Update position info
   string positionText = GetPositionInfo();
   ObjectSetString(0, "lblPosition", OBJPROP_TEXT, positionText);
   
   // Update status
   if(HasOpenPosition())
   {
      ObjectSetString(0, "lblStatus", OBJPROP_TEXT, "Status: Position Open");
      ObjectSetInteger(0, "lblStatus", OBJPROP_COLOR, clrBlue);
   }
   else if(StopLossPrice <= 0)
   {
      ObjectSetString(0, "lblStatus", OBJPROP_TEXT, "Status: Set Stop Loss");
      ObjectSetInteger(0, "lblStatus", OBJPROP_COLOR, clrRed);
   }
   else
   {
      ObjectSetString(0, "lblStatus", OBJPROP_TEXT, "Status: Ready");
      ObjectSetInteger(0, "lblStatus", OBJPROP_COLOR, clrBlack);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Get position information                                         |
//+------------------------------------------------------------------+
string GetPositionInfo()
{
   if(HasOpenPosition())
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(positionInfo.SelectByIndex(i))
         {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == Symbol())
            {
               ENUM_POSITION_TYPE posType = positionInfo.PositionType();
               double profit = positionInfo.Profit();
               double volume = positionInfo.Volume();
               string direction = (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
               return StringFormat("Position: %s %.2f lots P/L: $%.2f", direction, volume, profit);
            }
         }
      }
   }
   return "Position: None";
}

//+------------------------------------------------------------------+
//| Check if we have an open position                                |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == Symbol())
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                            |
//+------------------------------------------------------------------+
double CalculatePositionSize(ENUM_ORDER_TYPE orderType, double entryPrice)
{
   if(PreferredRisk <= 0) 
   {
      Print("Error: Preferred risk must be positive");
      return 0;
   }
   
   if(StopLossPrice <= 0)
   {
      Print("Error: Stop loss must be set first");
      return 0;
   }
   
   // Calculate stop distance in points
   double stopDistancePoints;
   if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
   {
      stopDistancePoints = (entryPrice - StopLossPrice) / _Point;
   }
   else if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
   {
      stopDistancePoints = (StopLossPrice - entryPrice) / _Point;
   }
   else
   {
      Print("Error: Invalid order type for position calculation");
      return 0;
   }
   
   if(stopDistancePoints <= 0) 
   {
      Print("Error: Stop distance must be positive");
      return 0;
   }
   
   // Calculate point value
   double pointValue = CalculatePointValue();
   
   if(pointValue <= 0)
   {
      Print("Error: Invalid point value calculated");
      return 0;
   }
   
   // Calculate lots needed
   double lots = PreferredRisk / (stopDistancePoints * pointValue);
   
   // Apply lot size constraints
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   // Normalize to step
   if(lotStep > 0)
      lots = MathFloor(lots / lotStep) * lotStep;
   
   // Apply min/max
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Calculate point value for current symbol                         |
//+------------------------------------------------------------------+
double CalculatePointValue()
{
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   
   if(tickSize > 0)
   {
      return tickValue * (_Point / tickSize);
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Validate spread conditions                                       |
//+------------------------------------------------------------------+
bool ValidateSpread(double riskDistance)
{
   if(riskDistance <= 0) 
   {
      Print("Error: Invalid risk distance for spread validation");
      return false;
   }
   
   int spreadPoints = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   double riskPoints = riskDistance / _Point;
   double tpPoints = riskPoints * RiskMultiplier;
   
   if(tpPoints <= 0) 
   {
      Print("Error: Invalid take profit distance");
      return false;
   }
   
   double spreadPercent = (spreadPoints / tpPoints) * 100.0;
   
   if(spreadPercent > MaxSpreadPercent)
   {
      Print("Spread too high: ", spreadPercent, "% > ", MaxSpreadPercent, "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Place Buy Limit order                                            |
//+------------------------------------------------------------------+
void PlaceBuyLimitOrder()
{
   // Check stop loss is set
   if(StopLossPrice <= 0)
   {
      Print("Error: Stop loss must be set in input parameters");
      return;
   }
   
   // Check if already have position
   if(HasOpenPosition())
   {
      Print("Cannot place order: Already have open position");
      return;
   }
   
   // Calculate spread
   double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * _Point;
   
   // Calculate entry price (previous low + spread)
   double entryPrice = previousBarLow + spread;
   double slPrice = StopLossPrice;
   
   // Validate SL position
   if(slPrice >= entryPrice)
   {
      Print("Error: Stop loss must be below entry for BUY LIMIT");
      return;
   }
   
   // Calculate TP (entry + (Distance to SL * RiskMultiplier))
   double distanceToSL = entryPrice - slPrice;
   double tpPrice = entryPrice + (distanceToSL * RiskMultiplier);
   
   // Validate spread
   if(!ValidateSpread(distanceToSL))
      return;
   
   // Calculate position size
   double lots = CalculatePositionSize(ORDER_TYPE_BUY_LIMIT, entryPrice);
   if(lots <= 0) return;
   
   // Place the order
   entryPrice = NormalizeDouble(entryPrice, _Digits);
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);
   
   Print("RREA - Placing BUY LIMIT at previous bar low + spread: ", entryPrice, 
         " SL: ", slPrice, 
         " TP: ", tpPrice,
         " Lots: ", lots);
   
   // Correct parameter order for BuyLimit
   if(!trade.BuyLimit(lots, entryPrice, Symbol(), slPrice, tpPrice, ORDER_TIME_GTC, 0, TradeComment))
   {
      Print("Failed to place BUY LIMIT. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Place Sell Limit order                                           |
//+------------------------------------------------------------------+
void PlaceSellLimitOrder()
{
   // Check stop loss is set
   if(StopLossPrice <= 0)
   {
      Print("Error: Stop loss must be set in input parameters");
      return;
   }
   
   // Check if already have position
   if(HasOpenPosition())
   {
      Print("Cannot place order: Already have open position");
      return;
   }
   
   // Calculate spread
   double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * _Point;
   
   // Calculate entry price (previous bar high)
   double entryPrice = previousBarHigh;
   double slPrice = StopLossPrice;
   
   // Validate SL position
   if(slPrice <= entryPrice)
   {
      Print("Error: Stop loss must be above entry for SELL LIMIT");
      return;
   }
   
   // Calculate TP (entry - ((Distance to SL * RiskMultiplier) + Spread))
   double distanceToSL = slPrice - entryPrice;
   double tpPrice = entryPrice - (distanceToSL * RiskMultiplier) - spread;
   
   // Validate spread
   if(!ValidateSpread(distanceToSL))
      return;
   
   // Calculate position size
   double lots = CalculatePositionSize(ORDER_TYPE_SELL_LIMIT, entryPrice);
   if(lots <= 0) return;
   
   // Place the order
   entryPrice = NormalizeDouble(entryPrice, _Digits);
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);
   
   Print("RREA - Placing SELL LIMIT at previous bar high: ", entryPrice, 
         " SL: ", slPrice, 
         " TP: ", tpPrice,
         " Lots: ", lots);
   
   // Correct parameter order for SellLimit
   if(!trade.SellLimit(lots, entryPrice, Symbol(), slPrice, tpPrice, ORDER_TIME_GTC, 0, TradeComment))
   {
      Print("Failed to place SELL LIMIT. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Place Buy Stop order                                             |
//+------------------------------------------------------------------+
void PlaceBuyStopOrder()
{
   // Check stop loss is set
   if(StopLossPrice <= 0)
   {
      Print("Error: Stop loss must be set in input parameters");
      return;
   }
   
   // Check if already have position
   if(HasOpenPosition())
   {
      Print("Cannot place order: Already have open position");
      return;
   }
   
   // Calculate spread
   double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * _Point;
   
   // Calculate entry price (previous high + 1 tick + spread)
   double entryPrice = previousBarHigh + _Point + spread;
   double slPrice = StopLossPrice;
   
   // Validate SL position
   if(slPrice >= entryPrice)
   {
      Print("Error: Stop loss must be below entry for BUY STOP");
      return;
   }
   
   // Calculate TP (previous high + 1 tick + (Distance to SL * RiskMultiplier))
   double distanceToSL = entryPrice - slPrice;
   double tpPrice = previousBarHigh + _Point + (distanceToSL * RiskMultiplier);
   
   // Validate spread
   if(!ValidateSpread(distanceToSL))
      return;
   
   // Calculate position size
   double lots = CalculatePositionSize(ORDER_TYPE_BUY_STOP, entryPrice);
   if(lots <= 0) return;
   
   // Place the order
   entryPrice = NormalizeDouble(entryPrice, _Digits);
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);
   
   Print("RREA - Placing BUY STOP at previous bar high + 1 tick + spread: ", entryPrice, 
         " SL: ", slPrice, 
         " TP: ", tpPrice,
         " Lots: ", lots);
   
   // Correct parameter order for BuyStop
   if(!trade.BuyStop(lots, entryPrice, Symbol(), slPrice, tpPrice, ORDER_TIME_GTC, 0, TradeComment))
   {
      Print("Failed to place BUY STOP. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Place Sell Stop order                                            |
//+------------------------------------------------------------------+
void PlaceSellStopOrder()
{
   // Check stop loss is set
   if(StopLossPrice <= 0)
   {
      Print("Error: Stop loss must be set in input parameters");
      return;
   }
   
   // Check if already have position
   if(HasOpenPosition())
   {
      Print("Cannot place order: Already have open position");
      return;
   }
   
   // Calculate spread
   double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * _Point;
   
   // Calculate entry price (previous low - 1 tick)
   double entryPrice = previousBarLow - _Point;
   double slPrice = StopLossPrice;
   
   // Validate SL position
   if(slPrice <= entryPrice)
   {
      Print("Error: Stop loss must be above entry for SELL STOP");
      return;
   }
   
   // Calculate TP (entry - ((Distance to SL * RiskMultiplier) + Spread))
   double distanceToSL = slPrice - entryPrice;
   double tpPrice = entryPrice - (distanceToSL * RiskMultiplier) - spread;
   
   // Validate spread
   if(!ValidateSpread(distanceToSL))
      return;
   
   // Calculate position size
   double lots = CalculatePositionSize(ORDER_TYPE_SELL_STOP, entryPrice);
   if(lots <= 0) return;
   
   // Place the order
   entryPrice = NormalizeDouble(entryPrice, _Digits);
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);
   
   Print("RREA - Placing SELL STOP at previous bar low - 1 tick: ", entryPrice, 
         " SL: ", slPrice, 
         " TP: ", tpPrice,
         " Lots: ", lots);
   
   // Correct parameter order for SellStop
   if(!trade.SellStop(lots, entryPrice, Symbol(), slPrice, tpPrice, ORDER_TIME_GTC, 0, TradeComment))
   {
      Print("Failed to place SELL STOP. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Cancel all pending orders                                        |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
{
   int ordersCanceled = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong orderTicket = OrderGetTicket(i);
      if(orderTicket > 0)
      {
         if(orderInfo.Select(orderTicket))
         {
            if(orderInfo.Magic() == MagicNumber && orderInfo.Symbol() == Symbol())
            {
               ENUM_ORDER_TYPE orderType = orderInfo.OrderType();
               if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT ||
                  orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP)
               {
                  if(trade.OrderDelete(orderTicket))
                  {
                     ordersCanceled++;
                  }
               }
            }
         }
      }
   }
   
   if(ordersCanceled > 0)
   {
      Print("Cancelled ", ordersCanceled, " pending orders");
   }
}

//+------------------------------------------------------------------+
//| OnTrade event handler                                            |
//+------------------------------------------------------------------+
void OnTrade()
{
   // When an order is filled (position opened), cancel all pending orders
   if(HasOpenPosition())
   {
      CancelAllPendingOrders();
      Print("Position opened, cancelled all pending orders");
   }
}