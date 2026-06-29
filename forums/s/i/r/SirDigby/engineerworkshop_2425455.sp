// --- Preprocessor -------------------------------------------------------------------------
#pragma semicolon 1
// --- Includes -----------------------------------------------------------------------------
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma newdecls required // Leave this after includes or you get warnings
// --- Definitions --------------------------------------------------------------------------

#define UPDATE_URL	"http://sirdigbot.bitbucket.org/sourcemod/engieshop/updatefile.txt"

enum EBuildingTypes
{
	Building_Invalid = -1,
	Building_Sentry = 0,
	Building_Dispenser,
	Building_Entry,
	Building_Exit,
	Building_All
}

enum EBuildVecTypes
{
	Vec_Sentry = 0,
	Vec_Dispenser,
	Vec_Teleport,
	Vec_Minisentry
}

/*** Most of these are un-used. ***/
enum EObjCollisions
{
	Coll_Ignore = 1,		/*** Ignore Absolutely Everything ***/
	Coll_Client = 2,		/*** Ignore Players (and a few projectiles) ***/
	Coll_Client2 = 10,		/*** Ignore Player, Projectiles and Bullets ***/
	Coll_Default = 21,		/*** Standard Collision for Sentry and Dispenser ***/
	Coll_Teleporter = 22	/*** Standard Collision for Teleporters ***/
}

enum
{
	Bounds_Lower = 0,
	Bounds_Upper,
	EScaleBounds
}

enum EMenuItemAccess
{
	Item_Resize = 1,
	Item_Friendly,
	Item_Outline,
	Item_Abilties,
	Item_Color,
	Item_Resize_Admin,
	Item_DamageScale_Admin,
	Item_Abilities_Ammo,
	Item_Abilities_NoSap,
	Item_Abilities_God,
	Item_Abilities_DmgToggle,
	Item_Abilities_Tele
}

#define PLUGIN_VERSION		"1.0.12b"
#define TAG_SM		"\x04[SM]\x01"
#define TAG_CON		"[SM]"

/*** #define _DEBUGMODE ***/

#define CHOICE1		"#c1"
#define CHOICE2		"#c2"
#define CHOICE3		"#c3"
#define CHOICE4		"#c4"
#define CHOICE5		"#c5"
#define CHOICE6		"#c6"
#define CHOICE7		"#c7"
#define CHOICE8		"#c8"
#define CHOICE9		"#c9"
#define CHOICE10		"#c0"
#define CHOICE11		"#cA"
#define CHOICE12		"#cB"
#define CHOICE13		"#cC"
#define CHOICE14		"#cD"
#define CHOICE15		"#cE"
#define CHOICE16		"#cF"

//0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0
#define MENU_SCALEITEMS	12
#define MENU_MAXCOLORS	32
#define MINI_DEFAULTSCALE 0.75
#define GUNSLINGER_IDI 142
#define BCOLOR_DEFAULT 99
#define ALPHA_FRIENDLY 210

#define VGUI_WIDTH 20.0
#define VGUI_HEIGHT 11.0
// --- Flagbit Definitions ------------------------------------------------------------------

#define FLG_ACTIVE				(1<<0)	/*** Is Building Currently Built ***/
#define FLG_ISRESIZED			(1<<1)	/*** Needed to know whether to fix g_flBuildingScale for mini-sentries, or to scale damage. Let's us know if minisentry is default ***/
#define FLG_ISMINISENTRY		(1<<2)	/*** Is the building a minisentry. ***/
#define FLG_SCALEDMG			(1<<3)	/*** Is this building allowed to scale its damage -- This value is set during resizing, so it's valid for both down and upscaling ***/
#define	FLG_FRIENDLY			(1<<4)	/*** Is this building friendly. Needed to block building from dealing damage/knockback ***/
#define FLG_OUTLINE				(1<<5)	/*** Does the building have an outline ***/
#define FLG_NOSAP				(1<<6)	/*** Is the building Unsappable -- In Abilities section. Admin only. This is only ever applied to Building_Sentry, but is effective for all buildings ***/
#define FLG_INFINITE			(1<<7)	/*** Does the building have infinite ammo. ***/
#define FLG_INVULN				(1<<8)	/*** Does the building have godmode ***/

//#define FLG_ALL			(1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8) /*** Used for removing all flags when checking entity index. DOESNT WORK. ***/
// --- Handles ------------------------------------------------------------------------------
Handle h_bCvarEnabled = null;
Handle h_flScaleLimits = null;
Handle h_iCollisionType = null;
Handle h_flCooldown = null;
Handle h_strColorConfig = null;
Handle h_bUpdate = null;
Handle h_iDamageUpscaleMode = null;
Handle h_iDamageDownscaleMode = null;
// --- Variables ----------------------------------------------------------------------------
bool g_bCvarEnabled;
float g_flScaleLimits[EScaleBounds];
static const float g_flBuildingMins[4][3] = {{-20.0, -20.0, 0.0}, {-20.0, -20.0, 0.0}, {-24.0, -24.0, 0.0}, {-15.0, -15.0, 0.0}}; //Sentry, Dispenser, Teleporter, Minisentry
static const float g_flBuildingMaxs[4][3] = {{20.0, 20.0, 66.0}, {20.0, 20.0, 55.0}, {24.0, 24.0, 12.0}, {15.0, 15.0, 49.5}};
int g_iCollisionType;
bool g_bLateLoad;
float g_flCooldown;
char g_strColorConfig[PLATFORM_MAX_PATH];
bool g_bUpdate;
int g_iDamageUpscaleMode;
int g_iDamageDownscaleMode;

char g_ColorNames[MENU_MAXCOLORS][16];
char g_Colors[MENU_MAXCOLORS][14];	//RGB: "255, 255, 255" = 13 characters
int g_iColorCount;
// --- Player Variables ---------------------------------------------------------------------
int g_iBuildingIndex[4][MAXPLAYERS + 1];		/*** The entity index for each building ***/			
int g_fbBuildingInfo[4][MAXPLAYERS + 1];		/*** The flagbits for each building ***/
float g_flBuildingScale[4][MAXPLAYERS + 1];		/*** Buidling Scale -- Used for damage scaling and Build Hooks ***/
int g_iBuildingColor[4][MAXPLAYERS + 1];		/*** Buidling Color. 99 (BCOLOR_DEFAULT) for default. ***/
float g_flLastCommand[MAXPLAYERS + 1] = {0.0, ...};	/*** The GetGameTime() for when a client last used a MENU command (i.e. Do not print message) -- Used to prevent spam-based crashes ***/



/***********************************************
	NOTES:

Menu Structure:
	-Main				-- Cooldown on select (loads for submenus)
		-Resize				-- Cooldown on load
			|-All
			|-Sentry
			|-Dispenser
			|-Tele Entry
			|-Tele Exit
			|----Float/Scale List		-- Cooldown on select
			-Reset All Buildings
			
		-Friendly Sentry Toggle
		-Outline Toggle				-- Cooldown on load
			-Enable All
			-Disable All
			-Toggle Sentry Outline
			-Toggle Dispenser Outline
			-Toggle Tele Entry Outline
			-Toggle Tele Exit Outline
		-Abilities
			-Infinite Ammo Toggle
			-Unsappable Toggle
			-Godmode Toggle
			-Teleport Building to Crosshair				-- Cooldown on select
				-Sentry
				-Dispenser
				-Tele Entry
				-Tele Exit
		-Color Building				-- Cooldown on select
			-List of Preset Colors
			-(?)Type Hex Code in Chat -- Use regex to verify


		-Updater Support
		
		
		
		
KNOWN BUGS:
		- Friendly Sentry does not prevent targeting.
			- It does, however, nullify damage.
		- Resized buildings have un-updated hitboxes.
			- This is solved by setting their collision type to ignore other players (when they aren't default size)
			Effectively preventing any unfair blocking.
		
PROBABLY PATCHED:
		- Infinite Ammo does not apply to active buildings.
		- There is no cooldown for using any functions, allowing a player to spam repeatedly.
			- This has been implemented, but is untested.
		- No-Sap had a sound-looping bug. This has probably been resolved, but I did optimise the code I borrowed, so maybe not.
		
		
		
		
Commands:
sm_engieshop
sm_rb
sm_friendlysentry
sm_buildingoutline

Overrides:
sm_engieshop_scale_admin	//Allow full selection of sizes
sm_engieshop_abilities		//Allow access to Abilities on Main Menu
sm_engieshop_damage_admin	//Allow access to Damage Upscaling.
sm_engieshop_ability_ammo	//Allow access to Abilities::Infinite Ammo
sm_engieshop_ability_nosap	//Allow access to Abilities::No-Sap
sm_engieshop_ability_god	//Allow access to Abilities::Godmode
sm_engieshop_ability_dmgtoggle	//Allow access to Abilities::Toggle Damage Scaling
sm_engieshop_ability_tele	//Allow access to Abilities::Teleport to Crosshair
sm_engieshop_color			//Allow access to the Color Buildings option.

***********************************************/




public Plugin myinfo = 
{
	name = "[TF2] Engineer's Workshop",
	author = "SirDigby",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};


public void OnPluginStart()
{
	LoadTranslations("engineerworkshop.phrases.txt");
	
	CreateConVar("dig_engieshop_version", PLUGIN_VERSION, "Engineer's Workshop version. Do Not Touch!", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	h_bCvarEnabled = CreateConVar("sm_engieshop_enabled", "1", "Toggle Engineer's Workshop\n(Default: 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(h_bCvarEnabled);
	HookConVarChange(h_bCvarEnabled, UpdateCvars);
	
	char boundExplode[EScaleBounds][16], buffer[32];
	h_flScaleLimits = CreateConVar("sm_engieshop_scale_bounds", "0.25;1.25", "Building Scale Limits for Non-Admins.\n(Separated by semicolon. Valid sizes are in increments of 0.25)\n(Default: 0.25;1.25)", FCVAR_PLUGIN);
	GetConVarString(h_flScaleLimits, buffer, sizeof(buffer));
	ExplodeString(buffer, ";", boundExplode, sizeof(boundExplode), sizeof(boundExplode[]));
	g_flScaleLimits[Bounds_Lower] = StringToFloat(boundExplode[Bounds_Lower]);
	g_flScaleLimits[Bounds_Upper] = StringToFloat(boundExplode[Bounds_Upper]);
	HookConVarChange(h_flScaleLimits, UpdateCvars);
	
	h_iCollisionType = CreateConVar("sm_engieshop_collision", "1",
	"The collision mode used when resizing a building.\n 0 - No Change (Buggy)\n 1 - Disable Collisions (Default)\n 2 - Disable Collision, execept Teleporters (Teleporters won't lock out teammates)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_iCollisionType = GetConVarBool(h_iCollisionType);
	HookConVarChange(h_iCollisionType, UpdateCvars);
	
	h_flCooldown = CreateConVar("sm_engieshop_cooldown", "0.2", "Cooldown Time for Most Menu-Based Functions (Fractions of a second)\n(Default: 0.2)", FCVAR_PLUGIN, true, 0.1, false);
	g_flCooldown = GetConVarFloat(h_flCooldown);
	HookConVarChange(h_flCooldown, UpdateCvars);
	
	h_strColorConfig = CreateConVar("sm_engieshop_color_file", "engieshop_colors", "Config (.cfg) File used for Building Colors (Relative to Sourcemod/Configs Directory)\n(Default: engieshop_colors)", FCVAR_PLUGIN);	
	char strConfig[PLATFORM_MAX_PATH+13], cvarBuffer[PLATFORM_MAX_PATH];
	GetConVarString(h_strColorConfig, cvarBuffer, sizeof(cvarBuffer));
	Format(strConfig, sizeof(strConfig), "configs/%s.cfg", cvarBuffer);
	BuildPath(Path_SM, g_strColorConfig, sizeof(g_strColorConfig), strConfig);
	HookConVarChange(h_strColorConfig, UpdateCvars);
	
	h_bUpdate = CreateConVar("sm_engieshop_autoupdate", "1", "Update this Plugin Automatically (Requires Updater)\n(Default: 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bUpdate = GetConVarBool(h_bUpdate);
	HookConVarChange(h_bUpdate, UpdateCvars);
	
	h_iDamageUpscaleMode = CreateConVar("sm_engieshop_damage_upscale", "0", "Default mode for Up-Scaling Damage on Resized Sentries (Default: 0)\n 0 - No Up-Scaling.\n 1 - Damage Up-Scales for Admins.\n 2 - Damage Up-Scales for Non-Admins.\n 3 - Damage Up-Scales for All Players.",
	FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_iDamageUpscaleMode = GetConVarInt(h_iDamageUpscaleMode);
	HookConVarChange(h_iDamageUpscaleMode, UpdateCvars);
	
	h_iDamageDownscaleMode = CreateConVar("sm_engieshop_damage_downscale", "3", "Default mode for Down-Scaling Damage on Resized Sentries (Default: 3)\n 0 - No Down-Scaling.\n 1 - Damage Down-Scales for Admins.\n 2 - Damage Down-Scales for Non-Admins.\n 3 - Damage Down-Scales for All Players.",
	FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_iDamageDownscaleMode = GetConVarInt(h_iDamageDownscaleMode);
	HookConVarChange(h_iDamageDownscaleMode, UpdateCvars);
	
	HookEvent("player_builtobject", Event_BuiltObject);
	HookEvent("object_destroyed", Event_DestroyedObject, EventHookMode_Pre);
	HookEvent("object_detonated", Event_RemoveOrDetonate, EventHookMode_Pre);
	HookEvent("object_removed", Event_RemoveOrDetonate, EventHookMode_Pre);
	HookEvent("player_sapped_object", Event_Sapped);
	AddNormalSoundHook(view_as<NormalSHook>(Hook_NormalSound)); // Yes, seriously.

	RegAdminCmd("sm_engieshop", Cmd_EngieWorkshop, ADMFLAG_GENERIC, "Modify your Buildings");
	RegAdminCmd("sm_rb", Cmd_ResizeBuilding, ADMFLAG_GENERIC, "Resize Your Buildings");
	RegAdminCmd("sm_friendlysentry", Cmd_FriendlySentry, ADMFLAG_GENERIC, "Toggle Friendly Sentry Mode");
	RegAdminCmd("sm_buildingoutline", Cmd_BuildingOutline, ADMFLAG_GENERIC, "Add Outline to Your Buildings");
	RegAdminCmd("sm_engieshop_reload", Cmd_ReloadConfig, ADMFLAG_ROOT, "Reload Engineer's Workshop Color Config");
	
	
	/*** Set Initial Values for Global Variables ***/
	for(int x = 0; x < 4; x++)
	{
		for(int y = 0; y < MAXPLAYERS; y++)
		{
			g_flBuildingScale[x][y] = 1.0;
			g_iBuildingIndex[x][y] = 0;
			g_fbBuildingInfo[x][y] = 0;
			g_iBuildingColor[x][y] = BCOLOR_DEFAULT;
		}
	}
	
	if(g_bLateLoad)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	LoadColorsConfig();
	return;
}



/*********************************************************************************************

	E V E N T S / F O R W A R D S
 
*********************************************************************************************/


public void UpdateCvars(Handle cvar, const char[] oldValue, const char[] newValue)
{
	#if defined _DEBUGMODE
	PrintToChatAll("ESHOP DEBUG: UpdateCvars()");
	#endif
	
	if(cvar == h_bCvarEnabled)
		g_bCvarEnabled = view_as<bool>(StringToInt(newValue));
	else if(cvar == h_flScaleLimits)
	{
		char boundExplode[EScaleBounds][16];
		if(ExplodeString(newValue, ";", boundExplode, sizeof(boundExplode), sizeof(boundExplode[])) != 2)
			return;
		g_flScaleLimits[Bounds_Lower] = StringToFloat(boundExplode[Bounds_Lower]);
		g_flScaleLimits[Bounds_Upper] = StringToFloat(boundExplode[Bounds_Upper]);
	}
	else if(cvar == h_iCollisionType)
		g_iCollisionType = StringToInt(newValue);
	else if(cvar == h_flCooldown)
		g_flCooldown = StringToFloat(newValue);
	else if(cvar == h_strColorConfig)
	{
		char strConfig[PLATFORM_MAX_PATH+13], cvarBuffer[PLATFORM_MAX_PATH];
		GetConVarString(h_strColorConfig, cvarBuffer, sizeof(cvarBuffer));
		Format(strConfig, sizeof(strConfig), "configs/%s.cfg", cvarBuffer);
		BuildPath(Path_SM, g_strColorConfig, sizeof(g_strColorConfig), strConfig);
		LoadColorsConfig();
	}
	else if(cvar == h_bUpdate)
	{
		g_bUpdate = GetConVarBool(h_bUpdate);
		(g_bUpdate) ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
	}
	else if(cvar == h_iDamageUpscaleMode)
		g_iDamageUpscaleMode = StringToInt(newValue);
	else if(cvar == h_iDamageDownscaleMode)
		g_iDamageDownscaleMode = StringToInt(newValue);
	return;
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_TF2)
	{
		Format(error, err_max, "%T", "EngieShop_Compatibility", LANG_SERVER);
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnConfigsExecuted()
{
	if(LibraryExists("updater") && g_bUpdate)
		Updater_AddPlugin(UPDATE_URL);
	return;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "updater") && g_bUpdate)
		Updater_AddPlugin(UPDATE_URL);
	return;
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "updater"))
		Updater_RemovePlugin();
	return;
}


public void OnClientPutInServer(int client)
{
	if(!IsClientReplay(client) && !IsClientSourceTV(client))
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	return;
}

public void OnClientDisconnect_Post(int client)
{
	for(int i = 0; i < 4; i++)
	{
		g_flBuildingScale[i][client] = 1.0;
		g_iBuildingIndex[i][client] = 0;
		g_fbBuildingInfo[i][client] = 0;
		g_iBuildingColor[i][client] = BCOLOR_DEFAULT;
	}
	g_flLastCommand[client] = 0.0;
	return;
}

public Action Event_BuiltObject(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bCvarEnabled)
		return Plugin_Continue;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int buildingIdx = GetEventInt(event, "index"); 
	
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: Event_BuiltObject()");
	#endif
	
	/*** Check Type. Do pre-build logic ***/
	EBuildingTypes type = GetBuildingType(buildingIdx);
	switch(type)
	{
		case Building_Invalid:
			return Plugin_Continue;
		case Building_Sentry:
		{
			if(PlayerHasGunslinger(client))
				g_fbBuildingInfo[type][client] |= FLG_ISMINISENTRY;
			else
			{
				// If player builds a 'minisentry', but doesnt have gunslinger, reset stats to default.  //DEBUG: This doesnt work as intended. Sentry is still wrong size.
				if(g_fbBuildingInfo[type][client] & FLG_ISMINISENTRY != 0)
				{	
					g_fbBuildingInfo[type][client] &= ~FLG_ISMINISENTRY; //disable minisentry flag
					g_fbBuildingInfo[type][client] &= ~FLG_ISRESIZED; //remove the non-default size flag
					g_flBuildingScale[type][client] = 1.0;	//Set building to default.
				}	
			}
		}
	}
	
	/*** Set Flags ***/
	g_iBuildingIndex[type][client] = buildingIdx;
	g_fbBuildingInfo[type][client] |= FLG_ACTIVE;
	
	/*** To ensure friendly sentries cannot damage buildings ***/
	if(IsValidEntity(buildingIdx))
		SDKHook(buildingIdx, SDKHook_OnTakeDamage, OnTakeDamage);
	
	/*** Begin Per-Setting Functions ***/
	if(g_fbBuildingInfo[type][client] & FLG_ISRESIZED != 0)
		ScaleActiveBuilding(client, g_flBuildingScale[type][client], type, false);
		
	if(g_fbBuildingInfo[type][client] & FLG_OUTLINE != 0)
		ApplyBuildingOutline(client, type, true);
		
	if(g_fbBuildingInfo[type][client] & FLG_FRIENDLY != 0)
		ApplyFriendlySentry(client, true);
		
	if(g_fbBuildingInfo[type][client] & FLG_INFINITE != 0)
		ApplyInfiniteAmmo(client, true);
		
	if(g_fbBuildingInfo[type][client] & FLG_INVULN != 0)
		ApplyGodmode(client, true, type);
		
	if(g_iBuildingColor[type][client] != BCOLOR_DEFAULT)
		SetBuildingColorByInt(client, type);
	
	return Plugin_Continue;
}


public Action Event_DestroyedObject(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bCvarEnabled)
		return Plugin_Continue;
		
	/*** No client index, so find m_hOwner on the building ***/
	int buildingIdx = GetEventInt(event, "index");
	int client = GetClientOfUserId(GetEventInt(event, "userid")); //GetEntPropEnt(buildingIdx, Prop_Send, "m_hOwnerEntity");
	int objectType = GetEventInt(event, "objecttype");
	/*** Since stuff will break if we dont disable properly, do NOT check for client validity ***/
	
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: Event_DestroyedObject()");
	#endif
	
	switch(objectType)
	{
		//Dispenser
		case 0:
			g_fbBuildingInfo[Building_Dispenser][client] &= ~FLG_ACTIVE;
		//Sentry
		case 2:
			g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_ACTIVE;
		//Teleport Entrance AND Exit
		case 1:
		{
			TFObjectMode mode = TF2_GetObjectMode(buildingIdx);
			if(mode == TFObjectMode_Entrance)
				g_fbBuildingInfo[Building_Entry][client] &= ~FLG_ACTIVE;
			else if(mode == TFObjectMode_Exit)
				g_fbBuildingInfo[Building_Exit][client] &= ~FLG_ACTIVE;
		}
	}
	if(IsValidEntity(buildingIdx))
		SDKUnhook(buildingIdx, SDKHook_OnTakeDamage, OnTakeDamage);
	return Plugin_Continue;
}

public Action Event_RemoveOrDetonate(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bCvarEnabled)
		return Plugin_Continue;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int buildingIdx = GetEventInt(event, "index");
	int objectType = GetEventInt(event, "objecttype");
	
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: Event_RemoveOrDetonate()");
	#endif

	switch(objectType)
	{
		//Dispenser
		case 0:
			g_fbBuildingInfo[Building_Dispenser][client] &= ~FLG_ACTIVE;
		//Sentry
		case 2:
			g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_ACTIVE;
		//Teleport Entrance AND Exit
		case 1:
		{
			TFObjectMode mode = TF2_GetObjectMode(buildingIdx);
			if(mode == TFObjectMode_Entrance)
				g_fbBuildingInfo[Building_Entry][client] &= ~FLG_ACTIVE;
			else if(mode == TFObjectMode_Exit)
				g_fbBuildingInfo[Building_Exit][client] &= ~FLG_ACTIVE;
				
			#if defined _DEBUGMODE
			PrintToChat(client, "ESHOP DEBUG: Event_RemoveOrDetonate(): TF2_GetObjectMode: %i", view_as<int>(mode));
			#endif
		}
	}
	if(IsValidEntity(buildingIdx))
		SDKUnhook(buildingIdx, SDKHook_OnTakeDamage, OnTakeDamage);
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!g_bCvarEnabled || !IsValidEntity(inflictor))
		return Plugin_Continue;

	char classnameStr[32];
	GetEdictClassname(inflictor, classnameStr, sizeof(classnameStr));
	if(StrEqual(classnameStr, "obj_sentrygun", true) || StrEqual(classnameStr, "tf_projectile_sentryrocket"))
	{
		if(g_fbBuildingInfo[Building_Sentry][attacker] & FLG_FRIENDLY != 0)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		if(g_fbBuildingInfo[Building_Sentry][attacker] & (FLG_ISRESIZED|FLG_SCALEDMG) == FLG_ISRESIZED|FLG_SCALEDMG)
		{
			#if defined _DEBUGMODE
			PrintToChat(attacker, "ESHOP DEBUG: FLG_ISRESIZED: %i, FLG_SCALEDMG: %i", g_fbBuildingInfo[Building_Sentry][attacker] & FLG_ISRESIZED, g_fbBuildingInfo[Building_Sentry][attacker] & FLG_SCALEDMG);
			#endif
			damage *= g_flBuildingScale[Building_Sentry][attacker];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void Event_Sapped(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	int sapper = GetEventInt(event, "sapperid");

	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_NOSAP != 0) // This IS valid. If no-sap is applied, it applies ONLY to sentry. This is to skip building types.
		AcceptEntityInput(sapper, "Kill");
	return;
}

/*** All credit to tylerst and his plugin Building Godmode for this ***/
public Action Hook_NormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(StrEqual(sample, "weapons/sapper_timer.wav", false) || (StrContains(sample, "spy_tape_", false) != -1))
	{
		if(!IsValidEntity(GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity")))
			return Plugin_Stop;
	}
	return Plugin_Continue;
}



/*********************************************************************************************

	C O M M A N D S
 
*********************************************************************************************/


public Action Cmd_EngieWorkshop(int client, int args)
{
	CheckCommand(client);
	Menu_Main(client);
	return Plugin_Handled;
}

public Action Cmd_ResizeBuilding(int client, int args)
{
	CheckCommand(client);
	Menu_Resize(client);
	return Plugin_Handled;
}

public Action Cmd_FriendlySentry(int client, int args)
{
	CheckCommand(client);
	ToggleFriendlySentry(client);
	return Plugin_Handled;
}

public Action Cmd_BuildingOutline(int client, int args)
{
	CheckCommand(client);
	Menu_Outline(client);
	return Plugin_Handled;
}

public Action Cmd_ReloadConfig(int client, int args)
{
	LoadColorsConfig();
	PrintToChat(client, "%s %T", TAG_CON, "EngieShop_ConfigReload", client);
	return Plugin_Handled;
}

void CheckCommand(int client)
{
	if(!g_bCvarEnabled)
	{
		ReplyToCommand(client, "%s %T", TAG_SM, "EngieShop_CvarDisabled", client);
		return;
	}
	if(client == 0)
	{
		ReplyToCommand(client, "%s %T", TAG_CON, "EngieShop_GameOnly", client);
		return;
	}
	return;
}



/*********************************************************************************************

	M E N U   S T U F F
 
*********************************************************************************************/


/******************
	Main Menu
******************/

void Menu_Main(int client)
{
	Handle hMenu = CreateMenu(MainHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_MainMenuTitle", LANG_SERVER); //Translation is handled in the MenuHandler.
	
	AddMenuItem(hMenu, CHOICE1, "Resize Buildings");
	AddMenuItem(hMenu, CHOICE2, "Toggle Friendly Sentry");
	AddMenuItem(hMenu, CHOICE3, "Outlines");
	AddMenuItem(hMenu, CHOICE4, "Color Buildings");
	AddMenuItem(hMenu, CHOICE5, "Abilities");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public int MainHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			/*** Disable options the client doesn't have access to ***/
			int style;
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info), style);
 
			if(StrEqual(info, CHOICE1) && !CleanAccessCheck(param1, Item_Resize))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE2) && !CleanAccessCheck(param1, Item_Friendly)) 
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE3) && !CleanAccessCheck(param1, Item_Outline))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE4) && !CleanAccessCheck(param1, Item_Color))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE5) && !CleanAccessCheck(param1, Item_Abilties))
				return ITEMDRAW_DISABLED;
			else return style;
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_MainMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			char display[64];
 
			/*** Translate each item. Returns cant be moved. ***/
			if(StrEqual(info, CHOICE1))
			{
				Format(display, sizeof(display), "%T", "EngieShop_MainChoice1", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_FRIENDLY != 0)
					Format(display, sizeof(display), "%T", "EngieShop_MainChoice2_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_MainChoice2_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				Format(display, sizeof(display), "%T", "EngieShop_MainChoice3", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				Format(display, sizeof(display), "%T", "EngieShop_MainChoice4", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE5))
			{
				Format(display, sizeof(display), "%T", "EngieShop_MainChoice5", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			/*** Prevent Menu-switch spam for outline, abilities and resize ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_Main(param1);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
			
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if(StrEqual(info, CHOICE1))
				Menu_Resize(param1);
			else if(StrEqual(info, CHOICE2))
			{
				ToggleFriendlySentry(param1);
				Menu_Main(param1);
			}
			else if(StrEqual(info, CHOICE3))
				Menu_Outline(param1);
			else if(StrEqual(info, CHOICE4))
				Menu_ColorBuilding(param1);
			else if(StrEqual(info, CHOICE5))
				Menu_Abilities(param1);
				
			#if defined _DEBUGMODE
			PrintToChat(param1, "ESHOP DEBUG: MenuAction_Select(Main): %s", info);
			#endif
		}
	}
	return 0;
}



/******************
	Resize Menu
******************/

void Menu_Resize(int client)
{
	Handle hMenu = CreateMenu(ResizeHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_ResizeMenuTitle", LANG_SERVER); //Translation is handled in the MenuHandler.
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, CHOICE1, "All");
	AddMenuItem(hMenu, CHOICE2, "Sentry");
	AddMenuItem(hMenu, CHOICE3, "Dispenser");
	AddMenuItem(hMenu, CHOICE4, "Entry Teleporter");
	AddMenuItem(hMenu, CHOICE5, "Exit Teleporter");
	AddMenuItem(hMenu, CHOICE6, "Reset All Buildings");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public int ResizeHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Main(param1);
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_ResizeMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			char display[64];
 
			/*** Translate each item. Returns cant be moved. ***/
			//Note: Could use StringToInt and then a switch here...
			if(StrEqual(info, CHOICE1))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice1", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice2", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice3", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice4", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE5))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice5", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE6))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice6", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			/*** Prevent Menu-Switch spam ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_Resize(param1);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
			
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			#if defined _DEBUGMODE
			PrintToChat(param1, "ESHOP DEBUG: MenuAction_Select(Resize): %s", info);
			#endif
			
			if(!StrEqual(info, CHOICE6))
				Menu_ResizeScale(param1, info);
			else
			{
				SetAllBuildingScale(param1, 1.0);
				Menu_Resize(param1);
			}
		}
	}
	return 0;
}


/*** 
 * Menu containing all sizes you can use for a building.
 ***/
void Menu_ResizeScale(int client, char[] strChoice)
{
	
	Handle hMenu = CreateMenu(ScaleHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem|MenuAction_Display);
	SetMenuTitle(hMenu, "%T", "EngieShop_ScaleMenuTitle", LANG_SERVER); //Translation is handled in the MenuHandler.
	SetMenuExitBackButton(hMenu, true);
	
	
	/*** itemNum adds an offset in steps of 100 to distinguish between building choices in the handler ***/
	char itemStr[8], valueStr[8];
	int itemValue = 25;
	int itemNum;
	
	if(StrEqual(strChoice, CHOICE1))
		itemNum = 0;
	else if(StrEqual(strChoice, CHOICE2))
		itemNum = 100;
	else if(StrEqual(strChoice, CHOICE3))
		itemNum = 200;
	else if(StrEqual(strChoice, CHOICE4))
		itemNum = 300;
	else if(StrEqual(strChoice, CHOICE5))
		itemNum = 400;
		
	char defaultStr[16];
	Format(defaultStr, sizeof(defaultStr), "%T", "EngieShop_Default", client);
	
	for(int i = 0; i < MENU_SCALEITEMS; i++)
	{
		IntToString(itemNum, itemStr, sizeof(itemStr));
		Format(valueStr, sizeof(valueStr), "%i%", itemValue); //Warning: The last % breaks ITEMDRAW_DISABLED if removed.
		if(i == 3)
			AddMenuItem(hMenu, itemStr, defaultStr);
		else
			AddMenuItem(hMenu, itemStr, valueStr);
		itemNum++;
		itemValue += 25;
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}


public int ScaleHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Resize(param1);
		}
		
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_ScaleMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		/*
		 * IMPORTANT: No Translation system for scale values
		case MenuAction_DisplayItem:
		{
		}
		*/
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[4], displayBuff[8];
			GetMenuItem(menu, param2, info, sizeof(info), style, displayBuff, sizeof(displayBuff));
			
			/*** This will always fail on the "Default" setting. Return is needed here to prevent errors further on ***/
			if(ReplaceString(displayBuff, sizeof(displayBuff), "%", "") != 1)
				return style;
			
			if(CleanAccessCheck(param1, Item_Resize_Admin))
				return style;
			
			/*** Scale item is currently integer (150% -> 150). ***/
			float sizeBuff = FloatDiv(StringToFloat(displayBuff), 100.0);
			if(FloatCompare(g_flScaleLimits[Bounds_Lower], sizeBuff) == 1 || FloatCompare(g_flScaleLimits[Bounds_Upper], sizeBuff) == -1)
				return ITEMDRAW_IGNORE; //ITEMDRAW_IGNORE prevents the item from being displayed.
				
			else 
				return style;
		}
		
		case MenuAction_Select:
		{
			char info[4], display[8];
			int style; //Dummy value for GetMenuItem
			GetMenuItem(menu, param2, info, sizeof(info), style, display, sizeof(display));
			
			/*** Function does a lot -- add cooldown check ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_ResizeScale(param1, info);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
		
			char defaultStr[16];
			Format(defaultStr, sizeof(defaultStr), "%T", "EngieShop_Default", param1);
			
			float setScale;
			if(ReplaceString(display, sizeof(display), "%", "") != 1 && !StrEqual(display, defaultStr))
				return 0;
			else if(StrEqual(display, defaultStr))
				setScale = 1.0;
			else
				setScale = FloatDiv(StringToFloat(display), 100.0);
				
			EBuildingTypes buildingType;
			char buildingName[32];
			switch(StringToInt(info)/100)
			{
				case 0:
				{
					/*** buildingType == Building_All ***/
					SetAllBuildingScale(param1, setScale);
					return 0;
				}
				case 1:
				{
					buildingType = Building_Sentry;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice2", param1);
				}
				case 2:
				{
					buildingType = Building_Dispenser;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice3", param1);
				}
				case 3:
				{
					buildingType = Building_Entry;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice4", param1);
				}
				case 4:
				{
					buildingType = Building_Exit;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice5", param1);
				}
				default:
					return 0;
			}
			SetBuildingScale(param1, setScale, buildingType);
			PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_ResizedBuilding", param1, buildingName, setScale);
			
			#if defined _DEBUGMODE
			PrintToChat(param1, "ESHOP DEBUG: MenuAction_Select(Scale): %s, %s, %.2f", info, buildingName, setScale);
			#endif
			
			Menu_Resize(param1);
		}
	}
	return 0;
}


/******************
	Outline Menu
******************/


void Menu_Outline(int client)
{
	Handle hMenu = CreateMenu(OutlineHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_OutlineMenuTitle", LANG_SERVER);
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, CHOICE1, "Enable All");
	AddMenuItem(hMenu, CHOICE2, "Disable All");
	AddMenuItem(hMenu, CHOICE3, "Toggle Sentry");
	AddMenuItem(hMenu, CHOICE4, "Toggle Dispenser");
	AddMenuItem(hMenu, CHOICE5, "Toggle Entry Teleporter");
	AddMenuItem(hMenu, CHOICE6, "Toggle Exit Teleporter");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public int OutlineHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Main(param1);
		}
		
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_OutlineMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			char display[64];
 
			/*** Translate each item. Returns cant be moved. ***/
			//Note: Could use StringToInt and then a switch here...
			if(StrEqual(info, CHOICE1))
			{
				Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice1", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice2", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_OUTLINE != 0)
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice3_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice3_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				if(g_fbBuildingInfo[Building_Dispenser][param1] & FLG_OUTLINE != 0)
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice4_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice4_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE5))
			{
				if(g_fbBuildingInfo[Building_Entry][param1] & FLG_OUTLINE != 0)
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice5_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice5_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE6))
			{
				if(g_fbBuildingInfo[Building_Exit][param1] & FLG_OUTLINE != 0)
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice6_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_OutlineChoice6_E", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			if(StrEqual(info, CHOICE1))
				SetAllOutlines(param1, true);
			else if(StrEqual(info, CHOICE2))
				SetAllOutlines(param1, false);
			else
			{
				char buildingName[32];
				EBuildingTypes bType;
				if(StrEqual(info, CHOICE3))
				{
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice2", param1); //IMPORTANT: This is intentional.
					bType = Building_Sentry;
				}
				else if(StrEqual(info, CHOICE4))
				{
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice3", param1);
					bType = Building_Dispenser;
				}
				else if(StrEqual(info, CHOICE5))
				{
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice4", param1);
					bType = Building_Entry;
				}
				else if(StrEqual(info, CHOICE6))
				{
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice5", param1);
					bType = Building_Exit;
				}
					
				ToggleBuildingOutline(param1, bType);
				PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_OutlineBuilding", param1, buildingName);
				
				#if defined _DEBUGMODE
				PrintToChat(param1, "ESHOP DEBUG: MenuAction_Select(Outline): %s, %s", info, buildingName);
				#endif
			}
			Menu_Outline(param1);
		}
	}
	return 0;
}



/*********************
	Abilities Menu
*********************/


void Menu_Abilities(int client)
{
	Handle hMenu = CreateMenu(AbilitiesHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_AbilitiesMenuTitle", LANG_SERVER);
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, CHOICE1, "Toggle Infinite Ammo");
	AddMenuItem(hMenu, CHOICE2, "Toggle No-Sap");
	AddMenuItem(hMenu, CHOICE3, "Toggle Godmode");
	AddMenuItem(hMenu, CHOICE4, "Toggle Damage Scaling");
	AddMenuItem(hMenu, CHOICE5, "Teleport to Crosshair");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public int AbilitiesHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Main(param1);
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info), style);
			
			if(StrEqual(info, CHOICE1) && !CleanAccessCheck(param1, Item_Abilities_Ammo))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE2) && !CleanAccessCheck(param1, Item_Abilities_NoSap)) 
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE3) && !CleanAccessCheck(param1, Item_Abilities_God))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE4) && !CleanAccessCheck(param1, Item_Abilities_DmgToggle))
				return ITEMDRAW_DISABLED;
			else if(StrEqual(info, CHOICE5) && !CleanAccessCheck(param1, Item_Abilities_Tele))
				return ITEMDRAW_DISABLED;
			else return style;
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_AbilitiesMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4], display[64];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			if(StrEqual(info, CHOICE1))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_INFINITE != 0)
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice1_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice1_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_NOSAP != 0)
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice2_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice2_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_INVULN != 0)
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice3_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice3_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				if(g_fbBuildingInfo[Building_Sentry][param1] & FLG_SCALEDMG != 0)
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice4_D", param1);
				else
					Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice4_E", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE5))
			{
				Format(display, sizeof(display), "%T", "EngieShop_AbilitiesChoice5", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			if(StrEqual(info, CHOICE1))
				ToggleInfiniteAmmo(param1);
			else if(StrEqual(info, CHOICE2))
				ToggleNoSap(param1);
			else if(StrEqual(info, CHOICE3))
				ToggleGodmode(param1);
			else if(StrEqual(info, CHOICE4))
				ToggleDamageScaling(param1);
			else if(StrEqual(info, CHOICE5))
			{
				Menu_Teleport(param1);
				return 0;
			}
			Menu_Abilities(param1);
		}
	}
	return 0;
}



/*********************
	Teleport Menu
*********************/


void Menu_Teleport(int client)
{
	Handle hMenu = CreateMenu(TeleportHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_TeleportMenuTitle", LANG_SERVER);
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, CHOICE1, "Sentry");
	AddMenuItem(hMenu, CHOICE2, "Dispenser");
	AddMenuItem(hMenu, CHOICE3, "Entry Teleporter");
	AddMenuItem(hMenu, CHOICE4, "Exit Teleporter");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}


public int TeleportHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Abilities(param1);
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_TeleportMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4], display[64];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			if(StrEqual(info, CHOICE1))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice2", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice3", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice4", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice5", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			/*** Function does a lot -- add cooldown check ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_Teleport(param1);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
			
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));

			EBuildingTypes bType;
			char buildingName[32];
			if(StrEqual(info, CHOICE1))
			{
				Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice2", param1); //IMPORTANT: This is intentional.
				bType = Building_Sentry;
			}
			else if(StrEqual(info, CHOICE2))
			{
				Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice3", param1);
				bType = Building_Dispenser;
			}
			else if(StrEqual(info, CHOICE3))
			{
				Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice4", param1);
				bType = Building_Entry;
			}
			else if(StrEqual(info, CHOICE4))
			{
				Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice5", param1);
				bType = Building_Exit;
			}
			else
				return 0;
		
				
			if(!TeleportBuilding(param1, bType))
				PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_NoTeleport", param1);
			else
				PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_TeleportSuccess", param1, buildingName);

			Menu_Teleport(param1);
		}
	}
	return 0;
}



/***************************
	Color Buildings Menu
***************************/

void Menu_ColorBuilding(int client)
{
	Handle hMenu = CreateMenu(ColorBuildingHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_Display|MenuAction_DisplayItem);
	SetMenuTitle(hMenu, "%T", "EngieShop_ColorBuildMenuTitle", LANG_SERVER);
	SetMenuExitBackButton(hMenu, true);
	
	AddMenuItem(hMenu, CHOICE1, "All");
	AddMenuItem(hMenu, CHOICE2, "Sentry");
	AddMenuItem(hMenu, CHOICE3, "Dispenser");
	AddMenuItem(hMenu, CHOICE4, "Entry Teleporter");
	AddMenuItem(hMenu, CHOICE5, "Exit Teleporter");
	AddMenuItem(hMenu, CHOICE6, "Reset All Buildings");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}


public int ColorBuildingHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_Main(param1);
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_ColorBuildMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[4], display[64];
			GetMenuItem(menu, param2, info, sizeof(info));
 
			if(StrEqual(info, CHOICE1))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice1", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE2))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice2", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE3))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice3", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE4))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice4", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE5))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice5", param1);
				return RedrawMenuItem(display);
			}
			else if(StrEqual(info, CHOICE6))
			{
				Format(display, sizeof(display), "%T", "EngieShop_ResizeChoice6", param1);
				return RedrawMenuItem(display);
			}
		}
		
		case MenuAction_Select:
		{
			/*** Function does a lot -- add cooldown check ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_ColorBuilding(param1);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
			
			char info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if(!StrEqual(info, CHOICE6))
				Menu_SetColor(param1, info);
			else
			{
				int vecColor[3] = {255, 255, 255};
				char defaultStr[16];
				Format(defaultStr, sizeof(defaultStr), "%T", "EngieShop_Default", param1);
				SetAllBuildingColor(param1, vecColor, defaultStr);
				Menu_ColorBuilding(param1);
			}
		}
	}
	return 0;
}


/*********************
	Color Menu
*********************/

void Menu_SetColor(int client, char[] strChoice)
{
	Handle hMenu = CreateMenu(SetColorHandler, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_Display);
	SetMenuTitle(hMenu, "%T", "EngieShop_SetColorMenuTitle", LANG_SERVER);
	SetMenuExitBackButton(hMenu, true);
	
	char itemStr[8];
	int itemNum;	
	if(StrEqual(strChoice, CHOICE1))
		itemNum = 0;
	else if(StrEqual(strChoice, CHOICE2))
		itemNum = 100;
	else if(StrEqual(strChoice, CHOICE3))
		itemNum = 200;
	else if(StrEqual(strChoice, CHOICE4))
		itemNum = 300;
	else if(StrEqual(strChoice, CHOICE5))
		itemNum = 400;
	
	/*** Add items ***/
	char defaultStr[16];
	Format(defaultStr, sizeof(defaultStr), "%T", "EngieShop_Default", client);
	IntToString(itemNum+BCOLOR_DEFAULT, itemStr, sizeof(itemStr)); //itemNum = building Type, BCOLOR_DEFAULT = 99 = color selected.
	AddMenuItem(hMenu, itemStr, defaultStr);
	
	for(int i = 0; i < g_iColorCount; i++)
	{
		IntToString(itemNum, itemStr, sizeof(itemStr));
		AddMenuItem(hMenu, itemStr, g_ColorNames[i]);
		itemNum++;
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return;
}

public int SetColorHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Menu_ColorBuilding(param1);
		}
		
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "EngieShop_SetColorMenuTitle", param1);
 
			Handle panel = view_as<Handle>(param2);
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_Select:
		{
			char info[4], display[16];
			int style; //Dummy value
			GetMenuItem(menu, param2, info, sizeof(info), style, display, sizeof(display));
			
			/*** Function does a lot -- add cooldown check ***/
			if(IsClientOnCooldown(param1))
			{
				Menu_SetColor(param1, info);
				return 0;
			}
			g_flLastCommand[param1] = GetGameTime();
			
			EBuildingTypes buildingType;
			char buildingName[32];
			int vecColor[3];
			int iSelection = StringToInt(info);
			bool result = false;
			
			#if defined _DEBUGMODE
			PrintToChatAll("ESHOP DEBUG: selection/100=%i", iSelection/100);
			#endif
			
			switch(iSelection/100)
			{
				case 0:
				{
					/*** buildingType == Building_All ***/
					char defaultStr[16];
					Format(defaultStr, sizeof(defaultStr), "%T", "EngieShop_Default", param1);
					
					if(GetColorVec(iSelection, vecColor[0], vecColor[1], vecColor[2]))
						SetAllBuildingColor(param1, vecColor, (iSelection != 99) ? g_ColorNames[iSelection] : defaultStr, iSelection); //Handles chat message
					Menu_ColorBuilding(param1);
					return 0;
				}
				case 1:
				{
					buildingType = Building_Sentry;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice2", param1);
					iSelection -= 100;
					if(GetColorVec(iSelection, vecColor[0], vecColor[1], vecColor[2]))
						result = true;
				}
				case 2:
				{
					buildingType = Building_Dispenser;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice3", param1);
					iSelection -= 200;
					if(GetColorVec(iSelection, vecColor[0], vecColor[1], vecColor[2]))
						result = true;
				}
				case 3:
				{
					buildingType = Building_Entry;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice4", param1);
					iSelection -= 300;
					if(GetColorVec(iSelection, vecColor[0], vecColor[1], vecColor[2]))
						result = true;
				}
				case 4:
				{
					buildingType = Building_Exit;
					Format(buildingName, sizeof(buildingName), "%T", "EngieShop_ResizeChoice5", param1);
					iSelection -= 400;
					if(GetColorVec(iSelection, vecColor[0], vecColor[1], vecColor[2]))
						result = true;
				}
				default:
					return 0;
			}
			if(result)
			{
				SetBuildingColor(param1, buildingType, vecColor, iSelection);
				PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_ColorSet", param1, buildingName, display);
				Menu_ColorBuilding(param1);
			}
			else
				PrintToChat(param1, "%s %T", TAG_SM, "EngieShop_ColorInvalid", param1, display);
		}
	}
	return 0;
}



/************************************************

	C O R E   F U N C T I O N S
 
************************************************/


/*** 
 * Sets Scale for All Buildings
 ***/
void SetAllBuildingScale(int client, float scale)
{
	SetBuildingScale(client, scale, Building_Sentry);
	SetBuildingScale(client, scale, Building_Dispenser);
	SetBuildingScale(client, scale, Building_Entry);
	SetBuildingScale(client, scale, Building_Exit);
	
	char allBuilds[32];
	Format(allBuilds, sizeof(allBuilds), "%T", "EngieShop_ResizedAll", client);
	PrintToChat(client, "%s %T", TAG_SM, "EngieShop_ResizedBuilding", client, allBuilds, scale);
	return;
}


/*** 
 * Set Scale of Client's Building
 * IMPORTANT: This handles both the entity's SetModelScale, and the global variable.
 * Additionally, the SetModelScale portion is the ONLY part of the whole code that handles Mini-sentries,
 * multiplying the "scale" float by 0.75 before applying it to the building. (But NOT the cvar)
 * This is important, because it allows the damage hook to properly control damage values,
 * scales the minisentry relative to its original size. AND gives us simpler code for resizing.
 * This also makes the "Default" (EngieShop_Default) value ACTUALLY the default minisentry size.
 ***/
void SetBuildingScale(int client, float scale, EBuildingTypes buildingType)
{
	/*** Set Building Info -- Does not require active building ***/
	float scaleBuff = scale;
	bool isDefault = false;
	g_flBuildingScale[buildingType][client] = scale;
	
	/*** If scale is >1.0, only allow damage scaling if they are admin. Else, allow damage scaling. ***/
	switch(FloatCompare(scale, 1.0))
	{
		case 1:
		{
			/*
			0 - No Up-scaling.
			1 - Damage Up-scales for Admins.
			2 - Damage Up-scales for Non-Admins.
			3 - Damage Up-scales for All Players.
			*/
			switch(g_iDamageUpscaleMode)
			{
				case 0:
					g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				case 1:
				{
					if(CleanAccessCheck(client, Item_DamageScale_Admin))
						g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
					else
						g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				}
				case 2:
				{
					if(!CleanAccessCheck(client, Item_DamageScale_Admin))
						g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
					else
						g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				}
				case 3:
					g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
			}
		}
		case -1:
		{
			switch(g_iDamageDownscaleMode)
			{
				case 0:
					g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				case 1:
				{
					if(CleanAccessCheck(client, Item_DamageScale_Admin))
						g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
					else
						g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				}
				case 2:
				{
					if(!CleanAccessCheck(client, Item_DamageScale_Admin))
						g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
					else
						g_fbBuildingInfo[buildingType][client] &= ~FLG_SCALEDMG;
				}
				case 3:
					g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
			}
		}
		default: //case -1 AND default
			g_fbBuildingInfo[buildingType][client] |= FLG_SCALEDMG;
	}
	
	/*** -------- The below will only apply to active buildings -------- ***/
	
	/*** If building is mini-sentry, multiply scale by 0.75 to scale it relative to sentry's original size. ***/
	if(buildingType == Building_Sentry)
	{
		if(g_fbBuildingInfo[buildingType][client] & FLG_ISMINISENTRY != 0)
		{
			scaleBuff = FloatMul(scale, MINI_DEFAULTSCALE);
			if(FloatCompare(scaleBuff, MINI_DEFAULTSCALE) == 0)
				isDefault = true;
			#if defined _DEBUGMODE
			PrintToChat(client, "ESHOP DEBUG: SetBuildingScale() FLG_ISMINISENTRY: scaleBuff:%f", scaleBuff);
			#endif
		}
	}
	if(FloatCompare(scaleBuff, 1.0) == 0)
		isDefault = true;
	
	
	if(!isDefault)
		g_fbBuildingInfo[buildingType][client] |= FLG_ISRESIZED;
	else
		g_fbBuildingInfo[buildingType][client] &= ~FLG_ISRESIZED;
	
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: SetBuildingScale() isDefault:%b, FLG_ISRESIZED: %b", isDefault, g_fbBuildingInfo[buildingType][client] & FLG_ISRESIZED);
	#endif
	
	/*** scaleBuff will either equal scale or scale * 0.75 here. It MUST be used for active buildings ONLY ***/
	
	if(g_fbBuildingInfo[buildingType][client] & FLG_ACTIVE != 0)
		ScaleActiveBuilding(client, scaleBuff, buildingType, isDefault);

	return;
}

/*** CORE FUNCTION -- Used by SetBuildingScale to scale ONLY active buildings ***/
stock void ScaleActiveBuilding(int client, float scale, EBuildingTypes buildingType, bool isDefault)
{
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: SetActiveBuilding() Pre");
	#endif

	/*** First, check building is valid edict. We can assume it is active due to the flag-check in the previous scope ***/
	int entIdx = g_iBuildingIndex[buildingType][client];
	if(entIdx < MaxClients || !IsValidEdict(entIdx))
		return;
		
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: SetActiveBuilding() Post: %.2f, %i, %b", scale, view_as<int>(buildingType), isDefault);
	#endif
	
	
	SetEntPropFloat(entIdx, Prop_Send, "m_flModelScale", scale);
	SetCollideBuilding(entIdx, buildingType, isDefault);
	//ScaleBuildingStats(entIdx, scale, buildingType); //IMPORTANT: Really experimental and does not (yet) function correctly.
	
	/*** Fix VGUI Panel on Dispensers -- Credit to pheadxdll ***/
	if(buildingType == Building_Dispenser)
	{
		int displayIdx = MaxClients+1;
		while((displayIdx = FindEntityByClassname(displayIdx, "vgui_screen")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntPropEnt(displayIdx, Prop_Send, "m_hOwnerEntity") == entIdx)
			{
				SetEntPropFloat(displayIdx, Prop_Send, "m_flWidth", FloatMul(g_flBuildingScale[buildingType][client], VGUI_WIDTH));
				SetEntPropFloat(displayIdx, Prop_Send, "m_flHeight", FloatMul(g_flBuildingScale[buildingType][client], VGUI_HEIGHT));
			}
		}
	}
	return;
}

/*** CORE FUNCTION -- Disabled Collisions on a Resized Building by setting invalid owner. ***/
stock void SetCollideBuilding(int index, EBuildingTypes bType, bool isDefault)
{
	if(g_iCollisionType == 0 || ((g_iCollisionType == 2) && (bType == Building_Entry || bType == Building_Exit)))
		return;
		
	/*** Based on building type, and isDefault, set appropriate collision type from enum. ***/
	EObjCollisions collisionType;
	
	switch(bType)
	{
		case Building_Sentry, Building_Dispenser:
			collisionType = ((isDefault) ? Coll_Default : Coll_Client);
		case Building_Entry, Building_Exit:
			collisionType = ((isDefault) ? Coll_Teleporter : Coll_Client);
		default:
			return;
	}
	
	#if defined _DEBUGMODE
	PrintToChatAll("ESHOP DEBUG: SetCollideBuilding(): index: %i, collisionType:%i", index, view_as<int>(collisionType));
	#endif
	
	SetEntProp(index, Prop_Send, "m_CollisionGroup", collisionType);
	return;
}

/*** EXPERIMENTAL CORE FUNCTION -- Sets Health and Ammo of a resized building ***/
stock void ScaleBuildingStats(int index, float scale, EBuildingTypes bType)
{
	float statBuff;
	int stat;
	
	stat = GetEntProp(index, Prop_Send, "m_iHealth");
	statBuff = FloatMul(view_as<float>(stat), scale);
	SetEntProp(index, Prop_Send, "m_iHealth", statBuff);
	
	stat = GetEntProp(index, Prop_Send, "m_iMaxHealth");
	statBuff = FloatMul(view_as<float>(stat), scale);
	SetEntProp(index, Prop_Send, "m_iMaxHealth", statBuff);
	
	switch(bType)
	{
		case Building_Sentry:
		{
			stat = GetEntProp(index, Prop_Send, "m_iAmmoShells");
			statBuff = FloatMul(view_as<float>(stat), scale);
			SetEntProp(index, Prop_Send, "m_iAmmoShells", statBuff);
			
			stat = GetEntProp(index, Prop_Send, "m_iAmmoRockets");
			statBuff = FloatMul(view_as<float>(stat), scale);
			SetEntProp(index, Prop_Send, "m_iAmmoRockets", statBuff);
		}
		case Building_Dispenser:
		{
			stat = GetEntProp(index, Prop_Send, "m_iAmmoMetal");
			statBuff = FloatMul(view_as<float>(stat), scale);
			SetEntProp(index, Prop_Send, "m_iAmmoMetal", statBuff);
		}
	}
	return;
}


/**************************
	Friendly Sentry Core
**************************/

void ToggleFriendlySentry(int client)
{
	bool state;
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_FRIENDLY != 0)
	{
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_FRIENDLY;
		state = false;
		ApplyFriendlySentry(client, false);
	}
	else
	{
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_FRIENDLY;
		state = true;
		ApplyFriendlySentry(client, true);
	}
	
	/*** Dont merge this into the ApplyFriendlySentry() function, since it's called during building ***/
	if(state)
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_FriendlySentryOn", client);
	else
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_FriendlySentryOff", client);
		
	return;
}

void ApplyFriendlySentry(int client, bool state)
{
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_ACTIVE == 0)
		return;
		
	int sentryIndex = g_iBuildingIndex[Building_Sentry][client];
	int flags = GetEntityFlags(sentryIndex);
	int vecColor[3];
	
	/*** I was told that FL_NOTARGET would prevent sentries auto-targeting too. Nope. Should Prevent being targeted by other sentries though ***/
	
	switch(state)
	{
		case true:
		{
			if(g_iBuildingColor[Building_Sentry][client] != BCOLOR_DEFAULT)
			{
				GetColorVec(g_iBuildingColor[Building_Sentry][client], vecColor[0], vecColor[1], vecColor[2]);
				flags |= FL_NOTARGET;
				SetEntityRenderMode(sentryIndex, RENDER_TRANSALPHA);
				SetEntityRenderColor(sentryIndex, vecColor[0], vecColor[1], vecColor[2], ALPHA_FRIENDLY);
			}
			else
			{
				flags |= FL_NOTARGET;
				SetEntityRenderMode(sentryIndex, RENDER_TRANSALPHA);
				SetEntityRenderColor(sentryIndex, _, _, _, ALPHA_FRIENDLY);
			}
		}
		case false:
		{
			if(g_iBuildingColor[Building_Sentry][client] != BCOLOR_DEFAULT)
			{
				GetColorVec(g_iBuildingColor[Building_Sentry][client], vecColor[0], vecColor[1], vecColor[2]);
				flags &= ~FL_NOTARGET;
				SetEntityRenderMode(sentryIndex, RENDER_NORMAL);
				SetEntityRenderColor(sentryIndex, vecColor[0], vecColor[1], vecColor[2], 255);
			}
			else
			{
				flags &= ~FL_NOTARGET;
				SetEntityRenderMode(sentryIndex, RENDER_NORMAL);
				SetEntityRenderColor(sentryIndex, _, _, _, 255);
			}
		}
	}

	SetEntityFlags(sentryIndex, flags);
	return;
}



/******************
	Outline Core
******************/
void SetAllOutlines(int client, bool setState)
{
	if(setState)
	{
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_OUTLINE;
		g_fbBuildingInfo[Building_Dispenser][client] |= FLG_OUTLINE;
		g_fbBuildingInfo[Building_Entry][client] |= FLG_OUTLINE;
		g_fbBuildingInfo[Building_Exit][client] |= FLG_OUTLINE;
		
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_EnabledAllOutline", client);
	}
	else
	{
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_OUTLINE;
		g_fbBuildingInfo[Building_Dispenser][client] &= ~FLG_OUTLINE;
		g_fbBuildingInfo[Building_Entry][client] &= ~FLG_OUTLINE;
		g_fbBuildingInfo[Building_Exit][client] &= ~FLG_OUTLINE;
		
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_DisabledAllOutline", client);
	}
	
	ApplyBuildingOutline(client, Building_Sentry, setState);
	ApplyBuildingOutline(client, Building_Dispenser, setState);
	ApplyBuildingOutline(client, Building_Entry, setState);
	ApplyBuildingOutline(client, Building_Exit, setState);
	
	return;
}

/*** IMPORTANT -- This is ONLY accessed via the outline menu ***/
void ToggleBuildingOutline(int client, EBuildingTypes bType)
{
	if(g_fbBuildingInfo[bType][client] & FLG_OUTLINE != 0)
		g_fbBuildingInfo[bType][client] &= ~FLG_OUTLINE;
	else
		g_fbBuildingInfo[bType][client] |= FLG_OUTLINE;

	/*** If Active ***/
	if(g_fbBuildingInfo[bType][client] & FLG_ACTIVE != 0)
		ApplyBuildingOutline(client, bType, (g_fbBuildingInfo[bType][client] & FLG_OUTLINE != 0) ? true : false);
	
	return;
}

void ApplyBuildingOutline(int client, EBuildingTypes bType, bool setState)
{
	if(g_fbBuildingInfo[bType][client] & FLG_ACTIVE != 0)
		SetEntProp(g_iBuildingIndex[bType][client], Prop_Send, "m_bGlowEnabled", setState);
	return;
}



/********************
	Abilities Core
********************/


void ToggleInfiniteAmmo(int client)
{
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_INFINITE != 0)
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_INFINITE;
	else
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_INFINITE;

	/*** If Active ***/
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_ACTIVE != 0)
		ApplyInfiniteAmmo(client, (g_fbBuildingInfo[Building_Sentry][client] & FLG_INFINITE != 0) ? true : false);
	return;
}

/*** Core Function -- Used by Event_BuiltObject and ToggleInfiniteAmmo() ***/
void ApplyInfiniteAmmo(int client, bool setState)
{
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_ACTIVE != 0)
	{
		#if defined _DEBUGMODE
		PrintToChat(client, "ESHOP DEBUG: INFINITE PASS ACTIVE");
		#endif
		
		int flags = GetEntProp(g_iBuildingIndex[Building_Sentry][client], Prop_Data, "m_spawnflags");
		
		#if defined _DEBUGMODE
		PrintToChat(client, "ESHOP DEBUG: Flags-Pre: %i", flags);
		#endif
		
		if(setState)
			flags |= 1<<3; // 1<<3 is 8, which is the spawnflag for Infinite Ammo
		else
			flags &= ~1<<3; // This part is important to disable the infinite ammo
		SetEntProp(g_iBuildingIndex[Building_Sentry][client], Prop_Data, "m_spawnflags", flags);
		
		#if defined _DEBUGMODE
		PrintToChat(client, "ESHOP DEBUG: Flags-Post: %i", flags);
		#endif
	}
	return;
}


void ToggleNoSap(int client)
{
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_NOSAP != 0) //Only needs to be applied to sentry.
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_NOSAP;
	else
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_NOSAP;
	return;
}


void ToggleGodmode(int client)
{
	bool state;
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_INVULN != 0)
	{
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_INVULN;
		g_fbBuildingInfo[Building_Dispenser][client] &= ~FLG_INVULN;
		g_fbBuildingInfo[Building_Entry][client] &= ~FLG_INVULN;
		g_fbBuildingInfo[Building_Exit][client] &= ~FLG_INVULN;
		state = false;
	}
	else
	{
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_INVULN;
		g_fbBuildingInfo[Building_Dispenser][client] |= FLG_INVULN;
		g_fbBuildingInfo[Building_Entry][client] |= FLG_INVULN;
		g_fbBuildingInfo[Building_Exit][client] |= FLG_INVULN;
		state = true;
	}

	/*** If Active ***/
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_ACTIVE != 0)
		ApplyGodmode(client, state, Building_Sentry);
		
	if(g_fbBuildingInfo[Building_Dispenser][client] & FLG_ACTIVE != 0)
		ApplyGodmode(client, state, Building_Dispenser);
		
	if(g_fbBuildingInfo[Building_Entry][client] & FLG_ACTIVE != 0)
		ApplyGodmode(client, state, Building_Entry);
		
	if(g_fbBuildingInfo[Building_Exit][client] & FLG_ACTIVE != 0)
		ApplyGodmode(client, state, Building_Exit);
	return;
}

/*** Core Function -- Used by Event_BuiltObject and ToggleGodmode() ***/
void ApplyGodmode(int client, bool setState, EBuildingTypes bType)
{
	if(g_fbBuildingInfo[bType][client] & FLG_ACTIVE != 0)
		SetEntProp(g_iBuildingIndex[bType][client], Prop_Data, "m_takedamage", (setState) ? 0 : 2);
	return;
}

/*** Credit to Roll The Dice for this ***/
bool TeleportBuilding(int client, EBuildingTypes bType)
{
	if(g_fbBuildingInfo[bType][client] & FLG_ACTIVE == 0)
		return false;
		
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: Tele: ACTIVE PASS");
	#endif
	
	/*** Get Appropriate vecMins/vecMaxs pair ***/
	EBuildVecTypes vecType;
	switch(bType)
	{
		case Building_Sentry:
		{
			if(g_fbBuildingInfo[bType][client] & FLG_ISMINISENTRY != 0)
				vecType = Vec_Minisentry;
			else
				vecType = Vec_Sentry;
		}
		case Building_Dispenser:
			vecType = Vec_Dispenser;
		case Building_Entry, Building_Exit:
			vecType = Vec_Teleport;
	}
	
	#if defined _DEBUGMODE
	PrintToChat(client, "ESHOP DEBUG: Tele: switch: %i", vecType);
	#endif
	
	/*** Get Aim Position ***/
	float flPos[3], flAng[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);
	Handle hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, client);
	
	if(hTrace != null && TR_DidHit(hTrace))
	{
		float flEndPos[3];
		TR_GetEndPosition(flEndPos, hTrace);
		//flEndPos[2] += 5.0;
		delete hTrace;
		
		#if defined _DEBUGMODE
		PrintToChat(client, "ESHOP DEBUG: Tele: endpos:%f, pos:%f, ang:%f", flEndPos, flPos, flAng);
		#endif
		
		/*** Sometimes surfaces are uneven, but still valid. So += the y-axis 5 times to make sure we can build here ***/
		// RTD does the by outright adding 5.0 to the y-axis, but this makes buildings float above flat surfaces
		bool result = false;
		for(int i = 0; i < 5; i++)
		{
			if(CanBuildHere(flEndPos, g_flBuildingMins[vecType], g_flBuildingMaxs[vecType]))
			{
				TeleportEntity(g_iBuildingIndex[bType][client], flEndPos, NULL_VECTOR, NULL_VECTOR);
				result = true;
				break;
			}	
			flEndPos[2] += 1.0;
		}
	
		return result;
	}
	delete hTrace;
	return false;
}

bool CanBuildHere(float flPos[3], float flMins[3], float flMaxs[3])
{
	TR_TraceHull(flPos, flPos, flMins, flMaxs, MASK_SOLID);
	return !TR_DidHit();
}

/*** Note: This allows you to build on anything that is not a player--including other buildings ***/
public bool TraceFilterIgnorePlayers(int entity, int contentsMask, any client)
{
	if(entity >= 1 && entity <= MaxClients)
		return false;
		
	return true;
}


void ToggleDamageScaling(int client)
{
	if(g_fbBuildingInfo[Building_Sentry][client] & FLG_SCALEDMG != 0)
	{
		g_fbBuildingInfo[Building_Sentry][client] &= ~FLG_SCALEDMG;
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_DmgScaleDisabled", client);
	}
	else
	{
		g_fbBuildingInfo[Building_Sentry][client] |= FLG_SCALEDMG;
		PrintToChat(client, "%s %T", TAG_SM, "EngieShop_DmgScaleEnabled", client);
	}
	return;
}



/*************************
	Building Color Core
*************************/

void SetAllBuildingColor(int client, int vecColor[3], char[] colorName, int selection = BCOLOR_DEFAULT)
{
	SetBuildingColor(client, Building_Sentry, vecColor, selection);
	SetBuildingColor(client, Building_Dispenser, vecColor, selection);
	SetBuildingColor(client, Building_Entry, vecColor, selection);
	SetBuildingColor(client, Building_Exit, vecColor, selection);
	
	char allName[32];
	Format(allName, sizeof(allName), "%T", "EngieShop_ResizedAll", client);
	PrintToChat(client, "%s %T", TAG_SM, "EngieShop_ColorSet", client, allName, colorName);
	return;
}

/*** Used by Event_BuiltObject ***/
void SetBuildingColorByInt(int client, EBuildingTypes bType)
{
	int vecColor[3];
	GetColorVec(g_iBuildingColor[bType][client], vecColor[0], vecColor[1], vecColor[2]);
	SetBuildingColor(client, bType, vecColor, g_iBuildingColor[bType][client]);
	return;
}

bool SetBuildingColor(int client, EBuildingTypes bType, int vecColor[3], int selection = BCOLOR_DEFAULT)
{
	/*** Check if RGB is valid ***/
	if((vecColor[0] > 255 || vecColor[0] < 0) || (vecColor[1] > 255 || vecColor[1] < 0) || (vecColor[2] > 255 || vecColor[2] < 0))
		return false;
	
	
	/*** Set variables despite building being inactive ***/
	bool isDefault = false;
	if(vecColor[0] == 255 && vecColor[1] == 255 && vecColor[2] == 255)
	{
		isDefault = true;
		g_iBuildingColor[bType][client] = BCOLOR_DEFAULT;
	}
	else
		g_iBuildingColor[bType][client] = selection;

		
	/*** Check if active ***/
	if(g_fbBuildingInfo[bType][client] & FLG_ACTIVE == 0)
		return false;
		
	int alphaValue = (g_fbBuildingInfo[bType][client] & FLG_FRIENDLY != 0) ? ALPHA_FRIENDLY : 255;
	
	if(isDefault)
		SetEntityRenderColor(g_iBuildingIndex[bType][client], 255, 255, 255, alphaValue);
	else
		SetEntityRenderColor(g_iBuildingIndex[bType][client], vecColor[0], vecColor[1], vecColor[2], alphaValue);
	
	return true;
}

bool GetColorVec(int menuSelection, int &vecColor1, int &vecColor2, int &vecColor3)
{
	/*** This is for the 'default' option on the color selection ***/
	if(menuSelection == BCOLOR_DEFAULT)
	{
		vecColor1 = 255;
		vecColor2 = 255;
		vecColor3 = 255;
		return true;
	}	
	
	char colorBuff[3][4];	// "255, 255, 255"
	if(ExplodeString(g_Colors[menuSelection], ", ", colorBuff, sizeof(colorBuff), sizeof(colorBuff[])) != 3)
	{
		if(ExplodeString(g_Colors[menuSelection], ",", colorBuff, sizeof(colorBuff), sizeof(colorBuff[]) != 3))
			return false;
	}
	
	vecColor1 = StringToInt(colorBuff[0]);
	vecColor2 = StringToInt(colorBuff[1]);
	vecColor3 = StringToInt(colorBuff[2]);
	
	return true;
}



/************************************************

	M I S C.   F U N C T I O N S
 
************************************************/


/*** This function is silent -- do not print messages ***/
bool IsClientOnCooldown(int client)
{	
	float flTimeLeft = FloatAdd(FloatSub(g_flCooldown, GetGameTime()), g_flLastCommand[client]);
	if(FloatCompare(flTimeLeft, 0.0) == 1)
		return true;
		
	return false;
}


bool PlayerHasGunslinger(int client)
{
	int index = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	int iDef;
	if(index != -1)
		iDef = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");
		
	if(iDef == GUNSLINGER_IDI)
		return true;
		
	return false;
}


EBuildingTypes GetBuildingType(int index)
{
	TFObjectMode objectMode = TF2_GetObjectMode(index);		
	TFObjectType objectType = TF2_GetObjectType(index);
	
	switch(objectType)
	{
		case TFObject_Sentry:
			return Building_Sentry;
		case TFObject_Dispenser:
			return Building_Dispenser;
		case TFObject_Teleporter:
		{
			if(objectMode == TFObjectMode_Entrance)
				return Building_Entry;
			else if (objectMode == TFObjectMode_Exit)
				return Building_Exit;
		}
	}
	return Building_Invalid;
}


/*** 
 * Cleaner method of checking command access. 
 ***/
bool CleanAccessCheck(int client, EMenuItemAccess menuChoice)
{
	switch(menuChoice)
	{
		case Item_Resize:
			return CheckCommandAccess(client, "sm_rb", ADMFLAG_GENERIC, false);
			
		case Item_Resize_Admin:
			return CheckCommandAccess(client, "sm_engieshop_scale_admin", ADMFLAG_BAN, true); //Override Only
			
		case Item_DamageScale_Admin:
			return CheckCommandAccess(client, "sm_engieshop_damage_admin", ADMFLAG_BAN, true); //Override Only
	
		
		case Item_Friendly:
			return CheckCommandAccess(client, "sm_friendlysentry", ADMFLAG_GENERIC, false);
		
		case Item_Outline:
			return CheckCommandAccess(client, "sm_buildingoutline", ADMFLAG_GENERIC, false);
		
		case Item_Color:
			return CheckCommandAccess(client, "sm_engieshop_color", ADMFLAG_GENERIC, true); //Override Only
		
		
		case Item_Abilties:
			return CheckCommandAccess(client, "sm_engieshop_abilities", ADMFLAG_GENERIC, true); //Override only.
		
		case Item_Abilities_Ammo:
			return CheckCommandAccess(client, "sm_engieshop_ability_ammo", ADMFLAG_BAN, true); //Override Only
			
		case Item_Abilities_NoSap:
			return CheckCommandAccess(client, "sm_engieshop_ability_nosap", ADMFLAG_BAN, true); //Override Only
		
		case Item_Abilities_God:
			return CheckCommandAccess(client, "sm_engieshop_ability_god", ADMFLAG_BAN, true); //Override Only
		
		case Item_Abilities_DmgToggle:
			return CheckCommandAccess(client, "sm_engieshop_ability_dmgtoggle", ADMFLAG_BAN, true); //Override Only
		
		case Item_Abilities_Tele:
			return CheckCommandAccess(client, "sm_engieshop_ability_tele", ADMFLAG_BAN, true); //Override Only
	}
	return false;
}


void LoadColorsConfig()
{
	#if defined _DEBUGMODE
	PrintToServer("Colors Config Loading: %s", g_strColorConfig);
	#endif

	/*** Verify KeyValue Config ***/
	if(!FileExists(g_strColorConfig))
	{
		SetFailState("%T", "EngieShop_NoColorsConfig", LANG_SERVER, g_strColorConfig);
		return;
	}
	
	KeyValues hKv = CreateKeyValues("BuildingColors");
	if(!FileToKeyValues(hKv, g_strColorConfig))
	{
		SetFailState("%T", "EngieShop_BadColorsConfig", LANG_SERVER, g_strColorConfig);
		delete hKv;
		return;
	}
	
	if(!hKv.GotoFirstSubKey())
	{
		SetFailState("%T", "EngieShop_ConfigSubKey", LANG_SERVER, g_strColorConfig);
		delete hKv;
		return;
	}
	
	/*** Zero-out Variables ***/
	for(int i = 0; i < MENU_MAXCOLORS; i++)
	{
		g_Colors[i] = "";
		g_ColorNames[i] = "";
	}
	g_iColorCount = 0;
	
	
	do
	{
		hKv.GetSectionName(g_ColorNames[g_iColorCount], sizeof(g_ColorNames[]));
		hKv.GetString("rgb", g_Colors[g_iColorCount], sizeof(g_Colors[]));
		g_iColorCount++;
	}while(hKv.GotoNextKey() && g_iColorCount < 32);
	
	#if defined _DEBUGMODE
	PrintToServer("Colors Config Load Success: %i", g_iColorCount);
	#endif
	
	delete hKv;
	return;
}