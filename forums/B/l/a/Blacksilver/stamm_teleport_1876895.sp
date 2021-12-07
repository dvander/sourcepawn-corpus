#include <sourcemod>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new v_level;

new Float:TeleportList[MAXPLAYERS + 1][3][3];

new Teleports[MAXPLAYERS + 1][3];

new timer[MAXPLAYERS + 1];
new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Teleport",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's can create Teleport Points",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	RegConsoleCmd("sm_sadd", AddTele, "Adds a new Teleporter");
	RegConsoleCmd("sm_stele", Tele, "Teleports an Player");
	
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerSpawn);
}

public OnMapStart()
{
	PrecacheModel("materials/sprites/strider_blackball.vmt", true); 
	
	for (new i=0; i <= MaxClients; i++)
	{
		Teleports[i][0] = 0;
		timer[i] = 0;
	}
}

public Action:AddTele(client, args)
{
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && IsPlayerAlive(client) && (GetClientTeam(client) == 3))
		{
			GetClientAbsAngles(client, TeleportList[client][1]);
			GetClientAbsOrigin(client, TeleportList[client][0]);
			
			Teleports[client][0] = 1;
			
			CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "TeleportAdded", LANG_SERVER);
		}
	}
	
	return Plugin_Handled;
}

public Action:Tele(client, args)
{
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && Teleports[client][0] && !timer[client] && IsPlayerAlive(client) && (GetClientTeam(client) == 3))
		{
			Teleports[client][2] = 1;
			Teleports[client][1] = createEnt(client);
		}
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (timer[i] > 0)
		{
			if (IsStammClientValid(i))
			{
				timer[i]--;
				
				if (timer[i] <= 0)
				{
					if (IsValidEntity(Teleports[i][1])) RemoveEdict(Teleports[i][1]);
					
					if (Teleports[i][2] == 1) 
					{
						TeleportEntity(i, TeleportList[i][0], TeleportList[i][1], NULL_VECTOR);
						Teleports[i][2] = 2;
						Teleports[i][1] = createEnt(i);
					}
				}
				else TeleportEntity(i, TeleportList[i][2], NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

public createEnt(client)
{
	new ent = CreateEntityByName("env_smokestack");
	
	GetClientAbsOrigin(client, TeleportList[client][2]);
	
	if (ent != -1)
	{
		DispatchKeyValue(ent, "WindSpeed", "0");
		DispatchKeyValue(ent, "WindAngle", "0");
		DispatchKeyValue(ent, "BaseSpread", "40");
		DispatchKeyValue(ent, "EndSize", "15");
		DispatchKeyValue(ent, "twist", "0");
		DispatchKeyValue(ent, "JetLength", "110");
		DispatchKeyValue(ent, "roll", "0");
		DispatchKeyValue(ent, "StartSize", "15");
		DispatchKeyValue(ent, "Rate", "250");
		DispatchKeyValue(ent, "SpreadSpeed", "15");
		DispatchKeyValue(ent, "renderamt", "255");
		DispatchKeyValue(ent, "Speed", "150");
		if (GetClientTeam(client) == 2) DispatchKeyValue(ent, "rendercolor", "255 0 0");
		else DispatchKeyValue(ent, "rendercolor", "0 0 255");
		DispatchKeyValue(ent, "InitialState", "1");
		DispatchKeyValue(ent, "angles", "0 0 0");
		DispatchKeyValue(ent, "SmokeMaterial", "sprites/strider_blackball.vmt");

		DispatchSpawn(ent);

		TeleportEntity(ent, TeleportList[client][2], NULL_VECTOR, NULL_VECTOR);
		
		timer[client] = 180;
	}
	
	return ent;
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	timer[client] = 0;
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetTeleport", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Teleport", description);
	
	Format(description, sizeof(description), "%T", "YouGetTeleport", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}