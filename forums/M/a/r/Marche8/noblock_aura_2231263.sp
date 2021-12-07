/* Changelog
* 
* v1.0
* - Init
* v1.1
* - Added CS:GO support
* - Removed morecolors
* - Added aura on spawn and freezetime end
* - Added cvars
*/

#include <sourcemod>
#include <smlib>

#define COLLISION_GROUP_DEBRIS_TRIGGER 2
#define COLLISION_GROUP_PLAYER 5
#define COLLISION_GROUP_PUSHAWAY 17

#define VERSION "1.1"

new Handle:cvarAuraRange = INVALID_HANDLE;
new Handle:cvarAuraTime = INVALID_HANDLE;
new Handle:cvarAuraNoblockTime = INVALID_HANDLE;
new Handle:cvarAuraSpawnNoblockTime = INVALID_HANDLE;
new Handle:cvarAuraRefreshRate = INVALID_HANDLE;
new Handle:cvarAuraBeamRate = INVALID_HANDLE;
new Handle:cvarAnnounceRate = INVALID_HANDLE;

enum Aura
{
	bool:AuraIgnore,
	Float:AuraEndTime,
	Float:NoBlockEndTime
}

new g_client[MAXPLAYERS+1][Aura];

new g_ioffsCollisionGroup;

new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hTimerEffect = INVALID_HANDLE;

new gGlow1;
new gHalo1;

new g_color[4];

public Plugin:myinfo = 
{
	name = "NoBlock Aura",
	author = "Zipcore, Lacrimosa99",
	description = "Spawn noblock and noblock aura",
	version = VERSION,
	url = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	CreateConVar("sm_noblock_aura_version", VERSION, "NoBlock Aura", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarAuraNoblockTime = CreateConVar("sm_noblock_aura_noblock_time", "1.0", "Give player in range this amount of time noblock.");
	cvarAuraRange = CreateConVar("sm_noblock_aura_range", "82.0", "Aura range to effect other players.");
	cvarAuraBeamRate = CreateConVar("sm_noblock_aura_beam_rate", "1.0", "Create a beacon every X seconds.");
	cvarAuraSpawnNoblockTime = CreateConVar("sm_noblock_aura_spawn_noblock_time", "10.0", "Give aura this amount of time on roundstart and playerspawn.");
	cvarAuraRefreshRate = CreateConVar("sm_noblock_aura_refresh_rate", "0.1", "Itervall to check for other players in range.");
	cvarAuraTime = CreateConVar("sm_noblock_aura_time", "10.0", "Extend time for aura command.");
	cvarAnnounceRate = CreateConVar("sm_noblock_announce_rate", "180.0", "Announce this plugin to players.");

	g_ioffsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_ioffsCollisionGroup == -1)
	{
		SetFailState("CBaseEntity:m_CollisionGroup not found");
	}
	
	HookEvent("round_freeze_end", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("say", ChatHook);
	RegConsoleCmd("say_team", ChatHook);
	
	g_color[0] = 255;
	g_color[1] = 50;
	g_color[2] = 50;
	g_color[3] = 50;
}

public OnMapStart()
{
	if(GetEngineVersion() == Engine_CSS)
	{
		gGlow1 = PrecacheModel("materials/sprites/laser.vmt", true);
		gHalo1 = PrecacheModel("materials/sprites/halo01.vmt");
	}
	else if(GetEngineVersion() == Engine_CSGO)
	{
		gGlow1 = PrecacheModel("materials/sprites/laserbeam.vmt", true);
		gHalo1 = PrecacheModel("materials/sprites/halo.vmt");
	}
	else SetFailState("Noblockaura failed: CSS and CSGO only.");
	
	if(GetConVarFloat(cvarAuraRefreshRate) > 0.0)
		g_hTimer = CreateTimer(GetConVarFloat(cvarAuraRefreshRate), Timer, _, TIMER_REPEAT);
	if(GetConVarFloat(cvarAuraBeamRate) > 0.0)
		g_hTimerEffect = CreateTimer(GetConVarFloat(cvarAuraBeamRate), TimerEffect, _, TIMER_REPEAT);
	
	if(GetConVarFloat(cvarAnnounceRate) > 0.0)
		CreateTimer(GetConVarFloat(cvarAnnounceRate), AnnounceMsg, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	// Kill Timers	
	ClearHandle(g_hTimer);
	ClearHandle(g_hTimerEffect);
}

public Action:AnnounceMsg(Handle:timer, any:client)
{
	PrintToChatAll("[Block] Type !block, !b, /block or /b to enable collision for 5 seconds.");
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:time = GetGameTime();
	
	g_client[client][AuraEndTime] = time;
	g_client[client][NoBlockEndTime] = time + GetConVarFloat(cvarAuraSpawnNoblockTime);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:time = GetGameTime();
	for(new i=1; i <= MaxClients; i++)
	{
		g_client[i][AuraEndTime] = time;
		g_client[i][NoBlockEndTime] = time + GetConVarFloat(cvarAuraSpawnNoblockTime);
	}
	PrintToChatAll("[Block] Collision enabled for %ds.", RoundToFloor(GetConVarFloat(cvarAuraSpawnNoblockTime)));
}

public Action:ChatHook(client, args)
{
	new String:line[32];
	new String:name[MAX_NAME_LENGTH];
	
	if (args > 0)
	{
		GetCmdArg(1,line,sizeof(line));
		GetClientName(client, name, sizeof(name));
		
		if (StrEqual(line, "!block", false) || StrEqual(line, "!b", false) || StrEqual(line, "/b", false) || StrEqual(line, "/block", false))
		{
			if(IsClientInGame(client))
			{
				if(IsPlayerAlive(client))
				{
					g_client[client][AuraEndTime] = GetGameTime() + GetConVarFloat(cvarAuraTime);
					PrintToChat(client, "[Block] Collision enabled for %ds.", RoundToFloor(GetConVarFloat(cvarAuraTime)));
				}
				else PrintToChat(client, "[Block] You need to be alive to use this command.");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer(Handle:timer, any:data)
{
	Refresh_Collision();
	return Plugin_Continue;
}

public Action:TimerEffect(Handle:timer, any:data)
{
	Refresh_Effect();
	return Plugin_Continue;
}

SetupBeacon(client)
{
	new Float:time = GetGameTime();
	new tempColor[4];
	
	tempColor[0] = GetRandomInt(100, 255);
	tempColor[1] = GetRandomInt(100, 255);
	tempColor[2] = GetRandomInt(100, 255);
	tempColor[3] = 50;
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	if(g_client[client][AuraEndTime] - time < 3) TE_SetupBeamRingPoint(vec, 25.0, 150.0, gGlow1, gHalo1, 0, 1, 0.5, 20.0, 0.0, g_color, 1, 0);
	else TE_SetupBeamRingPoint(vec, 25.0, 150.0, gGlow1, gHalo1, 0, 1, 0.5, 20.0, 0.0, tempColor, 1, 0);
	TE_SendToAll();
}

Refresh_Effect()
{
	new Float:time = GetGameTime();
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(g_client[i][AuraEndTime] > time)
			{
				SetupBeacon(i);
			}
		}
	}
}

Refresh_Collision()
{
	new Float:time = GetGameTime();
	
	//validate all players
	for(new i=1;i<=MaxClients;i++)
	{
		g_client[i][AuraIgnore] = false;
		
		if(!(IsClientInGame(i) && IsPlayerAlive(i)))
		{
			g_client[i][AuraIgnore] = true;
		}
	}
	
	//extend noblock
	for(new i=1;i<=MaxClients;i++)
	{
		if(g_client[i][AuraIgnore])
			continue;
		
		for(new j=1;j<=MaxClients;j++)
		{
			if(g_client[j][AuraIgnore])
				continue;
			
			if(g_client[i][AuraEndTime] > time)
			{
				if(Entity_InRange(j, i, GetConVarFloat(cvarAuraRange)))
				{
					g_client[j][NoBlockEndTime] = time + GetConVarFloat(cvarAuraNoblockTime);
				}
			}
		}
	}
	
	//set collision group
	for(new i=1;i<=MaxClients;i++)
	{
		if(g_client[i][AuraIgnore])
			continue;
		
		if(g_client[i][AuraEndTime] > time || g_client[i][NoBlockEndTime] > time)
			Client_SetNoblockable(i);
		else if(!IsPlayerStuck(i)) Client_SetBlockable(i);
		//else Client_SetPushable(i);
	}	
}

stock bool:IsPlayerStuck(client)
{
	decl Float:vOrigin[3], Float:vMins[3], Float:vMaxs[3];
	GetClientAbsOrigin(client, vOrigin);
	GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
	
	TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, FilterOnlyPlayers, client);
	return TR_DidHit();
}

public bool:FilterOnlyPlayers(entity, contentsMask, any:data)
{
	if(entity != data && entity > 0 && entity <= MaxClients)
	{
    	return true;
	}
	return false;
}

stock ClearHandle(&Handle:hndl)
{
	if(hndl != INVALID_HANDLE)
		CloseHandle(hndl);
	hndl = INVALID_HANDLE;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
	}
	else if (StrEqual(classname, "flashbang_projectile"))
	{
		SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
	}
	else if (StrEqual(classname, "smokegrenade_projectile"))
	{
		SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
	}
}

stock Client_SetNoblockable(client)
{
	if(GetEngineVersion() == Engine_CSS)
	{
		new count = 0;
		for(new i=1;i<=MaxClients;i++)
		{
			if(g_client[i][AuraIgnore])
				continue;
			
			if(!(IsClientInGame(i) && IsPlayerAlive(i)))
				continue;
			
			if(Entity_InRange(client, i, 64.0))
				count++;
		}
		
		if(count > 5)
		{
			SetEntityRenderColor(client, 255, 255, 255, 100);
		}
		else if(count > 2)
		{
			SetEntityRenderColor(client, 255, 255, 255, 150);
		}
		else SetEntityRenderColor(client, 255, 255, 255, 200);
	}
	SetEntData(client, g_ioffsCollisionGroup, COLLISION_GROUP_PLAYER, 4, true);
	
}

stock Client_SetBlockable(client)
{
	if(GetEngineVersion() == Engine_CSS)
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	SetEntData(client, g_ioffsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
}

stock Client_SetPushable(client)
{
	if(GetEngineVersion() == Engine_CSS)
	{
		SetEntityRenderColor(client, 255, 255, 0, 255);
	}
	SetEntData(client, g_ioffsCollisionGroup, COLLISION_GROUP_PUSHAWAY, 4, true);
}