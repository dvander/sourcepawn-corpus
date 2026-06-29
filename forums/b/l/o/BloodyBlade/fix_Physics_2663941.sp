#define PLUGIN_VERSION "1.2"
/*
=====================================================================================================================
=====================================================================================================================
211_1_1____2¶¶¶¶66¶¶¶¶¶¶¶88¶88__¶888¶¶2________126
__________¶¶¶¶¶12¶¶¶¶¶8¶¶¶866¶612¶8¶¶¶6_1_________
211_1___6¶¶¶¶¶¶¶¶¶¶¶¶¶¶866¶¶66¶822¶¶8886681_______
1111____2¶¶¶¶¶¶¶¶¶¶¶¶¶¶8688¶¶8_8¶2168¶61126_______
21___268¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶8¶¶¶¶¶¶68¶6_188__666______
11__12¶¶¶¶¶¶228¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶68¶2_26¶2_2861____     ___           _  _              _             _   _
1__16¶¶¶¶¶6___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶61¶¶_¶¶6¶____122__    /   \ ___   __| |(_)  ___  __ _ | |_  ___   __| | | |_  ___
1__8¶¶¶¶¶6____6¶¶¶¶8¶¶¶¶¶¶¶¶¶¶¶¶218¶18¶61¶1______1 	 / /\ // _ \ / _` || | / __|/ _` || __|/ _ \ / _` | | __|/ _ \
2186¶¶¶¶2_1____28682¶8¶8¶¶¶¶¶¶¶¶¶_68266¶1_2¶1_____ 	/ /_//|  __/| (_| || || (__| (_| || |_|  __/| (_| | | |_| (_) |
6862¶¶¶¶__1_____6___26_16¶8¶¶¶8__¶211612¶8_¶¶81886 /___,'  \___| \__,_||_| \___|\__,_| \__|\___| \__,_|  \__|\___/
¶88¶¶¶¶81_1____12________________¶¶1_11_6¶_2¶¶2___  _    _
6¶¶¶¶¶¶6__2____1________________2_88_2_1_¶1¶8661__ | |_ | |__    ___   _ __ ___    ___  _ __ ___    ___   _ __  _   _
1_¶¶¶¶¶2__8______________________1¶22____¶688¶¶12_ | __|| '_ \  / _ \ | '_ ` _ \  / _ \| '_ ` _ \  / _ \ | '__|| | | |
_2¶¶¶¶¶8__21_1_11_____________1__¶__11_1_¶81¶¶¶1__ | |_ | | | ||  __/ | | | | | ||  __/| | | | | || (_) || |   | |_| |
_2¶¶¶¶¶¶1_2621_1________________18___26__2¶2_¶¶___  \__||_| |_| \___| |_| |_| |_| \___||_| |_| |_| \___/ |_|    \__, |
28_¶¶¶¶¶1__262_____1_______1_____2___1611_8¶126___                                                               |___/
8__¶¶¶¶¶2_282_______________1____2___62_2__2¶¶6___                                 __
__2¶8¶8¶6_6¶¶¶8182______________622__16__12__82___                          ___   / _|
__¶2_2¶¶¶_6¶¶¶¶¶¶¶¶12__61_2¶¶¶¶¶¶¶¶66_6___¶¶21112_                         / _ \ | |_
1_81__8¶¶__6¶¶268¶¶¶¶61¶¶¶¶¶¶¶2_18¶¶1__1_2¶¶¶2_1_1                        | (_) ||  _|
8_22__1¶¶1__6¶¶¶¶¶¶¶¶_____¶¶¶¶¶¶¶_1¶____1¶¶¶¶8____                         \___/ |_|
1_22__1¶¶8____6¶¶¶2__________81___6______¶¶¶¶¶2___
_______¶¶¶2_______________________2______626¶¶6___
_______8¶¶6_______16__________________1__¶¶¶¶8¶81_  						  *****
_____686¶¶¶¶2___12______________________¶¶¶¶8¶¶¶86
___2¶¶¶¶8¶¶¶6_____26_______________16___¶¶¶¶¶¶¶¶¶6          __  __                     __     __
86¶¶¶¶¶¶¶¶¶¶¶¶221__2¶881__________22_____¶¶¶¶¶128¶         /\ \/\ \                   /\ \__ /\ \
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶882_16_____¶¶¶21____1_1¶¶¶¶¶228¶         \ \ \_\ \      __      __  \ \ ,_\\ \ \___
¶¶¶¶¶¶¶¶8¶¶¶¶8¶¶¶8¶¶¶¶¶¶¶¶¶62¶¶¶8___2___¶¶¶¶¶¶86¶¶          \ \  _  \   /'__`\  /'__`\ \ \ \/ \ \  _ `\
¶¶¶¶¶¶¶¶¶¶¶¶¶8162__6¶¶¶¶¶¶66_______6____¶¶¶¶¶¶66¶¶           \ \ \ \ \ /\  __/ /\ \L\.\_\ \ \_ \ \ \ \ \
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶66___88¶88________¶¶____¶¶¶¶¶¶862¶¶            \ \_\ \_\\ \____\\ \__/.\_\\ \__\ \ \_\ \_\
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶6¶1____________¶¶¶1___¶¶¶¶¶¶¶¶626¶             \/_/\/_/ \/____/ \/__/\/_/ \/__/  \/_/\/_/
¶¶¶¶¶¶¶8¶¶¶¶¶2¶8¶¶¶2_________2¶81___2¶¶¶¶¶¶¶¶86618          __                  __
¶¶¶¶¶¶8¶¶¶¶¶¶2¶¶¶¶8¶¶¶8¶622¶¶¶_____6¶¶¶¶¶8¶¶¶8288¶         /\ \                /\ \
¶¶¶¶¶¶¶¶¶¶¶8¶¶8888¶628¶¶¶¶¶2¶¶6____1¶¶¶¶¶8¶¶¶8¶¶¶¶         \ \ \         __    \_\ \      __       __   _ __
¶¶¶¶¶¶¶¶6¶¶8¶¶2666866¶¶¶¶¶¶_¶¶¶____6¶¶¶¶¶8¶¶68¶¶8¶          \ \ \  __  /'__`\  /'_` \   /'_ `\   /'__`\/\`'__\
¶¶¶¶¶¶¶¶68¶6¶¶668628¶¶¶¶¶¶82¶¶¶¶__1¶¶¶¶¶62¶¶68¶¶88           \ \ \L\ \/\  __/ /\ \L\ \ /\ \L\ \ /\  __/\ \ \/
¶¶¶¶¶¶¶¶6¶¶¶¶¶¶6666¶¶¶8¶2118¶¶¶¶6_8¶¶¶¶¶128¶6¶¶¶¶¶            \ \____/\ \____\\ \___,_\\ \____ \\ \____\\ \_\
¶¶¶¶¶¶¶¶¶¶¶88¶¶862¶¶¶8¶¶2826¶¶¶¶¶¶¶¶66¶¶16¶¶¶¶¶¶¶8             \/___/  \/____/ \/__,_ / \/___L\ \\/____/ \/_/
¶¶¶¶¶¶¶¶8¶¶¶2¶¶¶8¶¶¶28¶¶¶¶_2¶¶¶8¶¶¶22¶¶618¶¶¶¶¶¶¶¶                           	    	  /\____/
¶¶¶¶¶¶¶¶82¶¶28¶¶¶¶8_28¶¶¶2__¶881_¶618¶¶12¶¶¶¶¶¶¶¶¶                            			  \_/__/
=====================================================================================================================
=====================================================================================================================

												===< NOTE >===

- PhysicsFix: Most plugins use cheat commands to create oxygentank, propanetank or fireworkcrate and this is bad!! When you find such a propanetank on the map and try to shoot to blow up those zombies standing nearby nothing will happen. This plugin fixed it! 
              If you are playing with sv_cheats '1' and use the 'give oxygentank' command change 'physics_timer' the value to 1 or 2 sec.

- BarrowFix: Some custom campaings (like this) installed on your server cause a bug where the wheelbarrow may explode like propane tanks, set the value to '0' if this bug never happens.

*/

#pragma	semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define debug 0

#define	OXYGENTANK_MODEL		"models/props_equipment/oxygentank01.mdl"
#define	FIREWORKCRATE_MODEL	"models/props_junk/explosive_box001.mdl"
#define	PROPANETANK_MODEL		"models/props_junk/propanecanister001a.mdl"
#define WHEELBARROW_MODEL		"models/props_junk/wheebarrow01a.mdl"

#define	OXYGENTANK			"weapon_oxygentank"
#define	FIREWORKCRATE		"weapon_fireworkcrate"
#define	PROPANETANK			"weapon_propanetank"
#define	PHYSICS				"prop_physics"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Physics Fix",
	author = "raziEiL [disawar1]",
	description = "Fixed 3rd party plugins/addons bugs",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

ConVar g_hCvarBarrowFix, g_hCvarTimer;
bool g_bCvarBarrowFix, g_bAllowHook;
float g_fCvarTimer;

public void OnPluginStart()
{
	CreateConVar("physics_version", PLUGIN_VERSION, "Physics plugin version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	g_hCvarBarrowFix	=	CreateConVar("physics_barrow", "1", "WheelBarrow Fix: 1: Enable, 0: Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarTimer			=	CreateConVar("physics_timer", "0.01", "Time interval when the fix is triggered after oxygentank/fireworkcrate/propanetank created, 0.0: Disable Physics Fix", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	AutoExecConfig(true, "fix_Physics");

	PF_GetCVars();
	g_hCvarBarrowFix.AddChangeHook(OnCVarChange);
	g_hCvarTimer.AddChangeHook(OnCVarChange);
}

public void OnMapStart()
{
	g_bAllowHook = true;
}

public void OnMapEnd()
{
	g_bAllowHook = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity != -1 && IsValidEntity(entity))
	{
		if (g_bCvarBarrowFix && strcmp(classname, PHYSICS) == 0)
			CreateTimer(0.01, PF_t_WhellBarrow, EntIndexToEntRef(entity));
		else if (g_bAllowHook && g_fCvarTimer && (strcmp(classname, OXYGENTANK) == 0 || strcmp(classname, FIREWORKCRATE) == 0 || strcmp(classname, PROPANETANK) == 0))
		{
			CreateTimer(g_fCvarTimer, PF_t_RecreateThis, EntIndexToEntRef(entity));
		}
	}
}

public Action PF_t_WhellBarrow(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
		return;

	char sTemp[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

	if (strcmp(sTemp, WHEELBARROW_MODEL) == 0)
	{
#if debug
		LogMessage("Wheelbarrow entity %d created. Trying TODO FIX!", entity);
#endif
		PhysicsFixFunc(entity, WHEELBARROW_MODEL, true);
	}
}

public Action PF_t_RecreateThis(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
		return;

	char sTemp[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

	if (strcmp(sTemp, OXYGENTANK_MODEL) == 0 || strcmp(sTemp, FIREWORKCRATE_MODEL) == 0 || strcmp(sTemp, PROPANETANK_MODEL) == 0)
	{
#if debug
		LogMessage("Oxygentank/Propantank/Fireworkcrate entity %d created. Trying TODO FIX!", entity);
#endif
		PhysicsFixFunc(entity, sTemp);
	}
}

void PhysicsFixFunc(int entity, char[] sModel, bool bOverride = false)
{
	float vOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);

	// If player carrying this entity (null vector)
	if (vOrigin[0] == 0 && vOrigin[1] == 0 && vOrigin[2] == 0) return;

	float vAngeles[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAngeles);
	AcceptEntityInput(entity, "Kill");

	if (!bOverride)
		entity = CreateEntityByName(PHYSICS);
	else
		entity = CreateEntityByName("prop_physics_override");

	if (entity != -1 && IsValidEntity(entity))
	{
#if debug
		LogMessage("entity re-created with index %d %f %f %f (bOverride=%d)", entity, vOrigin[0], vOrigin[1], vOrigin[2], bOverride);
#endif
		DispatchKeyValue(entity, "model", sModel);
		TeleportEntity(entity, vOrigin, vAngeles, NULL_VECTOR);
		DispatchSpawn(entity);
	}
}

public void OnCVarChange(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	PF_GetCVars();
}

public void OnConfigsExecuted()
{
	PF_GetCVars();
}

void PF_GetCVars()
{
	g_bCvarBarrowFix = g_hCvarBarrowFix.BoolValue;
	g_fCvarTimer = g_hCvarTimer.FloatValue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char game[32];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead", false) && !StrEqual(game, "left4dead2", false) || !IsDedicatedServer())
	{
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}
