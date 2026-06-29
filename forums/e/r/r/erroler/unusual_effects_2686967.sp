#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <smlib>
new Handle:DB;
new Handle:Trie;

#define MAX_STEAMID_LENGTH 21
#define MAX_COMMUNITYID_LENGTH 18 
#define FirstSecondsAbleToChange 10
#define EOS '\0'
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6
#define PARTICLE_DISPATCH_FROM_ENTITY		(1<<0)

new bool:IsnOnTP[MAXPLAYERS+1];
new String:EffectIDChoosen[MAXPLAYERS+1][2][64];
new String:EffectIDs[128][2][64];
new String:EffectNames[128][2][64];
new Float:EffectPos[128][2][3];
new Float:EffectAngle[128][2][3];

new Handle:sv_allow_thirdperson = INVALID_HANDLE;
new Handle:Cvar_Method = INVALID_HANDLE;
new Handle:Cvar_Flag = INVALID_HANDLE;
new Handle:Cvar_AllowTP = INVALID_HANDLE;

new Index_Hat[MAXPLAYERS+1];
new Index_Feet_Particle[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Unusual Effects",
	author = "Erroler",
	description = "",
	version = "0.2",
	url = "https://github.com/Erroler"
};

public OnPluginStart()
{
	Trie = CreateTrie();
	RegConsoleCmd("sm_unusual", UnusualMainMenu_CMD);
	RegConsoleCmd("sm_unusuals", UnusualMainMenu_CMD);
	RegConsoleCmd("sm_ue", UnusualMainMenu_CMD);
	RegConsoleCmd("sm_unusualeffects", UnusualMainMenu_CMD);
	//
	decl String:error[255];
	DB = SQL_Connect("unusual", true, error, sizeof(error));
	if (DB == INVALID_HANDLE)	SetFailState("%s",  error);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	//
	CreateTimer(6.0, RemakeFeetParticles, _, TIMER_REPEAT);
	
	sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
	if(sv_allow_thirdperson == INVALID_HANDLE)
		SetFailState("sv_allow_thirdperson not found!");
	Cvar_Method = CreateConVar("sm_ue_method", "normal", "This plugin has two alternative ways of putting the effects on the players: normal (more stable, can't hide head effects in first person), experimental (buggy, sometimes doesn't work but hides head effects in first person).");
	Cvar_Flag = CreateConVar("sm_ue_flag", "o", "Restrict usage of the plugin to players with the given sourcemod flag. If left empty everyone can access it.");
	Cvar_AllowTP = CreateConVar("sm_ue_allow_thirdperson", "1", "Allow the usage of third person on the menu.");
	AutoExecConfig(true, "unusual_effects")
}

public Action:RemakeFeetParticles(Handle:timer)
{
	for(new i = 1; i  <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && Index_Feet_Particle[i] > 0 && IsValidEdict(Index_Feet_Particle[i]))
		{
			EquipClient_Feet(i);
		}
	}
}

///////////////////////////

public OnClientAuthorized(client)
{
	//Reset Stuff
	EffectIDChoosen[client][0][0] = EOS;
	EffectIDChoosen[client][1][0] = EOS;
	Index_Hat[client] = 0;
	Index_Feet_Particle[client] = 0;
	IsnOnTP[client] = false;
	//
	new String:Steamid64[MAX_COMMUNITYID_LENGTH];
	if(GetClientAuthId(client, AuthId_SteamID64, Steamid64, sizeof(Steamid64)))
	{
		decl String:qwery[300];
		FormatEx(qwery, sizeof(qwery), "SELECT * FROM `unusual_table` WHERE `steamid64` = '%s'", Steamid64);
		new Handle:h_query = SQL_Query(DB, qwery);
		if(SQL_HasResultSet(h_query) && SQL_GetRowCount(h_query) > 0 && SQL_FetchRow(h_query))
		{
			new String:temp[64];
			SQL_FetchString(h_query, 1, EffectIDChoosen[client][0], 64);
			if(!GetTrieString(Trie, EffectIDChoosen[client][0], temp, sizeof(temp)))
			{
				EffectIDChoosen[client][0][0] = EOS;
			}
			SQL_FetchString(h_query, 2, EffectIDChoosen[client][1], 64);
			if(!GetTrieString(Trie, EffectIDChoosen[client][1], temp, sizeof(temp)))
			{
				EffectIDChoosen[client][1][0] = EOS;
			}
		}
		else
		{
			decl String:query[256];
			FormatEx(query, sizeof(query), "INSERT INTO `unusual_table` (`steamid64`) VALUES ('%s')", Steamid64);
			SQL_FastQuery(DB, query);
		}
	}
}


public OnClientPutInServer(client)
{
	for(new i = 1; i  <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && Index_Hat[i] > 0 && EffectIDChoosen[i][0][0] != EOS)
		{
			new g_StringTable = FindStringTable("ParticleEffectNames");
			new index_particle = FindStringIndex(g_StringTable, EffectIDChoosen[i][0]);
			new Float:angles[3]; 
			new Float:position[3];
			GetEntPropVector(Index_Hat[i], Prop_Send, "m_vecOrigin", position);
			DispatchParticleEffectToClient(index_particle, position, angles, Index_Hat[i], 0.0, client, 0);
		}
	}
}

public OnClientDisconnect(client)
{
	DestroyHat(Index_Hat[client]);
}


public OnMapStart()
{
	PrecacheModel("models/player/t_animations.mdl");
	AddToDT_And_PC();
	ClearTrie(Trie);
	//
	BuildMenu_HeadEffects();
	BuildMenu_FeetEffects();
	if(DB != INVALID_HANDLE) SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS `unusual_table` (  `steamid64` varchar(48) NOT NULL UNIQUE,  `id_name_head` varchar(128) NOT NULL DEFAULT '',  `id_name_feet` varchar(128) NOT NULL DEFAULT '',  CONSTRAINT UC_STEAMID UNIQUE (steamid64))");

}

BuildMenu_HeadEffects()
{
	new Handle:kv = CreateKeyValues("SpecialEffects");
	decl String:File_H[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, File_H, sizeof(File_H), "configs/ue/unusuals_list_head.ini");
	FileToKeyValues(kv, File_H);
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	new String:Effect_Name[64];
	new String:Effect_ID[64];
	new String:temp[64];
	new x = 0;
	do
	{
		KvGetSectionName(kv, Effect_Name, sizeof(Effect_Name));
		KvGetString(kv, "particle_name", Effect_ID, 64);
		FormatEx(temp, sizeof(temp), "%i", x);
		SetTrieString(Trie, Effect_ID, temp, true);
		//
		strcopy(EffectIDs[x][0], 64, Effect_ID);
		PrecacheParticleSystem(Effect_ID);
		strcopy(EffectNames[x][0], 64, Effect_Name);
		//
		KvGetString(kv, "pos", temp, 64, "0.0 0.0 0.0");
		new String:temp_2[3][6];
		ExplodeString(temp, "_", temp_2, sizeof(temp_2), sizeof(temp_2[]));
		EffectPos[x][0][0] = StringToFloat(temp_2[0]);
		EffectPos[x][0][1] = StringToFloat(temp_2[1]);
		EffectPos[x][0][2] = StringToFloat(temp_2[2]);
		//
		KvGetString(kv, "angles", temp, 64, "0.0 0.0 0.0");
		ExplodeString(temp, " ", temp_2, sizeof(temp_2), sizeof(temp_2[]));
		EffectAngle[x][0][0] = StringToFloat(temp_2[0]);
		EffectAngle[x][0][1] = StringToFloat(temp_2[1]);
		EffectAngle[x][0][2] = StringToFloat(temp_2[2]);
		x++
	}
	while (KvGotoNextKey(kv));
	CloseHandle(kv);
}

BuildMenu_FeetEffects()
{
	new Handle:kv = CreateKeyValues("SpecialEffects");
	decl String:File_F[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, File_F, sizeof(File_F), "configs/ue/unusuals_list_feet.ini");
	FileToKeyValues(kv, File_F);
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	new String:Effect_Name[64];
	new String:Effect_ID[64];
	new String:temp[64];
	new x = 0;
	do
	{
		KvGetSectionName(kv, Effect_Name, sizeof(Effect_Name));
		KvGetString(kv, "particle_name", Effect_ID, 64);
		FormatEx(temp, sizeof(temp), "%i", x);
		SetTrieString(Trie, Effect_ID, temp, true);
		//
		strcopy(EffectIDs[x][1], 64, Effect_ID);
		PrecacheParticleSystem(Effect_ID);
		strcopy(EffectNames[x][1], 64, Effect_Name);
		//
		KvGetString(kv, "pos", temp, 64, "0.0 0.0 0.0");
		new String:temp_2[3][6];
		ExplodeString(temp, " ", temp_2, sizeof(temp_2), sizeof(temp_2[]));
		EffectPos[x][1][0] = StringToFloat(temp_2[0]);
		EffectPos[x][1][1] = StringToFloat(temp_2[1]);
		EffectPos[x][1][2] = StringToFloat(temp_2[2]);
		//
		KvGetString(kv, "angles", temp, 64, "0.0 0.0 0.0");
		ExplodeString(temp, " ", temp_2, sizeof(temp_2), sizeof(temp_2[]));
		EffectAngle[x][1][0] = StringToFloat(temp_2[0]);
		EffectAngle[x][1][1] = StringToFloat(temp_2[1]);
		EffectAngle[x][1][2] = StringToFloat(temp_2[2]);
		x++
	}
	while (KvGotoNextKey(kv));
	CloseHandle(kv);
}

//Download Tables and Precaching

AddToDT_And_PC()
{
	decl String:path[128];
	BuildPath(Path_SM, path, 128, "configs/ue/downloads.ini");
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
				if(FileExists(line))
				{
					AddFileToDownloadsTable(line);
					new String:FileZilo[PLATFORM_MAX_PATH];
					strcopy(FileZilo, sizeof(FileZilo), line);
					FileZilo[strlen(FileZilo) - 2] = 't';
					FileZilo[strlen(FileZilo) - 1] = 'f';
					if(FileExists(FileZilo))	AddFileToDownloadsTable(FileZilo);
					if(StrContains(line, ".pcf", true) != -1) 
					{	
						PrecacheGeneric(line, true) ;	
					}
				}
				else
				{
					LogMessage("%s File doesn't exist", line);
				}
			}
		}
	}
	CloseHandle(file);
}

// MainMenu

public Action:UnusualMainMenu_CMD(client,args)
{
	if(!IsClientConnected(client))	return Plugin_Handled;
	new String:flag[10];
	GetConVarString(Cvar_Flag, flag, sizeof(flag));
	if (!(GetUserFlagBits(client) & ReadFlagString(flag)) && !StrEqual(flag, ""))
	{
		CPrintToChat(client, "{DARKRED}[Unusual Effects]{YELLOW} You don't have permissions to access this command.");
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(MenuHandlerMainMenu, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Unusual Effects \n");
	//
	new String:Equipped[64];
	if(EffectIDChoosen[client][0][0] != EOS)
	{
		new String:temp[64];
		GetTrieString(Trie, EffectIDChoosen[client][0], temp, sizeof(temp));
		strcopy(Equipped, sizeof(Equipped), EffectNames[StringToInt(temp)][0]);
	}
	else
	{
		strcopy(Equipped, sizeof(Equipped), "-");
	}
	decl String:ToFormat[128];
	Format(ToFormat, sizeof(ToFormat), "Change head unusual effects\nCurrent effect: %s", Equipped);
	AddMenuItem(menu, "ee_head", ToFormat);
	//
	if(EffectIDChoosen[client][1][0] != EOS)
	{
		new String:temp[64];
		GetTrieString(Trie, EffectIDChoosen[client][1], temp, sizeof(temp));
		strcopy(Equipped, sizeof(Equipped), EffectNames[StringToInt(temp)][1]);
	}
	else
	{
		strcopy(Equipped, sizeof(Equipped), "-");
	}
	Format(ToFormat, sizeof(ToFormat), "Change feet unusual effects\nCurrent effect: %s", Equipped);
	AddMenuItem(menu, "ee_feet", ToFormat);
	//
	if(GetConVarBool(Cvar_AllowTP)) {
		if(IsnOnTP[client])	AddMenuItem(menu, "ee_fp", "Go back to first person");
		else 	AddMenuItem(menu, "ee_tp", "See effects in third person", ITEMDRAW_DISABLED);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}


public MenuHandlerMainMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:temp[32];
			GetMenuItem(menu, param2, temp, sizeof(temp));
			if(StrEqual(temp, "ee_head", true))
			{
				Head_Effects_Menu(param1);
			}
			else if(StrEqual(temp, "ee_feet", true))
			{
				Feet_Effects_Menu(param1);
			}
			else if(StrEqual(temp, "ee_fp", true))
			{
				ClientCommand(param1, "firstperson");
				IsnOnTP[param1] = false;
				UnusualMainMenu_CMD(param1, 0);
			}
			else if(StrEqual(temp, "ee_tp", true))
			{
				SendConVarValue(param1, sv_allow_thirdperson, "1")
				ClientCommand(param1, "thirdperson");
				IsnOnTP[param1] = true;
				UnusualMainMenu_CMD(param1, 0);
			}
		}
		case MenuAction_Cancel: 
		{
		
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_DrawItem:
		{
			new style;
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info), style);
		}
		case MenuAction_DisplayItem:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
		}
	}
	return 0;
}

//
Head_Effects_Menu(client)
{
	new Handle:menu = CreateMenu(MenuHandler1, MENU_ACTIONS_ALL);
	new String:Equipped[64];
	if(EffectIDChoosen[client][0][0] != EOS)
	{
		new String:temp[64];
		GetTrieString(Trie, EffectIDChoosen[client][0], temp, sizeof(temp));
		strcopy(Equipped, sizeof(Equipped), EffectNames[StringToInt(temp)][0]);
	}
	else
	{
		strcopy(Equipped, sizeof(Equipped), "-");
	}
	SetMenuTitle(menu, "Head unusual effects\nCurrent: %s\n", Equipped);
	if(StrEqual("",EffectIDChoosen[client][0], true))
	{
		AddMenuItem(menu, "", "[E] None");
	}
	else
	{
		AddMenuItem(menu, "", "None");
	}
	new count = 0;
	while(EffectIDs[count][0][0] != EOS && count < 400)
	{
		if(StrEqual(EffectIDs[count][0],EffectIDChoosen[client][0], true))
		{
			decl String:temp[256];
			FormatEx(temp, sizeof(temp), "[E] %s",  EffectNames[count][0]);
			AddMenuItem(menu, EffectIDs[count][0], temp);
		}
		else
		{
			AddMenuItem(menu, EffectIDs[count][0], EffectNames[count][0]);
		}
		count++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:effectid_select[64];
			GetMenuItem(menu, param2, effectid_select, sizeof(effectid_select));
			//
			new String:Steamid64[MAX_COMMUNITYID_LENGTH];
			if(GetClientAuthId(param1, AuthId_SteamID64, Steamid64, sizeof(Steamid64)))			{
				decl String:query[256];
				FormatEx(query, sizeof(query), "UPDATE `unusual_table` SET  `id_name_head` =  '%s' WHERE  `steamid64` =  '%s';", effectid_select, Steamid64);
				SQL_FastQuery(DB, query);
			}
			new bool:is_same = strcmp(EffectIDChoosen[param1][0], effectid_select, false) == 0;
			strcopy(EffectIDChoosen[param1][0], 64, effectid_select);
			if(StrEqual(effectid_select, "", true))
			{
				Head_Effects_Menu(param1);
				CPrintToChat(param1, "{DARKRED}[Unusual Effects]{YELLOW} You are no longer using a head {GREY}unusual effect{YELLOW}.");
				DestroyHat(param1);
			}
			else
			{
				decl String:temp[64];
				GetTrieString(Trie, effectid_select, temp, sizeof(temp));
				CPrintToChat(param1, "{DARKRED}[Unusual Effects]{YELLOW} You have selected {GREY}%s{YELLOW}.", EffectNames[StringToInt(temp)][0]);
				Head_Effects_Menu(param1);
				if(!is_same)	EquipClient_Head(param1);
			}
		}
		case MenuAction_Cancel: 
		{
			UnusualMainMenu_CMD(param1, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_DrawItem:
		{
			new style;
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info), style);
		}
		case MenuAction_DisplayItem:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
		}
	}
	return 0;
}


// OTHER Menu

//
Feet_Effects_Menu(client)
{
	new Handle:menu = CreateMenu(MenuHandler2, MENU_ACTIONS_ALL);
	new String:Equipped[64];
	if(EffectIDChoosen[client][1][0] != EOS)
	{
		new String:temp[64];
		GetTrieString(Trie, EffectIDChoosen[client][1], temp, sizeof(temp));
		strcopy(Equipped, sizeof(Equipped), EffectNames[StringToInt(temp)][1]);
	}
	else
	{
		strcopy(Equipped, sizeof(Equipped), "-");
	}
	SetMenuTitle(menu, "Feet unusual effects\nCUrrent: %s\n", Equipped);
	if(StrEqual("",EffectIDChoosen[client][1], true))
	{
		AddMenuItem(menu, "", "[E] None");
	}
	else
	{
		AddMenuItem(menu, "", "None");
	}
	new count = 0;
	while(EffectIDs[count][1][0] != EOS && count < 400)
	{
		if(StrEqual(EffectIDs[count][1],EffectIDChoosen[client][1], true))
		{
			decl String:temp[256];
			FormatEx(temp, sizeof(temp), "[E] %s",  EffectNames[count][1]);
			AddMenuItem(menu, EffectIDs[count][1], temp);
		}
		else
		{
			AddMenuItem(menu, EffectIDs[count][1], EffectNames[count][1]);
		}
		count++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:effectid_select[64];
			GetMenuItem(menu, param2, effectid_select, sizeof(effectid_select));
			//
			new String:Steamid64[MAX_COMMUNITYID_LENGTH];
			if(GetClientAuthId(param1, AuthId_SteamID64, Steamid64, sizeof(Steamid64)))
			{
				decl String:query[256];
				FormatEx(query, sizeof(query), "UPDATE `unusual_table` SET  `id_name_feet` =  '%s' WHERE  `steamid64` =  '%s';", effectid_select, Steamid64);
				SQL_FastQuery(DB, query);
			}
			strcopy(EffectIDChoosen[param1][1], 64, effectid_select);
			if(StrEqual(effectid_select, "", true))
			{
				Feet_Effects_Menu(param1);
				CPrintToChat(param1, "{DARKRED}[Unusual Effects]{YELLOW} You are no longer using a feet {GREY}unusual effect{YELLOW}.");
				DestroyParticle(param1);
			}
			else
			{
				decl String:temp[64];
				GetTrieString(Trie, effectid_select, temp, sizeof(temp));
				CPrintToChat(param1, "{DARKRED}[Unusual Effects]{YELLOW} You have selected {GREY}%s{YELLOW}.", EffectNames[StringToInt(temp)][1]);
				Feet_Effects_Menu(param1);
				EquipClient_Feet(param1);
			}
		}
		case MenuAction_Cancel: 
		{
			UnusualMainMenu_CMD(param1, 0);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_DrawItem:
		{
			new style;
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info), style);
		}
		case MenuAction_DisplayItem:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
		}
	}
	return 0;
}


//
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Index_Hat[client] = 0;
	Index_Feet_Particle[client] = 0;
	new String:flag[10];
	GetConVarString(Cvar_Flag, flag, sizeof(flag));
	IsnOnTP[client] = false;
	ClientCommand(client, "firstperson");
	if(GetUserFlagBits(client) & ReadFlagString(flag) || StrEqual(flag, ""))
	{
		CreateTimer(1.5, EquipClientTimer, client);
	}
}

public Action:EquipClientTimer(Handle:timer, any:client)
{
	EquipClient(client);
}


public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	DestroyHat(client);
	DestroyParticle(client);
	ClientCommand(client, "firstperson");
	IsnOnTP[client] = false;
}


public Action:Hook_SetTransmit(entity, client)  
{  
	if( entity == Index_Hat[client] )
	{
		if(!IsnOnTP[client])
		{
			return Plugin_Handled;
		}
	}
	else if (!IsPlayerAlive(client) || IsClientObserver(client))
	{
		new iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		new Hat_Owner = GetHatOwner(entity);
		if(Hat_Owner > 0)
		{
			if(Hat_Owner == iTarget)
			{
				new iSpecMode;
				iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
				if (iSpecMode == SPECMODE_FIRSTPERSON)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}


EquipClient(client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	if(EffectIDChoosen[client][0][0] != EOS) EquipClient_Head(client);
	if(EffectIDChoosen[client][1][0] != EOS) EquipClient_Feet(client);
}

EquipClient_Head(client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	CreateTimer(1.0, EquipEffectHead, client);
}

EquipClient_Feet(client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	DestroyParticle(client);
	new String:temp[64];
	GetTrieString(Trie, EffectIDChoosen[client][1], temp, sizeof(temp));
	Index_Feet_Particle[client] = CreateParticle(EffectIDChoosen[client][1], client, EffectPos[StringToInt(temp)][1] );
}

public Action:EquipEffectHead(Handle:timer, any:client)
{
	new String:method[20];
	GetConVarString(Cvar_Method, method, sizeof(method));
	//
	DestroyHat(client);
	new Float:pos_o[3];
	new hat = CreateHat(client, pos_o);
	if(hat == -1) // I don't think this is ever true?
	{
		CPrintToChat(client, "{DARKRED}[Unusual Effects]{YELLOW} Your player model doesn't support head unusual effects.");
		return;
	}
	Index_Hat[client] = hat;
	//
	if((strcmp(method, "normal", false)) == 0)
	{
		new String:temp[64];
		GetTrieString(Trie, EffectIDChoosen[client][0], temp, sizeof(temp));
		CreateParticleHead(EffectIDChoosen[client][0], Index_Hat[client], EffectPos[StringToInt(temp)][0] , pos_o);
	}
	else
	{
		new g_StringTable = FindStringTable("ParticleEffectNames");
		new index_particle = FindStringIndex(g_StringTable, EffectIDChoosen[client][0]);
		new Float:pos[3];
		new Float:position[3];
		GetEntPropVector(Index_Hat[client], Prop_Send, "m_vecOrigin", position);
		DispatchParticleEffectToAll(index_particle, position, pos, Index_Hat[client], 0.0, client, 0);
	}
	SDKHook(Index_Hat[client], SDKHook_SetTransmit, Hook_SetTransmit);
}

DestroyHat(client)
{
	if(client > 0 && client <= MaxClients && Index_Hat[client] > 0 && IsValidEdict(Index_Hat[client]))
	{
		new ent = Index_Hat[client]
		decl String:strName[50];
		GetEdictClassname(ent, strName, sizeof(strName));
		if(StrEqual(strName, "prop_dynamic", true))
		{
			AcceptEntityInput(Index_Hat[client], "SetParent", 0, Index_Hat[client], 0);
			new Float:pos[3];
			TeleportEntity(Index_Hat[client], pos, NULL_VECTOR, NULL_VECTOR); 
			CreateTimer(1.0, DestroyEntity, Index_Hat[client]);
			Index_Hat[client] = 0;
		}
	}
}

DestroyParticle(client)
{
	if(client > 0 && client <= MaxClients && Index_Feet_Particle[client] > 0 && IsValidEdict(Index_Feet_Particle[client]))
	{
		new ent = Index_Feet_Particle[client]
		decl String:strName[50];
		GetEdictClassname(ent, strName, sizeof(strName));
		if(StrContains(strName, "particle", true) != -1)
		{
			AcceptEntityInput(Index_Feet_Particle[client], "SetParent", 0, Index_Feet_Particle[client], 0);
			new Float:pos[3];
			TeleportEntity(Index_Feet_Particle[client], pos, NULL_VECTOR, NULL_VECTOR); 
			CreateTimer(0.0, DestroyEntity, Index_Feet_Particle[client]);
			Index_Feet_Particle[client] = 0;
		}
	}
}

public Action:DestroyEntity(Handle:timer, any:ent)
{	
	if(IsValidEdict(ent))
	{
		decl String:strName[50];
		GetEdictClassname(ent, strName, sizeof(strName));
		if(StrEqual(strName, "prop_dynamic", true))
		{
			decl String:m_ModelName[PLATFORM_MAX_PATH];
			GetEntPropString(ent, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
			if(StrEqual(m_ModelName, "models/player/t_animations.mdl", true))
			{
				SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
				AcceptEntityInput(ent, "Kill");
			}
		}
		else if(StrEqual(strName, "info_particle_system", true))
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}


CreateHat(client, Float:pos[3])
{
	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	new Float:fOffset[3];
	fOffset[0] = 0.0;
	fOffset[1] = 0.0;
	fOffset[2] = 0.0;
	GetClientAbsOrigin(client,or);
	GetClientAbsAngles(client,ang);
	
	
	
	decl String:tempz[64];
	GetTrieString(Trie, EffectIDChoosen[client][0], tempz, sizeof(tempz));
	new num = StringToInt(tempz);
	ang[0] += EffectAngle[num][0][0];
	ang[1] += EffectAngle[num][0][1];
	ang[2] += EffectAngle[num][0][2];
	
	new String:WhereToAttach[64];

	WhereToAttach = "facemask";
	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", "models/player/t_animations.mdl");
	DispatchKeyValue(ent, "spawnflags", "4");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);

	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	or[2] += 65.0;
	pos = or;
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString(WhereToAttach);
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
	
	return ent;
}


public Action:WaitFrameToPutNoEffect(Handle:timer, any:ent)
{
	new m_iEntEffects = GetEntProp(ent, Prop_Send, "m_fEffects"); 
	m_iEntEffects &= ~32;
	m_iEntEffects |= 1;
	m_iEntEffects |= 128;
	SetEntProp(ent, Prop_Send, "m_fEffects", m_iEntEffects);
}

stock GetHatOwner(hat)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(Index_Hat[i] == hat)
		{
			return i;
		}
	}
	return 0;
}

stock DispatchParticleEffectToClient(p_ParticleType, Float:p_Origin[3],  Float:p_Angle[3], p_Parent = INVALID_ENT_REFERENCE, Float:p_Delay = 0.0, client, AttachWhere)
{
	TE_Start("EffectDispatch");
	p_Origin[0] = p_Origin[0] + 100.0;
	p_Origin[1] = p_Origin[1] + 100.0;
	p_Origin[2] = p_Origin[2] + 100.0;
	TE_WriteNum("m_nHitBox", p_ParticleType);
	TE_WriteFloat("m_vOrigin.x", p_Origin[0]);
	TE_WriteFloat("m_vOrigin.y", p_Origin[1]);
	TE_WriteFloat("m_vOrigin.z", p_Origin[2]);
	TE_WriteFloat("m_vStart.x", p_Origin[0]);
	TE_WriteFloat("m_vStart.y", p_Origin[1]);
	TE_WriteFloat("m_vStart.z", p_Origin[2]);
	TE_WriteVector("m_vAngles", p_Angle);
	//
	new fFlags;
	TE_WriteNum("entindex", client);
	fFlags |= PARTICLE_DISPATCH_FROM_ENTITY;
	TE_WriteNum("m_fFlags", fFlags);
	TE_WriteNum("m_nDamageType", _:1);
	TE_WriteNum("m_nAttachmentIndex", AttachWhere);
	//
	if(p_Parent == INVALID_ENT_REFERENCE)
		TE_WriteNum("entindex", 0);
	else
		TE_WriteNum("entindex", p_Parent);
		
	TE_SendToClient(client, p_Delay);
}

stock DispatchParticleEffect(p_ParticleType, const Float:p_Origin[3], const Float:p_Angle[3], const p_Clients[], p_ClientCount, p_Parent = INVALID_ENT_REFERENCE, Float:p_Delay = 0.0)
{
	TE_Start("EffectDispatch");
	
	TE_WriteNum("m_nHitBox", p_ParticleType);
	TE_WriteFloat("m_vOrigin.x", p_Origin[0]);
	TE_WriteFloat("m_vOrigin.y", p_Origin[1]);
	TE_WriteFloat("m_vOrigin.z", p_Origin[2]);
	TE_WriteFloat("m_vStart.x", p_Origin[0]);
	TE_WriteFloat("m_vStart.y", p_Origin[1]);
	TE_WriteFloat("m_vStart.z", p_Origin[2]);
	TE_WriteVector("m_vAngles", p_Angle);
	
	if(p_Parent == INVALID_ENT_REFERENCE)
		TE_WriteNum("entindex", 0);
	else
		TE_WriteNum("entindex", p_Parent);
		
	TE_Send(p_Clients, p_ClientCount, p_Delay);
}

stock DispatchParticleEffectToAll(p_ParticleType, Float:p_Origin[3],  Float:p_Angle[3], p_Parent = INVALID_ENT_REFERENCE, Float:p_Delay = 0.0, client, AttachWhere)
{
	TE_Start("EffectDispatch");
	p_Origin[0] = p_Origin[0] + 100.0;
	p_Origin[1] = p_Origin[1] + 100.0;
	p_Origin[2] = p_Origin[2] + 100.0;
	TE_WriteNum("m_nHitBox", p_ParticleType);
	TE_WriteFloat("m_vOrigin.x", p_Origin[0]);
	TE_WriteFloat("m_vOrigin.y", p_Origin[1]);
	TE_WriteFloat("m_vOrigin.z", p_Origin[2]);
	TE_WriteFloat("m_vStart.x", p_Origin[0]);
	TE_WriteFloat("m_vStart.y", p_Origin[1]);
	TE_WriteFloat("m_vStart.z", p_Origin[2]);
	TE_WriteVector("m_vAngles", p_Angle);
	//
	new fFlags;
	TE_WriteNum("entindex", client);
	fFlags |= PARTICLE_DISPATCH_FROM_ENTITY;
	TE_WriteNum("m_fFlags", fFlags);
	TE_WriteNum("m_nDamageType", _:1);
	TE_WriteNum("m_nAttachmentIndex", AttachWhere);
	//
	if(p_Parent == INVALID_ENT_REFERENCE)
		TE_WriteNum("entindex", 0);
	else
		TE_WriteNum("entindex", p_Parent);
		
	TE_SendToAll(0.0);
}

stock CreateParticle(String:type[], entity, Float:pos_add[3])
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += pos_add[0];
		pos[1] += pos_add[1];
		pos[2] += pos_add[2];
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return particle;
}

stock CreateParticleHead(String:type[], entity, Float:pos_add[3], Float:pos_o[3])
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		new Float:angs[3];
		if(StrContains(type, "circling", false) != -1)
		{
			pos_o[2] += 14.0;
			angs[2] += 90.0;
		}
		pos_o[0] += pos_add[0];
		pos_o[1] += pos_add[1];
		pos_o[2] += pos_add[2];
		TeleportEntity(particle, pos_o, angs, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return particle;
}
