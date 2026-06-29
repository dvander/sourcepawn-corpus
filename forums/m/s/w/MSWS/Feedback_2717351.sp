#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define STEAM_LENGTH 64

public Plugin myinfo =  {
	name = "Feedback", 
	author = "MSWS", 
	description = "Anonymous Feedback System", 
	version = "1.0", 
	url = "https://msws.xyz"
};

enum Feedback {
	DISLIKE, 
	LIKE
}

int g_Cooldowns[MAXPLAYERS + 1][MAXPLAYERS + 1][2]; // [Client][Target][Dislike/Like]
int g_SimpleCooldowns[MAXPLAYERS + 1];
char g_Aliases[MAXPLAYERS + 1][STEAM_LENGTH];

ConVar g_ConCooldownLike, g_ConCooldownDislike, g_ConCooldownShare, g_ConCooldownGlobal, g_ConCooldownSimple;

Database g_Data;

bool g_Lite;

public void OnPluginStart() {
	RegConsoleCmd("sm_like", Command_Like, "Anonymously share some positive feedback towards a player");
	RegConsoleCmd("sm_dislike", Command_Dislike, "Anonymously share some negative feedback on a player");
	RegAdminCmd("sm_clearfeedback", Command_ClearFeedback, ADMFLAG_ROOT, "DELETES ALL Feedback given TO the target");
	RegAdminCmd("sm_deletefeedback", Command_DeleteFeedback, ADMFLAG_ROOT, "DELETES ALL Feedback given FROM the target");
	
	g_ConCooldownLike = CreateConVar("sm_cooldown_like", "300", "Seconds of delay between being able to use sm_like");
	g_ConCooldownDislike = CreateConVar("sm_cooldown_dislike", "300", "Seconds of delay between being able to use sm_dislike");
	g_ConCooldownShare = CreateConVar("sm_cooldown_shared", "0", "If 1, both sm_like and sm_dislike will be under the same cooldown");
	g_ConCooldownGlobal = CreateConVar("sm_cooldown_global", "0", "If 1, cooldown is for giving feedback to any player instead of the same player");
	g_ConCooldownSimple = CreateConVar("sm_cooldown_simple", "0", "If not 0, the cooldown does not sync with database, is global, and shared");
	
	AutoExecConfig();
	
	assignAliases();
	
	LoadTranslations("common.phrases");
	Database.Connect(ConnectedCreateTables, "feedback");
}

/**
* Responsible for ensuring connection to the database and creating the tables, once
* tables have been created (and database connected), loads player cooldowns.
*/
public void ConnectedCreateTables(Database db, const char[] error, any data) {
	if (db == null) {
		LogError("Could not connect to database: %s", error);
		return;
	}
	
	g_Data = db;
	DBDriver driver = g_Data.Driver;
	char[] sDriver = new char[10];
	
	driver.GetIdentifier(sDriver, 10);
	
	g_Lite = StrEqual(sDriver, "sqlite", false);
	
	g_Data.Query(EmptyQuery, g_Lite ? "CREATE TABLE IF NOT EXISTS PlayerFeedback(feedback INTEGER, player BIGINT, target BIGINT, message TEXT, timestamp INTEGER, UNIQUE(player, target));" : \
		"CREATE TABLE IF NOT EXISTS PlayerFeedback(feedback INTEGER, player BIGINT, target BIGINT, message TEXT, timestamp INTEGER, UNIQUE(player, target));");
	
	loadAllCooldowns();
}

/**
* A dummy query for database interactions that don't involve results
*/
public void EmptyQuery(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("An error occoured while executing a SQL Query: %s", error);
	}
}

public Action Command_Like(int client, int args) {
	HandleFeedback(client, args, LIKE);
	return Plugin_Handled;
}

public Action Command_Dislike(int client, int args) {
	HandleFeedback(client, args, DISLIKE);
	return Plugin_Handled;
}

public Action Command_ClearFeedback(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_clearfeedback <Steam64>");
		return Plugin_Handled;
	}
	
	if (g_Data == null) {
		ReplyToCommand(client, "[SM] The database is offline.");
		return Plugin_Handled;
	}
	
	char alias[32];
	GetCmdArg(1, alias, sizeof(alias));
	
	char msg[1024];
	char name[MAX_NAME_LENGTH];
	
	GetClientName(client, name, sizeof(name));
	
	g_Data.Format(msg, sizeof(msg), "DELETE FROM PlayerFeedback WHERE target = '%s';", alias);
	g_Data.Query(OnClientFeedbackClear, msg);
	
	LogAction(client, -1, "%L cleared all feedback from %s", client, alias);
	ShowActivity2(client, "[SM] ", "cleared all feedback from %s.", alias);
	
	return Plugin_Handled;
}

public Action Command_DeleteFeedback(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_deletefeedback <Steam64>");
		return Plugin_Handled;
	}
	
	if (g_Data == null) {
		ReplyToCommand(client, "[SM] The database is offline.");
		return Plugin_Handled;
	}
	
	char alias[32];
	GetCmdArg(1, alias, sizeof(alias));
	
	char msg[1024];
	char name[MAX_NAME_LENGTH];
	
	GetClientName(client, name, sizeof(name));
	
	g_Data.Format(msg, sizeof(msg), "DELETE FROM PlayerFeedback WHERE player = '%s';", alias);
	g_Data.Query(OnClientFeedbackDelete, msg);
	
	LogAction(client, -1, "%L deleted all feedback of %s", client, alias);
	ShowActivity2(client, "[SM] ", "deleted all feedback of %s.", alias);
	return Plugin_Handled;
}

public void OnClientFeedbackDelete(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("An error occured when deleting a player's feedback: %s", error);
		return;
	}
	LogError("Successfully deleted %d feedback%s of a player.", results.AffectedRows, results.AffectedRows == 1 ? "":"s");
}

public void OnClientFeedbackClear(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("An error occured when clearing a player's feedback: %s", error);
		return;
	}
	LogError("Successfully cleared %d feedback%s on a player.", results.AffectedRows, results.AffectedRows == 1 ? "":"s");
}

/**
* Combines liking and disliking to prevent unnecessary duplicate code
*/
public void HandleFeedback(int client, int args, Feedback type) {
	char cmd[32];
	
	Format(cmd, sizeof(cmd), "sm_%s", type ? "like":"dislike");
	//if (!CheckCommandAccess(client, "sm_repaccess", ADMFLAG_CUSTOM1)) {
	//ReplyToCommand(client, "[SM] You must be a DEFY Member to give feedback on other players.");
	//return;
	//}
	
	if (client <= 0 || !IsClientConnected(client) || IsFakeClient(client)) {
		ReplyToCommand(client, "[SM] You are currently unable to run this command.");
		return;
	}
	
	if (args < 2) {
		ReplyToCommand(client, "[SM] Usage: %s <#userid|name> <Message>", cmd);
		return;
	}
	
	char targetStr[32];
	GetCmdArg(1, targetStr, sizeof(targetStr));
	
	int targets[MAXPLAYERS + 1];
	char name[32];
	bool ml;
	int size = ProcessTargetString(targetStr, client, targets, MAXPLAYERS + 1, COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS, name, sizeof(name), ml);
	if (size != 1) {
		ReplyToTargetError(client, size);
		return;
	}
	
	int target = targets[0];
	
	if (!checkCooldown(DISLIKE, client, target)) {
		return;
	}
	
	if (target == client) {
		ReplyToCommand(client, "[SM] You cannot provide feedback on yourself.");
		return;
	}
	
	char calias[STEAM_LENGTH], talias[STEAM_LENGTH];
	if (!GetClientAuthId(client, AuthId_SteamID64, calias, sizeof(calias)) || !GetClientAuthId(target, AuthId_SteamID64, talias, sizeof(talias))) {
		ReplyToCommand(client, "[SM] Providing feedback is temporarily disabled");
		return;
	}
	
	char wholeMessage[256];
	char message[256];
	GetCmdArgString(wholeMessage, sizeof(wholeMessage));
	int start = SplitString(wholeMessage, " ", message, sizeof(message));
	int index = 0;
	for (int i = start; i < sizeof(wholeMessage); i++) {
		if (!wholeMessage[i])
			break;
		message[index] = wholeMessage[i];
		index++;
	}
	
	ReplyToCommand(client, addComment(client, target, calias, talias, type, message) ? "[SM] Your feedback has been recorded, thank you!":"[SM] An error occured while handling your feedback.");
	return;
}

/**
* Checks if the specified client may leave a like on the specified target
* @param type The Feedback type to check
* @param client The client whose cooldown to check
* @param target The target that the client is trying to give feedback to
* @param verbose If true, failure will send an error message to the target
*/
bool checkCooldown(Feedback type, int client, int target, bool verbose = true) {
	if (g_ConCooldownSimple.IntValue) {
		if (GetTime() - g_SimpleCooldowns[client] < g_ConCooldownSimple.IntValue) {
			if (!verbose)
				return false;
			char msg[32];
			FormatSeconds(g_ConCooldownSimple.IntValue - (GetTime() - g_SimpleCooldowns[client]), msg, sizeof(msg));
			ReplyToCommand(client, "[SM] You cannot give feedback for %s.", msg);
			return false;
		}
		return true;
	}
	
	type = g_ConCooldownShare.BoolValue ? LIKE : type;
	int cd = type ? g_ConCooldownLike.IntValue : g_ConCooldownDislike.IntValue;
	
	if (g_ConCooldownGlobal.BoolValue) {
		int high = 0;
		
		// Get the most recent cooldown from all players
		for (int i = 1; i < MAXPLAYERS; i++) {
			if (g_Cooldowns[client][i][type] > high) {
				high = g_Cooldowns[client][i][type];
			}
		}
		
		if (GetTime() - high < cd) {
			if (!verbose)
				return false;
			char msg[32];
			FormatSeconds(cd - (GetTime() - high), msg, sizeof(msg));
			ReplyToCommand(client, g_ConCooldownShare.BoolValue ? "[SM] You cannot give feedback for %s." : \
				"[SM] You cannot give that type of feedback for %s.", msg);
			return false;
		}
		return true;
	}
	
	if (GetTime() - g_Cooldowns[client][target][type] < cd) {
		if (!verbose)
			return false;
		char msg[32];
		FormatSeconds(cd - (GetTime() - g_Cooldowns[client][target][type]), msg, sizeof(msg));
		ReplyToCommand(client, g_ConCooldownShare.BoolValue ? "[SM] You cannot give this player feedback for %s." : \
			"[SM] You cannot give that player that type of feedback for %s.", msg);
		
		return false;
	}
	return true;
}

/**
* Formats the buffer with the specified duration using .2f seconds, minutes, hours, or days.
*
* @param seconds The amount of seconds in the timespan
* @param buffer The buffer to store the result in
* @param length The max length of the buffer
*/
void FormatSeconds(int seconds, char[] buffer, int length) {
	if (seconds < 60) {
		Format(buffer, length, "%d second%s", seconds, seconds == 1 ? "":"s");
	} else if (seconds < 60 * 60) {
		Format(buffer, length, "%.2f minute%s", seconds / 60.0, seconds / 60.0 == 1 ? "":"s");
	} else if (seconds < 60 * 60 * 24) {
		Format(buffer, length, "%.2f hours%s", seconds / 60.0 / 60.0, seconds / 60.0 / 60.0 == 1 ? "":"s");
	} else {
		Format(buffer, length, "%.2f day%s", seconds / 60.0 / 60.0 / 24.0, seconds / 60.0 / 60.0 / 24.0 == 1 ? "":"s");
	}
}

/**
* Resets cooldowns and cache
*/
public void OnClientDisconnect(int client) {
	for (int i = 1; i < MAXPLAYERS; i++) {
		g_Cooldowns[client][i][0] = 0;
		g_Cooldowns[client][i][1] = 0;
	}
	
	for (int i = 0; i < STEAM_LENGTH; i++) {
		g_Aliases[client][i] = 0;
	}
}

/**
* Syncs cache and loads cooldowns
*/
public void OnClientConnected(int client) {
	char alias[STEAM_LENGTH];
	GetClientAuthId(client, AuthId_SteamID64, alias, sizeof(alias));
	Format(g_Aliases[client], STEAM_LENGTH, "%s", alias);
	loadCooldown(client);
}

/**
* Assigns all online players to the Steam64 cache, useful for debugging.
*/
public void assignAliases() {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!IsClientConnected(i))
			continue;
		if (IsFakeClient(i))
			continue;
		char alias[STEAM_LENGTH];
		GetClientAuthId(i, AuthId_SteamID64, alias, sizeof(alias));
		//g_Aliases[i] = StringToInt(alias);
		Format(g_Aliases[i], STEAM_LENGTH, "%s", alias);
	}
}

/**
* Loads all online player's cooldowns, useful for debugging.
*/
public void loadAllCooldowns() {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!IsClientConnected(i))
			continue;
		if (IsFakeClient(i))
			continue;
		loadCooldown(i);
	}
}

/**
* Queries and stores the cooldowns of the specified client
*
* @param client The client whose cooldowns to grab
*/
void loadCooldown(int client) {
	if (g_Data == null)
		return;
	if (g_ConCooldownSimple.IntValue)
		return;
	
	char alias[STEAM_LENGTH];
	GetClientAuthId(client, AuthId_SteamID64, alias, sizeof(alias));
	
	char query[1024];
	g_Data.Format(query, sizeof(query), "SELECT feedback, player, target, timestamp FROM PlayerFeedback WHERE player = '%s';", alias);
	g_Data.Query(OnPlayerSQLLoad, query);
}

/**
* Responsible for parsing and storing the fetched data once its been queried.
*/
public void OnPlayerSQLLoad(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("An error occured when attempting to get player feedback: %s", error);
		return;
	}
	
	for (int i = 0; i < results.RowCount; i++) {
		if (!results.FetchRow())
			break;
		bool positive = results.FetchInt(0) == 1;
		char clientAlias[32]; results.FetchString(1, clientAlias, sizeof(clientAlias));
		char targetAlias[32]; results.FetchString(2, targetAlias, sizeof(targetAlias));
		int time = results.FetchInt(3);
		
		int client = getClientID(clientAlias);
		int target = getClientID(targetAlias);
		if (client == -1 || target == -1)
			continue;
		
		char msg[32];
		FormatSeconds(GetTime() - time, msg, sizeof(msg));
		
		g_Cooldowns[client][target][positive] = time;
	}
	
}

/**
* Retrieves the cached client index of the Steam64 ID
*
* @param alias The Steam64 ID to lookup
* @returns The client index or -1 if not found
*/
int getClientID(const char[] alias) {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (StrEqual(g_Aliases[i], alias))
			return i;
	}
	
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!IsClientConnected(i))
			continue;
		if (IsFakeClient(i))
			continue;
		char al[STEAM_LENGTH];
		GetClientAuthId(i, AuthId_SteamID64, al, sizeof(al));
		if (StrEqual(al, alias)) {
			Format(g_Aliases[i], STEAM_LENGTH, "%s", alias);
			return i;
		}
	}
	
	LogError("Attempted to get an offline player's index from Steam 64 ID %s", alias);
	return -1;
}

/**
* Queries and updates the database and sets updates the cooldown
* 
* @param clientId The player id of the client
* @param targetId The player id of the target
* @param client64 The Steam64 ID of the client
* @param target64 The Steam64 ID of the target
* @param type The type of feedback (LIKE/DISLIKE)
* @param message The message given by the client
*/
bool addComment(int clientId, int targetId, const char[] client64, const char[] target64, Feedback type, char[] message) {
	if (clientId <= 0 || targetId <= 0 || g_Data == null)
		return false;
	
	LogAction(clientId, targetId, "%L %s %L, message: %s", clientId, type ? "liked":"disliked", targetId, message);
	
	if (g_ConCooldownSimple.IntValue)
		g_SimpleCooldowns[clientId] = GetTime();
	else
		g_Cooldowns[clientId][targetId][type] = GetTime();
	
	char buffer[1024];
	
	g_Data.Format(buffer, sizeof(buffer), "REPLACE INTO PlayerFeedback (feedback, player, target, message, timestamp) VALUES (%d, %s, %s, '%s', %d);", type, client64, target64, message, GetTime());
	
	g_Data.Query(EmptyQuery, buffer);
	return true;
} 