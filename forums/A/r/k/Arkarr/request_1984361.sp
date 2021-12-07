#include <sourcemod>
#include <morecolors>

new Handle:g_delay;
new Handle:g_message;
new Handle:g_message_delay;
new Handle:g_command;
new Handle:g_save_path;
new Handle:g_useDatabase;
new Handle:timer_ad = INVALID_HANDLE;
new Handle:secCounter[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:DatabaseConnection;
new bool:requested[MAXPLAYERS + 1];
new bool:IsDatabaseActive;
new String:ad[900];
new String:plugintag[30] = "{lightgreen}[Request] {default}";
new secs[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Player Request",
	author = "Arkarr",
	description = "Players can send request.",
	version = "2.0",
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	g_delay = CreateConVar("sm_time_before_request","30.0","Time before a player can do another request.", _, true, 0.1);
	g_message = CreateConVar("sm_request_message","Do you want give us a feedback about our server ? Type /request !","Text of request advertissement.");
	g_message_delay = CreateConVar("sm_request_message_delay","45.0","Display the advertissmenet message every X seconds", _, true, 0.0);
	g_command = CreateConVar("sm_custom_command","feedback,request,ask,rq", "What should be the command for the plugin ?");
	g_save_path = CreateConVar("sm_save_path", "configs/request.txt", "Save path of the log file, BASED ON THE SOURCEMOD FOLDER !");
	g_useDatabase = CreateConVar("sm_use_database", "1", "Set if the plugin should save request in database or in a text file. Take effect only on map restart !");
	
	HookConVarChange(g_message_delay, OnTimerTimeChange);
	
	AutoExecConfig(true, "request");
	
	if(GetConVarInt(g_useDatabase) == 1)
	{
		IsDatabaseActive = true;
		SQL_TConnect(GotDatabase, "Request");
	}
	else
	{
		IsDatabaseActive = false;
	}
}

public OnConfigsExecuted()
{
	timer_ad = CreateTimer(GetConVarFloat(g_message_delay), AdTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public GotDatabase(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("[Request] Error with database : %s", error);
	}
	else
	{
		PrintToServer("[Request] Successfully connected to the database !");
		DatabaseConnection = hndl;
		ExecuteQuery(DatabaseConnection, "CREATE TABLE IF NOT EXISTS request (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY, playername VARCHAR(40) NOT NULL, steamid VARCHAR(40) NOT NULL, datevar VARCHAR(40) NOT NULL, timevar VARCHAR(40) NOT NULL, request VARCHAR(200) NOT NULL)");
	}
}

public OnTimerTimeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(timer_ad != INVALID_HANDLE)
	{
		KillTimer(timer_ad);
		timer_ad = INVALID_HANDLE;
	}
	
	timer_ad = CreateTimer(GetConVarFloat(g_message_delay), AdTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientPutInServer(client)
{
	requested[client] = false;
}

public Action:OnChatMessage(&client, Handle:recipients, String:name[], String:message[])
{
	decl String:cmdConvar[500], String:chatCmd[1][30];
	GetConVarString(g_command, cmdConvar, sizeof(cmdConvar));
	ExplodeString(message, " ", chatCmd, sizeof chatCmd, sizeof chatCmd[]);
	PrintToServer("Full %s Command %s", chatCmd[0], message);
	if(StrContains(cmdConvar, chatCmd[0]) != -1 && !requested[client])
		ProcessRequest(client, message, IsDatabaseActive);
	/*else
		PrintHintText(client, "%sYou need to wait %i before sending a nother request !", "[Request]",secs[client]);*/
}

public Action:CountSec(Handle:timer, any:user)  
{
	if(secs[user] >= 1)
	{
		secs[user]--;
	}
	else
	{
		if(secCounter[user] != INVALID_HANDLE)
		{
			KillTimer(secCounter[user]);
			secCounter[user] = INVALID_HANDLE;
		}
		requested[user] = false;
	}
}

public Action:AdTimer(Handle:timer, any:user)  
{
	GetConVarString(g_message, ad, sizeof(ad));
	CPrintToChatAll("%s%s", plugintag, ad);
}

stock ProcessRequest(client, const String:request[], bool:UseDatabase)
{
	if(IsValidClient(client))
	{
		decl String:playername[50], String:steamid[50], String:datevar[50], String:timevar[50];
		
		GetClientName(client, playername, 50);
		GetClientAuthString(client, steamid, 50);
		FormatTime(datevar, 50, "%m/%d/%Y");
		FormatTime(timevar, 50, "%H:%M:%S");
		
		if(UseDatabase)
		{
			decl String:sql[400];
			Format(sql, sizeof(sql), "INSERT INTO request (`steamid`, `playername`, `datevar`, `timevar`, `request`) VALUES ('%s','%s','%s','%s','%s')", steamid, playername, datevar, timevar, request);
			ExecuteQuery(DatabaseConnection, sql);
			requested[client] = true;
		}
		else
		{
			requested[client] = false;
			decl String:configFile[PLATFORM_MAX_PATH], String:savePath[100];
			GetConVarString(g_save_path, savePath, sizeof(savePath));
			BuildPath(Path_SM, configFile, sizeof(configFile), savePath);
			new Handle:file = OpenFile(configFile, "at+");
			if(file != INVALID_HANDLE)
			{
				WriteFileLine(file, "-----------------------");
				WriteFileLine(file, "Name : %s", playername);
				WriteFileLine(file, "Steam ID : %s", steamid);
				WriteFileLine(file, "Request : %s", request);
				WriteFileLine(file, "The %s at %s", datevar, timevar);
				WriteFileLine(file, "-----------------------");
				WriteFileLine(file, "");
				CloseHandle(file);
				
				//CPrintToChat(client, "%sRequest send ! Thanks for playing on our server !", plugintag);
				secs[client] = GetConVarInt(g_delay);
				secCounter[client] = CreateTimer(1.0, CountSec, client, TIMER_REPEAT);
				requested[client] = true;
			}
			else
			{
				return false;
			}
		}
		return true;
	}
	return false;
}

stock bool:ExecuteQuery(Handle:db, const String:query[])
{
	if (!SQL_FastQuery(db, query))
	{
		new String:error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[Request] ERROR: %s", error);
		return false;
	}
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}