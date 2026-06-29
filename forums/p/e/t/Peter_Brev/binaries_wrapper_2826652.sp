/******************************
COMPILE OPTIONS
******************************/
#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/
#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <smlib>
#include <jhl2dm>

/******************************
DEFINES
******************************/
#define ZOOM_NONE	0
#define ZOOM_XBOW	1
#define ZOOM_SUIT	2
#define ZOOM_TOGL	3
#define FIRSTPERSON 4

/******************************
ENUMERATIONS
******************************/
enum struct _gConVar
{
	ConVar sv_tags;
	ConVar xfov_minfov;
	ConVar xfov_defaultfov;
	ConVar xfov_maxfov;

	ConVar g_cTimeleftEnable;
	ConVar g_cTimeleftX;
	ConVar g_cTimeleftY;
	ConVar g_cTimeleftR;
	ConVar g_cTimeleftG;
	ConVar g_cTimeleftB;
	ConVar g_cTimeleftI;

	ConVar fps_max_check;
	ConVar fps_max_min_required;
	ConVar fps_max_max_required;
}
_gConVar gConVar;

/******************************
INTEGERS
******************************/
int		 giZoom[MAXPLAYERS + 1];

/******************************
HANDLES
******************************/
Handle	 gcFov,
	hHUD;

/******************************
PLUGIN INFO
******************************/
/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "HL2MP - Utilities",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "HL2MP Utilities",
	PL_VERSION[]	 = "1.1.0";

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
Purpose: When the plugin starts
******************************/
public void OnPluginStart()
{
	gcFov						 = RegClientCookie("hl2dm_fov", "Field-of-view value", CookieAccess_Public);

	gConVar.xfov_minfov			 = CreateConVar("fov_min", "70", "Minimum FOV allowed on server");
	gConVar.xfov_defaultfov		 = CreateConVar("fov_default", "90", "Default FOV of players on server");
	gConVar.xfov_maxfov			 = CreateConVar("fov_maxfov", "110", "Maximum FOV allowed on server");

	gConVar.g_cTimeleftEnable	 = CreateConVar("sm_timeleft_hud_enable", "0", "Enable timeleft to show on HUD", 0, true, 0.0, true, 1.0);
	gConVar.g_cTimeleftX		 = CreateConVar("sm_timeleft_x", "-1.0", "Position the HUD's timeleft on the X axis");
	gConVar.g_cTimeleftY		 = CreateConVar("sm_timeleft_y", "0.01", "Position the HUD's timeleft on the y axis");
	gConVar.g_cTimeleftR		 = CreateConVar("sm_timeleft_r", "255", "Red color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftG		 = CreateConVar("sm_timeleft_g", "220", "Green color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftB		 = CreateConVar("sm_timeleft_b", "0", "Blue color intensity of the HUD's timeleft", 0, true, 0.0, true, 255.0);
	gConVar.g_cTimeleftI		 = CreateConVar("sm_timeleft_i", "255", "Amount of transparency of the HUD's timeleft", 0, true, 0.0, true, 255.0);

	gConVar.fps_max_check		 = CreateConVar("sm_fps_max_check", "1", "Enable/Disable the checking of client's fps_max value", 0, true, 0.0, true, 1.0);
	gConVar.fps_max_min_required = CreateConVar("sm_fps_min", "60", "Minimum value that a client needs to set their fps_max at", 0, true, 10.0);
	gConVar.fps_max_max_required = CreateConVar("sm_fps_max", "1000", "Maximum value that a client needs to set their fps_max at", 0, true, 60.0);

	AutoExecConfig();

	RegConsoleCmd("fov", Command_FOV, "Set your desired field-of-view value");
	AddCommandListener(OnClientToggleZoom, "toggle_zoom");

	HookConVarChange(gConVar.g_cTimeleftEnable, OnConVarChanged_HudTimeleft);
}

/******************************
Purpose: Controls player FOV
******************************/
public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponSwitchPost, OnClientSwitchWeapon);

	if (GetConVarBool(gConVar.fps_max_check))
		QueryClientConVar(iClient, "fps_max", q_fpsmax);
}

public Action Command_FOV(int iClient, int iArgs)
{
	if (!iArgs)
	{
		int iMyFov = GetEntProp(iClient, Prop_Send, "m_iDefaultFOV");
		ReplyToCommand(iClient, "Usage: FOV <value> (Min: %d - Max: %d)\nYour FOV is %d.",
					   GetConVarInt(gConVar.xfov_minfov),
					   GetConVarInt(gConVar.xfov_maxfov),
					   iMyFov);

		return Plugin_Handled;
	}

	RequestFOV(iClient, GetCmdArgInt(1));

	return Plugin_Handled;
}

void RequestFOV(int iClient, int iFov)
{
	if (iFov < GetConVarInt(gConVar.xfov_minfov) || iFov > GetConVarInt(gConVar.xfov_maxfov))
	{
		ReplyToCommand(iClient, "Your FOV must be between %d and %d.", GetConVarInt(gConVar.xfov_minfov), GetConVarInt(gConVar.xfov_maxfov));
	}
	else
	{
		SetClientCookieInt(iClient, gcFov, iFov);
		ReplyToCommand(iClient, "Your FOV is set to %d.", iFov);
	}
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon)
{
	if (AreClientCookiesCached(iClient))
	{
		static int iLastButtons[MAXPLAYERS + 1];

		int		   iFov = GetClientCookieInt(iClient, gcFov);

		if (iFov < GetConVarInt(gConVar.xfov_minfov) || iFov > GetConVarInt(gConVar.xfov_maxfov))
		{
			// fov is out of bounds, reset
			iFov = GetConVarInt(gConVar.xfov_defaultfov);
		}

		if (!IsClientObserver(iClient) && IsPlayerAlive(iClient))
		{
			char sWeapon[32];

			GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));

			if (giZoom[iClient] == ZOOM_XBOW || giZoom[iClient] == ZOOM_TOGL)
			{
				// block suit zoom while xbow/toggle-zoomed
				iButtons &= ~IN_ZOOM;
			}

			if (giZoom[iClient] == ZOOM_TOGL)
			{
				if (StrEqual(sWeapon, "weapon_crossbow"))
				{
					// block xbow zoom while toggle zoomed
					iButtons &= ~IN_ATTACK2;
				}

				SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 90);
				return Plugin_Continue;
			}

			if (iButtons & IN_ZOOM)
			{
				if (!(iLastButtons[iClient] & IN_ZOOM) && !giZoom[iClient])
				{
					// suit zooming
					giZoom[iClient] = ZOOM_SUIT;
				}
			}
			else if (giZoom[iClient] == ZOOM_SUIT) {
				// no longer suit zooming
				giZoom[iClient] = ZOOM_NONE;
			}

			if ((StrEqual(sWeapon, "weapon_crossbow") && (iButtons & IN_ATTACK2) && !(iLastButtons[iClient] & IN_ATTACK2)) || (!StrEqual(sWeapon, "weapon_crossbow") && giZoom[iClient] == ZOOM_XBOW))
			{
				// xbow zoom cycle
				giZoom[iClient] = (giZoom[iClient] == ZOOM_XBOW ? ZOOM_NONE : ZOOM_XBOW);
			}
		}
		else {
			giZoom[iClient] = ZOOM_NONE;
		}

		// set values
		if (giZoom[iClient] || (IsClientObserver(iClient) && GetEntProp(iClient, Prop_Send, "m_iObserverMode") == FIRSTPERSON))
		{
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 90);
		}
		else if (giZoom[iClient] == ZOOM_NONE) {
			SetEntProp(iClient, Prop_Send, "m_iFOV", iFov);
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFov);
		}

		iLastButtons[iClient] = iButtons;
	}

	return Plugin_Continue;
}

public Action OnClientToggleZoom(int iClient, const char[] sCommand, int iArgs)
{
	if (giZoom[iClient] != ZOOM_NONE)
	{
		if (giZoom[iClient] == ZOOM_TOGL || giZoom[iClient] == ZOOM_SUIT)
		{
			giZoom[iClient] = ZOOM_NONE;
		}
	}
	else {
		giZoom[iClient] = ZOOM_TOGL;
	}

	return Plugin_Continue;
}

public Action OnClientSwitchWeapon(int iClient, int iWeapon)
{
	if (giZoom[iClient] == ZOOM_TOGL)
	{
		giZoom[iClient] = ZOOM_NONE;
	}

	return Plugin_Continue;
}

/******************************
Purpose: Timeleft on the HUD
NOTE: Timeleft is broken to some extent with Sourcemod in a way where time limit is not reset on mp_gamerestart.
Some servers may benefit from that with certain game modes, but for servers that need proper reset,
use Adrian's SM extension: https://github.com/Adrianilloo/sm_hl2dm_ext or do not use SM's chat triggers for this.
Please note that the time limit properly gets reset by default internally with the game/binaries.
THIS IS ONLY A SOURCEMOD ISSUE!

The following is only for those who benefit from that bug (deathrun, minigame, etc.).
******************************/
public void OnMapStart()
{
	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 1)
		CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	if (GetConVarInt(gConVar.fps_max_check) == 1)
		if (GetConVarInt(gConVar.fps_max_min_required) > GetConVarInt(gConVar.fps_max_max_required))	// in theory, this shouldn't be required, but this is just a safety net
		{
			// set back to default
			SetConVarInt(gConVar.fps_max_min_required, 10);
			SetConVarInt(gConVar.fps_max_max_required, 60);
		}
}

void q_fpsmax(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	if (result != ConVarQuery_Okay)
	{
		KickClient(client, "Client command query \"fps_max\" failed. Reconnect.");
		return;
	}

	int cvar = StringToInt(cvarValue);

	if (cvar < GetConVarInt(gConVar.fps_max_min_required) || cvar > GetConVarInt(gConVar.fps_max_max_required))
	{
		KickClient(client, "This server requires your \"fps_max\" value to be set between %d and %d. Your value: %d",
				   GetConVarInt(gConVar.fps_max_min_required), GetConVarInt(gConVar.fps_max_max_required), cvar);
		PrintToChatAll("\x01Player \x0700BFFF%N \x01kicked due to illegal fps_max value (Queried: \x05fps_max %d\x01).", client, cvar);
	}

	return;
}

public void OnConVarChanged_HudTimeleft(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 1)
		CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Countdown(Handle timer, any data)
{
	if (GetConVarInt(gConVar.g_cTimeleftEnable) == 0)
		return Plugin_Stop;

	static int time;
	GetMapTimeLeft(time);
	if (time < 1)
		return Plugin_Continue;

	static char left[32];
	if (time > 3599)
		FormatEx(left, sizeof(left), "%ih %02im", time / 3600, (time / 60) % 60);
	else if (time > 59)
		FormatEx(left, sizeof(left), "%i%c%02i", time / 60, time % 2 ? '.' : ':', time % 60);
	else FormatEx(left, sizeof(left), "%02i", time);

	if (!hHUD) hHUD = CreateHudSynchronizer();

	float x		  = GetConVarFloat(gConVar.g_cTimeleftX),
		  y		  = GetConVarFloat(gConVar.g_cTimeleftY);
	int red		  = GetConVarInt(gConVar.g_cTimeleftR),
		green	  = GetConVarInt(gConVar.g_cTimeleftG),
		blue	  = GetConVarInt(gConVar.g_cTimeleftB),
		intensity = GetConVarInt(gConVar.g_cTimeleftI);

	SetHudTextParams(x, y, 1.10, red, green, blue, intensity, 0, 0.0, 0.0, 0.0);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i)) ShowSyncHudText(i, hHUD, left);

	return Plugin_Continue;
}