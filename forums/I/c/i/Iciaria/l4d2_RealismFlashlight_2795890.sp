#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_NAME             "[L4D2] Realism Flash Light"
#define PLUGIN_DESCRIPTION      "Weapons not equipped with a flashlight will not be able to turn on the flashlight, optionally enable the flashlight battery system (dying torch vs blinking light)."
#define PLUGIN_VERSION          "1.2.4"
#define PLUGIN_AUTHOR           "Spokzooy/Iciaria"
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?p=2795890"

/*
-------------------------------------------------------------------------------
Change Logs:
1.2.4 (Nov-19-2023)
  - Add Cvar: l4d2_RealismFlashlight_AutoFlashlight", When switching from a weapon without a flashlight to a weapon with a flashlight, if the flashlight was previously in the ON state, it will automatically be restored. Requested by "Automage" And "swiftswing1'. 

1.2.3 (Oct-05-2023)
	- Fixed: If a player dies during a map transition, battery status will be locked.

1.2.2 (Feb-27-2023)
	- Fixed: Plugin no longer work after chapter transitions.
	- Fixed: Battery levels sometimes had incorrect values when round restarts or map changes.
	- Fixed: When changing the value of cvar "l4d2_RealismFlashLight_Bot_Buff" in the game, if the new value is less than or equal to the old value. The bot's battery will no longer be drained.
	- Add plugin native "RealismFlashlight_GetStatus".

1.2.1 (Feb-11-2023)
	- Fix the problem that the charging function is invalid. Thanks to "sonic155" for report and help tested.
	- It is now not possible to charge the battery above 100%.
	- New Cvars: l4d2_RealismFlashlight_Charge_Hint, Used to control whether to print a message in the chat box to remind the player when the battery is fully charged. 
	- Various changes to the code.

1.2 (Feb-09-2023)
	- The plugin now uses a new way to initialize the battery and check the client's correspondence with the character every server frame, This fixes some issues caused by players idle or changer characters.
	- Fixed "Exception reported: Entity X (X) is invalid" being thrown when a player joins a server. Thanks to "sonic155" for reporting.
	- New feature: hold down "duck + shove" or "shove" buttons to charge the battery. Requested by "sonic155".
	- New feature: Optionally limit survivor bots' flashlights and batteries as well, and set how quickly they drain.
	- New Cvars: l4d2_RealismFlashLight_Bot, l4d2_RealismFlashLight_Bot_Buff, l4d2_RealismFlashlight_Charge,l4d2_RealismFlashlight_Charge_Key, l4d2_RealismFlashlight_Charge_Second. 
	- Add console commands: sm_rfl_view  sm_rfl_set, Use them to view and set the character's flashlight battery status.
	- Various changes to the code.
	 
1.1.2 (Dec-28-2022)
	- Fix a problem: when Cvar changes, the value of "fPower" is always 0, causing the plugin to not work properly.
	- The error only occurs when the battery system is enabled.

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
#define C_NICK                                4
#define C_ROCHELLE				5
#define C_COACH                               6
#define C_ELLIS                               7

#define C_BILL                                0
#define C_ZOEY                                1
#define C_FRANCIS                             2
#define C_LOUIS                               3
*/
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))

#define CVAR_FLAGS	FCVAR_NOTIFY


//=========================================================================================
//	Plugin  Natives
//=========================================================================================
/**
 * @brief Get the character's flashlight status.
 * @remarks This plugin currently works through the "OnGameFrame()" function
 *				which may cause issues with other light related plugins.
 *
 * @param character		Target character.
 * @param index			Array index.
 *
 *
 * @return			Specified value.
 */
native int RealismFlashlight_GetStatus(int character, int index);

//=========================================================================================
//	Plugin ConVars
//=========================================================================================

ConVar g_hCvarRFL_ServerTickrate;
ConVar g_hCvarRFL_Debug;
ConVar g_hCvarRFL_Enabled;
ConVar g_hCvarRFL_AutoFlashlight;

ConVar g_hCvarRFL_PowerEnabled;
ConVar g_hCvarRFL_PowerMin;
ConVar g_hCvarRFL_PowerMax;
ConVar g_hCvarRFL_FlashThreshold_lv0;
ConVar g_hCvarRFL_FlashThreshold_lv0_Off_Min;
ConVar g_hCvarRFL_FlashThreshold_lv0_Off_Max;
ConVar g_hCvarRFL_FlashThreshold_lv0_On_Min;
ConVar g_hCvarRFL_FlashThreshold_lv0_On_Max;
ConVar g_hCvarRFL_FlashThreshold_lv1;
ConVar g_hCvarRFL_FlashThreshold_lv1_Off_Min;
ConVar g_hCvarRFL_FlashThreshold_lv1_Off_Max;
ConVar g_hCvarRFL_FlashThreshold_lv1_On_Min;
ConVar g_hCvarRFL_FlashThreshold_lv1_On_Max;
ConVar g_hCvarRFL_FlashThreshold_lv2;
ConVar g_hCvarRFL_FlashThreshold_lv2_Off_Min;
ConVar g_hCvarRFL_FlashThreshold_lv2_Off_Max;
ConVar g_hCvarRFL_FlashThreshold_lv2_On_Min;
ConVar g_hCvarRFL_FlashThreshold_lv2_On_Max;

ConVar g_hCvarRFL_Bot;
ConVar g_hCvarRFL_Bot_Buff;
ConVar g_hCvarRFL_Charge;
ConVar g_hCvarRFL_Charge_Key;
ConVar g_hCvarRFL_Charge_Second;
ConVar g_hCvarRFL_Charge_Hint;
//Convar g_hCvarRFL_Change_DeathCount_Allow;
//Convar g_hCvarRFL_Change_DeathCount_Second;
//COnvar g_hCvarRFL_Allow_Change_Items;

//=========================================================================================
//	Plugin Variables
//=========================================================================================

int	g_iCvarRFL_ServerTickrate;
bool	g_bCvarRFL_Debug;
bool	g_bCvarRFL_Enabled;
bool  g_bCvarRFL_AutoFlashlight;

bool	g_bCvarRFL_PowerEnabled;
int	g_iCvarRFL_PowerMin;
int	g_iCvarRFL_PowerMax;
float	g_fCvarRFL_FlashThreshold_lv0;
int	g_iCvarRFL_FlashThreshold_lv0_Off_Min;
int	g_iCvarRFL_FlashThreshold_lv0_Off_Max;
int	g_iCvarRFL_FlashThreshold_lv0_On_Min;
int	g_iCvarRFL_FlashThreshold_lv0_On_Max;
float	g_fCvarRFL_FlashThreshold_lv1;
int	g_iCvarRFL_FlashThreshold_lv1_Off_Min;
int	g_iCvarRFL_FlashThreshold_lv1_Off_Max;
int	g_iCvarRFL_FlashThreshold_lv1_On_Min;
int	g_iCvarRFL_FlashThreshold_lv1_On_Max;
float	g_fCvarRFL_FlashThreshold_lv2;
int	g_iCvarRFL_FlashThreshold_lv2_Off_Min;
int	g_iCvarRFL_FlashThreshold_lv2_Off_Max;
int	g_iCvarRFL_FlashThreshold_lv2_On_Min;
int	g_iCvarRFL_FlashThreshold_lv2_On_Max;

bool	g_bCvarRFL_Bot;
int	g_iCvarRFL_Bot_Buff;
bool	g_bCvarRFL_Charge;
bool	g_bCvarRFL_Charge_Key;
int	g_iCvarRFL_Charge_Second;
bool	g_bCvarRFL_Charge_Hint;

bool g_bHavaFlashlightWeapon_FlashLightOn[8];
int	g_iflashlightState[8][5];
/*+++++
[Character] 
[
0 = Flashlight_Status,
(
-2	=	Switch to a weapon without a flashlight when the flashlight is blinking.
-1	=	The battery is dead or not initialized.
0	=	Normal.
1	=	Holding a weapon without a flashlight(Off).
2	=	Flashlight is blinking(Off)
)
-----------------------------------------
1 = Battery Power, 
2 = Client User Id, 
(
If it is a fake client, This value will always be incremented by 100.
)
3 = Saved Power, 
4 = Flash Timer
]
++++++*/
bool	g_bKeyState[8];

bool	g_bAllow = false;
bool	g_bAllowSetPower = true;
bool	g_bInSafeRoom = false;
int	g_iServerTickrateCount;
int	g_iMaxPower;

static char g_sHavaFlashlight_WeaponList[19][] = {
        "weapon_pistol_magnum",
        "weapon_pistol",
        "weapon_rifle_m60",
        "weapon_grenade_launcher",
        "weapon_smg",
        "weapon_smg_silenced",
        "weapon_smg_mp5",
        "weapon_shotgun_chrome",
        "weapon_pumpshotgun",
        "weapon_rifle",
        "weapon_rifle_ak47",
        "weapon_rifle_desert",
        "weapon_rifle_sg552",
        "weapon_autoshotgun",
        "weapon_shotgun_spas",
        "weapon_sniper_awp",
        "weapon_sniper_military",
        "weapon_sniper_scout",
        "weapon_hunting_rifle"
}
//=========================================================================================
//	Plugin Basic
//=========================================================================================
public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	RegPluginLibrary("l4d2_RealismFlashlight");

	CreateNative("RealismFlashlight_GetStatus", Native_GetStatus);

	return APLRes_Success;
}

void CreateCvars()
{
	CreateConVar("l4d2_RealismFlashlight_Version",PLUGIN_VERSION , "Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarRFL_Enabled = CreateConVar("l4d2_RealismFlashLight_Enabled", "1", "Enabled This plugin?\n0 = Disabled, 1 = Enabled", CVAR_FLAGS);
	g_hCvarRFL_PowerEnabled = CreateConVar("l4d2_RealismFlashLight_PowerEnabled", "0", "Enable battery system?\nThe flashlight will blink on low battery and disable when the battery is depleted.\n0 = Disabled, 1 = Enabled", CVAR_FLAGS);
	g_hCvarRFL_PowerMin = CreateConVar("l4d2_RealismFlashLight_PowerMin", "200", "The minimum flashlight battery level that can be set when the battery is initialized.\nSecond, Int Value.");
	g_hCvarRFL_PowerMax = CreateConVar("l4d2_RealismFlashLight_PowerMax", "400", "The maximum flashlight battery level that can be set when the battery is initialized.\nSecond, Int Value.");
  g_hCvarRFL_AutoFlashlight = CreateConVar("l4d2_RealismFlashlight_AutoFlashlight", "0", "When switch from a weapon without a flashlight to a weapon with a flashlight,\nDoes it automatically restore the flashlight to its previously turned-on state if it was on?");

	g_hCvarRFL_FlashThreshold_lv0 = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0", "0.8", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv0' is applied\nPercentage, Float Value.\n0.00 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv0_Off_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_Off_Min", "10", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv0_Off_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_Off_Max", "160", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv0_On_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv0_On_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv0_On_Max", "6", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");

	g_hCvarRFL_FlashThreshold_lv1 = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1", "0.30", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv1' is applied\nPercentage, Float Value.\n0.00 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv1_Off_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_Off_Min", "2", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv1_Off_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_Off_Max", "120", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv1_On_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv1_On_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv1_On_Max", "12", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");

	g_hCvarRFL_FlashThreshold_lv2 = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2", "0.00", "When the power is lower than a few percent of 'l4d2_RealismFlashLight_PowerMax', the light flashing interval set by 'lv2' is applied\nPercentage, Float Value.\n0.00 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv2_Off_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_Off_Min", "2", "The minimum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled.");
	g_hCvarRFL_FlashThreshold_lv2_Off_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_Off_Max", "80", "The maximum interval between each flash of the flashlight light\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv2_On_Min = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_On_Min", "1", "The fastest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");
	g_hCvarRFL_FlashThreshold_lv2_On_Max = CreateConVar("l4d2_RealismFlashLight_FlashThreshold_lv2_On_Max", "14", "The slowest time after the flashlight is turned off to turn on automatically.\n0.1 Second, Int Value.\n0 = Disabled, 1 = Enabled.");

	g_hCvarRFL_ServerTickrate = CreateConVar("l4d2_RealismFlashLight_ServerTickrate", "0", "Server Minimum tickrate, reference value for battery timer.\nInt Value\n0 =Auto, Other Value = Value to Set", CVAR_FLAGS);
	g_hCvarRFL_Debug = CreateConVar("l4d2_RealismFlashLight_Debug", "0", "Enable debug mode?\n0 = Disabled, 1 = Enabled\nIf enabled, If enabled, check chat output when firing.");
	
	g_hCvarRFL_Bot = CreateConVar("l4d2_RealismFlashLight_Bot", "1", "Should the survivor robot's flashlight drain battery?\n1 = Yes, 0 = No\nNo matter what this value is set to, survivor bots will never be able to turn on the flashlight while holding a *disallowed weapon*.");
	g_hCvarRFL_Bot_Buff = CreateConVar("l4d2_RealismFlashLight_Bot_Buff", "4", "If 'l4d2_RealismFlashLight_Bot' has a value of 1, How many server frames must pass before the flashlight power of the survivor robot is consumed by one unit?\nInt Value.");
	g_hCvarRFL_Charge = CreateConVar("l4d2_RealismFlashlight_Charge", "0", "If 'l4d2_RealismFlashLight_PowerEnabled' has a value of 1, Should players be allowed to charge flashlight batteries?\n0 = No, 1 = Yes\nSurvivor bot never recharges flashlight battery.");
	g_hCvarRFL_Charge_Key = CreateConVar("l4d2_RealismFlashlight_Charge_Key", "1", "If the value of 'l4d2_RealismFlashLight_Bot_Buff' is 1, what button is used to charge?\n 0 = Shove only, 1 = Shove + Duck.");
	g_hCvarRFL_Charge_Second = CreateConVar("l4d2_RealismFlashlight_Charge_Second", "1", "If the value of 'l4d2_RealismFlashLight_Bot_Buff' is 1, How much power is charged every time you press it (or hold it every 1.2 seconds)?\nInt Value, Second.");
	g_hCvarRFL_Charge_Hint = CreateConVar("l4d2_RealismFlashlight_Charge_Hint", "1", "Print a message in the chat box if the battery is full?\n0 = No, 1 = Yes");
	//--Get Cvars Value
        g_hCvarRFL_ServerTickrate.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_Debug.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_Enabled.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_AutoFlashlight.AddChangeHook(Event_ConVarChanged);

        g_hCvarRFL_PowerEnabled.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_PowerMin.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_PowerMax.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv0.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv0_Off_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv0_Off_Max.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv0_On_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv0_On_Max.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv1.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv1_Off_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv1_Off_Max.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv1_On_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv1_On_Max.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv2.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv2_Off_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv2_Off_Max.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv2_On_Min.AddChangeHook(Event_ConVarChanged);
        g_hCvarRFL_FlashThreshold_lv2_On_Max.AddChangeHook(Event_ConVarChanged);

	g_hCvarRFL_Bot.AddChangeHook(Event_ConVarChanged);
	g_hCvarRFL_Bot_Buff.AddChangeHook(Event_ConVarChanged);
	g_hCvarRFL_Charge.AddChangeHook(Event_ConVarChanged);
	g_hCvarRFL_Charge_Key.AddChangeHook(Event_ConVarChanged);
	g_hCvarRFL_Charge_Second.AddChangeHook(Event_ConVarChanged);
	g_hCvarRFL_Charge_Hint.AddChangeHook(Event_ConVarChanged);
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarRFL_ServerTickrate = g_hCvarRFL_ServerTickrate.IntValue;
	g_bCvarRFL_Debug = g_hCvarRFL_Debug.BoolValue;
	g_bCvarRFL_Enabled = g_hCvarRFL_Enabled.BoolValue;
  g_bCvarRFL_AutoFlashlight = g_hCvarRFL_AutoFlashlight.BoolValue;

	g_bCvarRFL_PowerEnabled = g_hCvarRFL_PowerEnabled.BoolValue;
	g_iCvarRFL_PowerMin = g_hCvarRFL_PowerMin.IntValue;
	g_iCvarRFL_PowerMax = g_hCvarRFL_PowerMax.IntValue;
	g_fCvarRFL_FlashThreshold_lv0 = g_hCvarRFL_FlashThreshold_lv0.FloatValue;
	g_iCvarRFL_FlashThreshold_lv0_Off_Min = g_hCvarRFL_FlashThreshold_lv0_Off_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv0_Off_Max = g_hCvarRFL_FlashThreshold_lv0_Off_Max.IntValue;
	g_iCvarRFL_FlashThreshold_lv0_On_Min = g_hCvarRFL_FlashThreshold_lv0_On_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv0_On_Max = g_hCvarRFL_FlashThreshold_lv0_On_Max.IntValue;
	g_fCvarRFL_FlashThreshold_lv1 = g_hCvarRFL_FlashThreshold_lv1.FloatValue;
	g_iCvarRFL_FlashThreshold_lv1_Off_Min = g_hCvarRFL_FlashThreshold_lv1_Off_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv1_Off_Max = g_hCvarRFL_FlashThreshold_lv1_Off_Max.IntValue;
	g_iCvarRFL_FlashThreshold_lv1_On_Min = g_hCvarRFL_FlashThreshold_lv1_On_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv1_On_Max = g_hCvarRFL_FlashThreshold_lv1_On_Max.IntValue;
	g_fCvarRFL_FlashThreshold_lv2 = g_hCvarRFL_FlashThreshold_lv2.FloatValue;
	g_iCvarRFL_FlashThreshold_lv2_Off_Min = g_hCvarRFL_FlashThreshold_lv2_Off_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv2_Off_Max = g_hCvarRFL_FlashThreshold_lv2_Off_Max.IntValue;
	g_iCvarRFL_FlashThreshold_lv2_On_Min = g_hCvarRFL_FlashThreshold_lv2_On_Min.IntValue;
	g_iCvarRFL_FlashThreshold_lv2_On_Max = g_hCvarRFL_FlashThreshold_lv2_On_Max.IntValue;
	
	g_bCvarRFL_Bot = g_hCvarRFL_Bot.BoolValue;
	g_iCvarRFL_Bot_Buff = g_hCvarRFL_Bot_Buff.IntValue;
	g_bCvarRFL_Charge = g_hCvarRFL_Charge.BoolValue;
	g_bCvarRFL_Charge_Key = g_hCvarRFL_Charge_Key.BoolValue;
	g_iCvarRFL_Charge_Second = g_hCvarRFL_Charge_Second.IntValue;
	g_bCvarRFL_Charge_Hint = g_hCvarRFL_Charge_Hint.BoolValue;

	if(g_iCvarRFL_ServerTickrate == 0)
		AutoSetTickrate();

	g_iServerTickrateCount = RoundToFloor(float(g_iCvarRFL_ServerTickrate) / 10);
	g_iMaxPower = g_iCvarRFL_ServerTickrate * g_iCvarRFL_PowerMax;
	PrintToServer("\n============Realism Flashlight v%s--Maximum power allow to be set:%d", PLUGIN_VERSION, g_iMaxPower);
}

void AutoSetTickrate()
{
	PrintToServer("\n============Realism Flashlight v%s--Auto Set Tickrate:%d", PLUGIN_VERSION, g_iCvarRFL_ServerTickrate);
	ConVar ServerTickrate = FindConVar("sv_minupdaterate");
	g_iCvarRFL_ServerTickrate = ServerTickrate.IntValue;
	PrintToServer("\n============Realism Flashlight v%s--Auto Set Tickrate:%d", PLUGIN_VERSION, g_iCvarRFL_ServerTickrate);	
}

public void OnPluginStart()
{
	CreateCvars();
	AutoExecConfig(true, "l4d2_RealismFlashlight");

	RegAdminCmd("sm_rfl_view", Command_View, ADMFLAG_ROOT, "arg1:[character]\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2:[any]\nIf value, Messages from this command are visible to all.");
	RegAdminCmd("sm_rfl_set", Command_Set, ADMFLAG_ROOT, "");

	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("finale_win", Event_Finale_Win, EventHookMode_PostNoCopy);
	HookEvent("round_start_post_nav", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	HookEvent("weapon_fire", Event_WeaponFire);
	for(int i = 1; i <= 32; i++)
	{
		if(IS_VALID_SURVIVOR(i) )
			SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	}
}
//--I may need to do this in the "OnPluginStart()" function as well.
public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

Action Command_View (int client, int args) 
{
	char arg1[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	int character = StringToInt(arg1);
	char name[64];
	bool flag = false;
	if(args < 1)
	{
		ReplyToCommand(client, "[SM]Incorrect parameter!\narg1:[character]\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2:[any]\nIf value, Messages from this command are visible to all");
		return Plugin_Handled;
	}
	for(int i = 0; i <= 7; i++)
	{
		if(character == i && g_iflashlightState[i][2] != -1)
		{
			flag = true;
			GetClientName(g_iflashlightState[i][2], name, sizeof(name));
			if(args == 1)
			{
				PrintToChat(client, "\x03+++++ [L4D2 Realism Flashlight v%s] ++++++", PLUGIN_VERSION);
				PrintToChat(client, "Character:%d  Name:%s Userid:%d", i, name, g_iflashlightState[i][2]);
				PrintToChat(client, "\x04Power:%d Percentage:%f FlashlightState:%d", g_iflashlightState[i][1], float(g_iflashlightState[i][1]) / float(g_iCvarRFL_PowerMax * g_iCvarRFL_ServerTickrate), GetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects") );
				PrintToChat(client, "SavedPower:%d FlashTimer:%d FlashlightCheck:%d", g_iflashlightState[i][3], g_iflashlightState[i][4], g_iflashlightState[i][0]);									
			}
			if(args == 2)
			{
				PrintToChatAll("\x03++++++ [L4D2 Realism Flashlight v%s]\x05ChatAll\x03++++++", PLUGIN_VERSION);
				PrintToChatAll("Character:%d  Name:%s Userid:%d", i, name, g_iflashlightState[i][2]);
				PrintToChatAll("\x04Power:%d Percentage:%f FlashlightState:%d", g_iflashlightState[i][1], float(g_iflashlightState[i][1]) / float(g_iCvarRFL_PowerMax * g_iCvarRFL_ServerTickrate), GetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects") );
				PrintToChatAll("SavedPower:%d FlashTimer:%d FlashlightCheck:%d", g_iflashlightState[i][3], g_iflashlightState[i][4], g_iflashlightState[i][0]);							
			}
		}
	}
	if(!flag)
		ReplyToCommand(client, "[SM]No client found!\narg1:[character]\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2:[any]\nIf value, Messages from this command are visible to all");

	return Plugin_Handled;
}

Action Command_Set (int client, int args)
{
	if(!(args == 2) )
	{
		ReplyToCommand(client, "[SM]Incorrect parameter!\narg1: target\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2: Value to set(0 ~ value of cvar 'l4d2_RealismFlashLight_PowerMax')");
		return Plugin_Handled;
	}

	char arg2[8];
	GetCmdArg(2, arg2, sizeof(arg2));
	int value = StringToInt(arg2);
	if(value < 0 || value > g_iCvarRFL_PowerMax)
	{
		ReplyToCommand(client, "[SM]Incorrect parameter!\narg1: target\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2: Value to set(0 ~ value of cvar 'l4d2_RealismFlashLight_PowerMax')");
		return Plugin_Handled;		
	}

	char arg1[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target =  StringToInt(arg1);
	char name[64];
	for(int i = 0; i<= 7; i++)
	{
		if(target == i && g_iflashlightState[i][2] != -1)
		{
			GetClientName(g_iflashlightState[i][2], name, sizeof(name));
//			PrintToConsole(client,"[L4d2 Realism Flashlight v%s] Flashlight battery level for client\x05 '%s'\x01 has been set from\0x5 '%d'\0x1 to\0x5 '%d'\0x1(imprecise)!", PLUGIN_VERSION, name, g_iflashlightState[i][1], value);
//			PrintToChatAll("[L4d2 Realism Flashlight v%s] Flashlight battery level for client\x05 '%s'\x01 has been set from\0x5 '%d'\0x1 to\0x5 '%d'\0x1(imprecise)!", PLUGIN_VERSION, name, g_iflashlightState[i][1], value);
			//--I've tried a few things but still can't get the above code to work.
			PrintToConsole(client,"\x05[L4d2 Realism Flashlight v%s] Flashlight battery level for client *%s* has been set from %d to %d(imprecise)!", PLUGIN_VERSION, name, g_iflashlightState[i][1], value);
			PrintToChatAll("\x05[L4d2 Realism Flashlight v%s] Flashlight battery level for client *%s* has been set from %d to %d(imprecise)!", PLUGIN_VERSION, name, g_iflashlightState[i][1], value);

			g_iflashlightState[i][1] = value * g_iCvarRFL_ServerTickrate;
			if(g_iflashlightState[i][0] == -1)
				g_iflashlightState[i][0] = 0;

			return Plugin_Handled;
		}
	}
	ReplyToCommand(client, "[SM]No client found!\narg1: target\nl4d1:0~3(BZFL) l4d2:4~7(NRCE)\narg2: Value to set(0 ~ value of cvar 'l4d2_RealismFlashLight_PowerMax')");
	return Plugin_Handled;
}
//======================================================================================================================================================================================================
//Transition,Conversion,Initialization.
//======================================================================================================================================================================================================
//--Map Vote Change
public void OnMapEnd()
{
	if(!g_bInSafeRoom && !g_bAllowSetPower)
	{

		for(int i = 0; i <= 7; i++)
		{
			//
			g_iflashlightState[i][0] = -1;
			g_iflashlightState[i][1] = -1;
			g_iflashlightState[i][2] = -1;
			g_iflashlightState[i][3] = -1;
			g_iflashlightState[i][4] = -1;
			//
			//hava someting....
		//	g_iflashlightState[i][1] = g_iflashlightState[i][3];
			
		}
		SetClientFlashLight();
		PrintToServer("===========================\n OnMapEnd: ReSet List && SetClientFlashLight\n----------------------------------");				
	}
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("=======================\nMapTransitionPre, ReSet Power Value, g_bAllow Set to false,  g_bInSafeRoom Set to true\n-------------------------");
	g_bAllow = false;
	for(int i = 0; i <= 7; i++)
	{
		g_iflashlightState[i][3] = g_iflashlightState[i][1];
	}
	g_bInSafeRoom = true;
}
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bInSafeRoom)
	{
		g_bAllow = true;
		g_bInSafeRoom = false;
		PrintToServer("---\nRound Start: InSafeRoom = false\n===");
	}
}	

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("=======================\nRoundEndPost, ReSet Power Value\n-------------------------")
	for(int i = 0; i <= 7; i++)
	{
		g_iflashlightState[i][1] = g_iflashlightState[i][3];
		if(g_iflashlightState[i][3] > 0)
			g_iflashlightState[i][0] = 0;
	}
}

public void OnConfigsExecuted()
{
	GetCvars();

	if(!g_bAllowSetPower)
		return;
	PrintToServer("===========================\nAll Flag Set to False, ReSet List, g_bAllowSetPower Set to false && SetClientFlashLight\n----------------------------------");
	for(int i = 0; i <= 7; i++)
	{
		g_iflashlightState[i][0] = -1;
		g_iflashlightState[i][1] = -1;
		g_iflashlightState[i][2] = -1;
		g_iflashlightState[i][3] = -1;
		g_iflashlightState[i][4] = -1;
	}
	SetClientFlashLight();
	g_bAllowSetPower = false;	
}

void Event_Finale_Win(Event event, const char[] name, bool dontBroadcast)
{
	g_bAllowSetPower = true;
}

void SetClientFlashLight()
{
	for(int i = 0; i <= 7; i++)
	{
		g_iflashlightState[i][0] = 0;
		g_iflashlightState[i][1] = GetRandomInt(g_iCvarRFL_PowerMin * g_iCvarRFL_ServerTickrate,  g_iCvarRFL_PowerMax * g_iCvarRFL_ServerTickrate);	
		g_iflashlightState[i][3] = g_iflashlightState[i][1];
		PrintToServer("l4d2_RealismFlashlight: %d# PowerSetTo %d", i, g_iflashlightState[i][1]);				
	}
	//--It might be better to turn off the flashlight when changing maps or at the end of a round.
//	SetEntProp(client, Prop_Send, "m_fEffects", 0);

	g_bAllow = true;
}
//======================================================================================================================================================================================================
public void OnGameFrame()
{
	if(!g_bAllow || !g_bCvarRFL_Enabled)
		return;

	static float fPower = 0.00;
	static int iRandomTime_Off[8];
	static int iRandomTime_On[8];
	static int iSkip[8];
	static int iCharge;
	//--Check the actual correspondence between character and clients.
	for(int i = 0; i <= 7; i++)
	{
		for(int p = 0; p < 32; p++)
		{
			if(IS_SURVIVOR_ALIVE(p) )
			{
				if(GetEntProp(p, Prop_Send, "m_survivorCharacter") == i)
				{
					g_iflashlightState[i][2] = p;
				}
			}
		}

		if(!IsValidEntity(g_iflashlightState[i][2]) || (!g_bCvarRFL_Bot && IsFakeClient(g_iflashlightState[i][2])) || g_iflashlightState[i][2] == -1)
			continue;
		//--Charge.
		if(g_bKeyState[i] && g_bCvarRFL_Charge && g_bCvarRFL_PowerEnabled)
		{
			iCharge = g_iflashlightState[i][1] + (g_iCvarRFL_ServerTickrate * g_iCvarRFL_Charge_Second);
			if(iCharge > g_iMaxPower)
			{
				g_iflashlightState[i][1] = g_iMaxPower;
				if(g_bCvarRFL_Charge_Hint)
					PrintToChat(g_iflashlightState[i][2], "\x04[L4d2 Realism Flashlight v%s] The battery is already fully charged!", PLUGIN_VERSION);
			}
			else	g_iflashlightState[i][1] = iCharge;

			g_bKeyState[i] = false;

			//--Due to the way this version of the plugin (v1.2) works, there is no longer an uninitialized battery.
			if(g_iflashlightState[i][0] == -1)
				g_iflashlightState[i][0] = 0;
		}

		//--Here is the code to turn off the flashlight.
		if(g_iflashlightState[i][0] != 0)
		{
			SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 0);
	
			if(g_iflashlightState[i][0] != 2)
				continue;
		}
		//--Make sure the flashlight is not automatically turned on when it is not turned on.
		if(g_bCvarRFL_PowerEnabled && (GetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects") == 4 || g_iflashlightState[i][0] == 2) )
		{	
			fPower = float(g_iflashlightState[i][1]) / float(g_iCvarRFL_PowerMax * g_iCvarRFL_ServerTickrate);
			//--Control the blinking of the flashlight.
			if(fPower < g_fCvarRFL_FlashThreshold_lv2)
			{
				g_iflashlightState[i][4]++;
				if(g_iflashlightState[i][0] == 2)
				{
					if(iRandomTime_On[i] == 0)
						iRandomTime_On[i] =  (GetRandomInt(g_iCvarRFL_FlashThreshold_lv2_On_Min, g_iCvarRFL_FlashThreshold_lv2_On_Max) * g_iServerTickrateCount);
				
					if(g_iflashlightState[i][4] > (iRandomTime_Off[i] + iRandomTime_On[i]))
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 4);
						g_iflashlightState[i][0] = 0;
						g_iflashlightState[i][4] = 0;
						iRandomTime_On[i] = 0;
						iRandomTime_Off[i] = 0;
					}
				}
				if(g_iflashlightState[i][0] == 0)
				{
					if(iRandomTime_Off[i] == 0)
						iRandomTime_Off[i] = (GetRandomInt(g_iCvarRFL_FlashThreshold_lv2_Off_Min, g_iCvarRFL_FlashThreshold_lv2_Off_Max) * g_iServerTickrateCount);
					if(g_iflashlightState[i][4] > iRandomTime_Off[i])
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 0);
						g_iflashlightState[i][0] = 2;	
					}
				}
			}
			else	if(fPower < g_fCvarRFL_FlashThreshold_lv1)
			{
				g_iflashlightState[i][4]++;
				if(g_iflashlightState[i][0] == 2)
				{
					if(iRandomTime_On[i] == 0)
						iRandomTime_On[i] =  (GetRandomInt(g_iCvarRFL_FlashThreshold_lv1_On_Min, g_iCvarRFL_FlashThreshold_lv1_On_Max) * g_iServerTickrateCount);
				
					if(g_iflashlightState[i][4] > (iRandomTime_Off[i] + iRandomTime_On[i]))
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 4);
						g_iflashlightState[i][0] = 0;
						g_iflashlightState[i][4] = 0;
						iRandomTime_On[i] = 0;
						iRandomTime_Off[i] = 0;
					}
				}
				if(g_iflashlightState[i][0] == 0)
				{
					if(iRandomTime_Off[i] == 0)
						iRandomTime_Off[i] = (GetRandomInt(g_iCvarRFL_FlashThreshold_lv1_Off_Min, g_iCvarRFL_FlashThreshold_lv1_Off_Max) * g_iServerTickrateCount);
					if(g_iflashlightState[i][4] > iRandomTime_Off[i])
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 0);
						g_iflashlightState[i][0] = 2;	
					}
				}
			}
			else	if(fPower < g_fCvarRFL_FlashThreshold_lv0)
			{
				g_iflashlightState[i][4]++;
				if(g_iflashlightState[i][0] == 2)
				{
					if(iRandomTime_On[i] == 0)
						iRandomTime_On[i] =  (GetRandomInt(g_iCvarRFL_FlashThreshold_lv0_On_Min, g_iCvarRFL_FlashThreshold_lv0_On_Max) * g_iServerTickrateCount);
				
					if(g_iflashlightState[i][4] > (iRandomTime_Off[i] + iRandomTime_On[i]))
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 4);
						g_iflashlightState[i][0] = 0;
						g_iflashlightState[i][4] = 0;
						iRandomTime_On[i] = 0;
						iRandomTime_Off[i] = 0;
					}
				}
				if(g_iflashlightState[i][0] == 0)
				{
					if(iRandomTime_Off[i] == 0)
						iRandomTime_Off[i] = (GetRandomInt(g_iCvarRFL_FlashThreshold_lv0_Off_Min, g_iCvarRFL_FlashThreshold_lv0_Off_Max) * g_iServerTickrateCount);
					if(g_iflashlightState[i][4] > iRandomTime_Off[i])
					{
						SetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects", 0);
						g_iflashlightState[i][0] = 2;	
					}
				}
			}
		
			if(g_iflashlightState[i][1] <= 0)
			{
				g_iflashlightState[i][0] = -1;
			}
			//--Control how fast your flashlight battery drains.
			if(g_iflashlightState[i][1] > 0 && GetEntProp(g_iflashlightState[i][2], Prop_Send, "m_fEffects") == 4)
			{
				if(IsFakeClient(g_iflashlightState[i][2]) )
				{
					iSkip[i]++;
					//--Reset the value when "g_hCvarRFL_Bot_Buff" changes, to prevent the bot's battery from never decreasing again.
					if(iSkip[i] > g_iCvarRFL_Bot_Buff)
						iSkip[i] = 0;
					if(iSkip[i] == g_iCvarRFL_Bot_Buff)
					{
						g_iflashlightState[i][1]--;
						iSkip[i] = 0;
					}		
				}	
				else	g_iflashlightState[i][1]--;
			}
		}
	}
}

static bool bTimer[8];
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!g_bCvarRFL_Charge || !g_bCvarRFL_PowerEnabled || !IS_SURVIVOR_ALIVE(client) )
		return Plugin_Continue;
	
	int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if(bTimer[character])
		return Plugin_Continue;
	
	if(g_bCvarRFL_Charge_Key)
	{
		if(buttons & IN_ATTACK2 && buttons & IN_DUCK)
		{
			g_bKeyState[character] = true;	
			bTimer[character] = true;
			CreateTimer(1.2, tResetDelay, character)
		}
//		else	g_bKeyState[character] = false;
		return Plugin_Continue;
	}
	if(buttons & IN_ATTACK2)
	{
		g_bKeyState[character] = true;  
		bTimer[character] = true;
		CreateTimer(1.2, tResetDelay, character)			
	}
//	else	g_bKeyState[character] = false;
	return Plugin_Continue;
}
//--Prevents charging the battery too quickly.
Action tResetDelay(Handle timer, any icharacter)
{
	bTimer[icharacter] = false;
	return Plugin_Continue;
}
void OnWeaponSwitchPost(client, weapon)
{
	int client_count = RFL_GetClientCount(client);
	if(!g_bCvarRFL_Enabled || client_count == -1)
		return;
	if(!g_bAllow)
		return;

	if(g_iflashlightState[client_count][0] != 0 && g_iflashlightState[client_count][0] == -1 )
		return;

	bool Allow = false;
	if(GetClientTeam(client) == 2)	
	{
		char weapon_name[32];
		GetClientWeapon(client, weapon_name, sizeof(weapon_name));	
		for(int i = 0; i < 19; i ++)
		{
			if (strcmp(g_sHavaFlashlight_WeaponList[i], weapon_name) == 0)
			{
				Allow = true;
				if(g_iflashlightState[client_count][0] == 2)
					break;
        if(g_bCvarRFL_AutoFlashlight)
        {
          bool state = GetEntProp(client, Prop_Send, "m_fEffects") ? true : false;
          if(g_bHavaFlashlightWeapon_FlashLightOn[client_count] && !state)
            SetEntProp(client, Prop_Send, "m_fEffects", 4);
        
          g_bHavaFlashlightWeapon_FlashLightOn[client_count] = state;
        }
        g_iflashlightState[client_count][0] = 0;
				break;
			}
		}
	}
	if(!Allow)
	{
			//--When the flashlight is blinking (off)
			if(g_iflashlightState[client_count][0] == 2)
			{
				g_iflashlightState[client_count][0] = -2;
				return;
			}
      if(g_bCvarRFL_AutoFlashlight)  g_bHavaFlashlightWeapon_FlashLightOn[client_count] = GetEntProp(client, Prop_Send, "m_fEffects") ? true : false;

      SetEntProp(client, Prop_Send, "m_fEffects", 0);
			//--Turn off the flashlight.
			g_iflashlightState[client_count][0] = 1;			
	}
}

int RFL_GetClientCount(int client)
{
	for(int i = 0; i <= 7; i++)
	{
		if(g_iflashlightState[i][2] == client)
		{
			if(!g_bCvarRFL_Bot && IsFakeClient(client) )
				return -1;
			else	return i;
		}
	}
	return -1;
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bCvarRFL_Debug)
		return;
	int index = GetEventInt(event, "userid");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int count = -1024;
	if(GetClientTeam(client) == 2)
	{
		for(int i = 0; i <= 7; i++)
		{	
			if(g_iflashlightState[i][2] ==  client)
			{
				count = i;
			}
		}
		if(count == -1024)
		{
			PrintToChatAll("Client Not Found!");
			return;
		}
		PrintToChatAll("--++--\nIndex:%d, Id:%d, Character:%d,Flashlight_status:%d,Power:%d Saved_id:%d,Saved_power:%d, Flash_Timer:%d",index,client,count,g_iflashlightState[count][0],g_iflashlightState[count][1],g_iflashlightState[count][2],g_iflashlightState[count][3],g_iflashlightState[count][4]);
		PrintToChatAll("Offset:%d, Power_percentage:%f, Count:%d",GetEntProp(g_iflashlightState[count][2], Prop_Send, "m_fEffects"), float(g_iflashlightState[count][1]) / float(g_iCvarRFL_PowerMax * g_iCvarRFL_ServerTickrate), count );
	}
}

int Native_GetStatus(Handle plugin, int numParams)
{
	int character = GetNativeCell(1);
	int index = GetNativeCell(2);

	return g_iflashlightState[character][index];
}
