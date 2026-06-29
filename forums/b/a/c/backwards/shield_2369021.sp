#pragma semicolon 1
 
#include <sourcemod>
 
public Plugin:myinfo =
{
    name = "shield",
    author = "1337norway",
    description = "Allows Clients To Buy Temp Shields.",
    version = "1.0",
    url = "http://steamcommunity.com/id/EvGshuter/"
}
 
ConVar g_cvShieldMin, g_cvShieldTime;
 
public OnPluginStart()
{
        g_cvShieldMin = CreateConVar("sm_shield_min_balance", "8000", "The minimum balance a player can have in order to buy a shield.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
        g_cvShieldTime = CreateConVar("sm_shield_time", "15.0", "The time a shield lasts before it expires.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
       
        RegConsoleCmd("protect", ProtectCMD);
}
 
public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
        for(new i = 1;i < MaxClients; i++)
        {
                if(!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || (GetClientTeam(i) != 3 && GetClientTeam(i) != 2))
                        continue;
                       
                SetEntProp(i, Prop_Data, "m_takedamage", 2);
        }
}
 
public Action:ProtectCMD(client, args)
{
        if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || (GetClientTeam(client) != 3 && GetClientTeam(client) != 2))
                return Plugin_Handled;
   
        if(GetEntProp(client, Prop_Data, "m_takedamage") == 1)
        {
                PrintToChat(client, "You already have a Shield!");
                return Plugin_Handled;
        }
       
        new balance = GetEntProp(client, Prop_Send, "m_iAccount");
        if(balance < g_cvShieldMin.IntValue)
        {
                PrintToChat(client, "Sorry, you don't have $%i to buy a Shield!", g_cvShieldMin.IntValue);
                return Plugin_Handled;
        }
       
        balance -= g_cvShieldMin.IntValue;
       
        SetEntProp(client, Prop_Send, "m_iAccount", balance);
        SetEntProp(client, Prop_Data, "m_takedamage", 1);
       
        CreateTimer(g_cvShieldTime.FloatValue, Timer_RemoveGod, client);
       
        PrintToChat(client, "You've bought a Shield!");
       
        return Plugin_Continue;
}
 
public Action:Timer_RemoveGod(Handle:timer, any:client)
{
        if(!IsClientConnected(client) || !IsClientInGame(client))
                return Plugin_Stop;
 
        SetEntProp(client, Prop_Data, "m_takedamage", 2);
        PrintToChat(client, "Your Shield has ran out!");
       
        return Plugin_Stop;
}