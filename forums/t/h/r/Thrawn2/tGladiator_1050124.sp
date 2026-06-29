#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define VERSION "1.0.0.0"

#define TEAM_UNSIG 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3
#define DF_FEIGNDEATH 32

new Handle:g_hCvarEnable = INVALID_HANDLE;
new Handle:g_hCvarGladiatorRatio = INVALID_HANDLE;
new Handle:g_hCvarHealth = INVALID_HANDLE;
new Handle:g_hCvarInterval = INVALID_HANDLE;
new Handle:g_hCvarChargePeriod = INVALID_HANDLE;
new Handle:g_hCvarChargeCooldown = INVALID_HANDLE;
new Handle:g_hCvarSpawn = INVALID_HANDLE;
new Handle:g_hCvarSpawnRandom = INVALID_HANDLE;

new Handle:g_hRedSpawns = INVALID_HANDLE;
new Handle:g_hBluSpawns = INVALID_HANDLE;
new Handle:g_hKv = INVALID_HANDLE;

new Handle:g_hSdkRegenerate;
new Handle:g_hGiveNamedItem;
new Handle:g_hWeaponEquip;
new Handle:g_hMessage;

new bool:g_bEnabled;
new bool:g_bIsGladiator[MAXPLAYERS+1];
new bool:g_bHasCharged[MAXPLAYERS+1];
new bool:g_bSpawnRandom;
new bool:g_bSpawnMap;

new Float:g_fSpawn;
new Float:g_fChargeCooldown;
new Float:g_fChargePeriod;
new g_iGladiatorRatio;
new g_iGladiatorHealth;

new Handle:g_hHudTimer;

public Plugin:myinfo =
{
	name = "tGladiator",
	author = "Thrawn",
	description = "TF2 Gladiator Mod",
	version = VERSION,
	url = "http://aaa.wallbash.com"
};

public OnPluginStart() {
	CreateConVar("sm_tgladiator", VERSION, "TF2 Gladiator version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnable = CreateConVar("sm_tgladiator_enable", "1", "Enable Gladiator Mod", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarGladiatorRatio = CreateConVar("sm_tgladiator_ratio", "4", "Each x players will be one more gladiator.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarHealth = CreateConVar("sm_tgladiator_health", "4000", "A gladiator will spawn with this amount of health.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarChargePeriod = CreateConVar("sm_tgladiator_chargeperiod", "2.0", "A gladiators charge can last up to x seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarChargeCooldown = CreateConVar("sm_tgladiator_chargefreq", "3.0", "A gladiator can charge every x seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarInterval = CreateConVar("sm_tgladiator_hudinterval", "0.5", "How often health timer is updated (in seconds).");
	g_hCvarSpawn = CreateConVar("sm_tgladiator_spawnfreq", "1.5", "Spawn timer.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCvarSpawnRandom = CreateConVar("sm_tgladiator_spawnrandom", "1", "Enable random spawns.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(g_hCvarInterval, Cvar_Changed_Interval);
	g_hMessage = CreateHudSynchronizer();

	g_hRedSpawns = CreateArray();
	g_hBluSpawns = CreateArray();

	SetupSDK();
	
	HookConVarChange(g_hCvarEnable, Cvar_Changed);
	HookConVarChange(g_hCvarGladiatorRatio, Cvar_Changed);
	HookConVarChange(g_hCvarHealth, Cvar_Changed);
	HookConVarChange(g_hCvarChargePeriod, Cvar_Changed);
	HookConVarChange(g_hCvarChargeCooldown, Cvar_Changed);
	HookConVarChange(g_hCvarSpawn, Cvar_Changed);
	

	HookEvent("player_death", Event_player_death);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("post_inventory_application", Event_InvApp);
	HookEvent("teamplay_round_start", Event_round_start);
	
	RegConsoleCmd("jointeam",       OnManualJoinTeam);
	
	AutoExecConfig(true, "plugin.tGladiator");
}

public Action:OnGetGameDescription(String:gameDesc[64]) {
	gameDesc = "tGladiator";
	return Plugin_Changed;
}

public OnMapStart() 
{
	g_hHudTimer = CreateTimer(GetConVarFloat(g_hCvarInterval), Timer_ShowGladiatorHealth, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	ClearArray(g_hRedSpawns);
	ClearArray(g_hBluSpawns);
	for(new i=0;i<MAXPLAYERS;i++) {
		PushArrayCell(g_hRedSpawns, CreateArray(6));
		PushArrayCell(g_hBluSpawns, CreateArray(6));
	}
	g_bSpawnMap = false;
	if(g_hKv!=INVALID_HANDLE)
		CloseHandle(g_hKv);
	g_hKv = CreateKeyValues("Spawns");

	decl String:map[64];
	GetCurrentMap(map, sizeof(map));

	decl String:path[256];
	decl String:filepath[256];
	Format(filepath, sizeof(filepath), "configs/tgladiator/%s.cfg", map);
	BuildPath(Path_SM, path, sizeof(path), filepath);
	if(FileExists(path)) {		
		LogMessage("On this map can be spawned!");
		g_bSpawnMap = true;
		FileToKeyValues(g_hKv, path);
		
		decl String:sTeam[5], Float:vectors[6], Float:origin[3], Float:angles[3];
		KvGotoFirstSubKey(g_hKv);	
		
		do {
			KvGetString(g_hKv, "team", sTeam, sizeof(sTeam));
			KvGetVector(g_hKv, "origin", origin);
			KvGetVector(g_hKv, "angles", angles);
			vectors[0] = origin[0];
			vectors[1] = origin[1];
			vectors[2] = origin[2];
			vectors[3] = angles[0];
			vectors[4] = angles[1];
			vectors[5] = angles[2];
			
			if(strcmp(sTeam,"red") == 0 || strcmp(sTeam,"both") == 0) {
				for(new i=0;i<MAXPLAYERS;i++)
					PushArrayArray(GetArrayCell(g_hRedSpawns, i), vectors);
			}

			if(strcmp(sTeam,"blue") == 0 || strcmp(sTeam,"both") == 0) {
				for(new i=0;i<MAXPLAYERS;i++)
					PushArrayArray(GetArrayCell(g_hBluSpawns, i), vectors);
			}
		} while(KvGotoNextKey(g_hKv));			
		
	} else {
		LogError("File Not Found: %s", path);
	}
	//PrecacheModel("models/tf2dm/tf2logo1.mdl", true);
	PrecacheSound("items/spawn_item.wav", true);    
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	new ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "team_round_timer"))!=-1)
	{		
		SetVariantInt(60*30);
		AcceptEntityInput(ent, "SetMaxTime");	
		SetVariantInt(60*30);
		AcceptEntityInput(ent, "SetTime");		
	}

	/*	
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_regenerate"))!=-1)
		AcceptEntityInput(ent, "Disable");
	*/
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "team_control_point_master"))!=-1)
		AcceptEntityInput(ent, "Disable");
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "team_control_point"))!=-1)
		AcceptEntityInput(ent, "Disable");
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "trigger_capture_area"))!=-1)
		AcceptEntityInput(ent, "Disable");
	ent = MaxClients+1;		
}

stock SetupSDK()
{
    new Handle:hGameConf = LoadGameConfigFile("sm-tf2.resupply");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"Regenerate");
        g_hSdkRegenerate = EndPrepSDKCall();
                        
        CloseHandle(hGameConf);
    } else {
        SetFailState("Couldn't load SDK functions.");
    }

    hGameConf = LoadGameConfigFile("unlock.games");
    if (hGameConf != INVALID_HANDLE)
    {
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveNamedItem");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
		g_hGiveNamedItem = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "WeaponEquip");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hWeaponEquip = EndPrepSDKCall();    

		CloseHandle(hGameConf);
    } else {
        SetFailState("Couldn't load SDK functions.");
    }
    
}


public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	g_iGladiatorHealth = GetConVarInt(g_hCvarHealth);
	g_iGladiatorRatio = GetConVarInt(g_hCvarGladiatorRatio);
	g_fChargeCooldown = GetConVarFloat(g_hCvarChargeCooldown);
	g_fChargePeriod = GetConVarFloat(g_hCvarChargePeriod);
	g_fSpawn = GetConVarFloat(g_hCvarSpawn);
	g_bSpawnRandom = GetConVarBool(g_hCvarSpawnRandom);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();	
}

public Cvar_Changed_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    if (g_hHudTimer != INVALID_HANDLE) 
        KillTimer(g_hHudTimer);
    
    g_hHudTimer = CreateTimer(GetConVarFloat(g_hCvarInterval), Timer_ShowGladiatorHealth, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}



public Action:OnManualJoinTeam(client, args)
{
    if (GetClientTeam(client) != TEAM_RED && GetClientTeam(client) != TEAM_BLUE)
    {
        MakeHimPeasant(client);
        return Plugin_Handled;
    }
    
    // FIXME: Add the possibility for gladiators to switch team --> get a replacement
    
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	g_bIsGladiator[client] = false;
	g_bHasCharged[client] = false;
	
	if(g_bEnabled) {		
		LogMessage("Player hooked");
		SDKHook(client, SDKHook_PreThink, OnPreThink);		

		CreateTimer(0.1,SetClientMode,client);
	}		
}

public OnClientDisconnect(client)
{
	if(g_bEnabled) {
		if(g_bIsGladiator[client]) {
			g_bIsGladiator[client] = false;
									
			PickRandomGladiator(client);
		}
	}
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		//CreateTimer(0.1,SchetClientMode,client);

		if(g_bSpawnRandom && g_bSpawnMap) {
			CreateTimer(0.1, RandomSpawn, client);
		}
	}
}

public Action:Event_InvApp(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
		CreateTimer(0.1,SetClientMode,client);
	}
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bEnabled) {
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new deathFlags = GetEventInt(event, "death_flags");

		if (deathFlags & DF_FEIGNDEATH)		//skip dead ringer
			return Plugin_Continue;

		if(g_bIsGladiator[victim]) {
			g_bIsGladiator[victim] = false;
		
			//A Gladiator has been killed, hurray
			if(attacker == victim) {
				//The fool killed himself
				PickRandomGladiator(victim);
			}

			if(attacker > 0 && IsClientInGame(attacker) ) {
				//Has been killed by another player
				g_bIsGladiator[attacker] = true;
				CreateTimer(g_fSpawn, Respawn, attacker);
			} else {
				//By world
				PickRandomGladiator(victim);
			}
		} else {
			if (g_bIsGladiator[attacker] && IsClientInGame(attacker) && attacker != victim ) {
				decl String:msg[192];	
				Format(msg, sizeof(msg), "\x04%N \x01killed you with \x04%d \x01hp left", attacker, GetClientHealth(attacker));
				PrintToChat(victim, msg);	
			}		
		}

		CreateTimer(g_fSpawn, Respawn, victim);
	}
	return Plugin_Continue;
}

public Action:Respawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsClientOnTeam(client)) {
		TF2_RespawnPlayer(client);
	}
}

public Action:RandomSpawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		new team = GetClientTeam(client), Handle:array, size, Handle:spawns = CreateArray(), count = GetClientCount();
		decl Float:vectors[6], Float:origin[3], Float:angles[3];
		if(team==2) {
			for(new i=0;i<=count;i++) {
				array = GetArrayCell(g_hRedSpawns, i);
				if(GetArraySize(array)!=0)
					size = PushArrayCell(spawns, array);
			}
		} else {
			for(new i=0;i<=count;i++) {
				array = GetArrayCell(g_hBluSpawns, i);
				if(GetArraySize(array)!=0)
					size = PushArrayCell(spawns, array);
			}
		}
		array = GetArrayCell(spawns, GetRandomInt(0, GetArraySize(spawns)-1));
		size = GetArraySize(array);
		GetArrayArray(array, GetRandomInt(0, size-1), vectors);
		CloseHandle(spawns);
		origin[0] = vectors[0];
		origin[1] = vectors[1];
		origin[2] = vectors[2];
		angles[0] = vectors[3];
		angles[1] = vectors[4];
		angles[2] = vectors[5];
		
		TeleportEntity(client, origin, angles, NULL_VECTOR);
		EmitAmbientSound("items/spawn_item.wav", origin);
	}
}

public OnPreThink(client)
{
	if(g_bIsGladiator[client]) {
		new iButtons = GetClientButtons(client);
		if(!g_bHasCharged[client] && iButtons & IN_ATTACK2)
		{
			g_bHasCharged[client] = true;
			TF2_AddCond(client, 17);			
			CreateTimer(g_fChargePeriod,ChargePeriodOff, client);
			CreateTimer(g_fChargeCooldown, ChargeCooldownOff, client);
		}
    }
}

public Action:ChargePeriodOff(Handle:timer, any:client) {
	TF2_RemoveCond(client, 17);
}

public Action:ChargeCooldownOff(Handle:timer, any:client) {
	g_bHasCharged[client] = false;
}

public Action:SetClientMode(Handle:timer, any:client)
{
	new iBluTeamCount = GetTeamClientCount(TEAM_BLUE);
	new iGladiatorCount = GetGladiatorCount();		

	new iGladiatorsRequired = iBluTeamCount / g_iGladiatorRatio;
	if (iGladiatorsRequired < 1)
		iGladiatorsRequired = 1;

	if(iGladiatorCount < iGladiatorsRequired) {
		//Spawn as gladiator, because there is one missing
		PrintToChat(client, "Because there are no gladiators around you have been chosen as the new one");
		g_bIsGladiator[client] = true;
	}			

	if(g_bIsGladiator[client]) {			
		MakeHimGladiator(client);
	} else {
		MakeHimPeasant(client);
	}
}

public Action:Timer_ShowGladiatorHealth(Handle:timer) {
    for (new i = 1; i <= MaxClients; i++) 
	{
        if (g_bIsGladiator[i] && IsClientInGame(i) && !IsFakeClient(i)) 
		{
            SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
            ShowSyncHudText(i, g_hMessage, "Health: %d", GetClientHealth(i));
        }
    }

    return Plugin_Continue;
}

public PickRandomGladiator(victim) {
	// FIXME: rather pick one who hasnt been gladiator before.
	// And out of them, the weakest one.
	// He wants to have fun too.	

	new players[MaxClients+1];
	new count;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != victim)
		{
			players[count++] = i;
		}
	}

	if (count > 0)
	{
		new iGladiator = players[GetRandomInt(0,count-1)];
		g_bIsGladiator[iGladiator] = true;
		CreateTimer(g_fSpawn, Respawn, iGladiator);
	}
}

public MakeHimGladiator(client) {
	g_bIsGladiator[client] = true;
	
	if(GetClientTeam(client) != TEAM_RED) {
		//He's a Gladiator but not on Team Red
		ChangeClientTeam(client, TEAM_RED);
	}

	new TFClassType:class = TF2_GetClass("demoman");
	TF2_SetPlayerClass(client, class, false, true);

	SDKCall(g_hSdkRegenerate, client);
	
	TF2_AddCond(client, 16);
	
	if(IsADrunkenFool(client)) {
		//FIXME: Set Real properties, setting the speed is wrong
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);		
	} else {
		//Give him the right speed
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);

		//Give him health
		SetEntProp(client, Prop_Send, "m_iHealth", g_iGladiatorHealth);		
	}	

	if(!IsFakeClient(client)) {
		if(GetPlayerWeaponSlot(client, 0) != -1)
			TF2_RemoveWeaponSlot(client, 0);

		if(GetPlayerWeaponSlot(client, 1) != -1)			
			TF2_RemoveWeaponSlot(client, 1);
			
		ClientCommand(client,"slot3");
	}		
}

public IsADrunkenFool(client) {
	return false;
}

public MakeHimPeasant(client) {
	g_bIsGladiator[client] = false;
	if(GetClientTeam(client) != TEAM_BLUE) {
		LogMessage("You have been killed and are no gladiator anymore!");
		//He's a Peasant but not on Team Blue
		ChangeClientTeam(client, TEAM_BLUE);
	}		

	PrintToChat(client, "You are just a simple peasant. Kill the Gladiator!");

	//Dont allow Engineers, Spies or Demoman on the peasant team
	new TFClassType:class = TF2_GetPlayerClass(client);
	if(class == TFClass_Engineer || class == TFClass_Spy || class == TFClass_DemoMan) {
		TF2_SetPlayerClass(client, TFClassType:TFClass_Soldier);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
		SetEntProp(client, Prop_Send, "m_iHealth", 200);							
		
		SDKCall(g_hSdkRegenerate, client);

		CreateTimer(0.1,StripWeapons,client);
	}
	
}

public Action:StripWeapons(Handle:timer, any:client) {
	if(IsPlayerAlive(client)) {
		for(new i = 0; i < 5; i++) {
			if((GetPlayerWeaponSlot(client, i))!=-1) {			
				new weaponIndex;
				while((weaponIndex = GetPlayerWeaponSlot(client, i))!=-1) {
					RemovePlayerItem(client, weaponIndex);
					RemoveEdict(weaponIndex);
				}
			}
		}

		new weapShovel = SDKCall(g_hGiveNamedItem, client, "tf_weapon_shovel", 0);
		SDKCall(g_hWeaponEquip, client, weapShovel);

		new weapShotgun = SDKCall(g_hGiveNamedItem, client, "tf_weapon_shotgun_soldier", 0);
		SDKCall(g_hWeaponEquip, client, weapShotgun);

		new weapLauncher = SDKCall(g_hGiveNamedItem, client, "tf_weapon_rocketlauncher", 0);
		SDKCall(g_hWeaponEquip, client, weapLauncher);		
	}
}

public GetGladiatorCount() {
	new count = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_bIsGladiator[i]) {
			count++;
		}
	}	
	
	return count;
}

stock TF2_AddCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED));
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "addcond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}
stock TF2_RemoveCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED));
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
} 

IsClientOnTeam(client) {
	new team = GetClientTeam(client);
	return team==2||team==3;
}