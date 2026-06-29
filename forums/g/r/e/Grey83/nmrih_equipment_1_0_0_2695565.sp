#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_entinput>
/*
#undef MAXPLAYERS
#define MAXPLAYERS = 8
*/
static const char
	PL_NAME[]		= "[NMRiH] Equipment",
	PL_VER[]		= "1.0.0 2020.04.23",

	MAP_BANNED[]	= "nmo_dodgeball_",
	EQUIPMENT_TYPE[][] =
{
	"Categories",
	"Pistols",		// 0
	"Rifles",		// 1
	"Semiauto",		// 2
	"Auto",			// 3
	"Shotguns",		// 4
	"Melee",		// 5
	"Tools",		// 6
	"Medicines",	// 7
	"Explosives",	// 8
	"Ammo"			// 9
},
	EQUIPMENT_NAME[][] =
{
	"fa_1911",				// 0) Pistols
	"fa_glock17",
	"fa_m92fs",
	"fa_mkiii",
	"fa_sw686",
	"fa_jae700",			// 5) Rifles
	"fa_sako85",
	"fa_sako85_ironsights",
	"fa_winchester1892",
	"bow_deerhunter",
	"fa_cz858",				// 10) Semi-automatic rifles
	"fa_fnfal",
	"fa_sks",
	"fa_sks_nobayo",
	"fa_1022_25mag",
	"fa_1022",
	"fa_mp5a3",				// 16) Automatic guns
	"fa_mac10",
	"fa_m16a4",
	"fa_m16a4_carryhandle",
	"fa_870",				// 20) Shotguns
	"fa_500a",
	"fa_superx3",
	"fa_sv10",
	"me_chainsaw",			// 24) Melees
	"me_abrasivesaw",
	"me_fubar",
	"me_axe_fire",
	"me_sledge",
	"me_pipe_lead",
	"me_crowbar",
	"me_pickaxe",
	"me_machete",
	"me_cleaver",
	"me_bat_metal",
	"me_hatchet",
	"me_wrench",
	"me_shovel",
	"me_etool",
	"me_kitknife",
	"tool_welder",			// 40) Tools
	"tool_barricade",
	"tool_extinguisher",
	"tool_flare_gun",
	"item_maglite",
	"item_walkietalkie",
	"item_first_aid",		// 46) Medicines
	"item_bandages",
	"item_gene_therapy",
	"item_pills",
	"exp_molotov",			// 50) Explosives
	"exp_grenade",
	"exp_tnt",
	"ammobox_9mm",			// 53) Ammo types
	"ammobox_12gauge",
	"ammobox_22lr",
	"ammobox_45acp",
	"ammobox_308",
	"ammobox_357",
	"ammobox_556",
	"ammobox_762mm",
	"ammobox_arrow",
	"ammobox_board",
	"ammobox_flare",
	"ammobox_fuel"
};							// 65) Total

enum // types
{
	T_Fists = -1,

	T_Category,
	T_Pistol,
	T_Rifle,
	T_SemiAuto,
	T_Auto,
	T_Shotgun,
	T_Melee,
	T_Tool,
	T_Medicine,
	T_Explosive,
	T_Ammo,

	T_Total
};
enum {P_Type, P_Weight, P_Dmg, P_Hs, P_Stamina, P_Clip, P_Ammo}; // parameters

static const int
	// The order in the category menu
	ORDER[]	= {T_Medicine, T_Tool, T_Pistol, T_Auto, T_SemiAuto, T_Rifle, T_Shotgun, T_Melee, T_Explosive, T_Ammo},
	FIST[]	= {0, 5, 10, 16, 20, 24, 40, 46, 50, 53, 65},	// last cell it's total number items
	OFFSET[]= {1, 4, 5, 2, 6, 3, 7, 8, 12, 14, 15, 13},		// ammo offsets
	PARAMS[][] =	// values from NMRiH v1.11.1
{	// type			weight	dmg		hs	stamina	clip	ammo type
	{T_Pistol,		120,	75,		600,	1,	7,		3},	// fa_1911
	{T_Pistol,		90,		35,		300,	1,	17,		0},	// fa_glock17
	{T_Pistol,		110,	35,		300,	1,	15,		0},	// fa_m92fs
	{T_Pistol,		100,	25,		300,	1,	10,		2},	// fa_mkiii
	{T_Pistol,		130,	125,	600,	1,	6,		5},	// fa_sw686
	{T_Rifle,		450,	250,	900,	1,	10,		4},	// fa_jae700
	{T_Rifle,		400,	250,	900,	1,	5,		4},	// fa_sako85
	{T_Rifle,		380,	250,	900,	1,	5,		4},	// fa_sako85_ironsights
	{T_Rifle,		300,	125,	600,	1,	15,		5},	// fa_winchester1892
	{T_Rifle,		150,	20,		900,	1,	1,		8},	// bow_deerhunter
	{T_SemiAuto,	400,	150,	600,	1,	30,		7},	// fa_cz858
	{T_SemiAuto,	450,	200,	800,	1,	20,		4},	// fa_fnfal
	{T_SemiAuto,	400,	150,	600,	1,	10,		7},	// fa_sks
	{T_SemiAuto,	380,	150,	600,	1,	10,		7},	// fa_sks_nobayo
	{T_SemiAuto,	260,	25,		300,	1,	25,		2},	// fa_1022_25mag
	{T_SemiAuto,	250,	25,		300,	1,	10,		2},	// fa_1022
	{T_Auto,		300,	35,		300,	1,	30,		0},	// fa_mp5a3
	{T_Auto,		300,	62,		510,	1,	30,		3},	// fa_mac10
	{T_Auto,		400,	100,	500,	1,	30,		6},	// fa_m16a4
	{T_Auto,		400,	100,	500,	1,	30,		6},	// fa_m16a4_carryhandle
	{T_Shotgun,		350,	25,		200,	1,	8,		1},	// fa_870		x10
	{T_Shotgun,		350,	25,		200,	1,	5,		1},	// fa_500a		x10
	{T_Shotgun,		350,	25,		200,	1,	5,		1},	// fa_superx3	x10
	{T_Shotgun,		350,	25,		200,	1,	2,		1},	// fa_sv10		x10
	{T_Melee,		600,	65,		160,	1,	100,	11},// me_chainsaw
	{T_Melee,		550,	35,		120,	1,	80,		11},// me_abrasivesaw
	{T_Melee,		450,	110,	680,	40,	-1,		-1},// me_fubar
	{T_Melee,		400,	95,		400,	22,	-1,		-1},// me_axe_fire
	{T_Melee,		400,	100,	600,	35,	-1,		-1},// me_sledge
	{T_Melee,		215,	90,		320,	16,	-1,		-1},// me_pipe_lead
	{T_Melee,		220,	80,		320,	18,	-1,		-1},// me_crowbar	17.5
	{T_Melee,		380,	90,		500,	32,	-1,		-1},// me_pickaxe
	{T_Melee,		120,	80,		350,	14,	-1,		-1},// me_machete
	{T_Melee,		80,		75,		200,	10,	-1,		-1},// me_cleaver
	{T_Melee,		180,	80,		225,	16,	-1,		-1},// me_bat_metal
	{T_Melee,		90,		70,		280,	11,	-1,		-1},// me_hatchet
	{T_Melee,		80,		70,		190,	10,	-1,		-1},// me_wrench
	{T_Melee,		350,	80,		270,	18,	-1,		-1},// me_shovel
	{T_Melee,		200,	80,		230,	16,	-1,		-1},// me_etool
	{T_Melee,		50,		60,		140,	10,	-1,		-1},// me_kitknife
	{T_Tool,		120,	70,		180,	12,	-1,		-1},// tool_welder
	{T_Tool,		80,		70,		210,	10,	1,		9},	// tool_barricade
	{T_Tool,		400,	90,		240,	15,	-1,		-1},// tool_extinguisher
	{T_Tool,		50,		0,		0,		0,	1,		10},// tool_flare_gun
	{T_Tool,		90,		80,		165,	10,	-1,		-1},// item_maglite
	{T_Tool,		50,		0,		0,		0,	-1,		-1},// item_walkietalkie
	{T_Medicine,	85,		0,		0,		0,	-1,		-1},// item_first_aid
	{T_Medicine,	35,		0,		0,		0,	-1,		-1},// item_bandages
	{T_Medicine,	35,		0,		0,		0,	-1,		-1},// item_gene_therapy
	{T_Medicine,	35,		0,		0,		0,	-1,		-1},// item_pills
	{T_Explosive,	100,	150,	525,	0,	1,		-1},// exp_molotov	R=?		10
	{T_Explosive,	100,	1000,	1000,	0,	1,		-1},// exp_grenade	R=256	9
	{T_Explosive,	100,	1500,	1500,	0,	1,		-1},// exp_tnt		R=512	11
	{T_Ammo,		50,		0,		0,		0,	10,		0},	// ammobox_9mm			1
	{T_Ammo,		50,		0,		0,		0,	10,		1},	// ammobox_12gauge		4
	{T_Ammo,		100,	0,		0,		0,	20,		2},	// ammobox_22lr			5
	{T_Ammo,		50,		0,		0,		0,	10,		3},	// ammobox_45acp		2
	{T_Ammo,		50,		0,		0,		0,	10,		4},	// ammobox_308			6
	{T_Ammo,		60,		0,		0,		0,	12,		5},	// ammobox_357			3
	{T_Ammo,		50,		0,		0,		0,	10,		6},	// ammobox_556			7
	{T_Ammo,		50,		0,		0,		0,	10,		7},	// ammobox_762mm		8
	{T_Ammo,		50,		0,		0,		0,	10,		8},	// ammobox_arrow		12
	{T_Ammo,		5,		0,		0,		0,	1,		9},	// ammobox_board		14
	{T_Ammo,		20,		0,		0,		0,	4,		10},// ammobox_flare		15
	{T_Ammo,		250,	0,		0,		0,	50,		11}	// ammobox_fuel			13
//	{T_Fists,		0,		25,		50,		10,	-1,		-1}	// me_fists
},
/*
	(1 << 0)	= IN_ATTACK		+attack
	(1 << 1)	= IN_JUMP		+jump
	(1 << 2)	= IN_DUCK		+duck
	(1 << 3)	= IN_FORWARD	+forward
	(1 << 4)	= IN_BACK		+back
	(1 << 5)	= IN_USE		+use
	(1 << 7)	= IN_LEFT		+left
	(1 << 8)	= IN_RIGHT		+right
	(1 << 9)	= IN_MOVELEFT	+moveleft
	(1 << 10)	= IN_MOVERIGHT	+moveright
	(1 << 11)	= IN_ATTACK2	+attack2
	(1 << 13)	= IN_RELOAD		+reload
	(1 << 15)	= IN_ALT2		+dropweapon
	(1 << 16)	= IN_SCORE		+showscores
	(1 << 17)	= IN_SPEED		+speed
	(1 << 22)	= IN_BULLRUSH	+unload
	(1 << 24)	= IN_GRENADE2	+selectfire
	(1 << 26)	= 				+maglite
	(1 << 27)	= 				+shove
	(1 << 28)	= 				+compass
	(1 << 29)	= 				+inventory
	(1 << 30)	= 				+ammoinv
	(1 << 31)	= 				+voicecmd
*/
	IN_COMPASS	= (1<<28),	// for info panel
	IN_INVENTORY= (1<<29),	// for equipment menu
	IN_AMMOINV	= (1<<30);

bool
	bSpawn,
	bAdmin[MAXPLAYERS+1],
	bLate,
	bRestrictedMap;
int
	iInfo,
	iPAccess,
	iAAccess,
	iZHP,
	iMaxCarry,
	iAmmoOffset		= -1,
	iWpnOffset		= -1,
	iWeightOffset	= -1,
	bCarriedWeapon[MAXPLAYERS+1][65],
	iInMenu[MAXPLAYERS+1] = {-1, ...};
Handle
	hTimer[MAXPLAYERS+1];
Menu
	hMenu[T_Total];

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= "Grey83",
	description	= "Gives weapons and other stuff to the players",
	version		= PL_VER,
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if((iAmmoOffset		= FindSendPropInfo("CNMRiH_Player", "m_iAmmo")) < 1)		// 32 types
		SetFailState("Can't find offset 'm_iAmmo'!");
	if((iWpnOffset		= FindSendPropInfo("CNMRiH_Player", "m_hMyWeapons")) < 1)	// 48 types
		SetFailState("Can't find offset 'm_hMyWeapons'!");
	if((iWeightOffset = FindSendPropInfo("CNMRiH_Player", "_carriedWeight")) < 1)
		SetFailState("Can't find offset '_carriedWeight'!");

	LoadTranslations("nmrih_equipment.phrases.txt");

	CreateConVar("sm_equipment_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_equipment_info", "7", "Add info about items: 1 - weight, 2 - ammo, 4 - kill cost (bullets or stamina)", _, true, _, true, 7.0);
	cvar.AddChangeHook(CVarChanged_Info);
	iInfo = cvar.IntValue;

	cvar = CreateConVar("sm_equipment_spawn", "1", "Show menu for a player who has just been spawned", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Spawn);
	bSpawn = cvar.BoolValue;

	cvar = CreateConVar("sm_equipment_players", "255", "Allowed types for players: 1 - pistols, 2 - rifles, 4 - semiauto, 8 - auto, 16 - shotguns, 32 - melee, 64 - tools, 128 - medicines, 256 - explosives, 512 - ammo", _, true, _, true, 1023.0);
	cvar.AddChangeHook(CVarChanged_PAccess);
	iPAccess = cvar.IntValue;

	cvar = CreateConVar("sm_equipment_admins", "1023", "Allowed types for admins: 1 - pistols, 2 - rifles, 4 - semiauto, 8 - auto, 16 - shotguns, 32 - melee, 64 - tools, 128 - medicines, 256 - explosives, 512 - ammo", _, true, _, true, 1023.0);
	cvar.AddChangeHook(CVarChanged_AAccess);
	iAAccess = cvar.IntValue;

	if((cvar = FindConVar("inv_maxcarry")))
	{
		cvar.AddChangeHook(CVarChanged_MaxCarry);
		iMaxCarry = cvar.IntValue;
	}
	if((cvar = FindConVar("sv_zombie_health")))	// default: 500 (in nightmare: 1000)
	{
		cvar.AddChangeHook(CVarChanged_ZHealth);
		iZHP = cvar.IntValue;
	}

	if(bLate) for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) OnClientPostAdminCheck(i);
	bLate = false;

	hMenu[T_Category] = new Menu(Menu_Categories, MENU_ACTIONS_ALL);
	hMenu[T_Category].SetTitle("%s\n    %s:\n ", PL_NAME, EQUIPMENT_TYPE[T_Category]);
	hMenu[T_Category].ExitButton = true;

	for(int i = T_Pistol, j; i < T_Total; i++)
	{
		hMenu[T_Category].AddItem(NULL_STRING, EQUIPMENT_TYPE[ORDER[i-1]]);

		hMenu[i] = new Menu(Menu_Weapon, MENU_ACTIONS_ALL);
		hMenu[i].SetTitle("%s:\n    %s", PL_NAME, EQUIPMENT_TYPE[i]);
		for(j = FIST[i-1]; j < FIST[i]; j++) hMenu[i].AddItem(NULL_STRING, EQUIPMENT_NAME[j]);
		hMenu[i].ExitBackButton = true;
	}

	RegConsoleCmd("sm_guns", Cmd_Menu);

	HookEvent("player_spawn", Event_Spawn);

	AutoExecConfig(true, "nmrih_equipment");
}

public void CVarChanged_Info(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iInfo = cvar.IntValue;
}

public void CVarChanged_Spawn(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bSpawn = cvar.BoolValue;
}

public void CVarChanged_PAccess(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iPAccess = cvar.IntValue;
}

public void CVarChanged_AAccess(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAAccess = cvar.IntValue;
}

public void CVarChanged_MaxCarry(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxCarry = cvar.IntValue;
}

public void CVarChanged_ZHealth(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iZHP = cvar.IntValue;
}
public void OnMapStart()
{
	char map[16];
	GetCurrentMap(map, sizeof(map));
	bRestrictedMap = map[3] && !StrContains(map, MAP_BANNED);
}

public void OnClientPostAdminCheck(int client)
{
	bAdmin[client] = GetUserAdmin(client) != INVALID_ADMIN_ID;
	SDKHook(client, SDKHook_WeaponDropPost, Hook_WeaponEvent);
	SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEvent);
}

public void Hook_WeaponEvent(int client, int weapon)
{
	RequestFrame(RequestFrame_Callback, GetClientUserId(client));
}

public void RequestFrame_Callback(any client)
{
	if(!(client = GetClientOfUserId(client))) return;

	GetCarriedWeapons(client);
	if(iInMenu[client] != -1) hMenu[iInMenu[client]].Display(client, MENU_TIME_FOREVER);
	if(hTimer[client]) Timer_ItemsList(hTimer[client], GetClientUserId(client));
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(bSpawn && (client = GetClientOfUserId(event.GetInt("userid"))) && IsPlayerAlive(client))
		SendMenu(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerValid(client))
		return Plugin_Continue;

	static bool changed, menu[MAXPLAYERS+1], info[MAXPLAYERS+1];
	changed = menu[0] = info[0] = false;
	if(buttons & IN_AMMOINV)
	{
		menu[0] = !!(buttons & IN_INVENTORY);
		if(!bRestrictedMap && menu[0] && !menu[client])
		{
			SendMenu(client);
			buttons &= ~IN_INVENTORY;
			changed = true;
		}

		info[0] = !!(buttons & IN_COMPASS);
		if(info[0] && !info[client])
		{
			ToggleHintPanel(client);
			buttons &= ~IN_COMPASS;
			changed = true;
		}
	}
	menu[client] = menu[0];
	info[client] = info[0];
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	iInMenu[client] = -1;
	bAdmin[client] = false;
	if(hTimer[client]) delete hTimer[client];
}

public Action Cmd_Menu(int client, int args)
{
	if(!bRestrictedMap && IsPlayerValid(client)) SendMenu(client);

	return Plugin_Handled;
}

stock void SendMenu(const int client)
{
	if(!iPAccess && !(bAdmin[client] && iAAccess))
		return;

	iInMenu[client] = T_Category;
	hMenu[T_Category].Display(client, MENU_TIME_FOREVER);
}

public int Menu_Categories(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			static int weight, num;
			weight = GetEntData(client, iWeightOffset);
			num = GetCarriedWeapons(client);
			menu.SetTitle("%t\n  %i/%i (%i %t)\n    %t:\n ", "Title", weight, iMaxCarry, num, "items", EQUIPMENT_TYPE[T_Category]);
		}
		case MenuAction_DrawItem:
		{
			static int i;
			i = 1 << (ORDER[param] - 1);
			return iPAccess & i || (bAdmin[client] && iAAccess & i) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		}
		case MenuAction_DisplayItem:
		{
			static char buffer[256];
			SetGlobalTransTarget(client);
			FormatEx(buffer, sizeof(buffer), "%t (%i)", EQUIPMENT_TYPE[ORDER[param]], FIST[ORDER[param]] - FIST[ORDER[param]-1]);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Select:
		{
			iInMenu[client] = ORDER[param];
			hMenu[ORDER[param]].Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
			if(param == MenuCancel_Exit) iInMenu[client] = -1;
	}
	return 0;
}

public int Menu_Weapon(Menu menu, MenuAction action, int client, int param)
{
	static int item;
	switch(action)
	{
		case MenuAction_Display:
		{
			static int num;
			num = GetCarriedWeapons(client);
			menu.SetTitle("%t\n  %i/%i (%i %t)\n    %t:\n ", "Title", GetEntData(client, iWeightOffset), iMaxCarry, num, "items", EQUIPMENT_TYPE[iInMenu[client]]);
		}
		case MenuAction_DrawItem:
		{
			item = param + FIST[iInMenu[client]-1];
			return !bCarriedWeapon[client][item] && GetEntData(client, iWeightOffset) + PARAMS[item][P_Weight] <= iMaxCarry ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		}
		case MenuAction_DisplayItem:
			return RedrawMenuItem(FillMenuItem(client, param+FIST[iInMenu[client]-1]));
		case MenuAction_Select:
		{
			static int wpn;
			item = param + FIST[iInMenu[client]-1];
			if(item < 53)
			{
				if((wpn = GivePlayerItem(client, EQUIPMENT_NAME[item])) == -1)
					PrintToChat(client, "%t%t", "Prefix", "AlreadyHave", EQUIPMENT_NAME[item]);
				else
				{
					if(AcceptEntityInput(wpn, "use", client, client)) bCarriedWeapon[client][item] = true;
					PrintToChat(client, "%t%t", "Prefix", "HaveChosen", EQUIPMENT_NAME[item]);
				}
			}
			else if(iAmmoOffset > 0)
			{
				wpn = iAmmoOffset + OFFSET[item - 53] * 4;
				SetEntData(client, wpn, GetEntData(client, wpn) + PARAMS[item][P_Clip], _, true);
				PrintToChat(client, "%t%t", "Prefix", "AddedAmmo", EQUIPMENT_NAME[item], PARAMS[item][P_Clip]);
				menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack)	SendMenu(client);
			else if(param == MenuCancel_Exit)	iInMenu[client] = -1;
		}
	}

	return 0;
}

stock int GetCarriedWeapons(const int client)
{
	static int i, num, j;
	static char cls[24];
	for(i = 0; i < 53; i++) bCarriedWeapon[client][i] = false;
	for(num = i = 0; i < 48; i++)	// m_hMyWeapons contain 48 cells
		if((j = GetEntDataEnt2(client, iWpnOffset + i * 4)) != -1 && GetEdictClassname(j, cls, sizeof(cls)))
			for(j = 0; j < 53; j++) if(!strcmp(cls, EQUIPMENT_NAME[j]))
			{
				bCarriedWeapon[client][j] = true;
				num++;
				break;
			}
	return num;
}

stock char FillMenuItem(const int client, const int item)
{
	static char buffer[256];
	buffer[0] = 0;
	if(iInfo & 2 && PARAMS[item][P_Stamina] == 1)		// Ammo
		FormatEx(buffer, sizeof(buffer), " '%T' x%i", EQUIPMENT_NAME[53 + PARAMS[item][P_Ammo]], client, PARAMS[item][P_Clip]);
	if(iInfo & 4 && iZHP && PARAMS[item][P_Stamina])	// Kill cost
	{
		static float mult;
		if(item == 30)	// me_crowbar have float value of the QuickAttackStaminaCost
			mult	= iZHP * 17.5;
		else mult	= iZHP * (PARAMS[item][P_Stamina] + 0.0);
		Format(buffer, sizeof(buffer), "%s\n…Kill cost: %i - %i",
			buffer, RoundToNearest(mult / PARAMS[item][P_Hs]), RoundToNearest((mult / PARAMS[item][P_Dmg])));
	}	// Weight
	if(iInfo & 1 && PARAMS[item][P_Stamina]) Format(buffer, sizeof(buffer), "…%i%s", PARAMS[item][P_Weight], buffer);
	Format(buffer, sizeof(buffer), "%T%s\n%s", EQUIPMENT_NAME[item], client, bCarriedWeapon[client][item] ? " ☑" : "", buffer);
	return buffer;
}

void ToggleHintPanel(const int client)
{
	if(!client)
		return;

	if(hTimer[client]) delete hTimer[client];
	else hTimer[client] = CreateTimer(1.0, Timer_ItemsList, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_ItemsList(Handle timer, any client)
{
	if(!(client = GetClientOfUserId(client)))
	{
		timer = null;
		return Plugin_Stop;
	}

	if(!GetCarriedWeapons(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	static int i;
	static char buffer[256];
	buffer[0] = 0;
	for(i = 0; i < 53; i++) if(bCarriedWeapon[client][i])	// everything except ammo
		Format(buffer, sizeof(buffer), "%s%T\n", buffer, EQUIPMENT_NAME[i], client);
	buffer[strlen(buffer)-1] = 0;

	Handle msg = StartMessageOne("KeyHintText", client);
	BfWriteByte(msg, 1);
	BfWriteString(msg, buffer);
	EndMessage();

	return Plugin_Continue;
}

stock bool IsPlayerValid(const int client)
{
	return 0 < client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}