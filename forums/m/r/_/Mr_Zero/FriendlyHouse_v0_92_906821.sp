#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"0.92"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY
#define HIGH_FF_TOLERANCE	1000000
#define AUTOPICKUP_AREA		350
#define AUTOPICKUP_INTERVAL	0.5

new Handle:g_hFH_Enabled;
new Handle:g_hFH_VersusOnly;
new Handle:g_hFH_AutoPickupKit;
new Handle:g_hFH_AutoPickupPistol;
new Handle:g_hFriendlyFireTolerance_Convar;
new bool:g_bGameHaveBegun;
new bool:g_bIsEnabled;

public Plugin:myinfo = 
{
	name = "Friendly House",
	author = "Mr. Zero",
	description = "Disables friendly fire while survivors is still in safehouse, also includes other features such as auto pick up of medkits.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=101064"
}

public OnPluginStart()
{
	g_hFH_Enabled 			= CreateConVar("l4d_fh_enable"			,"1","Sets whether the plugin is active.",CVAR_FLAGS);
	g_hFH_VersusOnly 		= CreateConVar("l4d_fh_versusonly"		,"1","Sets whether its only in Versus the plugin is active. If 0 then it will also be active in Coop.",CVAR_FLAGS);
	g_hFH_AutoPickupKit 	= CreateConVar("l4d_fh_autopickupkit"	,"1","Sets whether the plugin will make the survivors automaticly pick up medkits in safe house (only working in versus).",CVAR_FLAGS);
	g_hFH_AutoPickupPistol 	= CreateConVar("l4d_fh_autopickuppistol","1","Sets whether the plugin will make the survivors automaticly pick up a 2nd pistol in safe house, if available (only working in versus).",CVAR_FLAGS);
	CreateConVar("l4d_fh_version", PLUGIN_VERSION, "Friendly House Version", CVAR_FLAGS|FCVAR_NOTIFY);
	
	AutoExecConfig(true,"FriendlyHouse");
	
	g_hFriendlyFireTolerance_Convar = FindConVar("survivor_ff_tolerance");
	
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("door_open", Event_OpenCheckPointDoor);
	HookEvent("round_start", Event_RoundStart);
	
	HookConVarChange(g_hFH_Enabled, ConvarChanged_Enabled);
}

CheckPluginDependencies()
{
	if(GetConVarBool(g_hFH_Enabled) && (IsGameMode("versus") || (IsGameMode("coop") && !GetConVarBool(g_hFH_VersusOnly))))
	{
		g_bIsEnabled = true;
		return;
	}
	g_bIsEnabled = false;
}

public OnMapStart(){CheckPluginDependencies();}

public Action:Event_OpenCheckPointDoor(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bGameHaveBegun || !g_bIsEnabled){return;}
	new bool:wasCheckpointDoor = GetEventBool(event,"checkpoint");
	if(wasCheckpointDoor){g_bGameHaveBegun = true;ResetConVar(g_hFriendlyFireTolerance_Convar);}
}

public Action:Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled){return;}
	g_bGameHaveBegun = true;
	ResetConVar(g_hFriendlyFireTolerance_Convar);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled){return;}
	g_bGameHaveBegun = false;
	SetConVarInt(g_hFriendlyFireTolerance_Convar,HIGH_FF_TOLERANCE,true,false);
	if(IsGameMode("versus"))
	{
		if(GetConVarBool(g_hFH_AutoPickupKit)){CreateTimer(AUTOPICKUP_INTERVAL,AutoPickupKitTimer,INVALID_HANDLE,TIMER_REPEAT);}
		if(GetConVarBool(g_hFH_AutoPickupPistol)){CreateTimer(AUTOPICKUP_INTERVAL,AutoPickupPistolTimer,INVALID_HANDLE,TIMER_REPEAT);}
	}
}

public Action:AutoPickupPistolTimer(Handle:timer)
{
	if(AutoPickupPistol()){return Plugin_Stop;}
	return Plugin_Continue;
}

public Action:AutoPickupKitTimer(Handle:timer)
{
	if(AutoPickupKit()){return Plugin_Stop;}
	return Plugin_Continue;
}

bool:AutoPickupPistol()
{
	new surClient = FindValidSurvivor();
	
	if(surClient == 0){return false;}
	
	new Float:surOrigin[3];
	GetClientAbsOrigin(surClient,surOrigin);
	
	new ent, count;
	while ((ent = FindEntityByClassnameNearby("weapon_pistol_spawn",surOrigin,AUTOPICKUP_AREA)) != -1)
	{
		RemoveEdict(ent);
		count ++;
	}
	
	if(count == 0){return true;}
	
	GiveSurvivorItems("weapon_pistol",GetConVarInt(FindConVar("survivor_limit")));
	
	return true;
}

bool:AutoPickupKit()
{
	new surClient = FindValidSurvivor();
	
	if(surClient == 0){return false;}
	
	new Float:surOrigin[3];
	GetClientAbsOrigin(surClient,surOrigin);
	
	new ent, count, maxcount = GetConVarInt(FindConVar("survivor_limit"));
	while ((ent = FindEntityByClassnameNearby("weapon_first_aid_kit_spawn",surOrigin,AUTOPICKUP_AREA)) != -1)
	{
		if(count == maxcount){break;}
		RemoveEdict(ent);
		count ++;
	}
	
	if(count == 0){return true;}
	
	GiveSurvivorItems("weapon_first_aid_kit",count);
	
	return true;
}

FindEntityByClassnameNearby(String:classname[],const Float:origin[3],const maxDistant)
{
	new curent = -1, prevent = 0;
	while ((curent = FindEntityByClassname(curent, classname)) != -1)
	{
		decl Float:entOrigin[3];
		GetEntPropVector(curent,Prop_Send,"m_vecOrigin",entOrigin);
		if(RoundToNearest(GetVectorDistance(entOrigin,origin)) > maxDistant){continue;}
		if(prevent){return prevent;}
		prevent = curent;
	}
	if(prevent){return prevent;}
	return -1;
}

FindValidSurvivor()
{
	for(new client;client<MaxClients;client++)
	{
		if(IsValidSurvivor(client))
		{
			return client;
		}
	}
	return 0;
}

GiveSurvivorItems(String:item[],maxcount)
{
	new count, String:command[] = "give", flags = GetCommandFlags(command);
	for(new client;client<MaxClients;client++)
	{
		if(IsValidSurvivor(client))
		{
			if(count == maxcount){break;}
			SetCommandFlags(command,flags^FCVAR_CHEAT);
			FakeClientCommand(client, "%s %s",command,item);
			SetCommandFlags(command, flags);
			count ++;
		}
	}
}

bool:IsValidSurvivor(client)
{
	if(client == 0)
		return false;
	
	if(!IsClientConnected(client))
		return false;
	
	if(!IsClientInGame(client))
		return false;
	
	if(GetClientTeam(client) != 2)
		return false;
	
	return true;
}

bool:IsGameMode(String:GameModeName[16])
{
	new String:GameMode[sizeof(GameModeName)];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (StrContains(GameMode, GameModeName, false) != -1){return true;}
	return false;
}

public ConvarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[]){CheckPluginDependencies();}