#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define PLUGIN_NAME		"[NMRiH] Cyclop's beam"
#define PLUGIN_VERSION	"1.0.0"
#define CHAT_TAG			"\x01[\x04Cyclop\x01] \x03"

static int g_iLaserMaterial;

bool g_bLaserEnabled[MAXPLAYERS+1];
bool bIsAdmin[MAXPLAYERS+1];
bool bLate;

Handle laserbeam_cookie = INVALID_HANDLE;
int iAimPref[MAXPLAYERS+1];
#define NUM_COLORS 9
static char sColorName[NUM_COLORS][10] = {
"Invisible",
"Red",
"Orange",
"Yellow",
"Green",
"Cyan",
"Blue",
"Purple",
"White"
};
static int aColor[NUM_COLORS][4] = {
{0, 0, 0, 63},
{255, 0, 0, 63},
{255, 127, 0, 63},
{255, 255, 0, 63},
{0, 255, 0, 63},
{0, 127, 255, 63},
{0, 0, 255, 63},
{255, 0, 255, 63},
{255, 255, 255, 63}
};

ConVar lb_color = null;
int iColor;
ConVar lb_alpha = null;
int iAlpha;
ConVar lb_dmg = null;
int iDamage;
ConVar lb_effect = null;
int iEffect;
ConVar lb_shove = null;
bool bShove;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Grey83",
	description = "Laser beam from the player's eyes",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("nmrih_cyclop.phrases");
	char menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);
	AutoExecConfig(true, "nmrih_cyclop");

	CreateConVar("nmrih_cyclop_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	lb_color = CreateConVar("sm_cyclop_default", "0", "Default client color preference (0 - 8)", FCVAR_NONE, true, 0.0, true, 8.0);
	lb_alpha = CreateConVar("sm_cyclop_alpha", "63", "Beam transparency", FCVAR_NONE, true, 0.0, true, 255.0 );
	lb_dmg = CreateConVar("sm_cyclop_damage", "250", "Default beam damage", FCVAR_NONE, true, 0.0);
	lb_effect = CreateConVar("sm_cyclop_effect", "1", "Zombies die with effect\n(0 - no effect, 1 - burn, 2 - dissolve, 3 - disappear, 4 - trow)", FCVAR_PLUGIN, true, 0.0, true, 4.0);
	lb_shove = CreateConVar("sm_cyclop_shove", "1", "Allow shove the zombies by pressing Reload", FCVAR_NONE, true, 0.0, true, 1.0);


	iColor = GetConVarInt(lb_color);
	iAlpha = GetConVarInt(lb_alpha);
	iDamage = GetConVarInt(lb_dmg);
	iEffect = GetConVarInt(lb_effect);
	bShove = GetConVarBool(lb_shove);

	HookConVarChange(lb_color, OnConVarChange);
	HookConVarChange(lb_alpha, OnConVarChange);
	HookConVarChange(lb_dmg, OnConVarChange);
	HookConVarChange(lb_effect, OnConVarChange);
	HookConVarChange(lb_shove, OnConVarChange);

	RegAdminCmd("sm_cyclop", Cmd_Toggle, ADMFLAG_SLAY, "Fire a deadly laser");
	RegAdminCmd("sm_ct", Cmd_Toggle, ADMFLAG_SLAY, "Fire a deadly laser");

	laserbeam_cookie = RegClientCookie("cyclop_color", "Cyclop's beam color", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, menutitle);

	HookEvent("player_spawn", Event_Spawn);
	if (bLate) {
		LookupClients();
		bLate = false;
	}
}

public void OnConVarChange(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	if (hCVar == lb_color) iColor = StringToInt(newValue);
	else if (hCVar == lb_alpha) iAlpha = StringToInt(newValue);
	else if (hCVar == lb_dmg) iDamage = StringToInt(newValue);
	else if (hCVar == lb_effect) iEffect = StringToInt(newValue);
	else if (hCVar == lb_shove) bShove = (StringToInt(newValue)) ? true : false;
}

void LookupClients() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) OnClientPostAdminCheck(i);
	}
}

public void OnMapStart()
{
	new Handle:gameConfig = LoadGameConfigFile("funcommands.games");
	new String:buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) g_iLaserMaterial = PrecacheModel(buffer);
}

public void OnClientPutInServer(int client)
{
	g_bLaserEnabled[client] = false;
}

public void OnClientPostAdminCheck(client)
{
	if  (1 <= client <= MaxClients) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public OnClientCookiesCached(client)
{
	char sPref[4];
	GetClientCookie(client, laserbeam_cookie, sPref, sizeof(sPref));
	if (StrEqual(sPref, "")) iAimPref[client] = iColor;
	else iAimPref[client] = StringToInt(sPref);
}

public Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bLaserEnabled[client] = false;
}

public Action Cmd_Toggle(int client, int args)
{
	if (!client) PrintToServer("[Cyclop] Command is in-game only");
	else if(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_bLaserEnabled[client] = !g_bLaserEnabled[client];
		PrintToChat(client, "%s%T", CHAT_TAG, g_bLaserEnabled[client] ? "Enabled" : "Disabled", client);
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon)
{
	if (bShove && IsPlayerAlive(client) && iButtons & IN_RELOAD) CreateBeam(client);
}
public OnGameFrame()
{
	for (new client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && g_bLaserEnabled[client]) CreateBeam(client, true);
			
	}
}

CreateBeam(int client, bool show = false)
{
	float flPos[3], flAng[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);

	flPos[2] -= 5.0;

	Handle TraceRay = TR_TraceRayFilterEx(flPos, flAng, (CONTENTS_SOLID|CONTENTS_OPAQUE), RayType_Infinite, TraceFilterEnt, client);

	if(TR_DidHit(TraceRay))
	{
		float flEndPos[3];
		TR_GetEndPosition(flEndPos, TraceRay);
		int iHit = TR_GetEntityIndex(TraceRay);

		float flDamageForce[3];
		MakeVectorFromPoints(flPos, flEndPos, flDamageForce);
		NormalizeVector(flDamageForce, flDamageForce);
		ScaleVector(flDamageForce, 500.0);

		if(iHit > MaxClients)
		{
			if (IsValidEdict(iHit) && IsValidEntity(iHit))
			{
				char item[12];
				GetEdictClassname(iHit, item, sizeof(item));
				if (StrContains(item, "npc_nmrih_", true) == 0)
				{
					if(show) SDKHooks_TakeDamage(iHit, client, client, float(iDamage), BeamEffect(), _, flDamageForce);
					TeleportEntity(iHit, NULL_VECTOR, NULL_VECTOR, flDamageForce);
				}
			}
		}

		if(show)
		{
			int color[4];
			color = aColor[iAimPref[client]];
			color[3] = iAlpha;
			TE_SetupBeamPoints(flPos, flEndPos, g_iLaserMaterial, 0, 0, 0, 0.06, 0.4, 0.0, 1, 0.0, color, 0);
			TE_SendToAll();
		}
	}

	delete TraceRay;
}

int BeamEffect()
{
	int effect;
	switch (iEffect)
	{
		case 0: effect = DMG_PARALYZE;					// без эффекта
		case 1: effect = DMG_BURN|DMG_DISSOLVE;		// загораются и растворяются
		case 2: effect = DMG_PARALYZE|DMG_DISSOLVE;	// растворяются
		case 3: effect = DMG_REMOVENORAGDOLL;		// исчезают
		case 4: effect = DMG_BLAST|DMG_VEHICLE;		// отбрасывает
	}
	return effect;
}

public bool TraceFilterEnt(int entityhit, int mask, any entity)
{
	return (entityhit != entity);
}

public PrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(bIsAdmin[client])
	{
		if (action == CookieMenuAction_DisplayOption)
			Format(buffer, maxlen, "%T: %T", "Menu_Title", client, sColorName[iAimPref[client]], client);
		else if (action == CookieMenuAction_SelectOption)
		{
			char MenuItem[64];
			Menu prefmenu = CreateMenu(PrefMenuHandler);
			Format(MenuItem, sizeof(MenuItem), "%T", "Cyclop_Control", client);
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