#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>

static const float
	MULT[] =
{	// https://developer.valvesoftware.com/wiki/Dimensions
	1.0,		// units/s
	0.01905,	// meters/s
	0.06858,	// kilometers/h
	0.04261364	// miles/h
};

static const char
	PL_NAME[]	= "Speed",
	PL_VER[]	= "1.0.1 01.07.2022",
	UNIT[][] =
{
	"u/s",
	"m/s",
	"km/h",
	"mph"
};

Handle
	hCookies,
	hTimer,
	hHUD;
bool
	bLate,
	bVertical,
	bShow[MAXPLAYERS+1];
int
	iUnit,
	iColor;
float
	fCD,
	fPosX,
	fPosY;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "The plugin shows the player in the HUD his current speed",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	if(!(hHUD = CreateHudSynchronizer())) SetFailState("Can't create HUD");

	CreateConVar("sm_speed_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_speed_update", "0.5", "Speed ​​information refresh rate. 0 - disabled", _, true, _, true, 5.0);
	cvar.AddChangeHook(CVarChanged_CD);
	fCD = cvar.FloatValue;

	cvar = CreateConVar("sm_speed_unit", "1", "0 - units/s, 1 - meters/s, 2 - kilometers/h, 3 - miles/h", _, true, _, true, 3.0);
	cvar.AddChangeHook(CVarChanged_Unit);
	iUnit = cvar.IntValue;

	cvar = CreateConVar("sm_speed_vertical", "0", "Take into account the vertical component of the velocity", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Vertical);
	bVertical = cvar.BoolValue;

	cvar = CreateConVar("sm_speed_color", "007fffff", "HUD info color. Set by HEX (RGB, RGBA, RRGGBB or RRGGBBAA, values 0 - F or 00 - FF, resp.). Wrong color code = white", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Color);
	CVarChanged_Color(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_speed_x", "-1.0", "Position from left to right (-1.0 - center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosX);
	fPosX = cvar.FloatValue;

	cvar = CreateConVar("sm_speed_y", "0.9", "Position from top to bottom (-1.0 - center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosY);
	fPosY = cvar.FloatValue;

	AutoExecConfig(true, "sm_speed");

	hCookies = RegClientCookie("sm_speed", "Show speedometer", CookieAccess_Private);
	SetCookieMenuItem(Cookie_Speedometer, 0, PL_NAME);

	if(!bLate) return;

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		if(!AreClientCookiesCached(i))
			bShow[i] = true;
		else GetCookieValue(i);
	}
}

public void CVarChanged_CD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fCD = cvar.FloatValue;
	OnMapEnd();
	OnMapStart();
}

public void CVarChanged_Unit(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iUnit = cvar.IntValue;
}

public void CVarChanged_Vertical(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bVertical = cvar.BoolValue;
}

public void CVarChanged_Color(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char clr[12];
	cvar.GetString(clr, sizeof(clr));
	clr[9] = 0;	// чтобы проверялось максимум 7 первых символов

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{	// не HEX-число
			iColor = -1;	// невалидный цвет => 0xFFFFFFFF
			LogError("HEX color '%s' isn't valid! HUD color is 0x%x (%d %d %d %d)!", clr, iColor, (iColor & 0xFF000000) >>> 24, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF);
			return;
		}
		i++;
	}

	clr[8] = 0;
	if(i == 6)								// добавляем прозрачность
	{
		clr[6] = clr[7] = 'F';
		i = 8;
	}
	if(i == 3 || i == 4)	// короткая форма => полная форма
	{
		if(i == 3) clr[6] = clr[7] = 'F';	// добавляем прозрачность
		else clr[6] = clr[7] = clr[3];
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 8;
	}

	if(i != 8) iColor = -1;	// невалидный цвет => 0xFFFFFFFF
	else StringToIntEx(clr, iColor , 16);
}

stock bool StringIsNumeric(const char[] str)
{
	if(!str[0]) return false;

	int x;
	while(str[x])
	{
		if(str[x] < '0' || str[x] > '9') return false;
		x++;
	}
	return true;
}

public void CVarChanged_PosX(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChanged_PosY(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void Cookie_Speedometer(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
		FormatEx(buffer, maxlen, "%s: %s", PL_NAME, bShow[client] ? "☑" : "☐");
	else if(action == CookieMenuAction_SelectOption)
	{
		bShow[client] = !bShow[client];
		SetClientCookie(client, hCookies, bShow[client] ? "1" : "0");
		ShowCookieMenu(client);
	}
}

public void OnMapStart()
{
	if(fCD > 0) hTimer = CreateTimer(fCD, Timer_UpdateHUD, _, TIMER_REPEAT);
}

public void OnClientCookiesCached(int client)
{
	if(client && !IsFakeClient(client)) GetCookieValue(client);
}

stock void GetCookieValue(int client)
{
	static char buffer[4];
	GetClientCookie(client, hCookies, buffer, sizeof(buffer));
	bShow[client] = buffer[0] != '0';
}

public void OnClientDisconnect(int client)
{
	bShow[client] = false;
}

public void OnMapEnd()
{
	if(hTimer) delete hTimer;
}

public Action Timer_UpdateHUD(Handle timer)
{
	SetHudTextParams(fPosX, fPosY, fCD + 0.1, (iColor & 0xFF000000) >>> 24, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF, _, 0.0, _, 0.1);
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && bShow[i] && GetClientTeam(i) > 1 && !IsFakeClient(i) && IsPlayerAlive(i)) ShowSpeed(i);

	return Plugin_Continue;
}

static void ShowSpeed(int client)
{
	static float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	if(!bVertical) vel[2] = 0.0;

	ShowSyncHudText(client, hHUD, "%.3f %s", GetVectorLength(vel) * MULT[iUnit], UNIT[iUnit]);
}