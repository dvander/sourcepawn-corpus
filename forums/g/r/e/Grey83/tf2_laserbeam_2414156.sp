#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <tf2>
//#include <tf2_stocks>
#include <clientprefs>

#define PLUGIN_NAME		"[TF2] Laser Beam"
#define PLUGIN_VERSION	"1.1.0"

static int g_iLaserMaterial, g_iHaloMaterial;

bool g_bLaserEnabled[MAXPLAYERS+1];

Handle laserbeam_cookie = INVALID_HANDLE;
int iAimPref[MAXPLAYERS+1];
#define NUM_COLORS 9
static char sColorName[NUM_COLORS][7] = {
"Red",
"Orange",
"Yellow",
"Green",
"Cyan",
"Blue",
"Purple",
"White",
"Black"
};
static int aColor[NUM_COLORS][4] = {
{255, 0, 0, 63},
{255, 127, 0, 63},
{255, 255, 0, 63},
{0, 255, 0, 63},
{0, 127, 255, 63},
{0, 0, 255, 63},
{255, 0, 255, 63},
{255, 255, 255, 63},
{0, 0, 0, 63}
};

ConVar lb_color = null;
ConVar lb_alpha = null;
ConVar lb_dmg = null;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Pelipoika (rewritten by Grey83)",
	description = "Laser beams from the player's eyes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2413816"
};

public void OnPluginStart()
{
	LoadTranslations("tf2_laserbeam.phrases");
	char menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);
	AutoExecConfig(true, "tf2_laserbeam");

	CreateConVar("tf2_laserbeam_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	lb_color = CreateConVar("sm_laserbeam_default", "0", "Default client colour preference (0 - 8)", FCVAR_NONE, true, 0.0, true, 8.0);
	lb_alpha = CreateConVar("sm_laserbeam_alpha", "63", "Amount of transparency", FCVAR_NONE, true, 0.0, true, 255.0 );
	lb_dmg = CreateConVar("sm_laserbeam_damage", "2", "Default laser beam damage", FCVAR_NONE, true, 0.0);

//	RegAdminCmd("sm_laserbeam", Command_ToggleLaser, ADMFLAG_ROOT, "Fire a deadly laser");
	RegConsoleCmd("sm_laserbeam", Command_ToggleLaser, "Fire a deadly laser");
	RegConsoleCmd("sm_lb", Command_ToggleLaser, "Fire a deadly laser");

	laserbeam_cookie = RegClientCookie("laserbeam_color", "Laser beam color", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, menutitle);
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

public void OnClientPutInServer(int client)
{
	g_bLaserEnabled[client] = false;
}

public OnClientCookiesCached(client)
{
	char sPref[4];
	GetClientCookie(client, laserbeam_cookie, sPref, sizeof(sPref));
	if (StrEqual(sPref, "")) iAimPref[client] = GetConVarInt(lb_color);
	else iAimPref[client] = StringToInt(sPref);
}

public Action Command_ToggleLaser(int client, int args)
{
	if (!client) PrintToServer("[LB] Command is in-game only");
	else if(0 < client <= MaxClients && IsClientInGame(client))
	{
		g_bLaserEnabled[client] = !g_bLaserEnabled[client];
		PrintToChat(client, g_bLaserEnabled[client] ? "[LASER] Enabled, hold R to fire the laser" : "[LASER] Disabled");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon)
{
	if (IsPlayerAlive(client) && g_bLaserEnabled[client] && iButtons & IN_RELOAD)
	{
		float flPos[3], flAng[3];
		GetClientEyePosition(client, flPos);
		GetClientEyeAngles(client, flAng);
		
		flPos[2] -= 5.0;
		
		Handle TraceRay = TR_TraceRayFilterEx(flPos, flAng, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceFilterEnt, client);
		
		if(TR_DidHit(TraceRay))
		{
			float flEndPos[3];
			TR_GetEndPosition(flEndPos, TraceRay);
			int iHit = TR_GetEntityIndex(TraceRay);
			
			float flDamageForce[3];
			MakeVectorFromPoints(flPos, flEndPos, flDamageForce);
			NormalizeVector(flDamageForce, flDamageForce);
			ScaleVector(flDamageForce, 500.0);

			if(0 < iHit <= MaxClients && IsClientInGame(iHit))
			{
				SDKHooks_TakeDamage(iHit, client, client, float(GetConVarInt(lb_dmg)), DMG_ENERGYBEAM|DMG_PLASMA|DMG_DISSOLVE, _, flDamageForce);
				TeleportEntity(iHit, NULL_VECTOR, NULL_VECTOR, flDamageForce);
			}
			int color[4];
			color = aColor[iAimPref[client]];
			color[3] = GetConVarInt(lb_alpha);
			TE_SetupBeamPoints(flPos, flEndPos, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 0.06, 1.0, 1.0, 1, 0.0, color, 0);
			TE_SendToAll();
		}
		
		delete TraceRay;
	}
}

public bool TraceFilterEnt(int entityhit, int mask, any entity)
{
	return (entityhit != entity);
}

public PrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
		Format(buffer, maxlen, "%T: %T", "Menu_Title", client, sColorName[iAimPref[client]], client);
	else if (action == CookieMenuAction_SelectOption)
	{
		char MenuItem[64];
		Menu prefmenu = CreateMenu(PrefMenuHandler);
		Format(MenuItem, sizeof(MenuItem), "%T", "LaserBeam_Control", client);
		prefmenu.SetTitle(MenuItem);
		char sNum[4];
		for (new i = 0; i < NUM_COLORS; i++)
		{
			Format(MenuItem, sizeof(MenuItem), "%T%T", sColorName[i], client, iAimPref[client] == i ? "(Selected)" : "none", client);
			IntToString(i, sNum, 4);
			AddMenuItem(prefmenu, sNum, MenuItem, iAimPref[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
#if NUM_COLORS < 10
		SetMenuPagination(prefmenu, MENU_NO_PAGINATION);
#endif
		SetMenuExitButton(prefmenu, true);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public int PrefMenuHandler(Menu prefmenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		decl String:sPref[8];
		prefmenu.GetItem(item, sPref, sizeof(sPref));
		iAimPref[client] = StringToInt(sPref);
		SetClientCookie(client, laserbeam_cookie, sPref);
	}
	else if (action == MenuAction_End) delete prefmenu;

	if(0 < client <= MaxClients && IsClientInGame(client)) ShowCookieMenu(client);
}