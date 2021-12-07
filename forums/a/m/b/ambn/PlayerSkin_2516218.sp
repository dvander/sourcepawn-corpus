#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <n_arm_fix>

#define PLUGIN_VERSION "3.0.6 (Public version + Single Flag Support Only)"
#define PLUGIN_AUTHOR "noBrain"
#define MAX_SKIN_PATH 256
//flags
/*
#define RESERVATION ADMFLAG_RESERVATION
#define GENERIC ADMFLAG_GENERIC
#define KICK ADMFLAG_KICK
#define BAN	ADMFLAG_BAN
#define	UNBAN ADMFLAG_UNBAN
#define	SLAY ADMFLAG_SLAY
#define	CHANGEMAP ADMFLAG_CHANGEMAP
#define	CVAR ADMFLAG_CONVARS
#define	CONFIG ADMFLAG_CONFIG
#define	CHAT ADMFLAG_CHAT
#define	VOTE ADMFLAG_VOTE
#define	PASSWORD ADMFLAG_PASSWORD
#define	RCON ADMFLAG_RCON
#define	CHEATS ADMFLAG_CHEATS
#define	ROOT ADMFLAG_ROOT
#define	CUSTOM1 ADMFLAG_CUSTOM1
#define	CUSTOM2 ADMFLAG_CUSTOM2
#define	CUSTOM3 ADMFLAG_CUSTOM3
#define	CUSTOM4 ADMFLAG_CUSTOM4
#define	CUSTOM5 ADMFLAG_CUSTOM5
#define	CUSTOM6 ADMFLAG_CUSTOM6
*/
ConVar g_cFix = null;
ConVar g_bomb = null;
ConVar d_ct_skin = null;
ConVar d_ct_arm = null;
ConVar d_t_skin = null;
ConVar d_t_arm = null;
ConVar m_custom = null;
ConVar m_custom2 = null;
ConVar m_classic = null;
ConVar m_awp = null;
ConVar g_smodel = null;
ConVar g_epskin = null;
ConVar g_sReset = null;
ConVar g_gHaveCategories = null;
ConVar g_aAutoMod = null;
ConVar g_aAutoSkin = null;
ConVar g_aAutoShowMenu = null;

char g_szPlayerSkinPath[MAXPLAYERS+1][MAX_SKIN_PATH];
char g_szPlayerArmPath[MAXPLAYERS+1][MAX_SKIN_PATH];
char weaponClass[MAXPLAYERS+1][5][32];
char d_gct_skin[64], d_gct_arm[64], d_gt_skin[64], d_gt_arm[64];
char StrSkinTeam[MAXPLAYERS+1][2];
char AdminUserFlags[MAXPLAYERS+1][4];
char ServerMapMod[32];

bool g_bUserHasSkins[MAXPLAYERS+1] = false;
bool g_bUserHasArms[MAXPLAYERS+1];
//bool UserGotDefSkins[MAXPLAYERS+1];
bool IsRoundFresh;


int SkinTeam[MAXPLAYERS+1];
int playerWeapons[MAXPLAYERS + 1][5];
int UserCurrentTeam[MAXPLAYERS + 1];

public Plugin myinfo =  {

	name = "PlayerSkin",
	author = PLUGIN_AUTHOR,
	description = "Allow players to select their skins.",
	version = PLUGIN_VERSION,

};

public void OnPluginStart() 
{

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", PlayerDisConnect, EventHookMode_PostNoCopy);
	HookEvent("cs_pre_restart", RoundPreChange);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", PlayerDeath);
	RegConsoleCmd("sm_pskin", Command_PlayerSkin);
	RegConsoleCmd("sm_models", Command_PlayerSkin);
	RegConsoleCmd("sm_skins", Command_PlayerSkin);
	//RegConsoleCmd("sm_printi", Command_Print);

	g_cFix = CreateConVar("sm_pg_cFix", "1", "Allow Plugin To Apply An Arm fix on player spawn.");
	g_bomb = CreateConVar("sm_map_bomb", "0", "Set this to 1 if your map is a bomb defusal map.");
	d_ct_skin = CreateConVar("sm_ct_model", "models/player/ctm_fbi.mdl");
	d_ct_arm = CreateConVar("sm_ct_arm", "models/weapons/ct_arms.mdl");
	d_t_skin = CreateConVar("sm_t_model", "models/player/tm_phoenix.mdl");
	d_t_arm = CreateConVar("sm_t_arm", "models/weapons/t_arms.mdl");
	m_classic = CreateConVar("sm_map_classic", "0", "Gives Knife + Pistol + Previous Gun To Players");
	m_awp = CreateConVar("sm_map_awp", "0", "Give Knife + Awp To Players");
	m_custom = CreateConVar("sm_map_custom", "0", "Give Knife + Previous Weapon To Players");
	m_custom2 = CreateConVar("sm_map_custom2", "1", "Give Knife To Players");
	g_smodel = CreateConVar("sm_map_mstay", "0", "remove player's selected skin on map change and needed to be chosen again.");
	g_epskin = CreateConVar("sm_pskin_enable", "1", "Enable/Disable Command pskin");
	g_sReset = CreateConVar("sm_force_arms_change", "1", "If ture, then player's arms will reset on pick.");
	g_gHaveCategories = CreateConVar("sm_cat_enable", "0", "Enable/Disable categories support");
	g_aAutoMod = CreateConVar("sm_auto_map_mode", "1", "If true, plugin will detect map mode it self");
	g_aAutoSkin = CreateConVar("sm_auto_skin_set", "1", "If true, plugin will use convars and file to set your skin automatically");
	g_aAutoShowMenu = CreateConVar("sm_start_menu", "0", "If true, will show skin menu to all users.");
	
}

/*public Action Command_Print(int client, int args)
{
	char User[32];
	GetCmdArg(1, User, sizeof(User));
	int target = FindTarget(client, User);
	PrintToServer("Admin User Flag : %s", AdminUserFlags[target]);
	PrintToServer("Server Mod Map Is %s", ServerMapMod);
	int int1, int2, int3, int4;
	int1 = GetConVarInt(m_classic);
	int2 = GetConVarInt(m_awp);
	int3 = GetConVarInt(m_custom);
	int4 = GetConVarInt(m_custom2);
	PrintToServer("Int ha Bet Tartiv %d %d %d %d", int1, int2, int3, int4);
	return;
}*/
public void OnMapStart() 
{
	CreateTimer(1.0, CheckMapMod);
	if(!GetConVarBool(g_smodel))
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientConnected(client))
			{
				g_bUserHasSkins[client] = false;
				g_bUserHasArms[client] = false;
			}
		}
	}
	char Arms[128], Skin[128];
	GetConVarString(d_ct_arm, d_gct_arm, sizeof(d_gct_arm));
	GetConVarString(d_t_arm, d_gt_arm, sizeof(d_gt_arm));
	GetConVarString(d_ct_skin, d_gct_skin, sizeof(d_gct_skin));
	GetConVarString(d_t_skin, d_gt_skin, sizeof(d_gt_skin));
	
	PrecacheModel(d_gct_arm);
	PrecacheModel(d_gt_arm);
	PrecacheModel(d_gct_skin);
	PrecacheModel(d_gt_skin);
	
	Handle kv = CreateKeyValues("Skins");
	Handle kt = CreateKeyValues("Admin_Skins");
	FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");
	FileToKeyValues(kt, "addons/sourcemod/configs/admin_skin.ini");
	KvGotoFirstSubKey(kv, false);
	KvGotoFirstSubKey(kt, false);

	do 
	{
	
		KvGetString(kv, "Skin", Skin, sizeof(Skin), "");
		KvGetString(kv, "Arms", Arms, sizeof(Arms), "");

		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}

		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kv, false));
	
	do 
	{
	
		KvGetString(kt, "SkinT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));
	
	do 
	{
	
		KvGetString(kt, "SkinCT", Skin, sizeof(Skin), "");
		KvGetString(kt, "ArmsCT", Arms, sizeof(Arms), "");
		if(!StrEqual(Arms, "")) 
		{
			PrecacheModel(Arms);
		}
		if(!StrEqual(Skin, ""))
		{
			PrecacheModel(Skin);
		}

	} while (KvGotoNextKey(kt, false));

	CloseHandle(kv);
	CloseHandle(kt);
	Handle FileDownloader;
	AddFilesToDownload(FileDownloader, "addons/sourcemod/configs/download_list.ini");
	CloseHandle(FileDownloader);

}

public Action CheckMapMod(Handle timer)
{
	if(!GetConVarBool(g_aAutoMod))
	{
		return Plugin_Handled;
	}
	CheckServerMod(ServerMapMod, sizeof(ServerMapMod));
	if(StrEqual(ServerMapMod, "MAP_ZM") || StrEqual(ServerMapMod, "MAP_ZE"))
	{
		Handle PluginName = null;
		char Plugin_Name[32];
		GetPluginFilename(PluginName, Plugin_Name, sizeof(Plugin_Name));
		ServerCommand("sm plugins unload %s", Plugin_Name);
		CloseHandle(PluginName);
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(0.1, AdminCheck, client);
}

public Action AdminCheck(Handle timer, any client)
{
	if(IsUserAdmin(client))
	{
		//Format(AdminUserFlags[client], sizeof(AdminUserFlags[]), GetUserCFlags(client));
		GetUserCFlags(client, AdminUserFlags[client]);
	}
}

public Action PlayerDisConnect(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bUserHasSkins[client] = false;
	g_bUserHasArms[client] = false;
	//Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), "");
	//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), "");
	return Plugin_Continue;
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarBool(g_aAutoShowMenu))
	{
		if(GetConVarBool(g_gHaveCategories))
		{
			if(IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
			{
				DisplaySkinMenu(client, true);
			}
		}
		else if(!GetConVarBool(g_gHaveCategories))
		{
			if(IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client))
			{
				DisplaySkinMenu(client, false);
			}
		}
	}
	CreateTimer(0.2, SetSkins, GetEventInt(event, "userid"));
	if(UserCurrentTeam[client] != GetClientTeam(client))
	{
		g_bUserHasSkins[client] = false;
	}
	if(IsUserAdmin(client) && !g_bUserHasSkins[client] && GetConVarBool(g_aAutoSkin))
	{
		bool s_gSkinFound = false;
		char SectionName[16];
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, "addons/sourcemod/configs/admin_skin.ini");
		KvGotoFirstSubKey(kv, true);
		do
		{
			KvGetSectionName(kv, SectionName, sizeof(SectionName));
			if(StrContains(SectionName, AdminUserFlags[client], false) != -1)
			{
				s_gSkinFound = true;
				break;
			}
			else
			{
				continue;
			}
		}
		while(s_gSkinFound == false && KvGotoNextKey(kv, true));
		if(s_gSkinFound)
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				UserCurrentTeam[client] = 2;
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				if(!StrEqual(SkinPathT, ""))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathT, ""))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						g_bUserHasArms[client] = false;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
				}
			}
			if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				UserCurrentTeam[client] = 3;
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				if(!StrEqual(SkinPathCT, ""))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathCT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathCT, ""))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathCT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						g_bUserHasArms[client] = false;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
				}
			}
		}
		CloseHandle(kv);
	}
	else if(!IsUserAdmin(client) && !g_bUserHasSkins[client] && GetConVarBool(g_aAutoSkin))
	{
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, "addons/sourcemod/configs/admin_skin.ini");
		if(KvJumpToKey(kv, "def", false))
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				UserCurrentTeam[client] = 2;
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				if(!StrEqual(SkinPathT, ""))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathT, ""))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						g_bUserHasArms[client] = false;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
				}
			}
			if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				UserCurrentTeam[client] = 3;
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				if(!StrEqual(SkinPathCT, ""))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathCT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathCT, ""))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathCT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						g_bUserHasArms[client] = false;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
				}
			}
		}
		CloseHandle(kv);
	}
	return Plugin_Continue;

}

public Action RoundPreChange(Handle event, const char[] name, bool dontBroadcast) 
{
	IsRoundFresh = true;
	if(GetConVarBool(g_cFix)) 
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientWeapons(i);
				StripAllWeapons(i);
			}
		}
	}
	return Plugin_Continue;
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.3, GiveWeapons);
	return Plugin_Continue;
}

public Action GiveWeapons(Handle timer)
{
	IsRoundFresh = false;
	if(GetConVarBool(g_cFix)) 
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			StripAllWeapons(client);
		}
		if(GetConVarBool(m_classic))
		{
			SetConVarBool(m_awp, false);
			SetConVarBool(m_custom, false);
			SetConVarBool(m_custom2, false);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GiveClientWeapons(i);
					int TeamID = GetClientTeam(i);
					GivePlayerItem(i, "weapon_knife")
					if(TeamID == 2)
					{
						GivePlayerItem(i, "weapon_glock");
					}
					else if(TeamID == 3)
					{
						GivePlayerItem(i, "weapon_hkp2000");
					}
				}
			}
		}
		else if(GetConVarBool(m_awp))
		{
			SetConVarBool(m_classic, false);
			SetConVarBool(m_custom, false);
			SetConVarBool(m_custom2, false);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GivePlayerItem(i, "weapon_knife");
					GivePlayerItem(i, "weapon_awp");
				}
			}
		}
		else if(GetConVarBool(m_custom))
		{
			SetConVarBool(m_classic, false);
			SetConVarBool(m_awp, false);
			SetConVarBool(m_custom2, false);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GiveClientWeapons(i);
					GivePlayerItem(i, "weapon_knife")
				}
			}
		}
		else if(GetConVarBool(m_custom2))
		{
			SetConVarBool(m_classic, false);
			SetConVarBool(m_awp, false);
			SetConVarBool(m_custom, false);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					GivePlayerItem(i, "weapon_knife")
				}
			}
		}
	}
	if(GetConVarBool(g_bomb))
	{
		GiveC4();
	}
	return Plugin_Continue;
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	for(int slot = 0; slot <= 4; slot++)
	{
		playerWeapons[client][slot] = -1;
		weaponClass[client][slot] = "";
	}
	return Plugin_Continue;

}


public Action SetSkins(Handle timer, any userid) {

	int client = GetClientOfUserId(userid);

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return Plugin_Stop;

	}

	if(GetConVarBool(g_cFix)) 
	{
		StripAllWeapons(client);
		if(!IsRoundFresh)
		{
			if(GetConVarBool(m_classic))
			{
				int TeamID = GetClientTeam(client);
				if(TeamID == 2)
				{
					GivePlayerItem(client, "weapon_knife");
					GivePlayerItem(client, "weapon_glock");
				}
				else if(TeamID == 3)
				{
					GivePlayerItem(client, "weapon_knife");
					GivePlayerItem(client, "weapon_hkp2000");
				}
			}
			if(GetConVarBool(m_awp))
			{
				GivePlayerItem(client, "weapon_knife")
				GivePlayerItem(client, "weapon_awp");
			}
			if(GetConVarBool(m_custom))
			{
				GivePlayerItem(client, "weapon_knife")
			}
			if(GetConVarBool(m_custom2))
			{
				GivePlayerItem(client, "weapon_knife")
			}
		}
	}
	return Plugin_Continue;
}

public void ArmsFix_OnArmsSafe(int client)
{

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;

	}

	if(g_bUserHasSkins[client] == true) 
	{
		if(g_bUserHasArms[client] == true) 
		{
			if(!IsModelPrecached(g_szPlayerArmPath[client]))
			{
				PrecacheModel(g_szPlayerArmPath[client])
			}
			SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szPlayerArmPath[client]);

		} else if(g_bUserHasArms[client] == false) {

			int iTeamID = GetClientTeam(client);
			if(iTeamID == 2) 
			{

				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl");

			} else if(iTeamID == 3) 
			{

				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");

			}

		}

	}
	else if(g_bUserHasSkins[client] == false && GetConVarBool(g_aAutoSkin))
	{
		int TeamID = GetClientTeam(client);
		if(TeamID == 2)
		{
			SetEntPropString(client, Prop_Send, "m_szArmsModel", d_gt_arm);
		}
		else if(TeamID == 3)
		{
			SetEntPropString(client, Prop_Send, "m_szArmsModel", d_gct_arm);
		}
	}

}

public void ArmsFix_OnModelSafe(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;

	}
	if(g_bUserHasSkins[client] == true) 
	{
		if(!IsModelPrecached(g_szPlayerSkinPath[client]))
		{
			PrecacheModel(g_szPlayerSkinPath[client])
		}
		if(StrEqual(StrSkinTeam[client], ""))
		{
			SetEntityModel(client, g_szPlayerSkinPath[client]);
		}
		else if(!StrEqual(StrSkinTeam[client], ""))
		{
			if(GetClientTeam(client) == SkinTeam[client])
			{
				SetEntityModel(client, g_szPlayerSkinPath[client]);
			}
		}
	}
	else if(g_bUserHasSkins[client] == false && GetConVarBool(g_aAutoSkin))
	{
		int TeamID = GetClientTeam(client);
		if(TeamID == 2)
		{
			SetEntityModel(client, d_gt_skin);
		}
		else if(TeamID == 3)
		{
			SetEntityModel(client, d_gct_skin);
		}
	}
}

public Action Command_PlayerSkin(int client, int args) 
{
	if(GetConVarBool(g_epskin))
	{
		if(GetConVarBool(g_gHaveCategories))
		{
			DisplaySkinMenu(client, true);
		}
		else if(!GetConVarBool(g_gHaveCategories))
		{
			DisplaySkinMenu(client, false);
		}
	}
	else
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01Command !pskin is disabled by server operator!");
		return Plugin_Continue;
	}
	return Plugin_Continue;

}

stock Action DisplaySkinMenu(int client, bool HaveCategories) {

	if(HaveCategories)
	{
		char SkinName[32], UniqueId[32];
		Handle menu = CreateMenu(SkinMenuHandle);
		SetMenuTitle(menu, "Select a Category :");
		Handle kt = CreateKeyValues("Categories");
		FileToKeyValues(kt, "addons/sourcemod/configs/categories.ini");
		KvGotoFirstSubKey(kt, false);
		do
		{
			KvGetString(kt, "Name", SkinName, sizeof(SkinName));
			KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
			AddMenuItem(menu, UniqueId, SkinName);
		}
		while(KvGotoNextKey(kt, false))
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		SetMenuExitButton(menu, true);
		CloseHandle(kt)
	}
	else if(!HaveCategories)
	{
		char SkinName[32], UniqueId[32];
		Handle menu = CreateMenu(SkinMenu);
		AddMenuItem(menu, "def", "Choose Default Skin");
		SetMenuTitle(menu, "Select a Skin");
		Handle kv = CreateKeyValues("Skins");
		FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");
		KvGotoFirstSubKey(kv, false);
		do {
			KvGetString(kv, "Name", SkinName, sizeof(SkinName));
			KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
			AddMenuItem(menu, UniqueId, SkinName);
		}
		while(KvGotoNextKey(kv, false));
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		SetMenuExitButton(menu, true);
		CloseHandle(kv);
	}
	return Plugin_Continue;
}

public int SkinMenuHandle(Handle menu, MenuAction action, int param1, int param2)
{

	char SkinName[32], UniqueId[32], Flag[16], ADMFlag[16];
	Handle kv = CreateKeyValues("Categories");
	FileToKeyValues(kv, "addons/sourcemod/configs/categories.ini");

	switch (action) 
	{
		case MenuAction_Select: 
		{
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);
			do
			{
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(StrEqual(item, UniqueId))
				{
					KvGetString(kv, "Flag", ADMFlag, sizeof(ADMFlag));
					Handle smenu = CreateMenu(SkinMenu);
					AddMenuItem(smenu, "def", "Choose Default Skin");
					Handle kt = CreateKeyValues("skins");
					FileToKeyValues(kt, "addons/sourcemod/configs/skin.ini");
					KvGotoFirstSubKey(kt, false);
					do
					{
						KvGetString(kt, "Flag", Flag, sizeof(Flag));
						if(StrEqual(ADMFlag, Flag))
						{
							KvGetString(kt, "Name", SkinName, sizeof(SkinName));
							KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
							AddMenuItem(smenu, UniqueId, SkinName);
						}
					}
					while(KvGotoNextKey(kt, false));
					DisplayMenu(smenu, param1, MENU_TIME_FOREVER);
					SetMenuExitButton(smenu, true);
					CloseHandle(kt);
					CloseHandle(kv);
				}
				else
				{
					KvGotoNextKey(kv, false);
				}
			}
			while(!StrEqual(item, UniqueId));
			
		}
		case MenuAction_End: 
		{

			CloseHandle(kv);
			CloseHandle(menu);
		}
	}
}



public int SkinMenu(Handle menu, MenuAction action, int param1, int param2) {

	char SkinName[32], SkinPath[128], ArmPath[128], UniqueId[32], Flag[16], StriTeamID[32];
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, "addons/sourcemod/configs/skin.ini");

	switch (action) {

		case MenuAction_Select: {

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);

			do {

				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));

				if (StrEqual(item, "def")) {

					g_bUserHasSkins[param1] = false;
					CloseHandle(kv);
					CloseHandle(menu);
					break;

				}
				

				if (StrEqual(item, UniqueId)) 
				{
					int iTeamID = KvGetNum(kv, "Team");
					KvGetString(kv, "Team", StriTeamID, sizeof(StriTeamID));

					if(!StrEqual(StriTeamID, ""))
					{
						if(GetClientTeam(param1) != iTeamID) 
						{
							PrintToChat(param1, " \x10[PlayerSkin] \x01This Selected Skin Is Not For Your Team!");
							return;
						}
					}

					SkinTeam[param1] = iTeamID;
					//StrSkinTeam[param1] = StriTeamID;
					Format(StrSkinTeam[param1], sizeof(StrSkinTeam[]), StriTeamID);
					KvGetString(kv, "Name", SkinName, sizeof(SkinName));
					KvGetString(kv, "Skin", SkinPath, sizeof(SkinPath));
					KvGetString(kv, "Arms", ArmPath, sizeof(ArmPath));
					KvGetString(kv, "Flag", Flag, sizeof(Flag));
					ReplaceString(Flag, sizeof(Flag), "a", "1");
					ReplaceString(Flag, sizeof(Flag), "b", "2");
					ReplaceString(Flag, sizeof(Flag), "c", "4");
					ReplaceString(Flag, sizeof(Flag), "d", "8");
					ReplaceString(Flag, sizeof(Flag), "e", "16");
					ReplaceString(Flag, sizeof(Flag), "f", "32");
					ReplaceString(Flag, sizeof(Flag), "g", "64");
					ReplaceString(Flag, sizeof(Flag), "h", "128");
					ReplaceString(Flag, sizeof(Flag), "i", "256");
					ReplaceString(Flag, sizeof(Flag), "j", "512");
					ReplaceString(Flag, sizeof(Flag), "k", "1024");
					ReplaceString(Flag, sizeof(Flag), "l", "2048");
					ReplaceString(Flag, sizeof(Flag), "m", "4096");
					ReplaceString(Flag, sizeof(Flag), "n", "8192");
					ReplaceString(Flag, sizeof(Flag), "z", "16384");
					ReplaceString(Flag, sizeof(Flag), "o", "32768");
					ReplaceString(Flag, sizeof(Flag), "p", "65536");
					ReplaceString(Flag, sizeof(Flag), "q", "131072");
					ReplaceString(Flag, sizeof(Flag), "r", "262144");
					ReplaceString(Flag, sizeof(Flag), "s", "524288");
					ReplaceString(Flag, sizeof(Flag), "t", "1048576");
					if(StrEqual(Flag, ""))
					{
						SetEntityModel(param1, SkinPath);
						PrintToChat(param1, " \x10[PlayerSkin] \x01You are now \x04%s", SkinName);
					}
					else if(!StrEqual(Flag, ""))
					{
						int UserFlag = StringToInt(Flag);
						if(CheckCommandAccess(param1, "command_PlayerVIP", UserFlag))
						{
							SetEntityModel(param1, SkinPath);
							PrintToChat(param1, " \x10[PlayerSkin] \x01You are now a \x04%s", SkinName);
						}
						else if(!CheckCommandAccess(param1, "command_PlayerVIP", UserFlag))
						{
							PrintToChat(param1, " \x10[PlayerSkin] \x01You do not have needed permissions to use this skin!");
							return;
						}
					}
					if(!StrEqual(ArmPath, "")) {

						SetEntPropString(param1, Prop_Send, "m_szArmsModel", ArmPath);
						g_bUserHasArms[param1] = true;

					} else if(StrEqual(ArmPath, "")) {

						g_bUserHasArms[param1] = false;

					}

					g_bUserHasSkins[param1] = true;
					Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), SkinPath); 
					Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), ArmPath);
					if(GetConVarBool(g_sReset))
					{
						ResetArms(param1);
					}
				} 
				else 
				{

					KvGotoNextKey(kv, false);

				}

			} while (!StrEqual(item, UniqueId));

		}

		case MenuAction_End: {

			CloseHandle(kv);
			CloseHandle(menu);
		}

	}

}

stock void StripAllWeapons(int client) {

	if (client < 1 || client > MaxClients || !IsClientInGame(client)) {

		return;

	}

	int weapon;
	for (int i; i < 4; i++) {
	
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
		
			if (IsValidEntity(weapon)) {
			
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
				
			}
			
		}
		
	}
	
}
stock void GetClientWeapons(int client)
{
    for(int slot = 0; slot <= 4; slot++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            playerWeapons[client][slot] = GetPlayerWeaponSlot(client, slot);
            if(playerWeapons[client][slot] > MaxClients)
            {
                GetEdictClassname(playerWeapons[client][slot], weaponClass[client][slot], 32);
            }
            else weaponClass[client][slot] = "";
        }
    }
}

stock void GiveClientWeapons(int client)
{
    for(int slot = 0; slot <= 4; slot++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            if(playerWeapons[client][slot] > MaxClients)
            {
                GivePlayerItem(client, weaponClass[client][slot]);
            }
        }
    }
}

public int GetRandomPlayer(int team)
{
    int RandomClient;

    ArrayList ValidClients = new ArrayList();
    
    for(int i = 1; i < MaxClients; i++)
    {
        if(IsValidClient(i) && GetClientTeam(i) == team)
        {
            ValidClients.Push(i);
        }
    }
    
    RandomClient = ValidClients.Get(GetRandomInt(0, ValidClients.Length - 1));
    
    delete ValidClients;
  
    return RandomClient;
}

stock bool IsValidClient(int client) 
{ 
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client)); 
} 
stock void GiveC4()
{
	char WeaponName[32];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			for(int slot = 0; slot <= 4; slot++)
			{
				int ent = GetPlayerWeaponSlot(i, slot);
				if(ent != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEdictClassname(ent, WeaponName, sizeof(WeaponName));
						if(StrEqual(WeaponName, "weapon_c4"))
						{
							RemovePlayerItem(i, ent);
						}
					}
				}
			}
		}
	}
	CreateTimer(0.1, GiveBomb);
}
public Action GiveBomb(Handle timer)
{
	int user = GetRandomPlayer(2);
	GivePlayerItem(user, "weapon_c4");
	PrintToChat(user, " \x10[PlayerSkin] \x01You are now holding the bomb!");
}
char GetUserCFlags(int client, char StrFlag[4])
{
	int UserFlagBits = GetUserFlagBits(client);
	char Flag[8];
	IntToString(UserFlagBits, Flag, sizeof(Flag));
	if(StrEqual(Flag, "1"))
	{
		ReplaceString(Flag, sizeof(Flag), "1", "a");
	}
	else if(StrEqual(Flag, "2"))
	{
		ReplaceString(Flag, sizeof(Flag), "2", "b");
	}
	else if(StrEqual(Flag, "4"))
	{
		ReplaceString(Flag, sizeof(Flag), "4", "c");
	}
	else if(StrEqual(Flag, "8"))
	{
		ReplaceString(Flag, sizeof(Flag), "8", "d");
	}
	else if(StrEqual(Flag, "16"))
	{
		ReplaceString(Flag, sizeof(Flag), "16", "e");
	}
	else if(StrEqual(Flag, "32"))
	{
		ReplaceString(Flag, sizeof(Flag), "32", "f");
	}
	else if(StrEqual(Flag, "64"))
	{
		ReplaceString(Flag, sizeof(Flag), "64", "g");
	}
	else if(StrEqual(Flag, "128"))
	{
		ReplaceString(Flag, sizeof(Flag), "128", "h");
	}
	else if(StrEqual(Flag, "256"))
	{
		ReplaceString(Flag, sizeof(Flag), "256", "i");
	}
	else if(StrEqual(Flag, "512"))
	{
		ReplaceString(Flag, sizeof(Flag), "512", "j");
	}
	else if(StrEqual(Flag, "1024"))
	{
		ReplaceString(Flag, sizeof(Flag), "1024", "k");
	}
	else if(StrEqual(Flag, "2048"))
	{
		ReplaceString(Flag, sizeof(Flag), "2048", "l");
	}
	else if(StrEqual(Flag, "4096"))
	{
		ReplaceString(Flag, sizeof(Flag), "4096", "m");
	}
	else if(StrEqual(Flag, "8192"))
	{
		ReplaceString(Flag, sizeof(Flag), "8192", "n");
	}
	else if(StrEqual(Flag, "16384"))
	{
		ReplaceString(Flag, sizeof(Flag), "16384", "z");
	}
	else if(StrEqual(Flag, "32768"))
	{
		ReplaceString(Flag, sizeof(Flag), "32768", "o");
	}
	else if(StrEqual(Flag, "65536"))
	{
		ReplaceString(Flag, sizeof(Flag), "65536", "p");
	}
	else if(StrEqual(Flag, "131072"))
	{
		ReplaceString(Flag, sizeof(Flag), "131072", "q");
	}
	else if(StrEqual(Flag, "262144"))
	{
		ReplaceString(Flag, sizeof(Flag), "262144", "r");
	}
	else if(StrEqual(Flag, "524288"))
	{
		ReplaceString(Flag, sizeof(Flag), "524288", "s");
	}
	else if(StrEqual(Flag, "1048576"))
	{
		ReplaceString(Flag, sizeof(Flag), "1048576", "t");
	}
	Format(StrFlag, sizeof(StrFlag), Flag);
}

bool IsUserAdmin(int client)
{
	if(GetUserFlagBits(client) == 0)
	{
		return false;
	}
	else if(GetUserFlagBits(client) != 0)
	{
		return true;
	}
	return false;
}

stock void ResetArms(int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		GetClientWeapons(client);
		StripAllWeapons(client)
		CreateTimer(0.1, Arms_Job, client);
	}
}
public Action Arms_Job(Handle timer, any client)
{
	GiveClientWeapons(client)
	for(int slot = 0; slot <= 4; slot++)
    {
       weaponClass[client][slot] = "";
	}
}
stock void AddFilesToDownload(Handle FileHandle, char[] Path)
{
	char PathOfFile[512];
	FileHandle = OpenFile(Path, "r");
	while(ReadFileLine(FileHandle, PathOfFile, sizeof(PathOfFile)))
	{
		if(IsValidFile(PathOfFile))
		{
			AddFileToDownloadsTable(PathOfFile);
			if(IsFileModel(PathOfFile))
			{
				if(!IsModelPrecached(PathOfFile))
				{
					PrecacheModel(PathOfFile);
				}
			}
		}
		if(IsEndOfFile(FileHandle))
		{
			break;
		}
	}
}
bool IsValidFile(char[] FilePath)
{
	if(StrContains(FilePath, "models") != -1)
	{
		return true;
	}
	else if(StrContains(FilePath, "materials") != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
	
	//return false;
}
bool IsFileModel(char[] FilePath)
{
	if(StrContains(FilePath, "mdl") != -1)
	{
		return true;
	}
	return false
}
bool IsFileMaterial(char[] FilePath)
{
	if(StrContains(FilePath, "vtf") != -1)
	{
		return true;
	}
	return false
}
stock void CheckServerMod(char[] StrServerMod, int maxlen)
{
	char StrMapName[64];
	GetCurrentMap(StrMapName, sizeof(StrMapName));
	if(IsMapHostage())
	{
		Format(StrServerMod, maxlen, "MAP_HOSTAGE");
		SetConVarInt(m_classic, 1);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		return;
	}
	else if(IsMapBomb())
	{
		Format(StrServerMod, maxlen, "MAP_BOMB");
		SetConVarInt(m_classic, 1);
		SetConVarInt(g_bomb, 1);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		return;
	}
	else if(StrContains(StrMapName, "awp_") != -1)
	{
		Format(StrServerMod, maxlen, "MAP_AWP");
		SetConVarInt(m_classic, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 1);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		return;
	}
	else if(StrContains(StrMapName, "mg_") != -1)
	{
		if(IsMapBomb())
		{
			SetConVarInt(g_bomb, 1);
			SetConVarInt(m_classic, 1);
			SetConVarInt(m_awp, 0);
			SetConVarInt(m_custom, 0);
			SetConVarInt(m_custom2, 0);
			Format(StrServerMod, maxlen, "MAP_BOMB");
			return;
		}
		else if(IsMapHostage())
		{
			SetConVarInt(g_bomb, 0);
			SetConVarInt(m_classic, 1);
			SetConVarInt(m_awp, 0);
			SetConVarInt(m_custom, 0);
			SetConVarInt(m_custom2, 0);
			Format(StrServerMod, maxlen, "MAP_HOSTAGE");
			return;
		}
		else
		{
			SetConVarInt(g_bomb, 0);
			SetConVarInt(m_classic, 0);
			SetConVarInt(m_awp, 0);
			SetConVarInt(m_custom, 0);
			SetConVarInt(m_custom2, 1);
			Format(StrServerMod, maxlen, "MAP_MG");
			return;
		}
	}
	else if(StrContains(StrMapName, "surf_") != -1)
	{
		SetConVarInt(m_classic, 1);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		Format(StrServerMod, maxlen, "MAP_SURF");
		return;
	}
	else if(StrContains(StrMapName, "zm_") != -1)
	{
		Format(StrServerMod, maxlen, "MAP_ZM");
		SetConVarInt(m_classic, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "ze_") != -1)
	{
		Format(StrServerMod, maxlen, "MAP_ZE");
		SetConVarInt(m_classic, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "dr_") != -1 || StrContains(StrMapName, "deathrun_") != -1)
	{
		Format(StrServerMod, maxlen, "MAP_DEATHRUN");
		SetConVarInt(m_classic, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "35hp_") != -1)
	{
		Format(StrServerMod, maxlen, "MAP_35HP");
		SetConVarInt(m_classic, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else
	{
		Format(StrServerMod, maxlen, "MAP_UNKNOWN");
		SetConVarInt(m_classic, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
}
bool IsMapBomb()
{
	for(int entity = 1; entity <= 4096; entity++)
	{
		if(IsValidEntity(entity))
		{
			char ClassName[32];
			GetEdictClassname(entity, ClassName, sizeof(ClassName))
			if(StrEqual(ClassName, "func_bomb_target"), false)
			{
				return true;
			}
			else
			{
				continue;
			}
		}
	}
	return false;
}
bool IsMapHostage()
{
	for(int entity = 1; entity <= 4096; entity++)
	{
		if(IsValidEntity(entity))
		{
			char ClassName[32];
			GetEdictClassname(entity, ClassName, sizeof(ClassName))
			if(StrEqual(ClassName, "func_hostage_rescue"), false)
			{
				return true;
			}
			else
			{
				continue;
			}
		}
	}
	return false;
}