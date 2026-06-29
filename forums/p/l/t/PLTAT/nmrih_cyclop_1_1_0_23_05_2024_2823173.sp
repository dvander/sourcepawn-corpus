#pragma semicolon 1
#pragma newdecls required

#undef MAXPLAYERS
#define MAXPLAYERS	9

#include <clientprefs>
#include <sdkhooks>
#include <sdktools_engine>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_trace>

static const char
	PL_NAME[]	= "[NMRiH] Cyclop's beam",
	PL_VER[]	= "1.1.0_23.05.2024",

	CHAT_TAG[]	= "\x01[\x04管理员激光\x01] \x03",
	CLR_NAME[][] =
{
	"Red",
	"Orange",
	"Yellow",
	"Green",
	"Cyan",
	"Blue",
	"Purple",
	"White",
	"Invisible"
};

static const int
	COLOR[][] =
{
	{255,   0,   0, 63},
	{255, 127,   0, 63},
	{255, 255,   0, 63},
	{  0, 255,   0, 63},
	{  0, 127, 255, 63},
	{  0,   0, 255, 63},
	{255,   0, 255, 63},
	{255, 255, 255, 63},
	{  0,   0,   0, 63}
},
	EFFECT[] =
{
	DMG_PARALYZE,				// без эффекта,
	DMG_BURN|DMG_DISSOLVE,		// загораются и растворяются
	DMG_PARALYZE|DMG_DISSOLVE,	// растворяются
	DMG_REMOVENORAGDOLL,		// исчезают
	DMG_BLAST|DMG_VEHICLE		// отбрасывает
};

Handle
	laserbeam_cookie;
bool
	bEnabled[MAXPLAYERS+1],
	bLate,
	bShove;
int
	iBeam,
	iHalo,
	iAimPref[MAXPLAYERS+1] = {-1, ...},
	iColor,
	iAlpha,
	iEffect;
float
	fDamage;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Laser beam from the player's eyes",
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
	CreateConVar("nmrih_cyclop_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_cyclop_default", "0", "Default client color preference (0 - 8)", _, true, _, true, 8.0);
	iColor = cvar.IntValue;
	cvar.AddChangeHook(CVarChange_Color);

	cvar = CreateConVar("sm_cyclop_alpha", "63", "Amount of transparency", _, true, _, true, 255.0);
	iAlpha = cvar.IntValue;
	cvar.AddChangeHook(CVarChange_Alpha);

	cvar = CreateConVar("sm_cyclop_damage", "250", "Default beam damage", _, true);
	fDamage = cvar.IntValue + 0.0;
	cvar.AddChangeHook(CVarChange_Damage);

	cvar = CreateConVar("sm_cyclop_effect", "1", "Zombies die with effect\n(0 - no effect, 1 - burn, 2 - dissolve, 3 - disappear, 4 - trow)", _, true, _, true, 4.0);
	iEffect = cvar.IntValue;
	cvar.AddChangeHook(CVarChange_Effect);

	cvar = CreateConVar("sm_cyclop_shove", "1", "Shove the zombies by pressing Reload", _, true, _, true, 1.0);
	bShove = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Shove);

	AutoExecConfig(true, "nmrih_cyclop");

	RegAdminCmd("sm_cyclop", Cmd_Toggle, ADMFLAG_SLAY, "Fire a deadly laser");
	RegAdminCmd("sm_ct", Cmd_Toggle, ADMFLAG_SLAY, "Fire a deadly laser");

	LoadTranslations("nmrih_cyclop.phrases");

	char buffer[64];
	Format(buffer, sizeof(buffer), "%T", "Menu_Title", LANG_SERVER);
	laserbeam_cookie = RegClientCookie("cyclop_color", "Cyclop's beam color", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, buffer);

	HookEvent("player_spawn", Event_Spawn);
	if(bLate)
	{
		for(int i; ++i <= MaxClients;) if(IsClientInGame(i) && AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
}

public void CVarChange_Color(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iColor = cvar.IntValue;
}

public void CVarChange_Alpha(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAlpha = cvar.IntValue;
}

public void CVarChange_Damage(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fDamage = cvar.IntValue + 0.0;
}

public void CVarChange_Effect(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iEffect = cvar.IntValue;
}

public void CVarChange_Shove(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bShove = cvar.BoolValue;
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	char buffer[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) iBeam = PrecacheModel(buffer);
	iHalo = PrecacheModel("materials/sprites/laser/laser_dot_r.vmt");
}

public void OnClientDisconnect(int client)
{
	bEnabled[client] = false;
	iAimPref[client] = -1;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
		return;

	char sPref[4];
	GetClientCookie(client, laserbeam_cookie, sPref, sizeof(sPref));
	iAimPref[client] = sPref[0] ? StringToInt(sPref) : -1;
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	bEnabled[GetClientOfUserId(event.GetInt("userid"))] = false;
}

public Action Cmd_Toggle(int client, int args)
{
	if(!client) PrintToServer("[Cyclop] 仅游戏玩家可用");
	else if(GetUserFlagBits(client) & 0x7FFE && IsPlayerAlive(client))
	{
		bEnabled[client] ^= true;
		PrintToChat(client, "%s%t", CHAT_TAG, bEnabled[client] ? "Enabled" : "Disabled");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(bShove && buttons & IN_RELOAD && IsPlayerAlive(client)) CreateBeam(client, false);
	return Plugin_Continue;
}

public void OnGameFrame()
{
	for(int i; ++i <= MaxClients;) if(IsClientInGame(i) && IsPlayerAlive(i) && bEnabled[i]) CreateBeam(i, true);
}

void CreateBeam(int client, bool show)
{
	static float start[3], end[3];
	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, end);

	start[2] -= 5.0;

	Handle TraceRay = TR_TraceRayFilterEx(start, end, (CONTENTS_SOLID|CONTENTS_OPAQUE), RayType_Infinite, TraceFilterEnt, client);

	if(TR_DidHit(TraceRay))
	{
		TR_GetEndPosition(end, TraceRay);
		int ent = TR_GetEntityIndex(TraceRay);

		static char cls[12];
		if(ent > MaxClients && IsValidEdict(ent) && IsValidEntity(ent)
		&& GetEdictClassname(ent, cls, sizeof(cls)) && !strncmp(cls, "npc_nmrih_", 10, true))
		{
			static float vec[3];
			MakeVectorFromPoints(start, end, vec);
			NormalizeVector(vec, vec);
			ScaleVector(vec, 500.0);
			if(show) SDKHooks_TakeDamage(ent, client, client, fDamage, EFFECT[iEffect], _, vec);
			TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vec);
		}

		if(show)
		{
			static int color[4];
			if((ent = iAimPref[client]) == -1) ent = iColor;
			color = COLOR[ent];
			color[3] = iAlpha;
			TE_SetupBeamPoints(start, end, iBeam, 0, 0, 0, 0.06, 0.4, 0.0, 1, 0.0, color, 0);
			TE_SendToAll();

			TE_SetupGlowSprite(end, iHalo, 0.06, 0.1, iAlpha);
			TE_SendToClient(client);
		}
	}

	delete TraceRay;
}

public bool TraceFilterEnt(int entityhit, int mask, any entity)
{
	return (entityhit != entity);
}

public void PrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(GetUserFlagBits(client) & 0x7FFE)	// any flag from ADMFLAG_GENERIC to ADMFLAG_ROOT
	{
		if(action == CookieMenuAction_DisplayOption)
		{
			if(iAimPref[client] == -1)
				FormatEx(buffer, maxlen, "%T", "Menu_Title", client);
			else FormatEx(buffer, maxlen, "%T: %T", "Menu_Title", client, CLR_NAME[iAimPref[client]], client);
		}
		else //if(action == CookieMenuAction_SelectOption)
		{
			char MenuItem[64];
			Menu menu = CreateMenu(PrefMenuHandler);
			menu.SetTitle("%t", "Cyclop_Control");
			for(int i; i < sizeof(COLOR); i++)
			{
				Format(MenuItem, sizeof(MenuItem), "%T%T", CLR_NAME[i], client, iAimPref[client] == i ? "(Selected)" : "none", client);
				AddMenuItem(menu, "", MenuItem, iAimPref[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}

			if(menu.ItemCount < 10) SetMenuPagination(menu, MENU_NO_PAGINATION);

			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
}

public int PrefMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char buffer[4];
			FormatEx(buffer, sizeof(buffer), "%i", item);
			iAimPref[client] = item;
			SetClientCookie(client, laserbeam_cookie, buffer);
		}
		case MenuAction_End:
			delete menu;
		default:
			return 0;
	}

	ShowCookieMenu(client);

	return 0;
}