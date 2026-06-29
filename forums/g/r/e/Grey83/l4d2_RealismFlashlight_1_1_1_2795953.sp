#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>

#define PLUGIN_NAME			"[L4D2] Realism Flash Light"
#define PLUGIN_DESCRIPTION	"Weapons not equipped with a flashlight will not be able to turn on the flashlight, optionally enable the flashlight battery system (dying torch vs blinking light)."
#define PLUGIN_VERSION		"1.1.1"
#define PLUGIN_AUTHOR		"Iciaria (rewritten by Grey83)"
#define PLUGIN_URL			"https://forums.alliedmods.net/showthread.php?p=2795890"

/*
-------------------------------------------------------------------------------
Change Logs:
1.1.1 (Dec-26-2022, by Grey83)
	- All plugin code has been rewritten to the new syntax
	- Added ConVar bounds
	- Fixed timer tOnClientPutInServer
	- Slightly optimize performance and simplify code

1.1 (Dec-26-2022)
	- Now use "GetEngineVersion" in "AskPluginLoad2" to detect game type.
	- Use "strcmp" instead of "strncmp" to check weapon names.
	- Use "Get/SetEntProp" instead of "Get/SetEntData" to control the state of the flashlight.
	- Now use the new way to pass the value of Cvar.
	- Thanks to "Silvers" for suggestions.
	- Changed default value of Cvars, on older versions, had wrong value (FlashThreshold_lv*).
	- Survivor bots' flashlights are now also restricted.
	- Various changes to the code.
	- Optimize performance and simplify code.

1.0 (Dec-25-2022)
	- Initial release.

-------------------------------------------------------------------------------

Credit：
--@Mr.Zero ([L4D2] Block Flashlight (1.2, 18/10-2011))
First idea to learn how to control a flashlight light, something I've always wanted.

--@Silvers ([L4D2] Swap Character (1.2) [21-Mar-2020])
Learn how to get a client's character and check them.

--@ConnerRia. Fork. by Dragokas & KoMiKoZa ([L4D2] Saferoom Naps: Spawn Next Map With 50 HP)
Learn how to use the "map_transition" event.

--@All the players who helped me with the test
*/

/*
#define IS_VALID_CLIENT(%1)		(%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1)	(IsClientConnected(%1) && IsClientInGame(%1))
#define IS_VALID_INGAME(%1)		(IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_SURVIVOR(%1)			(GetClientTeam(%1) == 2)
#define IS_VALID_SURVIVOR(%1)	(IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
*/

/*
static const char g_sNoFlashlight_WeaponList[][]= {
	"weapon_melee",
	"weapon_first",
	"weapon_pain_",
	"weapon_molot",
	"weapon_pipe_",
	"weapon_vomit",
	"weapon_adren",
	"weapon_defib",
	"weapon_upgra",
	"weapon_upgra",
}
*/

static const char WEAPONS[][] =
{
	"pistol_magnum",
	"pistol",
	"rifle_m60",
	"grenade_launcher",
	"smg",
	"smg_silenced",
	"smg_mp5",
	"shotgun_chrome",
	"pumpshotgun",
	"rifle",
	"rifle_ak47",
	"rifle_desert",
	"rifle_sg552",
	"autoshotgun",
	"shotgun_spas",
	"sniper_awp",
	"sniper_military",
	"sniper_scout",
	"hunting_rifle"
};

#define CVAR_FLAGS	FCVAR_NOTIFY

enum
{
	Th_Off_Min,
	Th_Off_Max,
	Th_On_Min,
	Th_On_Max,

	Th_Total
};
enum
{
	C_Bill,
	C_Zoey,
	C_Francis,
	C_Louis,
	C_Nick,
	C_Rochelle,
	C_Coach,
	C_Ellis,

	C_Total
};
/*
[Character]:
	0 = Flashlight_Status
	(
		-2	= Switch to a weapon without a flashlight when the flashlight is blinking.
		-1	= The battery is dead or not initialized.
		 0	= Normal.
		 1	= Holding a weapon without a flashlight(Off).
		 2	= Flashlight is blinking(Off)
	)
	1 = Battery Power,
	2 = Client User Id,
	3 = Saved Power,
	4 = Flash Timer
*/
enum
{
	S_Flashlight,
	S_Battery,
	S_Client,
	S_Saved,
	S_Timer,

	S_Total
};
//=========================================================================================
//	Plugin ConVars
//=========================================================================================
ConVar
	g_hServerTickrate,
	g_hEnabled,

	g_hPowerEnabled,
	g_hPowerMin,
	g_hPowerMax,
	g_hfThreshold[3],
	g_hiThreshold[3][Th_Total];

//=========================================================================================
//	Plugin Variables
//=========================================================================================
bool
	g_bEnabled,
	g_bPowerEnabled;
int
	g_iServerTickrate,
	g_iPowerMin,
	g_iPowerMax,
	g_iThreshold[3][Th_Total];
float
	g_fThreshold[3];


//=========================================================================================
bool
	g_bAllow,
	g_bAllowSetPower = true,
	g_bInSafeRoom;
int
	g_iFLState[C_Total][S_Total],
//	g_iFlashlight_Offset,
	g_iServerTickrateCount;

//=========================================================================================
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_RealismFlashlight_Version", PLUGIN_VERSION , "Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("l4d2_RealismFlashLight_Debug", "0", "Enabled This plugin?\n0 = Disabled, 1 = Enabled", _, true, _, true, 1.0);
	g_hEnabled.AddChangeHook(CvarChanged_Debug);

	g_hEnabled = CreateConVar("l4d2_RealismFlashLight_Enabled", "1", "Enabled This plugin?\n0 = Disabled, 1 = Enabled", CVAR_FLAGS, true, _, true, 1.0);
	g_hEnabled.AddChangeHook(CvarChanged);
	g_hPowerEnabled = CreateConVar("l4d2_RealismFlashLight_PowerEnabled", "0", "Enable battery system?\nThe flashlight will blink on low battery and disable when the battery is depleted.\n0 = Disabled, 1 = Enabled", CVAR_FLAGS, true, _, true, 1.0);
	g_hPowerEnabled.AddChangeHook(CvarChanged);
	g_hPowerMin = CreateConVar("l4d2_RealismFlashLight_PowerMin", "240", "The minimum flashlight battery level that can be set when the battery is initialized.\nSecond, Int Value.", _, true, 1.0);
	g_hPowerMin.AddChangeHook(CvarChanged);
	g_hPowerMax = CreateConVar("l4d2_RealismFlashLight_PowerMax", "480", "The maximum flashlight battery level that can be set when the battery is initialized.\nSecond, Int Value.", _, true, 1.0);
	g_hPowerMax.AddChangeHook(CvarChanged);

	g_hfThreshold[0] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0", "1.00", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv0' is applied\nPercentage, Float Value.\n0.0 = Disabled.", _, true, _, true, 1.0);
	g_hfThreshold[0].AddChangeHook(CvarChanged);
	g_hiThreshold[0][Th_Off_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_Off_Min", "10", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.", _, true);
	g_hiThreshold[0][Th_Off_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[0][Th_Off_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_Off_Max", "80", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[0][Th_Off_Max].AddChangeHook(CvarChanged);
	g_hiThreshold[0][Th_On_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[0][Th_On_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[0][Th_On_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_On_Max", "4", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[0][Th_On_Max].AddChangeHook(CvarChanged);

	g_hfThreshold[1] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1", "0.50", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv1' is applied\nPercentage, Float Value.\n0.0 = Disabled.", _, true, _, true, 1.0);
	g_hfThreshold[1].AddChangeHook(CvarChanged);
	g_hiThreshold[1][Th_Off_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_Off_Min", "2", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.", _, true);
	g_hiThreshold[1][Th_Off_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[1][Th_Off_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_Off_Max", "20", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[1][Th_Off_Max].AddChangeHook(CvarChanged);
	g_hiThreshold[1][Th_On_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[1][Th_On_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[1][Th_On_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_On_Max", "12", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[1][Th_On_Max].AddChangeHook(CvarChanged);

	g_hfThreshold[2] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2", "0.20", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv2' is applied\nPercentage, Float Value.\n0.0 = Disabled.", _, true, _, true, 1.0);
	g_hfThreshold[2].AddChangeHook(CvarChanged);
	g_hiThreshold[2][Th_Off_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_Off_Min", "2", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.", _, true);
	g_hiThreshold[2][Th_Off_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[2][Th_Off_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_Off_Max", "8", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[2][Th_Off_Max].AddChangeHook(CvarChanged);
	g_hiThreshold[2][Th_On_Min] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[2][Th_On_Min].AddChangeHook(CvarChanged);
	g_hiThreshold[2][Th_On_Max] = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_On_Max", "4", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.", _, true);
	g_hiThreshold[2][Th_On_Max].AddChangeHook(CvarChanged);

	g_hServerTickrate = CreateConVar("l4d2_RealismFlashLight_ServerTickrate", "0", "Server Minimum tickrate, reference value for battery timer.\nInt Value\n0 =Auto, Other Value = Value to Set", CVAR_FLAGS, true);
	g_hServerTickrate.AddChangeHook(CvarChanged);

	AutoExecConfig(true, "l4d2_RealismFlashlight");

	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("finale_win", Event_Finale_Win, EventHookMode_PostNoCopy);
	HookEvent("round_start_post_nav", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iServerTickrate	= g_hServerTickrate.IntValue;
	g_bEnabled			= g_hEnabled.BoolValue;

	g_bPowerEnabled		= g_hPowerEnabled.BoolValue;
	g_iPowerMin			= g_hPowerMin.IntValue;
	g_iPowerMax			= g_hPowerMax.IntValue;

	for(int i, j; i < sizeof(g_fThreshold); i++)
	{
		g_fThreshold[i] = g_hfThreshold[i].FloatValue;
		for(j = 0; j < Th_Total; j++) g_iThreshold[i][j] = g_hiThreshold[i][j].IntValue;
	}
}

public void CvarChanged_Debug(ConVar convar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if(hooked == convar.BoolValue)
		return;

	if(!hooked)
		hooked = HookEventEx("weapon_fire", Event_WeaponFire);
	else UnhookEvent("weapon_fire", Event_WeaponFire);
}

public void OnConfigsExecuted()
{
	CvarChanged(null, NULL_STRING, NULL_STRING);

	if(!g_iServerTickrate)
	{
		PrintToServer("\n============Realism Flashlight--Auto Set Tickrate:%d,", g_iServerTickrate);
		if(!g_hServerTickrate) g_hServerTickrate = FindConVar("sv_minupdaterate");
		if(g_hServerTickrate) g_iServerTickrate = g_hServerTickrate.IntValue;
		PrintToServer("\n============Realism Flashlight--Auto Set Tickrate:%d,", g_iServerTickrate);
	}
	g_iServerTickrateCount = RoundToFloor(g_iServerTickrate * 0.1);

	if(!g_bAllowSetPower)
		return;

	PrintToServer("===========================\nAll Flag Set to False, ReSet List, g_bAllowSetPower Set to false\n----------------------------------");
	ResetFlashlightState();
	g_bAllowSetPower = false;
}

public void OnMapEnd()
{
	if(!g_bInSafeRoom && !g_bAllowSetPower)
	{
		ResetFlashlightState();
		PrintToServer("===========================\n OnMapEnd: ReSet List\n----------------------------------");
	}
}

void ResetFlashlightState()
{
	for(int i, j; i < C_Total; i++) for(j = 0; i < S_Total; i++) g_iFLState[i][j] = -1;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("=======================\nMapTransitionPre, ReSet Power Value, g_bAllow Set to false,  g_bInSafeRoom Set to true\n-------------------------");
//	PrintToChatAll("===MapTransitionPre, ReSet Power Value, g_bAllow Set to false, g_bInSafeRoom Set to true-------------------------");
	g_bAllow = false;
	for(int i; i < C_Total; i++) g_iFLState[i][S_Saved] = g_iFLState[i][S_Battery];
	g_bInSafeRoom = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bInSafeRoom)
	{
		g_bInSafeRoom = false;
		PrintToServer("---\nRound Start: InSafeRoom = false\n===");
	}
}
//--Maybe consider turning off the flashlight here?
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("=======================\nRoundEndPost, ReSet Power Value\n-------------------------");
//	PrintToChatAll("==RoundEndPost, ReSet Power Value-------------------------");
	for(int i; i < C_Total; i++) g_iFLState[i][S_Battery] = g_iFLState[i][S_Saved];
}

public void Event_Finale_Win(Event event, const char[] name, bool dontBroadcast)
{
	g_bAllowSetPower = true;
}

public void OnClientPutInServer(int client)
{
	//--Old version check method.
	//g_iFlashlight_Offset = FindSendPropInfo("CTerrorPlayer", "m_fEffects");
	if(!g_bEnabled)
		return;

	//--If the player loads too slowly and the battery is not initialized.
	//--The battery will be set in "OnGameFrame".
	CreateTimer(10.0, Timer_OnClientPutInServer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public Action Timer_OnClientPutInServer(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)) && IsClientInGame(client)) SetClientFlashLight(client);
	return Plugin_Continue;
}

void SetClientFlashLight(int client)
{
	SetEntProp(client, Prop_Send, "m_fEffects", 0);

	for(int i, power; i < C_Total; i++)
	{
		g_iFLState[i][S_Flashlight] = 0;
		if(GetEntProp(client, Prop_Send, "m_survivorCharacter") == i && g_iFLState[i][S_Battery] == -1)
		{
			power = GetRandomInt(g_iPowerMin * g_iServerTickrate,  g_iPowerMax * g_iServerTickrate);
			g_iFLState[i][S_Battery] = power;
			g_iFLState[i][S_Client] = client;
			g_iFLState[i][S_Saved] = power;
			PrintToServer("Client:%d|%d#Power Set:%d|Save:%d  -Player_Name- %N\n", client, i, g_iFLState[i][S_Battery],g_iFLState[i][S_Saved], client);
//			PrintToChatAll("Client:%d|%d#Power Set:%d  -Player_Name- %N", client, i, g_iFLState[i][S_Battery], client);
		}

		//--The new client id may be the same as the disconnected client id.
		if(GetEntProp(client, Prop_Send, "m_survivorCharacter") == i && g_iFLState[i][S_Battery] != -1 && g_iFLState[i][S_Client] != client)
		{
			PrintToServer("\nUpdate_client_id:%d -> %d, Character:%d Now_Player_Name:%N\n",g_iFLState[i][S_Client], client, i, client);
//			PrintToChatAll("Update_client_id: %d -> %d, Character:%d, Now_Player_Name:%N", g_iFLState[i][S_Client], client, i, client);
			g_iFLState[i][S_Client] = client;
		}
	}
	g_bAllow = true;
}

public void OnGameFrame()
{
	if(!g_bAllow || !g_bEnabled)
		return;

	static float fPower;
	//--Store threshold value for one-shot flash timer.
	//--This is to prevent the threshold from being refreshed for the next frame.
	//--It will only be refreshed after the Flashlight flash of this time is over.
	static int iRandomTime_Off[8], iRandomTime_On[8];

	for(int i, j; i < C_Total; i++) if(g_iFLState[i][S_Client] != -1 && IsValidClient(g_iFLState[i][S_Client]))
	{
		//--Here is the code to turn off the flashlight.
		if(g_iFLState[i][S_Flashlight])
		{
//			SetEntData(g_iFLState[i][S_Client], g_iFlashlight_Offset, 0, 1, true);
			SetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects", 0);

			if(g_iFLState[i][S_Flashlight] != 2)
				continue;
		}

		//--Version 1.0 -> 1.1 (Data -> Prop)
		//GetEntData(g_iFLState[i][S_Client], g_iFlashlight_Offset) == 4
		//GetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects") == 4
		//--See also: https://forums.alliedmods.net/showpost.php?p=2795894&postcount=2

		//--Make sure the flashlight is not automatically turned on when it is not turned on.
		if(g_bPowerEnabled
		&& (GetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects") == 4 || g_iFLState[i][S_Flashlight] == 2))
		{
			fPower = g_iFLState[i][S_Battery] / float(g_iPowerMax * g_iServerTickrate);
			for(j = 2; j >= 0; j--) if(fPower < g_fThreshold[j])
			{
				g_iFLState[i][S_Timer]++;
				if(g_iFLState[i][S_Flashlight] == 2)
				{
					if(!iRandomTime_On[i])
						iRandomTime_On[i] = GetRandomInt(g_iThreshold[2][Th_On_Min], g_iThreshold[2][Th_On_Max]) * g_iServerTickrateCount;

					if(g_iFLState[i][S_Timer] > (iRandomTime_Off[i] + iRandomTime_On[i]))
					{
						SetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects", 4);
						g_iFLState[i][S_Flashlight] = g_iFLState[i][S_Timer] = iRandomTime_On[i] = iRandomTime_Off[i] = 0;
					}
				}

				if(!g_iFLState[i][S_Flashlight])
				{
					if(!iRandomTime_Off[i])
						iRandomTime_Off[i] = GetRandomInt(g_iThreshold[2][Th_Off_Min], g_iThreshold[2][Th_Off_Max]) * g_iServerTickrateCount;

					if(g_iFLState[i][S_Timer] > iRandomTime_Off[i])
					{
						SetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects", 0);
						g_iFLState[i][S_Flashlight] = 2;
					}
				}

				break;
			}

//			PrintToChatAll("Power: %d", GetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects"));

			//--If the battery is dead, or the value is not initialized.
			//--Permanently turn off the torch / try to initialize the battery
			if(g_iFLState[i][S_Battery] <= 0)
			{
				if(g_iFLState[i][S_Battery] == -1)
				{
//					PrintToChatAll("Not initialized on connect::%d|%d, try to reset",g_iFLState[i][S_Client],  i);
					SetClientFlashLight(g_iFLState[i][S_Client]);
				}
				g_iFLState[i][S_Flashlight] = -1;
			}

			if(g_iFLState[i][S_Battery] > 0 && GetEntProp(g_iFLState[i][S_Client], Prop_Send, "m_fEffects") == 4)
			{
				g_iFLState[i][S_Battery]--;
//				PrintToChatAll("Client:%d, Power: %d, Character:%d",g_iFLState[i][S_Client], g_iFLState[i][S_Battery], i);
			}
		}
	}
}
public void OnWeaponSwitchPost(int client, int weapon)
{
	if(!g_bEnabled || !g_bAllow)
		return;

	int client_count = RFL_GetClientCount(client);
	if(client_count == -1)
		return;

//	PrintToServer("Character: %d",GetEntProp(client, Prop_Send, "m_survivorCharacter"));
	if(/*g_iFLState[client_count][S_Flashlight] && */g_iFLState[client_count][S_Flashlight] == -1)
		return;

//	PrintToServer("Character: %d",GetEntProp(client, Prop_Send, "m_survivorCharacter"));
	bool Allow;
	if(GetClientTeam(client) == 2)
	{
		char weapon_name[28];
		GetClientWeapon(client, weapon_name, sizeof(weapon_name));
		if(weapon_name[0] == 'w') for(int i; i < sizeof(WEAPONS); i ++)
		{
//			PrintToServer("client: %d, %s",client, weapon_name);
			if(!strcmp(WEAPONS[i], weapon_name[7]))
			{
				Allow = true;
				if(g_iFLState[client_count][S_Flashlight] != 2) g_iFLState[client_count][S_Flashlight] = 0;
				break;
			}
		}
	}

	if(!Allow)
	{
		//--When the flashlight is blinking (off)
		if(g_iFLState[client_count][S_Flashlight] == 2)
		{
			g_iFLState[client_count][S_Flashlight] = -2;
			return;
		}

		SetEntProp(client, Prop_Send, "m_fEffects", 0);
		//--Turn off the flashlight.
		g_iFLState[client_count][S_Flashlight] = 1;
	}
}

int RFL_GetClientCount(int client)
{
	for(int i; i < C_Total; i++) if(g_iFLState[i][S_Client] == client && IsValidClient(client))
		return i;

	return -1;
}

bool IsValidClient(int client)
{
	return IsValidEntity(client) && !IsFakeClient(client);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int index = GetEventInt(event, "userid");
	int client = GetClientOfUserId(index), count = -1024;
	if(client && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		for(int i; i < C_Total; i++) if(g_iFLState[i][S_Client] == client) count = i;
		if(count == -1024)
		{
			PrintToChatAll("Client Not Found!");
			return;
		}

		PrintToChatAll("--++--\nIndex:%d, Id:%d, Character:%d,Flashlight_status:%d,Power:%d Saved_id:%d,Saved_power:%d, Flash_Timer:%d", index, client, count, g_iFLState[count][S_Flashlight], g_iFLState[count][S_Battery], g_iFLState[count][S_Client], g_iFLState[count][S_Saved], g_iFLState[count][S_Timer]);
		PrintToChatAll("Offset:%d, Power_percentage:%f, Count:%d", GetEntProp(g_iFLState[count][2], Prop_Send, "m_fEffects"), g_iFLState[count][S_Battery] / float(g_iPowerMax * g_iServerTickrate), count);
	}
}