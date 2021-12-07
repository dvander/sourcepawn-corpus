#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.3"

new g_iKnifeCount[MAXPLAYERS+1];
new bool:lateLoad;
new Handle:knifelimithandle = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Knife Limit",
	author = "TeC, tooti",
	description = "1 Knife per round",
	version = PLUGIN_VERSION,
	url = "sourceserver.info"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoad = late;
}

public OnPluginStart()
{
	CreateConVar("sm_knifelimit_version", PLUGIN_VERSION, "Knife Limit: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	knifelimithandle = CreateConVar("sm_knifelimit", "1", "Knife Limit");

	HookEvent("round_start", Event_RoundStart);

	if (lateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}		
}

public OnClientPutInServer(client)
{
	g_iKnifeCount[client] = 0;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (client > 0 && attacker > 0 && attacker <= MaxClients && client != attacker)
	{
		if (GetClientTeam(client) != GetClientTeam(attacker))
		{
			new String:sWeapon[32];
			GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
	
			if (StrEqual(sWeapon, "weapon_knife"))
			{
				new String:knifelimit[32];
				GetConVarString(knifelimithandle,knifelimit, sizeof(knifelimit));
				new knifel = StringToInt(knifelimit);
				if (g_iKnifeCount[attacker] >= knifel)
				{ 
					PrintToChat(attacker, "\x04[Knife-Limit]\x03 You can only knife once in a round");
					ForcePlayerSuicide(attacker);
					return Plugin_Handled;
				}
				else
				{
					g_iKnifeCount[attacker]++;
					PrintToChat(attacker, "\x04[Knife-Limit]\x03 You have no knife wounds anymore!");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			g_iKnifeCount[i] = 0;
	}
}