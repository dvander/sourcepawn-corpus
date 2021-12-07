/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

bool playing = true;
#define DOIT_DELAY 0.5

#define MAXENTITIES 2048
new bool:spawn_ready[MAXPLAYERS+1];
new Handle:hurted_timer[MAXENTITIES+1] = INVALID_HANDLE;
new Handle:enemyseen_timer[MAXENTITIES+1] = INVALID_HANDLE;
new Float:hurted[MAXENTITIES+1];
new Float:enemyseen[MAXENTITIES+1];
new bool:damage_hook[MAXENTITIES+1];
new bool:spec_said[MAXPLAYERS+1];
new Handle:spectate_timer[MAXPLAYERS+1];
new Handle:robot_timer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:ctimer = INVALID_HANDLE;
new bool:auto_respawn[MAXPLAYERS+1];

new bool:firsttime[MAXPLAYERS+1];

new sayn = 0;

#define MAX_NEAR_DISTANCE	500.0
#define PLAYER_WIDTH		43.0
#define PLAYER_WIDTH_HALF	22.0
#define PLAYER_HEIGHT		64.0
#define PLAYER_HEIGHT_HALF	32.0
// debatable
#define SENTRY_GUN_HEIGHT	40.0
#define DISPENSER_HEIGHT	40.0

#define RESPAWN_SOUNDS_COUNT 4
#define teleport_sound "ambient/levels/labs/electric_explosion5.wav"
new String:respawn_sounds[][] = {"weapons/stunstick/alyx_stunner1.wav","weapons/stunstick/alyx_stunner2.wav"
				,"weapons/ar2/ar2_reload_rotate.wav","weapons/ar2/ar2_reload_push.wav"};

#define SPEC_FOR_MSG_TIME 2.75

//new g_sprite;

new TF2GameRulesEntity; //The entity that controls spawn wave times
new Handle:RespawnTimeBlue = INVALID_HANDLE;
new Handle:RespawnTimeRed = INVALID_HANDLE;
new Handle:enabled = INVALID_HANDLE;
new bool:g_enabled = false;


// unsee delay is slightly bigger because it usually has at least 1 second error.. like you get spotted and timer immediately lowers by 1...
#define UNSEE_DELAY 5.0
#define UNHURT_DELAY 4.0

public Plugin:myinfo = 
{
	name = "Frontline Respawns",
	author = "Tom Fyuri",
	description = "Frontline respawning, spectate ally, press E, respawn instantly...",
	version = "0.0.1",
	url = ""
};
stock TagsCheck(const String:tag[], bool:remove = false)
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (StrContains(tags, tag, false) == -1 && !remove)
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	else if (StrContains(tags, tag, false) > -1 && remove)
	{
		ReplaceString(tags, sizeof(tags), tag, "", false);
		ReplaceString(tags, sizeof(tags), ",,", ",", false);
		SetConVarString(hTags, tags);
	}
}
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	
	HookEvent("teamplay_round_stalemate", RoundEnd, EventHookMode_PostNoCopy); //Disable spawning during suddendeath. Could be fun if enabled with melee only.
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_PostNoCopy); //Disable spawning during beat the crap out of the losing team mode. Fun if on :)
	HookEvent("teamplay_game_over", RoundEnd, EventHookMode_PostNoCopy); //Disable spawning
	
	HookEvent("teamplay_round_start", RoundStart, EventHookMode_PostNoCopy); //Enable fast spawning
	
	// Medic Call hook(3.3)
	AddCommandListener(Command_SpawnME, "voicemenu");
	
	enabled = CreateConVar("sm_fr_enabled", "1", "Turn on/off frontline respawning", FCVAR_NOTIFY|FCVAR_NOTIFY);
	RespawnTimeBlue = CreateConVar("sm_fr_time_blue", "15.0", "(non) Frontline respawns time for Blue team", FCVAR_NOTIFY|FCVAR_NOTIFY);
	RespawnTimeRed = CreateConVar("sm_fr_time_red", "15.0", "(non) Frontline respawns time for Red team", FCVAR_NOTIFY|FCVAR_NOTIFY);
	
	HookConVarChange(enabled, RespawnsConVarChanged);
	HookConVarChange(RespawnTimeBlue, RespawnConVarChanged);
	HookConVarChange(RespawnTimeRed, RespawnConVarChanged);
	HookConVarChange(FindConVar("sv_tags"), TagsChanged);
	
	RegConsoleCmd("respawn", RespawnToggle);
	
	HookEveryone();
}
public OnConfigsExecuted()
{
	TogglePlugin(GetConVarBool(enabled));
}
public TagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TogglePlugin(GetConVarBool(enabled));
}
public RespawnsConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TogglePlugin(StringToInt(newValue) == 1);
}
public TogglePlugin(bool:mvar){	
	if (mvar) {
		g_enabled = true;
		TagsCheck("frontline_respawns");
	}
	else {
		g_enabled = false;
		TagsCheck("frontline_respawns", true);
	}
}
public RespawnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_enabled){
		SetRespawnTime();
	}
}
HookEveryone()
{
	for (new client = 1; client <= GetMaxClients(); client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (!damage_hook[client])
			{
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				damage_hook[client] = true;
			}
		}
	}
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
	{
		if (!damage_hook[iEnt])
		{
			SDKHook(iEnt, SDKHook_OnTakeDamage, OnTakeDamage);
			damage_hook[iEnt] = true;
		}
	}
}
public OnMapStart()
{
	decl String:buffer[256];
	for (new i=0; i<RESPAWN_SOUNDS_COUNT; i++)
	{
		PrecacheSound(respawn_sounds[i], true);
		Format(buffer, sizeof(buffer), "sound/%s", respawn_sounds[i]);
		AddFileToDownloadsTable(buffer);
	}
	PrecacheSound(teleport_sound, true);
	Format(buffer, sizeof(buffer), "sound/%s", teleport_sound);
	AddFileToDownloadsTable(buffer);
	/*AddFileToDownloadsTable("materials/sprites/laser.vmt");
	AddFileToDownloadsTable("materials/sprites/laser.vmf");
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");*/
	//CreateTimer(2.5, MapStarted, _, TIMER_FLAG_NO_MAPCHANGE);
	
	//Find the TF_GameRules Entity
	TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	
	if (TF2GameRulesEntity == -1)
	{
		LogToGame("Could not find TF_GameRules to set respawn wave time");
	}
	
	ctimer = CreateTimer(120.0, TellEveryone, _, TIMER_REPEAT);
	
	// Disable the plugin during Arena Mode
	if (IsArenaMap())
		SetConVarInt(enabled, 0);
	//else g_enabled = GetConVarBoolean(enabled);
}
public bool:IsArenaMap()
{
	new iEnt = FindEntityByClassname(-1, "tf_logic_arena");
	
	if (iEnt == -1)
		return false;
	else
		return true;
}
public OnMapEnd()
{
	KillTimer(ctimer);
	ctimer = INVALID_HANDLE;
}
public Action:TellEveryone(Handle:timer, any:client)
{
	if(g_enabled){
		switch (sayn){
			case 0:
			{
				PrintToChatAll("\x04[Frontline Respawns]\x01 Spectate your ally, press E, respawn! That simple!");
			}
			case 1:
			{
				PrintToChatAll("\x04[Frontline Respawns]\x01 However, if your ally is under fire you may not respawn near them!");
			}
			case 2:
			{
				PrintToChatAll("\x04[Frontline Respawns]\x01 Say !respawn to toggle auto respawner, random ally will be selected every time!");
			}
		}
	}
	sayn=sayn+1;
	if (sayn>2) sayn=0;
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
	spawn_ready[client] = false;
	auto_respawn[client] = false;
	firsttime[client] = true;
	damage_hook[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public OnClientDisconnect(client)
{
	spawn_ready[client] = false;
	auto_respawn[client] = false;
	if (damage_hook[client])
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		damage_hook[client] = false;
	}
}
public Action:RespawnToggle(client, args)
{
	if (client > 0) auto_respawn[client] = !auto_respawn[client];
	if (auto_respawn[client]) {
		if (robot_timer[client] == INVALID_HANDLE && !IsPlayerAlive(client)) {
			robot_timer[client] = CreateTimer(1.0, SpawnThisGuy2, client, TIMER_REPEAT);
		}
		if (g_enabled){
			PrintToChat(client, "\x04[Frontline Respawns]\x01 You will automatically spawn as soon as possible.");
		}
	} else {
		if (g_enabled){
			PrintToChat(client, "\x04[Frontline Respawns]\x01 You may spawn manually by pressing \"Medic!\" now.");
		}
	}
	return Plugin_Handled;
}
public SetRespawnTime()
{
	if (TF2GameRulesEntity != -1 && g_enabled)
	{
		new Float:RespawnTimeRedValue = GetConVarFloat(RespawnTimeRed);
		if (RespawnTimeRedValue >= 6.0) //Added this check for servers setting spawn time to 6 seconds. The -6.0 below would cause instant spawn.
			SetVariantFloat(RespawnTimeRedValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		else
			SetVariantFloat(RespawnTimeRedValue);
			
		AcceptEntityInput(TF2GameRulesEntity, "SetRedTeamRespawnWaveTime", RoundFloat(RespawnTimeRedValue), RoundFloat(RespawnTimeRedValue), 0);
		
		new Float:RespawnTimeBlueValue = GetConVarFloat(RespawnTimeBlue);
		if (RespawnTimeBlueValue >= 6.0)
			SetVariantFloat(RespawnTimeBlueValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		else
			SetVariantFloat(RespawnTimeBlueValue);
			
		AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", RoundFloat(RespawnTimeBlueValue), RoundFloat(RespawnTimeBlueValue), 0);
	}
}
public PlayerDeath(Handle:event, const String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && playing && IsClientInGame(client) && GetClientTeam(client) > 1 && !(GetEventInt(event, "death_flags") & 32))// && GetTeamClientCount(GetClientTeam(client)) > 0)
	{
		CreateTimer(DOIT_DELAY, DoIt, client, TIMER_FLAG_NO_MAPCHANGE);
		spawn_ready[client] = true;
		if (g_enabled){
			SetRespawnTime();
		}
	}
}
public RoundStart(Handle:event, const String:sName[], bool:bDontBroadcast)
{
	playing = true;
	g_enabled = GetConVarInt(enabled)==1;
}
public RoundEnd(Handle:event, const String:sName[], bool:bDontBroadcast)
{
	playing = false;
	g_enabled = GetConVarInt(enabled)==1;
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && GetClientTeam(client) > 1)
	{
		spawn_ready[client] = false;
		spec_said[client] = false;
		hurted[client] = 0.0;
		enemyseen[client] = 0.0;
		if (hurted_timer[client] == INVALID_HANDLE)
		{
			hurted_timer[client] = CreateTimer(1.0, Unhurt, client, TIMER_REPEAT);
		}
		if (enemyseen_timer[client] == INVALID_HANDLE)
		{
			enemyseen_timer[client] = CreateTimer(1.0, Unsee, client, TIMER_REPEAT);
		}
		if (g_enabled){
			if (firsttime[client]){
				PrintToChat(client,"\x04[Frontline Respawns]\x01 Spectate your ally, press E, respawn! That simple!");
				PrintToChat(client,"\x04[Frontline Respawns]\x01 However, if your ally is under fire you may not respawn near them!");
				PrintToChat(client,"\x04[Frontline Respawns]\x01 Say !respawn to toggle auto respawner, random ally will be selected every time!");
				firsttime[client]=false;
			}
		}
	}
}
public void OnEntityCreated(int entity, const char[] classname)
{
    if(StrEqual(classname, "obj_dispenser", false))
    {
		new client = entity;
		hurted[client] = 0.0;
		enemyseen[client] = 0.0;
		if (hurted_timer[client] == INVALID_HANDLE)
		{
			hurted_timer[client] = CreateTimer(1.0, Unhurt, client, TIMER_REPEAT);
		}
		if (enemyseen_timer[client] == INVALID_HANDLE)
		{
			enemyseen_timer[client] = CreateTimer(1.0, Unsee, client, TIMER_REPEAT);
		}
		if (!damage_hook[client])
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			damage_hook[client] = true;
		}
	}
}
public void OnEntityDestroyed(int entity)
{
    if(hurted_timer[entity] != INVALID_HANDLE || enemyseen_timer[entity] != INVALID_HANDLE)
    {
		new client = entity;
		KillTimer(hurted_timer[client]);
		hurted_timer[client] = INVALID_HANDLE;
		KillTimer(enemyseen_timer[client]);
		enemyseen_timer[client] = INVALID_HANDLE;
		if (damage_hook[client])
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			damage_hook[client] = false;
		}
	}
}
public Action:Unhurt(Handle:timer, any:client)
{
	if (client > GetMaxClients())
	{
		if (hurted[client]>0.0)
		{		
			hurted[client]-=1.0;
		}
	}else{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
		{
			KillTimer(hurted_timer[client]);
			hurted_timer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		if (hurted[client]>0.0)
		{		
			hurted[client]-=1.0;
		}
	}
	return Plugin_Continue;
}
public Action:Unsee(Handle:timer, any:client)
{
	if (client > GetMaxClients())
	{
		if (enemyseen[client]>0.0)
		{
			enemyseen[client]-=1.0;
		}
	}else{
		if (!IsClientInGame(client) || !IsPlayerAlive(client))
		{
			KillTimer(enemyseen_timer[client]);
			enemyseen_timer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		if (enemyseen[client]>0.0)
		{
			/*
			decl String:buffer[128];
			Format(buffer, sizeof(buffer), "unseen left. %f", enemyseen[client]);
			PrintToChat(client,buffer);*/
			enemyseen[client]-=1.0;
		}
}	
	return Plugin_Continue;
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//if (client > 0 && client < 65 && damage >= 1.0 && attacker > 0 && attacker < 65 && GetClientTeam(client) != GetClientTeam(attacker))
	if (client > 0 && client != attacker)
	{
		hurted[client] = UNHURT_DELAY;
	}
}
public Action:SpawnThisGuy2(Handle:timer, any:player)
{
	if (!IsValidClient(player))
	{
		KillTimer(robot_timer[player]);
		robot_timer[player] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if (SpawnThisGuy(player,true)) {
		KillTimer(robot_timer[player]);
		robot_timer[player] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))  
public int GetRandomPlayer(int team) 
{
    int[] clients = new int[MaxClients];
    int clientCount;

    LoopClients(client)
    {
        if ((GetClientTeam(client) == team) && IsPlayerAlive(client) 
			&& !TF2_IsPlayerInCondition(client, TFCond_Cloaked) // cloaked spies do not spawn allies, ever
			&& !TF2_IsPlayerInCondition(client, TFCond_Disguised) // disguised spies do not spawn allies, ever)
			&& ((GetEntityFlags(client) & FL_ONGROUND) || (GetEntityFlags(client) & FL_INWATER))
			&& !(hurted[client] > 0.0)
			&& !(GetEntityFlags(client) & FL_DUCKING))
        {
			new bool:seen = enemyseen[client] || EnemySee(client, team);
			if (!seen) {
				clients[clientCount++] = client;
			}
        }
    }

    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
public int GetRandomPlayerOrDispenser(int team) 
{
    int[] clients = new int[MAXENTITIES]; // hmm?
    int clientCount;

    LoopClients(client)
    {
        if ((GetClientTeam(client) == team) && IsPlayerAlive(client) 
			&& !TF2_IsPlayerInCondition(client, TFCond_Cloaked) // cloaked spies do not spawn allies, ever
			&& !TF2_IsPlayerInCondition(client, TFCond_Disguised) // disguised spies do not spawn allies, ever)
			&& ((GetEntityFlags(client) & FL_ONGROUND) || (GetEntityFlags(client) & FL_INWATER))
			&& !(hurted[client] > 0.0)
			&& !(GetEntityFlags(client) & FL_DUCKING))
        {
			new bool:seen = enemyseen[client] || EnemySee(client, team);
			if (!seen) {
				clients[clientCount++] = client;
			}
		}
	}
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
	{
		new owner = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
		if (GetClientTeam(owner) == team) // enemy
		{
			new bool:seen = enemyseen[iEnt] || EnemySee(iEnt, team);
			if (!seen) {
				clients[clientCount++] = iEnt;
			}
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
public SpawnThisGuy(player,auto)
{
	// 1. find nearest ally
	// 2. check if noone sees him
	// 3. spawn there
	if (!g_enabled) return false;
	new bool:bot = IsFakeClient(player) || auto;
	new Float:clientpos[3]; GetClientEyePosition(player, clientpos);
	new Float:position[3]; new Float:distance;
	new perfect = 0;
	new team = GetClientTeam(player);
	new bool:good = false;
	new bool:building = false;
	if (!bot) {
		for (new client = 1; client <= GetMaxClients(); client++)
		{
			if (client != player && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && team == GetClientTeam(client))
			{
				GetClientEyePosition(client, position);
				if ((bot || GetVectorDistance(position, clientpos) <= MAX_NEAR_DISTANCE) // best distance
				 &&	(perfect == 0 || GetVectorDistance(position, clientpos) < distance) // better distance
				 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) // cloaked spies do not spawn allies, ever
				 && !TF2_IsPlayerInCondition(client, TFCond_Disguised) // disguised spies do not spawn allies, ever
				 && !(GetEntityFlags(client) & FL_DUCKING)) // no crouching
				{
					distance = GetVectorDistance(position, clientpos);
					perfect = client;
				}
			}
		}
		// maybe dispenser is near by?
		new iEnt = -1;
		//new bool:sentry=false;
		while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE) {
			new owner = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
			if (GetClientTeam(owner) == team) // enemy
			{
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", position);
				position[2] = position[2] + DISPENSER_HEIGHT;
				if ((bot || GetVectorDistance(position, clientpos) <= MAX_NEAR_DISTANCE)
					&& (perfect == 0 || GetVectorDistance(position, clientpos) < distance)) {
					distance = GetVectorDistance(position, clientpos);
					perfect = iEnt;
					building = true;
				}
			}
		}
		
		new bool:danger = false;
		if (perfect > 0)
		{
			if (!building){
				danger = hurted[perfect] > 0.0 || (enemyseen[perfect] || EnemySee(perfect, team));
				good = !danger && ((GetEntityFlags(perfect) & FL_ONGROUND) || (GetEntityFlags(perfect) & FL_INWATER)) && !(GetEntityFlags(perfect) & FL_DUCKING);
			}
			else {
				danger = hurted[perfect] > 0.0 || (enemyseen[perfect] || EnemySee(perfect, team));
				good = !danger;
			}
		}
		/*decl String:buffer[128];
		Format(buffer, sizeof(buffer), "Okay? %b %b %d", danger, good, perfect);
		PrintToChat(player,buffer);*/
		if (perfect > 0 && danger)
		{
			//Format(buffer, sizeof(buffer), "%T", "danger place", player);
			PrintHintText(player, "The nearest ally is in trouble, try another one!");
			PrintCenterText(player, "The nearest ally is in trouble, try another one!");
			good = false;
		}
		else if (spec_said[player])
		{
			if (perfect == 0)
			{
				//Format(buffer, sizeof(buffer), "%T", "no friends", player);
				PrintHintText(player, "There is no valid ally near by...");
				PrintCenterText(player, "There is no valid ally near by...");
			}
		}
		else if (!spec_said[player])
		{
			//Format(buffer, sizeof(buffer), "%T", "spectate close", player);
			PrintHintText(player, "Spectate nearest ally and press \"Medic!\" to respawn near them! Make sure no enemies see them!");
			PrintCenterText(player, "Spectate nearest ally and press \"Medic!\" to respawn near them! Make sure no enemies see them!");
			if (spectate_timer[player] == INVALID_HANDLE)
				spectate_timer[player] = CreateTimer(SPEC_FOR_MSG_TIME, SpecSaid, player, TIMER_FLAG_NO_MAPCHANGE);
		}
	} else {
		new target = GetRandomPlayerOrDispenser(GetClientTeam(player));
		if (target > 0) {
			perfect = target;
			good = true;
		}
		if (perfect > MaxClients) building = true;
	}
	if (good && spawn_ready[player] && playing)
	{
		new Float:pos[3];
		if (!building) {
			GetClientAbsOrigin(perfect, pos);
		}else{
			GetEntPropVector(perfect, Prop_Send, "m_vecOrigin", pos);
		}
		// respawn code
		new Float:angles[3];
		GetEntPropVector(player, Prop_Data, "m_angAbsRotation", angles);
		TF2_RespawnPlayer(player);
		// sound effect
		EmitAmbientSound(teleport_sound, pos, player, SNDLEVEL_NORMAL, _, 0.8); // 0.8
		EmitAmbientSound(respawn_sounds[GetRandomInt(0,1)], pos, player, SNDLEVEL_NORMAL, _, 0.8); // 0.8
		// effect
		decl Float:Origin[3];
		Origin = pos; Origin[2]+=55.0;
		TE_SetupEnergySplash(Origin,Origin,false);
		TE_SendToAll();
		TE_SetupSparks(Origin,Origin,255,1);
		TE_SendToAll();
		TeleportEntity(player, pos, NULL_VECTOR, NULL_VECTOR);
		//PrintToChatAll("player spawns at %.2f %.2f %.2f", spawn[0], spawn[1], spawn[2]);
		SetEntPropVector(player, Prop_Data, "m_angAbsRotation", angles);
		GetClientAbsOrigin(player, Origin);
		Origin[2]+=55.0;
		// TODO at this point you can stuck at your own dispenser, that's an issue i dont know how to solve right now
		return true; // respawned
	}
	/*else
	{
		decl String:name[40];
		GetClientName(player, name, sizeof(name));
		PrintToChat(perfect, "%s is trying to respawn near you...", name);
	}*/
	return false;
}

stock bool:EnemySee(const player, const team, requester=0)
{
	new Float:cpos[3], Float:endpos[3], Float:pos[3], Float:opos[3];
	new bool:result;
	new bool:building=false;
	if (player < MaxClients)
	{
		GetClientAbsOrigin(player, opos); pos = opos;
	}
	else {
		GetEntPropVector(player, Prop_Send, "m_vecOrigin", opos);
		pos = opos;
		building = true;
	}
	if (!building) {
		for (new Float:position = 0.0; position <= PLAYER_HEIGHT; position += PLAYER_HEIGHT_HALF)
		{
			pos[2] = opos[2] + position;
			{
				decl Handle:TraceRay;
				for (new client = 1; client <= GetMaxClients(); client++)
				{
					if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != team && GetClientTeam(client) > 1)
					{
						GetClientEyePosition(client, cpos);
						TraceRay = TR_TraceRayFilterEx(cpos, pos, MASK_ALL, RayType_EndPoint, TraceRayDontHitSelf, client);
						if(TR_DidHit(TraceRay))
						{
							TR_GetEndPosition(endpos, TraceRay);
							CloseHandle(TraceRay);
							if (GetVectorDistance(endpos, pos) <= PLAYER_WIDTH_HALF)
							{
								/*if (requester>0)
								{
									TE_SetupBeamPoints(pos, endpos, g_sprite, 0, 0, 0, 5.0, 3.0, 3.0, 7, 0.0, color_r, 0);
									TE_SendToClient(requester);
								}*/
								result = true;
							}
						}
						else
						{
							// the thing is that player PROBABLY see me...
							/*if (requester>0)
							{
								TE_SetupBeamPoints(cpos, pos, g_sprite, 0, 0, 0, 5.0, 3.0, 3.0, 7, 0.0, color_r, 0);
								TE_SendToClient(requester);
							}*/
							result = true;
						}
					}
					if (result)
					{
						enemyseen[player] = UNSEE_DELAY;
						return true;
					}
				}
			}
		}
	}else{
		pos[2] = opos[2] + DISPENSER_HEIGHT;
		{
			decl Handle:TraceRay;
			for (new client = 1; client <= GetMaxClients(); client++)
			{
				if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != team && GetClientTeam(client) > 1)
				{
					GetClientEyePosition(client, cpos);
					TraceRay = TR_TraceRayFilterEx(cpos, pos, MASK_ALL, RayType_EndPoint, TraceRayDontHitSelf, client);
					if(TR_DidHit(TraceRay))
					{
						TR_GetEndPosition(endpos, TraceRay);
						CloseHandle(TraceRay);
						if (GetVectorDistance(endpos, pos) <= PLAYER_WIDTH_HALF)
						{
							/*if (requester>0)
							{
								TE_SetupBeamPoints(pos, endpos, g_sprite, 0, 0, 0, 5.0, 3.0, 3.0, 7, 0.0, color_r, 0);
								TE_SendToClient(requester);
							}*/
							result = true;
						}
					}
					else
					{
						// the thing is that player PROBABLY see me...
						/*if (requester>0)
						{
							TE_SetupBeamPoints(cpos, pos, g_sprite, 0, 0, 0, 5.0, 3.0, 3.0, 7, 0.0, color_r, 0);
							TE_SendToClient(requester);
						}*/
						result = true;
					}
				}
				if (result)
				{
					enemyseen[player] = UNSEE_DELAY;
					return true;
				}
			}
		}
	}
	// sentry gun
	new iEnt = -1;
	//new bool:sentry=false;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE) {
		new owner = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
		if (GetClientTeam(owner) != team) // enemy
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", cpos);
			cpos[2] = cpos[2] + SENTRY_GUN_HEIGHT;
			pos = opos;
			if (!building) {
				for (new Float:position = 0.0; position <= PLAYER_HEIGHT; position += PLAYER_HEIGHT_HALF)
				{
					pos[2] = opos[2] + position;
					{
						decl Handle:TraceRay;
						TraceRay = TR_TraceRayFilterEx(cpos, pos, MASK_ALL, RayType_EndPoint, TraceRayDontHitSelf, iEnt);
						if(TR_DidHit(TraceRay))
						{
							TR_GetEndPosition(endpos, TraceRay);
							CloseHandle(TraceRay);
							if (GetVectorDistance(endpos, pos) <= PLAYER_WIDTH_HALF)
							{
								result = true;
								//sentry  = true;
							}
						}
						else
						{
							result = true;
							//sentry = true;
						}
						if (result)
						{
							enemyseen[player] = UNSEE_DELAY;
							/*if (sentry) {
								decl String:buffer[128];
								Format(buffer, sizeof(buffer), "a sentry sees you. %f", enemyseen[player]);
								PrintToChatAll(buffer);
							}*/
							return true;
						}
					}
				}
			}else{
				pos[2] = opos[2] + DISPENSER_HEIGHT;
				{
					decl Handle:TraceRay;
					TraceRay = TR_TraceRayFilterEx(cpos, pos, MASK_ALL, RayType_EndPoint, TraceRayDontHitSelf, iEnt);
					if(TR_DidHit(TraceRay))
					{
						TR_GetEndPosition(endpos, TraceRay);
						CloseHandle(TraceRay);
						if (GetVectorDistance(endpos, pos) <= PLAYER_WIDTH_HALF)
						{
							result = true;
							//sentry  = true;
						}
					}
					else
					{
						result = true;
						//sentry = true;
					}
					if (result)
					{
						enemyseen[player] = UNSEE_DELAY;
						/*if (sentry) {
							decl String:buffer[128];
							Format(buffer, sizeof(buffer), "a sentry sees you. %f", enemyseen[player]);
							PrintToChatAll(buffer);
						}*/
						return true;
					}
				}
			}
		}
	}
	return false;
}
public Action:SpecSaid(Handle:timer, any:client)
{
	spec_said[client] = true;
	spectate_timer[client] = INVALID_HANDLE;
}
public Action:DoIt(Handle:timer, any:client)
{
	if (client <= 0 || !IsClientInGame(client) || IsPlayerAlive(client) || GetClientTeam(client) <= 1 || !playing)
	{
		return Plugin_Handled; // exit from this
	}
	spec_said[client] = false;
	//PrintToChatAll("DoIt");
	if (IsFakeClient(client) || auto_respawn[client])
	{
		CreateTimer(0.5, SpawnThisGuy2, client, TIMER_FLAG_NO_MAPCHANGE);
		robot_timer[client] = CreateTimer(1.0, SpawnThisGuy2, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}
bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}
public Action:Command_SpawnME(client, const String:command[], argc)
{
	if (!g_enabled) return Plugin_Continue;
	new String:args[5];
	GetCmdArgString(args, sizeof(args));
	if (!StrEqual(args, "0 0"))
	{
		return Plugin_Continue;
	}
	if(IsValidClient(client))
	{
		if(!spawn_ready[client])
			return Plugin_Continue;
		{
			SpawnThisGuy(client,false);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}
