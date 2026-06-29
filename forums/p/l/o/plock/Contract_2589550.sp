#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#undef REQUIRE_PLUGIN
#include <zephyrus_store>
#include <warden>
#include <hosties>
#include <lastrequest>
#include <myjailshop>
#include <store-backend>
#include <smrpg>
#include <shavit>
#pragma newdecls optional
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <cstrike>
#pragma newdecls required

//Plugin Info
#define PLUGIN_TAG						"\x01\x0B \x04 [ \x05 Contract\x04 ] \x01 "
#define PLUGIN_NAME						"[ANY] Contract"
#define PLUGIN_AUTHOR 					"Arkarr" //warden & lastrequest by shanapu
#define PLUGIN_VERSION 					"1.6"
#define PLUGIN_DESCRIPTION 				"Assign contract to player and let them a certain period of time to do it to earn extra credits."
//KeyValue fields
#define FIELD_CONTRACT_NAME 			"Contract Name"
#define FIELD_CONTRACT_ACTION			"Contract Type"
#define FIELD_CONTRACT_OBJECTIVE		"Contract Objective"
#define FIELD_CONTRACT_CHANCES			"Contract Chances"
#define FIELD_CONTRACT_REWARD			"Contract Reward"
#define FIELD_CONTRACT_WEAPON			"Contract Weapon"
//Database queries
#define QUERY_INIT_DATABASE				"CREATE TABLE IF NOT EXISTS `contracts` (`steamid` varchar(45) NOT NULL, `name` varchar(45) NOT NULL, `points` int NOT NULL, `accomplishedcount` int NOT NULL, PRIMARY KEY (`steamid`))"
#define QUERY_LOAD_CONTRACTS			"SELECT `points`, `accomplishedcount` FROM contracts WHERE `steamid`=\"%s\""
#define QUERY_UPDATE_CONTRACTS			"UPDATE `contracts` SET `points`=\"%i\",`accomplishedcount`=\"%i\",`name`=\"%s\", WHERE `steamid`=\"%s\";"
#define QUERY_NEW_ENTRY					"INSERT INTO `contracts` (`steamid`,`name`,`points`,`accomplishedcount`) VALUES (\"%s\", '%s', %i, %i);"
#define QUERY_ALL_CONTRACTS				"SELECT `name`, `points`,`accomplishedcount` FROM `contracts` ORDER BY `points` DESC"
#define QUERY_CLEAR_CONTRACTS			"DELETE FROM `contracts`"
//Other plugins related stuff
#define STORE_NONE						"NONE"
#define STORE_ZEPHYRUS					"ZEPHYRUS"
#define STORE_SMSTORE					"SMSTORE"
#define STORE_SMRPG						"SMRPG"
#define STORE_MYJS						"MYJS"

EngineVersion engineName;

Handle CVAR_DBConfigurationName;
Handle CVAR_ChanceGetContract;
Handle CVAR_TeamRestrictions;
Handle CVAR_ContractInterval;
Handle CVAR_MinimumPlayers;
Handle CVAR_MinimumPlayersProgress;
Handle CVAR_UsuedStore;

Handle TIMER_ContractsDistribution;
Handle COOKIE_CurrentContract;
Handle COOKIE_ShowHUD;
Handle DATABASE_Contract;
Handle ARRAY_Contracts;

bool IsInContract[MAXPLAYERS + 1];
bool IsInDatabase[MAXPLAYERS + 1];
bool IsDatabaseConnected = false;
bool ShowHUD[MAXPLAYERS + 1];
bool g_bIsLR = false;

int contractPoints[MAXPLAYERS + 1];
int contractReward[MAXPLAYERS + 1];
int contractProgress[MAXPLAYERS + 1];
int contractObjective[MAXPLAYERS + 1];
int contractAccomplishedCount[MAXPLAYERS + 1];

float g_fdistance;
float newPosition[3];
float lastPosition[MAXPLAYERS + 1][3];

char action[50];
char reward[10];
char weapon[10];
char chances[10];
char objective[10];
char contractType[MAXPLAYERS + 1][100];
char contractName[MAXPLAYERS + 1][100];
char contractWeapon[MAXPLAYERS + 1][100];
char contractDescription[MAXPLAYERS + 1][100];

public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{	
	RegAdminCmd("sm_givecontract", CMD_GiveContract, ADMFLAG_GENERIC, "Give a contract to a user.");
	RegAdminCmd("sm_resetcontract", CMD_ResetContract, ADMFLAG_GENERIC, "Clear the contract table.");
	
	RegConsoleCmd("sm_contract", CMD_DisplayContractInfo, "Display your current contract info.");
	RegConsoleCmd("sm_contractlevel", CMD_DisplayContractRank, "Display your contract rank.");
	RegConsoleCmd("sm_contracttop", CMD_DisplayContractTop, "Display the first 10 best contract rank.");
	RegConsoleCmd("sm_contracthud", CMD_ToggleHUD, "Remove/Display your current contract in HUD");
	//RegConsoleCmd("sm_test", CMD_test);
	
	CVAR_DBConfigurationName = CreateConVar("sm_database_configuration_name", "storage-local", "Configuration name in database.cfg, by default, all results are saved in the sqlite database.");
	CVAR_ChanceGetContract = CreateConVar("sm_contract_chance_get_contract", "30", "The % of luck to get a new contract every 5 minutes.", _, true, 1.0);
	CVAR_TeamRestrictions = CreateConVar("sm_contract_teams", "2;3", "Team index wich can get contract. 2 = RED/T 3 = BLU/CT");
	CVAR_UsuedStore = CreateConVar("sm_contract_store_select", "NONE", "NONE=No store usage/ZEPHYRUS=use zephyrus store/SMSTORE=use sourcemod store/MYJS=use MyJailShop");
	CVAR_MinimumPlayers = CreateConVar("sm_contract_minimum_players", "2", "How much player needed before receving an contract.", _, true, 1.0);
	CVAR_MinimumPlayersProgress = CreateConVar("sm_contract_minimum_players_progress", "2", "How much player need to progress with a contract.", _, true, 1.0);
	CVAR_ContractInterval = CreateConVar("sm_contract_interval", "300", "Time (in seconds) before giving a new contract if any.", _, true, 1.0);
	
	AutoExecConfig(true, "contract");
	
	COOKIE_CurrentContract = RegClientCookie("Contract_CurrentContractName", "Contain the name of the current contract.", CookieAccess_Private);
	COOKIE_ShowHUD = RegClientCookie("Contract_ShowHUD", "Bool toggle show player contract HUD.", CookieAccess_Public);
	
	engineName = GetEngineVersion();
	
	CreateTimer(0.5, TMR_UpdateHUD, _, TIMER_REPEAT);
	
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsValidClientContract (z))
			continue;
		
		GetClientAbsOrigin(z, lastPosition[z]);
		SDKHook(z, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_end", OnRoundEnd);
	
	LoadTranslations("common.phrases");
	LoadTranslations("contract.phrases");
}

public void OnPluginEnd()
{
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsValidClientContract (z) || !IsInContract[z])
			continue;
		
		SaveCookie(z);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	MarkNativeAsOptional("Store_GetClientAccountID");
	MarkNativeAsOptional("Store_GiveCreditsToUsers");
	MarkNativeAsOptional("SMRPG_AddClientExperience");
	
	return APLRes_Success;
}

public void SaveCookie(int client)
{
	if (IsInContract[client])
	{
		char sCookieValue[100];
		Format(sCookieValue, sizeof(sCookieValue), "%s¢%i", contractName[client], contractProgress[client]);
		SetClientCookie(client, COOKIE_CurrentContract, sCookieValue);
	}
}

public void OnClientCookiesCached(int client)
{
	char sCookieValue[100];
	char tmpContractName[100];
	char sContractNameValue[2][100];
	GetClientCookie(client, COOKIE_CurrentContract, sCookieValue, sizeof(sCookieValue));
	
	if (StrEqual(sCookieValue, "-"))
		return;
	
	if (StrContains(sCookieValue, "¢") == -1)
	{
		SetClientCookie(client, COOKIE_CurrentContract, "-");
		return;
	}
	
	ExplodeString(sCookieValue, "¢", sContractNameValue, sizeof sContractNameValue, sizeof sContractNameValue[]);
	
	GetClientCookie(client, COOKIE_ShowHUD, sCookieValue, sizeof(sCookieValue));
	
	if (StringToInt(sCookieValue) != 1)
		ShowHUD[client] = false;
	else
		ShowHUD[client] = true;
	
	int contractCount = GetArraySize(ARRAY_Contracts);
	while (contractCount > 0)
	{
		contractCount--;
		
		Handle TRIE_Contract = GetArrayCell(ARRAY_Contracts, contractCount);
		GetTrieString(TRIE_Contract, FIELD_CONTRACT_NAME, tmpContractName, sizeof(tmpContractName));
		
		if (StrEqual(tmpContractName, sContractNameValue[0]))
		{
			AssignateContract(client, true, contractCount);
			contractProgress[client] = StringToInt(sContractNameValue[1]);
			break;
		}
	}
}

public void OnConfigsExecuted()
{
	ReadConfigFile();
	
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsValidClientContract (z))
			continue;
		
		if (AreClientCookiesCached(z))
			OnClientCookiesCached(z);
	}
	
	if (GetConVarInt(CVAR_MinimumPlayers) <= GetPlayerCount())
		TIMER_ContractsDistribution = CreateTimer(GetConVarFloat(CVAR_ContractInterval), TMR_DistributeContracts, _, TIMER_REPEAT);
	
	
	if(!IsDatabaseConnected)
	{
		char dbconfig[45];
		GetConVarString(CVAR_DBConfigurationName, dbconfig, sizeof(dbconfig));
		SQL_TConnect(GotDatabase, dbconfig);
	}
}

public void OnClientConnected(int client)
{
	if (TIMER_ContractsDistribution == INVALID_HANDLE)
	{
		if (GetConVarInt(CVAR_MinimumPlayers) <= GetPlayerCount())
			TIMER_ContractsDistribution = CreateTimer(GetConVarFloat(CVAR_ContractInterval), TMR_DistributeContracts, _, TIMER_REPEAT);
	}
	
	IsInContract[client] = false;
	
	if (DATABASE_Contract != INVALID_HANDLE)
		LoadContracts(client);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	if (!IsValidClientContract (client))
		return;
	
	if (TIMER_ContractsDistribution != INVALID_HANDLE)
	{
		if (GetConVarInt(CVAR_MinimumPlayers) > GetPlayerCount())
		{
			KillTimer(TIMER_ContractsDistribution);
			TIMER_ContractsDistribution = INVALID_HANDLE;
		}
	}
	
	SaveCookie(client);
	SaveIntoDatabase(client);
}

//Event callback
public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{	
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
		
	if (GetConVarInt(CVAR_MinimumPlayersProgress) <= GetPlayerCount())
		return;
				
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
	if (IsInContract[attacker] && StrEqual(contractType[attacker], "TEAM_KILL"))
	{
		if(attacker != client && GetClientTeam(attacker) == GetClientTeam(client))
		{
			contractProgress[attacker]++;
			VerifyContract(attacker);
		}
	}
	
	if (!IsValidClientContract (client))
		return;
	
	if (IsInContract[attacker] && StrEqual(contractType[attacker], "HEADSHOT"))
	{
		int customkill = GetEventInt(event, "customkill");
		
		if (engineName == Engine_TF2)
		{
			if ((customkill == TF_CUSTOM_HEADSHOT || customkill == TF_CUSTOM_HEADSHOT_DECAPITATION))
			{
				contractProgress[attacker]++;
				VerifyContract(attacker);
			}
		}
		else if (engineName == Engine_CSGO || engineName == Engine_CSS)
		{
			if (GetEventInt(event, "headshot") == 1)
			{
				contractProgress[attacker]++;
				VerifyContract(attacker);
			}
		}
	}
	
	if(IsInContract[attacker] && StrEqual(contractType[attacker], "NO_SCOPE"))
	{
		if((StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1) || !(0 < GetEntProp(attacker, Prop_Data, "m_iFOV") < GetEntProp(attacker, Prop_Data, "m_iDefaultFOV")))
		{
			contractProgress[attacker]++;
			
			VerifyContract(attacker);
		}
	}
	
	if (IsInContract[client] && StrEqual(contractType[client], "DIE"))
	{
		if (CheckKillMethod(client))
			contractProgress[client]++;
		
		if (IsInContract[attacker] && StrEqual(contractType[attacker], "KILL"))
		{
			if (CheckKillMethod(attacker))
				contractProgress[attacker]++;
			
			VerifyContract(attacker);
		}
		
		VerifyContract(client);
	}
	
	if (IsInContract[attacker] && StrEqual(contractType[attacker], "KILL"))
	{
		if (CheckKillMethod(attacker))
			contractProgress[attacker]++;
		
		VerifyContract(attacker);
	}
	
	if (!LibraryExists("warden"))
		return;
	
	if (IsInContract[attacker] && StrEqual(contractType[attacker], "WARDEN_KILLS"))
	{
		if (warden_iswarden(attacker))
		{
			if (CheckKillMethod(attacker))
			{
				contractProgress[attacker]++;
				VerifyContract(attacker);
			}
		}
	}
}

public void OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (!LibraryExists("warden") && !LibraryExists("hosties"))
		return;
	
	if (GetConVarInt(CVAR_MinimumPlayersProgress) <= GetPlayerCount())
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClientContract(i) && IsInContract[i] && IsPlayerAlive(i))
		{
			if (StrEqual(contractType[i], "WARDEN_ROUNDS"))
			{
				if (warden_iswarden(i))
				{
					contractProgress[i]++;
					VerifyContract(i);
				}
			}
			if (g_bIsLR)
			{
				if (StrEqual(contractType[i], "LAST_REQUEST"))
				{
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						contractProgress[i]++;
						VerifyContract(i);
					}
				}
			}
		}
	}
	g_bIsLR = false;
}

public void MyJailbreak_OnEventDayEnd(char[] EventDayName, int winner)
{
	if (GetConVarInt(CVAR_MinimumPlayersProgress) <= GetPlayerCount())
		return;
		
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClientContract(i) && IsInContract[i] && IsPlayerAlive(i))
		{
			if(winner > 1)
			{
				if (GetClientTeam(i) != winner)
					continue;
			}
			
			if (StrEqual(contractType[i], "EVENT_DAYS"))
			{
				contractProgress[i]++;
				VerifyContract(i);
			}
		}
	}
}
public int OnAvailableLR(int Announced)
{
	g_bIsLR = true;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetConVarInt(CVAR_MinimumPlayersProgress) <= GetPlayerCount())
		return Plugin_Continue;
		
	if (IsValidClientContract (victim) && IsInContract[victim] && StrEqual(contractType[victim], "TAKE_DAMAGE"))
	{
		contractProgress[victim] += RoundToCeil(damage);
		VerifyContract(victim);
	}
	
	if (IsValidClientContract (attacker) && IsInContract[attacker] && StrEqual(contractType[attacker], "DEAL_DAMAGE"))
	{
		contractProgress[attacker] += RoundToCeil(damage);
		VerifyContract(attacker);
	}
	
	return Plugin_Continue;
}

public void Shavit_OnFinish(int client, BhopStyle style, float time, int jumps, int strafes, float sync)
{
	if (GetConVarInt(CVAR_MinimumPlayersProgress) <= GetPlayerCount())
		return;
		
	if (IsInContract[client] && StrEqual(contractType[client], "FINISH_BHOPSHAVIT"))
	{
		contractProgress[client]++;
		VerifyContract(client);
	}
}

//Command callback.
/*public Action CMD_test(int client, int args)
{
	OnClientDisconnect(client);
}*/

public Action CMD_ResetContract(int client, int args)
{
	char message[100];
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Database_reset");
	
	if (client == 0)
		PrintToServer("[Contract] %t", "Database_reset");
	else
		PrintMessageChat(client, message);
	
	for (int z = 0; z < MaxClients; z++)
	{
		IsInContract[z] = false;
		IsInDatabase[z] = false;
		
		contractPoints[z] = 0;
		contractAccomplishedCount[z] = 0;
	}
	
	SQL_FastQuery(DATABASE_Contract, QUERY_CLEAR_CONTRACTS);
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Done");
	
	if (client == 0)
		PrintToServer("[Contract] %t", "Done");
	else
		PrintMessageChat(client, message);
}

public Action CMD_GiveContract(int client, int args)
{
	if (args < 1)
	{
		char message[100];
		Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_GiveUsage");
		
		PrintMessageChat(client, message);
		return Plugin_Handled;
	}
	
	char arg1[45];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg1, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_NO_BOTS, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}
	
	for (int i = 0; i < target_count; i++)
		AssignateContract(target_list[i], true, -1);
		
	char message[100];
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_GiveSucess", target_count);
	
	PrintMessageChat(client, message);
	
	return Plugin_Handled;
}

public Action CMD_DisplayContractInfo(int client, int args)
{
	if (!IsValidClientContract (client))
		return Plugin_Handled;
	
	char message[100];
		
	if (!IsInContract[client])
	{
		Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_None");
		
		PrintMessageChat(client, message);
		return Plugin_Handled;
	}
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_Mission", contractDescription[client]);
	PrintMessageChat(client, message);
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_Progress", contractProgress[client], contractObjective[client]);
	PrintMessageChat(client, message);
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_Reward", contractReward[client]);
	PrintMessageChat(client, message);
	
	return Plugin_Handled;
}

public Action CMD_DisplayContractRank(int client, int args)
{
	if (!IsValidClientContract (client))
		return Plugin_Handled;
	
	int target = -1;
	
	if (args == 0)
	{
		target = client;
	}
	else
	{
		char sTarget[45];
		GetCmdArg(1, sTarget, sizeof(sTarget));
		target = FindTarget(client, sTarget, true, false);
	}
	
	char message[100];
		
	if (target == -1)
	{
		Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Target_Invalid");
		PrintMessageChat(client, message);
	}
	
	if (client == target)
	{
		Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_CompletedInfoSelf", contractAccomplishedCount[client], contractPoints[client]);
		PrintMessageChat(client, message);
	}
	else
	{
		Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_CompletedInfoOther", target, contractAccomplishedCount[target], contractPoints[target]);
		PrintMessageChat(client, message);
	}
	
	return Plugin_Handled;
}

public Action CMD_DisplayContractTop(int client, int args)
{
	char message[100];
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Database_LoadingTop");
	
	PrintMessageChat(client, message);
	SQL_TQuery(DATABASE_Contract, T_GetTop10, QUERY_ALL_CONTRACTS, client);
	
	return Plugin_Handled;
}

public Action CMD_ToggleHUD(int client, int args)
{
	if (ShowHUD[client])
	{
		ShowHUD[client] = false;
		SetClientCookie(client, COOKIE_ShowHUD, "0");
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "HUD_disabled");
	}
	else
	{
		ShowHUD[client] = true;
		SetClientCookie(client, COOKIE_ShowHUD, "1");
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "HUD_enabled");
	}
	
	return Plugin_Handled;
}
//Function
public bool CheckKillMethod(int client)
{
	if (strlen(contractWeapon[client]) < 3)
		return true;
	
	char sWeapon[100];
	int aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (IsValidEntity(aWeapon))
		GetEntPropString(aWeapon, Prop_Data, "m_iClassname", sWeapon, sizeof(sWeapon));
	
	if (StrEqual(contractWeapon[client], sWeapon))
	{
		return true;
	}
	else
	{
		if (engineName == Engine_TF2)
		{
			if (StrEqual(contractWeapon[client], "PRIMARY") && aWeapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				return true;
			else if (StrEqual(contractWeapon[client], "SECONDARY") && aWeapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				return true;
			else if (StrEqual(contractWeapon[client], "MELEE") && aWeapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
				return true;
		}
		else if (engineName == Engine_CSGO || engineName == Engine_CSS)
		{
			if (StrEqual(contractWeapon[client], "PRIMARY") && aWeapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY))
				return true;
			else if (StrEqual(contractWeapon[client], "SECONDARY") && aWeapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY))
				return true;
			else if (StrEqual(contractWeapon[client], "MELEE") && aWeapon == GetPlayerWeaponSlot(client, CS_SLOT_KNIFE))
				return true;
		}
	}
	
	return false;
}

public void LoadContracts(int client)
{
	char query[100];
	char steamid[30];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), QUERY_LOAD_CONTRACTS, steamid);
	SQL_TQuery(DATABASE_Contract, T_GetPlayerInfo, query, client);
}

public void SendContract(int client, Handle contractInfos, bool forceYES)
{
	char sObjectiv[100];
	char cWeapon[100];
	char cAction[50];
	char cName[100];
	int cObjective;
	int cReward;
	
	GetTrieString(contractInfos, FIELD_CONTRACT_NAME, cName, sizeof(cName));
	GetTrieString(contractInfos, FIELD_CONTRACT_ACTION, cAction, sizeof(cAction));
	GetTrieValue(contractInfos, FIELD_CONTRACT_OBJECTIVE, cObjective);
	GetTrieValue(contractInfos, FIELD_CONTRACT_REWARD, cReward);
	if (GetTrieString(contractInfos, FIELD_CONTRACT_WEAPON, cWeapon, sizeof(cWeapon)) && strlen(cWeapon) > 3)
	{
		contractWeapon[client] = cWeapon;
		Format(cWeapon, sizeof(cWeapon), " (%s)", cWeapon);
	}
	
	if (StrEqual(cAction, "WALK"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_Walk", cObjective);
	else if (StrEqual(cAction, "KILL"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_Kill", cObjective, cWeapon);
	else if (StrEqual(cAction, "HEADSHOT"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_Headshot", cObjective);
	else if (StrEqual(cAction, "DIE"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_Die", cObjective);
	else if (StrEqual(cAction, "WARDEN_ROUNDS"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_WardenRounds", cObjective);
	else if (StrEqual(cAction, "WARDEN_KILLS"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_WardenKills", cObjective, cWeapon);
	else if (StrEqual(cAction, "LAST_REQUEST"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_LastRequest", cObjective);
	else if (StrEqual(cAction, "FINISH_BHOPSHAVIT"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_BhopShavit", cObjective);
	else if (StrEqual(cAction, "DEAL_DAMAGE"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_DealDamage", cObjective);
	else if (StrEqual(cAction, "TAKE_DAMAGE"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_TakeDamage", cObjective);
	else if (StrEqual(cAction, "NO_SCOPE"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_NoScope", cObjective);
	else if (StrEqual(cAction, "TEAM_KILL"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_TeamKill", cObjective);
	else if (StrEqual(cAction, "EVENT_DAYS"))
		Format(sObjectiv, sizeof(sObjectiv), "%t", "Contract_EventDays", cObjective);
	
	contractReward[client] = cReward;
	contractProgress[client] = 0;
	contractObjective[client] = cObjective;
	Format(contractType[client], sizeof(contractType[]), cAction);
	Format(contractName[client], sizeof(contractName[]), cName);
	Format(contractDescription[client], sizeof(contractDescription[]), "%s - %s", cName, sObjectiv);
	
	if (!forceYES)
	{
		char phrases[100];
		Format(cName, sizeof(cName), "%t - %s", "Contract_New", cName);
		Panel menu = new Panel();
		SetPanelTitle(menu, cName);
		Format(phrases, sizeof(phrases), "%t", "menu_objectiv");
		DrawPanelItem(menu, phrases, ITEMDRAW_RAWLINE);
		DrawPanelItem(menu, sObjectiv, ITEMDRAW_RAWLINE);
		Format(phrases, sizeof(phrases), "%t", "menu_accept");
		DrawPanelItem(menu, phrases, ITEMDRAW_RAWLINE);
		Format(phrases, sizeof(phrases), "%t", "menu_yes");
		DrawPanelItem(menu, phrases);
		Format(phrases, sizeof(phrases), "%t", "menu_no");
		DrawPanelItem(menu, phrases);
		SendPanelToClient(menu, client, MenuHandle_MainMenu, MENU_TIME_FOREVER);
	}
	else
	{
		IsInContract[client] = true;
	}
}

public void VerifyContract(int client)
{
	if (contractProgress[client] < contractObjective[client])
		return;
		
	if (!IsInContract[client])
		return;
	
	IsInContract[client] = false;
	
	contractAccomplishedCount[client]++;
	contractPoints[client] += contractReward[client];
	
	SaveIntoDatabase(client);
	
	char store[15];
	GetConVarString(CVAR_UsuedStore, store, sizeof(store));
	
	if (StrEqual(store, STORE_ZEPHYRUS))
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + contractReward[client]);
	}
	else if (StrEqual(store, STORE_SMSTORE))
	{
		int id[1];
		id[0] = Store_GetClientAccountID(client);
		Store_GiveCreditsToUsers(id, 1, contractReward[client]);
	}
	else if (StrEqual(store, STORE_SMRPG))
	{
		SMRPG_SetClientExperience(client, SMRPG_GetClientExperience(client) + contractReward[client]);
	}
	else if (StrEqual(store, STORE_MYJS))
	{
		MyJailShop_SetCredits(client, MyJailShop_GetCredits(client)+contractReward[client]);
	}
	
	char message[100];
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_ThankYou");
	PrintMessageChat(client, message);
	
	Format(message, sizeof(message), "%s %t", PLUGIN_TAG, "Contract_ThankReward", contractReward[client]);
	PrintMessageChat(client, message);
	
	SetClientCookie(client, COOKIE_CurrentContract, "-");
}

public void SaveIntoDatabase(int client)
{
	char query[400];
	char steamid[30];
	char clientName[45];
	
	if (!GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)))
		return;
	
	GetClientNameForDatabase(DATABASE_Contract, client, clientName, sizeof(clientName));
	
	if (IsInDatabase[client])
	{
		Format(query, sizeof(query), QUERY_UPDATE_CONTRACTS, contractPoints[client], contractAccomplishedCount[client], clientName, steamid);
		PrintToConsole(client, query);
		SQL_FastQuery(DATABASE_Contract, query);
	}
	else
	{
		Format(query, sizeof(query), QUERY_NEW_ENTRY, steamid, clientName, contractPoints[client], contractAccomplishedCount[client]);
		PrintToConsole(client, query);
		SQL_FastQuery(DATABASE_Contract, query);
	}
}

public void AssignateContract(int client, bool force, int contractID)
{
	float pourcent = GetConVarFloat(CVAR_ChanceGetContract) / 100.0;
	float ch = GetRandomFloat(0.0, 1.0);
	PrintToServer("GET CONTRACT CHANCE %.2f <= %.2f", ch, pourcent);
	
	if (force == false && ch > pourcent)
		return;
		
	PrintToServer("OK!");
	PrintToServer("CONTRACT ID : %i", contractID);
	if (contractID == -1)
	{
		PrintToServer("OK!");
		
		int contractCount = GetArraySize(ARRAY_Contracts);
		while (contractCount > 0)
		{
			contractCount--;
			
			Handle TRIE_Contract = GetArrayCell(ARRAY_Contracts, GetRandomInt(0, contractCount-1));
			
			GetTrieValue(TRIE_Contract, FIELD_CONTRACT_CHANCES, pourcent);
			
			if(pourcent > 1.0)
				pourcent /= 100;
				
			if (GetRandomFloat(0.0, 1.0) <= pourcent)
				continue;
				
			SendContract(client, TRIE_Contract, false);
			break;
		}
		
		if (force)
		{
			Handle TRIE_Contract = GetArrayCell(ARRAY_Contracts, GetRandomInt(0, GetArraySize(ARRAY_Contracts) - 1));
			GetTrieValue(TRIE_Contract, FIELD_CONTRACT_CHANCES, pourcent);
			SendContract(client, TRIE_Contract, false);
		}
	}
	else
	{
		if (contractID < 0 || contractID > GetArraySize(ARRAY_Contracts) - 1)
		{
			SetFailState("INVALID CONTRACT ID SUPPLIED !");
			return;
		}
		
		Handle TRIE_Contract = GetArrayCell(ARRAY_Contracts, contractID);
		GetTrieValue(TRIE_Contract, FIELD_CONTRACT_CHANCES, pourcent);
		SendContract(client, TRIE_Contract, true);
	}
}

//Timer callback
public Action TMR_UpdateHUD(Handle tmr)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && IsInContract[i] && ShowHUD[i])
		{
			GetClientAbsOrigin(i, newPosition);
			g_fdistance = GetVectorDistance(lastPosition[i], newPosition);
			lastPosition[i] = newPosition;
			if (g_fdistance / 20 >= 1 && StrEqual(contractType[i], "WALK"))
			{
				contractProgress[i] += 1;
				VerifyContract(i);
			}
		}
	}
	
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsInContract[z] || !IsValidClientContract (z) || !ShowHUD[z])
			continue;
		
		SetHudTextParams(0.02, 0.0, 0.8, 255, 0, 0, 200);
		ShowHudText(z, -1, contractDescription[z]);
		SetHudTextParams(0.02, 0.03, 0.8, 255, 0, 0, 200);
		ShowHudText(z, -1, "%i / %i", contractProgress[z], contractObjective[z]);
	}
}

public Action TMR_DistributeContracts(Handle tmr)
{
	char teams[10];
	char team[3];
	GetConVarString(CVAR_TeamRestrictions, teams, sizeof(teams));
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsValidClientContract (z) || IsInContract[z])
			continue;
			
		PrintToServer("*************");
		IntToString(GetClientTeam(z), team, sizeof(team));
		
		if (StrContains(teams, team) == -1)
			continue;
		
		AssignateContract(z, false, -1);
		PrintToServer("*************");
	}
}

//Menu Handlers
public int MenuHandle_MainMenu(Handle menu, MenuAction menuAction, int client, int itemIndex)
{
	if (menuAction == MenuAction_Select)
	{
		if (itemIndex == 1)
			IsInContract[client] = true;
		else if (itemIndex == 2)
			IsInContract[client] = false;
	}
	else
	{
		CloseHandle(menu);
	}
}

public int MenuHandler_Top(Handle menu, MenuAction menuAction, int param1, int param2)
{
	if (menuAction == MenuAction_End)
		CloseHandle(menu);
}

//Database related stuff
public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("%t", "Database_Failure", error);
	}
	else
	{
		DATABASE_Contract = hndl;
		IsDatabaseConnected = true;
		
		char buffer[300];
		if (!SQL_FastQuery(DATABASE_Contract, QUERY_INIT_DATABASE))
		{
			SQL_GetError(DATABASE_Contract, buffer, sizeof(buffer));
			SetFailState("%s", buffer);
		}
		
		for (int z = 1; z < MaxClients; z++)
		{
			if (!IsValidClientContract (z))
				continue;
			
			LoadContracts(z);
		}
	}
}

public void T_GetTop10(Handle db, Handle results, const char[] error, any data)
{
	int client = data;
	
	if (client == 0)
		return;
	
	if (results == INVALID_HANDLE)
	{
		char message[100];
		Format(message, sizeof(message), "%t", "Database_ErrorTopPlayer", PLUGIN_TAG);
		
		PrintMessageChat(client, message);
		
		LogError("Query failed >>> %s", error);
		return;
	}
	
	Handle menu = CreateMenu(MenuHandler_Top);
	SetMenuTitle(menu, "%t", "Contract_MTopSeven");
	
	char name[45];
	char menuEntry[100];
	
	int points = 0;
	int count = 7;
	int accomplishedcount = 0;
	while (SQL_FetchRow(results))
	{
		if (count <= 0)
			break; //I could use MySQL but nah.
		SQL_FetchString(results, 0, name, sizeof(name));
		points = SQL_FetchInt(results, 1);
		accomplishedcount = SQL_FetchInt(results, 2);
		Format(menuEntry, sizeof(menuEntry), "%t", "Contract_MenuItem", name, points, accomplishedcount);
		AddMenuItem(menu, "-", menuEntry, ITEMDRAW_DISABLED);
		count--;
	}
	
	DisplayMenu(menu, client, 40);
	
	CloseHandle(results);
}

public void T_GetPlayerInfo(Handle db, Handle results, const char[] error, any data)
{
	if (DATABASE_Contract == INVALID_HANDLE)
		return;
	
	int client = data;
	if (!IsValidClientContract (client))
		return;
	
	if (!SQL_FetchRow(results))
	{
		IsInDatabase[client] = false;
	}
	else
	{
		contractPoints[client] = SQL_FetchInt(results, 0);
		contractAccomplishedCount[client] = SQL_FetchInt(results, 1);
		IsInDatabase[client] = true;
	}
}

//Stocks
stock bool ReadConfigFile()
{
	ARRAY_Contracts = CreateArray();
	
	char path[100];
	Handle kv = CreateKeyValues("Contracts Options");
	BuildPath(Path_SM, path, sizeof(path), "/configs/contracts.cfg");
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv))
		return;
	
	char cName[100];
	do
	{
		KvGetString(kv, FIELD_CONTRACT_NAME, cName, sizeof(cName));
		KvGetString(kv, FIELD_CONTRACT_ACTION, action, sizeof(action));
		KvGetString(kv, FIELD_CONTRACT_OBJECTIVE, objective, sizeof(objective));
		KvGetString(kv, FIELD_CONTRACT_CHANCES, chances, sizeof(chances));
		KvGetString(kv, FIELD_CONTRACT_REWARD, reward, sizeof(reward));
		KvGetString(kv, FIELD_CONTRACT_WEAPON, weapon, sizeof(weapon));
		
		Handle tmpTrie = CreateTrie();
		SetTrieString(tmpTrie, FIELD_CONTRACT_NAME, cName, false);
		SetTrieString(tmpTrie, FIELD_CONTRACT_ACTION, action, false);
		SetTrieValue(tmpTrie, FIELD_CONTRACT_OBJECTIVE, StringToInt(objective), false);
		SetTrieValue(tmpTrie, FIELD_CONTRACT_CHANCES, (StringToFloat(chances) / 100.0), false);
		SetTrieValue(tmpTrie, FIELD_CONTRACT_REWARD, StringToInt(reward), false);
		SetTrieString(tmpTrie, FIELD_CONTRACT_WEAPON, weapon, false);
		
		PushArrayCell(ARRAY_Contracts, tmpTrie);
		
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);
}

//https://forums.alliedmods.net/showpost.php?p=2457161&postcount=9
stock void GetClientNameForDatabase(Handle db, int client, char[] buffer, int bufferSize) //buffer[2*MAX_NAME_LENGTH+2])??
{
	GetClientName(client, buffer, bufferSize);
	SQL_EscapeString(db, buffer, buffer, bufferSize);
}

stock int GetPlayerCount()
{
	int count = 0;
	for (int i = 0; i < MaxClients; i++)
	{
		if (IsValidClientContract (i))
			count++;
	}
	
	return count;
}

stock void PrintMessageChat(int client, char[] message)
{
	if (engineName == Engine_CSS || engineName == Engine_CSGO)
	{
		char CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
	 
	 	for (int i = 0; i < 6; i++)
			ReplaceString(message, 100, CTag[i], "", false);
			
		PrintToChat(client, message);
	}
	else
	{
		CPrintToChat(client, message);
	}
}

stock bool IsValidClientContract (int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
} 
