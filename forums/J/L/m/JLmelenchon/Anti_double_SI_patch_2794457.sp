#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:SmokerAlive = false;
new bool:HunterAlive = false;

bool WasFirstSmoker[MAXPLAYERS + 1] = false;
bool WasFirstHunter[MAXPLAYERS + 1] = false;

public Plugin myinfo = 
{
	name = "Anti double SI patch",
	author = "Lunatix",
	description = "Fix the problem when there are double smoker/hunter",
	version = "1.4",
	url = "http"
};

public void OnPluginStart()
{
	HookEvent("player_disconnect", playerDisconnect);
	HookEvent("player_bot_replace", BotReplacedPlayer);
	HookEvent("player_spawn", PlayerSpawn_Event, EventHookMode_PostNoCopy);
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEndResetFirstSI, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client > 0 && IsClientInGame(client))
        {
            WasFirstSmoker[client] = false;
            WasFirstHunter [client] = false;
            SmokerAlive = false;
            HunterAlive = false;
            //PrintToChatAll("[Debug] First hunter and smoker bools reset for every client.");
        }
    }
}

public void Event_RoundEndResetFirstSI(Event hEvent, const char[] name, bool dontBroadcast)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client > 0 && IsClientInGame(client))
        {
            WasFirstSmoker[client] = false;
            WasFirstHunter [client] = false;
            SmokerAlive = false;
            HunterAlive = false;
            //PrintToChatAll("[Debug] First hunter and smoker bools reset for every client.");
        }
    }
}

public playerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients) return;
    
    if (WasFirstSmoker[client] == true)
    {
        WasFirstSmoker[client] = false;
        SmokerAlive = false;
        //PrintToChatAll("[Debug] First smoker %N disconnected", client);
    }
    
    if (WasFirstHunter[client] == true)
    {
        WasFirstHunter [client] = false;
        HunterAlive = false;
        //PrintToChatAll("[Debug] First hunter %N disconnected", client);
    }
    
}

public void BotReplacedPlayer(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("player"));
    int iBot = GetClientOfUserId(hEvent.GetInt("bot"));
    
    if (client > 0 && WasFirstSmoker[client] == true)
    {
        //SmokerAlive = true;
        WasFirstSmoker[client] = false;
        //PrintToChatAll("[Debug] First smoker %N becomes tank and is replaced by bot", client);
    }
    
    if (client > 0 && WasFirstHunter[client] == true)
    {
        //HunterAlive = true;
        WasFirstHunter[client] = false;
        //PrintToChatAll("[Debug] First hunter %N becomes tank and is replaced by bot", client);
    }
    
    if (GetEntProp(iBot, Prop_Send, "m_zombieClass") == 1) //change is so it is at the same level than player
    {
        WasFirstSmoker[iBot] = true;
        //SmokerAlive = true;
        //PrintToChatAll("[Debug] Bot is now the new first smoker");
    }
    
    if (GetEntProp(iBot, Prop_Send, "m_zombieClass") == 3)
    {
        WasFirstHunter[iBot] = true;
        //HunterAlive = true;
        //PrintToChatAll("[Debug] Bot is now the new first hunter");
    }
}

public void PlayerSpawn_Event(Event event, const char[] eName, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client <= 0 || client > MaxClients) return;
    
    if (IsClientInGame(client) && GetClientTeam(client) == 3)
    {
        if (GetEntProp(client, Prop_Send, "m_zombieClass") == 1)
        {
            if (SmokerAlive == false)
		    {
		        WasFirstSmoker[client] = true;
		        SmokerAlive = true;
		        //PrintToChatAll("[Debug] %N is now the new first smoker", client);
		    }
		    
            if (SmokerAlive == true && IsFakeClient(client))
		    {
		        CreateTimer(0.1, TimerCheckDoubleSmoker);
		    }
        }
        
        if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3)
        {
            if (HunterAlive == false)
		    {
		        WasFirstHunter [client] = true;
		        HunterAlive = true;
		        //PrintToChatAll("[Debug] %N is now the new first hunter", client);
		    }
		    
            if (HunterAlive == true && IsFakeClient(client))
		    {
		        CreateTimer(0.1, TimerCheckDoubleHunter);
		    }
        }
    }
    
}

public Action:TimerCheckDoubleSmoker(Handle:timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client <= 0 || client > MaxClients) return;
        
        if (IsClientConnected(client) && IsFakeClient(client) && WasFirstSmoker[client] == false)
		{
		    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 1)
		    {
		        if (L4D2_IsInfectedBusy(client) == false)
		        {
		            KickClient(client);
		            //PrintToChatAll("[Debug] Double smoker detected, bot killed as he was not first.");
		        }
		    }
		}
    }
}

public Action:TimerCheckDoubleHunter(Handle:timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (client <= 0 || client > MaxClients) return;
        
        if (IsClientConnected(client) && IsFakeClient(client) && WasFirstHunter[client] == false)
		{
		    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3)
		    {
		        if (L4D2_IsInfectedBusy(client) == false)
		        {
		            KickClient(client);
		            //PrintToChatAll("[Debug] Double hunter detected, bot killed as he was not first.");
		        }
		    }
		}
    }
}

public void PlayerDeath_Event(Event event, const char[] eName, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3)
    {
        if (GetEntProp(client, Prop_Send, "m_zombieClass") == 1)
        {
            if (WasFirstSmoker[client] == true)
            {
                WasFirstSmoker[client] = false;
                SmokerAlive = false;
                //PrintToChatAll("[Debug] First smoker %N is now dead, waiting for next one.", client);
            }
        }
        
        if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3)
        {
            if (WasFirstHunter[client] == true)
            {
                WasFirstHunter [client] = false;
                HunterAlive = false;
                //PrintToChatAll("[Debug] First hunter %N is now dead, waiting for next one.", client);
            }
        }
    }
}

stock bool L4D2_IsInfectedBusy(int client)
{
    return GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
}