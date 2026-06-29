/* Includes */
#include <sourcemod>
#include <sceneprocessor>
#include <sdktools_functions>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

/* Plugin Information */ 
public Plugin:myinfo = { 
	name        = "[L4D2] Team Kill Reactions", 
	author        = "DeathChaos25", 
	description    = "Implements unused TeamKillAccident reaction lines for all 8 survivors",
	url        = "https://forums.alliedmods.net/showthread.php?t=259791" 
}

/* Globals */ 

static const String:MODEL_NICK[] 		= "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] 		= "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] 		= "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] 		= "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] 		= "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] 		= "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] 		= "models/survivors/survivor_manager.mdl";

/* Plugin Functions */ 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder)); 
	if (!StrEqual(s_GameFolder, "left4dead", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead Only!"); 
		return APLRes_Failure;
	}
	return APLRes_Success; 
}
public OnPluginStart() 
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	CreateConVar("l4d2_teamkill_voc_version", PLUGIN_VERSION, "Current Version of Team Kill Vocalizations", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	CheckModelPreCache(MODEL_NICK);
	CheckModelPreCache(MODEL_ROCHELLE);
	CheckModelPreCache(MODEL_COACH);
	CheckModelPreCache(MODEL_ELLIS);
	CheckModelPreCache(MODEL_BILL);
	CheckModelPreCache(MODEL_ZOEY);
	CheckModelPreCache(MODEL_FRANCIS);
	CheckModelPreCache(MODEL_LOUIS);
}

public Event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(!IsSurvivor(victim) || !IsSurvivor(attacker) || GetClientTeam(attacker) != GetClientTeam(victim)) 
	{
		return;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(attacker));
	WritePackCell(pack, GetClientUserId(victim));
	CreateTimer(1.5, ReactionDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(!IsSurvivor(victim) || !IsSurvivor(attacker) || GetClientTeam(attacker) != GetClientTeam(victim)) 
	{
		return;
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(attacker));
	WritePackCell(pack, GetClientUserId(victim));
	CreateTimer(2.5, ReactionDelayTimer, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, GetClientUserId(victim));
	CreateTimer(6.5, SwearDelayTimer, pack2, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}
public Action:ReactionDelayTimer(Handle:timer, Handle:pack) 
{
	ResetPack(pack);
	new attacker = GetClientOfUserId(ReadPackCell(pack));
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (victim == 0 || attacker == 0)
	{
		return Plugin_Stop;
	}
	new reactor = GetRandomSurvivor(attacker, victim);
	ReactToTeamKill(reactor);
	PerformSceneEx(attacker, "PlayerSorry", _, 1.5);
	return Plugin_Stop;
}
public Action:SwearDelayTimer(Handle:timer, Handle:pack) 
{
	ResetPack(pack);
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (victim == 0 || !IsSurvivor(victim) || IsActorBusy(victim))
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
	new String:model[PLATFORM_MAX_PATH] = "";
	new String:s_Vocalize[PLATFORM_MAX_PATH] = "";
	new i_Rand;
	GetClientModel(client, model, sizeof(model));
	
	if (StrEqual(model, MODEL_COACH)) {
		i_Rand = GetRandomInt(1, 8);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/coach/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	else if (StrEqual(model, MODEL_ELLIS)) {
		i_Rand = GetRandomInt(1, 5);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/mechanic/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	
	else if (StrEqual(model, MODEL_NICK)) {
		i_Rand = GetRandomInt(1, 3);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/gambler/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	else if (StrEqual(model, MODEL_ROCHELLE)) {
		i_Rand = GetRandomInt(1, 4);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/producer/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	else if (StrEqual(model, MODEL_FRANCIS)) {
		i_Rand = GetRandomInt(1, 6);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/biker/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	else if (StrEqual(model, MODEL_BILL)) {
		i_Rand = GetRandomInt(1, 4);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/namvet/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}	
	else if (StrEqual(model, MODEL_LOUIS)) {
		i_Rand = GetRandomInt(1, 4);
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/manager/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
	else if (StrEqual(model, MODEL_ZOEY)) {
		i_Rand = GetRandomInt(3, 8);
		if (i_Rand == 4)
		{
			i_Rand = 3;
		}
		else if (i_Rand == 7)
		{
			i_Rand = 6;
		}
		
		Format(s_Vocalize, sizeof(s_Vocalize),"scenes/teengirl/teamkillaccident0%i.vcd", i_Rand);
		PerformSceneEx(client, "", s_Vocalize);
	}
}
stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s",Modelfile);
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
	new clients[MaxClients+1], clientCount;
	
	for(new i = 1; i <= MaxClients; i++)
		if(i != attacker && i != victim && IsSurvivor(i) && IsPlayerAlive(i) && !IsActorBusy(i) )
			clients[clientCount++] = i;
		
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
