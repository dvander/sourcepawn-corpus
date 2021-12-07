#include <sourcemod>
#include <sdktools>
#include <scp>
#include <multicolors>
#include <hl_cleverbotapi>

#pragma newdecls required

//Plugin Info
#define PLUGIN_TAG			"{purple}[Cleverbot]{default}"
#define PLUGIN_NAME			"[ANY] Cleverbot"
#define PLUGIN_AUTHOR 		"Arkarr"
#define PLUGIN_VERSION 		"1.0"
#define PLUGIN_DESCRIPTION 	"Allow to send messages to cleverbot."
//Database queries
#define QUERY_INIT_DATABASE	"CREATE TABLE IF NOT EXISTS `cleverbot_apikeys` (`apikey` varchar(50) NOT NULL, `usued` int NOT NULL, PRIMARY KEY (`apikey`))"
#define QUERY_LOAD_APIKEY	"SELECT `apikey` FROM cleverbot_apikeys WHERE `usued`=\"0\" LIMIT 1"
#define QUERY_SET_USUED_KEY	"UPDATE `cleverbot_apikeys` SET `usued`=\"1\" WHERE `apikey`=\"%s\""
#define QUERY_RESET_KEYS	"UPDATE `cleverbot_apikeys` SET `usued`=\"0\""
#define QUERY_ADD_API_KEY	"INSERT INTO `cleverbot_apikeys` VALUES (\"%s\", 0)"

Handle DATABASE_APIKeys;
Handle CVAR_DatabaseConfigName;
Handle CVAR_CleverbotName;

char CleverBotAPI[50];
char CleverBotName[20];
char ConvID[MAXPLAYERS + 1][30];
char ClientPreviousMsg[MAXPLAYERS + 1][200]; //I should find a better way of doing it.

bool NoMoreAPIKey;

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
	CVAR_DatabaseConfigName = CreateConVar("cleverbot_database_config", "storage-local", "The name of the configuration of the database in database.cfg");
	CVAR_CleverbotName = CreateConVar("cleverbot_name", "Cleverbot", "The keyword to send cleverbot messages.");

	RegServerCmd("sm_cbmsg", CMD_SendMessage, "Send a message to cleverbot.");
	
	RegAdminCmd("sm_cbaddapikey", CMD_AddAPIKey, ADMFLAG_CONFIG, "Add an api key to the database.");
}

public void OnConfigsExecuted()
{
	char CleverBotDBConf[50];
	
	GetConVarString(CVAR_DatabaseConfigName, CleverBotDBConf, sizeof(CleverBotDBConf));
	GetConVarString(CVAR_CleverbotName, CleverBotName, sizeof(CleverBotName));
	
	SQL_TConnect(GotDatabase, CleverBotDBConf);
}

public void OnClientConnected(int client)
{
	Format(ConvID[client], sizeof(ConvID[]), "");
}

public void CP_OnChatMessagePost(int author, ArrayList recipients, const char[] flagstring, const char[] formatstring, const char[] name, const char[] message, bool processcolors, bool removecolors)
{
	char words[100][20];
	char msg[1980];
	ExplodeString(message, " ", words, sizeof(words), sizeof(words[]));
	
	if(StrContains(words[0], CleverBotName) == -1)
		return;
	
	for (int i = 1; i < 20; i++)
	{
		if(i == 1)
			Format(msg, sizeof(msg), "%s", words[i]);
		else
			Format(msg, sizeof(msg), "%s %s", msg, words[i]);
	}
	
	SendMessage(author, msg);
}

public Action CMD_AddAPIKey(int client, int args)
{
	if(args < 1)
	{
		PrintToServer("Usage : sm_cbaddapikey [API KEY]");
		return Plugin_Handled;
	}
	
	char apikey[150];
	GetCmdArg(1, apikey, sizeof(apikey));
	
	Format(apikey, sizeof(apikey), QUERY_ADD_API_KEY, apikey);
	
	PrintToServer(apikey);
	
	if(client != 0)
	{
		if(SQL_FastQuery(DATABASE_APIKeys, apikey))
			CPrintToChat(client, "%s New key inserted !", PLUGIN_TAG);
		else
			CPrintToChat(client, "%s Adding the new key failed ! Key already exist ?", PLUGIN_TAG);
	}
	else
	{
		if(SQL_FastQuery(DATABASE_APIKeys, apikey))
			PrintToServer("[Cleverbot] New key inserted !");
		else
			PrintToServer("[Cleverbot] Adding the new key failed ! Key already exist ?");
	}
		
	return Plugin_Handled;
}

public Action CMD_SendMessage(int args)
{	
	if(args < 1)
	{
		PrintToServer("Usage : sm_cbmsg [MESSAGE]");
		return Plugin_Handled;
	}
	
	char msg[200];
	GetCmdArgString(msg, sizeof(msg));
	
	SendMessage(0, msg);
	
	return Plugin_Handled;
}

//functions
public void SendMessage(int client, char[] msg)
{
	if(NoMoreAPIKey)
	{
	    if(client == 0)
	    	PrintToServer("[Cleverbot] I'm out of API key, try later.");
	    else
	    	CPrintToChat(client, "%s %s", PLUGIN_TAG, "I'm out of API key, try later.");
	}
	else
	{
		CleverBot_SendRequest(CleverBotAPI, msg, CleverBot_Callback, ConvID[client], client);
		Format(ClientPreviousMsg[client], sizeof(ClientPreviousMsg[]), msg);
	}
}

//Cleverbot stuff

public void CleverBot_Callback(char[] response, char[] conversationID, ArrayList chatHistory, StatusCode statusCode, int client, int randomNumber)
{
    if (statusCode != StatusCode_Success)
    {
    	if(statusCode == StatusCode_InvalidAPIKey)
    	{
    		//Not sure if I should save the conversation ID here...
    		
    		char query[100];
    		Format(query, sizeof(query), QUERY_SET_USUED_KEY, CleverBotAPI);
    		SQL_FastQuery(DATABASE_APIKeys, query);
    		
    		if(client == 0)
    			SQL_TQuery(DATABASE_APIKeys, T_GetApiKey, QUERY_LOAD_APIKEY, 0);
			else
    			SQL_TQuery(DATABASE_APIKeys, T_GetApiKey, QUERY_LOAD_APIKEY, GetClientUserId(client));
   		}
   		else
   		{
	        char errorString[128];
	        CleverBot_GetErrorLogString(statusCode, errorString, sizeof(errorString));
	        LogError("CleverBot API Error (%d) : %s", statusCode, errorString);
	        
    		CPrintToChat(client, "%s %s", PLUGIN_TAG, "Sorry, I ran into a problem. Please, contact a server administrator.");
      	}
    }
    else
    {
	    if (client != 0 && !IsClientInGame(client))
	        return;
	
	    Format(ConvID[client], sizeof(ConvID[]), conversationID);
	    
	    if(client == 0)
	    	PrintToServer("[Cleverbot] %s", response);
	    else
	    	CPrintToChat(client, "%s %s", PLUGIN_TAG, response);
    }
}

//Database sutff
public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("%s", error);
		return;
	}
	
	DATABASE_APIKeys = hndl;
	
	char buffer[300];
	if (!SQL_FastQuery(DATABASE_APIKeys, QUERY_INIT_DATABASE))
	{
		SQL_GetError(DATABASE_APIKeys, buffer, sizeof(buffer));
		SetFailState("%s", buffer);
	}
	
	char today[10];
	FormatTime(today, sizeof(today), "%d");
	
	if(StringToInt(today) == 3)
	{
		PrintToServer("Reseting API keys...");
		SQL_FastQuery(DATABASE_APIKeys, QUERY_RESET_KEYS);
	}
	
	SQL_TQuery(DATABASE_APIKeys, T_GetApiKey, QUERY_LOAD_APIKEY);
}

public void T_GetApiKey(Handle db, Handle results, const char[] error, any data)
{
	if (DATABASE_APIKeys == INVALID_HANDLE)
		return;
	
	if (!SQL_FetchRow(results))
	{
		NoMoreAPIKey = true;
	}
	else
	{
		SQL_FetchString(results, 0, CleverBotAPI, sizeof(CleverBotAPI));
		
		NoMoreAPIKey = false;
		
		int client = GetClientOfUserId(data);
		
		if (client != 0 && !IsClientInGame(client))
			SendMessage(client, ClientPreviousMsg[client]);
	}
}