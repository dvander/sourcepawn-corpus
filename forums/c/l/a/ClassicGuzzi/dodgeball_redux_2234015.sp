// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <tf2attributes>
#include <steamtools>

// ---- Defines ----------------------------------------------------------------
#define DB_VERSION "0.1.2"
#define PLAYERCOND_SPYCLOAK (1<<4)
#define PLAYER_SPEED 300.0
#define BASE_SPEED 1100.0
#define TRED 2
#define TBLUE 3
#define SOUND_SPAWN	"weapons/sentry_rocket.wav"
#define SOUND_ALERT	"weapons/sentry_spot.wav"
#define SOUND_ALERT_VOL	0.8
#define NO_VELCHANGE_TIME 5

//Colors
#define DEF_R 63
#define DEF_G 255
#define DEF_B 127
#define ALERT_R 255
#define ALERT_G 0
#define ALERT_B 0


enum db_Hud
{
    Handle:hud_Speed,
	Handle:hud_Reflects,
    Handle:hud_Owner,
    Handle:hud_Target,
    Handle:hud_SuperShot
}

// ---- Variables --------------------------------------------------------------
new bool:g_isDBmap = false;
new bool:g_onPreparation = false;
new bool:g_roundActive = false;
new g_BlueSpawn = -1;
new g_RedSpawn = -1;
new g_RocketEnt = -1;
new g_RocketBounces = 0;
new g_RocketTarget= -1;
new bool:g_RocketAimed = false;
new Float:g_RocketDirection[3] = { 0.0, 0.0, 0.0};
new g_DeflectCount = 0;
new g_observer = -1;

new g_notchangetime = 0;

new g_HudSyncs[db_Hud];

// ---- Plugin's CVars Management ----------------------------------------------
new bool:g_Enabled;
new bool:g_OnlyPyro;
new Float:g_SpawnTime;
new Float:g_BaseDamage;
new Float:g_SpeedMul;
new Float:g_DeflectInc;
new Float:g_Turnrate;
new bool:g_TargetClosest;
new bool:g_AllowAim;
new Float:g_AimedSpeedMul;
new bool:g_ShowInfo;
new g_MaxBounce;
new bool:g_BlockFT;

new Handle:db_Enabled;
new Handle:db_OnlyPyro;
new Handle:db_SpawnTime;
new Handle:db_BaseDamage;
new Handle:db_SpeedMul;
new Handle:db_DeflectInc;
new Handle:db_Turnrate;
new Handle:db_TargetClosest;
new Handle:db_AllowAim;
new Handle:db_AimedSpeedMul;
new Handle:db_ShowInfo;
new Handle:db_MaxBounce;
new Handle:db_BlockFT;

// ---- Server's CVars Management ----------------------------------------------
new Handle:db_airdash;
new Handle:db_push;
new Handle:db_burstammo;

new db_airdash_def = 1;
new db_push_def = 1;
new db_burstammo_def = 1;

// ---- Plugin's Information ---------------------------------------------------
public Plugin:myinfo =
{
	name	= "[TF2] Dodgeball Redux",
	author	= "Classic",
	description	= "Dodgeball plugin for TF2",
	version	= DB_VERSION,
	url	= "http://www.clangs.com.ar"
};

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_db_version", DB_VERSION, "Dogdeball Redux Version.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	db_Enabled		= CreateConVar("sm_db_enabled", "1", "Enables / Disables the Dodgeball Redux plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	db_OnlyPyro	= CreateConVar("sm_db_onlypyro", "0", "Force players to pyro class.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	db_SpawnTime	= CreateConVar("sm_db_rocket_spawntime", "2.0", "Time that takes to re-spawn a new rocket.", FCVAR_PLUGIN, true, 0.1);
	db_BaseDamage	= CreateConVar("sm_db_rocket_basedamage", "200", "Base damage of the rocket. It will be bigger than this, because it will be crit. ", FCVAR_PLUGIN, true, 1.0);
	db_SpeedMul	= CreateConVar("sm_db_rocket_speedmul","0.9", "Value that the base rocket speed (1100) is multiplied by for the initial speed.", FCVAR_PLUGIN, true, 0.0);
	db_DeflectInc	= CreateConVar("sm_db_rocket_deflectinc", "0.05", "Increment of the speed on every reflect", FCVAR_PLUGIN, true, 0.0);
	db_Turnrate	= CreateConVar("sm_db_rocket_turnrate", "0.05", "Turn rate per tick" , FCVAR_PLUGIN, true, 0.0);
	db_TargetClosest	= CreateConVar("sm_db_target_closest", "1", "Select a the closest target on deflect. If it's 0 it will be random.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	db_AllowAim	= CreateConVar("sm_db_target_allowaim", "1", "If the player is aiming to another player, the rocket will go to that player.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	db_AimedSpeedMul	= CreateConVar("sm_db_aimedSpeedMul", "1.5", "Speed multiplier when a rocket is deflected aiming, this will revert after the next defelct.", FCVAR_PLUGIN, true, 0.0);
	db_ShowInfo = CreateConVar("sm_db_showinfo", "1", "Shows Rocket's information on screen",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	db_MaxBounce = CreateConVar("sm_db_maxbounce", "10", "Max time that a rocket can bounce on walls.",FCVAR_PLUGIN, true, 0.0);
	db_BlockFT = CreateConVar("sm_db_block_flamethrower", "1", "If true, the plugin would block the rainblower and the Degreaser",FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_Enabled = GetConVarBool(db_Enabled);
	g_OnlyPyro = GetConVarBool(db_OnlyPyro);
	g_SpawnTime = GetConVarFloat(db_SpawnTime);
	g_BaseDamage = GetConVarFloat(db_BaseDamage);
	g_SpeedMul = GetConVarFloat(db_SpeedMul);
	g_DeflectInc = GetConVarFloat(db_DeflectInc);
	g_Turnrate = GetConVarFloat(db_Turnrate);
	g_TargetClosest = GetConVarBool(db_TargetClosest);
	g_AllowAim = GetConVarBool(db_AllowAim);
	g_AimedSpeedMul = GetConVarFloat(db_AimedSpeedMul);
	g_ShowInfo = GetConVarBool(db_ShowInfo);
	g_MaxBounce = GetConVarInt(db_MaxBounce);
	g_BlockFT = GetConVarBool(db_BlockFT);
		
	//Cvars's hook
	HookConVarChange(db_Enabled, OnCVarChange);
	HookConVarChange(db_OnlyPyro, OnCVarChange);
	HookConVarChange(db_SpawnTime, OnCVarChange);
	HookConVarChange(db_BaseDamage, OnCVarChange);
	HookConVarChange(db_SpeedMul, OnCVarChange);
	HookConVarChange(db_DeflectInc, OnCVarChange);
	HookConVarChange(db_Turnrate, OnCVarChange);
	HookConVarChange(db_TargetClosest, OnCVarChange);
	HookConVarChange(db_AllowAim, OnCVarChange);
	HookConVarChange(db_AimedSpeedMul, OnCVarChange);
	HookConVarChange(db_ShowInfo, OnCVarChange);
	HookConVarChange(db_MaxBounce, OnCVarChange);
	HookConVarChange(db_BlockFT, OnCVarChange);
	
	//Server's Cvars
	db_airdash = FindConVar("tf_scout_air_dash_count");
	db_push = FindConVar("tf_avoidteammates_pushaway");
	db_burstammo = FindConVar("tf_flamethrower_burstammo");

	//HUD
	g_HudSyncs[hud_Speed] = CreateHudSynchronizer();
	g_HudSyncs[hud_Reflects] = CreateHudSynchronizer();
	g_HudSyncs[hud_Owner] = CreateHudSynchronizer();
	g_HudSyncs[hud_Target] = CreateHudSynchronizer();
	g_HudSyncs[hud_SuperShot] = CreateHudSynchronizer();
	
	//Hooks
	HookEvent("teamplay_round_start", OnPrepartionStart);
	HookEvent("arena_round_start", OnRoundStart); 
	HookEvent("post_inventory_application", OnPlayerInventory);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_round_stalemate", OnRoundEnd);
	
	// Precache sounds
	PrecacheSound(SOUND_SPAWN, true);
	PrecacheSound(SOUND_ALERT, true);
	
	AutoExecConfig(true, "plugin.dodgeball_redux");
	AddServerTag("dodgeball");
}

/* OnCVarChange()
**
** We edit the global variables values when their corresponding cvar changes.
** -------------------------------------------------------------------------- */
public OnCVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar ==  db_Enabled)
		g_Enabled = GetConVarBool(db_Enabled);
	if(convar ==  db_OnlyPyro)
		g_OnlyPyro = GetConVarBool(db_OnlyPyro);
	if(convar ==  db_SpawnTime)
		g_SpawnTime = GetConVarFloat(db_SpawnTime);
	if(convar ==  db_BaseDamage)
		g_BaseDamage = GetConVarFloat(db_BaseDamage);
	if(convar ==  db_SpeedMul)
		g_SpeedMul = GetConVarFloat(db_SpeedMul);
	if(convar ==  db_DeflectInc)
		g_DeflectInc = GetConVarFloat(db_DeflectInc);
	if(convar ==  db_Turnrate)
		g_Turnrate = GetConVarFloat(db_Turnrate);
	if(convar ==  db_TargetClosest)		
		g_TargetClosest = GetConVarBool(db_TargetClosest);
	if(convar ==  db_AllowAim)
		g_AllowAim = GetConVarBool(db_AllowAim);
	if(convar ==  db_AimedSpeedMul)
		g_AimedSpeedMul = GetConVarFloat(db_AimedSpeedMul);
	if(convar ==  db_ShowInfo)		
		g_ShowInfo = GetConVarBool(db_ShowInfo);
	if(convar ==  db_MaxBounce)		
		g_MaxBounce = GetConVarInt(db_MaxBounce);
	if(convar ==  db_BlockFT)		
		g_BlockFT = GetConVarBool(db_BlockFT);

}


/* OnMapStart()
**
** Here we reset every global variable, and we check if the current map is a dodgeball map.
** If it is a db map, we get the cvars def. values and the we set up our own values.
** -------------------------------------------------------------------------- */
public OnMapStart()
{	
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (g_Enabled && (strncmp(mapname, "db_", 3, false) == 0 || (strncmp(mapname, "tfdb_", 5, false) == 0) ))
	{
		LogMessage("[DB] Dodgeball map detected. Enabling Dodgeball Gamemode.");
		g_isDBmap = true;
		Steam_SetGameDescription("Dodgeball Redux");
	}
 	else
	{
		LogMessage("[DB] Current map is not a Dodgeball map. Disabling Dodgeball Gamemode.");
		g_isDBmap = false;
		Steam_SetGameDescription("Team Fortress");	
	}
}

/* OnMapEnd()
**
** Here we reset the server's cvars to their default values.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
	ResetCvars();
}



/* OnPrepartionStart()
**
** We setup the cvars again and we freeze the players.
** -------------------------------------------------------------------------- */
public Action:OnPrepartionStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_Enabled || !g_isDBmap) return;
	
	g_onPreparation = true;
	
	//We force the cvars values needed every round (to override if any cvar was changed).
	SetupCvars();

	//Players shouldn't move until the round starts
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
			SetEntityMoveType(i, MOVETYPE_NONE);	
	if(g_ShowInfo)
		ShowHud(20.0,_,_,_,_);
}

/* OnRoundStart()
**
** We unfreeze every player.
** -------------------------------------------------------------------------- */
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_Enabled || !g_isDBmap) return;
	SearchSpawns();
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_WALK);
	g_onPreparation = false;
	g_roundActive = true;
	if(GetRandomInt(0,1))
		CreateTimer(0.1, FireRocket,  TRED);
	else
		CreateTimer(0.1, FireRocket,  TBLUE);

}

/* OnRoundEnd()
**
** Here we destroy the rocket.
** -------------------------------------------------------------------------- */
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_roundActive=false;
	if(g_RocketEnt != -1)
	{	
		if (IsValidEntity(g_RocketEnt)) 
			RemoveEdict(g_RocketEnt);
	}
}

/* OnPlayerInventory()
**
** Here we strip players weapons (if we have to).
** Also we give special melee weapons (again, if we have to).
** -------------------------------------------------------------------------- */
public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Enabled && g_isDBmap)
	{
		new bool:replace_primary = true;
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item1);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Item2);
		
		//We kill the demomen's shield on this preparation.
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
		{
			AcceptEntityInput(ent, "kill");
		}
		
		decl String:classname[64];
		new wep_ent = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(wep_ent > MaxClients && IsValidEntity(wep_ent))
		{
			new wep_index = GetEntProp(wep_ent, Prop_Send, "m_iItemDefinitionIndex"); 
			if (wep_ent > MaxClients && IsValidEdict(wep_ent) && GetEdictClassname(wep_ent, classname, sizeof(classname)))
			{	
				if (StrEqual(classname, "tf_weapon_flamethrower", false) )
				{
					if( (wep_index != 215 && wep_index != 741) || !g_BlockFT)
					{
						TF2Attrib_SetByDefIndex(wep_ent, 254, 4.0);
						replace_primary = false; 
					}
				}
			}
		}
		if(replace_primary)
		{
		
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			
			new Handle:hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
			TF2Items_SetClassname(hItem, "tf_weapon_flamethrower");
			TF2Items_SetItemIndex(hItem, 21);
			TF2Items_SetLevel(hItem, 69);
			TF2Items_SetQuality(hItem, 6);
			TF2Items_SetAttribute(hItem, 0, 254, 4.0); //Can't push other players
			TF2Items_SetNumAttributes(hItem, 1);
			new iWeapon = TF2Items_GiveNamedItem(client, hItem);
			CloseHandle(hItem);
			EquipPlayerWeapon(client, iWeapon);
		}
		
		TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
		
	
	}
}

/* OnPlayerSpawn()
**
** Here we set the spy cloak and we move the death player.
** -------------------------------------------------------------------------- */
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new TFClassType:iClass;
	if(g_Enabled && g_isDBmap)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		iClass = TF2_GetPlayerClass(client);
		if(g_OnlyPyro)
		{			
			if (!(iClass == TFClass_Pyro || iClass == TFClassType:TFClass_Unknown))
			{
				TF2_SetPlayerClass(client, TFClass_Pyro, false, true);
				TF2_RespawnPlayer(client);
			}
		}
		else if(iClass == TFClass_Spy)
		{
			new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
			
			if (cond & PLAYERCOND_SPYCLOAK)
			{
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
			}
		}
		if(g_onPreparation)
			SetEntityMoveType(client, MOVETYPE_NONE);	
	}
}

/* SearchSpawns()
**
** Searchs for blue and red rocket spawns
** -------------------------------------------------------------------------- */
public SearchSpawns()
{
	if(!g_Enabled || !g_isDBmap) return;
	new iEntity = -1;
	g_RedSpawn = -1;
	g_BlueSpawn = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		decl String:strName[32]; 
		GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
		{
			g_RedSpawn = iEntity;
		}
		if ((StrContains(strName, "rocket_spawn_blue") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
		{
			g_BlueSpawn = iEntity;
		}
	}
	
	if (g_RedSpawn == -1) SetFailState("No RED spawn points found on this map.");
	if (g_BlueSpawn == -1) SetFailState("No BLU spawn points found on this map.");
	
	//ObserverPoint
	new Float:opPos[3];
	new Float:opAng[3];
	
	new spawner = GetRandomInt(0,1);
	if(spawner == 0)
		spawner = g_RedSpawn;
	else
		spawner = g_BlueSpawn;
	if(IsValidEntity(spawner)&& spawner > MaxClients)
	{
		GetEntPropVector(spawner,Prop_Data,"m_vecOrigin",opPos);
		GetEntPropVector(spawner,Prop_Data, "m_angAbsRotation", opAng);
		g_observer = CreateEntityByName("info_observer_point");
		DispatchKeyValue(g_observer, "Angles", "90 0 0");
		DispatchKeyValue(g_observer, "TeamNum", "0");
		DispatchKeyValue(g_observer, "StartDisabled", "0");
		DispatchSpawn(g_observer);
		AcceptEntityInput(g_observer, "Enable");
		TeleportEntity(g_observer, opPos, opAng, NULL_VECTOR);
	}
	else
	{
		g_observer = -1;
	}
	return;
}


/* SearchTarget()
**
** Searchs for a new Target
** -------------------------------------------------------------------------- */
public SearchTarget()
{
	if(!g_Enabled || !g_isDBmap) return;
	if(g_RocketEnt <= 0) return;
	new rTeam = GetEntProp(g_RocketEnt, Prop_Send, "m_iTeamNum", 1);
	
	//Check by aim
	if(g_AllowAim)
	{
		new rOwner = GetEntPropEnt(g_RocketEnt, Prop_Send, "m_hOwnerEntity");
		if(rOwner != 0)
		{
			new cAimed = GetClientAimTarget(rOwner, true);
			if( cAimed > 0 && cAimed < MaxClients && IsPlayerAlive(cAimed) && GetClientTeam(cAimed) != rTeam )
			{
				g_RocketTarget= cAimed;
				g_RocketAimed = true;
				//PrintCenterText(rOwner,"Super shot to %N!!",cAimed);
				return;
			}
		}
	}
	g_RocketAimed = false;
	//We make a list of possibles players
	new possiblePlayers[MAXPLAYERS+1];
	new possibleNumber = 0;
	for(new i = 1; i <= MaxClients ; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == rTeam )
			continue;
		possiblePlayers[possibleNumber] = i;
		possibleNumber++;
	}
	//If there weren't any player the could be targeted
	if(possibleNumber == 0)
	{
		g_RocketTarget= -1;
		if(g_roundActive)
			LogError("[DB] Tried to fire a rocket but there weren't any player available.");
		return;
	}
	
	//Random player
	if(!g_TargetClosest)
		g_RocketTarget= possiblePlayers[ GetRandomInt(0,possibleNumber-1)];
	
	//We find the closest player in the valid players vector
	else
	{
		//Some aux variables
		new Float:aux_dist;
		new Float:aux_pos[3];
		//Rocket's position
		new Float:rPos[3];
		GetEntPropVector(g_RocketEnt, Prop_Send, "m_vecOrigin", rPos);
		
		//First player in the list will be the current closest player
		new closest = possiblePlayers[0];
		GetClientAbsOrigin(closest,aux_pos);
		new Float:closest_dist = GetVectorDistance(rPos,aux_pos, true);
		
		
		for(new i = 1; i < possibleNumber; i++)
		{
			//We use the squared option for optimization since we don't need the absolute distance.
			GetClientAbsOrigin(possiblePlayers[i],aux_pos);
			aux_dist = GetVectorDistance(rPos, aux_pos, true);
			if(closest_dist > aux_dist)
			{
				closest = possiblePlayers[i];
				closest_dist = aux_dist;
			}
		}
		g_RocketTarget= closest;
	}
	

}
/* FireRocket()
**
** Timer used to spawn a new rocket.
** -------------------------------------------------------------------------- */
public Action:FireRocket(Handle:timer, any:rocketTeam)
{
	if(!g_Enabled || !g_isDBmap || !g_roundActive) return;
	new spawner;
	if(rocketTeam == TRED)
		spawner = g_RedSpawn;
	else if(rocketTeam == TBLUE)
		spawner = g_BlueSpawn;
	else
		SetFailState("Tried to fire a rocket for other team than red or blue.");

	new iEntity = CreateEntityByName( "tf_projectile_rocket");
	if (iEntity && IsValidEntity(iEntity))
	{
		// Fetch spawn point's location and angles.
		new Float:fPosition[3], Float:fAngles[3], Float:fDirection[3], Float:fVelocity[3];
		GetEntPropVector(spawner, Prop_Send, "m_vecOrigin", fPosition);
		GetEntPropVector(spawner, Prop_Send, "m_angRotation", fAngles);
		GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		CopyVectors(fDirection, g_RocketDirection);
		
		// Setup rocket entity.
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
		SetEntProp(iEntity,	Prop_Send, "m_bCritical",	 1);
		SetEntProp(iEntity,	Prop_Send, "m_iTeamNum",	 rocketTeam, 1); 
		SetEntProp(iEntity,	Prop_Send, "m_iDeflected",   1);
		
		new Float:aux_mul= BASE_SPEED*g_SpeedMul;
		fVelocity[0] = fDirection[0]*aux_mul;
		fVelocity[1] = fDirection[1]*aux_mul;
		fVelocity[2] = fDirection[2]*aux_mul;
		TeleportEntity(iEntity, fPosition, fAngles, fVelocity);
		
		SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, g_BaseDamage, true);
		DispatchSpawn(iEntity);
		
		g_RocketEnt = iEntity;
		SDKHook(iEntity, SDKHook_StartTouch, OnStartTouch);
		g_RocketBounces = 0;
		SearchTarget();
		EmitSoundToAll(SOUND_SPAWN, iEntity);
		if( g_RocketTarget > 0 && g_RocketTarget < MaxClients)
			EmitSoundToClient(g_RocketTarget, SOUND_ALERT, _, _, _, _, SOUND_ALERT_VOL);
			
		ShowHud(10.0,aux_mul,g_DeflectCount,0,g_RocketTarget);
		//Observer
		if(IsValidEntity(g_observer))
		{
			TeleportEntity(g_observer, fPosition, fAngles, Float:{0.0, 0.0, 0.0});
			SetVariantString("!activator");
			AcceptEntityInput(g_observer, "SetParent", g_RocketEnt);
		}

	}
}

public Action:OnStartTouch(entity, other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	// Only allow a rocket to bounce x times.
	if (g_RocketBounces >= g_MaxBounce)
		return Plugin_Continue;
	
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action:OnTouch(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);

	g_RocketBounces++;
	g_notchangetime = NO_VELCHANGE_TIME;
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public bool:TEF_ExcludeEntity(entity, contentsMask, any:data)
{
	return (entity != data);
}

/* OnGameFrame()
**
** We set the player max speed on every frame, and also we set the spy's cloak on empty.
** Here we also check what to do with the rocket. We checks for deflects and modify the rocket's speed.
** -------------------------------------------------------------------------- */
public OnGameFrame()
{
	
	if(g_Enabled && g_isDBmap)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", PLAYER_SPEED);
				if(TF2_GetPlayerClass(i) == TFClass_Spy)
				{
					SetCloak(i, 1.0);
				}
			}
		}
		//Rocket Management
		if(g_RocketEnt > 0 && g_roundActive) 
		{
			new rOwner = GetEntPropEnt(g_RocketEnt, Prop_Send, "m_hOwnerEntity");
			
			//Check if the target is available
			if(g_RocketTarget < 0 || g_RocketTarget > MaxClients || !IsClientConnected(g_RocketTarget) ||	!IsClientInGame(g_RocketTarget) || !IsPlayerAlive(g_RocketTarget))
			{
				SearchTarget();
			}
			
			//Check deflects
			new rDef  = GetEntProp(g_RocketEnt, Prop_Send, "m_iDeflected") - 1;
			new Float:aux_mul = 0.0;
			if(rDef > g_DeflectCount)
			{
				new Float:fViewAngles[3], Float:fDirection[3];
				GetClientEyeAngles(g_RocketTarget, fViewAngles);
				GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
				CopyVectors(fDirection, g_RocketDirection);
				
				SearchTarget();
				g_DeflectCount++;
				if( g_RocketTarget > 0 && g_RocketTarget < MaxClients)
				{
					EmitSoundToClient(g_RocketTarget, SOUND_ALERT, _, _, _, _, SOUND_ALERT_VOL);	
					if(g_RocketAimed)
					{
						EmitSoundToClient(g_RocketTarget, SOUND_SPAWN, _, _, _, _, SOUND_ALERT_VOL);	
						if (rOwner > 0 && rOwner <= MaxClients)
							EmitSoundToClient(rOwner, SOUND_SPAWN, _, _, _, _, SOUND_ALERT_VOL);	
							
						SetHudTextParams(-1.0, -1.0, 1.5, ALERT_R, ALERT_G, ALERT_B, 255, 2, 0.28 , 0.1, 0.1);
						ShowSyncHudText(rOwner, g_HudSyncs[hud_SuperShot], "Super Shot!");
					}
				}
				if(g_ShowInfo)
				{
					aux_mul = BASE_SPEED * g_SpeedMul * (1 + g_DeflectInc * rDef);
					ShowHud(10.0,aux_mul,g_DeflectCount,rOwner,g_RocketTarget);
				}
			}
			//If isn't a deflect then we have to modify the rocket's direction and velocity
			else
			{
				if(g_RocketTarget > 0 && g_RocketTarget <= MaxClients)
				{
					decl Float:fDirectionToTarget[3]; 
					CalculateDirectionToClient(g_RocketEnt, g_RocketTarget, fDirectionToTarget);
					LerpVectors(g_RocketDirection, fDirectionToTarget, g_RocketDirection, g_Turnrate);
				}
			}
			
			decl Float:fAngles[3]; GetVectorAngles(g_RocketDirection, fAngles);
			decl Float:fVelocity[3]; CopyVectors(g_RocketDirection, fVelocity);
			
			if(aux_mul == 0.0)
				aux_mul = BASE_SPEED * g_SpeedMul * (1 + g_DeflectInc * rDef);
			if(g_AllowAim && g_RocketAimed)
				aux_mul *= g_AimedSpeedMul;
			fVelocity[0] = g_RocketDirection[0]*aux_mul;
			fVelocity[1] = g_RocketDirection[1]*aux_mul;
			fVelocity[2] = g_RocketDirection[2]*aux_mul;
			if(g_notchangetime > 0)
				g_notchangetime--;
			else
			{
				SetEntPropVector(g_RocketEnt, Prop_Data, "m_vecAbsVelocity", fVelocity);
				SetEntPropVector(g_RocketEnt, Prop_Send, "m_angRotation", fAngles);
			}
			
		}
	}
}
/* OnEntityDestroyed()
**
** We check if the rocket got destroyed, and then fire a timer for a new rocket.
** -------------------------------------------------------------------------- */
public OnEntityDestroyed(entity)
{
	if(!g_Enabled || !g_isDBmap) return;
	if(entity == -1)
	{
		return;
	}

	if(entity == g_RocketEnt && IsValidEntity(g_RocketEnt))
	{
		
		new rTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		g_RocketEnt = -1;
		g_RocketTarget= -1;
		g_RocketAimed = false;
		g_DeflectCount = 0;
		if(g_roundActive)
		{
			if(rTeam == TRED)
				CreateTimer(g_SpawnTime, FireRocket,  TBLUE);
			else if(rTeam == TBLUE)
				CreateTimer(g_SpawnTime, FireRocket,  TRED);
			if(g_ShowInfo)
				ShowHud(g_SpawnTime,_,_,_,_);

		}
		
		if( IsValidEntity(g_observer))
		{
			SetVariantString("");
			AcceptEntityInput(g_observer, "ClearParent");
			
			new Float:opPos[3];
			new Float:opAng[3];
			
			new spawner = GetRandomInt(0,1);
			if(spawner == 0)
				spawner = g_RedSpawn;
			else
				spawner = g_BlueSpawn;
			
			if(IsValidEntity(spawner)&& spawner > MaxClients)
			{
				GetEntPropVector(spawner,Prop_Data,"m_vecOrigin",opPos);
				GetEntPropVector(spawner,Prop_Data, "m_angAbsRotation", opAng);
				TeleportEntity(g_observer, opPos, opAng, NULL_VECTOR);
			}		
		}
	}
	
}

stock ShowHud( Float:h_duration=0.1, Float:h_speed=0.0, h_reflects=-1, h_owner=-1, h_target=0)
{

	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			continue;
			
		if(g_RocketAimed)
			SetHudTextParams(0.03, 0.41, h_duration, ALERT_R, ALERT_G, ALERT_B, 255, 0, 0.0, 0.0, 0.0);
		else
			SetHudTextParams(0.03, 0.41, h_duration, DEF_R, DEF_G, DEF_B, 255, 0, 0.0, 0.0, 0.0);
		if(h_speed > 0.0)
			ShowSyncHudText(i, g_HudSyncs[hud_Speed], "Speed: %.1f", h_speed);
		else
			ShowSyncHudText(i, g_HudSyncs[hud_Speed], "Speed: -");

		SetHudTextParams(0.03, 0.44, h_duration, DEF_R, DEF_G, DEF_B, 255, 0, 0.0, 0.0, 0.0);
		if(h_reflects > -1)
			ShowSyncHudText(i, g_HudSyncs[hud_Reflects], "Reflects: %d", h_reflects);
		else
			ShowSyncHudText(i, g_HudSyncs[hud_Reflects], "Reflects: -");		

		SetHudTextParams(0.03, 0.47, h_duration, DEF_R, DEF_G, DEF_B, 255, 0, 0.0, 0.0, 0.0);
		if(h_owner > 0 && h_owner <= MaxClients)
			ShowSyncHudText(i, g_HudSyncs[hud_Owner], "Owner: %N", h_owner);
		else if(h_owner == 0)
			ShowSyncHudText(i, g_HudSyncs[hud_Owner], "Owner: Server");
		else
			ShowSyncHudText(i, g_HudSyncs[hud_Owner], "Owner: -");
			
		SetHudTextParams(0.03, 0.50, h_duration, DEF_R, DEF_G, DEF_B, 255, 0, 0.0, 0.0, 0.0);
		if(h_target > 0 && h_target <= MaxClients)
			ShowSyncHudText(i, g_HudSyncs[hud_Target], "Target: %N", h_target);
		else
			ShowSyncHudText(i, g_HudSyncs[hud_Target], "Target: -");
	}
}


/* OnConfigsExecuted()
**
** Here we get the default values of the CVars that the plugin is going to modify.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
	if(!g_Enabled || !g_isDBmap) return;
	db_airdash_def = GetConVarInt(db_airdash);
	db_push_def = GetConVarInt(db_push);
	db_burstammo_def = GetConVarInt(db_burstammo);
	SetupCvars();
}

/* SetupCvars()
**
** Modify several values of the CVars that the plugin needs to work properly.
** -------------------------------------------------------------------------- */
public SetupCvars()
{
	SetConVarInt(db_airdash, 0);
	SetConVarInt(db_push, 0);
	SetConVarInt(db_burstammo,0);
}

/* ResetCvars()
**
** Reset the values of the CVars that the plugin used to their default values.
** -------------------------------------------------------------------------- */
public ResetCvars()
{
	SetConVarInt(db_airdash, db_airdash_def);
	SetConVarInt(db_push, db_push_def);
	SetConVarInt(db_burstammo, db_burstammo_def);
}

/* OnPlayerRunCmd()
**
** Block flamethrower's Mouse1 attack.
** -------------------------------------------------------------------------- */
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if(!g_Enabled || !g_isDBmap) return Plugin_Continue;
	iButtons &= ~IN_ATTACK;
	return Plugin_Continue;
}

/* TF2_SwitchtoSlot()
**
** Changes the client's slot to the desired one.
** -------------------------------------------------------------------------- */
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

/* SetCloak()
**
** Function used to set the spy's cloak meter.
** -------------------------------------------------------------------------- */
stock SetCloak(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

/* CopyVectors()
**
** Copies the contents from a vector to another.
** -------------------------------------------------------------------------- */
stock CopyVectors(Float:fFrom[3], Float:fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}

/* LerpVectors()
**
** Calculates the linear interpolation of the two given vectors and stores
** it on the third one.
** -------------------------------------------------------------------------- */
stock LerpVectors(Float:fA[3], Float:fB[3], Float:fC[3], Float:t)
{
	if (t < 0.0) t = 0.0;
	if (t > 1.0) t = 1.0;
	
	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

/* CalculateDirectionToClient()
**
** As the name indicates, calculates the orientation for the rocket to move
** towards the specified client.
** -------------------------------------------------------------------------- */
CalculateDirectionToClient(iEntity, iClient, Float:fOut[3])
{
	if(iClient < 0 || iClient > MaxClients)
		return;
	decl Float:fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(iClient, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}