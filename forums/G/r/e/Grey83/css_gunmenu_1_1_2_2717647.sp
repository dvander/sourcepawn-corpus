#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_entinput>
#if SOURCEMOD_V_MINOR >= 9
	#include <sdktools_variant_t>
#endif

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"[CSS] Gun Menu"
	#define PL_VER	"1.1.2"
#endif

static const char
#if SOURCEMOD_V_MINOR < 11
	PL_NAME[]	= "[CSS] Gun Menu",
	PL_VER[]	= "1.1.2",
#endif

	WEAPON[][][][] =
{
	{	// Primary
		{"",					"Random\n  Sniper rifles:"},
		{"weapon_awp",			"Arctic Warfare Magnum"},				//       1
		{"weapon_sg550",		"SIG SG 550"},							//       2
		{"weapon_g3sg1",		"H&K G3/SG1"},							//       4
		{"weapon_scout",		"Steyr Scout\n  Assault rifles:"},		//       8
		{"weapon_ak47",			"Izhmash AK"},							//      16
		{"weapon_m4a1",			"Colt M4A1"},							//      32
		{"weapon_sg552",		"SIG SG 552"},							//      64
		{"weapon_aug",			"Steyr AUG"},							//     128
		{"weapon_galil",		"IMI Galil AR"},						//     256
		{"weapon_famas",		"FAMAS\n  Submachine guns:"},			//     512
		{"weapon_mac10",		"Ingram MAC-10"},						//   1 024
		{"weapon_mp5navy",		"H&K MP5 Navy"},						//   2 048
		{"weapon_tmp",			"Steyr TMP"},							//   4 096
		{"weapon_ump45",		"H&K UMP 45"},							//   8 192
		{"weapon_p90",			"FN P90\n  Shotguns:"},					//  16 384
		{"weapon_m3",			"Benelli M3 Super 90"},					//  32 768
		{"weapon_xm1014",		"Benelli М4 Super 90\n  Machinegun:"},	//  65 536
		{"weapon_m249",			"M249"}									// 131 072
	},
	{	// Secondary
		{"",					"Random\n "},
		{"weapon_glock",		"Glock-18"},			// 1
		{"weapon_usp",			"H&K USP"},				// 2
		{"weapon_p228",			"SIG Sauer P228"},		// 4
		{"weapon_deagle",		"IMI Desert Eagle"},	// 8
		{"weapon_fiveseven",	"FN Five-SeveN USG"},	// 16
		{"weapon_elite",		"Dual Beretta 92"},		// 32
		{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""}
	},
	{	// Grenades
		{"",					"Random\n "},
		{"weapon_hegrenade",	"M26 HE grenade"},		// 1
		{"weapon_flashbang",	"M84 Stun grenade"},	// 2
		{"weapon_smokegrenade",	"M18 Smoke grenade"},	// 4
		{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},{"",""},
		{"",""}
	}
};

enum
{
	W_Prim,
	W_Sec,
	W_Nade,

	W_Total
};

enum
{
	Slot_Primary = 0,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};

Handle
	hCookies,
	hDropped[2048];
bool
	bLate,
	bGive[W_Total][MAXPLAYERS+1] = {{true, ...}, {true, ...}, {true, ...}};
int
	iAllowed[W_Total],
	iArmor,
	iNadesMax[3],
	iWpnChoice[W_Total][MAXPLAYERS+1],
	iMenuSize[] = {18, 6, 3};
float
	fClear;
Menu
	hMenu[W_Total];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Gun Menu for gamemodes such as Retake, Deathmatch etc.",
	author		= "Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=294225"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_gun_menu_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_gun_menu_primary", "262143", "Allowed primary weapons", _, true, 1.0, true, 262143.0);
	cvar.AddChangeHook(CVarChanged_Primary);
	iAllowed[W_Prim] = cvar.IntValue;

	cvar = CreateConVar("sm_gun_menu_secondary", "63", "Allowed secondary weapons", _, true, 1.0, true, 63.0);
	cvar.AddChangeHook(CVarChanged_Secondary);
	iAllowed[W_Sec] = cvar.IntValue;

	cvar = CreateConVar("sm_gun_menu_grenades", "7", "Allowed grenades", _, true, _, true, 7.0);
	cvar.AddChangeHook(CVarChanged_Grenades);
	iAllowed[W_Nade] = cvar.IntValue;

	cvar = CreateConVar("sm_gun_menu_armor", "2", "Give to player: 0 - nothing, 1 - armor, 2 - armor + helmet", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChanged_Armor);
	iArmor = cvar.IntValue;

	cvar = CreateConVar("sm_gun_menu_clear", "10", "Time after which the dropped weapon will be removed (-1 - disable cleaning)", _, true, -1.0, true, 86400.0);
	cvar.AddChangeHook(CVarChanged_Clear);
	CVarChanged_Clear(cvar, NULL_STRING, NULL_STRING);

	cvar = FindConVar("ammo_hegrenade_max");
	if(cvar)
	{
		cvar.AddChangeHook(HEMaxChanged);
		iNadesMax[0] = cvar.IntValue;
	}
	cvar = FindConVar("ammo_flashbang_max");
	if(cvar)
	{
		cvar.AddChangeHook(FlashMaxChanged);
		iNadesMax[1] = cvar.IntValue;
	}
	cvar = FindConVar("ammo_smokegrenade_max");
	if(cvar)
	{
		cvar.AddChangeHook(SmokeMaxChanged);
		iNadesMax[2] = cvar.IntValue;
	}

	AutoExecConfig(true, "css_gun_menu");

	int i;
	hMenu[W_Prim] = new Menu(Handler_PrimaryMenu, MenuAction_Select|MenuAction_DrawItem);
	hMenu[W_Prim].SetTitle("Primary weapon (%i):", iMenuSize[W_Prim]);
	for(; i <= iMenuSize[W_Prim]; i++) hMenu[W_Prim].AddItem(NULL_STRING, WEAPON[W_Prim][i][1]);

	hMenu[W_Sec] = new Menu(Handler_SecondaryMenu, MenuAction_Select|MenuAction_DrawItem);
	hMenu[W_Sec].SetTitle("Secondary weapon (%i):", iMenuSize[W_Sec]);
	for(i = 0; i <= iMenuSize[W_Sec]; i++) hMenu[W_Sec].AddItem(NULL_STRING, WEAPON[W_Sec][i][1]);

	hMenu[W_Nade] = new Menu(Handler_GrenadesMenu, MenuAction_Select|MenuAction_DrawItem);
	hMenu[W_Nade].SetTitle("Grenades (%i):", iMenuSize[W_Nade]);
	for(i = 0; i <= iMenuSize[W_Nade]; i++) hMenu[W_Nade].AddItem(NULL_STRING, WEAPON[W_Nade][i][1]);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn",Event_Spawn);
	HookEvent("player_death",Event_Death, EventHookMode_PostNoCopy);

	ToggleBuyZones();

	AddCommandListener(Cmd_Buy, "autobuy");
	AddCommandListener(Cmd_Buy, "rebuy");
	AddCommandListener(Cmd_Buy, "buy");

	hCookies = RegClientCookie(PL_NAME, "Selected weapon", CookieAccess_Private);
	if(!bLate) return;

	bLate = false;
	for(i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i)) iWpnChoice[W_Prim][i] = iWpnChoice[W_Sec][i] = iWpnChoice[W_Nade][i] = -1;
		else if(AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
}

public void CVarChanged_Primary(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAllowed[W_Prim] = cvar.IntValue;
}

public void CVarChanged_Secondary(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAllowed[W_Sec] = cvar.IntValue;
}

public void CVarChanged_Grenades(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAllowed[W_Nade] = cvar.IntValue;
}

public void CVarChanged_Armor(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iArmor = cvar.IntValue;
}

public void CVarChanged_Clear(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fClear = cvar.IntValue + 0.0;

	static bool hooked;
	if((fClear < 0) == !hooked) return;

	hooked = !hooked;
	if(hooked)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) OnClientPutInServer(i);
	}
	else for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		SDKUnhook(i, SDKHook_WeaponDropPost, OnWeaponDropped);
		SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEqiped);
	}
}

public void HEMaxChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iNadesMax[0] = cvar.IntValue;
}

public void FlashMaxChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iNadesMax[1] = cvar.IntValue;
}

public void SmokeMaxChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iNadesMax[2] = cvar.IntValue;
}

public void OnPluginEnd()
{
	ToggleBuyZones(true);
}

public Action Cmd_Buy(int client, const char[] cmd, int argc)
{
	if(client && IsClientInGame(client) && GetClientTeam(client)) hMenu[W_Prim].Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Menu_PrimaryWeapon(int client, int args)
{
	if(client) hMenu[W_Prim].Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Handler_PrimaryMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		iWpnChoice[W_Prim][client] = param ? param : -1;
		SaveChoiceToCookies(client);
		if(bGive[W_Prim][client]) GivePlayerWeapon(client, W_Prim);
		hMenu[W_Sec].Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_DrawItem)
	{
		if(!param) return ITEMDRAW_DEFAULT;

		static int i;
		i = 1 << (param - 1);
		return iAllowed[W_Prim] & i ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	}
	return 0;
}

public int Handler_SecondaryMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		iWpnChoice[W_Sec][client] = param ? param : -1;
		SaveChoiceToCookies(client);
		if(bGive[W_Sec][client]) GivePlayerWeapon(client, W_Sec);
		if(iAllowed[W_Nade]) hMenu[W_Nade].Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_DrawItem)
	{
		if(!param) return ITEMDRAW_DEFAULT;

		static int i;
		i = 1 << (param - 1);
		return iAllowed[W_Sec] & i ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	}
	return 0;
}

public int Handler_GrenadesMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		iWpnChoice[W_Nade][client] = param ? param : -1;
		SaveChoiceToCookies(client);
		if(bGive[W_Nade][client]) GivePlayerWeapon(client, W_Nade);
	}
	else if(action == MenuAction_DrawItem)
	{
		if(!param) return ITEMDRAW_DEFAULT;

		static int i;
		i = 1 << (param - 1);
		return iAllowed[W_Nade] & i ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	}
	return 0;
}

stock void SaveChoiceToCookies(int client)
{
	int value;
	if(iWpnChoice[W_Prim][client] != -1) value  = iWpnChoice[W_Prim][client] << 16;
	else value  = 1 << 24;
	if(iWpnChoice[W_Sec][client] != -1) value |= iWpnChoice[W_Sec][client] << 8;
	else value |= 2 << 24;
	if(iWpnChoice[W_Nade][client] != -1) value |= iWpnChoice[W_Nade][client];
	else value |= 4 << 24;

	static char buffer[12];
	FormatEx(buffer, sizeof(buffer), "0x%08x", value);
//	PrintToServer("\n%N's choice: %s\n", client, buffer);
	SetClientCookie(client, hCookies, buffer);
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client)) iWpnChoice[W_Prim][client] = iWpnChoice[W_Sec][client] = iWpnChoice[W_Nade][client] = -1;
	if(fClear < 0) return;

	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEqiped);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDropped);
}

void OnWeaponDropped(int client, int wpn)
{
	if(wpn <= MaxClients) return;

	if(hDropped[wpn]) delete hDropped[wpn];
	hDropped[wpn] = CreateTimer(fClear, Timer_CheckDropped, EntIndexToEntRef(wpn));
}

void OnWeaponEqiped(int client, int wpn)
{
	if(hDropped[wpn]) delete hDropped[wpn];
}

public void OnEntityDestroyed(int entity)
{
	if(entity > MaxClients && entity < 2048 && hDropped[entity]) delete hDropped[entity];
}

public Action Timer_CheckDropped(Handle timer, any wpn)
{
	if((wpn = EntRefToEntIndex(wpn)) != INVALID_ENT_REFERENCE)
	{
		hDropped[wpn] = null;

		static int zone;
		if((zone = CreateEntityByName("env_entity_dissolver")) == -1)
		{
			AcceptEntityInput(wpn, "Kill");
			return;
		}

		static char buffer[16];
		FormatEx(buffer, sizeof(buffer), "dissolve_%i", wpn);
		DispatchKeyValue(wpn, "targetname", buffer);
		DispatchKeyValue(zone, "target", buffer);
//		тип исчезновения: 0 - Energy, 1 - Heavy electrical, 2 - Light electrical, 3 - Core effect
		DispatchKeyValue(zone, "dissolvetype", "3");
		DispatchKeyValue(zone, "magnitude", "50");

		SetVariantString("!activator");
		AcceptEntityInput(zone, "SetParent", wpn, zone, 0);
		AcceptEntityInput(zone, "Dissolve");
	}
}

public void OnMapEnd()
{
	for(int i = MaxClients + 1; i < 2048; i++) if(hDropped[i]) delete hDropped[i];
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client)) return;

	char buffer[12];
	GetClientCookie(client, hCookies, buffer, sizeof(buffer));
//	PrintToServer("\n%N's settings: %s\n", client, buffer);
	if(buffer[0] != '0' || buffer[1] != 'x' || strlen(buffer) < 3 || strlen(buffer) > 10) return;

	int value = StringToInt(buffer, 0x10), rnd = (value & 0xFF000000) >>> 24;
	iWpnChoice[W_Prim][client] = rnd & 1 ? -1 : (value & 0xFF0000) >> 16;
	iWpnChoice[W_Sec][client] = rnd & 2 ? -1 : (value & 0xFF00) >> 8;
	iWpnChoice[W_Nade][client] = rnd & 4 ? -1 :  value & 0xFF;
}

public void OnClientDisconnect(int client)
{
	iWpnChoice[W_Prim][client] = iWpnChoice[W_Sec][client] = iWpnChoice[W_Nade][client] = 0;
	bGive[W_Prim][client] = bGive[W_Sec][client] = bGive[W_Nade][client] = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ToggleBuyZones();
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(!(client = GetClientOfUserId(event.GetInt("userid"))) || GetClientTeam(client) < 2) return;

	if(!iWpnChoice[W_Prim][client])
		hMenu[W_Prim].Display(client, MENU_TIME_FOREVER);
	else if(!iWpnChoice[W_Sec][client])
		hMenu[W_Sec].Display(client, MENU_TIME_FOREVER);
	else if(iAllowed[W_Nade] && !iWpnChoice[W_Nade][client])
		hMenu[W_Nade].Display(client, MENU_TIME_FOREVER);
	else RequestFrame(RequestFrame_Callback, GetClientUserId(client));
}

public void RequestFrame_Callback(int client)
{
	static int team, armor, helmet, defuser;
	if(!(client = GetClientOfUserId(client)) || (team = GetClientTeam(client)) < 2) return;

	if(iArmor && (armor > 0 || (armor = FindSendPropInfo("CCSPlayer", "m_ArmorValue")) > 0))
		SetEntData(client, armor, 100, 1, true);
	if(iArmor == 2 && (helmet > 0 || (helmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet")) > 0))
		SetEntData(client, helmet, 1, 1, true);
	if(team == 3 && (defuser > 0 || (defuser = FindSendPropInfo("CCSPlayer", "m_bHasDefuser")) > 0))
		SetEntData(client, defuser, 1, 1, true);

	RemoveWeaponBySlot(client, Slot_Primary);
	if(!GivePlayerWeapon(client, W_Prim)) return;

	RemoveWeaponBySlot(client, Slot_Secondary);
	if(!GivePlayerWeapon(client, W_Sec)) return;

	if(iAllowed[W_Nade]) GivePlayerWeapon(client, W_Nade);
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "item_defuser")) != -1) AcceptEntityInput(entity, "Kill");
}

stock bool GivePlayerWeapon(int client, int type)
{
	static int wpn, i, weapons[18], num;
	wpn = iWpnChoice[type][client];
	if(wpn == -1)
	{
		for(i = 1, num = -1; i <= iMenuSize[type]; i++) if(iAllowed[type] & (1 << i)) weapons[++num] = i;
		wpn = num ? weapons[GetRandomInt(0, num)] : weapons[num++];
	}
	else if(!wpn || !(iAllowed[type] & (1 << (wpn - 1))))
	{
		bGive[type][client] = true;
		iWpnChoice[type][client] = 0;
		hMenu[type].Display(client, MENU_TIME_FOREVER);

		return false;
	}


	if(type != W_Nade) GivePlayerItem(client, WEAPON[type][wpn][0]);
	else
	{
		static int ammo;
		if(ammo < 1) ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
		num = ammo + (wpn+10) * 4;
		if(GetEntData(client, num) < 1)
			GivePlayerItem(client, WEAPON[type][wpn][0]);
		SetEntData(client, num, iNadesMax[wpn-1], 4, true);
	}

	bGive[type][client] = false;
	return true;
}

stock bool RemoveWeaponBySlot(int client, int slot)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	return ent > MaxClients && RemovePlayerItem(client, ent) && AcceptEntityInput(ent, "Kill");
}

stock void ToggleBuyZones(bool enable = false)
{
	// убираем попытки ботов закупится при отключении зон покупок
	static ConVar cvar;
	if(!cvar) cvar = FindConVar("bot_eco_limit");
	else
	{
		static int limit = -1;
		if(limit == -1) limit = cvar.IntValue;
		else SetConVarInt(cvar, enable ? limit : 16001);
	}

	char state[8];
	state = enable ? "Enable" : "Disable";
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "func_buyzone")) != -1) AcceptEntityInput(entity, state);
}