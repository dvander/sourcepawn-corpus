#pragma semicolon 1
#include <sourcemod> 
#include <sdktools> 
#include <sdkhooks> 
#include <clientprefs>

#include <zombiereloaded>

public Plugin:myinfo =
{
	name = "ZR HIDE PLAYER CS:GO",
	author = "SHUFEN.jp",
	description = "",
	version = "1.0",
	url = ""
};

bool:g_bHide[MAXPLAYERS+1][MAXPLAYERS+1]; 
bool:g_hide[MAXPLAYERS+1] = {false,...};
bool:g_hideoptions[MAXPLAYERS+1] = {false,...};


Handle:SecondTimers[MAXPLAYERS+1];

Handle:HidePlayer = INVALID_HANDLE;
char g_hideplayer[MAXPLAYERS+1][8];


//Handle g_hPluginEnabled = INVALID_HANDLE;
//bool g_bPluginEnabled;


public OnPluginStart() 
{
	
	HidePlayer = RegClientCookie("zr hide player", "", CookieAccess_Private);
	
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnSpawn);
	RegConsoleCmd("sm_hide", Comando);
	RegConsoleCmd("sm_unhide", Comando2);
	
	HookConVarChange(FindConVar("sv_disable_immunity_alpha"), Changed);
	
	SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
	

}


public Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(cvar, 1);
}


public OnClientCookiesCached(client)
{
	GetClientCookie(client, HidePlayer, g_hideplayer[client], 8);
}


public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!ZR_IsClientHuman(client)) return;
	
	
	if(g_hideoptions[client] || (StrEqual(g_hideplayer[client], "true")))
	{
		FakeClientCommand(client, "say  /hide");
	}
}




public Action:Comando(client, args)
{
	
	//reghook[client] = false;
	
	
	if (SecondTimers[client] != INVALID_HANDLE)
	{
		PrintToChat(client, "\x04 \x03[HIDE] \x04You \x05already using \x04Hide Function, Type \x07!unhide \x04for Disable");
		return Plugin_Handled;
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientHuman(client))
	{
		g_hide[client] = true;
		g_hideoptions[client] = true;
		
		SecondTimers[client] = CreateTimer(1.5, Pasar, client, TIMER_REPEAT);
		
		FormatEx(g_hideplayer[client], 8, "true" ,g_hideplayer[client]);
		
		PrintToChat(client, "\x04 \x03[HIDE] %s" ,g_hide[client]?" \x04Hide Function is \x02Enabled\x04, Type \x07!unhide \x04for Disable":"\x06Hide Function is \x02Disabled\x06, Type \x07!hide \x06for Enable");
	}
	else
	{
		PrintToChat(client, "\x04 \x03[HIDE] \x04You can use \x07!hide \x04only at Human");
	}
	
	
	return Plugin_Handled;
}

public Action:Comando2(client, args)
{
	g_hide[client] = false;
	g_hideoptions[client] = false;
	
	if (SecondTimers[client] != INVALID_HANDLE)
		KillTimer(SecondTimers[client]);
	SecondTimers[client] = INVALID_HANDLE;	
	
	
	PrintToChat(client, "\x04 \x03[HIDE] \x06Hide Function is \x02Disabled\x06, Type \x07!hide \x06for Enable");
	FormatEx(g_hideplayer[client], 8, "false" ,g_hideplayer[client]);
	
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	
	
	SetClientCookie(client, HidePlayer, g_hideplayer[client]);
	g_hideplayer[client] = "";
	
	
	
	if (SecondTimers[client] != INVALID_HANDLE)
		KillTimer(SecondTimers[client]);
	SecondTimers[client] = INVALID_HANDLE;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (SecondTimers[client] != INVALID_HANDLE)
	{
		KillTimer(SecondTimers[client]);
		SecondTimers[client] = INVALID_HANDLE;
	}
	
	for(new i = 1; i <= MaxClients; i++)
	{
		g_hide[client] = false;
		g_bHide[client][i] = false;
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (SecondTimers[client] != INVALID_HANDLE)
	{
		KillTimer(SecondTimers[client]);
		SecondTimers[client] = INVALID_HANDLE;
	}
	
	for(new i = 1; i <= MaxClients; i++)
	{
		g_bHide[client][i] = false;
	}
	
	g_hide[client] = false;
}

public Action:Pasar(Handle:timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			CheckClientOrg(i);
	}
}

CheckClientOrg(Client) 
{
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(Client, MedicOrigin);
	
	for (new X = 1; X <= MaxClients; X++)
	{
		if(X != Client && IsClientInGame(X) && IsPlayerAlive(X) && ZR_IsClientHuman(X))
		{
			GetClientAbsOrigin(X, TargetOrigin);
			Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
			//PrintToChatAll("test")
			if(Distance <= 100.0)
				g_bHide[Client][X] = true;
			else
			g_bHide[Client][X] = false;
			
		}
	}
}

public OnClientPutInServer(client) 
{
	g_hideoptions[client] = false;
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	
	
	
	
	for(new i = 1; i <= MaxClients; i++)
		g_bHide[client][i] = false; 
}



public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			if (SecondTimers[client] != INVALID_HANDLE)
			{
				KillTimer(SecondTimers[client]);
			}
			SecondTimers[client] = INVALID_HANDLE;
		}
	}
}

AdjustAlpha(entity)
{
	SetEntityRenderMode (entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 255, 255, 255, 80);
}

public Action:Hook_SetTransmit(client1, client2) 
{ 
	new entity = (client1 != client2 && g_hide[client2] && g_bHide[client1][client2]);
	AdjustAlpha(entity);
	
	return Plugin_Continue; 
}

	