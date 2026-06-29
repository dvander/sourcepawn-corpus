#pragma semicolon 1
#pragma newdecls required

#include <sdktools_engine>
#include <sdktools_functions>
#include <sdktools_gamerules>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

static const int COLOR[][] = {{0xff, 0x3f, 0x1f}, {0x1f, 0x3f, 0xff}};	// Default beam colors (T, CT)

int
	hBeam,
	hHalo,
	iColor[2][4];
float
	fLife,
	fWidth;

public Plugin myinfo =
{
	name		= "Laser Tag",
	version		= "1.0.0_31.03.2025",
	description	= "",
	author		= "Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=350863"
}

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_laser_tag_enable", "1", "1/0 = Enable/Disable plugin", FCVAR_NONE, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	CVarChange_Enable(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_laser_tag_life", "0.3", "Laser beam life", FCVAR_NONE, true, 0.01, true, 1.0);
	cvar.AddChangeHook(CVarChange_Life);
	fLife = cvar.FloatValue;

	cvar = CreateConVar("sm_laser_tag_width", "3.0", "Laser beam width", FCVAR_NONE, true, 0.1, true, 100.0);
	cvar.AddChangeHook(CVarChange_Width);
	fWidth = cvar.FloatValue;

	cvar = CreateConVar("sm_laser_tag_alpha", "127", "Laser beam alpha", _, true, _, true, 255.0);
	cvar.AddChangeHook(CVarChange_Alpha);
	iColor[0][3] = iColor[1][3] = cvar.IntValue;

	cvar = CreateConVar("sm_laser_tag_t", "ff3f1f", "T laser beam color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = red", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_ColorT);
	SetColor(cvar, 0);

	cvar = CreateConVar("sm_laser_tag_ct", "1f3fff", "CT laser beam color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = blue", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_ColorCT);
	SetColor(cvar, 1);

	AutoExecConfig(true, "laser_tag");
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if(hooked == cvar.BoolValue)
		return;

	if(!(hooked ^= true))
		UnhookEvent("bullet_impact", Event_BulletImpact);
	else HookEvent("bullet_impact", Event_BulletImpact);
}

public void CVarChange_Life(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fLife = cvar.FloatValue;
}

public void CVarChange_Width(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fWidth = cvar.FloatValue;
}

public void CVarChange_Alpha(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iColor[0][3] = iColor[1][3] = cvar.IntValue;
}

public void CVarChange_ColorT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, 0);
}

public void CVarChange_ColorCT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	SetColor(cvar, 1);
}

void SetColor(ConVar cvar, int type)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{
			ResetColor(type, clr);
			return;
		}
		i++;
	}

	if(i != 6) ResetColor(type, clr);

	clr[6] = 0;
	if(i == 3)
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	StringToIntEx(clr, i, 16);
	SaveColor(type, (i & 0xFF0000) >> 16, (i & 0xFF00) >> 8, i & 0xFF);
}

void ResetColor(int type, char[] clr)
{
	SaveColor(type);
	LogError("HEX color '%s' isn't valid!\nLaser beam color is 0x%2x%2x%2x (%d %d %d)!\n", clr, COLOR[type][0], COLOR[type][1], COLOR[type][2], COLOR[type][0], COLOR[type][1], COLOR[type][2]);
}

void SaveColor(int type, int r = -1, int g = -1, int b = -1)
{
	if(r == -1) r = COLOR[type][0], g = COLOR[type][1], b = COLOR[type][2];
	iColor[type][0] = r, iColor[type][1] = g, iColor[type][2] = b;
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(gameConfig == null) LogError("Unable to load game config funcommands.games");
	else
	{
		char buffer[PLATFORM_MAX_PATH];
		if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
			hBeam = PrecacheModel(buffer);
		if(hBeam == -1)
			LogError("Can't find config for SpriteBeam!");

		if(GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
			hHalo = PrecacheModel(buffer);
		else hHalo = 0;
	}
	CloseHandle(gameConfig);
}

public void Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	if(hBeam == -1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid")), type;
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || (type = GetClientTeam(client)) < 2)
		return;

	static float orig[3], vec[3];
	GetClientEyePosition(client, orig);
	vec[0] = event.GetFloat("x");
	vec[1] = event.GetFloat("y");
	vec[2] = event.GetFloat("z");

	TE_SetupBeamPoints(orig, vec, hBeam, hHalo, 0, 0, fLife, fWidth, fWidth, 1, 0.0, iColor[type - 2], 0);
	TE_SendToAll();
}