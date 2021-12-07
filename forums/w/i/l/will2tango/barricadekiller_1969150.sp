#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.20"

/*ChangeLog
1.00	Release
1.10	Totals for Admin
1.20	Reset Options
*/

#define SURVIVOR	2
#define ZOMBIE		3
#define READY		4

public Plugin:myinfo =
{
	name = "ZPS Barricade Killer",
	author = "Will2Tango",
	description = "Notification when a Survivor Kills a Barricade.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

//Cvars
new Handle:hEnabled = INVALID_HANDLE;
new Handle:hReset = INVALID_HANDLE;

new bool:gEnabled = true;
new gReset = 1;

//Player Vars
new cadeKillCount[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{
	//Cvars
	CreateConVar("zps_barricadekiller_version", PLUGIN_VERSION, "ZPS Barricade Killer Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnabled = CreateConVar("sm_barricadekiller_enabled", "1", "Turns Barricade Killer Off/On. (1/0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hReset = CreateConVar("sm_barricadekiller_reset", "2", "When to reset Running Totals, 0=never, 1=map, 2=round.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	HookConVarChange(hEnabled, ConVarChange);
	HookConVarChange(hReset, ConVarChange);
	
	//Hooks
	HookEvent("break_prop", SomethingBroke);
	HookEvent("player_spawn", PlayerSpawn);
	
	//Translations
	LoadTranslations("barricadekiller.phrases");
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	gEnabled = GetConVarBool(hEnabled);
	gReset = GetConVarInt(hReset);
}

public OnMapEnd()
{
	if (gEnabled && gReset == 1)
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				cadeKillCount[i] = 0;
			}
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gEnabled && gReset == 2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetClientTeam(client);
		
		if (team == READY)
		{
			cadeKillCount[client] = 0;
		}
	}
}

public Action:SomethingBroke(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (!gEnabled)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if (team == SURVIVOR)
	{
		new ent = GetEventInt(event, "entindex");
		
		decl String:model[128];
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
		
		if (StrContains(model, "/barricades/", false) != -1)
		{
			cadeKillCount[client]++;
			
			new String:killerName[MAX_NAME_LENGTH];
			GetClientName(client, killerName, sizeof(killerName));
			
			new total = cadeKillCount[client];
			new flags;
			
			for (new i = 1; i < MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if (i == client)
					{
						PrintToChat(i, "[SM] %t", "You");
					}
					else
					{
						flags = GetUserFlagBits(i);
						
						if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC)
						{
							PrintToChat(i, "[SM] %t", "Admin", killerName, total);
						}
						else if (GetClientTeam(i) == SURVIVOR)
						{
							PrintToChat(i, "[SM] %t", "All", killerName);
						}
					}
				}
			}
			
			LogMessage("%L Broke a Baricade! (%i)", client, total);
		}
	}
}