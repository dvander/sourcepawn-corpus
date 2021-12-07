#pragma semicolon 1

#define PLUGIN_VERSION "1.01"

#define COLORCHAT

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#if defined COLORCHAT
#include <csgocolors>
#endif

public Plugin myinfo = 
{
	name = "Time Played",
	author = "Deathknife",
	description = "Time Played based of Dr. McKay's Player Analytics",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/Deathknife273/"
};

//[][][] could have been better? + awful variable naming right here
int gFormatTime[] = {
	2628000,
	604800,
	86400,
	3600,
	60
};

char gFormatPlurar[][] = {
	"Months",
	"Weeks",
	"Days",
	"Hours",
	"Minutes",
};

char gFormatSingular[][] = {
	"Month",
	"Week",
	"Day",
	"Hour",
	"Minute"
};

Handle hDatabase = null;

//ConVars 
ConVar hDelay;

float fDelay = 0.0;

//Last time client used timeplayed(to prevent client spamming queries)
float fLastUse[MAXPLAYERS + 1];

public void OnPluginStart() {
	//Register Commands
	RegConsoleCmd("sm_timeplayed", Cmd_TimePlayed, "View your time played!");
	
	//Register convars
	hDelay = CreateConVar("sm_timeplayed_cooldown", "3.0", "Time in seconds between being able to use timeplayed", _, true, 0.0);
	fDelay = hDelay.FloatValue;
	HookConVarChange(hDelay, OnCvarChange);
	//Exec config
	AutoExecConfig();
	
	SQL_TConnect(DB_Connect, "timeplayed");
	
	//Register cookie
	
	//Hookevents
	
	//Late load
	for (int i = 1; i <= MaxClients;i++) {
		if(IsValidClient(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void DB_Connect(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
		//Store handle globally
		hDatabase = hndl;
	}
}

public Action Cmd_TimePlayed(int client, int argc) {
	if(hDatabase == null) {
		#if defined COLORCHAT
		CReplyToCommand(client, "{red}Connection wasn't established yet, please try again later.");
		#else
		ReplyToCommand(client, "Connection wasn't established yet, please try again later.");
		#endif
		return Plugin_Handled;
	}
	
	if(GetGameTime() < fLastUse[client] + fDelay) {
		#if defined COLORCHAT
		CReplyToCommand(client, "{red}Please wait before using this command again.");
		#else
		ReplyToCommand(client, "Please wait before using this command again.");
		#endif
		return Plugin_Handled;
	}
	
	fLastUse[client] = GetGameTime();
	
	//Build the query 
	static char query[1024];
	
	char authid[32];
	GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));
	
	//SELECT SUM(duration) as total,( IF (EXISTS (SELECT * FROM `player_analytics` WHERE auth='STEAM_0:11:1' AND duration IS NULL), MAX(connect_time), -1 ) ) as latest FROM `player_analytics` WHERE auth='STEAM_0:11:1' ORDER BY duration ASC;
	//FormatEx(query, sizeof(query), "SELECT SUM(duration) as total,MAX(connect_time) FROM `player_analytics` WHERE auth='%s'", authid);
	//Send query
	FormatEx(query, sizeof(query), "SELECT SUM(duration) as total,( IF (EXISTS (SELECT * FROM `player_analytics` WHERE auth='%s' AND duration IS NULL), MAX(connect_time), -1 ) ) as latest FROM `player_analytics` WHERE auth='%s'", authid, authid);
	SQL_TQuery(hDatabase, DB_TimePlayed, query, GetClientUserId(client), DBPrio_Low);
	
	return Plugin_Handled;
}

public void DB_TimePlayed(Handle owner, Handle hndl, char[] error, any data) {
	//Make sure client is still in server
	int client = GetClientOfUserId(data);
	if(!IsValidClient(client)) return;
	
	if (hndl == INVALID_HANDLE) {
		LogError("Database failure: %s", error);
	} else {
		while(SQL_FetchRow(hndl)) {
			int iSeconds = SQL_FetchInt(hndl, 0);
			//Shows the time the client joined in current session 
			int iCurrentJoin = SQL_FetchInt(hndl, 1);
			if(iCurrentJoin != -1) {
				//Calculate current time played and add it to seconds
				iSeconds += GetTime() - iCurrentJoin;
			}
			//Format message and print 
			static char TimeMessage[256];
			static char buffer[32];
			TimeMessage[0] = '\0';
			
			//Check if its just in seconds
			if(iSeconds < gFormatTime[sizeof(gFormatTime) - 1]) {
				#if defined COLORCHAT
				FormatEx(buffer, sizeof(buffer), "{green}%i{normal} %s", iSeconds, (iSeconds == 1) ? "Second" : "Seconds");
				#else
				FormatEx(buffer, sizeof(buffer), "%i %s", iSeconds, (iSeconds == 1) ? "Second" : "Seconds");
				#endif
			}else {
				//Loop through array and find any times to use
				for(int i = 0; i < sizeof(gFormatTime); i++) {
					//Check if client played more than that
					int iRequired = gFormatTime[i];
					if(iSeconds > iRequired) {
						int iAmount = iSeconds / iRequired;
						iSeconds = iSeconds % iRequired;
						
						//Beginning of message
						if(TimeMessage[0] == '\0') {
							#if defined COLORCHAT
							FormatEx(TimeMessage, sizeof(TimeMessage), "{green}%i{normal} %s", iAmount, (iAmount == 1) ? gFormatSingular[i] : gFormatPlurar[i]);
							#else
							FormatEx(TimeMessage, sizeof(TimeMessage), "%i %s", iAmount, (iAmount == 1) ? gFormatSingular[i] : gFormatPlurar[i]);
							#endif
						}else {
							//Not beggining of message, so add
							#if defined COLORCHAT
							FormatEx(buffer, sizeof(buffer), ", {green}%i{normal} %s", iAmount, (iAmount == 1) ? gFormatSingular[i] : gFormatPlurar[i]);
							#else
							FormatEx(buffer, sizeof(buffer), ", %i %s", iAmount, (iAmount == 1) ? gFormatSingular[i] : gFormatPlurar[i]);
							#endif
							StrCat(TimeMessage, sizeof(TimeMessage), buffer);
						}
					}
				}
				
				//Add remainder 
				#if defined COLORCHAT
				FormatEx(buffer, sizeof(buffer), " and {green}%i{normal} %s", iSeconds, (iSeconds == 1) ? "Second" : "Seconds");
				#else
				FormatEx(buffer, sizeof(buffer), " and %i %s", iSeconds, (iSeconds == 1) ? "Second" : "Seconds");
				#endif
			}
			
			StrCat(TimeMessage, sizeof(TimeMessage), buffer);
			
			#if defined COLORCHAT
			CPrintToChat(client, "You have played for %s", TimeMessage);
			#else
			PrintToChat(client, "You have played for %s", TimeMessage);
			#endif
		}
	}
}

public void OnCvarChange(Handle hCvar, char[] oldvalue, char[] newvalue) {
	if(hCvar == hDelay) {
		fDelay = StringToFloat(newvalue);
	}
}

public void OnClientPutInServer(int client) {
	fLastUse[client] = -fDelay;
}

stock bool IsValidClient(int client, bool bAlive = false) {
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}