#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#include <calcplayerscore>
#define PL_VERSION "1.1.7"
new Handle:gameConf;
//new Handle:giveNamedItem;
//new Handle:weaponEquip;
new Handle:forceStalemate;
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;
new Handle:g_hElim = INVALID_HANDLE;
new bool:g_bElim = false;
new Handle:g_hLives = INVALID_HANDLE;
new g_iLives = 5;
new lives[MAXPLAYERS+1] = {0, ...};
new Handle:g_hFrag = INVALID_HANDLE;
new bool:g_bFrag = false;
new Handle:g_hFrags = INVALID_HANDLE;
new g_iFrags = 50;
new frags[MAXPLAYERS+1] = {0, ...};
new fragst[2] = {0, 0};
new fov[MAXPLAYERS+1] = {0, ...};
new fovz[MAXPLAYERS+1] = {0, ...};
new Handle:g_hSpawn = INVALID_HANDLE;
new g_iSpawn = 5;
new bool:prot[MAXPLAYERS+1] = {false, ...};
new Handle:g_hFireDelay = INVALID_HANDLE;
new Float:g_fFireDelay;
new Handle:g_hFlag = INVALID_HANDLE;
new bool:g_bFlag = true;
new Handle:g_hFlagh = INVALID_HANDLE;
new bool:g_bFlagh = false;
new Handle:g_hFlagt = INVALID_HANDLE;
new g_iFlagt = 15;
new flagl[8][2];
new Float:flago[8][3];
new flagc = 0;
new flagcapl[16][2];
new flagcapc = 0;
new Handle:g_hFall = INVALID_HANDLE;
new Float:g_fFall = 1.0;
new Handle:g_hMult = INVALID_HANDLE;
new bool:g_bMult = true;
new Handle:g_hAccel = INVALID_HANDLE;
new Handle:g_hFullB = INVALID_HANDLE;
new bool:g_bFullB = false;
new Handle:g_hDrop = INVALID_HANDLE;
new bool:g_bDrop = true;
new Handle:g_hBhop = INVALID_HANDLE;
new bool:g_bBhop = false;
new Handle:g_hDj = INVALID_HANDLE;
new bool:g_bDj = true;
new Handle:g_hPhysprops = INVALID_HANDLE;
new bool:g_bPhysprops = false;
new bool:dropped[MAXPLAYERS+1] = {false, ...};
new bool:killed[MAXPLAYERS+1] = {false, ...};
new Float:traceData[MAXPLAYERS+1][6];
new Handle:accel = INVALID_HANDLE;
new Handle:mpff = INVALID_HANDLE;
new bool:bmpff = false;
new Handle:db = INVALID_HANDLE;
new bool:arena = false;
new bool:roundend = false;
new bool:sqlite = false;
new g_BeamSprite;
new g_HaloSprite;
new g_ExplosionSprite;
new gamerules = -1;
new offsActiveWeapon = -1;
new offsClip1 = -1;
new offsNextPrimaryAttack = -1;
new offsTeamNum = -1;
new offsFOV = -1;
new offsDefaultFOV = -1;
new weaponRateQueue[MAXPLAYERS+1];
new weaponRateQueueLen;
new propVelQueue[128];
new propVelQueueLen;
new bhopground[MAXPLAYERS+1];
new bhopjump[MAXPLAYERS+1];
new Float:bhopvel[MAXPLAYERS+1][3];
new candj[MAXPLAYERS+1];
new Handle:g_hHudFrags = INVALID_HANDLE;
new Handle:g_hFragsTimer = INVALID_HANDLE;
new bool:g_bShowFrags[MAXPLAYERS+1];
new Float:g_fFragsPos[MAXPLAYERS+1][2];
public Plugin:myinfo =
{
	name = "Instagib",
	author = "MikeJS",
	description = "Instant kills, scouts and sniper rifles.",
	version = PL_VERSION,
	url = "http://www.steamcommunity.com/groups/instagibfortress/"
};
public OnPluginStart() {
	decl String:error[256];
	if(SQL_CheckConfig("instagib")) {
		db = SQL_Connect("instagib", true, error, sizeof(error));
	} else {
		db = SQL_Connect("storage-local", true, error, sizeof(error));
	}
	if(db==INVALID_HANDLE) {
		LogError("Could not connect to database: %s", error);
		return;
	}
	decl String:ident[16];
	SQL_ReadDriver(db, ident, sizeof(ident));
	if(StrEqual(ident, "mysql", false)) {
		sqlite = false;
	} else if(StrEqual(ident, "sqlite", false)) {
		sqlite = true;
	} else {
		LogError("Invalid database.");
		return;
	}
	if(sqlite) {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS instagib (steamid TEXT, fov INTEGER, fovz INTEGER, fragsxpos REAL, fragsypos REAL, showfrags INTEGER)");
	} else {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS instagib (steamid VARCHAR(32) NOT NULL, fov INT(4) NOT NULL, fovz INT(4) NOT NULL, fragsxpos DECIMAL(6, 3), fragsypos DECIMAL(6, 3), showfrags INT(4))");
	}
	gameConf = LoadGameConfigFile("instagib.games");
	/*StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
	giveNamedItem = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	weaponEquip = EndPrepSDKCall();*/
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "ForceStalemate");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	forceStalemate = EndPrepSDKCall();
	offsActiveWeapon = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	offsClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	offsTeamNum = FindSendPropInfo("CBaseEntity", "m_iTeamNum");
	offsFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	offsDefaultFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	CreateConVar("instagib", PL_VERSION, "TF2 Instagib version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("instagib_enable", "1", "Enable/disable TF2 Instagib.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hElim = CreateConVar("instagib_elim", "0", "Enable/disable elimination mode.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hLives = CreateConVar("instagib_lives", "5", "Set elimination lives.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFrag = CreateConVar("instagib_frag", "0", "Enable/disable frag limit.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFrags = CreateConVar("instagib_frags", "50", "Set frag limit.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpawn = CreateConVar("instagib_spawn", "3", "Spawn protection time, in seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFireDelay = CreateConVar("instagib_firedelay", "1.3", "Delay between shots.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFlag = CreateConVar("instagib_flag", "1", "Return flag on touch.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFlagh = CreateConVar("instagib_flagh", "0", "Can only cap with flag home.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFlagt = CreateConVar("instagib_flagt", "15", "Flag return timer, in seconds.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFall = CreateConVar("instagib_fall", "0.5", "Fall damage multiplier.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hMult = CreateConVar("instagib_mult", "1", "Change whether the beam will pass through targets on a hit, allowing multikills.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hAccel = CreateConVar("instagib_accel", "50", "sv_airaccelerate", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFullB = CreateConVar("instagib_fullbright", "0", "Make players one colour.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDrop = CreateConVar("instagib_drop", "0", "Allow ig_drop.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hBhop = CreateConVar("instagib_bhop", "0", "Enable bunnyhopping.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hDj = CreateConVar("instagib_dj", "0", "Keep double jump momentum.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hPhysprops = CreateConVar("instagib_physprops", "0", "Make explosions affect prop_physics_multiplayers.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	accel = FindConVar("sv_airaccelerate");
	mpff = FindConVar("mp_friendlyfire");
	RegConsoleCmd("ig_drop", Command_drop, "Drop from the sky!");
	RegConsoleCmd("sm_fov", Command_fov, "Set your FOV.");
	RegConsoleCmd("sm_fovz", Command_fovz, "Set your zoom FOV.");
	RegConsoleCmd("sm_instagib", Command_settings, "Show Instagib settings.");
	RegConsoleCmd("+sm_zoom", Command_zoom1, "Zoom out.");
	RegConsoleCmd("-sm_zoom", Command_zoom2, "Zoom in.");
	RegConsoleCmd("ig_fragspos", Command_fragspos, "Set frag counter location.");
	RegConsoleCmd("ig_frags", Command_frags, "Toggle frag counter");
	HookConVarChange(g_hEnabled, Cvar_enabled);
	HookConVarChange(g_hElim, Cvar_elim);
	HookConVarChange(g_hLives, Cvar_lives);
	HookConVarChange(g_hFrag, Cvar_frag);
	HookConVarChange(g_hFrags, Cvar_frags);
	HookConVarChange(g_hSpawn, Cvar_spawn);
	HookConVarChange(g_hFireDelay, Cvar_firedelay);
	HookConVarChange(g_hFlag, Cvar_flag);
	HookConVarChange(g_hFlagh, Cvar_flagh);
	HookConVarChange(g_hFlagt, Cvar_flagt);
	HookConVarChange(g_hFall, Cvar_fall);
	HookConVarChange(g_hMult, Cvar_mult);
	HookConVarChange(g_hAccel, Cvar_accel);
	HookConVarChange(g_hFullB, Cvar_fullb);
	HookConVarChange(g_hDrop, Cvar_drop);
	HookConVarChange(g_hBhop, Cvar_bhop);
	HookConVarChange(g_hDj, Cvar_dj);
	HookConVarChange(g_hPhysprops, Cvar_physprops);
	HookConVarChange(mpff, Cvar_ff);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	HookEvent("teamplay_restart_round", Event_teamplay_round_start);
	HookEvent("teamplay_round_win", Event_teamplay_round_win);
	HookEntityOutput("item_teamflag", "OnDrop", Ent_OnDrop);
	HookEntityOutput("item_teamflag", "OnPickUp", Ent_OnPickup);
	HookEntityOutput("item_teamflag", "OnCapture", Ent_OnReturn);
	HookEntityOutput("item_teamflag", "OnReturn", Ent_OnReturn);
	g_hHudFrags = CreateHudSynchronizer();
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, PreThinkHook);
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
	SDKHook(client, SDKHook_WeaponEquip, WeaponEquip);
	
	frags[client] = 0;
	lives[client] = 0;
	prot[client] = false;
	if(!IsFakeClient(client)) {
		//ClientCommand(client, "r_screenoverlay instagib/crosshairoverlay.vmt");
		decl String:clientid[32], String:query[256];
		new userid = GetClientUserId(client);
		GetClientAuthString(client, clientid, sizeof(clientid));
		Format(query, sizeof(query), "SELECT fov,fovz,fragsxpos,fragsypos,showfrags FROM instagib WHERE steamid='%s'", clientid);
		SQL_TQuery(db, SQLQueryConnect, query, userid);
	}
}

public OnCalcPlayerScore(client, score) {
	if(g_bEnabled) {
		if(g_bElim) {
			return lives[client];
		} else {
			return frags[client];
		}
	}
	return score;
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bElim = GetConVarBool(g_hElim);
	g_iLives = GetConVarInt(g_hLives);
	g_bFrag = GetConVarBool(g_hFrag);
	g_iFrags = GetConVarInt(g_hFrags);
	g_iSpawn = GetConVarInt(g_hSpawn);
	g_fFireDelay = GetConVarFloat(g_hFireDelay);
	g_bFlag = GetConVarBool(g_hFlag);
	g_bFlagh = GetConVarBool(g_hFlagh);
	g_iFlagt = GetConVarInt(g_hFlagt);
	g_fFall = GetConVarFloat(g_hFall);
	g_bMult = GetConVarBool(g_hMult);
	SetConVarInt(accel, GetConVarInt(g_hAccel), true);
	g_bFullB = GetConVarBool(g_hFullB);
	g_bDrop = GetConVarBool(g_hDrop);
	g_bBhop = GetConVarBool(g_hBhop);
	g_bDj = GetConVarBool(g_hDj);
	g_bPhysprops = GetConVarBool(g_hPhysprops);
	bmpff = GetConVarBool(mpff);
	SetConVarBool(FindConVar("tf_weapon_criticals"), true);
	if(g_hFragsTimer==INVALID_HANDLE) {
		if(!g_bElim)
			g_hFragsTimer = CreateTimer(0.1, UpdateFrags, _, TIMER_REPEAT);
	} else {
		KillTimer(g_hFragsTimer);
		g_hFragsTimer = INVALID_HANDLE;
	}
}
public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:strError[], iMaxErrors)
{
	MarkNativeAsOptional("OnCalcPlayerScore");
	return APLRes_Success;
}
public OnMapStart() {
	arena = true;
	if(FindEntityByClassname(MaxClients+1, "tf_logic_arena")==-1)
		arena = false;
	gamerules = FindEntityByClassname(MaxClients+1, "tf_gamerules");
	if(gamerules==-1)
		gamerules = CreateEntityByName("tf_gamerules");
	fragst[0] = 0;
	fragst[1] = 0;
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound("buttons/button14.wav");
	PrecacheSound("buttons/button17.wav");
	PrecacheSound("vo/intel_teamreturned.wav");
	PrecacheSound("vo/intel_enemyreturned.wav");
	PrecacheSound("vo/intel_enemyreturned2.wav");
	PrecacheSound("vo/intel_enemyreturned3.wav");
	//AddFileToDownloadsTable("materials/instagib/crosshairoverlay.vtf");
	//AddFileToDownloadsTable("materials/instagib/crosshairoverlay.vmt");
	for(new i=1;i<=MaxClients;i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	if(GetConVarBool(g_hEnabled))
		for(new i=1;i<=MaxClients;i++)
			CreateTimer(0.5, Respawn, i);
	CreateTimer(0.1, UpdateFrags, _, TIMER_REPEAT);
}

public OnGameFrame() {
	if(weaponRateQueueLen) {
		new Float:enginetime = GetGameTime(), ent;
		for(new i=0;i<weaponRateQueueLen;i++) {
			ent = weaponRateQueue[i];
			if(IsValidEntity(ent))
				SetEntDataFloat(ent, offsNextPrimaryAttack, enginetime+g_fFireDelay, true);
		}
		weaponRateQueueLen = 0;
	}
	if(propVelQueueLen) {
		new ent;
		for(new i=0;i<propVelQueueLen;i++) {
			ent = propVelQueue[i];
			if(IsValidEntity(ent))
				SetEntPropVector(ent, Prop_Data, "m_vecVelocity", NULL_VECTOR);
		}
		propVelQueueLen = 0;
	}
	for(new i=1;i<MaxClients;i++)
		if(dropped[i] && GetEntityFlags(i) & FL_ONGROUND)
			dropped[i] = false;
	if(g_bBhop || g_bDj) {
		decl Float:velocity[3];
		decl Float:speed;
		decl Float:speed2;
		decl Float:oldspeed;
		if(g_bBhop && g_bDj) {
			for(new i=1;i<=MaxClients;i++) {
				if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);
					speed = SquareRoot((velocity[0]*velocity[0])+(velocity[1]*velocity[1]));
					if(GetClientButtons(i) & IN_JUMP && (GetEntityFlags(i) & FL_ONGROUND || bhopground[i])) {
						if(!(bhopground[i] || GetClientButtons(i) & IN_DUCK)) {
							speed2 = SquareRoot((speed*speed)+(bhopvel[i][2]*bhopvel[i][2]));
							if(speed==0.0)
								speed2 = 0.0;
							velocity[0] = velocity[0]*speed2/speed;
							velocity[1] = velocity[1]*speed2/speed;
						}
						velocity[2] = 800.0/3.0;
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
					} else if(candj[i] && bhopjump[i]==0 && GetClientButtons(i) & IN_JUMP) {
						oldspeed = SquareRoot((bhopvel[i][0]*bhopvel[i][0])+(bhopvel[i][1]*bhopvel[i][1]));
						velocity[2] = 800.0/3.0;
						if(oldspeed>=400.0) {
							if(speed==0.0)
								oldspeed = 0.0;
							velocity[0] = velocity[0]*oldspeed/speed;
							velocity[1] = velocity[1]*oldspeed/speed;
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
						}
						candj[i] = false;
					}
					if(candj[i]==0 && GetEntityFlags(i) & FL_ONGROUND)
						candj[i] = true;
					bhopground[i] = GetEntityFlags(i) & FL_ONGROUND;
					bhopjump[i] = GetClientButtons(i) & IN_JUMP;
					bhopvel[i][0] = velocity[0];
					bhopvel[i][1] = velocity[1];
					bhopvel[i][2] = velocity[2];
				}
			}
		} else if(g_bBhop) {
			for(new i=1;i<=MaxClients;i++) {
				if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);
					speed = SquareRoot((velocity[0]*velocity[0])+(velocity[1]*velocity[1]));
					if(GetClientButtons(i) & IN_JUMP && (GetEntityFlags(i) & FL_ONGROUND || bhopground[i])) {
						if(!(bhopground[i] || GetClientButtons(i) & IN_DUCK)) {
							speed2 = SquareRoot((speed*speed)+(bhopvel[i][2]*bhopvel[i][2]));
							if(speed==0.0)
								speed2 = 0.0;
							velocity[0] = velocity[0]*speed2/speed;
							velocity[1] = velocity[1]*speed2/speed;
						}
						velocity[2] = 800.0/3.0;
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
					}
					if(candj[i]==0 && GetEntityFlags(i) & FL_ONGROUND)
						candj[i] = true;
					bhopground[i] = GetEntityFlags(i) & FL_ONGROUND;
					bhopjump[i] = GetClientButtons(i) & IN_JUMP;
					bhopvel[i][0] = velocity[0];
					bhopvel[i][1] = velocity[1];
					bhopvel[i][2] = velocity[2];
				}
			}
		} else {
			for(new i=1;i<=MaxClients;i++) {
				if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);
					speed = SquareRoot((velocity[0]*velocity[0])+(velocity[1]*velocity[1]));
					if(candj[i] && bhopjump[i]==0 && GetClientButtons(i) & IN_JUMP && !(GetClientButtons(i) & IN_JUMP && (GetEntityFlags(i) & FL_ONGROUND || bhopground[i]))) {
						oldspeed = SquareRoot((bhopvel[i][0]*bhopvel[i][0])+(bhopvel[i][1]*bhopvel[i][1]));
						velocity[2] = 800.0/3.0;
						if(oldspeed>=400.0) {
							if(speed==0.0)
								oldspeed = 0.0;
							velocity[0] = velocity[0]*oldspeed/speed;
							velocity[1] = velocity[1]*oldspeed/speed;
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
						}
						candj[i] = false;
					}
					if(candj[i]==0 && GetEntityFlags(i) & FL_ONGROUND)
						candj[i] = true;
					bhopground[i] = GetEntityFlags(i) & FL_ONGROUND;
					bhopjump[i] = GetClientButtons(i) & IN_JUMP;
					bhopvel[i][0] = velocity[0];
					bhopvel[i][1] = velocity[1];
					bhopvel[i][2] = velocity[2];
				}
			}
		}
	}
}
public TouchHook(ent, other) {
	if(g_bEnabled && g_bFlag && GetFlagState(ent)==2 && other>0 && other<=MaxClients && GetClientTeam(other)==GetEntData(ent, offsTeamNum, 2)) {
		new idx = -1;
		for(new i=0;i<=flagc;i++) {
			if(flagl[i][0]==ent) {
				idx = i;
				break;
			}
		}
		decl Float:flagorigin[3], Float:iconorigin[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", flagorigin);
		new iconc = MaxClients+1;
		while((iconc = FindEntityByClassname(iconc, "item_teamflag_return_icon"))!=-1) {
			GetEntPropVector(iconc, Prop_Send, "m_vecOrigin", iconorigin);
			if(flagorigin[0]==iconorigin[0] && flagorigin[1]==iconorigin[1])
				AcceptEntityInput(iconc, "kill");
		}
		TeleportEntity(ent, flago[idx], NULL_VECTOR, NULL_VECTOR);
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)) {
				if(GetEntData(ent, offsTeamNum, 2)==GetClientTeam(i)) {
					new rint = GetRandomInt(1, 3);
					if(rint==1) {
						EmitSoundToClient(i, "vo/intel_enemyreturned.wav", _, _, _, _, 0.75);
					} else {
						decl String:buffer[128];
						Format(buffer, sizeof(buffer), "vo/intel_enemyreturned%i.wav", rint);
						EmitSoundToClient(i, buffer, _, _, _, _, 0.75);
					}
				} else {
					EmitSoundToClient(i, "vo/intel_teamreturned.wav", _, _, _, _, 0.75);
				}
			}
		}
		SetFlagState(ent, 0);
		SetEntProp(ent, Prop_Send, "m_nFlagStatus", 0);
	}
}
public PreThinkHook(client) {
	if(g_bEnabled) {
		new buttons = GetEntProp(client, Prop_Data, "m_nButtons");
		buttons &= ~(IN_ATTACK2);
		SetEntProp(client, Prop_Data, "m_nButtons", buttons);
	}
}
public Action:TakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(g_bEnabled)
	{
		if(damagetype & DMG_FALL) {
			damage *= g_fFall;
			return Plugin_Changed;
		}
		if(attacker>0 && attacker<=MaxClients && !roundend)
		{
			return Plugin_Stop;
		}
		if(prot[victim])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:WeaponEquip(client, weapon)
{
	if(g_bEnabled)
	{
		CreateTimer(0.1, Equip, client);
	}
	return Plugin_Continue;
}

public Ent_OnDrop(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 2);
}
public Ent_OnPickup(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 1);
}
public Ent_OnReturn(const String:output[], caller, activator, Float:delay) {
	SetFlagState(caller, 0);
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} else {
		decl String:query[512], String:steamid[32];
		GetClientAuthString(client, steamid, sizeof(steamid));
		if(SQL_FetchRow(hndl)) {
			fov[client] = SQL_FetchInt(hndl, 0);
			fovz[client] = SQL_FetchInt(hndl, 1);
			g_fFragsPos[client][0] = SQL_FetchFloat(hndl, 2);
			g_fFragsPos[client][1] = SQL_FetchFloat(hndl, 3);
			g_bShowFrags[client] = SQL_FetchInt(hndl, 4)==1;
		} else {
			if(sqlite) {
				Format(query, sizeof(query), "INSERT INTO instagib VALUES('%s', 120, 20, 0.05, 0.05, 1)", steamid);
				SQL_TQuery(db, SQLErrorCheckCallback, query);
			} else {
				Format(query, sizeof(query), "INSERT INTO instagib (steamid, fov, fovz) VALUES ('%s', 120, 20, 0.05, 0.05, 1)", steamid);
				SQL_TQuery(db, SQLErrorCheckCallback, query);
			}
			fov[client] = 120;
			fovz[client] = 20;
			g_fFragsPos[client][0] = g_fFragsPos[client][1] = 0.05;
			g_bShowFrags[client] = true;
			CreateTimer(20.0, WelcomeMessage, client);
		}
		if(g_bEnabled) {
			SetEntData(client, offsFOV, fov[client], 4, true);
			SetEntData(client, offsDefaultFOV, fov[client], 4, true);
		}
	}
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(GetConVarBool(g_hEnabled)) {
		HookEvent("player_death", Event_player_death, EventHookMode_Pre);
		HookEvent("player_spawn", Event_player_spawn);
		HookEvent("teamplay_round_start", Event_teamplay_round_start);
		HookEvent("teamplay_restart_round", Event_teamplay_round_start);
		HookEvent("teamplay_round_win", Event_teamplay_round_win);
		HookEntityOutput("item_teamflag", "OnDrop", Ent_OnDrop);
		HookEntityOutput("item_teamflag", "OnPickUp", Ent_OnPickup);
		HookEntityOutput("item_teamflag", "OnCapture", Ent_OnReturn);
		HookEntityOutput("item_teamflag", "OnReturn", Ent_OnReturn);
		g_bEnabled = true;
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i))
				CreateTimer(0.5, Respawn, i);
	} else {
		UnhookEvent("player_death", Event_player_death, EventHookMode_Pre);
		UnhookEvent("player_spawn", Event_player_spawn);
		UnhookEvent("teamplay_round_start", Event_teamplay_round_start);
		UnhookEvent("teamplay_restart_round", Event_teamplay_round_start);
		UnhookEvent("teamplay_round_win", Event_teamplay_round_win);
		UnhookEntityOutput("item_teamflag", "OnDrop", Ent_OnDrop);
		UnhookEntityOutput("item_teamflag", "OnPickUp", Ent_OnPickup);
		UnhookEntityOutput("item_teamflag", "OnCapture", Ent_OnReturn);
		UnhookEntityOutput("item_teamflag", "OnReturn", Ent_OnReturn);
		g_bEnabled = false;
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i)) {
				SetEntData(i, offsFOV, 90, 4, true);
				SetEntData(i, offsDefaultFOV, 90, 4, true);
				CreateTimer(0.5, Respawn, i);
			}
		}
		new regenc = MaxClients+1;
		while((regenc = FindEntityByClassname(regenc, "func_regenerate"))!=-1) {
			AcceptEntityInput(regenc, "Enable");
		}
	}
}
public Cvar_elim(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bElim = GetConVarBool(g_hElim);
	if(!g_bElim && g_hFragsTimer==INVALID_HANDLE) {
		g_hFragsTimer = CreateTimer(0.1, UpdateFrags, _, TIMER_REPEAT);
	} else if(g_hFragsTimer!=INVALID_HANDLE) {
		KillTimer(g_hFragsTimer);
		g_hFragsTimer = INVALID_HANDLE;
	}
}
public Cvar_lives(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iLives = GetConVarInt(g_hLives);
}
public Cvar_frag(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bFrag = GetConVarBool(g_hFrag);
}
public Cvar_frags(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iFrags = GetConVarInt(g_hFrags);
}
public Cvar_spawn(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iSpawn = GetConVarInt(g_hSpawn);
}
public Cvar_firedelay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fFireDelay = GetConVarFloat(g_hFireDelay);
}
public Cvar_flag(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bFlag = GetConVarBool(g_hFlag);
}
public Cvar_flagh(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bFlagh = GetConVarBool(g_hFlagh);
}
public Cvar_flagt(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iFlagt = GetConVarInt(g_hFlagt);
}
public Cvar_fall(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fFall = GetConVarFloat(g_hFall);
}
public Cvar_mult(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bMult = GetConVarBool(g_hMult);
}
public Cvar_accel(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SetConVarInt(accel, GetConVarInt(g_hAccel), true);
}
public Cvar_fullb(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bFullB = GetConVarBool(g_hFullB);
}
public Cvar_drop(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bDrop = GetConVarBool(g_hDrop);
}
public Cvar_bhop(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bBhop = GetConVarBool(g_hBhop);
}
public Cvar_dj(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bDj = GetConVarBool(g_hDj);
}
public Cvar_physprops(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bPhysprops = GetConVarBool(g_hPhysprops);
}
public Cvar_ff(Handle:convar, const String:oldValue[], const String:newValue[]) {
	bmpff = GetConVarBool(mpff);
}
public Action:Command_drop(client, args) {
	if(g_bEnabled) {
		if(g_bDrop) {
			if(IsClientInGame(client) && IsPlayerAlive(client)) {
				if(!(GetEntityFlags(client) & FL_ONGROUND) && !dropped[client]) {
					decl Float:velocity[3], Float:speed;
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
					speed = SquareRoot((velocity[0]*velocity[0])+(velocity[1]*velocity[1]));
					velocity[0] = velocity[0]/1.5;
					velocity[1] = velocity[1]/1.5;
					velocity[2] = speed>=800.0/3.0?0-speed:0-(800.0/3.0);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
					dropped[client] = true;
				}
			}
		} else {
			PrintToChat(client, "ig_drop has been disabled on this server.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Command_fov(client, args) {
	if(g_bEnabled) {
		if(args>0) {
			decl String:arg[8], String:clientid[32], String:query[512];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) {
				if(!IsCharNumeric(arg[i])) {
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			if(StringToInt(arg)<=0 || StringToInt(arg)>160) {
				ReplyToCommand(client, "Value must be between 1 and 160.");
				return Plugin_Handled;
			}
			GetClientAuthString(client, clientid, sizeof(clientid));
			fov[client] = StringToInt(arg);
			SetEntData(client, offsFOV, fov[client], 4, true);
			SetEntData(client, offsDefaultFOV, fov[client], 4, true);
			Format(query, sizeof(query), "UPDATE instagib SET fov=%i WHERE steamid='%s'", fov[client], clientid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			ReplyToCommand(client, "FOV set to %i.", fov[client]);
		} else {
			ReplyToCommand(client, "FOV: %i", fov[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Command_fovz(client, args) {
	if(g_bEnabled) {
		if(args>0) {
			decl String:arg[8], String:clientid[32], String:query[512];
			GetCmdArg(1, arg, sizeof(arg));
			for(new i=0;i<strlen(arg);i++) {
				if(!IsCharNumeric(arg[i])) {
					ReplyToCommand(client, "Value must be an integer.");
					return Plugin_Handled;
				}
			}
			if(StringToInt(arg)<=0 || StringToInt(arg)>160) {
				ReplyToCommand(client, "Value must be between 1 and 160.");
				return Plugin_Handled;
			}
			GetClientAuthString(client, clientid, sizeof(clientid));
			fovz[client] = StringToInt(arg);
			Format(query, sizeof(query), "UPDATE instagib SET fovz=%i WHERE steamid='%s'", fovz[client], clientid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			ReplyToCommand(client, "Zoom FOV set to %i.", fovz[client]);
		} else {
			ReplyToCommand(client, "Zoom FOV: %i", fovz[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Command_zoom1(client, args) {
	if(g_bEnabled && client>0) {
		SetEntData(client, offsFOV, fovz[client], 4, true);
		SetEntData(client, offsDefaultFOV, fovz[client], 4, true);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Command_zoom2(client, args) {
	if(g_bEnabled && client>0) {
		SetEntData(client, offsFOV, fov[client], 4, true);
		SetEntData(client, offsDefaultFOV, fov[client], 4, true);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:Command_fragspos(client, args) {
	if(g_bEnabled && client>0) {
		if(args!=2) {
			ReplyToCommand(client, "ig_fragspos <x> <y>");
		} else {
			decl String:arg1[8], String:arg2[8], String:query[256], String:steamid[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			g_fFragsPos[client][0] = StringToFloat(arg1);
			g_fFragsPos[client][1] = StringToFloat(arg2);
			GetClientAuthString(client, steamid, sizeof(steamid));
			Format(query, sizeof(query), "UPDATE instagib SET fragsxpos=%f,fragsypos=%f WHERE steamid='%s'", g_fFragsPos[client][0], g_fFragsPos[client][1], steamid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			ReplyToCommand(client, "Frag counter moved.");
		}
	}
	return Plugin_Handled;
}
public Action:Command_frags(client, args) {
	if(g_bEnabled) {
		if(client>0) {
			if(args==0) {
				g_bShowFrags[client] = !g_bShowFrags[client];
			} else {
				decl String:argstr[8];
				GetCmdArgString(argstr, sizeof(argstr));
				g_bShowFrags[client] = StringToInt(argstr)==1;
			}
			ReplyToCommand(client, "Frag counter %sabled.", g_bShowFrags[client]?"en":"dis");
		}
	}
	return Plugin_Handled;
}
public Action:Command_settings(client, args) {
	ReplyToCommand(client, "Instagib version: %s", PL_VERSION);
	ReplyToCommand(client, "Frag limit: %sabled (frags: %i)", g_bFrag?"en":"dis", g_iFrags);
	ReplyToCommand(client, "Elimination: %sabled (lives: %i)", g_bElim?"en":"dis", g_iLives);
	ReplyToCommand(client, "Frag limit: %sabled (frags: %i)", g_bFrag?"en":"dis", g_iFrags);
	ReplyToCommand(client, "Spawn protection: %i", g_iSpawn);
	ReplyToCommand(client, "Fire delay: %f", GetConVarFloat(g_hFireDelay));
	ReplyToCommand(client, "Fall damage: %f", g_fFall);
	ReplyToCommand(client, "Flag touch: %sabled", g_bFlag?"en":"dis");
	ReplyToCommand(client, "Flag home cap: %sabled", g_bFlagh?"en":"dis");
	ReplyToCommand(client, "Flag timer: %i", g_iFlagt);
	ReplyToCommand(client, "Multiple hits: %sabled", g_bMult?"en":"dis");
	ReplyToCommand(client, "Air accel: %i", GetConVarInt(accel));
	ReplyToCommand(client, "Fullbright: %sabled", g_bFullB?"en":"dis");
	ReplyToCommand(client, "ig_drop: %sabled", g_bDrop?"en":"dis");
	ReplyToCommand(client, "Bunnyhopping: %sabled", g_bBhop?"en":"dis");
	ReplyToCommand(client, "DJ Momentum: %sabled", g_bDj?"en":"dis");
	if(!g_bEnabled)
		ReplyToCommand(client, "\x04Instagib has been disabled.");
	return Plugin_Handled;
}
public Action:Equip(Handle:timer, any:client) {
	if(g_bEnabled) {
		if(IsClientInGame(client) && IsPlayerAlive(client)) {
			for(new i=1;i<6;i++)
				TF2_RemoveWeaponSlot(client, i);
			/*decl String:wpn[32];
			GetClientWeapon(client, wpn, sizeof(wpn));
			if(!StrEqual(wpn, "tf_weapon_sniperrifle")) {
				new weaponIndex;
				while((weaponIndex = GetPlayerWeaponSlot(client, 0))!=-1) {
					RemovePlayerItem(client, weaponIndex);
					RemoveEdict(weaponIndex);
				}
				new entity = SDKCall(giveNamedItem, client, "tf_weapon_sniperrifle", 0, 0);
				SDKCall(weaponEquip, client, entity);
				SetEntData(GetEntDataEnt2(client, offsActiveWeapon), offsClip1, 9);
			}
			CreateTimer(5.0, Equip, client);*/
		}
	}
}
public Action:Respawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsClientOnTeam(client))
		TF2_RespawnPlayer(client);
}
public Action:SpawnProt(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 255);
	}
	prot[client] = false;
}
public Action:SetupFlags(Handle:timer) {
	new flag = MaxClients+1;
	flagc = 0;
	while((flag = FindEntityByClassname(flag, "item_teamflag"))!=-1) {
		decl String:buffer[32], Float:origin[3];
		Format(buffer, sizeof(buffer), "ReturnTime %i", g_iFlagt);
		SetVariantString(buffer);
		AcceptEntityInput(flag, "AddOutput");
		GetEntPropVector(flag, Prop_Send, "m_vecOrigin", origin);
		SDKHook(flag, SDKHook_Touch, TouchHook);
		flagl[flagc][0] = flag;
		flagl[flagc][1] = 0;
		flago[flagc][0] = origin[0];
		flago[flagc][1] = origin[1];
		flago[flagc++][2] = origin[2];
	}
}
public Action:WelcomeMessage(Handle:timer, any:client) {
	if(IsClientInGame(client) && g_bElim)
		PrintToChat(client, "\x01Elimination mode enabled, please wait for the next round to start. Lives: \x03%i\x01.", g_iLives);
}
public Action:UpdateFrags(Handle:timer) {
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientConnected(i) && IsClientInGame(i) && g_bShowFrags[i]) {
			SetHudTextParams(g_fFragsPos[i][0], g_fFragsPos[i][1], 0.5, 255, 255, 255, 192, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, g_hHudFrags, "Frags: %i", frags[i]);
		}
	}
}
SetGameRulesScore(team, score) {
	SetVariantInt(score-GetTeamScore(team));
	AcceptEntityInput(gamerules, team==2?"AddRedTeamScore":"AddBlueTeamScore");
}
GetFlagState(ent) {
	new idx = -1;
	for(new i=0;i<=flagc;i++) {
		if(flagl[i][0]==ent) {
			idx = i;
			break;
		}
	}
	if(idx==-1) {
		return false;
	} else {
		return flagl[idx][1];
	}
}
SetFlagState(ent, value) {
	new idx = -1;
	for(new i=0;i<=flagc;i++) {
		if(flagl[i][0]==ent) {
			idx = i;
			break;
		}
	}
	if(idx!=-1)
		flagl[idx][1] = value;
	if(g_bFlagh)
		for(new i=0;i<=flagcapc;i++)
			if(flagcapl[i][1]==GetEntData(ent, offsTeamNum, 2))
				AcceptEntityInput(flagcapl[i][0], value==0?"Enable":"Disable");
}
CheckApplyExplosionForce(ent, const Float:vecPos[3]) {
	decl Float:vecOri[3], Float:vecNorm[3], Float:vecVel[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOri);
	vecOri[2] += 20;
	new Float:distance = GetVectorDistance(vecOri, vecPos);
	if(distance>192 || distance==0)
		return;
	SubtractVectors(vecOri, vecPos, vecNorm);
	for(new n=0;n<3;n++) {
		vecNorm[n] = vecNorm[n]/((distance/10)*(distance/10))*250;
		if(vecNorm[n]>800.0)
			vecNorm[n] = 800.0;
	}
	GetEntPropVector(ent, Prop_Data, "m_vecVelocity", vecVel);
	AddVectors(vecNorm, vecVel, vecVel);
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vecVel);
	if(ent>MaxClients) {
		propVelQueue[propVelQueueLen++] = ent;
	}
}
IsClientOnTeam(client) {
	new team = GetClientTeam(client);
	switch(team) {
		case 2: return true;
		case 3: return true;
	}
	return false;
}
OnlyPlayerAlive(client) {
	new team = GetClientTeam(client);
	for(new i=1;i<=MaxClients;i++) {
		if(i!=client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==team)
			return false;
	}
	return true;
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	decl String:weaponname[32];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//ClientCommand(client, "r_screenoverlay 0");
	GetEventString(event, "weapon", weaponname, sizeof(weaponname));
	if(!StrEqual(weaponname, "sniperrifle") && killed[client]) {
		killed[client] = false;
		return Plugin_Handled;
	}
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")), bool:spawn = true;
	if(g_bElim) {
		lives[client]--;
		if(lives[client]<=0) {
			decl String:buffer[256];
			Format(buffer, sizeof(buffer), "\x01\x03%N \x01has been \x04ELIMINATED\x01!", client);
			SayText2(client, buffer);
			spawn = false;
		} else {
			PrintToChat(client, "\x01You have \x04%i \x01%s left.", lives[client], lives[client]==1?"life":"lives");
		}
	} else if(!roundend) {
		new team = GetClientTeam(attacker==0?client:attacker);
		if(client==attacker || attacker==0 || GetClientTeam(client)==team) {
			frags[attacker]--;
			fragst[team-2]--;
			if(g_bFrag)
				SetGameRulesScore(team, fragst[team-2]);
		} else {
			frags[attacker]++;
			fragst[team-2]++;
			if(g_bFrag) {
				SetGameRulesScore(team, fragst[team-2]);
				if(fragst[team-2]>=g_iFrags) {
					PrintToChatAll("\x01%s team hit the fraglimit!", team==2?"RED":"BLU");
					if(!roundend) {
						new ent = CreateEntityByName("game_round_win");
						if(ent>0) {
							SetVariantInt(team==2?2:3);
							AcceptEntityInput(ent, "SetTeam");
							AcceptEntityInput(ent, "RoundWin");
							AcceptEntityInput(ent, "kill");
						}
					}
				}
			}
		}
	}
	if(prot[client])
		prot[client] = false;
	if(spawn && !roundend)
		CreateTimer(3.0, Respawn, client);
	return Plugin_Continue;
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//ClientCommand(client, "r_screenoverlay instagib/crosshairoverlay.vmt");
	if(TF2_GetPlayerClass(client)!=TFClass_Scout) {
		TF2_SetPlayerClass(client, TFClass_Scout);
		TF2_RespawnPlayer(client);
		SetEntityHealth(client, 125);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0);
	}
	if(g_iSpawn>0) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 192);
		CreateTimer(float(g_iSpawn), SpawnProt, client);
		prot[client] = true;
	} else {
		SetEntityRenderColor(client, g_bFullB&&GetClientTeam(client)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(client)==2?0:255, 255);
	}
	CreateTimer(0.01, Equip, client);
}
public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	roundend = false;
	new regenc = MaxClients+1;
	while((regenc = FindEntityByClassname(regenc, "func_regenerate"))!=-1)
		AcceptEntityInput(regenc, "Disable");
	CreateTimer(0.01, SetupFlags);
	new cap = MaxClients+1;
	flagcapc = 0;
	while((cap = FindEntityByClassname(cap, "func_capturezone"))!=-1) {
		flagcapl[flagcapc][0] = cap;
		flagcapl[flagcapc++][1] = GetEntData(cap, offsTeamNum, 2);
	}
	for(new i=0;i<8;i++) {
		flagl[i][0] = -1;
		flagl[i][1] = 0;
	}
	for(new i=0;i<=MaxClients;i++) {
		lives[i] = g_iLives;
		frags[i] = 0;
		prot[i] = false;
	}
	fragst[0] = 0;
	fragst[1] = 0;
	if(g_bFrag) {
		SetGameRulesScore(2, 0);
		SetGameRulesScore(3, 0);
	}
	if(g_bElim && !arena)
		SDKCall(forceStalemate, 1, false, false);
}
public Action:Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	roundend = true;
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)) {
			if(prot[i] && IsPlayerAlive(i)) {
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				SetEntityRenderMode(i, RENDER_NORMAL);
				SetEntityRenderColor(i, g_bFullB&&GetClientTeam(i)==3?0:255, g_bFullB?0:255, g_bFullB&&GetClientTeam(i)==2?0:255, 255);
				prot[i] = false;
			}
		}
	}
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	if(g_bEnabled) {
		SetEntData(GetEntDataEnt2(client, offsActiveWeapon), offsClip1, 10);
		decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client, vecAng);
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayerNoKill);
		if(TR_DidHit(trace)) {
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[2] -= 4;
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, g_HaloSprite, 0, 0, 0.5, 8.0, 4.0, 5, 0.0, GetClientTeam(client)==2?{255, 19, 19, 255}:{19, 19, 255, 255}, 30);
			TE_SendToAll();
			for(new i=0;i<3;i++) {
				traceData[client][i] = vecOrigin[i];
				traceData[client][i+3] = vecPos[i];
			}
			TR_TraceRayFilter(vecOrigin, vecPos, MASK_SHOT_HULL, RayType_EndPoint, TraceEntityFilterPlayer, client);
			vecPos[2] += 2;
			TE_SetupExplosion(vecPos, g_ExplosionSprite, 1.0, 0, 0, 192, 500);
			TE_SendToAll();
			for(new i=1;i<=MaxClients;i++)
				if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(client)!=GetClientTeam(i) || bmpff || i==client))
					CheckApplyExplosionForce(i, vecPos);
			if(g_bPhysprops) {
				new physprop = MaxClients+1;
				while((physprop = FindEntityByClassname(physprop, "prop_physics_multiplayer"))!=-1)
					CheckApplyExplosionForce(physprop, vecPos);
			}
		}
		CloseHandle(trace);
		new ent = GetEntDataEnt2(client, offsActiveWeapon);
		if(ent!=-1)
			weaponRateQueue[weaponRateQueueLen++] = ent;
		result = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) {
	if(entity<=MaxClients) {
		if(client==entity || prot[entity]) {
			if(prot[entity])
				EmitSoundToClient(client, "buttons/button14.wav", _, _, _, _, 0.75);
			return false;
		} else {
			new team = GetClientTeam(entity);
			if(team!=GetClientTeam(client) || bmpff) {
				killed[entity] = true;
				if(g_bElim) {
					if(OnlyPlayerAlive(entity)) {
						if(lives[entity]<=1) {
							for(new i=1;i<MaxClients;i++) {
								if(IsClientInGame(i)) {
									if(team==GetClientTeam(i) && lives[i]>0) {
										TF2_RespawnPlayer(i);
										break;
									}
								}
							}
							FakeClientCommand(entity, "explode");
						} else {
							TF2_RespawnPlayer(entity);
						}
					} else {
						FakeClientCommand(entity, "explode");
					}
				} else {
					FakeClientCommand(entity, "explode");
				}
				new Handle:newEvent = CreateEvent("player_death", true);
				SetEventInt(newEvent, "userid", GetClientUserId(entity));
				SetEventInt(newEvent, "attacker", GetClientUserId(client));
				SetEventString(newEvent, "weapon", "sniperrifle");
				SetEventInt(newEvent, "weaponid", 16);
				FireEvent(newEvent, false);
				EmitSoundToClient(client, "buttons/button17.wav", _, _, _, _, 0.75);
				decl Float:vecOrigin[3], Float:vecPos[3];
				for(new i=0;i<3;i++) {
					vecOrigin[i] = traceData[client][i];
					vecPos[i] = traceData[client][i+3];
				}
				TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite, g_HaloSprite, 0, 0, 3.0, 8.0, 4.0, 5, 0.0, {19, 255, 19, 255}, 30);
				TE_SendToClient(entity);
				return !g_bMult;
			}
		}
	}
	return true;
}
public bool:TraceEntityFilterPlayerNoKill(entity, contentsMask) {
	return entity>MaxClients;
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error))
		LogError("Query failed: %s", error);
}
SayText2(client, const String:message[]) {
	new Handle:buffer = StartMessageAll("SayText2");
	if(buffer!=INVALID_HANDLE) {
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}