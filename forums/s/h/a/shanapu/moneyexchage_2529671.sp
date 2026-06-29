#include <sourcemod> 
#include <sdktools> 
#include <cstrike> 
#include <store> 

ConVar gc_fRate; 
ConVar gc_iMaxExchange; 
int g_iAmount[MAXPLAYERS+1] = 0;

public Plugin myinfo =  
{ 
    name = "Money Exchange", 
    author = "shanapu", 
    description = "exchange game money to store credits", 
    version = "1.1", 
    url = "https://github.com/shanapu/" 
}; 

public void OnPluginStart() 
{ 
    RegConsoleCmd("sm_exchange", Command_Exchange) 
    gc_fRate = CreateConVar("sm_exchange_rate", "0.5", "1 game dollar are x store credits");
    gc_iMaxExchange = CreateConVar("sm_exchange_limit", "5000", "how many credits can be get in exchange", _, true, 1.0); 
} 

public Action Command_Exchange(int client, int args) 
{ 
    if (client == 0) 
    { 
        ReplyToCommand(client, "%t", "Command is in-game only"); 
        return Plugin_Handled; 
    } 

    if (args < 1) 
    { 
        ReplyToCommand(client, "Use: sm_exchange [amount]"); 
        return Plugin_Handled; 
    }

    char arg[10]; 
    GetCmdArg(1, arg, sizeof(arg)); 
    int amount = StringToInt(arg); 
    int money = GetEntProp(client, Prop_Send, "m_iAccount") 

    if (amount > money) 
    { 
        ReplyToCommand(client, "Not enough money"); 
        return Plugin_Handled; 
    }
    
    float fAmount = float(amount) * gc_fRate.FloatValue; 
    int newamount = RoundToZero(fAmount); 
    
    if(g_iAmount[client] + newamount >= gc_iMaxExchange.IntValue)
    {
        ReplyToCommand(client, "Reached the exchange limit of %i credits. Try smaller value", gc_iMaxExchange.IntValue); 
        return Plugin_Handled; 
    }
     
    SetEntProp(client, Prop_Send, "m_iAccount", money - amount); 


    g_iAmount[client] = g_iAmount[client] + newamount;
    Store_SetClientCredits(client, Store_GetClientCredits(client)+newamount); 
     
    PrintToChat(client, "Exchange: you got %d store credits for %d dollar", newamount, amount); 

    return Plugin_Handled; 
}