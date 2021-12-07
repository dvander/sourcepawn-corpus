#define PLUGIN_VERSION "1.0"
public Plugin myinfo = 
{
	name = "FOV+", 
	version = PLUGIN_VERSION, 
	description = "Allow custom FOV in HL2DM", 
	author = "Ribas (mod from harper's FOV Extended')", 
	url = "http://oppressiveterritory.ddns.net"
};

#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_PLUGIN

#pragma newdecls required

/******************************************************************/

#define FIRSTPERSON 4
enum( += 1) { ZOOM_NONE = 0, ZOOM_XBOW, ZOOM_SUIT, ZOOM_TOGL }

int Zoom[MAXPLAYERS + 1];

ConVar MinimumFOV, DefaultFOV, MaximumFOV;

Handle FovCookie;

/******************************************************************/

public void OnPluginStart()
{
	FovCookie = RegClientCookie("hl2dm_fov", "Field-of-view value", CookieAccess_Public);
	MinimumFOV = CreateConVar("sm_fov_min", "90", "Minimum client FOV");
	DefaultFOV = CreateConVar("sm_fov_default", "95", "Default HL2DM's FOV of players");
	MaximumFOV = CreateConVar("sm_fov_max", "130", "Max client FOV");
	AutoExecConfig(true, "sm_fov");
	
	RegConsoleCmd("sm_fov", Command_FOV, "Set your desired field-of-view value");
	AddCommandListener(OnClientChangeFOV, "fov");
	AddCommandListener(OnClientToggleZoom, "toggle_zoom");
}


public Action Command_FOV(int client, int args) {
	RequestFOV(client, GetCmdArgInt(1));
}

public Action OnClientChangeFOV(int client, const char[] command, int args)
{
    RequestFOV(client, GetCmdArgInt(1));
}

public Action OnClientToggleZoom(int client, const char[] command, int args)
{
	if (Zoom[client] != ZOOM_NONE) {
		if (Zoom[client] == ZOOM_TOGL || Zoom[client] == ZOOM_SUIT) {
			Zoom[client] = ZOOM_NONE;
		}
	}
	else {
		Zoom[client] = ZOOM_TOGL;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (AreClientCookiesCached(client))
	{
		static int lastbuttons[MAXPLAYERS + 1];
		
		int fov = GetClientCookieInt(client, FovCookie);
		
		if (fov < GetConVarInt(MinimumFOV) || fov > GetConVarInt(MaximumFOV)) {
			// fov is out of bounds, reset
			fov = GetConVarInt(DefaultFOV);
		}
		
		if (!IsClientObserver(client) && IsPlayerAlive(client))
		{
			char sWeapon[32];
			
			GetClientWeapon(client, sWeapon, sizeof(sWeapon));
			
			if (Zoom[client] == ZOOM_XBOW || Zoom[client] == ZOOM_TOGL) {
				// block suit zoom while xbow/toggle-zoomed
				buttons &= ~IN_ZOOM;
			}
			
			if (Zoom[client] == ZOOM_TOGL)
			{
				if (StrEqual(sWeapon, "weapon_crossbow")) {
					// block xbow zoom while toggle zoomed
					buttons &= ~IN_ATTACK2;
				}
				
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
				return Plugin_Continue;
			}
			
			if (buttons & IN_ZOOM)
			{
				if (!(lastbuttons[client] & IN_ZOOM) && !Zoom[client]) {
					// suit zooming
					Zoom[client] = ZOOM_SUIT;
				}
			}
			else if (Zoom[client] == ZOOM_SUIT) {
				// no longer suit zooming
				Zoom[client] = ZOOM_NONE;
			}
			
			if ((StrEqual(sWeapon, "weapon_crossbow") && (buttons & IN_ATTACK2) && !(lastbuttons[client] & IN_ATTACK2))
				 || (!StrEqual(sWeapon, "weapon_crossbow") && Zoom[client] == ZOOM_XBOW)
				) {
				// xbow zoom cycle
				Zoom[client] = Zoom[client] == ZOOM_XBOW ? ZOOM_NONE : ZOOM_XBOW;
			}
		} else {
			Zoom[client] = ZOOM_NONE;
		}
		
		// set values
		if (Zoom[client] || (IsClientObserver(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == FIRSTPERSON)) {
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		}
		else if (Zoom[client] == ZOOM_NONE) {
			SetEntProp(client, Prop_Send, "m_iFOV", fov);
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);
		}
		
		lastbuttons[client] = buttons;
	}
	
	return Plugin_Continue;
}

void RequestFOV(int client, int fov)
{
	if (fov < GetConVarInt(MinimumFOV) || fov > GetConVarInt(MaximumFOV)) {
	SetHudTextParams(0.1, 0.55, 5.0, 255, 20, 0, 255, 2, 0.05, 0.02, 0.02);
	ShowHudText(client, 7, "FOV must be a number between %i and %i", GetConVarInt(MinimumFOV), GetConVarInt(MaximumFOV));
	SetHudTextParams(0.1, 0.58, 5.0, 255, 20, 0, 255, 2, 0.05, 0.02, 0.02);
	ShowHudText(client, 8, "(default is %i).",GetConVarInt(DefaultFOV));
	}
	else {
	SetHudTextParams(0.1, 0.55, 5.0, 0, 100, 255, 255, 2, 0.05, 0.02, 0.02);
	ShowHudText(client, 7, "Your FOV is now %i.", fov);
	SetClientCookieInt(client, FovCookie, fov);
		}
}

int GetClientCookieInt(int client, Handle cookie)
{
	char sValue[256];
	GetClientCookie(client, cookie, sValue, sizeof(sValue));
	return (StringToInt(sValue));
}

void SetClientCookieInt(int client, Handle cookie, int value)
{
	char sValue[256];
	IntToString(value, sValue, sizeof(sValue));
	SetClientCookie(client, cookie, sValue);
}

int GetCmdArgInt(int arg)
{
	char buffer[192];
	GetCmdArg(arg, buffer, sizeof(buffer));
	return (StringToInt(buffer));
} 