#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.22"
#define CVAR_FLAGS          FCVAR_NOTIFY|FCVAR_REPLICATED

#define DEBUG 0


static const Float:TRACE_TOLERANCE 			= 25.0;

new Handle:CloudEnabled = INVALID_HANDLE;
new Handle:CloudDuration = INVALID_HANDLE;
new Handle:CloudRadius = INVALID_HANDLE;
new Handle:CloudDamage = INVALID_HANDLE;
new Handle:CloudShake = INVALID_HANDLE;
new Handle:CloudBlocksRevive = INVALID_HANDLE;
new Handle:SoundPath = INVALID_HANDLE;
new Handle:CloudMeleeSlowEnabled = INVALID_HANDLE;
new Handle:DisplayDamageMessage = INVALID_HANDLE;

static Handle:cvarGameModeActive	= INVALID_HANDLE;
static bool:isAllowedGameMode		= false;

new meleeentinfo;
new bool:isincloud[MAXPLAYERS+1];
new bool:swappedTeams[MAXPLAYERS+1];
new bool:MeleeDelay[MAXPLAYERS+1];
new propinfoghost;

public Plugin:myinfo = 
{
	name = "L4D_Cloud_Damage",
	author = " AtomicStryker",
	description = "Left 4 Dead Cloud Damage",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96665"
}

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	AddNormalSoundHook(NormalSHook:HookSound_Callback); //my melee hook since they didnt include an event for it
	HookEvent("player_team", PlayerTeam);
	HookEvent("round_start", RoundStart);
	
	CloudEnabled = CreateConVar("l4d_cloud_damage_enabled", "1", " Enable/Disable the Cloud Damage plugin ", CVAR_FLAGS);
	CloudDamage = CreateConVar("l4d_cloud_damage_damage", "2.5", " Amount of damage the cloud deals every half second", CVAR_FLAGS);
	CloudDuration = CreateConVar("l4d_cloud_damage_time", "10.0", "How long the cloud damage persists in seconds. ", CVAR_FLAGS);
	CloudRadius = CreateConVar("l4d_cloud_damage_radius", "150", " Radius of gas cloud damage ", CVAR_FLAGS);
	SoundPath = CreateConVar("l4d_cloud_damage_sound", "player/survivor/voice/choke_5.wav", "Path to the Soundfile being played on each damaging Interval", CVAR_FLAGS);
	CloudMeleeSlowEnabled = CreateConVar("l4d_cloud_meleeslow_enabled", "0", " Enable/Disable the Cloud Melee Slow Effect ", CVAR_FLAGS);
	DisplayDamageMessage = CreateConVar("l4d_cloud_message_enabled", "0", " 0 - Disabled; 1 - small HUD Hint; 2 - big HUD Hint; 3 - Chat Notification ", CVAR_FLAGS);
	CloudShake = CreateConVar("l4d_cloud_shake_enabled", "0", " Enable/Disable the Cloud Damage Shake ", CVAR_FLAGS);
	CloudBlocksRevive = CreateConVar("l4d_cloud_blocks_revive", "0", " Enable/Disable the Cloud Damage Stopping Reviving ", CVAR_FLAGS);
	
	cvarGameModeActive =	CreateConVar("l4d2_cloud_gamemodesactive",
							"coop,versus,teamversus,realism",
							" Set the gamemodes for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ",
							CVAR_FLAGS);
	
	HookConVarChange(FindConVar("mp_gamemode"), GameModeChanged);
	CheckGamemode();
	
	CreateConVar("l4d_cloud_damage_version", PLUGIN_VERSION, " Version of L4D Cloud Damage on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);

	// Autoexec config
	AutoExecConfig(true, "L4D_Cloud_Damage");
	
	meleeentinfo = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	decl String:gamename[128];
	GetGameFolderName(gamename, sizeof(gamename));
	if (StrContains(gamename, "left4dead") < 0)
	{
		SetFailState("This Plugin only supports L4D or L4D2");
	}
}

public GameModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CheckGamemode();
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckGamemode();
}

static CheckGamemode()
{
	decl String:gamemode[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	decl String:convarsetting[PLATFORM_MAX_PATH];
	GetConVarString(cvarGameModeActive, convarsetting, sizeof(convarsetting));
	
	isAllowedGameMode = ListContainsString(convarsetting, ",", gamemode);
}

stock bool:ListContainsString(const String:list[], const String:separator[], const String:string[])
{
	decl String:buffer[64][15];
	
	new count = ExplodeString(list, separator, buffer, 14, sizeof(buffer));
	for (new i = 0; i < count; i++)
	{
		if (StrEqual(string, buffer[i], false))
		{
			return true;
		}
	}
	
	return false;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If client is valid
	if (!client
	|| !isAllowedGameMode
	|| !IsClientInGame(client)
	|| GetClientTeam(client) !=3
	|| IsPlayerSpawnGhost(client))
	{
		return Plugin_Continue;
	}
	
	decl String:class[100];
	GetClientModel(client, class, sizeof(class));
	
	if (StrContains(class, "smoker", false) != -1)
	{
		if (GetConVarBool(CloudEnabled))
		{
			#if DEBUG
			PrintToChatAll("Smokerdeath caught, Plugin running");
			#endif
			
			decl Float:g_pos[3];
			GetClientEyePosition(client, g_pos);
			
			CreateGasCloud(client, g_pos);
		}
	}
	return Plugin_Continue;
}

static CreateGasCloud(client, Float:g_pos[3])
{
	#if DEBUG
	PrintToChatAll("Action GasCloud running");
	#endif
	
	new Float:targettime = GetEngineTime() + GetConVarFloat(CloudDuration);
	
	new Handle:data = CreateDataPack();
	WritePackCell(data, client);
	WritePackFloat(data, g_pos[0]);
	WritePackFloat(data, g_pos[1]);
	WritePackFloat(data, g_pos[2]);
	WritePackFloat(data, targettime);
	
	CreateTimer(0.5, Point_Hurt, data, TIMER_REPEAT);
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	swappedTeams[client] = true;
	CreateTimer(0.5, EraseGhostExploit, client);
}

public Action:EraseGhostExploit(Handle:timer, any:client)
{	
	swappedTeams[client] = false;
}

public Action:Point_Hurt(Handle:timer, Handle:hurt)
{
	ResetPack(hurt);
	new client = ReadPackCell(hurt);
	decl Float:g_pos[3];
	g_pos[0] = ReadPackFloat(hurt);
	g_pos[1] = ReadPackFloat(hurt);
	g_pos[2] = ReadPackFloat(hurt);
	new Float:targettime = ReadPackFloat(hurt);
	
	if (targettime - GetEngineTime() < 0)
	{
		#if DEBUG
		PrintToChatAll("Target Time reached Action PointHurter killing itself");
		#endif
	
		CloseHandle(hurt);
		return Plugin_Stop;
	}
	
	#if DEBUG
	PrintToChatAll("Action PointHurter running");
	#endif
	
	if (!IsClientInGame(client)) client = -1;
	// dummy line to prevent compiling errors. the client data has to be read or the datapack becomes corrupted
	
	decl Float:targetVector[3];
	decl Float:distance;
	new Float:radiussetting = GetConVarFloat(CloudRadius);
	decl String:soundFilePath[256];
	GetConVarString(SoundPath, soundFilePath, sizeof(soundFilePath));
	new bool:shakeenabled = GetConVarBool(CloudShake);
	new damage = GetConVarInt(CloudDamage);
	new bool:slowenabled = GetConVarBool(CloudMeleeSlowEnabled);
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (!target
		|| !IsClientInGame(target)
		|| !IsPlayerAlive(target)
		|| GetClientTeam(target) != 2)
		{
			continue;
		}

		GetClientEyePosition(target, targetVector);
		distance = GetVectorDistance(targetVector, g_pos);
		
		if (distance > radiussetting
		|| !IsVisibleTo(g_pos, targetVector)) continue;

		EmitSoundToClient(target, soundFilePath);
		switch (GetConVarInt(DisplayDamageMessage))
		{
			case 1:
			PrintCenterText(target, "You are taking damage from standing in a Smoker Cloud");
			
			case 2:
			PrintHintText(target, "You are taking damage from standing in a Smoker Cloud");
			
			case 3:
			PrintToChat(target, "You are taking damage from standing in a Smoker Cloud");
		}
		
		if (shakeenabled)
		{
			new Handle:hBf = StartMessageOne("Shake", target);
			BfWriteByte(hBf, 0);
			BfWriteFloat(hBf,6.0);
			BfWriteFloat(hBf,1.0);
			BfWriteFloat(hBf,1.0);
			EndMessage();
			CreateTimer(0.5, StopShake, target);
		}
		
		if (slowenabled && !IsFakeClient(target))
		{
			isincloud[target] = true;
			CreateTimer(0.5, ClearMeleeBlock, target);
		}
		
		applyDamage(damage, target, client);
	}
	
	return Plugin_Continue;
}

public Action:HookSound_Callback(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
	//to work only on melee sounds, its 'swish' or 'weaponswing'
	if (StrContains(StrSample, "Swish", false) == -1) return Plugin_Continue;
	//so the client has the melee sound playing. OMG HES MELEEING!
	
	if (Entity > MAXPLAYERS) return Plugin_Continue; // bugfix for some people on L4D2
	
	//add in a 1 second delay so this doesnt fire every frame
	if (MeleeDelay[Entity]) return Plugin_Continue; //note 'Entity' means 'client' here
	MeleeDelay[Entity] = true;
	CreateTimer(0.5, ResetMeleeDelay, Entity);
	
	#if DEBUG
	PrintToChatAll("Melee detected via soundhook.");
	#endif
	
	if (isincloud[Entity]) SetEntData(Entity, meleeentinfo, 1.5, 4);	
	
	return Plugin_Continue;
}

public Action:ResetMeleeDelay(Handle:timer, any:client)
{
	MeleeDelay[client] = false;
}

public Action:ClearMeleeBlock(Handle:timer, Handle:target)
{
	isincloud[target] = false;
}

public Action:StopShake(Handle:timer, any:target)
{
	if (!target || !IsClientInGame(target)) return;
	
	new Handle:hBf = StartMessageOne("Shake", target);
	BfWriteByte(hBf, 0);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	BfWriteFloat(hBf, 0.0);
	EndMessage();
}

stock bool:IsPlayerSpawnGhost(client)
{
	if (GetEntData(client, propinfoghost, 1)) return true;
	return false;
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

// timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684
// added some L4D specific checks
static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.10, timer_stock_applyDamage, dataPack);
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);
	
	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (!IsClientInGame(victim)) return;
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;
	
	new bool:reviveblock = GetConVarBool(CloudBlocksRevive);

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", reviveblock ? "65536" : "263168");
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	
	return isVisible;
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}