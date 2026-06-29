#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <morecolors>
#include <smlib>
#include <smartdm>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>
#define REQUIRE_PLUGIN

#define EOS '\0'
#define CSS_WEAPON_NUMBER 40
#define MAX_SKINS_PER_WEAPON 65
#define EF_NODRAW 32
new String:ListOfEntityWeaponsToUse[CSS_WEAPON_NUMBER][38];
//new String:ListOfNamesWeaponsToUse[CSS_WEAPON_NUMBER][33];
new String:weaponmenu[MAXPLAYERS+1][38];
new String:weaponmenu_displayname[MAXPLAYERS+1][33];
new String:g_menuCommands[32][32];
//
//new String:ActiveWeapon[MAXPLAYERS+1][50];
new bool:SpawnCheck[MAXPLAYERS+1];
new ClientVM[MAXPLAYERS+1][2];
new bool:IsCustom[MAXPLAYERS+1];
new nadeThrown[MAXPLAYERS];
new Handle:h_DB;
//new Handle:h_DB_noT;
//
enum Weapon_Info
{
	String:Name[64],
	String:Description[128],
	String:VModel[128],
	String:WModel[128],
	String:Flag[16],
	String:Enabled[4],
	Index,
	PVModel,
	PWModel,
	NumUsers
}

new weapon_info[CSS_WEAPON_NUMBER][MAX_SKINS_PER_WEAPON][Weapon_Info];
new client_wepskin_index[MAXPLAYERS+1][CSS_WEAPON_NUMBER];
new weapon_owner[2048];
new bool:ViewModelsEnabled[MAXPLAYERS+1] = true;
new bool:WorldModelsEnabled[MAXPLAYERS+1] = true;
//new bool:Experimental[MAXPLAYERS+1] = true;
new Process[MAXPLAYERS+1];
//new bool:Dropped_Weapons_Get_Model[MAXPLAYERS+1] = true;
//new On_Pick_Up_get_model[MAXPLAYERS+1] = 1;	// 0 Always get the model of the player who dropped it // 1 Always get your model // 2 Get Player who dropped model incase you have stock skin // 3 Get player who dropped model incase you have no stock skin OR public skin

new bool:ReviewVM[MAXPLAYERS + 1] = false;

new Handle:g_AccessMethod;
new Handle:g_AccessFlag;
new Handle:g_AccessGroup;
new Handle:g_VModelsEnabled;
new Handle:g_WModelsEnabled;
new Handle:g_EnableDropModels;
new Handle:g_ChatCommands;
new Handle:g_EnableDownloadFile;
new Handle:g_SmartDM;
new Handle:g_lowercase;
new Handle:g_tellusersskin;
new Handle:g_AskUserIfTheyWantPublicSkins;
new Handle:trie;
new OFFSET_THROWER;
new ToReloadnumusers = 0;
new String:G_SteamID[MAXPLAYERS+1][50]
//
new weapondefaultpc[40]
new static String:weaponVDefaultModels[][] = 
{
{"models/weapons/v_rif_ak47.mdl"},
{"models/weapons/v_rif_aug.mdl"},
{"models/weapons/v_snip_awp.mdl"},
{""},
{"models/weapons/v_pist_deagle.mdl"},
{"models/weapons/v_pist_elite.mdl"},
{"models/weapons/v_rif_famas.mdl"},
{"models/weapons/w_pist_fiveseven.mdl"},
{"models/weapons/v_eq_flashbang.mdl"},
{"models/weapons/v_snip_g3sg1.mdl"},
{"models/weapons/v_rif_galil.mdl"},
{"models/weapons/v_pist_glock18.mdl"},
{"models/weapons/v_eq_fraggrenade.mdl"},
{"models/weapons/v_shot_m3super90.mdl"},
{"models/weapons/v_rif_m4a1.mdl"},
{"models/weapons/v_mach_m249para.mdl"},
{"models/weapons/v_smg_mac10.mdl"},
{"models/weapons/v_smg_mp5.mdl"},
{"models/weapons/v_smg_p90.mdl"},
{"models/weapons/v_pist_p228.mdl"},
{"models/weapons/v_snip_scout.mdl"},
{"models/weapons/v_snip_sg550.mdl"},
{"models/weapons/v_rif_sg552.mdl"},
{"models/weapons/v_eq_smokegrenade.mdl"},
{"models/weapons/v_smg_tmp.mdl"},
{"models/weapons/v_smg_ump45.mdl"},
{"models/weapons/v_pist_usp.mdl"},
{"models/weapons/v_shot_xm1014.mdl"},
{"models/weapons/v_knife_t.mdl"},
{"models/weapons/v_knife_t.mdl"}
};
//
public Plugin:myinfo = 
{
	name = "PT'Fun Weapon Models",
	author = "Erroler",
	description = "",
	version = "133.7",
	url = "ptfun.net"
}

new bool:TeSTing[MAXPLAYERS +1];
public OnPluginStart()
{
	//decl String:error[255];
	//h_DB_noT = SQL_Connect("wmodels", true, error, sizeof(error));
	//h_DB = SQL_Connect("wmodels", true, error, sizeof(error));
	SQL_TConnect(OnDatabaseConnect, "wmodels");
	//RegConsoleCmd("sm_skinsarmas", DisplayWeaponMenu);
	//RegAdminCmd("sm_reloadweaponmodels", ReloadWeaponModels, ADMFLAG_ROOT);
	g_AccessMethod = CreateConVar("sm_wm_accessmethod", "public" , "Method used to restrict clients from openning the weapon models menu. Choices: flag group public")
	g_AccessFlag = CreateConVar("sm_wm_accessflag", "" , "Flag required to open weapon models menu")
	g_AccessGroup = CreateConVar("sm_wm_accessgroup", "vip" , "Group the client must be in to open weapon models menu")
	g_ChatCommands = CreateConVar("sm_wm_chatcommands", "!weaponmodels !weapons" , "String of text players must type to open the weapon menu")
	g_VModelsEnabled = CreateConVar("sm_wm_vmodelsenabled", "1" , "Enables Viewmodels portion of the plugin")
	g_WModelsEnabled = CreateConVar("sm_wm_wmodelsenabled", "1" , "Enables Worldmodels portion of the plugin")
	g_EnableDropModels = CreateConVar("sm_wm_dropmodelsenabled", "1" , "Enables dropped models portion of the plugin - Dropped weapons will be changed to the world model of the skin the player dropped.")
	g_EnableDownloadFile = CreateConVar("sm_wm_downloadparser", "0" , "If 1 adds files on downloads.ini to download table.")
	g_SmartDM = CreateConVar("sm_wm_useSmartDM", "0" , "If 1 uses SmartDM to add .mdl and all files associated with it to download table.")
	g_lowercase = CreateConVar("sm_wm_lowercasedownloads", "1" , "If 1 lowercases all lines in downloads.ini");
	g_tellusersskin = CreateConVar("sm_wm_informplayernumber", "1" , "If 1 displays the users that use each skin description style");
	g_AskUserIfTheyWantPublicSkins = CreateConVar("sm_wm_ask_about_public_skins_on_first_join", "1" , "If 1 new players will be asked if they want to be equipped with public weapon models.");
	OFFSET_THROWER  = FindSendPropOffs("CBaseGrenade", "m_hThrower");
	AutoExecConfig(true, "sm_weaponmodels")
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	CreateTimer(1.0, LoadConfigs);
	LoadTranslations("weaponmodels.phrases");
	//HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("bomb_planted", Event_C4Planted);
	HookEvent("round_start", Event_RoundStart);
	for (new client = 1; client <= MaxClients; client++) 
	{ 
		if (IsClientInGame(client)) 
		{
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
			CreateTimer(0.1, FetchClientSettings, client);
			//find both of the clients viewmodels
			ClientVM[client][0] = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
				
			new PVM = -1;
			while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
			{
				if (GetEntPropEnt(PVM, Prop_Send, "m_hOwner") == client)
				{
					if (GetEntProp(PVM, Prop_Send, "m_nViewModelIndex") == 1)
					{
						ClientVM[client][1] = PVM;
						break;
					}
				}
			}
		} 
	}
	AddCommandListener(Command_Drop, "drop");
	for (new i=1; i<=MaxClients; i++)
	{
		for (new v=0; v<=CSS_WEAPON_NUMBER-1; v++)
		{
			client_wepskin_index[i][v] = 64;
		}
		if(IsClientConnected(i) && IsClientAuthorized(i))	OnClientPostAdminCheck(i);
	}
	//ReloadUserSkinsNUM();
	//RegConsoleCmd("sm_reloadweapons", relol);
	//RegConsoleCmd("sm_fetchme", fetchhh);
}

public Action:fetchhh(client, args)
{
	if( 0 < client <= MaxClients)
	{
		TeSTing[client] = !TeSTing[client];
		PrintToChat(client, "%i", TeSTing[client]);
	}
	return Plugin_Handled;
}


//public Action:relol(client, args)
//{
//	ReloadUserSkinsNUM();
//	return Plugin_Handled;
//}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		PrintToServer("Error connecting to database: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change. Error 01");
	}
	h_DB = hndl;
	decl String:CreateDBifnotexist[2000];
	Format(CreateDBifnotexist, sizeof(CreateDBifnotexist), "CREATE TABLE IF NOT EXISTS `wmodels` (`SteamID` char(32) NOT NULL DEFAULT '',`1` varchar(3) NOT NULL DEFAULT '64',`2` varchar(3) NOT NULL DEFAULT '64',`3` varchar(3) NOT NULL DEFAULT '64',`4` varchar(3) NOT NULL DEFAULT '64',`5` varchar(3) NOT NULL DEFAULT '64',`6` varchar(3) NOT NULL DEFAULT '64',`7` varchar(3) NOT NULL DEFAULT '64',`8` varchar(3) NOT NULL DEFAULT '64',`9` varchar(3) NOT NULL DEFAULT '64',`10` varchar(3) NOT NULL DEFAULT '64',`11` varchar(3) NOT NULL DEFAULT '64',`12` varchar(3) NOT NULL DEFAULT '64',`13` varchar(3) NOT NULL DEFAULT '64',`14` varchar(3) NOT NULL DEFAULT '64',`15` varchar(3) NOT NULL DEFAULT '64',`16` varchar(3) NOT NULL DEFAULT '64',`17` varchar(3) NOT NULL DEFAULT '64',`18` varchar(3) NOT NULL DEFAULT '64',`19` varchar(3) NOT NULL DEFAULT '64',`20` varchar(3) NOT NULL DEFAULT '64',`21` varchar(3) NOT NULL DEFAULT '64',`22` varchar(3) NOT NULL DEFAULT '64',`23` varchar(3) NOT NULL DEFAULT '64',`24` varchar(3) NOT NULL DEFAULT '64',`25` varchar(3) NOT NULL DEFAULT '64',`26` varchar(3) NOT NULL DEFAULT '64',`27` varchar(3) NOT NULL DEFAULT '64',`28` varchar(3) NOT NULL DEFAULT '64',`29` varchar(3) NOT NULL DEFAULT '64',`30` varchar(3) NOT NULL DEFAULT '64',`31` varchar(3) NOT NULL DEFAULT '64',`32` varchar(3) NOT NULL DEFAULT '64',`33` varchar(3) NOT NULL DEFAULT '64',`34` varchar(3) NOT NULL DEFAULT '64',`35` varchar(3) NOT NULL DEFAULT '64',`36` varchar(3) NOT NULL DEFAULT '64',`37` varchar(3) NOT NULL DEFAULT '64',`38` varchar(3) NOT NULL DEFAULT '64',`39` varchar(3) NOT NULL DEFAULT '64',`40` varchar(3) NOT NULL DEFAULT '64', `viewm` varchar(3) NOT NULL DEFAULT '1',`worldm` varchar(3) NOT NULL DEFAULT '1', PRIMARY KEY (`SteamID`),UNIQUE KEY `SteamID` (`SteamID`)) ENGINE=MyISAM DEFAULT CHARSET=latin1;");
	SQL_TQuery(hndl, SQL_DoNothing, CreateDBifnotexist);
	//InitConfigFile();
}

/*
public Action:ActiveWeapond(client,args)
{
	ReplyToCommand(client, "Active Weapon: %s", ActiveWeapon[client]);
}
*/
public OnConfigsExecuted()
{
	if ((GetConVarInt(g_EnableDownloadFile)) == 1) AddToDT();
	AddServerTag("custom_weapon_models");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GetActiveWeaponModel", NativeActiveWModel);
	MarkNativeAsOptional("ZR_IsClientZombie");
	RegPluginLibrary("weaponmodels_5");
	return APLRes_Success;
}

public NativeActiveWModel(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	new String:weapon_name[40];
	GetNativeString(2, weapon_name, sizeof(weapon_name))
	new intweaponz = WeaponNameToNum(weapon_name);
	new wepindex_d = client_wepskin_index[client][intweaponz];
	if(weapon_info[intweaponz][wepindex_d][WModel][0] != EOS)
	{
		SetNativeString(3, weapon_info[intweaponz][wepindex_d][WModel] , 128);
	}
	else	SetNativeString(3, "models/weapons/w_knife_ct.mdl" , 128);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_WeaponEquipPost, WeaponEquip_CallBackPosto); 
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
	//SDKHook(client, SDKHook_WeaponDropPost, WeaponDropPost);
	//SDKHook(client, SDKHook_WeaponEquipPost, WeaponEquip_CallBack); 
	//SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
	//if(client > 0 && client < MAXPLAYERS+1) CreateTimer(1.0, FetchClientSettings, client);
	//SDKHook(client, SDKHook_WeaponEquip, WeaponEquip_CallBackk);
}

public Action:AskClient(Handle:Timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (!client || client > MaxClients)
	{
		return Plugin_Stop;
	}
	if(!IsClientConnected(client))
	{
		return Plugin_Stop;
	}
	if(IsClientInGame(client))
	{
		CreateTimer(0.1, AskClientMenu, client)
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:AskClientMenu(Handle:Timer, any:client)
{
	if(bool:GetConVarInt(g_AskUserIfTheyWantPublicSkins))
	{
		decl String:name[80];
		GetClientName(client, name, sizeof(name));	
		new Handle:menu = CreateMenu(MenuHandler1);
		SetMenuTitle(menu, "%t", "First Time Joining Menu Title", name);
		decl String:line_translation[128];
		FormatEx(line_translation, sizeof(line_translation), "%t", "First Time Joining Menu Positive menu entry");
		AddMenuItem(menu, "Yes", line_translation);
		FormatEx(line_translation, sizeof(line_translation), "%t", "First Time Joining Menu Negative menu entry");
		AddMenuItem(menu, "No", line_translation);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 3600);
	}
}

public OnClientPostAdminCheck(client)	{	if(client > 0 && client <= MaxClients) CreateTimer(0.01, FetchClientSettings, client);	}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		//SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		//SDKUnhook(client, SDKHook_WeaponEquipPost, WeaponEquip_CallBack);
		//Save stuff
		decl String:qwery[1024];
		FormatEx(qwery, sizeof(qwery), "UPDATE `wmodels` SET ");
		for(new i = 1; i <= 29; i++)
		{
			Format(qwery, sizeof(qwery), "%s`%i` = '%i', ", qwery, i, client_wepskin_index[client][i]);
		}
		Format(qwery, sizeof(qwery), "%s`30` = '%i' WHERE `SteamID` = '%s'", qwery, client_wepskin_index[client][30], G_SteamID[client]);
		SQL_TQuery(h_DB,SQL_DoNothing, qwery);
		strcopy(G_SteamID[client], sizeof(G_SteamID[]), "BOT");
	}
}

public Action:FetchClientSettings(Handle:timer, any:client)
{
	if (IsFakeClient(client))	return;
	if(client < 1 || client > MAXPLAYERS)	return;
	
	new String:steamid[50];
	GetClientAuthString(client, steamid, sizeof(steamid))
	G_SteamID[client] = steamid;
	////////////////////////
	//new String:GoGoFetch[100];
	//Format(GoGoFetch, sizeof(GoGoFetch), "SELECT viewm,worldm FROM `wmodels` WHERE SteamID = '%s'", steamid);
	//SQL_TQuery(h_DB, LoadDefinitions, GoGoFetch, client);
	Tellm(client);
	////////////////////////
	new String:DoesItEvenExist[128]
	Format(DoesItEvenExist, sizeof(DoesItEvenExist), "SELECT * FROM wmodels WHERE SteamID = '%s'", steamid);
	SQL_TQuery(h_DB, LoadUserStuff, DoesItEvenExist, client);
	/*
	new Handle:queryExist = SQL_Query(h_DB_noT, DoesItEvenExist);
	//
	if(SQL_FetchRow(queryExist))
	{
		new String:NowToFetch[130];
		Format(NowToFetch, sizeof(NowToFetch), dbToFetch, steamid);
		new Handle: FetchTech = SQL_Query(h_DB_noT, NowToFetch);
		if(SQL_FetchRow(FetchTech))
		{
			decl String:data[5];
			for (new n=1; n<=CSS_WEAPON_NUMBER-1; n++)
			{
				SQL_FetchString(FetchTech, n, data, sizeof(data));
				new int_index = StringToInt(data);
				client_wepskin_index[client][n] = int_index;
			}
		}
		CloseHandle(FetchTech);
	}
	else
	{
		new String:init[128];
		Format(init, sizeof(init), "INSERT INTO `rg3952_wmodels`.`wmodels` (`SteamID`) VALUES ('%s');", steamid);
		SQL_FastQuery(h_DB_noT, init);
		for (new i=0; i<=CSS_WEAPON_NUMBER-1; i++)
		{
			client_wepskin_index[client][i] = 64;
		}
		CreateTimer(0.2, AskClient, GetClientSerial(client), TIMER_REPEAT);
	}
	CloseHandle(queryExist);
	*/
}



public LoadUserStuff(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Query Error: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change. Error 02");
	}
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		decl String:data[5];
		for (new n=1; n<=CSS_WEAPON_NUMBER-1; n++)
		{
			SQL_FetchString(hndl, n, data, sizeof(data));
			new int_index = StringToInt(data);
			client_wepskin_index[client][n] = int_index;
		}
	}
	else
	{
		decl String:steamid[40];
		GetClientAuthString(client, steamid, sizeof(steamid));
		new String:init[128];
		Format(init, sizeof(init), "INSERT INTO `wmodels` (`SteamID`) VALUES ('%s');", steamid);
		SQL_TQuery(h_DB, SQL_DoNothing, init);
		//SQL_FastQuery(h_DB_noT, init);
		for (new i=0; i<=CSS_WEAPON_NUMBER-1; i++)
		{
			client_wepskin_index[client][i] = 64;
		}
		CreateTimer(0.2, AskClient, GetClientSerial(client), TIMER_REPEAT);
	}
}

public MenuHandler1(Handle:menu_s, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu_s, param2, info, sizeof(info));
			if (StrEqual(info, "Yes"))
			{	
				CPrintToChat(param1, "%t", "First Time Joining - Welcome to server chat message - YES");
				CPrintToChat(param1, "%t", "First Time Joining - Number of skins equiped", EquipPublicSkins(param1));
			}
			else if (StrEqual(info, "No"))
			{
				CPrintToChat(param1, "%t", "First Time Joining - Welcome to server chat message - NO");
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu_s);
		}
	}
}

AddToDT()
{
	decl String:path[128];
	BuildPath(Path_SM, path, 128, "configs/weapon_models/downloads.ini");
	new Handle:file = OpenFile(path, "r");
	decl String:line[128];
	decl len;
	while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
	{
		if(!(strncmp(line, "//", 2) == 0))
		{
			if(line[0] != '\n')
			{
				len = strlen(line);
				if (line[len-1] == '\n')
				{
					line[len-1] = EOS;
				}
				TrimString(line);
				if(GetConVarInt(g_lowercase) == 1)
				{		
					if(FileExists(line))
					{
						if (GetConVarInt(g_SmartDM) == 1)	Downloader_AddFileToDownloadsTable(line);
						else	AddFileToDownloadsTable(line);
					}
					else
					{
						String_ToLower(line, line, sizeof(line)); 
						if(FileExists(line))
						{
							if (GetConVarInt(g_SmartDM) == 1)	Downloader_AddFileToDownloadsTable(line);
							else	AddFileToDownloadsTable(line);
						}
					}
				}
				else
				{
					if(FileExists(line))
					{
						if (GetConVarInt(g_SmartDM) == 1)	Downloader_AddFileToDownloadsTable(line);
						else AddFileToDownloadsTable(line);
					}
				}
			}
		}
	}
	CloseHandle(file);
}
public Action:LoadConfigs(Handle:timer, any:none)
{
	new String:saychat[128];
	GetConVarString(g_ChatCommands, saychat , sizeof(saychat));
	ExplodeString(saychat, " ", g_menuCommands, sizeof(g_menuCommands), sizeof(g_menuCommands[]));

}


public OnMapStart()
{
	if(h_DB == INVALID_HANDLE)
	{
		SQL_TConnect(OnDatabaseConnect, "wmodels");
	}	
	//InitConfigFile();
	for(new i = 0; i < sizeof(weaponVDefaultModels);i++)
	{
		if(weaponVDefaultModels[i][0] != EOS)
		{
			weapondefaultpc[i] = PrecacheModel(weaponVDefaultModels[i]);
		}
	}
}


public OnMapEnd()
{
	new i = 0;
	while(i <= 39)
	{
		strcopy(ListOfEntityWeaponsToUse[i], sizeof(ListOfEntityWeaponsToUse), "");
		i++
	}
	/*
	if(trie != INVALID_HANDLE)
	{
		CloseHandle(trie);
		trie = INVALID_HANDLE;
	}
	*/
}

public Action:Command_Say(client, const String:command[], args)
{
	if (0 < client <= MaxClients && !IsClientInGame(client)) 
		return Plugin_Continue;
			
	decl String:text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	for (new index = 0; index < sizeof(g_menuCommands); index++) 
	{
		if (StrEqual(g_menuCommands[index], text))
		{
			new String:method[10];
			GetConVarString(g_AccessMethod, method, sizeof(method));
			if (StrEqual(method, "flag", true))
			{
				new chat_flag;
				new String:flag[2];
				GetConVarString(g_AccessFlag, flag, sizeof(flag))
				chat_flag = ReadFlagString(flag);
				if(GetUserFlagBits(client) & chat_flag) Interface_Menu(client);
				else (CPrintToChatEx(client,client, "%t", "NotAllowedToAcessMainMenu"));
			
			}
			else if (StrEqual(method, "group", true))
			{
				new String:group[16];
				GetConVarString(g_AccessGroup, group, sizeof(group))
				if(Client_IsInAdminGroup(client, group, false)) Interface_Menu(client);
				else (CPrintToChatEx(client,client, "%t", "NotAllowedToAcessMainMenu"));
			
			}
			else if (StrEqual(method, "public", true))
			{
				Interface_Menu(client);
			}
			if(text[0] == '/') return Plugin_Handled;
		}		
	}
	
	return Plugin_Continue;
}
/*
public Action:ReloadWeaponModels(client,args)
{
	CloseHandle(g_hbuildemenu);
	g_hbuildemenu = INVALID_HANDLE;
	g_hbuildemenu = BuildWeaponMenu();
	return Plugin_Handled;
}
*/
//

new Init_Timer_ASDF;

public Action:Init_Timer(Handle:timer)
{
	if(h_DB == INVALID_HANDLE)
	{
		if(Init_Timer_ASDF > 0)
		{
			LogError("Retrying database connection for the %i time", Init_Timer_ASDF);
			CreateTimer(1.0, Init_Timer);
		}
		Init_Timer_ASDF++;
	}
	else
	{
		InitConfigFile();
	}
}

InitConfigFile()
{
	if(h_DB == INVALID_HANDLE)	return;
	if(trie != INVALID_HANDLE)
	{
		CloseHandle(trie);
		trie = INVALID_HANDLE;
	}
	trie = CreateTrie();
	/* Create the KV Handle */
	new Handle:kv = CreateKeyValues("WeaponModels");
	/* Build Path to the file which stores all the keyvalues */
	decl String:File[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, File, sizeof(File), "configs/weapon_models/weapon_models.ini");
	/* Read keyvalues from file */
	FileToKeyValues(kv, File);
	// If keyvalues file is not in valid format then return invalid_handle (abort parsing)
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	//
	for (new x=0; x<CSS_WEAPON_NUMBER; x++)
			{
				for (new n=0; n<CSS_WEAPON_NUMBER; n++)
				{
					strcopy(weapon_info[x][n][Flag], 3, "z");
				}
			}
	//
	new String:WeaponName[38], String:DisplayName[2][33], String:Category_Name[CSS_WEAPON_NUMBER][32];
	new x = 0;
	new String:buffer[5];
	do
	{
		/* Get Section Name*/
		KvGetSectionName(kv, WeaponName, sizeof(WeaponName));
		/* Convert Section name to Int */
		new adij = WeaponNameToNum(WeaponName);
		/* Let's see if we should put this section on menu! */
		/*
		
		new String:temporary_string[4];
		KvGetString(kv, "enabled", temporary_string, sizeof(temporary_string), "1");
		new temporary_num = StringToInt(temporary_string);
		if (temporary_num == 0)	weapon_enabled[adij] = false;
		
		*/
		/* Explode String: weapon_m4a1 -> m4a1 */
		if(!ExplodeString(WeaponName, "_", DisplayName, sizeof(DisplayName), sizeof(DisplayName[]))) return;
		/* Upper case it! */
		new String:FDisplayName[33];
		StrToUpper(DisplayName[1], FDisplayName, sizeof(FDisplayName));
		/* Add to arrays for later alphabetical order sorting */
		//Format(ListOfNamesWeaponsToUse[x], sizeof(ListOfNamesWeaponsToUse[]), "%s", FDisplayName);
		//Format(ListOfEntityWeaponsToUse[x], sizeof(ListOfEntityWeaponsToUse[]), "%s", WeaponName);
		strcopy(ListOfEntityWeaponsToUse[x], sizeof(ListOfEntityWeaponsToUse), WeaponName);
		KvGetString(kv, "category_name", Category_Name[x], 32, FDisplayName);
		SetTrieString(trie, WeaponName, Category_Name[x], true);
		/* Lets Explore the section! */
		KvJumpToKey(kv, WeaponName, false)
		KvGotoFirstSubKey(kv, true);
		new y = 0;
		do
		{
			new String:SectionName[64];
			KvGetSectionName(kv, SectionName, sizeof(SectionName));
			strcopy(weapon_info[adij][y][Name], 64, SectionName);
			KvGetString(kv, "description", weapon_info[adij][y][Description], 128, "");
			KvGetString(kv, "view_model", weapon_info[adij][y][VModel], 128, "");
			//if (!FileExists(weapon_info[adij][y][VModel]))		LogError("[Weapon_Models] View Model File for %s - %s not found. Intencional or not?", WeaponName, weapon_info[adij][y][VModel]);
			if(weapon_info[adij][y][VModel][0] != EOS)
			{			
				if (GetConVarInt(g_SmartDM) == 1)
				{
					Downloader_AddFileToDownloadsTable(weapon_info[adij][y][VModel]);
				}
				weapon_info[adij][y][PVModel] = PrecacheModel(weapon_info[adij][y][VModel]);
			}
			KvGetString(kv, "world_model", weapon_info[adij][y][WModel], 128, "");
			//if (!FileExists(weapon_info[adij][y][WModel]))		LogError("[Weapon_Models] World Model File for %s - %s not found. Intencional or not?", WeaponName, weapon_info[adij][y][VModel]);
			if(weapon_info[adij][y][WModel][0] != EOS)
			{	
				if (GetConVarInt(g_SmartDM) == 1)
				{
					Downloader_AddFileToDownloadsTable(weapon_info[adij][y][WModel]);
				}
				weapon_info[adij][y][PWModel] = PrecacheModel(weapon_info[adij][y][WModel]);
			}
			KvGetString(kv, "flag", weapon_info[adij][y][Flag], 128, "");
			KvGetString(kv, "enabled", weapon_info[adij][y][Enabled], 4, "1");
			KvGetString(kv, "index", buffer, 4, "0");
			weapon_info[adij][y][Index] = StringToInt(buffer);
			new String:IndexPos[5];
			IntToString(y, IndexPos, sizeof(IndexPos));
			if (GetConVarInt(g_tellusersskin) == 1)	
			{
				if (ToReloadnumusers == 0 && weapon_info[adij][y][Name][0] != EOS)
				{
					new Handle:data = CreateDataPack();
					WritePackCell(data, adij);
					WritePackCell(data, y);
					CreateTimer( (GetRandomFloat(0.1, 1.5)) ,GetUsersTimer, data);
				}
			}
			//SetTrieString(trie2, SectionName, weapon_info[adij][y][Description], true);
			//SetTrieString(trie3, SectionName, IndexPos, true);
			new EnabledInt = StringToInt(weapon_info[adij][y][Enabled]);
			if (EnabledInt != 0)
				y++;
		}
		while(KvGotoNextKey(kv) && y < 65)
		x++;
		y++;
		for (new i=y; i<=65; i++)
		{
			strcopy(weapon_info[adij][y][Flag], 5, "z");
		}
		KvGoBack(kv);
		y = 0;
	}
	while (KvGotoNextKey(kv));
	/* Sort Weapon Names */
	x = 0;
	
	SortCustom2D(_:ListOfEntityWeaponsToUse, sizeof(ListOfEntityWeaponsToUse), SortAlphabetically);	// Thanks 11530 - https://forums.alliedmods.net/showthread.php?t=233250
	
	/* Some safety for the plugin not to crash */
	ToReloadnumusers++;
	/* Make sure we close the file! */
	KvRewind(kv);
	CloseHandle(kv);
}

public Action:GetUsersTimer(Handle:timer, any:data)
{
	if(h_DB != INVALID_HANDLE)
	{
		ResetPack(data);
		new adij =	ReadPackCell(data);
		new y =	ReadPackCell(data);
		CloseHandle(data);
		GetUsersOfSkin(adij, y);
	}
	else
	{
		CreateTimer(1.0, GetUsersTimer, data);
	}
}

public SortAlphabetically(String:elem1[], String:elem2[], const String:array[][], Handle:hndl)
{
	new String:string1[38],String:string2[38];
	strcopy(string1, sizeof(string1), elem1);
	strcopy(string2, sizeof(string2), elem2);
	
	if (elem1[0] == elem2[0])
	{
		string1[0] = ' ';
		string2[0] = ' ';
		TrimString(string1);
		TrimString(string2);
				
		new n = 1;
		while (n > 0 && n < strlen(elem1) && n < strlen(elem2))
		{
			if (string1[n] == string2[n])
			{
				string1[n] = ' ';
				string2[n] = ' ';
				TrimString(string1);
				TrimString(string2);
				n++;
			}
			else
			{
				return strcmp(string1[n], string2[n], false);
			}
		}
	}
	else
	{
		return strcmp(elem1[0], elem2[0], false);
	}
	return strcmp(elem1, elem2, false);
}  

/////////////	
Interface_Menu(client)
{

	// create menu
	new Handle:interface_menus = CreateMenu(Interface_wepmenu);
	new String:entry[128];
	Format(entry, sizeof(entry), "%t", "Change Weapon Skins");
	AddMenuItem(interface_menus, "changewep", entry);
	Format(entry, sizeof(entry), "%t", "Definitions");
	AddMenuItem(interface_menus, "def", entry);
	SetMenuTitle(interface_menus, "%t", "Main Menu Title");
	
	AddMenuItem(interface_menus, "creds", "Credits");
	
	DisplayMenu(interface_menus, client, MENU_TIME_FOREVER);
}

public Interface_wepmenu(Handle:interface_menus, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_Select)
	{
		new String:info[38];
		GetMenuItem(interface_menus, param2, info, sizeof(info));
		new bool:GotAccess = false;
		if (StrEqual(info, "changewep"))
		{
			/*
			//Check for Access
			new x = 0;
			new n = 0;
			while(weapon_info[x][n][Name][0] != EOS && weapon_info[x][n][Flag] != EOS && GotAccess == false)
			{
				while(weapon_info[x][n][Flag] && GotAccess == false)
				{
					new skinf;
					skinf = ReadFlagString(weapon_info[x][n][Flag]);
					if(GetUserFlagBits(param1) & skinf)
					{
						GotAccess = true;
					}
					n++;
				}
				x++;
				n = 0;
			}
			*/
			
			for (new x=0; x<CSS_WEAPON_NUMBER && GotAccess == false; x++)
			{
				for (new n=0; n<CSS_WEAPON_NUMBER && GotAccess == false; n++)
				{
					if (weapon_info[x][n][Flag][0] == EOS) GotAccess = true;
					else
					{
						new skinf;
						skinf = ReadFlagString(weapon_info[x][n][Flag]);
						if(GetUserFlagBits(param1) & skinf)
						{
							GotAccess = true;
						}
					}
				}
			}
			if (GotAccess) Main_Weapon_Menu(param1)
			else {CPrintToChat(param1, "%t", "No Access to Menu to choose weapon to change skin"); Interface_Menu(param1);}
		}
		if (StrEqual(info, "def")) Menu_Def(param1)
		if (StrEqual(info, "creds")) Creditos(param1)
	}
	if (action == MenuAction_End)
	{
		CloseHandle(interface_menus);
	}
}
//////////////////
Menu_Def(client)
{
	if (client < 1 || client > MAXPLAYERS)	return;
	// create menu
	new Handle:def_menu = CreateMenu(Def_Options);
	new String:entry[256];
	if(ViewModelsEnabled[client]) 
	{
		Format(entry, sizeof(entry), "%t", "Disable View Models");
		AddMenuItem(def_menu, "disview", entry);
	}
	if(!ViewModelsEnabled[client]) 
	{
		Format(entry, sizeof(entry), "%t", "Enable View Models");
		AddMenuItem(def_menu, "enaview", entry);
	}
	if(WorldModelsEnabled[client]) 
	{
		Format(entry, sizeof(entry), "%t", "Disable World Models");
		AddMenuItem(def_menu, "disworld", entry);
	}
	if(!WorldModelsEnabled[client]) 
	{
		Format(entry, sizeof(entry), "%t", "Enable World Models");
		AddMenuItem(def_menu, "enaworld", entry);
	}
	SetMenuTitle(def_menu, "%t", "Definitions Title");
	SetMenuExitBackButton(def_menu, true);
	DisplayMenu(def_menu, client, MENU_TIME_FOREVER);
}


public Def_Options(Handle:def_menu, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_Select)
	{
		if(param1 < 1) return;
		new String:steamid[30];
		GetClientAuthString(param1, steamid, sizeof(steamid));
		new String:QuerySQL[100];
		
		new String:info[38];
		GetMenuItem(def_menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "disview"))
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `viewm` = '0' WHERE `SteamID` = '%s'", steamid);
			ViewModelsEnabled[param1] = false;
		}
		if (StrEqual(info, "enaview"))
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `viewm` = '1' WHERE `SteamID` = '%s'", steamid);
			ViewModelsEnabled[param1] = true;
		}
		if (StrEqual(info, "disworld"))
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `worldm` = '0' WHERE `SteamID` = '%s'", steamid);
			WorldModelsEnabled[param1] = false;
		}
		
		if (StrEqual(info, "enaworld"))
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `worldm` = '1' WHERE `SteamID` = '%s'", steamid);
			WorldModelsEnabled[param1] = true;
		}
		SQL_TQuery(h_DB, SQL_DoNothing, QuerySQL);
		//SQL_FastQuery(h_DB_noT, QuerySQL);
		Menu_Def(param1);
	}
	if (action == MenuAction_End)
	{
		CloseHandle(def_menu);
		/*
		if(param1 < 1) return;
		new String:QuerySQL[100];
		new String:steamid[30];
		GetClientAuthString(param1, steamid, sizeof(steamid));
		
		if (ViewModelsEnabled[param1])
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `viewm` = '1' WHERE `SteamID` = '%s'", steamid);
		}
		else if (!ViewModelsEnabled[param1])
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `viewm` = '0' WHERE `SteamID` = '%s'", steamid);
		}
		SQL_TQuery(h_DB, SQL_DoNothing, QuerySQL);
		if (WorldModelsEnabled[param1])
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `worldm` = '1' WHERE `SteamID` = '%s'", steamid);
		}
		
		else if (!WorldModelsEnabled[param1])
		{
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `worldm` = '0' WHERE `SteamID` = '%s'", steamid);
		}
		SQL_TQuery(h_DB, SQL_DoNothing, QuerySQL);
		*/
	}
	if (action == MenuAction_Cancel)
	{
		if(param1 < 1) return;
		Interface_Menu(param1);
	}
}
////////////////////

Creditos(client)
{
	// create menu
	new Handle:credits_menu = CreateMenu(Credits_Menuu);
	new String:credits[512];
	Format(credits, sizeof(credits), "%t", "Credits");
	SetMenuTitle(credits_menu, "Créditos:\n \n");
	AddMenuItem(credits_menu, "is" , credits , ITEMDRAW_DISABLED);
	SetMenuExitBackButton(credits_menu, true);
	DisplayMenu(credits_menu, client, MENU_TIME_FOREVER);
}

public Credits_Menuu(Handle:credits_menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(credits_menu);
	}
	if (action == MenuAction_Cancel)
	{
		Interface_Menu(param1);
	}
}


////////////////////
Main_Weapon_Menu(client)
{

	// create menu
	new Handle:menura = CreateMenu(Menu_MainWeaponSkin);
	for(new i; i < sizeof(ListOfEntityWeaponsToUse); i++)
	{
		if(strlen(ListOfEntityWeaponsToUse[i]) > 0)
		{
			new int_weapon = WeaponNameToNum(ListOfEntityWeaponsToUse[i]);
			new index = client_wepskin_index[client][int_weapon];
			
			new String:NameDescToDisplayMenu[128];
			GetTrieString(trie, ListOfEntityWeaponsToUse[i], NameDescToDisplayMenu, sizeof(NameDescToDisplayMenu));
			
			new String:current_skin_name[40];
			strcopy(current_skin_name, sizeof(current_skin_name), weapon_info[int_weapon][index][Name])
			if (weapon_info[int_weapon][index][Flag][0] == EOS) strcopy(current_skin_name, sizeof(current_skin_name), weapon_info[int_weapon][index][Name])
			else if (weapon_info[int_weapon][index][Flag][0] != EOS)
			{
				new skinf;
				skinf = ReadFlagString(weapon_info[int_weapon][index][Flag]);
				if(GetUserFlagBits(client) & skinf)
				{
					strcopy(current_skin_name, sizeof(current_skin_name), weapon_info[int_weapon][index][Name])
				}
				else Format(current_skin_name,sizeof(current_skin_name), "Stock");
			}
			if(current_skin_name[0] == EOS)	Format(current_skin_name,sizeof(current_skin_name), "Stock");
			Format(NameDescToDisplayMenu, sizeof(NameDescToDisplayMenu), "%t", "MainMenuEntry", NameDescToDisplayMenu, current_skin_name);
			
			if(HasAcessCat(client, int_weapon)) AddMenuItem(menura, ListOfEntityWeaponsToUse[i], NameDescToDisplayMenu);
			//AddMenuItem(menura, ListOfEntityWeaponsToUse[i], NameDescToDisplayMenu);
			//Format(ListOfEntityWeaponsToUse[i], sizeof(ListOfEntityWeaponsToUse), "");
		}
	}
	SetMenuTitle(menura, "%t", "SelectWeaponToChangeSkin");
	SetMenuExitBackButton(menura, true);
	DisplayMenu(menura, client, MENU_TIME_FOREVER);
}

public Menu_MainWeaponSkin(Handle:menura, MenuAction:action, param1, param2)
{
	
	if (action == MenuAction_Select)
	{
		new String:info[38];
		GetMenuItem(menura, param2, info, sizeof(info));
		Specific_weapon_menu(param1, info);
		//new armanum = WeaponNameToNum(info);
		//PrintToChat(param1, "%s", weapon_info[armanum][1][VModel])
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menura);
	}
	if (action == MenuAction_Cancel)
	{
		Interface_Menu(param1)
	}
}

Specific_weapon_menu(client, String:weapon[], itemnum = 0)
{
	if (StrContains(weapon, "weapon", false) == -1) return;
	if (client == 0 || client > MAXPLAYERS) return;
	new WeaponInt = WeaponNameToNum(weapon);
	new String:DisplayNamez[2][33];
	ExplodeString(weapon, "_", DisplayNamez, sizeof(DisplayNamez), sizeof(DisplayNamez[]))
	//new String:FDisplayNamez[33];
	//StrToUpper(DisplayNamez[1], FDisplayNamez, sizeof(FDisplayNamez));
	new String:DisplayNameWM[40];
	GetTrieString(trie, weapon, DisplayNameWM, sizeof(DisplayNameWM));
	
	// create menu
	new Handle:menuz = CreateMenu(Menu_ChooseSpecificWSkins);
	new x = 0;
	while(weapon_info[WeaponInt][x][Name][0] != EOS)
	{
		
		new String:WhatIsGoingToBeDisplayed[250];
		if (GetConVarInt(g_tellusersskin) == 1)
		{
			new String:DescToDisplay[200];
			strcopy(DescToDisplay, sizeof(DescToDisplay), weapon_info[WeaponInt][x][Description]);
			if(DescToDisplay[0] == EOS)
			{
				FormatEx(DescToDisplay, sizeof(DescToDisplay), "%t", "Number of players with skin equiped" ,weapon_info[WeaponInt][x][NumUsers]);
			
			}
			else
			{
				Format(DescToDisplay, sizeof(DescToDisplay), "%s \n%t", DescToDisplay, "Number of players with skin equiped" ,weapon_info[WeaponInt][x][NumUsers]);
			}
			
			if(client_wepskin_index[client][WeaponInt] == x)
			{		
				FormatEx(WhatIsGoingToBeDisplayed, sizeof(WhatIsGoingToBeDisplayed), "[E] %s \n%s", weapon_info[WeaponInt][x][Name], DescToDisplay);
			}
			else
			{
				FormatEx(WhatIsGoingToBeDisplayed, sizeof(WhatIsGoingToBeDisplayed), "%s \n%s", weapon_info[WeaponInt][x][Name], DescToDisplay);
			}
		}
		else
		{
			if(client_wepskin_index[client][WeaponInt] == x)
			{		
				Format(WhatIsGoingToBeDisplayed, sizeof(WhatIsGoingToBeDisplayed), "[E] %s \n%s", weapon_info[WeaponInt][x][Name], weapon_info[WeaponInt][x][Description]);
			}
			else
			{
				Format(WhatIsGoingToBeDisplayed, sizeof(WhatIsGoingToBeDisplayed), "%s \n%s", weapon_info[WeaponInt][x][Name], weapon_info[WeaponInt][x][Description]);
			}
		}
		new String:Position[4]
		IntToString(x, Position, sizeof(Position));
		if (weapon_info[WeaponInt][x][Flag][0] != EOS)
		{
			new skin_flag;
			skin_flag = ReadFlagString(weapon_info[WeaponInt][x][Flag]);
			if(GetUserFlagBits(client) & skin_flag)
			{
				AddMenuItem(menuz, Position, WhatIsGoingToBeDisplayed);
			}
		}
		else
		{
			AddMenuItem(menuz, Position, WhatIsGoingToBeDisplayed)
		}
		x++;
	}
	// store client current weapon menu
	strcopy(weaponmenu[client], 38, weapon);
	strcopy(weaponmenu_displayname[client], 33, DisplayNameWM);
	// send menu to client
	SetMenuExitBackButton(menuz, true);
	SetMenuTitle(menuz, "%t", "SelectSkinToChangeWeaponModelTo", DisplayNameWM);
	DisplayMenu(menuz, client, MENU_TIME_FOREVER);
	// Now to set the page to the same one the client was in when he changed model:
	if(itemnum > 6 && itemnum != 64)
	{
		//itemnum++;
		new Float:omnom = (itemnum / 7.0);
		new Row = RoundToFloor(omnom);
		//new Float:Timer = 0.000;
		for(new i = 1; i <= Row; i++)
		{
			//CreateTimer(Timer, MenuSelect9, client);
			//Timer = Timer + 0.001;
			FakeClientCommand(client, "menuselect 9");
		}
	}
}

public Action:MenuSelect9(Handle:Timer, any:client) { FakeClientCommand(client, "menuselect 9"); }

public Menu_ChooseSpecificWSkins(Handle:menuz, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param1 > 0)
			{
			new armaint = WeaponNameToNum(weaponmenu[param1]);	
			new String:info[38];
			GetMenuItem(menuz, param2, info, sizeof(info));
			new position = StringToInt(info);
			new temp_int = get_menu_position_for_client(param1, armaint, position);
			
			//
			new oldskin = client_wepskin_index[param1][armaint];
			//
			if (client_wepskin_index[param1][armaint] == position)
			{
				position = 64;
				client_wepskin_index[param1][armaint] = 64;
				CPrintToChatEx(param1, param1, "%t", "OnSameSkinChange", weaponmenu_displayname[param1]);
				if (GetConVarInt(g_tellusersskin) == 1) weapon_info[armaint][oldskin][NumUsers]--;
			}
			else
			{
				new String:ToDisplayNe[64];
				strcopy(ToDisplayNe, sizeof(ToDisplayNe), weapon_info[armaint][position][Name]);
				TrimString(ToDisplayNe);
				client_wepskin_index[param1][armaint] = position;
				CPrintToChatEx(param1, param1, "%t", "OnSkinChange", weaponmenu_displayname[param1], ToDisplayNe);
				if (GetConVarInt(g_tellusersskin) == 1)
				{ 
					weapon_info[armaint][oldskin][NumUsers]--;
					weapon_info[armaint][position][NumUsers]++;
				}
			}
			Specific_weapon_menu(param1, weaponmenu[param1], temp_int)
			
			new weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			if(IsValidEdict(weapon))
			{
				new String:szz_Classname[32];
				GetEdictClassname(weapon, szz_Classname, sizeof(szz_Classname));
				if (StrEqual(szz_Classname, weaponmenu[param1], false))
				{
					if (StrContains(szz_Classname, "knife", false) != -1 || StrContains(szz_Classname, "claws", false) != -1)
					{
						RemovePlayerItem(param1, weapon);
						RemoveEdict(weapon);
						GivePlayerItem(param1, "weapon_knife");
						return;
					}
					new silencer;
					if ((StrContains(szz_Classname, "m4a1", false) != -1) || (StrContains(szz_Classname, "usp", false) != -1))
					{
						silencer = GetEntProp(weapon, Prop_Send, "m_bSilencerOn");
					}
					new m_iPrimaryAmmoType		= GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); // Ammo type
					new m_iClip1 = -1;
					new m_iAmmo_prim	 = -1;
					if(m_iPrimaryAmmoType != -1)
					m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
					m_iAmmo_prim = GetEntProp(param1, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
					RemovePlayerItem(param1, weapon);
					if (IsValidEdict(weapon)) AcceptEntityInput(weapon, "Kill");
					new weapon2 = GivePlayerItem(param1, szz_Classname);
					SetEntProp(weapon2, Prop_Send, "m_iClip1", m_iClip1); // Set weapon clip ammunition
					SetEntProp(param1, Prop_Send, "m_iAmmo", m_iAmmo_prim, _, m_iPrimaryAmmoType); // Set player ammunition of this weapon primary ammo type
					if(silencer == 1)
					{
						SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 1);
						SetEntProp(weapon, Prop_Send, "m_weaponMode", 1);
					}
				}
			}
			new String:steamid[30];
			GetClientAuthString(param1, steamid, sizeof(steamid));
			new String:QuerySQL[100];
			Format(QuerySQL, sizeof(QuerySQL), "UPDATE `wmodels` SET `%i` = '%i' WHERE `SteamID` = '%s'", armaint, position, steamid);
			//SQL_FastQuery(h_DB_noT, QuerySQL);
			SQL_TQuery(h_DB,SQL_DoNothing, QuerySQL);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuz);
	}
	else if (action == MenuAction_Cancel)
	{
		if(param1 > 0)
		{
			Main_Weapon_Menu(param1);
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	decl String:classname[30];
	GetEdictClassname(entity, classname, sizeof(classname));
	PrintToChat(Owner, "Lal %s", classname);
	if (StrEqual(classname, "hegrenade_projectile", false) || StrEqual(classname, "flashbang_projectile", false) || StrEqual(classname, "smokegrenade_projectile", false))
	{
		new Handle:datapack = CreateDataPack();
		WritePackString(datapack, classname);
		WritePackCell(datapack, entity);
		new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		WritePackCell(datapack, client);
		CreateTimer(0.01, InitGrenade, datapack);
		PrintToChat(client, "Lol %s", classname);
	}
*/
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////


stock StrToUpper(const String:str[], String:buffer[], bufsize) {

	new n=0, x=0;
	while (str[n] != EOS && x < (bufsize-1)) { // Make sure we are inside bounds

		new char = str[n++]; // Caching
	
		if (char == ' ') { // Am I nothing ?
			// Let's do nothing !
			continue;
		}
		else if (CharToLower(char)) { // Am I big ?
			char = CharToUpper(char); // Big becomes low
		}

		buffer[x++] = char; // Write into our new string
	}

	buffer[x++] = EOS; // Finalize with the end ( = always 0 for strings)

	return x; // return number of bytes written for later proove
}  
//


stock WeaponNameToNum(const String:str[])
{
	new String:ToReplaceString[38];
	strcopy(ToReplaceString, sizeof(ToReplaceString), str);
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_ak47", "1");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_aug", "2");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_awp", "3");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_c4", "4");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_deagle", "5");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_elite", "6");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_famas", "7");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_fiveseven", "8");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_flashbang", "9");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "flashbang_projectile", "9");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_g3sg1", "10");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_galil", "11");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_glock", "12");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_hegrenade", "13");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "hegrenade_projectile", "13");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_m3", "14");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_m4a1", "15");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_m249", "16");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_mac10", "17");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_mp5navy", "18");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_p90", "19");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_p228", "20");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_scout", "21");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_sg550", "22");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_sg552", "23");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_smokegrenade", "24");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "smokegrenade_projectile", "24");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_tmp", "25");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_ump45", "26");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_usp", "27");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_xm1014", "28");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_claws", "29");
	ReplaceString(ToReplaceString, sizeof(ToReplaceString), "weapon_knife", "30");
	return StringToInt(ToReplaceString);
}

stock DefaultModel(weaponnum , String:buffer[], bufsize)
{
	strcopy(weaponnum, bufsize, weaponVDefaultModels[weaponnum]);
}
stock bool:HasAcessCat(client, int_weapon)
{
	if(!IsClientInGame(client))	return false;
	new m = 0;
	while(m < MAX_SKINS_PER_WEAPON)
	{
		if(weapon_info[int_weapon][m][Flag][0] != EOS)
		{
			new skin_flag;
			skin_flag = ReadFlagString(weapon_info[int_weapon][m][Flag]);
			if(GetUserFlagBits(client) & skin_flag) return true;
		}
		else if (weapon_info[int_weapon][m][Name][0] != EOS)
		{
			return true;
		}
		m++;
	}
	return false;

}
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////



public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "predicted_viewmodel", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
	if (StrEqual(classname, "hegrenade_projectile", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
	if (StrEqual(classname, "flashbang_projectile", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
	if (StrEqual(classname, "smokegrenade_projectile", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}
	



public OnEntitySpawned(entity)
{
	if(IsValidEntity(entity) && entity >= 0 && entity < 2049)
	{
		decl String:classname[40];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "predicted_viewmodel", false))
		{
			new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
			if ((Owner > 0) && (Owner <= MaxClients))
			{
				if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
				{
					ClientVM[Owner][0] = entity;
				}
				else if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 1)
				{
					ClientVM[Owner][1] = entity;
				}
			}
		}
		if (StrEqual(classname, "hegrenade_projectile", false))
		{
			//new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
			//nadeThrown[client] = entity;
			CreateTimer(0.0, InitGrenade, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (StrEqual(classname, "flashbang_projectile", false))
		{
			//new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
			//nadeThrown[client] = entity;
			CreateTimer(0.0, InitGrenade, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (StrEqual(classname, "smokegrenade_projectile", false))
		{
			//new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
			//nadeThrown[client] = entity;
			CreateTimer(0.0, InitGrenade, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:InitGrenade(Handle:timer, any:iGrenade)
{
	if(!IsValidEntity(iGrenade))
	{
		return;
	}
	
	new client = GetEntDataEnt2(iGrenade, OFFSET_THROWER);
	
	if(client < 1 || client > MaxClients)
	{
		return;
	}
	
	nadeThrown[client] = iGrenade;
}


public OnPostThinkPost(client)
{
	decl String:cvarvaluel[3];
	GetConVarString(g_VModelsEnabled, cvarvaluel , sizeof(cvarvaluel))
	new cvarivalueu = StringToInt(cvarvaluel);
	if (cvarivalueu == 0)		return;
	
	decl String:method[10];
	GetConVarString(g_AccessMethod, method, sizeof(method));
	if (StrEqual(method, "flag", true))
	{
		decl chat_flag;
		decl String:flag[2];
		GetConVarString(g_AccessFlag, flag, sizeof(flag))
		chat_flag = ReadFlagString(flag);
		if(!(GetUserFlagBits(client) & chat_flag))		return;
	}
	else if (StrEqual(method, "group", true))
	{
		decl String:group[16];
		GetConVarString(g_AccessGroup, group, sizeof(group))
		if(!Client_IsInAdminGroup(client, group, false)) return;
			
	}
	
	if(nadeThrown[client] > 0 && IsValidEntity(nadeThrown[client]) && WorldModelsEnabled[client])
	{
		decl String:classname[30];
		GetEdictClassname(nadeThrown[client], classname, sizeof(classname));
		new integer_wep = WeaponNameToNum(classname);
		new wepindex_player = client_wepskin_index[client][integer_wep];
		if (weapon_info[integer_wep][wepindex_player][WModel][0] != EOS && (weapon_info[integer_wep][wepindex_player][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[integer_wep][wepindex_player][Flag])))
		{
			if (IsValidEntity(nadeThrown[client]) && IsValidEdict(nadeThrown[client])) SetEntProp(nadeThrown[client], Prop_Send, "m_nModelIndex", weapon_info[integer_wep][wepindex_player][PWModel]);
		}
		nadeThrown[client] = 0;
	}
	
	static OldWeapon[MAXPLAYERS + 1];
	static OldSequence[MAXPLAYERS + 1];
	static Float:OldCycle[MAXPLAYERS + 1];
	static bool:IsAlive[MAXPLAYERS + 1];
	
	if(IsAlive[client] && !IsPlayerAlive(client))
	{
		new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
	}
	if(!IsAlive[client] && IsPlayerAlive(client))
	{
		SpawnCheck[client] = true;
	}
	IsAlive[client] = IsPlayerAlive(client);
	
	if(ReviewVM[client])
	{
		OldWeapon[client] = 0;
		ReviewVM[client] = false;
	}
	
	decl String:ClassName[30];
	new WeaponIndex;
	
	//handle spectators
	if (!IsPlayerAlive(client))
	{
		new spec = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (spec != -1 )
		{
			new val = GetEntProp(spec, Prop_Send, "m_iHealth");
			if (val < 1)	return;
			WeaponIndex = GetEntPropEnt(spec, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(WeaponIndex))
				return;
			GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
			new wepnum = WeaponNameToNum(ClassName);
			new index_sk = client_wepskin_index[spec][wepnum];
			if(client_wepskin_index[spec][wepnum] < 64 && (weapon_info[wepnum][index_sk][VModel][0] != EOS) && ViewModelsEnabled[spec] && (weapon_info[wepnum][index_sk][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[wepnum][index_sk][Flag])))
			{
				if(wepnum == 30 && (GetFeatureStatus(FeatureType_Native, "ZR_IsClientZombie") == FeatureStatus_Available))
				{
					if (ZR_IsClientZombie(spec))
					{
						if (IsValidEntity(ClientVM[client][1])) SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[29][index_sk][PVModel]);
					}
					else
					{
						if (IsValidEntity(ClientVM[client][1])) SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[wepnum][index_sk][PVModel]);
					}
				}
				else if (IsValidEntity(ClientVM[client][1])) SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[wepnum][index_sk][PVModel]);
				if(IsValidEntity(ClientVM[client][1]))
				{		
					decl String:classnamel[150];
					GetEdictClassname(ClientVM[client][1], classnamel, sizeof(classnamel));
					if(StrContains(classnamel, "env_", false) == -1)
					{
						SetEntProp(ClientVM[client][1], Prop_Send, "m_nSkin", weapon_info[wepnum][index_sk][Index]);  
					}
				}
			}
		}
		
		return;
	}
	
	if (ClientVM[client][0] == 0)
	{
		return;
	}
	WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new Sequence = 5000;
	if (IsValidEntity(ClientVM[client][0])) {  Sequence = GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"); }
	if(Sequence == 5000)	RegiveWeapon(client, WeaponIndex);
	new Float:Cycle = GetEntPropFloat(ClientVM[client][0], Prop_Data, "m_flCycle");
	
	if (IsValidEntity(ClientVM[client][0]))
	{
		
		if (WeaponIndex <= 0)
		{
			new EntEffects;
			if(IsValidEntity(ClientVM[client][1])) EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
			
			IsCustom[client] = false;
				
			OldWeapon[client] = WeaponIndex;
			OldSequence[client] = Sequence;
			OldCycle[client] = Cycle;
			
			return;
		}
	}
	//just stuck the weapon switching in here aswell instead of a separate hook
	if (WeaponIndex != OldWeapon[client])
	{
		GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
		new wepnumz = WeaponNameToNum(ClassName);
		//
		if(wepnumz == 30 && (GetFeatureStatus(FeatureType_Native, "ZR_IsClientZombie") == FeatureStatus_Available) && (ZR_IsClientZombie(client)))
		{
			wepnumz = 29;
		}
		//
		new indx_t = client_wepskin_index[client][wepnumz];
		if (client_wepskin_index[client][wepnumz] < 64 && (weapon_info[wepnumz][indx_t][VModel][0] != EOS) && ViewModelsEnabled[client] && (weapon_info[wepnumz][indx_t][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[wepnumz][indx_t][Flag])) && IsValidEntity(ClientVM[client][0]))
		{
			new EntEffects;
			if (IsValidEntity(ClientVM[client][0])) EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
			//unhide unused viewmodel
			if (IsValidEntity(ClientVM[client][1])) EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
			EntEffects &= ~EF_NODRAW;
			SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
			
			//set model and copy over props from viewmodel to used viewmodel
			/*
			if(wepnumz == 30 && (GetFeatureStatus(FeatureType_Native, "ZR_IsClientZombie") == FeatureStatus_Available) && ViewModelsEnabled[client])
				{
					if (ZR_IsClientZombie(client))
					{
						SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[29][indx_t][PVModel]);
					}
					else
					{
						SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[wepnumz][indx_t][PVModel]);
					}
				}
			else */
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapon_info[wepnumz][indx_t][PVModel]);
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nSkin", weapon_info[wepnumz][indx_t][Index]);  
			SetEntPropEnt(ClientVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(ClientVM[client][0], Prop_Send, "m_hWeapon"));
			
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
			SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
			
			IsCustom[client] = true;
			
		} 
		else if (HasAnyCustomWeaponsEquiped(client))
		{
			new EntEffects;
			if (IsValidEntity(ClientVM[client][0])) EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
			//unhide unused viewmodel
			if (IsValidEntity(ClientVM[client][1])) EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
			EntEffects &= ~EF_NODRAW;
			SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
			wepnumz--;
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", weapondefaultpc[wepnumz]);
			SetEntPropEnt(ClientVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(ClientVM[client][0], Prop_Send, "m_hWeapon"));
			
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
			SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
			IsCustom[client] = true;
		}
		else
		{
			//hide unused viewmodel if the current weapon isn't using it
			new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
			
			IsCustom[client] = false;
		}
	}
	else
	{
		static Data[MAXPLAYERS+1];
		if (IsCustom[client] && IsValidEntity(ClientVM[client][1]))
		{
			//copy the animation stuff from the viewmodel to the used one every frame
			SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
			SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
			
			if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
			{
				if(GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, 2)) Data[client] = 5;
				SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", 0);
			}
			else if(Sequence == OldSequence[client])
			{
				if(Data[client] > 0)
				{
					Data[client] -= 1;
					SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", 0);
				}
				else if(Data[client]) Data[client] = 0;
			}
			else if(Data[client]) Data[client] = 0;
		}
	}
	//hide viewmodel a frame after spawning
	if (SpawnCheck[client])
	{
		SpawnCheck[client] = false;
		if (IsCustom[client])
		{
			new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
		}
	}
	
	OldWeapon[client] = WeaponIndex;
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}

//
#define SPECMODE_FIRSTPERSON 		4
//hide viewmodel on death

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if(!IsPlayerAlive(victim))
	{
		Client_Death(victim);
	}
}

public Client_Death(client)
{
	new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
	EntEffects |= EF_NODRAW;
	SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsPlayerAlive(i) || IsClientObserver(i))
			{
				new iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				new iSpecMode;
				iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if(client == iTarget && iSpecMode == SPECMODE_FIRSTPERSON)
				{
					new EntEffects2 = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
					EntEffects2 |= EF_NODRAW;
					SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects2);
				}
			}
		}
	}
	new String:cvarivalued[3];
	GetConVarString(g_WModelsEnabled, cvarivalued , sizeof(cvarivalued))
	//new cvarivalued2 = StringToInt(cvarivalued);
	//if(cvarivalued2 == 1)	CreateTimer(0.01, ChangeDroppedModel, client);
}
			
//when a player repsawns at round start after surviving previous round the viewmodel is unhidden
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	//use to delay hiding viewmodel a frame or it won't work
	SpawnCheck[client] = true;
	//CreateTimer(0.01, SpawnHelper, client);
}

public Action:SpawnHelper(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) > 1) && IsPlayerAlive(client))
	{
		new wep_index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(wep_index > 0 && IsValidEdict(wep_index)) RegiveWeapon(client, wep_index);
	}
}

public WeaponEquip_CallBackPosto(client, weapon)
{
	weapon_owner[weapon] = client;
}

public Action:ChangeDroppedModel(Handle:Timer, any:client)
{
	new x = 0;
	while(x < 2048)
	{
		if(IsValidEntity(x) && weapon_owner[x] == client)
		{
			new String:sz_Classname[32];
			GetEdictClassname(x, sz_Classname, sizeof(sz_Classname));
			new intweapon = WeaponNameToNum(sz_Classname);
			new wepindex_c = client_wepskin_index[client][intweapon];
			if( client_wepskin_index[client][intweapon] < 64 && (weapon_info[intweapon][wepindex_c][WModel][0] != EOS) && WorldModelsEnabled[client] && (weapon_info[intweapon][wepindex_c][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[intweapon][wepindex_c][Flag])))
			{
				//SetEntProp(x, Prop_Send, "m_iWorldModelIndex", weapon_info[intweapon][wepindex_c][PWModel]);
				//SetEntityRenderColor(x, 255, 255, 255, 255);
				//SetEntityRenderMode(x, RenderMode:0);
				SetEntityModel(x, weapon_info[intweapon][wepindex_c][WModel]);
				SetEntityRenderColor(x, 255, 255, 255, 255);
			}
		}
		x++;
	}
}
/////////////////////////////////////////////////////////////////////////////////////

public Action:Command_Drop(client, const String:command[], argc)
{
	new Handle:datapack = CreateDataPack();
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	WritePackCell(datapack, weapon);
	WritePackCell(datapack, client);
	
	decl String:method[10];
	GetConVarString(g_AccessMethod, method, sizeof(method));
	if (StrEqual(method, "flag", true))
	{
		decl chat_flag;
		decl String:flag[2];
		GetConVarString(g_AccessFlag, flag, sizeof(flag))
		chat_flag = ReadFlagString(flag);
		if(!(GetUserFlagBits(client) & chat_flag))		return Plugin_Continue;
	}
	else if (StrEqual(method, "group", true))
	{
		decl String:group[16];
		GetConVarString(g_AccessGroup, group, sizeof(group))
		if(!Client_IsInAdminGroup(client, group, false)) return Plugin_Continue;
			
	}
	
	CreateTimer(0.001, DroppedWeapon, datapack);
	return Plugin_Continue;
}

public Action:DroppedWeapon(Handle:timer, any:data)
{
	ResetPack(data);
	new weaponc = ReadPackCell(data);
	new clientd = ReadPackCell(data);
	CloseHandle(data);
	decl String:cvarvaluez[3];
	GetConVarString(g_WModelsEnabled, cvarvaluez , sizeof(cvarvaluez))
	new cvarivalued = StringToInt(cvarvaluez);
	if (cvarivalued == 0)		return Plugin_Stop;
	if (!(clientd <= 0 || clientd > MaxClients))
	{
		new String:sz_Classname[32];
		if(!IsValidEdict(weaponc))	return Plugin_Stop;
		GetEdictClassname(weaponc, sz_Classname, sizeof(sz_Classname));
		new intweapon = WeaponNameToNum(sz_Classname);
		new wepindex_c = client_wepskin_index[clientd][intweapon];
		if( client_wepskin_index[clientd][intweapon] < 64 && (weapon_info[intweapon][wepindex_c][WModel][0] != EOS) && WorldModelsEnabled[clientd] && (weapon_info[intweapon][wepindex_c][Flag][0] == EOS || GetUserFlagBits(clientd) & ReadFlagString(weapon_info[intweapon][wepindex_c][Flag])))
		{
			//CS_DropWeapon(client, weapon, true, true);
			SetEntProp(weaponc, Prop_Send, "m_iWorldModelIndex", weapon_info[intweapon][wepindex_c][PWModel]);
			SetEntityRenderColor(weaponc, 255, 255, 255, 255);
			SetEntityRenderMode(weaponc, RenderMode:0);
		}
	}
	return Plugin_Continue;
}
//////////////////////////////////////////////////////////////////////////
/*
public Action:OnPlayerRunCmd(client, &iButtons, &Impulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	new iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEdict(iActiveWeapon))	return;
	decl String:cvarvalue[3];
	GetConVarString(g_EnableDropModels, cvarvalue , sizeof(cvarvalue))
	new cvarivalue = StringToInt(cvarvalue);
	if (cvarivalue == 0)		return;
	decl String:method[10];
	GetConVarString(g_AccessMethod, method, sizeof(method));
	if (StrEqual(method, "flag", true))
	{
		decl chat_flag;
		decl String:flag[2];
		GetConVarString(g_AccessFlag, flag, sizeof(flag))
		chat_flag = ReadFlagString(flag);
		if(!(GetUserFlagBits(client) & chat_flag))		return;
	}
	else if (StrEqual(method, "group", true))
	{
		decl String:group[16];
		GetConVarString(g_AccessGroup, group, sizeof(group))
		if(!Client_IsInAdminGroup(client, group, false)) return;
			
	}
	decl String:sWeapon[64];
	GetEdictClassname(iActiveWeapon, sWeapon, sizeof(sWeapon));
	new intweaponz = WeaponNameToNum(sWeapon);
	new wepindex_d = client_wepskin_index[client][intweaponz];
	if ((weapon_info[intweaponz][wepindex_d][WModel][0] != EOS) && iActiveWeapon != -1 && WorldModelsEnabled[client] && (weapon_info[intweaponz][wepindex_d][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[intweaponz][wepindex_d][Flag])))
	{
		SetEntProp(iActiveWeapon, Prop_Send, "m_iWorldModelIndex", weapon_info[intweaponz][wepindex_d][PWModel]);
		//SDKHook
	}
} 
*/

public WeaponSwitchPost(client, iActiveWeapon)
{
	if (!IsClientConnected(client))
	{
	return;
	}

	if (!IsValidEdict(iActiveWeapon))	return;
	decl String:cvarvalue[3];
	GetConVarString(g_EnableDropModels, cvarvalue , sizeof(cvarvalue))
	new cvarivalue = StringToInt(cvarvalue);
	if (cvarivalue == 0)		return;
	decl String:method[10];
	GetConVarString(g_AccessMethod, method, sizeof(method));
	if (StrEqual(method, "flag", true))
	{
		decl chat_flag;
		decl String:flag[2];
		GetConVarString(g_AccessFlag, flag, sizeof(flag))
		chat_flag = ReadFlagString(flag);
		if(!(GetUserFlagBits(client) & chat_flag))		return;
	}
	else if (StrEqual(method, "group", true))
	{
		decl String:group[16];
		GetConVarString(g_AccessGroup, group, sizeof(group))
		if(!Client_IsInAdminGroup(client, group, false)) return;
			
	}
	decl String:sWeapon[64];
	GetEdictClassname(iActiveWeapon, sWeapon, sizeof(sWeapon));
	new intweaponz = WeaponNameToNum(sWeapon);
	new wepindex_d = client_wepskin_index[client][intweaponz];
	if ((weapon_info[intweaponz][wepindex_d][WModel][0] != EOS) && iActiveWeapon != -1 && WorldModelsEnabled[client] && (weapon_info[intweaponz][wepindex_d][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[intweaponz][wepindex_d][Flag])))
	{
		//PrintToChat(client, "swaped weapon u did");
		SetEntProp(iActiveWeapon, Prop_Send, "m_iWorldModelIndex", weapon_info[intweaponz][wepindex_d][PWModel]);
	}
}

Tellm(client)
{
		new String:steamid[32];
		GetClientAuthString(client, steamid, sizeof(steamid))
		new String:GoGoFetch[100];
		Format(GoGoFetch, sizeof(GoGoFetch), "SELECT viewm,worldm FROM `wmodels` WHERE SteamID = '%s'", steamid);
		SQL_TQuery(h_DB, LoadDefinitions, GoGoFetch, client);
		/*
		new Handle: handlegogofetch = SQL_Query(h_DB_noT, GoGoFetch);
		if(SQL_FetchRow(handlegogofetch))
		{
			new String:VM1[4];
			SQL_FetchString(handlegogofetch, 0, VM1 , sizeof(VM1));
			if (StringToInt(VM1) == 1)	ViewModelsEnabled[client] = true;
			else if (StringToInt(VM1) == 0) ViewModelsEnabled[client] = false;
			new String:WM1[4];
			SQL_FetchString(handlegogofetch, 1, WM1 , sizeof(WM1));
			if (StringToInt(WM1) == 1) WorldModelsEnabled[client] = true;
			else if (StringToInt(WM1) == 0) WorldModelsEnabled[client] = false;
		}
		CloseHandle(handlegogofetch);
		*/
}


public LoadDefinitions(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Query Error: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change. Error 03");
	}
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		new String:VM1[4];
		SQL_FetchString(hndl, 0, VM1 , sizeof(VM1));
		if (StringToInt(VM1) == 1)	ViewModelsEnabled[client] = true;
		else if (StringToInt(VM1) == 0) ViewModelsEnabled[client] = false;
		new String:WM1[4];
		SQL_FetchString(hndl, 1, WM1 , sizeof(WM1));
		if (StringToInt(WM1) == 1) WorldModelsEnabled[client] = true;
		else if (StringToInt(WM1) == 0) WorldModelsEnabled[client] = false;
	}
}

//////////////////////////////////////////////////////////////////////////

public Event_C4Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, C4Planted, client);
}

public Action:C4Planted(Handle:timer, any:client)
{
	decl String:cvarvaluez[3];
	GetConVarString(g_WModelsEnabled, cvarvaluez , sizeof(cvarvaluez))
	new cvarivalued = StringToInt(cvarvaluez);
	if (cvarivalued == 0)		return;
	if (client > 0 && client <= MaxClients)
	{
		new wepindex_c = client_wepskin_index[client][4];
		if( client_wepskin_index[client][4] < 64 && (weapon_info[4][wepindex_c][WModel][0] != EOS) && WorldModelsEnabled[client] && (weapon_info[4][wepindex_c][Flag][0] == EOS || GetUserFlagBits(client) & ReadFlagString(weapon_info[4][wepindex_c][Flag])))
		{
			new c4 = -1;
			while ((c4 = FindEntityByClassname(c4, "planted_c4")) != INVALID_ENT_REFERENCE) 
			{
				SetEntityModel(c4, weapon_info[4][wepindex_c][WModel]);
				SetEntityRenderColor(c4, 255, 255, 255, 255);
				
				new Float:vec[3];
				GetEntPropVector(c4, Prop_Send, "m_vecOrigin", vec);
				vec[2] += 10.0;
				SetEntPropVector(c4, Prop_Send, "m_vecOrigin", vec);
				
				SetEntPropFloat(c4, Prop_Data, "m_flModelScale", 1.5);
			}
		}
	}
}
//////////////////////////////////////////

stock RegiveWeapon(client, weapon)
{
	if(IsValidEdict(weapon))
		{
		new String:szz_Classname[32];
		GetEdictClassname(weapon, szz_Classname, sizeof(szz_Classname));
		//new equipweapon = GetPlayerWeaponSlot(client, 0) 
		//EquipPlayerWeapon(client, equipweapon) 
		if (StrContains(szz_Classname, "knife", false) != -1)
		{
			RemovePlayerItem(client, weapon);
			GivePlayerItem(client, "weapon_knife");
			return;
		}
		new m_iPrimaryAmmoType		= GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); // Ammo type
		new m_iClip1 = -1;
		new m_iAmmo_prim	 = -1;
		if(m_iPrimaryAmmoType != -1)
		m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
		m_iAmmo_prim = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
		RemovePlayerItem(client, weapon);
		if (IsValidEdict(weapon)) AcceptEntityInput(weapon, "Kill");
		new weapon2 = GivePlayerItem(client, szz_Classname);
		SetEntProp(weapon2, Prop_Send, "m_iClip1", m_iClip1); // Set weapon clip ammunition
		SetEntProp(client, Prop_Send, "m_iAmmo", m_iAmmo_prim, _, m_iPrimaryAmmoType); // Set player ammunition of this weapon primary ammo type
	}
}

//////////////////////////////////

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	//ReloadUserSkinsNUM()
	new x = 0;
	while(x < 2048)
	{
		weapon_owner[x] = 0;
		x++;
	}
}
stock ReloadUserSkinsNUM()
{
	for(new i = 1; i < CSS_WEAPON_NUMBER; i++)
		for(new x = 0; x < MAX_SKINS_PER_WEAPON; x++)
			GetUsersOfSkin(i, x)
}

stock GetUsersOfSkin(weapon_index, skin_index)
{
	new String:QueryString[100];
	Format(QueryString, sizeof(QueryString), "SELECT SteamID FROM `wmodels` WHERE `%i` = '%i'", weapon_index, skin_index);
	//new Handle:ASDF = SQL_Query(DB, QueryString);
	new Handle:data = CreateDataPack();
	WritePackCell(data, weapon_index);
	WritePackCell(data, skin_index);
	SQL_TQuery(h_DB, SQL_ThreadedCallback, QueryString, data);
	//weapon_info[weapon_index][skin_index][NumUsers] = SQL_GetRowCount(ASDF);
	//CloseHandle(ASDF);
}

public SQL_ThreadedCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		PrintToServer("Error connecting to database: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change. Error 04");
	}
	ResetPack(data);
	new weapon_index = ReadPackCell(data);
	new skin_index = ReadPackCell(data);
	CloseHandle(data);
	weapon_info[weapon_index][skin_index][NumUsers] = SQL_GetRowCount(hndl);
}

/////////////////////////////

/*
public Action:OnTakeDamage_CallBack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new hp = GetEntProp(victim, Prop_Send, "m_iHealth");
	new damage_int = RoundToNearest(damage);
	if ( hp - damage_int <= 0 )
	{
		new weapon_victim = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if (weapon_victim > 0 )
		{
			RemovePlayerItem(victim, weapon_victim);
		}
	}
	
	return Plugin_Continue;
}
*/


public SQL_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query errors: %s", error);
		SetFailState("Lost connection to database. Reconnecting on map change. Error 05");
	}
}


///////////////////////////////////

stock EquipPublicSkins(client)
{
	new number_of_skins;
	for(new i; i < sizeof(ListOfEntityWeaponsToUse); i++)
	{
		if(ListOfEntityWeaponsToUse[i][0] != EOS)
		{
			new int_weapon = WeaponNameToNum(ListOfEntityWeaponsToUse[i]);
			if(EquipPublicSkinIfAvailable(client, int_weapon))	number_of_skins++;
		}
	}
	return number_of_skins;
}

stock bool:EquipPublicSkinIfAvailable(client, int_weapon)
{
	new m = 0;
	new num_public_skin = 0;
	new bool:BoolPublic[MAX_SKINS_PER_WEAPON] = false;
	
	while(m < MAX_SKINS_PER_WEAPON)
	{
		if (weapon_info[int_weapon][m][Flag][0] == EOS && weapon_info[int_weapon][m][Name][0] != EOS)
		{
			num_public_skin++;
			BoolPublic[m] = true;
		}
		m++;
	}
	if (num_public_skin == 0)	return	false;
	
	new random_int = GetRandomInt(1, num_public_skin);
	m = 0;
	new p = 0;
	
	while(m < MAX_SKINS_PER_WEAPON)
	{
		if (weapon_info[int_weapon][m][Flag][0] == EOS && weapon_info[int_weapon][m][Name][0] != EOS)
		{
			p++;
			if (p == random_int)
			{
				client_wepskin_index[client][int_weapon] = m;
				break;
			}
		}
		m++;
	}
	
	decl String:query_mysql[255], String:steamid[30];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(query_mysql, sizeof(query_mysql), "UPDATE `wmodels` SET `%i` = '%i' WHERE `SteamID` = '%s'", int_weapon, client_wepskin_index[client][int_weapon], steamid);
	//SQL_FastQuery(h_DB_noT, query_mysql);
	SQL_TQuery(h_DB, SQL_DoNothing, query_mysql);
	return true;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	PrintToChat(client, "infetado");
	CreateTimer(0.01, ReviewViewModel, client);
}

public Action:ReviewViewModel(Handle:timer, any:client)
{
	if(client > 0 && client <= MaxClients)
	{
		//ReviewVM[client] = true;
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != 0)	RegiveWeapon(client, weapon);
	}
}


// Code taken from AKC

public OnPostThink(id)
{
	new buttons = GetClientButtons(id);
	if(buttons & IN_ATTACK)
	{
		new WeaponIndex = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
		if(WeaponIndex <= 0) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(id, Prop_Send, "m_flNextAttack")) return;
		Process[id] = 0;
	}
	if(buttons & IN_ATTACK2)
	{
		new WeaponIndex = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
		if(WeaponIndex <= 0) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(id, Prop_Send, "m_flNextAttack")) return;
		Process[id] = 0;
	}
}

get_menu_position_for_client(client, int_weapon, position)
{
	new m = 0;
	new num_public_skin = 0;
	
	while(m < MAX_SKINS_PER_WEAPON && m < position)
	{
		if ((weapon_info[int_weapon][m][Flag][0] == EOS || weapon_info[int_weapon][m][Flag] & GetUserFlagBits(client)) && weapon_info[int_weapon][m][Name][0] != EOS)
		{
			num_public_skin++;
		}
		m++;
	}
	num_public_skin++;
	return num_public_skin;
}

//

#define WEAPONS_SLOTS_MAX 5

enum WeaponsSlot
{
    Slot_Invalid        = -1,   /** Invalid weapon (slot). */
    Slot_Primary        = 0,    /** Primary weapon slot. */
    Slot_Secondary      = 1,    /** Secondary weapon slot. */
    Slot_Melee          = 2,    /** Melee (knife) weapon slot. */
    Slot_Projectile     = 3,    /** Projectile (grenades, flashbangs, etc) weapon slot. */
    Slot_Explosive      = 4,    /** Explosive (c4) weapon slot. */
}

stock bool:HasAnyCustomWeaponsEquiped(client)
{
	new weapons_array[WeaponsSlot];
	WeaponsGetClientWeapons(client, weapons_array);
	for (new x = 0; x < WEAPONS_SLOTS_MAX; x++)
	{
		// If slot is empty, then stop.
		if (weapons_array[x] == -1)
		{
			continue;
		}
		new String:classname[50];
		GetEdictClassname(weapons_array[x], classname, sizeof(classname))
		new weapon_num = WeaponNameToNum(classname);
		new index = client_wepskin_index[client][weapon_num];
		if(index < 64)
		{
			return true;
		}
	}
	return false;
}

// ZombieReloaded stock
stock WeaponsGetClientWeapons(client, weapons[WeaponsSlot])
{
	// x = Weapon slot.
	for (new x = 0; x < WEAPONS_SLOTS_MAX; x++)
	{
		weapons[x] = GetPlayerWeaponSlot(client, x);
	}
}