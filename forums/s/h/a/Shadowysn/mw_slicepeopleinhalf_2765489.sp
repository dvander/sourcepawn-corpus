// Plugin by Mecha the Slag (http://MechaWare.net/)
// Models and belonging textures by Valve, modified by Mecha the Slag
// Meat texture by NeoDement (http://www.tf2items.com/id/neodement)

#define PLUGIN_NAME "[TF2] Slice People in Half"
#define PLUGIN_AUTHOR "Mecha the Slag, Shadowysn (new-syntax)"
#define PLUGIN_DESC "Slice people in two halves with sharp melee weapons!"
#define PLUGIN_VERSION "1.35"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2765489&postcount=97"
#define PLUGIN_NAME_SHORT "Slice People in Half"
#define PLUGIN_NAME_TECH "slice"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

// Definitions
#define DF_CRITS			(1 << 20)	 //crits = DAMAGE_ACID
#define DF_NO_CRITS		65536	   //nocrit
#define AUTOEXEC_CFG		"mw_slicepeopleinhalf"

bool g_bSliced[MAXPLAYERS+1];
float g_fTimeUntilSlice[MAXPLAYERS+1] = {-1.0};
static const char g_strWeapons[][] =
{
	"sword", // Demoman Eyelander
	"axtinguisher", // Pyro Axtinguisher
	"fireaxe", // Pyro Fire Axe
	"battleaxe", // Demoman Scotsman Skullcutter
	"headtaker", // Demoman HHH Headtaker
	"claidheamohmor", // Demoman Claidheamh Mor
	"demokatana", // Demoman|Soldier Half Zatoichi, is special case, soldier won't swing vertically
	"persian_persuader", // Demoman Persian Persuader
	//"nessieclub", // Demoman Nessie Nine Iron, should this count though?
};
static ConVar g_hChance, g_hIcon, g_hSuicide;
float g_fChance;
int g_iIcon;
bool g_bSuicide;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_chance", PLUGIN_NAME_TECH);
	g_hChance =	CreateConVar(cmd_str, "1.0", "Chance for the slice to happen. 1.0 = always, 0.0 = never", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hChance.AddChangeHook(CC_SIH_Chance);
	Format(cmd_str, sizeof(cmd_str), "%s_icon", PLUGIN_NAME_TECH);
	g_hIcon =	CreateConVar(cmd_str, "2", "1: Always changes the slice icon to sawblade, 2: Only on sm_slice or sm_sliceme", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hIcon.AddChangeHook(CC_SIH_Icon);
	Format(cmd_str, sizeof(cmd_str), "%s_suicide", PLUGIN_NAME_TECH);
	g_hSuicide =	CreateConVar(cmd_str, "0", "If on, allows sm_sliceme suicides", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSuicide.AddChangeHook(CC_SIH_Suicide);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvars();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	
	RegAdminCmd("sm_slice", Command_Slice, ADMFLAG_SLAY, "sm_slice <#userid|name>");
	RegConsoleCmd("sm_sliceme", Command_SliceMe, "Slice Yourself in Half!");
	
	// Use common.phrases for ReplyToTargetError
	LoadTranslations("common.phrases");
}

void CC_SIH_Chance(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_fChance =	convar.FloatValue;	}
void CC_SIH_Icon(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iIcon =		convar.IntValue;	}
void CC_SIH_Suicide(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bSuicide =	convar.BoolValue;	}
void SetCvars()
{
	CC_SIH_Chance(g_hChance, "", "");
	CC_SIH_Icon(g_hIcon, "", "");
	CC_SIH_Suicide(g_hSuicide, "", "");
}

bool shouldRemoveRag = false;
int slotsForBluGibs = 0;

public void OnEntityCreated(int entity, const char[] classname)
{
	//PrintToServer("entitycreated: %s", classname);
	//PrintToServer("slotsForBluGibs: %i", slotsForBluGibs);
	if ((slotsForBluGibs <= 0 || classname[0] != 'r') && (!shouldRemoveRag || classname[0] != 't')) return;
	
	if (strcmp(classname, "raggib", false) == 0)
	{
		slotsForBluGibs--;
		SetEntProp(entity, Prop_Send, "m_nSkin", 1);
	}
	else if (strcmp(classname, "tf_ragdoll", false) == 0)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	g_bSliced[client] = false;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0)); 
	int damagebits = event.GetInt("damagebits", 0);
	static char strWeapon[PLATFORM_MAX_PATH];
	event.GetString("weapon", strWeapon, sizeof(strWeapon));
	bool bAcceptable = false;
	//int customkill = event.GetInt("customkill", 0);
	
	int inflictor = event.GetInt("inflictor_entindex", 0);
	static char infl_str[16]; infl_str[0] = '\0';
	if (RealValidEntity(inflictor))
	{
		GetEntityClassname(inflictor, infl_str, sizeof(infl_str));
		//PrintToServer("inflictor_entindex: %i, %s", inflictor, infl_str);
		//PrintToServer("strcmp: %i", strcmp(infl_str, "headless_hatman", false));
	}
	
	int attacker = GetClientOfUserId(event.GetInt("attacker", 0)); 
	TFClassType iAttackClass = TFClass_Unknown;
	if (IsValidClient(attacker))
		iAttackClass = TF2_GetPlayerClass(attacker);
	
	//if (customkill & TF_CUSTOM_DECAPITATION)
	if (strcmp(infl_str, "headless_hatman", false) == 0)
	{
		bAcceptable = true;
		damagebits &= DMG_CRIT;
	}
	else
	{
		for (int iLoop = 0; iLoop < sizeof(g_strWeapons); iLoop++)
		{
			if (strcmp(strWeapon, g_strWeapons[iLoop], false) == 0)
			{
				if (strcmp(strWeapon, "demokatana", false) != 0 || iAttackClass == TFClass_DemoMan)
					bAcceptable = true;
			}
		}
	}
	
	float fRandom = GetRandomFloat();
	
	if (IsValidClient(client) && ((damagebits & DMG_CRIT && bAcceptable && (g_fChance >= fRandom)) || g_bSliced[client]))
	{
		static char strClassname[52]; strClassname[0] = '\0';
		TFClassType iClass = TF2_GetPlayerClass(client);
		if (iClass == TFClass_DemoMan)	strcopy(strClassname, sizeof(strClassname), "demo");
		if (iClass == TFClass_Pyro)		strcopy(strClassname, sizeof(strClassname), "pyro");
		if (iClass == TFClass_Heavy)		strcopy(strClassname, sizeof(strClassname), "heavy");
		if (strClassname[0] != '\0')
		{
			static char strModel[PLATFORM_MAX_PATH];
			Format(strModel, sizeof(strModel), "models/decapitation/%s_left2.mdl", strClassname);
			CreateGib(client, strModel, 1.0);
			Format(strModel, sizeof(strModel), "models/decapitation/%s_right2.mdl", strClassname);
			CreateGib(client, strModel, -1.0);
			
			float origin[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", origin);
			WriteParticle(origin, "env_sawblood");
			WriteParticle(origin, "env_sawblood");
			WriteParticle(origin, "env_sawblood");
			WriteParticle(origin, "env_sawblood_chunk");
			WriteParticle(origin, "env_sawblood_chunk");
			WriteParticle(origin, "env_sawblood_chunk");
			WriteParticle(origin, "env_sawblood_goop");
			WriteParticle(origin, "env_sawblood_goop");
			EmitGameSoundToAll("TFPlayer.Decapitated", -1, SNDLEVEL_SCREAMING, -1, origin);
			
			shouldRemoveRag = true;
			RequestFrame(RemoveBody, client);
			if (g_iIcon == 1 || (g_iIcon == 2 && g_bSliced[client]))
			{
				int damagebits2 = DF_NO_CRITS;
				if (damagebits & DMG_CRIT)
				{
					damagebits2 += DMG_CRIT;
				}
				event.SetInt("damagebits", damagebits2);
			}
		}
	}
	
	g_bSliced[client] = false;
}

void RemoveBody(int client)
{
	/*int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (RealValidEntity(iRagdoll))
	{
		AcceptEntityInput(iRagdoll, "Kill");
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", -1);
	}*/
	shouldRemoveRag = false;
}

public void OnMapStart()
{
	PrecacheModel("models/decapitation/demo_left2.mdl", true);
	PrecacheModel("models/decapitation/demo_right2.mdl", true);
	AddToDownloadModel("models/decapitation/demo_left2");
	AddToDownloadModel("models/decapitation/demo_right2");
	
	PrecacheModel("models/decapitation/pyro_left2.mdl", true);
	PrecacheModel("models/decapitation/pyro_right2.mdl", true);
	AddToDownloadModel("models/decapitation/pyro_left2");
	AddToDownloadModel("models/decapitation/pyro_right2");
	
	PrecacheModel("models/decapitation/heavy_left2.mdl", true);
	PrecacheModel("models/decapitation/heavy_right2.mdl", true);
	AddToDownloadModel("models/decapitation/heavy_left2");
	AddToDownloadModel("models/decapitation/heavy_right2");
	
	AddFileToDownloadsTable("materials/models/decapitation/meat.vtf");
	AddFileToDownloadsTable("materials/models/decapitation/meat.vmt");
	
	PrecacheScriptSound("TFPlayer.Decapitated");
}

void AddToDownloadModel(const char strPath[PLATFORM_MAX_PATH])
{
	static char strModel[PLATFORM_MAX_PATH];
	Format(strModel, sizeof(strModel), "%s.mdl", strPath);
	AddFileToDownloadsTable(strModel);
	Format(strModel, sizeof(strModel), "%s.dx80.vtx", strPath);
	AddFileToDownloadsTable(strModel);
	Format(strModel, sizeof(strModel), "%s.dx90.vtx", strPath);
	AddFileToDownloadsTable(strModel);
	Format(strModel, sizeof(strModel), "%s.phy", strPath);
	AddFileToDownloadsTable(strModel);
	Format(strModel, sizeof(strModel), "%s.sw.vtx", strPath);
	AddFileToDownloadsTable(strModel);
	Format(strModel, sizeof(strModel), "%s.vvd", strPath);
	AddFileToDownloadsTable(strModel);
}

void CreateGib(int client, const char strModel[PLATFORM_MAX_PATH], float fDir)
{
	float fOrigin[3], fAngle[3], fVel[3];
	GetClientAbsOrigin(client, fOrigin);
	GetClientEyeAngles(client, fAngle);
	
	fAngle[0] = 0.0;
	fAngle[1] += 90.0;
	fAngle[2] = 90.0;
	
	float fOffset1 = Cosine(fAngle[1]*0.0174532925),
	fOffset2 = Sine(fAngle[1]*0.0174532925),
	//fStrength = GetRandomFloat(100.0, 1000.0);
	fStrength = GetRandomFloat(75.0, 90.0);
	
	fVel[0] += fOffset1*fDir*fStrength;
	fVel[1] += fOffset2*fDir*fStrength;
	fVel[2] += fStrength;
	
	//TFClassType iClass = TF2_GetPlayerClass(client);
	//switch (iClass)
	//{
		//case TFClass_DemoMan:
		//{
	fOrigin[0] += fOffset1*5.0;
	fOrigin[1] += fOffset2*5.0;
	fOrigin[2] += 40.0;
		/*}
		case TFClass_Heavy:
		{
			fOrigin[0] -= fOffset1*25.0;
			fOrigin[1] -= fOffset2*25.0;
			fOrigin[2] += 50.0;
		}
		case TFClass_Pyro:
		{
			fOrigin[0] += fOffset1*2.0;
			fOrigin[1] += fOffset2*2.0;
			fOrigin[2] += 0.0;
		}*/
	//}

	/*int ragdoll = CreateEntityByName("prop_ragdoll");
	DispatchKeyValue(ragdoll, "model", strModel);
	
	if (GetClientTeam(client) == 3) DispatchKeyValue(ragdoll, "skin", "1");
	
	DispatchSpawn(ragdoll); ActivateEntity(ragdoll);
	DispatchKeyValue(ragdoll, "OnUser1", "!self,Kill,,15.0,-1");
	AcceptEntityInput(ragdoll, "FireUser1");
	
	SetEntProp(ragdoll, Prop_Data, "m_CollisionGroup", 1);
	SetEdictFlags(ragdoll, 4);
	TeleportEntity(ragdoll, fOrigin, fAngle, fVel);*/
	
	int ragshooter = CreateEntityByName("env_shooter");
	DispatchKeyValue(ragshooter, "spawnflags", "4"); // Fade out even when in player's view
	DispatchKeyValue(ragshooter, "shootmodel", strModel);
	DispatchKeyValue(ragshooter, "delay", "0");
	DispatchKeyValue(ragshooter, "m_iGibs", "1");
	DispatchKeyValue(ragshooter, "m_flGibLife", "15");
	DispatchKeyValue(ragshooter, "m_flVariance", "0");
	DispatchKeyValue(ragshooter, "Simulation", "2");
	//DispatchKeyValueVector(ragshooter, "origin", fOrigin);
	//DispatchKeyValueVector(ragshooter, "angles", fAngle);
	
	//DispatchKeyValueVector(ragshooter, "gibangles", fAngle); // This doesn't work?
	//DispatchKeyValue(ragshooter, "gibanglevelocity", "0 0 0");
	
	DispatchKeyValueVector(ragshooter, "m_flVelocity", fVel);
	TeleportEntity(ragshooter, fOrigin, fAngle, NULL_VECTOR); // Use this instead.
	
	DispatchSpawn(ragshooter); ActivateEntity(ragshooter);
	//if (GetClientTeam(client) == TFTeam_Blue) SetEntProp(ragshooter, Prop_Data, "m_nSkin", 1); // Doesn't work for env_shooter
	if (view_as<TFTeam>(GetClientTeam(client)) == TFTeam_Blue) slotsForBluGibs++;
	// Go to OnEntityCreated to see how the skin is changed and why slotsForBluGibs is relevant for it
	
	AcceptEntityInput(ragshooter, "Shoot");
	DispatchKeyValue(ragshooter, "OnUser1", "!self,Kill,,1.0,-1");
	AcceptEntityInput(ragshooter, "FireUser1");
}

void WriteParticle(const float origin[3], const char[] strParticle)
{
	//Initialize:
	int particle = CreateEntityByName("info_particle_system");
	
	//Validate:
	if (!RealValidEntity(particle)) return;
	
	//Declare:
	float fPos[3], fAngle[3];

	//Initialize:
	fAngle[0] = GetRandomFloat(0.0, 360.0);
	fAngle[1] = GetRandomFloat(0.0, 15.0);
	fAngle[2] = GetRandomFloat(0.0, 15.0);

	//Origin:
	fPos = origin;
	fPos[2] += GetRandomFloat(35.0, 65.0);
	TeleportEntity(particle, fPos, fAngle, NULL_VECTOR);

	//Properties:
	DispatchKeyValue(particle, "effect_name", strParticle);

	//Spawn:
	DispatchSpawn(particle);
	
	//Start:
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	//Delete:
	DispatchKeyValue(particle, "OnUser1", "!self,Kill,,3.0,-1");
	AcceptEntityInput(particle, "FireUser1");
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }

Action Command_SliceMe(int client, int args)
{
	if (!g_bSuicide || !IsValidClient(client)) return Plugin_Handled;
	float game_time = GetGameTime();
	if (g_fTimeUntilSlice[client] > game_time) return Plugin_Handled;
	g_fTimeUntilSlice[client] = game_time+5.0;
	
	g_bSliced[client] = true;
	SetEntityHealth(client, 1);
	SDKHooks_TakeDamage(client, 0, client, 100.0, DMG_CRIT|DMG_CLUB|DMG_SLASH, -1);
	if (IsPlayerAliveNotGhost(client))
		ForcePlayerSuicide(client);
	return Plugin_Handled;
}

Action Command_Slice(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_slice <#userid|name>");
		return Plugin_Handled;
	}

	static char strArg[65];
	GetCmdArgString(strArg, sizeof(strArg));
	
	static char target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			strArg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int iLoop = 0; iLoop < target_count; iLoop++)
	{
		if (!IsValidClient(target_list[iLoop])) continue;
		
		g_bSliced[target_list[iLoop]] = true;
		SetEntityHealth(target_list[iLoop], 1);
		SDKHooks_TakeDamage(target_list[iLoop], 0, target_list[iLoop], 100.0, DMG_CRIT|DMG_CLUB|DMG_SLASH, -1);
		if (IsPlayerAliveNotGhost(target_list[iLoop]))
			ForcePlayerSuicide(target_list[iLoop]); // use this as a backup option
	}

	return Plugin_Handled;
}