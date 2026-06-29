#pragma semicolon 1
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{ 
	name = "Team Kill Reactions Fix", 
	author = "DeathChaos25", 
	description = "Fixes Bugs Related To Team Kill Reactions.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=259791" 
}

static const String:MODEL_NICK[] = "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] = "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] = "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] = "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] = "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] = "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] = "models/survivors/survivor_manager.mdl";

public OnPluginStart() 
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	
	CreateConVar("teamkill_reactions_fix_version", PLUGIN_VERSION, "Team Kill Reactions Fix Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:OnPlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsSurvivor(victim) || !IsSurvivor(attacker) || attacker == victim) 
	{
		return;
	}
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(attacker));
	WritePackCell(pack, GetClientUserId(victim));
	CreateTimer(1.5, ReactionDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsSurvivor(victim) || !IsSurvivor(attacker) || attacker == victim) 
	{
		return;
	}
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(attacker));
	WritePackCell(pack, GetClientUserId(victim));
	CreateTimer(2.5, ReactionDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, GetClientUserId(victim));
	CreateTimer(6.5, SwearDelayTimer, pack2, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
}

public Action:ReactionDelayTimer(Handle:timer, Handle:pack) 
{
	ResetPack(pack);
	new attacker = GetClientOfUserId(ReadPackCell(pack));
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (!IsSurvivor(attacker) || !IsSurvivor(victim))
	{
		return Plugin_Stop;
	}
	
	new reactor = GetRandomSurvivor(attacker, victim);
	ReactToTeamKill(reactor);
	
	decl String:model[PLATFORM_MAX_PATH], String:rScene[PLATFORM_MAX_PATH], i_Rand;
	
	GetClientModel(attacker, model, sizeof(model));
	if (StrEqual(model, MODEL_COACH, false))
	{
		i_Rand = GetRandomInt(1, 7);
		Format(rScene, sizeof(rScene), "scenes/coach/sorry0%i.vcd", i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_ELLIS, false))
	{
		i_Rand = GetRandomInt(1, 10);
		Format(rScene, sizeof(rScene), "scenes/mechanic/sorry%s%d.vcd", (i_Rand < 10 ? "0" : ""), i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_NICK, false))
	{
		i_Rand = GetRandomInt(1, 8);
		Format(rScene, sizeof(rScene), "scenes/gambler/sorry0%i.vcd", i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_ROCHELLE, false))
	{
		i_Rand = GetRandomInt(1, 8);
		Format(rScene, sizeof(rScene), "scenes/producer/sorry0%i.vcd", i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_FRANCIS, false))
	{
		i_Rand = GetRandomInt(1, 18);
		if (i_Rand == 11)
		{
			i_Rand = 12;
		}
		
		Format(rScene, sizeof(rScene), "scenes/biker/sorry%s%d.vcd", (i_Rand < 10 ? "0" : ""), i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_BILL, false))
	{
		i_Rand = GetRandomInt(1, 12);
		if (i_Rand == 6)
		{
			i_Rand = 7;
		}
		
		Format(rScene, sizeof(rScene), "scenes/namvet/sorry%s%d.vcd", (i_Rand < 10 ? "0" : ""), i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}	
	else if (StrEqual(model, MODEL_LOUIS, false))
	{
		i_Rand = GetRandomInt(1, 7);
		if (i_Rand == 5)
		{
			i_Rand = 6;
		}
		
		Format(rScene, sizeof(rScene), "scenes/manager/sorry0%i.vcd", i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	else if (StrEqual(model, MODEL_ZOEY, false))
	{
		i_Rand = GetRandomInt(4, 23);
		if (i_Rand == 19)
		{
			i_Rand = 20;
		}
		else if (i_Rand == 21 || i_Rand == 22)
		{
			i_Rand = 23;
		}
		
		Format(rScene, sizeof(rScene), "scenes/teengirl/sorry%s%d.vcd", (i_Rand >= 20 ? "2" : i_Rand < 10 ? "0" : ""), i_Rand);
		PerformSceneEx(attacker, "", rScene, 1.5);
	}
	
	return Plugin_Stop;
}

public Action:SwearDelayTimer(Handle:timer, Handle:pack) 
{
	ResetPack(pack);
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (!IsSurvivor(victim) || IsActorBusy(victim))
	{
		return Plugin_Stop;
	}
	
	PerformSceneEx(victim, "PlayerNegative");
	return Plugin_Stop;
}

stock ReactToTeamKill(client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	decl String:model[PLATFORM_MAX_PATH], String:rScene[PLATFORM_MAX_PATH];
	new i_Rand;
	
	GetClientModel(client, model, sizeof(model));
	if (StrEqual(model, MODEL_COACH, false))
	{
		i_Rand = GetRandomInt(1, 8);
		Format(rScene, sizeof(rScene),"scenes/coach/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_ELLIS, false))
	{
		i_Rand = GetRandomInt(1, 5);
		Format(rScene, sizeof(rScene),"scenes/mechanic/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_NICK, false))
	{
		i_Rand = GetRandomInt(1, 3);
		Format(rScene, sizeof(rScene),"scenes/gambler/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_ROCHELLE, false))
	{
		i_Rand = GetRandomInt(1, 4);
		Format(rScene, sizeof(rScene),"scenes/producer/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_FRANCIS, false))
	{
		i_Rand = GetRandomInt(1, 6);
		Format(rScene, sizeof(rScene),"scenes/biker/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_BILL, false))
	{
		i_Rand = GetRandomInt(1, 4);
		Format(rScene, sizeof(rScene),"scenes/namvet/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}	
	else if (StrEqual(model, MODEL_LOUIS, false))
	{
		i_Rand = GetRandomInt(1, 4);
		Format(rScene, sizeof(rScene),"scenes/manager/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
	else if (StrEqual(model, MODEL_ZOEY, false))
	{
		i_Rand = GetRandomInt(3, 8);
		if (i_Rand == 4)
		{
			i_Rand = 3;
		}
		else if (i_Rand == 7)
		{
			i_Rand = 6;
		}
		
		Format(rScene, sizeof(rScene),"scenes/teengirl/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", rScene);
	}
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock GetRandomSurvivor(attacker, victim)
{
	new clients[MAXPLAYERS+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsActorBusy(i) && i != attacker && i != victim)
		{
			clients[clientCount++] = i;
		}
	}
	
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}

