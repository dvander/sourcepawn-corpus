#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <n_arms_fix>

#define PLUGIN_VERSION "4.6.0 fix1 (With Multi Flag Support)"
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
//ConVar d_ct_skin = null;
//ConVar d_ct_arm = null;
//ConVar d_t_skin = null;
//ConVar d_t_arm = null;
ConVar m_custom = null;
ConVar m_custom2 = null;
ConVar m_classic = null;
ConVar m_awp = null;
//ConVar g_smodel = null;
ConVar g_epskin = null;
ConVar g_sReset = null;
ConVar g_gHaveCategories = null;
ConVar g_aAutoMod = null;
//ConVar g_aAutoSkin = null;
ConVar g_aAutoShowMenu = null;
//ConVar g_aDisReset = null;
ConVar g_bModelCheck = null;
ConVar g_cAskForArms = null;
ConVar g_cHideMenu = null;
ConVar g_cHideTeams = null;
ConVar g_cSaveUserSkin = null;
ConVar g_cMaxUse = null;

char g_szPlayerSkinPath[MAXPLAYERS+1][MAX_SKIN_PATH];
char g_szPlayerArmPath[MAXPLAYERS+1][MAX_SKIN_PATH];
char weaponClass[MAXPLAYERS+1][5][32];
//char d_gct_skin[64], d_gct_arm[64], d_gt_skin[64], d_gt_arm[64];
char StrSkinTeam[MAXPLAYERS+1][2];
//char AdminUserFlags[MAXPLAYERS+1][4];
char ServerMapMod[32];
char defArms[][] = { "models/weapons/ct_arms.mdl", "models/weapons/t_arms.mdl" };

//Define PathOfFile
char g_szFileSkinPath[PLATFORM_MAX_PATH], g_szFileAutoSkinPath[PLATFORM_MAX_PATH], g_szFileCategoryPath[PLATFORM_MAX_PATH], g_szFileUserSkinPath[PLATFORM_MAX_PATH], g_szFileUserDataPath[PLATFORM_MAX_PATH];

bool g_bUserHasSkins[MAXPLAYERS+1] = false;
bool g_bUserHasArms[MAXPLAYERS+1];
bool g_bHasSavedSkinSet[MAXPLAYERS+1];
bool g_bHasAsked[MAXPLAYERS+1];
//bool g_bChoosedAsk[MAXPLAYERS+1];
//bool g_bHaveUsedCommand[MAXPLAYERS+1];
//bool UserGotDefSkins[MAXPLAYERS+1];
bool IsRoundFresh;
bool g_bHasUserAsnwered[MAXPLAYERS+1];


int g_iUserArmChoice[MAXPLAYERS+1] = 0;
int SkinTeam[MAXPLAYERS+1];
int playerWeapons[MAXPLAYERS + 1][5];
int UserCurrentTeam[MAXPLAYERS + 1];
int g_iUsedNum[MAXPLAYERS+1] = 0;


Handle g_iTimerCheck[MAXPLAYERS+1];
Handle g_hUserData;

public Plugin myinfo =  {

	name = "PlayerSkin",
	author = PLUGIN_AUTHOR,
	description = "Allow players to select their skins.",
	version = PLUGIN_VERSION,

};

public void OnPluginStart() 
{

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_disconnect", PlayerDisConnect, EventHookMode_Pre);
	HookEvent("cs_pre_restart", RoundPreChange);
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", OnTeamChange, EventHookMode_Pre);
	//HookEvent("round_prestart", RoundPreStart);
	
	
	RegConsoleCmd("sm_pskin", Command_PlayerSkin);
	RegConsoleCmd("sm_models", Command_PlayerSkin);
	RegConsoleCmd("sm_skins", Command_PlayerSkin);
	RegConsoleCmd("sm_printi", Command_Print);

	g_cFix = CreateConVar("sm_pg_cFix", "0", "Allow Plugin To Apply An Arm fix on player spawn.");
	g_bomb = CreateConVar("sm_map_bomb", "0", "Set this to 1 if your map is a bomb defusal map.");
	//d_ct_skin = CreateConVar("sm_ct_model", "models/player/ctm_fbi.mdl");
	//d_ct_arm = CreateConVar("sm_ct_arm", "models/weapons/ct_arms.mdl");
	//d_t_skin = CreateConVar("sm_t_model", "models/player/tm_phoenix.mdl");
	//d_t_arm = CreateConVar("sm_t_arm", "models/weapons/t_arms.mdl");
	m_classic = CreateConVar("sm_map_classic", "0", "Gives Knife + Pistol + Previous Gun To Players");
	m_awp = CreateConVar("sm_map_awp", "0", "Give Knife + Awp To Players");
	m_custom = CreateConVar("sm_map_custom", "0", "Give Knife + Previous Weapon To Players");
	m_custom2 = CreateConVar("sm_map_custom2", "1", "Give Knife To Players");
	//g_smodel = CreateConVar("sm_map_mstay", "1", "remove player's selected skin on map change and needed to be chosen again.");
	g_epskin = CreateConVar("sm_pskin_enable", "1", "Enable/Disable Command pskin");
	g_sReset = CreateConVar("sm_force_arms_change", "0", "If ture, then player's arms will reset on pick.");
	g_gHaveCategories = CreateConVar("sm_cat_enable", "0", "Enable/Disable categories support");
	g_aAutoMod = CreateConVar("sm_auto_map_mode", "1", "If true, plugin will detect map mode it self");
	//g_aAutoSkin = CreateConVar("sm_auto_skin_set", "1", "If true, plugin will use convars and file to set your skin automatically");
	g_aAutoShowMenu = CreateConVar("sm_start_menu", "0", "If true, will show skin menu to all users.");
	//g_aDisReset = CreateConVar("sm_map_dstay", "0", "Player's Skins stays on disconnrect on the userid.");
	g_bModelCheck = CreateConVar("sm_model_check", "0", "Check client model to refresh if changed.");
	g_cAskForArms = CreateConVar("sm_ask_arms", "1", "Check for gloves before setting arms.");
	g_cHideMenu = CreateConVar("sm_hide_options", "0", "Hide menu options if the guy does not have access to the skin.");
	g_cHideTeams = CreateConVar("sm_hide_teams", "0", "Hide menu options for opposite team");
	g_cSaveUserSkin = CreateConVar("sm_save_skins", "0", "Save what skin user choose.");
	g_cMaxUse = CreateConVar("sm_max_use", "1", "Set how many times ");
	
	//Delay loading database.
	CreateTimer(1.0, Timer_SetupDataBase);
	
	//Define Created Paths
	BuildPath(Path_SM, g_szFileSkinPath, sizeof(g_szFileSkinPath), "configs/skin.ini");
	BuildPath(Path_SM, g_szFileAutoSkinPath, sizeof(g_szFileAutoSkinPath), "configs/admin_skin.ini");
	BuildPath(Path_SM, g_szFileCategoryPath, sizeof(g_szFileCategoryPath), "configs/categories.ini");
	BuildPath(Path_SM, g_szFileUserSkinPath, sizeof(g_szFileUserSkinPath), "configs/user_skins.ini");
	BuildPath(Path_SM, g_szFileUserDataPath, sizeof(g_szFileUserDataPath), "configs/userskindata.ini");
	
	//Auto-Create Configurations
	AutoExecConfig(true, "configs.playerskin");
	
	//Load Translations
	LoadTranslations("pskin.phrases.txt");
}

public void OnConfigsExecuted()
{
	PrintToServer("[PlayerSkin] Configs has executed.");
}

public Action Timer_SetupDataBase(Handle iTimer)
{
	//Load Skins Data Once
	g_hUserData = CreateKeyValues("database");
	FileToKeyValues(g_hUserData, g_szFileUserDataPath);
}
public Action Command_Print(int client, int args)
{
	char User[32];
	GetCmdArg(1, User, sizeof(User));
	//int target = FindTarget(client, User);
	//PrintToServer("Admin User Flag : %s", AdminUserFlags[target]);
	PrintToConsole(client, "Server Mod Map Is %s", ServerMapMod);
	PrintToConsole(client, g_szPlayerSkinPath[client]);
	PrintToConsole(client, g_szPlayerArmPath[client]);
	int int1, int2, int3, int4;
	int1 = GetConVarInt(m_classic);
	int2 = GetConVarInt(m_awp);
	int3 = GetConVarInt(m_custom);
	int4 = GetConVarInt(m_custom2);
	PrintToConsole(client, "Int ha Bet Tartiv %d %d %d %d", int1, int2, int3, int4);
	if(g_bUserHasArms[client])
	{
		PrintToConsole(client, "ARM = YES");
	}
	else
	{
		PrintToConsole(client, "ARM = NO");
	}
	if(g_bUserHasSkins[client])
	{
		PrintToConsole(client, "SKIN = YES");
	}
	else
	{
		PrintToConsole(client, "SKIN = NO");
	}
	if(g_bHasSavedSkinSet[client])
	{
		PrintToConsole(client, "SAVEDSET = YES");
	}
	else
	{
		PrintToConsole(client, "SAVEDSET = NO");
	}
	return;
}
public void OnMapStart() 
{
	CreateTimer(1.0, CheckMapMod);
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientConnected(client))
		{
			g_bUserHasSkins[client] = false;
			g_bUserHasArms[client] = false;
			g_bHasSavedSkinSet[client] = false;
			g_bHasAsked[client] = false;
			g_iUsedNum[client] = 0;
			RefreshAllSkinSettings(client);
		}
	}
	char Arms[128], Skin[128];
	//GetConVarString(d_ct_arm, d_gct_arm, sizeof(d_gct_arm));
	//GetConVarString(d_t_arm, d_gt_arm, sizeof(d_gt_arm));
	//GetConVarString(d_ct_skin, d_gct_skin, sizeof(d_gct_skin));
	//GetConVarString(d_t_skin, d_gt_skin, sizeof(d_gt_skin));
	
	PrecacheModel(defArms[0]);
	PrecacheModel(defArms[1]);
	//PrecacheModel(d_gct_skin);
	//PrecacheModel(d_gt_skin);
	
	Handle kv = CreateKeyValues("Skins");
	Handle kt = CreateKeyValues("Admin_Skins");
	FileToKeyValues(kv, g_szFileSkinPath);
	FileToKeyValues(kt, g_szFileAutoSkinPath);
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
	//AddFilesToDownload("addons/sourcemod/configs/download_list.ini");
}

public Action CheckMapMod(Handle timer)
{
	if(!GetConVarBool(g_aAutoMod))
	{
		return Plugin_Handled;
	}
	CheckServerMod(ServerMapMod);
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

/*public void OnClientPostAdminCheck(int client)
{
	//CreateTimer(0.1, AdminCheck, client);
	if(ApplyUserSkin(client))
	{
		PrintToConsole(client, "[PlayerSkin] Your skin has been set.");
	}
}

public Action AdminCheck(Handle timer, any client)
{
	if(IsUserAdmin(client))
	{
		//Format(AdminUserFlags[client], sizeof(AdminUserFlags[]), GetUserCFlags(client));
		int UserFlagBitz = GetUserFlagBits(client);
		GetUserCFlags(client, AdminUserFlags[client]);
	}
}

public Action RoundPreStart(Event event, const char[] name, bool dontBroadcast) 
{
	for(int client = 1; client <= MaxClients ; client++)
	{
		if(IsClientConnected(client) && !IsFakeClient(client))
		{
			if(SetUserSkins(client))
			{
				PrintToConsole(client, "[PlayerSkin] Your skins have restored!");
			}
		}
	}
}
*/
public Action PlayerDisConnect(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bUserHasSkins[client] = false;
	g_bUserHasArms[client] = false;
	g_bHasAsked[client] = false;
	g_bHasSavedSkinSet[client] = false;
	g_iUsedNum[client] = 0;
	//Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), "");
	//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), "");
	return Plugin_Continue;
}

public Action OnTeamChange(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	SkinTeam[client] = team;
	Format(StrSkinTeam[client], sizeof(StrSkinTeam[]), "%d", team);
	//PrintToConsole(client, "[ZZZZ] TEAM CHANGED TO %d", team);
	//UserCurrentTeam[client] = team;
	RefreshAllSkinSettings(client);
	/*
	if(HaveSavedSkin(client, team))
	{
		PrintToConsole(client, "[ZZZZ] REACHED AND CHECKED HAVESAVEDSKINS.");
		if(SetUserSkins(client))
		{
			PrintToConsole(client, "[ZZZZ] REACHED AND CHECKED SAVEUSERSKINS.");
			PrintToConsole(client, "[PlayerSkin] Your Skins has changed to your saved skins.");
		}
	}
	*/
}


public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsClientConnected(client) || IsFakeClient(client))
	{
		return;
	}
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
	CreateTimer(0.02, SetSkins, event.GetInt("userid"));
	/*
	if(UserCurrentTeam[client] != GetClientTeam(client))
	{
		g_bUserHasSkins[client] = false;
		g_bUserHasArms[client] = false;
	}
	*/
	UserCurrentTeam[client] = GetClientTeam(client);
	//g_bHasSavedSkinSet[client] && 
	//!g_bUserHasArms[client]
	if(IsClientWithArms(client) && !g_bHasAsked[client])
	{
		//&& IsClientWithArms(client)
		if(GetConVarBool(g_cAskForArms))
		{
			AskForArms(client);
			g_bHasAsked[client] = true;
		}
		else
		{
			g_bUserHasArms[client] = true;
			g_bHasAsked[client] = true;
		}
	}
	if(HaveSavedSkin(client, GetClientTeam(client)))
	{
		if(!g_bHasSavedSkinSet[client])
		{
			//PrintToConsole(client, "[PlayerSkin] You are awating to get your skins on next round!");
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "SkinWait", client);
		}
	}
	else if(ApplyUserSkin(client))
	{
		PrintToConsole(client, "[PlayerSkin] You have gained your skins!");
	}
	else if(IsUserAdmin(client) && !g_bUserHasSkins[client])
	{
		bool s_gSkinFound = false;
		char SectionName[16];
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, g_szFileAutoSkinPath);
		KvGotoFirstSubKey(kv, true);
		do
		{
			KvGetSectionName(kv, SectionName, sizeof(SectionName));
			
			if(GetUserAcsessValue(SectionName) == GetUserFlagBits(client))
			{
				s_gSkinFound = true;
				break;
			}
		}
		while(s_gSkinFound == false && KvGotoNextKey(kv, true));
		
		//if(KvJumpToKey(kv, AdminUserFlags[client], false))
		if(s_gSkinFound)
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				//UserCurrentTeam[client] = 2;
				SkinTeam[client] = 2;
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				if(!StrEqual(SkinPathT, "", false))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathT, "", false))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[1]);
						g_bUserHasArms[client] = true;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
				}
			}
			else if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				//UserCurrentTeam[client] = 3;
				SkinTeam[client] = 3;
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				if(!StrEqual(SkinPathCT, "", false))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathCT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathCT, "", false))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathCT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[0]);
						g_bUserHasArms[client] = true;
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
	else if(!IsUserAdmin(client) && !g_bUserHasSkins[client])
	{
		Handle kv = CreateKeyValues("Admin_Skins");
		FileToKeyValues(kv, g_szFileAutoSkinPath);
		if(KvJumpToKey(kv, "def", false))
		{
			int ClientTeam = GetClientTeam(client);
			if(ClientTeam == 2)
			{
				char SkinPathT[128], ArmsPathT[128];
				//UserCurrentTeam[client] = 2;
				SkinTeam[client] = 2;
				KvGetString(kv, "SkinT", SkinPathT, sizeof(SkinPathT));
				KvGetString(kv, "ArmsT", ArmsPathT, sizeof(ArmsPathT));
				if(!StrEqual(SkinPathT, "", false))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathT, "", false))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[1]);
						g_bUserHasArms[client] = true;
					}
				}
				else
				{
					g_bUserHasArms[client] = false;
					g_bUserHasSkins[client] = false;
				}
			}
			else if(ClientTeam == 3)
			{
				char SkinPathCT[128], ArmsPathCT[128];
				//UserCurrentTeam[client] = 3;
				SkinTeam[client] = 3;
				KvGetString(kv, "SkinCT", SkinPathCT, sizeof(SkinPathCT));
				KvGetString(kv, "ArmsCT", ArmsPathCT, sizeof(ArmsPathCT));
				if(!StrEqual(SkinPathCT, "", false))
				{
					Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), SkinPathCT);
					g_bUserHasSkins[client] = true;
					if(!StrEqual(ArmsPathCT, "", false))
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), ArmsPathCT);
						g_bUserHasArms[client] = true;
					}
					else
					{
						Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[0]);
						g_bUserHasArms[client] = true;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
					g_bUserHasArms[client] = false;
				}
			}
		}
		CloseHandle(kv);
	}
	/*
	if(g_bUserHasSkins[client])
	{
		CallArms(client);
		CallModels(client);
	}
	*/
	return;

}

public Action RoundPreChange(Event event, const char[] name, bool dontBroadcast) 
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

public Action RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.3, GiveWeapons);
	for(int client = 1; client <= MaxClients ; client++)
	{
		if(IsClientConnected(client) && !IsFakeClient(client))
		{
			g_iUsedNum[client] = 0;
			if(HaveSavedSkin(client, GetClientTeam(client)) && !g_bHasSavedSkinSet[client])
			{
				if(SetUserSkins(client))
				{
					PrintToConsole(client, "[PlayerSkin] Your skins have restored!");
				}
			}
		}
	}
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

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
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
	if(g_bUserHasSkins[client])
	{
		CallArms(client);
		CallModels(client);
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

stock void CallArms(int client)
{
	if(g_bUserHasSkins[client]) 
	{
		if(g_bUserHasArms[client]) 
		{
			if(!IsModelPrecached(g_szPlayerArmPath[client]))
			{
				PrecacheModel(g_szPlayerArmPath[client])
			}
			if(!StrEqual(g_szPlayerArmPath[client], "", false))
			{
				if(g_iUserArmChoice[client] == 0)
				{
					SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szPlayerArmPath[client]);
				}
				else if(g_iUserArmChoice[client] == 1)
				{
					SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szPlayerArmPath[client]);
				}
				else if(g_iUserArmChoice[client] == 2)
				{
					int g_iTeam = GetClientTeam(client);
					if(g_iTeam == 2)
					{
						SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
					}
					else if(g_iTeam == 3)
					{
						SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
					}
				}
			}

		} 
	}
		/*else if(!g_bUserHasArms[client]) 
		{
			
			int iTeamID = GetClientTeam(client);
			PrintToChatAll("[DEBUG] Set Def Arms.");
			if(iTeamID == 2) 
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms.mdl");

			} else if(iTeamID == 3) 
			{

				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/ct_arms.mdl");

			}
			
			
			if(!ArmsFix_HasDefaultArms(client))
			{
				ArmsFix_SetDefaults(client);
			}
			
		}

	}
	else if(g_bUserHasSkins[client] == false)
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
	}*/

}

stock void CallModels(int client)
{
	if(g_bUserHasSkins[client]) 
	{
		if(!IsModelPrecached(g_szPlayerSkinPath[client]))
		{
			PrecacheModel(g_szPlayerSkinPath[client])
		}
		if(StrEqual(StrSkinTeam[client], ""))
		{
			if(!StrEqual(g_szPlayerSkinPath[client], "", false))
			{
				SetEntityModel(client, g_szPlayerSkinPath[client]);
			}
		}
		else if(!StrEqual(StrSkinTeam[client], ""))
		{
			if(GetClientTeam(client) == SkinTeam[client])
			{
				if(!StrEqual(g_szPlayerSkinPath[client], "", false))
				{
					SetEntityModel(client, g_szPlayerSkinPath[client]);
				}
			}
			else
			{
				g_bUserHasSkins[client] = false;
				g_bUserHasArms[client] = false;
			}
		}
	}
	/*
	else if(g_bUserHasSkins[client] == false)
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
	}*/
}

public Action Command_PlayerSkin(int client, int args) 
{
	if(GetConVarBool(g_epskin))
	{
		if(g_iUsedNum[client] >= GetConVarInt(g_cMaxUse))
		{
			PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ReachedLimit", client);
			//PrintToChat(client, " \x10[PlayerSkin] \x01You can not use this command for now!");
			return Plugin_Handled;
		}
		else if(GetConVarBool(g_gHaveCategories))
		{
			DisplaySkinMenu(client, true);
			g_iUsedNum[client] += 1;
			//g_bHaveUsedCommand[client] = true;
		}
		else if(!GetConVarBool(g_gHaveCategories))
		{
			DisplaySkinMenu(client, false);
			g_iUsedNum[client] += 1;
			//g_bHaveUsedCommand[client] = true;
		}
	}
	else
	{
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "CommandDisabled", client);
		//PrintToChat(client, " \x10[PlayerSkin] \x01Command !pskin is disabled by server operator!");
		return Plugin_Continue;
	}
	return Plugin_Continue;

}

stock void DisplaySkinMenu(int client, bool HaveCategories) {

	if(HaveCategories)
	{
		if(GetConVarBool(g_cHideMenu))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenuHandle);
			SetMenuTitle(menu, "Select a Category :");
			Handle kt = CreateKeyValues("Categories");
			FileToKeyValues(kt, g_szFileCategoryPath);
			KvGotoFirstSubKey(kt, false);
			do
			{
				char g_szUserFlags[32];
				KvGetString(kt, "Name", SkinName, sizeof(SkinName));
				KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
				KvGetString(kt, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kt, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kt);
		}
		else if(!GetConVarBool(g_cHideMenu))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenuHandle);
			SetMenuTitle(menu, "Select a Category :");
			Handle kt = CreateKeyValues("Categories");
			FileToKeyValues(kt, g_szFileCategoryPath);
			KvGotoFirstSubKey(kt, false);
			do
			{
				KvGetString(kt, "Name", SkinName, sizeof(SkinName));
				KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
				AddMenuItem(menu, UniqueId, SkinName);
			}
			while(KvGotoNextKey(kt, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kt);
		}
	}
	else if(!HaveCategories)
	{
		if(GetConVarBool(g_cHideMenu) && GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				char g_szUserFlags[32];
				int g_iTeamNum = KvGetNum(kv, "Team", 0);
				KvGetString(kv, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(g_iTeamNum != 0)
				{
					if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue) && GetClientTeam(client) == g_iTeamNum)
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
				else
				{
					if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(GetConVarBool(g_cHideMenu) && !GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				char g_szUserFlags[32];
				KvGetString(kv, "Flag", g_szUserFlags, sizeof(g_szUserFlags));
				int g_iUserAccessValue = GetUserAcsessValue(g_szUserFlags);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(CheckCommandAccess(client, "command_testz", g_iUserAccessValue))
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(!GetConVarBool(g_cHideMenu) && GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				int g_iTeamNum = KvGetNum(kv, "Team", 0);
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(g_iTeamNum != 0)
				{
					if(GetClientTeam(client) == g_iTeamNum)
					{
						AddMenuItem(menu, UniqueId, SkinName);
					}
				}
				else
				{
					AddMenuItem(menu, UniqueId, SkinName);
				}
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
		else if(!GetConVarBool(g_cHideMenu) && !GetConVarBool(g_cHideTeams))
		{
			char SkinName[32], UniqueId[32];
			Handle menu = CreateMenu(SkinMenu);
			AddMenuItem(menu, "def", "Choose Default Skin");
			SetMenuTitle(menu, "Select a Skin");
			Handle kv = CreateKeyValues("Skins");
			FileToKeyValues(kv, g_szFileSkinPath);
			KvGotoFirstSubKey(kv, false);
			do 
			{
				KvGetString(kv, "Name", SkinName, sizeof(SkinName));
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				AddMenuItem(menu, UniqueId, SkinName);
			}
			while(KvGotoNextKey(kv, false));
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			SetMenuExitButton(menu, true);
			CloseHandle(kv);
		}
	}
}

public int SkinMenuHandle(Handle menu, MenuAction action, int param1, int param2)
{

	char SkinName[32], UniqueId[32], Flag[64], ADMFlag[64];

	switch (action) 
	{
		case MenuAction_Select: 
		{
			Handle kv = CreateKeyValues("Categories");
			FileToKeyValues(kv, g_szFileCategoryPath);
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);
			do
			{
				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));
				if(StrEqual(item, UniqueId, false))
				{
					KvGetString(kv, "catgroup", ADMFlag, sizeof(ADMFlag));
					Handle smenu = CreateMenu(SkinMenu);
					AddMenuItem(smenu, "def", "Choose Default Skin");
					Handle kt = CreateKeyValues("skins");
					FileToKeyValues(kt, g_szFileSkinPath);
					KvGotoFirstSubKey(kt, false);
					do
					{
						KvGetString(kt, "catgroup", Flag, sizeof(Flag));
						if(StrEqual(ADMFlag, Flag, false))
						{
							KvGetString(kt, "Name", SkinName, sizeof(SkinName));
							KvGetString(kt, "u_id", UniqueId, sizeof(UniqueId));
							if(GetConVarBool(g_cHideTeams))
							{
								int g_iTeamNum = KvGetNum(kt, "Team", 0);
								if(g_iTeamNum != 0)
								{
									if(GetClientTeam(param1) == g_iTeamNum)
									{
										AddMenuItem(smenu, UniqueId, SkinName);
									}
								}
								else
								{
									AddMenuItem(smenu, UniqueId, SkinName);
								}
							}
							else
							{
								AddMenuItem(smenu, UniqueId, SkinName);
							}
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

			//CloseHandle(kv);
			CloseHandle(menu);
		}
	}
}



public int SkinMenu(Handle menu, MenuAction action, int param1, int param2) {

	char SkinName[32], SkinPath[128], ArmPath[128], UniqueId[32], Flag[16], StriTeamID[32];
	Handle kv = CreateKeyValues("Skins");
	FileToKeyValues(kv, g_szFileSkinPath);

	switch (action) {

		case MenuAction_Select: {

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			KvGotoFirstSubKey(kv, false);

			do {

				KvGetString(kv, "u_id", UniqueId, sizeof(UniqueId));

				if (StrEqual(item, "def")) 
				{
					if(RemoveSavedSkins(param1))
					{
						PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "SavedSkinsRemoved", param1);
						//PrintToChat(param1, " \x10[PlayerSkin] \x01 Your saved skins has removed!");
					}
					g_bUserHasSkins[param1] = false;
					g_bUserHasArms[param1] = false;
					//Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), ""); 
					//Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), "");
					if(GetClientTeam(param1) == 3)
					{
						SetEntPropString(param1, Prop_Send, "m_szArmsModel", "");
						Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), ""); 
						Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), "");	
					}
					else if(GetClientTeam(param1) == 2)
					{
						SetEntPropString(param1, Prop_Send, "m_szArmsModel", "");
						Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), ""); 
						Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), "");
					}
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
							PrintToChat(param1, " \x10[PlayerSkin] \x01%T", "WrongTeam", param1);
							//PrintToChat(param1, " \x10[PlayerSkin] \x01This Selected Skin Is Not For Your Team!");
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
					/*
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
					*/
					//IsClientWithArms(param1) && 
					if(!StrEqual(ArmPath, "", false) && GetConVarBool(g_cAskForArms) && IsClientWithArms(param1))
					{
						AskForArms(param1);
					}
					else if(!StrEqual(ArmPath, "", false)) {

						SetEntPropString(param1, Prop_Send, "m_szArmsModel", ArmPath);
						g_bUserHasArms[param1] = true;

					} else if(StrEqual(ArmPath, "", false)) {

						g_bUserHasArms[param1] = false;
						if(GetClientTeam(param1) == 3)
						{
							SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[0]);
						}
						else if(GetClientTeam(param1) == 2)
						{
							SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[1]);
						}

					}
					if(!IsModelPrecached(SkinPath))
					{
						PrecacheModel(SkinPath);
						SetEntityModel(param1, SkinPath);
					}
					else{SetEntityModel(param1, SkinPath);}
					g_bUserHasSkins[param1] = true;
					Format(g_szPlayerSkinPath[param1], sizeof(g_szPlayerSkinPath[]), SkinPath); 
					Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), ArmPath);
					if(GetConVarBool(g_bModelCheck))
					{
						if(g_iTimerCheck[param1] != null)
						{
							KillTimer(g_iTimerCheck[param1]);
							g_iTimerCheck[param1] = CreateTimer(1.0, Timer_ModelCheck, param1, TIMER_REPEAT);
						}
					}
					if(GetConVarBool(g_sReset) && !IsClientWithArms(param1) && g_iUserArmChoice[param1] != 1)
					{
						ResetArms(param1);
					}
					if(GetConVarBool(g_cSaveUserSkin))
					{
						SaveUserSkin(param1, g_szPlayerSkinPath[param1], g_szPlayerArmPath[param1]);
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

public Action Timer_ModelCheck(Handle timer, any client)
{
	if(!g_bUserHasSkins || !IsClientConnected(client))
	{
		KillTimer(g_iTimerCheck[client])
	}
	if(CheckModelChange(client, g_szPlayerSkinPath[client]))
	{
		SetEntityModel(client, g_szPlayerSkinPath[client]);
		PrintToChat(client, " \x10[PlayerSkin] \x01%T", "ModelRefresh", client);
		//PrintToChat(client, " \x10[PlayerSkin] \x01Your skin has been refreshed!");
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
	if(GetTeamClientCount(team) > 0)
	{
		do
		{
			RandomClient = GetRandomInt(1, MaxClients);
		}
		while(!IsClientInGame(RandomClient) || GetClientTeam(RandomClient) != team);
		return RandomClient;
	}
	else
		return -1;
/*
    ArrayList ValidClients = new ArrayList();
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && GetClientTeam(i) == team)
        {
            ValidClients.Push(i);
        }
    }
    int Index = GetRandomInt(0, ValidClients.Length - 1);
	
    RandomClient = ValidClients.Get(Index);
    
    delete ValidClients;
  
    return RandomClient;
*/
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
							AcceptEntityInput(ent, "Kill");
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
	if(user == -1)
		return Plugin_Stop;
	GivePlayerItem(user, "weapon_c4");
	PrintToChat(user, " \x10[PlayerSkin] \x01%T", "HoldingBomb", user);
	//PrintToChat(user, " \x10[PlayerSkin] \x01You are now holding the bomb!");
	return Plugin_Continue;
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

stock void AddFilesToDownload(char[] Path)
{
	char PathOfFile[512];
	Handle FileHandle = OpenFile(Path, "r");
	while(ReadFileLine(FileHandle, PathOfFile, sizeof(PathOfFile)) && !IsEndOfFile(FileHandle))
	{
		if(strlen(PathOfFile) > 0 && IsValidFile(PathOfFile))
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
	}
}
bool IsValidFile(char[] FilePath)
{
	if(StrContains(FilePath, "models", false) != -1)
	{
		return true;
	}
	else if(StrContains(FilePath, "materials", false) != -1)
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
	if(StrContains(FilePath, "mdl", false) != -1)
	{
		return true;
	}
	return false
}
bool IsFileMaterial(char[] FilePath)
{
	if(StrContains(FilePath, "vtf", false) != -1)
	{
		return true;
	}
	return false
}
stock void CheckServerMod(char StrServerMod[32])
{
	char StrMapName[64];
	GetCurrentMap(StrMapName, sizeof(StrMapName));
	if(IsMapHostage())
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_HOSTAGE");
		SetConVarInt(m_classic, 1);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		return;
	}
	else if(IsMapBomb())
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_BOMB");
		SetConVarInt(m_classic, 1);
		SetConVarInt(g_bomb, 1);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 0);
		return;
	}
	else if(StrContains(StrMapName, "awp_") != -1)
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_AWP");
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
			Format(StrServerMod, sizeof(StrServerMod), "MAP_BOMB");
			return;
		}
		else if(IsMapHostage())
		{
			SetConVarInt(g_bomb, 0);
			SetConVarInt(m_classic, 1);
			SetConVarInt(m_awp, 0);
			SetConVarInt(m_custom, 0);
			SetConVarInt(m_custom2, 0);
			Format(StrServerMod, sizeof(StrServerMod), "MAP_HOSTAGE");
			return;
		}
		else
		{
			SetConVarInt(g_bomb, 0);
			SetConVarInt(m_classic, 0);
			SetConVarInt(m_awp, 0);
			SetConVarInt(m_custom, 0);
			SetConVarInt(m_custom2, 1);
			Format(StrServerMod, sizeof(StrServerMod), "MAP_MG");
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
		Format(StrServerMod, sizeof(StrServerMod), "MAP_SURF");
		return;
	}
	else if(StrContains(StrMapName, "zm_") != -1)
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_ZM");
		SetConVarInt(m_classic, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "ze_") != -1)
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_ZE");
		SetConVarInt(m_classic, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "dr_") != -1 || StrContains(StrMapName, "deathrun_") != -1)
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_DEATHRUN");
		SetConVarInt(m_classic, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else if(StrContains(StrMapName, "35hp_") != -1)
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_35HP");
		SetConVarInt(m_classic, 0);
		SetConVarInt(g_bomb, 0);
		SetConVarInt(m_awp, 0);
		SetConVarInt(m_custom, 0);
		SetConVarInt(m_custom2, 1);
		return;
	}
	else
	{
		Format(StrServerMod, sizeof(StrServerMod), "MAP_UNKNOWN");
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
			GetEntityClassname(entity, ClassName, sizeof(ClassName))
			if(StrEqual(ClassName, "func_bomb_target", false))
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
			GetEntityClassname(entity, ClassName, sizeof(ClassName))
			if(StrEqual(ClassName, "func_hostage_rescue", false))
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
stock int GetUserAcsessValue(char[] flags)
{
	int UserFlagNum = 0;
	if(StrContains(flags, "a", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1;
	}
	if(StrContains(flags, "b", false) != -1)
	{
		UserFlagNum = UserFlagNum + 2;
	}
	if(StrContains(flags, "c", false) != -1)
	{
		UserFlagNum = UserFlagNum + 4;
	}
	if(StrContains(flags, "d", false) != -1)
	{
		UserFlagNum = UserFlagNum + 8;
	}
	if(StrContains(flags, "e", false) != -1)
	{
		UserFlagNum = UserFlagNum + 16;
	}
	if(StrContains(flags, "f", false) != -1)
	{
		UserFlagNum = UserFlagNum + 32;
	}
	if(StrContains(flags, "g", false) != -1)
	{
		UserFlagNum = UserFlagNum + 64;
	}
	if(StrContains(flags, "h", false) != -1)
	{
		UserFlagNum = UserFlagNum + 128;
	}
	if(StrContains(flags, "i", false) != -1)
	{
		UserFlagNum = UserFlagNum + 256;
	}
	if(StrContains(flags, "j", false) != -1)
	{
		UserFlagNum = UserFlagNum + 512;
	}
	if(StrContains(flags, "k", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1024;
	}
	if(StrContains(flags, "l", false) != -1)
	{
		UserFlagNum = UserFlagNum + 2024;
	}
	if(StrContains(flags, "m", false) != -1)
	{
		UserFlagNum = UserFlagNum + 4096;
	}
	if(StrContains(flags, "n", false) != -1)
	{
		UserFlagNum = UserFlagNum + 8192;
	}
	if(StrContains(flags, "z", false) != -1)
	{
		UserFlagNum = UserFlagNum + 16384;
	}
	if(StrContains(flags, "o", false) != -1)
	{
		UserFlagNum = UserFlagNum + 32768;
	}
	if(StrContains(flags, "p", false) != -1)
	{
		UserFlagNum = UserFlagNum + 65536;
	}
	if(StrContains(flags, "q", false) != -1)
	{
		UserFlagNum = UserFlagNum + 131072;
	}
	if(StrContains(flags, "r", false) != -1)
	{
		UserFlagNum = UserFlagNum + 262144;
	}
	if(StrContains(flags, "s", false) != -1)
	{
		UserFlagNum = UserFlagNum + 524288;
	}
	if(StrContains(flags, "t", false) != -1)
	{
		UserFlagNum = UserFlagNum + 1048576;
	}
	return UserFlagNum;
}
bool CheckModelChange(int client, char[] StockModel)
{
	char CurrentModel[128];
	GetClientModel(client, CurrentModel, sizeof(CurrentModel));
	if(!StrEqual(CurrentModel, StockModel, false))
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool IsClientWithArms(int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_hMyWearables") != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}
stock void AskForArms(int client)
{
	if(!g_bHasUserAsnwered[client])
	{
		char MSG_ASK[64], MSG_YES[32], MSG_NO[32];
		Format(MSG_ASK, sizeof(MSG_ASK), "%T", "MSG_ASK", LANG_SERVER); 
		Format(MSG_YES, sizeof(MSG_YES), "%T", "MSG_YES", LANG_SERVER);
		Format(MSG_NO, sizeof(MSG_NO), "%T", "MSG_NO", LANG_SERVER);
		Handle hmenu = CreateMenu(AskForArmsMenu);
		SetMenuTitle(hmenu, MSG_ASK);
		AddMenuItem(hmenu, "Menu_Yes", MSG_YES);
		AddMenuItem(hmenu, "Menu_No", MSG_NO);
		DisplayMenu(hmenu, client, MENU_TIME_FOREVER);
		SetMenuExitButton(hmenu, false);
	}
	else
	{
		PrintToConsole(client, "[PlayerSkin] Your choice of arms has restored.");
	}
}

public int AskForArmsMenu(Handle menu, MenuAction action, int param1, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if(StrEqual(item, "Menu_Yes", false))
			{
				SetEntPropString(param1, Prop_Send, "m_szArmsModel", g_szPlayerArmPath[param1]);
				g_bUserHasArms[param1] = true;
				g_bHasUserAsnwered[param1] = true;
				g_iUserArmChoice[param1] = 1;
				//g_bChoosedAsk[client] = true;
				if(GetConVarBool(g_sReset))
				{
					ResetArms(param1);
				}
			}
			else if(StrEqual(item, "Menu_No", false))
			{
				g_bUserHasArms[param1] = true;
				//g_bChoosedAsk[client] = true;
				g_bHasUserAsnwered[param1] = true;
				g_iUserArmChoice[param1] = 2;
				if(GetClientTeam(param1) == 3)
				{
					if(!IsClientWithArms(param1))
					{
						SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[0]);
						Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), defArms[0]);
					}
				}
				else if(GetClientTeam(param1) == 2)
				{
					if(!IsClientWithArms(param1))
					{
						SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[1]);
						Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), defArms[1]);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(GetClientTeam(param1) == 3)
			{
				if(!IsClientWithArms(param1))
				{
					SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[0]);
					Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), defArms[0]);
				}
			}
			else if(GetClientTeam(param1) == 2)
			{
				if(!IsClientWithArms(param1))
				{
					SetEntPropString(param1, Prop_Send, "m_szArmsModel", defArms[1]);
					Format(g_szPlayerArmPath[param1], sizeof(g_szPlayerArmPath[]), defArms[1]);
				}
			}
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}
bool ApplyUserSkin(int client)
{
	if(g_bUserHasSkins[client])
	{
		return false;
	}
	else
	{
		char SteamAuth[32];
		GetClientAuthId(client, AuthId_SteamID64, SteamAuth, sizeof(SteamAuth));
		Handle kv = CreateKeyValues("userids");
		FileToKeyValues(kv, g_szFileUserSkinPath);
		if(KvJumpToKey(kv, SteamAuth, false))
		{
			char g_szSkins[128], g_szArms[128];
			int g_iTeamNum = GetClientTeam(client);
			if(g_iTeamNum == 2)
			{
				if(KvJumpToKey(kv, "T", false))
				{
					KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
					KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
					if(!StrEqual(g_szSkins, "", false))
					{
						Format(StrSkinTeam[client], sizeof(StrSkinTeam[]), "2");
						Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), g_szSkins);
						g_bUserHasSkins[client] = true;
						if(!StrEqual(g_szArms, "", false))
						{
							Format(g_szPlayerArmPath[client], sizeof(g_szPlayerSkinPath[]), g_szArms);
							g_bUserHasArms[client] = true;
						}
						CloseHandle(kv);
						return true;
					}
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
			else if(g_iTeamNum == 3)
			{
				if(KvJumpToKey(kv, "CT", false))
				{
					KvGetString(kv, "Skin", g_szSkins, sizeof(g_szSkins));
					KvGetString(kv, "Arms", g_szArms, sizeof(g_szArms));
					if(!StrEqual(g_szSkins, "", false))
					{
						Format(StrSkinTeam[client], sizeof(StrSkinTeam[]), "3");
						Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), g_szSkins);
						g_bUserHasSkins[client] = true;
						if(!StrEqual(g_szArms, "", false))
						{
							Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), g_szArms);
							g_bUserHasArms[client] = true;
						}
						CloseHandle(kv);
						return true;
					}
				}
				else
				{
					CloseHandle(kv);
					return false;
				}
			}
			else
			{
				CloseHandle(kv);
				return false;
			}
		}
		else
		{
			CloseHandle(kv);
			return false;
		}
	}
	return false;
}


bool HaveSavedSkin(int client, int Team)
{
	Handle kv = CreateKeyValues("database");
	FileToKeyValues(kv, g_szFileUserDataPath);
	char SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	if(KvJumpToKey(kv, SteamAuth, false))
	{
		if(Team == 2)
		{
			if(KvJumpToKey(kv, "T", false))
			{
				CloseHandle(kv);
				return true;
			}
			else
			{
				CloseHandle(kv);
				return true;
			}
		}
		else if(Team == 3)
		{
			if(KvJumpToKey(kv, "CT", false))
			{
				CloseHandle(kv);
				return true;
			}
			else
			{
				CloseHandle(kv);
				return true;
			}		
		}
		else
		{
			CloseHandle(kv);
			return false;
		}
	}
	else
	{
		CloseHandle(kv);
		return false;
	}
}


void SaveUserSkin(int client, char[] sPath, char[] aPath)
{
	char SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	KvRewind(g_hUserData);
	if(KvJumpToKey(g_hUserData, SteamAuth, true))
	{
		if(GetClientTeam(client) == 2)
		{
			if(KvJumpToKey(g_hUserData, "T", true))
			{
				KvSetString(g_hUserData, "SkinPath", sPath);
				KvSetString(g_hUserData, "ArmsPath", aPath);
				KvRewind(g_hUserData);
				KeyValuesToFile(g_hUserData, g_szFileUserDataPath);
				//PrintToChat(client, " \x10[PlayerSkin]\x01 Your skin for Team2 has saved.");
				PrintToChat(client, " \x10[PlayerSkin] \x01%T", "SavedSkinTeam2", client);
				PrintToServer("[PlayerSkin] User %N Skins + Arms has saved on database.", client);
			}
		}
		else if(GetClientTeam(client) == 3)
		{
			if(KvJumpToKey(g_hUserData, "CT", true))
			{
				KvSetString(g_hUserData, "SkinPath", sPath);
				KvSetString(g_hUserData, "ArmsPath", aPath);
				KvRewind(g_hUserData);
				KeyValuesToFile(g_hUserData, g_szFileUserDataPath);
				//PrintToChat(client, " \x10[PlayerSkin]\x01 Your skin for Team3 has saved.");
				PrintToChat(client, " \x10[PlayerSkin] \x01%T", "SavedSkinTeam3", client);
				PrintToServer("[PlayerSkin] User %N Skins + Arms has saved on database.", client);
			}
		}
	}
}

bool SetUserSkins(int client)
{
	if(g_bHasSavedSkinSet[client])
	{
		return false;
	}
	else
	{
		char SteamAuth[32];
		GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
		KvRewind(g_hUserData);
		if(KvJumpToKey(g_hUserData, SteamAuth, false))
		{
			if(GetClientTeam(client) == 2)
			{
				if(KvJumpToKey(g_hUserData, "T", false))
				{
					char sPath[128], aPath[128];
					KvGetString(g_hUserData, "SkinPath", sPath, sizeof(sPath), "");
					KvGetString(g_hUserData, "ArmsPath", aPath, sizeof(aPath), "");
					if(!StrEqual(sPath, ""))
					{
						Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), sPath);
						g_bUserHasSkins[client] = true;
						g_bHasSavedSkinSet[client] = true;
						if(!StrEqual(aPath, ""))
						{
							Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), aPath);
							// && IsClientWithArms(client)
							if(GetConVarBool(g_cAskForArms))
							{
								//AskForArms(client);
								g_bUserHasArms[client] = false;
							}
							else
							{
								g_bUserHasArms[client] = true;
							}
							//SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
							//g_bUserHasArms[client] = true;
						}
						else
						{
							//g_bUserHasArms[client] = false;
						}
						return true;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
					return false;
				}
			}
			else if(GetClientTeam(client) == 3)
			{
				if(KvJumpToKey(g_hUserData, "CT", false))
				{
					char sPath[128], aPath[128];
					KvGetString(g_hUserData, "SkinPath", sPath, sizeof(sPath), "");
					KvGetString(g_hUserData, "ArmsPath", aPath, sizeof(aPath), "");
					if(!StrEqual(sPath, ""))
					{
						Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), sPath);
						g_bUserHasSkins[client] = true;
						g_bHasSavedSkinSet[client] = true;
						if(!StrEqual(aPath, ""))
						{
							Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), aPath);
							// && IsClientWithArms(client)
							if(GetConVarBool(g_cAskForArms))
							{
								//AskForArms(client);
								g_bUserHasArms[client] = false;
							}
							else
							{
								g_bUserHasArms[client] = true;
							}
							//SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
							//g_bUserHasArms[client] = true;
						}
						else
						{
							//g_bUserHasArms[client] = false;
						}
						return true;
					}
				}
				else
				{
					g_bUserHasSkins[client] = false;
					return false;
				}
			}
		}
		else
		{
			return false;
		}
		return false;
	}
}

bool RemoveSavedSkins(int client)
{
	char SteamAuth[32];
	GetClientAuthId(client, AuthId_Steam2, SteamAuth, sizeof(SteamAuth));
	KvRewind(g_hUserData);
	if(KvJumpToKey(g_hUserData, SteamAuth, false))
	{
		if(GetClientTeam(client) == 3)
		{
			if(KvJumpToKey(g_hUserData, "CT", false))
			{
				KvDeleteThis(g_hUserData);
				KvRewind(g_hUserData);
				KeyValuesToFile(g_hUserData, g_szFileUserDataPath);
				return true;
			}
		}
		else if(GetClientTeam(client) == 2)
		{
			if(KvJumpToKey(g_hUserData, "T", false))
			{
				KvDeleteThis(g_hUserData);
				KvRewind(g_hUserData);
				KeyValuesToFile(g_hUserData, g_szFileUserDataPath);
				return true;
			}
		}
	}
	else
	{
		return false;
	}
	return false;
}

void RefreshAllSkinSettings(int client)
{
	//PrintToConsole(client, "[ZZZZ] REACHED AND REFRESHES SETTINGS.");
	g_bUserHasSkins[client] = false;
	g_bUserHasArms[client] = false;
	g_bHasSavedSkinSet[client] = false;
	g_bHasAsked[client] = false;
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
	if(GetClientTeam(client) == 3)
	{
		//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[0]);
		//SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[0]);
		//Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), ""); 
		//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), "");
	}
	else if(GetClientTeam(client) == 2)
	{
		//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), defArms[1]);
		//SetEntPropString(client, Prop_Send, "m_szArmsModel", defArms[1]);
		//Format(g_szPlayerSkinPath[client], sizeof(g_szPlayerSkinPath[]), ""); 
		//Format(g_szPlayerArmPath[client], sizeof(g_szPlayerArmPath[]), "");
	}
}
