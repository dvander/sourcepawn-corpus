#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_NAME "[L4D1/2] Gnome Fly"
#define PLUGIN_AUTHOR "Custom"
#define PLUGIN_DESC "Flying gnome with weapon and jetpack"
#define PLUGIN_VERSION "2.0"
#define PLUGIN_NAME_SHORT "GnomeFly"
#define PLUGIN_NAME_TECH "l4d_gnomefly"

#define SOUNDCLIPEMPTY		   "weapons/ClipEmpty_Rifle.wav" 
#define SOUNDRELOAD			  "weapons/shotgun/gunother/shotgun_load_shell_2.wav" 
#define SOUNDREADY			 "weapons/shotgun/gunother/shotgun_pump_1.wav"
#define SOUND_JETPACK		   "ambient/gas/steam2.wav"

#define WEAPONCOUNT 18

// Sonidos de armas
#define SOUND0 "weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav" 
#define SOUND1 "weapons/rifle/gunfire/rifle_fire_1.wav" 
#define SOUND2 "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav" 
#define SOUND3 "weapons/shotgun/gunfire/shotgun_fire_1.wav" 
#define SOUND4 "weapons/SMG/gunfire/smg_fire_1.wav" 
#define SOUND5 "weapons/pistol/gunfire/pistol_fire.wav" 
#define SOUND6 "weapons/magnum/gunfire/magnum_shoot.wav" 
#define SOUND7 "weapons/rifle_ak47/gunfire/rifle_fire_1.wav" 
#define SOUND8 "weapons/rifle_desert/gunfire/rifle_fire_1.wav" 
#define SOUND9 "weapons/sg552/gunfire/sg552-1.wav"
#define SOUND10 "weapons/machinegun_m60/gunfire/machinegun_fire_1.wav"
#define SOUND11 "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav"
#define SOUND12 "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav"
#define SOUND13 "weapons/sniper_military/gunfire/sniper_military_fire_1.wav"
#define SOUND14 "weapons/scout/gunfire/scout_fire-1.wav"
#define SOUND15 "weapons/awp/gunfire/awp1.wav"
#define SOUND16 "weapons/mp5navy/gunfire/mp5-1.wav"
#define SOUND17 "weapons/smg_silenced/gunfire/smg_fire_1.wav"

// Modelos de armas
#define MODEL0 "models/w_models/weapons/w_hunting_rifle.mdl"
#define MODEL1 "models/w_models/weapons/w_rifle_m16.mdl"
#define MODEL2 "models/w_models/weapons/w_autoshot_m4s.mdl"
#define MODEL3 "models/w_models/weapons/w_pumpshotgun.mdl"
#define MODEL4 "models/w_models/weapons/w_smg_uzi.mdl"
#define MODEL5 "models/w_models/weapons/w_pistol_1911.mdl"
#define MODEL6 "models/w_models/weapons/w_magnum.mdl"
#define MODEL7 "models/w_models/weapons/w_rifle_ak47.mdl"
#define MODEL8 "models/w_models/weapons/w_rifle_m16a2.mdl"
#define MODEL9 "models/w_models/weapons/w_rifle_sg552.mdl"
#define MODEL10 "models/w_models/weapons/w_m60.mdl"
#define MODEL11 "models/w_models/weapons/w_shotgun_chrome.mdl"
#define MODEL12 "models/w_models/weapons/w_shotgun_spas.mdl"
#define MODEL13 "models/w_models/weapons/w_sniper_military.mdl"
#define MODEL14 "models/w_models/weapons/w_sniper_scout.mdl"
#define MODEL15 "models/w_models/weapons/w_sniper_awp.mdl"
#define MODEL16 "models/w_models/weapons/w_smg_mp5.mdl"
#define MODEL17 "models/w_models/weapons/w_smg_silenced.mdl"

#define GNOME_MODEL "models/props_junk/gnome.mdl"
#define JETPACK_MODEL "models/props_equipment/oxygentank01.mdl"

static char SOUND[WEAPONCOUNT+3][70]=
{SOUND0, SOUND1, SOUND2, SOUND3, SOUND4, SOUND5, SOUND6, SOUND7, SOUND8, SOUND9,
 SOUND10, SOUND11, SOUND12, SOUND13, SOUND14, SOUND15, SOUND16, SOUND17,
 SOUNDCLIPEMPTY, SOUNDRELOAD, SOUNDREADY};

static char MODEL[WEAPONCOUNT][64]=
{MODEL0, MODEL1, MODEL2, MODEL3, MODEL4, MODEL5, MODEL6, MODEL7, MODEL8, MODEL9,
 MODEL10, MODEL11, MODEL12, MODEL13, MODEL14, MODEL15, MODEL16, MODEL17};

// Datos de armas
static float fireinterval[WEAPONCOUNT] =		{0.25, 0.068, 0.30, 0.65, 0.060, 0.20, 0.33, 0.145, 0.14, 0.14, 0.068, 0.65, 0.30, 0.265, 0.9, 1.25, 0.065, 0.055};
static float bulletaccuracy[WEAPONCOUNT] =		{1.15, 1.4, 3.5, 3.5, 1.6, 1.7, 1.7, 1.5, 1.6, 1.5, 1.5, 3.5, 3.5, 1.15, 1.00, 0.8, 1.6, 1.6};
static float weaponbulletdamage[WEAPONCOUNT] =	{90.0, 30.0, 25.0, 30.0, 20.0, 30.0, 60.0, 70.0, 40.0, 40.0, 50.0, 30.0, 30.0, 90.0, 100.0, 150.0, 35.0, 35.0};
static int weaponclipsize[WEAPONCOUNT] =		{15, 50, 10, 8, 50, 30, 8, 40, 20, 50, 150, 8, 10, 30, 15, 20, 50, 50};
static int weaponbulletpershot[WEAPONCOUNT] =	{1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 1, 7, 7, 1, 1, 1, 1, 1};
static float weaponloadtime[WEAPONCOUNT] =		{2.0, 1.5, 0.3, 0.3, 1.5, 1.5, 1.9, 1.5, 1.5, 1.6, 0.0, 0.3, 0.3, 2.0, 2.0, 2.0, 1.5, 1.5};
static int weaponloadcount[WEAPONCOUNT] =		{15, 50, 1, 1, 50, 30, 8, 40, 60, 50, 1, 1, 1, 30, 15, 20, 50, 50};
static bool weaponloaddisrupt[WEAPONCOUNT] =	{false, false, true, true, false, false, false, false, false, true, true, true, false, false, false, false, false, false};

// Variables del gnome
static int gnome[MAXPLAYERS+1];
static int weapon_entity[MAXPLAYERS+1];
static int jetpack_entity[MAXPLAYERS+1];
static int jetpack_flame[MAXPLAYERS+1][2];
static int keybuffer[MAXPLAYERS+1];
static int weapontype[MAXPLAYERS+1];
static int bullet[MAXPLAYERS+1];
static float firetime[MAXPLAYERS+1];
static bool reloading[MAXPLAYERS+1];
static float reloadtime[MAXPLAYERS+1];
static float scantime[MAXPLAYERS+1];
static int SIenemy[MAXPLAYERS+1];
static int CIenemy[MAXPLAYERS+1];
static float gnomeangle[MAXPLAYERS+1][3];
static float lastgnomepos[MAXPLAYERS+1][3];
static float lastweaponpos[MAXPLAYERS+1][3];
static float lastjetpackpos[MAXPLAYERS+1][3];
static bool jetpack_active[MAXPLAYERS+1];
static float walktime[MAXPLAYERS+1];  // <--- AÑADIR ESTA LÍNEA
// ConVars
ConVar l4d_gnome_limit;
ConVar l4d_gnome_reactiontime;
ConVar l4d_gnome_scanrange;
ConVar l4d_gnome_damagefactor;
ConVar l4d_gnome_messages;
ConVar l4d_gnome_glow;

static float gnome_reactiontime;
static float gnome_scanrange;
static float gnome_damagefactor;
static int gnome_messages;
static char gnome_glow[12];

static int g_sprite;
static bool L4D2Version = false;
static int GameMode = 0;
static bool gamestart = false;

// Offsets de posición
#define WEAPON_OFFSET_X 14.0
#define WEAPON_OFFSET_Y 8.0
#define WEAPON_OFFSET_Z 6.0
#define WEAPON_SCALE 0.85

#define JETPACK_OFFSET_X 0.0
#define JETPACK_OFFSET_Y -8.0
#define JETPACK_OFFSET_Z -5.0
#define JETPACK_SCALE 0.9

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		L4D2Version = true;
		return APLRes_Success;
	}
	else if (GetEngineVersion() == Engine_Left4Dead)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	static char temp_str[32];
	
	Format(temp_str, sizeof(temp_str), "%s_limit", PLUGIN_NAME_TECH);
	l4d_gnome_limit = CreateConVar(temp_str, "2", "Number of Gnomes [0-3]", FCVAR_NONE);
	
	Format(temp_str, sizeof(temp_str), "%s_reactiontime", PLUGIN_NAME_TECH);
	l4d_gnome_reactiontime = CreateConVar(temp_str, "2.0", "Gnome reaction time [0.5, 5.0]", FCVAR_NONE);
	
	Format(temp_str, sizeof(temp_str), "%s_scanrange", PLUGIN_NAME_TECH);
	l4d_gnome_scanrange = CreateConVar(temp_str, "800.0", "Scan enemy range [100.0, 10000.0]", FCVAR_NONE);
	
	Format(temp_str, sizeof(temp_str), "%s_damagefactor", PLUGIN_NAME_TECH);
	l4d_gnome_damagefactor = CreateConVar(temp_str, "0.5", "Damage factor [0.2, 1.0]", FCVAR_NONE);
	
	Format(temp_str, sizeof(temp_str), "%s_messages", PLUGIN_NAME_TECH);
	l4d_gnome_messages = CreateConVar(temp_str, "3", "Which messages to enable", FCVAR_NONE);

	Format(temp_str, sizeof(temp_str), "%s_glow", PLUGIN_NAME_TECH);
	l4d_gnome_glow = CreateConVar(temp_str, "0 127 127", "The glow color to use for gnomes", FCVAR_NONE);

	AutoExecConfig(true, "l4d_gnomefly");
	HookConVarChange(l4d_gnome_reactiontime, ConVarChange);
	HookConVarChange(l4d_gnome_scanrange, ConVarChange);
	HookConVarChange(l4d_gnome_damagefactor, ConVarChange);
	HookConVarChange(l4d_gnome_messages, ConVarChange);
	HookConVarChange(l4d_gnome_glow, ConVarChange);
	GetConVar();

	static char GameName[13];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if (strncmp(GameName, "survival", 8, false) == 0)
		GameMode = 3;
	else if (strncmp(GameName, "versus", 6, false) == 0)
		GameMode = 2;
	else
		GameMode = 1;

	RegConsoleCmd("sm_gnomefly", sm_gnomefly);
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("round_end", RoundEnd, EventHookMode_Post);
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
	gamestart = false;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (RealValidEntity(gnome[i]))
		{
			Release(i);
		}
	}
}

void GetConVar()
{
	gnome_reactiontime = GetConVarFloat(l4d_gnome_reactiontime);
	gnome_scanrange = GetConVarFloat(l4d_gnome_scanrange);
	gnome_damagefactor = GetConVarFloat(l4d_gnome_damagefactor);
	gnome_messages = GetConVarInt(l4d_gnome_messages);
	GetConVarString(l4d_gnome_glow, gnome_glow, sizeof(gnome_glow));
}

void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();
}

public void OnMapStart()
{
	for (int i = 0; i < WEAPONCOUNT; i++)
	{
		if (L4D2Version || i <= 5)
		{
			PrecacheModel(MODEL[i], true);
		}
	}
	
	PrecacheModel(GNOME_MODEL, true);
	PrecacheModel(JETPACK_MODEL, true);
	PrecacheSound(SOUND_JETPACK, true);

	for (int i = 0; i < WEAPONCOUNT; i++)
	{
		PrecacheSound(SOUND[i], true);
	}
	
	PrecacheSound(SOUNDCLIPEMPTY, true);
	PrecacheSound(SOUNDRELOAD, true);
	PrecacheSound(SOUNDREADY, true);
	
	if (L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");
	}
	gamestart = false;
}

void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (RealValidEntity(gnome[i]))
		{
			Release(i, false);
		}
	}
}

void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (RealValidEntity(gnome[i]))
		{
			Release(i);
		}
	}
	gamestart = false;
}

void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	gnome[client] = 0;
	weapon_entity[client] = 0;
	jetpack_entity[client] = 0;
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!gamestart) return;
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(attacker))
	{
		if (attacker != victim && GetClientTeam(attacker) == 3)
		{
			scantime[victim] = GetEngineTime();
			SIenemy[victim] = attacker;
		}
	}
	else
	{
		int ent = GetEventInt(event, "attackerentid");
		CIenemy[victim] = ent;
	}
}

void DelEntity(int ent)
{
	if (!RealValidEntity(ent)) return;
	AcceptEntityInput(ent, "Kill");
}

void Release(int controller, bool del = true)
{
	int g = gnome[controller];
	int w = weapon_entity[controller];
	int j = jetpack_entity[controller];
	
	if (RealValidEntity(g))
	{
		gnome[controller] = 0;
		if (del) DelEntity(g);
	}
	
	if (RealValidEntity(w))
	{
		weapon_entity[controller] = 0;
		if (del) DelEntity(w);
	}
	
	if (RealValidEntity(j))
	{
		jetpack_entity[controller] = 0;
		if (del) DelEntity(j);
	}
	
	// Apagar llamas del jetpack
	for (int i = 0; i < 2; i++)
	{
		if (RealValidEntity(jetpack_flame[controller][i]))
		{
			AcceptEntityInput(jetpack_flame[controller][i], "TurnOff");
			DelEntity(jetpack_flame[controller][i]);
		}
		jetpack_flame[controller][i] = 0;
	}
	
	if (gamestart)
	{
		int count = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (RealValidEntity(gnome[i]))
			{
				count++;
			}
		}
		if (count == 0) gamestart = false;
	}
}

Action sm_gnomefly(int client, int args)
{
	if (GameMode == 2) return Plugin_Handled;
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Handled;
	if (RealValidEntity(gnome[client]))
	{
		PrintToChat(client, "You already have a gnome! Press WALK+USE to remove it.");
		return Plugin_Handled;
	}
	
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (RealValidEntity(gnome[i]))
		{
			count++;
		}
	}
	
	if (count + 1 > GetConVarInt(l4d_gnome_limit))
	{
		PrintToChat(client, "No more gnomes available!");
		return Plugin_Handled;
	}

	if (args >= 1)
	{
		static char arg[24];
		GetCmdArg(1, arg, sizeof(arg));
		if (strncmp(arg, "hunting", 7, false) == 0) weapontype[client] = 0;
		else if (strncmp(arg, "rifle", 5, false) == 0) weapontype[client] = 1;
		else if (strncmp(arg, "auto", 4, false) == 0) weapontype[client] = 2;
		else if (strncmp(arg, "pump", 4, false) == 0) weapontype[client] = 3;
		else if (strncmp(arg, "smg", 3, false) == 0) weapontype[client] = 4;
		else if (strncmp(arg, "pistol", 6, false) == 0) weapontype[client] = 5;
		else if (strncmp(arg, "magnum", 6, false) == 0 && L4D2Version) weapontype[client] = 6;
		else if (strncmp(arg, "ak47", 4, false) == 0 && L4D2Version) weapontype[client] = 7;
		else if (strncmp(arg, "desert", 6, false) == 0 && L4D2Version) weapontype[client] = 8;
		else if (strncmp(arg, "sg552", 5, false) == 0 && L4D2Version) weapontype[client] = 9;
		else if (strncmp(arg, "m60", 3, false) == 0 && L4D2Version) weapontype[client] = 10;
		else if (strncmp(arg, "chrome", 6, false) == 0 && L4D2Version) weapontype[client] = 11;
		else if (strncmp(arg, "spas", 4, false) == 0 && L4D2Version) weapontype[client] = 12;
		else if (strncmp(arg, "military", 8, false) == 0 && L4D2Version) weapontype[client] = 13;
		else if (strncmp(arg, "scout", 5, false) == 0 && L4D2Version) weapontype[client] = 14;
		else if (strncmp(arg, "awp", 3, false) == 0 && L4D2Version) weapontype[client] = 15;
		else if (strncmp(arg, "mp5", 3, false) == 0 && L4D2Version) weapontype[client] = 16;
		else if (strncmp(arg, "silenced", 8, false) == 0 && L4D2Version) weapontype[client] = 17;
		else
		{
			weapontype[client] = GetRandomInt(0, L4D2Version ? WEAPONCOUNT-1 : 5);
		}
	}
	else
	{
		weapontype[client] = GetRandomInt(0, L4D2Version ? WEAPONCOUNT-1 : 5);
	}
	
	AddGnome(client, true);
	return Plugin_Handled;
}

void AddGnome(int client, bool showmsg = false)
{
	float vAngles[3], vOrigin[3], pos[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	TR_TraceRayFilter(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit())
	{
		TR_GetEndPosition(pos);
	}

	float v1[3], v2[3];
	
	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);
	ScaleVector(v2, 50.0);
	AddVectors(pos, v2, v1);
	
	// Crear el gnome con movimiento FLY
	int ent = CreateEntityByName("prop_dynamic_override");
	if (!RealValidEntity(ent)) return;
	
	DispatchKeyValue(ent, "solid", "6");
	DispatchKeyValue(ent, "model", GNOME_MODEL);
	DispatchKeyValue(ent, "glowcolor", gnome_glow);
	DispatchKeyValue(ent, "glowstate", "2");
	DispatchSpawn(ent);
	TeleportEntity(ent, v1, NULL_VECTOR, NULL_VECTOR);
	
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
	SetEntityMoveType(ent, MOVETYPE_FLY);
	
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetAnimation");
	SetVariantString("idle");
	AcceptEntityInput(ent, "SetDefaultAnimation");
	
	// Crear el arma (independiente)
	int weaponEnt = CreateEntityByName("prop_dynamic_override");
	if (RealValidEntity(weaponEnt))
	{
		float weaponPos[3];
		weaponPos[0] = v1[0] + WEAPON_OFFSET_X;
		weaponPos[1] = v1[1] + WEAPON_OFFSET_Y;
		weaponPos[2] = v1[2] + WEAPON_OFFSET_Z;
		
		DispatchKeyValue(weaponEnt, "solid", "0");
		DispatchKeyValue(weaponEnt, "model", MODEL[weapontype[client]]);
		DispatchKeyValue(weaponEnt, "glowcolor", gnome_glow);
		DispatchKeyValue(weaponEnt, "glowstate", "2");
		DispatchSpawn(weaponEnt);
		
		SetEntPropFloat(weaponEnt, Prop_Send, "m_flModelScale", WEAPON_SCALE);
		SetEntProp(weaponEnt, Prop_Send, "m_CollisionGroup", 2);
		SetEntityMoveType(weaponEnt, MOVETYPE_FLY);
		
		float weaponAngles[3] = {0.0, 90.0, 0.0};
		TeleportEntity(weaponEnt, weaponPos, weaponAngles, NULL_VECTOR);
		
		weapon_entity[client] = weaponEnt;
	}
	
	// Crear el jetpack (independiente)
	int jetpackEnt = CreateEntityByName("prop_dynamic_override");
	if (RealValidEntity(jetpackEnt))
	{
		float jetpackPos[3];
		jetpackPos[0] = v1[0] + JETPACK_OFFSET_X;
		jetpackPos[1] = v1[1] + JETPACK_OFFSET_Y;
		jetpackPos[2] = v1[2] + JETPACK_OFFSET_Z;
		
		DispatchKeyValue(jetpackEnt, "solid", "0");
		DispatchKeyValue(jetpackEnt, "model", JETPACK_MODEL);
		DispatchKeyValue(jetpackEnt, "glowcolor", gnome_glow);
		DispatchKeyValue(jetpackEnt, "glowstate", "2");
		DispatchSpawn(jetpackEnt);
		
		SetEntPropFloat(jetpackEnt, Prop_Send, "m_flModelScale", JETPACK_SCALE);
		SetEntProp(jetpackEnt, Prop_Send, "m_CollisionGroup", 2);
		SetEntityMoveType(jetpackEnt, MOVETYPE_FLY);
		
		float jetpackAngles[3] = {0.0, 90.0, 0.0};
		TeleportEntity(jetpackEnt, jetpackPos, jetpackAngles, NULL_VECTOR);
		
		jetpack_entity[client] = jetpackEnt;
		
		// Crear llamas del jetpack (como child del jetpack)
		CreateJetpackFlame(client, jetpackEnt);
	}
	
	SIenemy[client] = 0;
	CIenemy[client] = 0;
	scantime[client] = 0.0;
	keybuffer[client] = 0;
	bullet[client] = weaponclipsize[weapontype[client]];
	reloading[client] = false;
	reloadtime[client] = 0.0;
	firetime[client] = 0.0;
	gnome[client] = ent;
	jetpack_active[client] = true;
	walktime[client] = 0.0;  // Inicializar walktime
	
	// Inicializar posiciones
	lastgnomepos[client][0] = v1[0];
	lastgnomepos[client][1] = v1[1];
	lastgnomepos[client][2] = v1[2];
	lastweaponpos[client][0] = 0.0;
	lastweaponpos[client][1] = 0.0;
	lastweaponpos[client][2] = 0.0;
	lastjetpackpos[client][0] = 0.0;
	lastjetpackpos[client][1] = 0.0;
	lastjetpackpos[client][2] = 0.0;
	
	if (showmsg && (gnome_messages & 1))
	{
		PrintHintText(client, "Flying gnome with jetpack and weapon! Press WALK+USE to remove.");
		PrintToChatAll("\x04%N\x03 summoned a flying gnome!", client);
	}
	
	gamestart = true;
}

void CreateJetpackFlame(int client, int jetpack)
{
	for (int i = 0; i < 2; i++)
	{
		int flame = CreateEntityByName("env_steam");
		if (RealValidEntity(flame))
		{
			DispatchKeyValue(flame, "SpawnFlags", "1");
			DispatchKeyValue(flame, "Type", "0");
			DispatchKeyValue(flame, "InitialState", "0");
			DispatchKeyValue(flame, "Spreadspeed", "2");
			DispatchKeyValue(flame, "Speed", "400");
			DispatchKeyValue(flame, "Startsize", "3");
			DispatchKeyValue(flame, "EndSize", "12");
			DispatchKeyValue(flame, "Rate", "555");
			DispatchKeyValue(flame, "RenderColor", "255 100 50");
			DispatchKeyValue(flame, "JetLength", "60");
			DispatchKeyValue(flame, "RenderAmt", "200");
			
			DispatchSpawn(flame);
			
			// Posición relativa al jetpack
			float flamePos[3];
			flamePos[0] = 0.0;
			flamePos[1] = (i == 0) ? -8.0 : 8.0;
			flamePos[2] = -12.0;
			
			TeleportEntity(flame, flamePos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(flame, "SetParent", jetpack);
			AcceptEntityInput(flame, "TurnOn");
			
			jetpack_flame[client][i] = flame;
		}
	}
	
	// Sonido del jetpack
	float pos[3];
	GetEntPropVector(jetpack, Prop_Send, "m_vecOrigin", pos);
	EmitSoundToAll(SOUND_JETPACK, jetpack, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, 100, -1, pos, NULL_VECTOR, true, 0.0);
}

void UpdateWeaponPosition(int client, float gnomeOrigin[3])
{
	if (!RealValidEntity(weapon_entity[client])) return;
	
	float newWeaponPos[3];
	newWeaponPos[0] = gnomeOrigin[0] + WEAPON_OFFSET_X;
	newWeaponPos[1] = gnomeOrigin[1] + WEAPON_OFFSET_Y;
	newWeaponPos[2] = gnomeOrigin[2] + WEAPON_OFFSET_Z;
	
	if (lastweaponpos[client][0] != 0.0)
	{
		newWeaponPos[0] = newWeaponPos[0] * 0.7 + lastweaponpos[client][0] * 0.3;
		newWeaponPos[1] = newWeaponPos[1] * 0.7 + lastweaponpos[client][1] * 0.3;
		newWeaponPos[2] = newWeaponPos[2] * 0.7 + lastweaponpos[client][2] * 0.3;
	}
	
	lastweaponpos[client][0] = newWeaponPos[0];
	lastweaponpos[client][1] = newWeaponPos[1];
	lastweaponpos[client][2] = newWeaponPos[2];
	
	float weaponAngles[3];
	weaponAngles[0] = gnomeangle[client][0];
	weaponAngles[1] = gnomeangle[client][1];
	weaponAngles[2] = gnomeangle[client][2];
	
	TeleportEntity(weapon_entity[client], newWeaponPos, weaponAngles, NULL_VECTOR);
}

void UpdateJetpackPosition(int client, float gnomeOrigin[3])
{
	if (!RealValidEntity(jetpack_entity[client])) return;
	
	float newJetpackPos[3];
	newJetpackPos[0] = gnomeOrigin[0] + JETPACK_OFFSET_X;
	newJetpackPos[1] = gnomeOrigin[1] + JETPACK_OFFSET_Y;
	newJetpackPos[2] = gnomeOrigin[2] + JETPACK_OFFSET_Z;
	
	if (lastjetpackpos[client][0] != 0.0)
	{
		newJetpackPos[0] = newJetpackPos[0] * 0.7 + lastjetpackpos[client][0] * 0.3;
		newJetpackPos[1] = newJetpackPos[1] * 0.7 + lastjetpackpos[client][1] * 0.3;
		newJetpackPos[2] = newJetpackPos[2] * 0.7 + lastjetpackpos[client][2] * 0.3;
	}
	
	lastjetpackpos[client][0] = newJetpackPos[0];
	lastjetpackpos[client][1] = newJetpackPos[1];
	lastjetpackpos[client][2] = newJetpackPos[2];
	
	float jetpackAngles[3];
	jetpackAngles[0] = gnomeangle[client][0];
	jetpackAngles[1] = gnomeangle[client][1];
	jetpackAngles[2] = gnomeangle[client][2];
	
	TeleportEntity(jetpack_entity[client], newJetpackPos, jetpackAngles, NULL_VECTOR);
}

static float lasttime = 0.0;
static int button;
static float gnomepos[3], robotvec[3];
static float clienteyepos[3];
static float clientangle[3], enemypos[3], infectedorigin[3], infectedeyepos[3];
static float chargetime;

void Do(int client, float currenttime)
{
	if (RealValidEntity(gnome[client]))
	{
		if (IsFakeClient(client) || !IsValidClient(client) || !IsPlayerAlive(client))
		{
			Release(client);
		}
		else
		{
			button = GetClientButtons(client);
			GetEntPropVector(gnome[client], Prop_Send, "m_vecOrigin", gnomepos);
			
			if ((button & IN_USE) && (button & IN_SPEED) && !(keybuffer[client] & IN_USE))
			{
				Release(client);
				if (gnome_messages & 1)
				{
					PrintToChatAll("\x04%N\x03 removed their flying gnome.", client);
				}
				return;
			}
			
			// Escanear enemigos
			if (currenttime - scantime[client] > gnome_reactiontime)
			{
				scantime[client] = currenttime;
				SIenemy[client] = ScanEnemy(client, gnomepos);
				CIenemy[client] = ScanCommon(client, gnomepos);
			}
			
			bool targetok = false;
			if (IsValidClient(SIenemy[client]) && IsPlayerAlive(SIenemy[client]))
			{
				GetClientEyePosition(SIenemy[client], infectedeyepos);
				GetClientAbsOrigin(SIenemy[client], infectedorigin);
				enemypos[0] = infectedorigin[0] * 0.4 + infectedeyepos[0] * 0.6;
				enemypos[1] = infectedorigin[1] * 0.4 + infectedeyepos[1] * 0.6;
				enemypos[2] = infectedorigin[2] * 0.4 + infectedeyepos[2] * 0.6;
				
				SubtractVectors(enemypos, gnomepos, gnomeangle[client]);
				GetVectorAngles(gnomeangle[client], gnomeangle[client]);
				targetok = true;
			}
			else
			{
				SIenemy[client] = 0;
			}
			
			if (!targetok && RealValidEntity(CIenemy[client]))
			{
				GetEntPropVector(CIenemy[client], Prop_Send, "m_vecOrigin", enemypos);
				enemypos[2] += 40.0;
				SubtractVectors(enemypos, gnomepos, gnomeangle[client]);
				GetVectorAngles(gnomeangle[client], gnomeangle[client]);
				targetok = true;
			}
			else if (!targetok)
			{
				CIenemy[client] = 0;
			}
			
			// Sistema de recarga (igual que antes)
			if (reloading[client])
			{
				if (bullet[client] >= weaponclipsize[weapontype[client]] && currenttime - reloadtime[client] > weaponloadtime[weapontype[client]])
				{
					reloading[client] = false;
					reloadtime[client] = currenttime;
					EmitSoundToAll(SOUNDREADY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, gnomepos, NULL_VECTOR, false, 0.0);
				}
				else if (currenttime - reloadtime[client] > weaponloadtime[weapontype[client]])
				{
					reloadtime[client] = currenttime;
					bullet[client] += weaponloadcount[weapontype[client]];
					if (bullet[client] > weaponclipsize[weapontype[client]])
						bullet[client] = weaponclipsize[weapontype[client]];
					EmitSoundToAll(SOUNDRELOAD, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, gnomepos, NULL_VECTOR, false, 0.0);
				}
			}
			
			if (!reloading[client] && !targetok && bullet[client] < weaponclipsize[weapontype[client]])
			{
				reloading[client] = true;
				reloadtime[client] = currenttime;
				if (!weaponloaddisrupt[weapontype[client]])
				{
					bullet[client] = 0;
				}
			}
			
			// Disparo
			if (!reloading[client] && currenttime - firetime[client] > fireinterval[weapontype[client]])
			{
				if (targetok && bullet[client] > 0)
				{
					bullet[client]--;
					FireBullet(client, gnome[client], enemypos, gnomepos);
					firetime[client] = currenttime;
				}
				else if (targetok && bullet[client] <= 0)
				{
					firetime[client] = currenttime;
					EmitSoundToAll(SOUNDCLIPEMPTY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, gnomepos, NULL_VECTOR, false, 0.0);
					reloading[client] = true;
					reloadtime[client] = currenttime;
				}
			}
			
			// MOVIMIENTO EXACTAMENTE COMO EL ROBOT
			GetClientEyePosition(client, clienteyepos);
			clienteyepos[2] += 30.0;
			GetClientEyeAngles(client, clientangle);
			
			float distance = GetVectorDistance(gnomepos, clienteyepos);
			
			// MISMA LÓGICA QUE EL ROBOT
			if (distance > 500.0)
			{
				TeleportEntity(gnome[client], clienteyepos, gnomeangle[client], NULL_VECTOR);
			}
			else if (distance > 100.0)
			{
				MakeVectorFromPoints(gnomepos, clienteyepos, robotvec);
				NormalizeVector(robotvec, robotvec);
				ScaleVector(robotvec, 5.0 * distance);
				
				if (!targetok)
				{
					GetVectorAngles(robotvec, gnomeangle[client]);
				}
				
				TeleportEntity(gnome[client], NULL_VECTOR, gnomeangle[client], robotvec);
				walktime[client] = currenttime;
			}
			else
			{
				robotvec[0] = robotvec[1] = robotvec[2] = 0.0;
				if (!targetok && currenttime - firetime[client] > 4.0 && currenttime - walktime[client] > 1.0)
				{
					gnomeangle[client][1] += 5.0;
				}
				TeleportEntity(gnome[client], NULL_VECTOR, gnomeangle[client], robotvec);
			}
			
			// ACTUALIZAR POSICIONES DE ARMA Y JETPACK (INDEPENDIENTES)
			GetEntPropVector(gnome[client], Prop_Send, "m_vecOrigin", gnomepos);
			UpdateWeaponPosition(client, gnomepos);
			UpdateJetpackPosition(client, gnomepos);
			
			keybuffer[client] = button;
		}
	}
}

public void OnGameFrame()
{
	if (!gamestart) return;
	
	float currenttime = GetEngineTime();
	for (int client = 1; client <= MaxClients; client++)
	{
		Do(client, currenttime);
	}
}

int ScanCommon(int client, float rpos[3])
{
	float infectedpos[3], vec[3], angle[3];
	int find = 0;
	float mindis = 100000.0, dis = 0.0;
	
	for (int i = MaxClients + 1; i <= GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		static char classname[9];
		GetEntityClassname(i, classname, sizeof(classname));
		if (strcmp(classname, "infected", false) != 0) continue;
		
		int health = GetEntProp(i, Prop_Data, "m_iHealth");
		if (health <= 0) continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", infectedpos);
		dis = GetVectorDistance(rpos, infectedpos);
		
		if (dis < gnome_scanrange && dis < mindis)
		{
			SubtractVectors(infectedpos, rpos, vec);
			GetVectorAngles(vec, angle);
			TR_TraceRayFilter(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, gnome[client]);
			
			if (!TR_DidHit())
			{
				find = i;
				mindis = dis;
			}
		}
	}
	return find;
}

int ScanEnemy(int client, float rpos[3])
{
	float infectedpos[3], vec[3], angle[3];
	int find = 0;
	float mindis = 100000.0, dis = 0.0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			GetClientEyePosition(i, infectedpos);
			dis = GetVectorDistance(rpos, infectedpos);
			
			if (dis < gnome_scanrange && dis < mindis)
			{
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				TR_TraceRayFilter(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, gnome[client]);
				
				if (!TR_DidHit())
				{
					find = i;
					mindis = dis;
				}
			}
		}
	}
	return find;
}

void FireBullet(int controller, int bot, float infectedpos[3], float botorigin[3])
{
	float vAngles[3], vAngles2[3], pos[3];
	
	SubtractVectors(infectedpos, botorigin, infectedpos);
	GetVectorAngles(infectedpos, vAngles);
	
	float arr1 = 0.0 - bulletaccuracy[weapontype[controller]];
	float arr2 = bulletaccuracy[weapontype[controller]];
	
	float v1[3], v2[3];
	for (int c = 0; c < weaponbulletpershot[weapontype[controller]]; c++)
	{
		vAngles2[0] = vAngles[0] + GetRandomFloat(arr1, arr2);
		vAngles2[1] = vAngles[1] + GetRandomFloat(arr1, arr2);
		vAngles2[2] = vAngles[2] + GetRandomFloat(arr1, arr2);
		
		int hittarget = 0;
		TR_TraceRayFilter(botorigin, vAngles2, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, bot);
		
		if (TR_DidHit())
		{
			TR_GetEndPosition(pos);
			hittarget = TR_GetEntityIndex();
			
			float Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(pos, Direction, 1, 3);
			TE_SendToAll();
		}
		
		if (hittarget > 0)
		{
			DoDamage(weapontype[controller], hittarget, controller);
		}
		
		SubtractVectors(botorigin, pos, v1);
		NormalizeVector(v1, v2);
		ScaleVector(v2, 36.0);
		SubtractVectors(botorigin, v2, infectedorigin);
		
		int color[4] = {200, 200, 200, 230};
		float life = 0.06, width1 = 0.01, width2 = L4D2Version ? 0.08 : 0.3;
		
		TE_SetupBeamPoints(infectedorigin, pos, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
		TE_SendToAll();
		
		EmitSoundToAll(SOUND[weapontype[controller]], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, botorigin, NULL_VECTOR, false, 0.0);
	}
}

void DoDamage(int wtype, int target, int sender)
{
	if (!RealValidEntity(target)) return;
	if (!RealValidEntity(sender)) return;
	
	int robot_var = sender;
	if (RealValidEntity(gnome[sender]))
		robot_var = gnome[sender];
	
	float damage = weaponbulletdamage[wtype] * gnome_damagefactor;
	SDKHooks_TakeDamage(target, robot_var, sender, damage, DMG_BULLET, robot_var);
}

bool TraceRayDontHitSelfAndLive(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (IsValidClient(entity)) return false;
	if (RealValidEntity(entity))
	{
		static char classname[9];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "infected", false) == 0) return false;
	}
	return true;
}

bool TraceRayDontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (IsValidClient(entity) && (GetClientTeam(entity) == 2 || GetClientTeam(entity) == 4)) return false;
	return true;
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

public void OnClientDisconnect(int client)
{
	Release(client);
}