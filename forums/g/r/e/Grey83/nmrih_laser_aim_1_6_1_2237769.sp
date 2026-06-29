#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

static const char VERSION[]	= "1.6.1";
static const char NAME[]		= "[NMRiH] Laser Aim";

static const char sName[]		= "\x01[\x04LaserAim\x01] \x03";
static const char sCom[]		= "\x04!settings";

static const char SpritesPath[]	= "materials/sprites/laser/laser_dot_";

ConVar hEnable, hMessage, hAll;
bool bEnable, bMessage, bAll;
ConVar hDefColour, hTrans;
int iDefColour, iTrans;
ConVar hLife, hWidth, hDotWidth;
float fLife, fWidth, fDotWidth;
Handle laser_aim_cookie;

int iAimPref[MAXPLAYERS+1];

static const int NUM_COLORS = 8;
int hDot[8] = {-1, ...}, hBeam = -1;
static const int cColor[] = {'r', 'o', 'y', 'g', 'c', 'b', 'p', 'w'};
static const char sColorName[][] = { "Red",
	"Orange",
	"Yellow",
	"Green",
	"Cyan",
	"Blue",
	"Purple",
	"White",
	"Switch off" };
static const int aColor[][] = { {255, 0, 0, 63},
	{255, 127, 0, 63},
	{255, 255, 0, 63},
	{0, 255, 0, 63},
	{0, 127, 255, 63},
	{0, 0, 255, 63},
	{255, 0, 255, 63},
	{255, 255, 255, 63},
	{0, 0, 0, 0} };

public Plugin myinfo =
{
	name = NAME,
	author = "Leonardo (rewrited by Grey83)",
	description = "Creates a laser dot every time a firearm in the hands of the player",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=253367"
};

public void OnPluginStart()
{
	LoadTranslations("nmrih_laser_aim.phrases");

	CreateConVar("nmrih_laser_aim_version", VERSION, NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hEnable		= CreateConVar("sm_laser_aim_on", "1", "1 turns the plugin on, 0 is off", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	hMessage	= CreateConVar("sm_laser_aim_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	hDefColour	= CreateConVar("sm_laser_aim_default", "0", "Default client colour preference (0 - 8)", FCVAR_NONE, true, 0.0, true, 8.0);
	hAll			= CreateConVar("sm_laser_aim2all", "1", "The player can see: 1- all lasers, 0 - only their own lasers", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hTrans		= CreateConVar("sm_laser_aim_alpha", "63", "Amount of transparency", FCVAR_NONE, true, 0.0, true, 255.0);
	hLife		= CreateConVar("sm_laser_aim_life", "0.6", "Life of the dot", FCVAR_NONE, true, 0.51, true, 1.0);
	hWidth		= CreateConVar("sm_laser_aim_width", "0.4", "Width of the beam", FCVAR_NONE, true, 0.1);
	hDotWidth	= CreateConVar("sm_laser_aim_dot_width", "0.1", "Width of the dot", FCVAR_NONE, true, 0.1);

	laser_aim_cookie = RegClientCookie("laser_aim_enable", "enabled setting", CookieAccess_Private);
	char menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);
	SetCookieMenuItem(PrefMenu, 0, menutitle);

	bEnable			= GetConVarBool(hEnable);
	bMessage		= GetConVarBool(hMessage);
	iDefColour	= GetConVarInt(hDefColour);
	bAll				= GetConVarBool(hAll);
	iTrans		= GetConVarInt(hTrans);
	fLife				= (GetConVarFloat(hLife)/10);
	fWidth			= GetConVarFloat(hWidth);
	fDotWidth		= GetConVarFloat(hDotWidth);

	HookConVarChange(hEnable, OnConVarChanged);
	HookConVarChange(hMessage, OnConVarChanged);
	HookConVarChange(hDefColour, OnConVarChanged);
	HookConVarChange(hAll, OnConVarChanged);
	HookConVarChange(hTrans, OnConVarChanged);
	HookConVarChange(hLife, OnConVarChanged);
	HookConVarChange(hWidth, OnConVarChanged);
	HookConVarChange(hDotWidth, OnConVarChanged);

	AutoExecConfig(true, "nmrih_laser_aim");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hEnable) bEnable = view_as<bool>(StringToInt(newValue));
	else if(convar == hMessage) bMessage = view_as<bool>(StringToInt(newValue));
	else if(convar == hDefColour) iDefColour = StringToInt(newValue);
	else if(convar == hAll) bAll = view_as<bool>(StringToInt(newValue));
	else if(convar == hTrans) iTrans = StringToInt(newValue);
	else if(convar == hLife) fLife = (StringToFloat(newValue)/10);
	else if(convar == hWidth) fWidth = StringToFloat(newValue);
	else if(convar == hDotWidth) fDotWidth = StringToFloat(newValue);
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(LoadGameConfigFile("funcommands.games"), "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) hBeam = PrecacheModel(buffer);

	for(int i; i < NUM_COLORS; i++)
	{
		Format(buffer, PLATFORM_MAX_PATH, "%s%c.vmt", SpritesPath, cColor[i]);
		hDot[i] = PrecacheModel(buffer, true);
		AddFileToDownloadsTable(buffer);
		Format(buffer, PLATFORM_MAX_PATH, "%s%c.vtf", SpritesPath, cColor[i]);
		AddFileToDownloadsTable(buffer);
	}
}

public void OnClientCookiesCached(int client)
{
	char sPref[8];
	GetClientCookie(client, laser_aim_cookie, sPref, sizeof(sPref));
	if(StrEqual(sPref, "")) iAimPref[client] = iDefColour;
	else iAimPref[client] = StringToInt(sPref);
}

public void OnClientPostAdminCheck(int client)
{
	if(bEnable && bMessage && 0 < client <= MaxClients) PrintToChat(client, "%s%T %s", sName, "Welcome Message", client, sCom);
}

public void PrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T: %T", "Menu_Title", client, sColorName[iAimPref[client]], client);
	}
	else if(action == CookieMenuAction_SelectOption)
	{
		char MenuItem[64];
		Menu prefmenu = new Menu(PrefMenuHandler);
		int currPref = iAimPref[client];
		SetMenuTitle(prefmenu, "%T", "Laser_Aim_Control", client);
		char sNum[2];
		for(int i; i < NUM_COLORS + 1; i++)
		{
			Format(MenuItem, sizeof(MenuItem), "%T %T", sColorName[i], client, currPref == i ? "(Selected)" : "none", client);
			IntToString(i, sNum, 2);
			AddMenuItem(prefmenu, sNum, MenuItem, currPref == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		if(NUM_COLORS < 10) SetMenuPagination(prefmenu, MENU_NO_PAGINATION);
		SetMenuExitButton(prefmenu, true);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public int PrefMenuHandler(Menu prefmenu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char sPref[8];
		GetMenuItem(prefmenu, item, sPref, sizeof(sPref));
		iAimPref[client] = StringToInt(sPref);
		SetClientCookie(client, laser_aim_cookie, sPref);
		PrintToChat(client, "%s%T \x04%T", sName, "Color selected", client, sColorName[iAimPref[client]], client);
	}
	else if(action == MenuAction_End) CloseHandle(prefmenu);

	ShowCookieMenu(client);
}

public void OnGameFrame()
{
	if(bEnable)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && iAimPref[i] != NUM_COLORS)
			{
				static char weapon[12];
				GetClientWeapon(i, weapon, sizeof(weapon));

				if((StrContains(weapon, "fa_", true) == 0) || (StrContains(weapon, "tool_flare_", true) == 0) || (StrContains(weapon, "bow_", true) == 0)) CreateBeam(i, iAimPref[i]);
			}
		}
	}
}

void CreateBeam(const int client, const int pref)
{
	static float fDestination[3];
	GetPlayerEye(client, fDestination);

	static int dot;
	if((dot = hDot[pref]) > -1)
	{
		TE_SetupGlowSprite(fDestination, dot, fLife, fDotWidth, iTrans);
		if(bAll) TE_SendToAll();
		else TE_SendToClient(client);
	}

	if(hBeam > -1 && 0 < GetEntProp(client, Prop_Data, "m_iFOV") < GetEntProp(client, Prop_Data, "m_iDefaultFOV"))
	{
		static int iColor[4];
		iColor = aColor[pref];
		iColor[3] = iTrans;
		static float pos[3];
		NewOrigin(client, fDestination, pos);
		TE_SetupBeamPoints(pos, fDestination, hBeam, 0, 0, 0, fLife, fWidth, 0.0, 1, 0.0, iColor, 0);
		if(bAll) TE_SendToAll();
		else TE_SendToClient(client);
	}
}

void NewOrigin(const int client, const float dest[3], float orig[3])
{
	GetClientAbsOrigin(client, orig);
	orig[2] += (GetClientButtons(client) & IN_DUCK) ? 28 : 60;
	static float percentage;
	percentage = 0.4 / (GetVectorDistance(orig, dest) / 100);
	orig[1] -= 0.08;
	for(int i; i < 3; i++)
	{
		orig[i] += (dest[i] - orig[i]) * percentage;
	}
}

bool GetPlayerEye(const int client, float pos[3])
{
	static float ang[3];
	GetClientEyePosition(client,pos);
	GetClientEyeAngles(client, ang);

	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, FilterPlayer);

	static bool hit;
	hit = TR_DidHit(trace);
	if(hit) TR_GetEndPosition(pos, trace);
	CloseHandle(trace);
	return hit;
}

public bool FilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}