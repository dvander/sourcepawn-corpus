#include <sourcemod>
#include <sdktools>
#include <bank>

#pragma newdecls required

//Plugin Info
#define PLUGIN_TAG			"[Bank]"
#define PLUGIN_NAME			"[ANY] Bank"
#define PLUGIN_AUTHOR 		"Arkarr"
#define PLUGIN_VERSION 		"1.0"
#define PLUGIN_DESCRIPTION 	"A simple bank system where you can store money."
//Database
#define QUERY_INIT_DB_TCLIENTS		"CREATE TABLE IF NOT EXISTS `clients` (`clientID` int NOT NULL AUTO_INCREMENT, `steamid` varchar(45) NOT NULL, `credits` int NOT NULL, `bankID` int NOT NULL, PRIMARY KEY (`clientID`))"
#define QUERY_INIT_DB_TBANKS		"CREATE TABLE IF NOT EXISTS `banks` (`bankID` int NOT NULL AUTO_INCREMENT,  `name` varchar(50) NOT NULL, PRIMARY KEY (`bankID`))"
#define QUERY_CREATE_BANK			"INSERT INTO `banks` (name) VALUES ('%s')"
#define QUERY_SELECT_BANKS			"SELECT * FROM `banks`"
#define QUERY_SELECT_CLIENT_BANK	"SELECT * FROM `clients` WHERE steamid='%s' AND bankID=%i"
#define QUERY_ADD_CLIENT_TO_BANK	"INSERT INTO `clients` (steamid, credits, bankID) VALUES ('%s', '0', %i)"
#define QUERY_UPDATE_CLIENT_CREDITS	"UPDATE `clients` SET credits='%i' WHERE steamid='%s' AND bankID=%i"

Handle DATABASE_Banks;
//Handle FORWARD_DatabaseReady;

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
   //FORWARD_DatabaseReady = CreateGlobalForward("Bank_DatabaseReady", ET_Event)
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{   
   	CreateNative("Bank_Create", Native_BankCreate);
	CreateNative("Bank_GetBalance", Native_BankGetBalance);
	CreateNative("Bank_SetBalance", Native_BankSetBalance);
	CreateNative("Bank_SetBalanceSteam", Native_BankSetBalanceSteam);
	CreateNative("Bank_EditBalance", Native_BankEditBalance);
	
	RegPluginLibrary("Bank");
   
	SQL_TConnect(DBConResult, "Bank");
   
	return APLRes_Success;
}

//Database init

public void DBConResult(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	else
	{
		DATABASE_Banks = hndl;
		
		char buffer[300];
		if (!SQL_FastQuery(DATABASE_Banks, QUERY_INIT_DB_TCLIENTS) || !SQL_FastQuery(DATABASE_Banks, QUERY_INIT_DB_TBANKS))
		{
			SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
			SetFailState(buffer);
		}
		/*else
		{
			Call_StartForward(FORWARD_DatabaseReady);
	  	}*/
	}
}

//Natives

public int Native_BankCreate(Handle plugin, int numParams)
{
	char buffer[300];
	char strBankName[128];
	GetNativeString(1, strBankName, sizeof(strBankName));
		
	if(BankExist(strBankName))
	{
		Format(buffer, sizeof(buffer), "Bank %s already exist !", strBankName);
		PrintErrorMessage(buffer);
		
		return false;
	}
	
	Format(buffer, sizeof(buffer), QUERY_CREATE_BANK, strBankName);
	if (!SQL_FastQuery(DATABASE_Banks, buffer))
	{
		SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
		PrintErrorMessage(buffer);
		
		return false;
	}
	
	return true;
}

public int Native_BankEditBalance(Handle plugin, int numParams)
{
	char steamID[50];
	char buffer[200];
	char strBankName[128];
	
	GetNativeString(1, strBankName, sizeof(strBankName));
	int client = GetNativeCell(2);
	int ammount = GetNativeCell(3);
	bool create = GetNativeCell(4);
	
	int bankID = GetBankID(strBankName)
	if(bankID == -1)
	{
		Format(buffer, sizeof(buffer), "Bank %s doesn't exist !", strBankName);
		PrintErrorMessage(buffer);
		return false;
	}
	
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
	Handle TRIE_Client = ClientFromBank(client, strBankName);
	
	int clientID;
	GetTrieValue(TRIE_Client, "ID", clientID);
	if(clientID == -1 || clientID == 0)
	{
		if(!create)
		{
			Format(buffer, sizeof(buffer), "User not in bank %s !", strBankName);
			PrintErrorMessage(buffer);
			return false;
		}
		else
		{
			Format(buffer, sizeof(buffer), QUERY_ADD_CLIENT_TO_BANK, steamID, bankID);
			if (!SQL_FastQuery(DATABASE_Banks, buffer))
			{
				SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
				PrintErrorMessage(buffer);
				
				return false;
			}
		}
	}
	
	int credits;
	GetTrieValue(TRIE_Client, "credits", credits);
	credits += ammount;
	delete TRIE_Client;
	
	Format(buffer, sizeof(buffer), QUERY_UPDATE_CLIENT_CREDITS, credits, steamID, bankID);
	if (!SQL_FastQuery(DATABASE_Banks, buffer))
	{
		SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
		PrintErrorMessage(buffer);
		
		return false;
	}
	
	return true;
}

public int Native_BankGetBalance(Handle plugin, int numParams)
{
	char strBankName[128];
	
	GetNativeString(1, strBankName, sizeof(strBankName));
	int client = GetNativeCell(2);
	
	Handle clientInfos = ClientFromBank(client, strBankName);
	
	if(clientInfos == INVALID_HANDLE)
	{
		return -1;
	}
	else
	{
		int credits;
		GetTrieValue(clientInfos, "credits", credits);
		delete clientInfos;
		return credits;
	}
}

public int Native_BankSetBalance(Handle plugin, int numParams)
{
	char steamID[50];
	char buffer[200];
	char strBankName[128];
	
	GetNativeString(1, strBankName, sizeof(strBankName));
	int client = GetNativeCell(2);
	int ammount = GetNativeCell(3);
	bool create = GetNativeCell(4);
	
	int bankID = GetBankID(strBankName)
	if(bankID == -1)
	{
		Format(buffer, sizeof(buffer), "Bank %s doesn't exist !", strBankName);
		PrintErrorMessage(buffer);
		return false;
	}
	
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
	Handle TRIE_Client = ClientFromBank(client, strBankName);
	
	int clientID;
	GetTrieValue(TRIE_Client, "ID", clientID);
	delete TRIE_Client;
	if(clientID == -1 || clientID == 0)
	{
		if(!create)
		{
			Format(buffer, sizeof(buffer), "User not in bank %s !", strBankName);
			PrintErrorMessage(buffer);
			return false;
		}
		else
		{
			Format(buffer, sizeof(buffer), QUERY_ADD_CLIENT_TO_BANK, steamID, bankID);
			if (!SQL_FastQuery(DATABASE_Banks, buffer))
			{
				SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
				PrintErrorMessage(buffer);
				
				return false;
			}
		}
	}
	
	Format(buffer, sizeof(buffer), QUERY_UPDATE_CLIENT_CREDITS, ammount, steamID, bankID);
	if (!SQL_FastQuery(DATABASE_Banks, buffer))
	{
		SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
		PrintErrorMessage(buffer);
		
		return false;
	}
	
	return true;
}

public int Native_BankSetBalanceSteam(Handle plugin, int numParams)
{
	char steamID[50];
	char buffer[200];
	char strBankName[128];
	
	GetNativeString(1, strBankName, sizeof(strBankName));
	GetNativeString(2, steamID, sizeof(steamID));
	int ammount = GetNativeCell(3);
	
	int bankID = GetBankID(strBankName)
	if(bankID == -1)
	{
		Format(buffer, sizeof(buffer), "Bank %s doesn't exist !", strBankName);
		PrintErrorMessage(buffer);
		return false;
	}
	
	Format(buffer, sizeof(buffer), QUERY_UPDATE_CLIENT_CREDITS, ammount, steamID, bankID);
	if (!SQL_FastQuery(DATABASE_Banks, buffer))
	{
		SQL_GetError(DATABASE_Banks, buffer, sizeof(buffer));
		PrintErrorMessage(buffer);
		
		return false;
	}
	
	return true;
}

//Helper function

stock Handle ClientFromBank(int client, const char[] strBankName)
{
	char dbquery[100];
	char steamID[50];
	
	Handle TRIE_Client = CreateTrie();
	
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
	Format(dbquery, sizeof(dbquery), QUERY_SELECT_CLIENT_BANK, steamID, GetBankID(strBankName));

	DBResultSet query = SQL_Query(DATABASE_Banks, dbquery);
	if (query == null)
	{
		char error[255];
		SQL_GetError(DATABASE_Banks, error, sizeof(error));
		SetFailState(error);
		
		return INVALID_HANDLE;
	} 
	else 
	{
		SetTrieValue(TRIE_Client, "credits", -1);
		while (SQL_FetchRow(query))
		{
			SetTrieValue(TRIE_Client, "ID", SQL_FetchInt(query, 0));
			SetTrieString(TRIE_Client, "steamid", steamID);
			SetTrieValue(TRIE_Client, "credits", SQL_FetchInt(query, 2), true);
			SetTrieValue(TRIE_Client, "bankID", SQL_FetchInt(query, 3));
		}
		
		delete query;
	}
	
	return TRIE_Client;
}

stock int GetBankID(const char[] strBankName)
{
	int bankID = -1;
	DBResultSet query = SQL_Query(DATABASE_Banks, QUERY_SELECT_BANKS);
	if (query == null)
	{
		char error[255];
		SQL_GetError(DATABASE_Banks, error, sizeof(error));
		SetFailState(error);
		
		return false;
	} 
	else 
	{
		char bankName[45];
		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 1, bankName, sizeof(bankName));
			if(StrEqual(strBankName, bankName))
				bankID = SQL_FetchInt(query, 0);
		}
		
		delete query;
	}
	
	return bankID;
}

stock bool BankExist(const char[] strBankName)
{
	return GetBankID(strBankName) > 0 ? true : false;
}

stock void PrintErrorMessage(const char[] msg)
{
	PrintToServer("%s - ERROR - %s", PLUGIN_TAG, msg);
}