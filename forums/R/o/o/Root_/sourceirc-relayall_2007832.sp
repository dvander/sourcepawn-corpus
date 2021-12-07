/*
       This file is part of SourceIRC.

    SourceIRC is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SourceIRC is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SourceIRC.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <regex>
#undef REQUIRE_PLUGIN
#include <sourceirc>

new g_userid = 0;

new bool:g_isteam = false;

public Plugin:myinfo = {
	name = "SourceIRC -> Relay All",
	author = "Azelphur",
	description = "Relays various game events",
	version = IRC_VERSION,
	url = "http://azelphur.com/"
};

public OnPluginStart() {	
	RegConsoleCmd("me", Command_Me);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Post);
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
	HookEvent("player_chat", Event_PlayerSay, EventHookMode_Post);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);

	LoadTranslations("sourceirc.phrases");
}

public OnAllPluginsLoaded() {
	if (LibraryExists("sourceirc"))
		IRC_Loaded();
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "sourceirc"))
		IRC_Loaded();
}

IRC_Loaded() {
	IRC_CleanUp(); // Call IRC_CleanUp as this function can be called more than once.
	IRC_RegAdminCmd("msg", Command_Msg, ADMFLAG_CHAT, "msg <message> - send a message to server");
	IRC_HookEvent("PRIVMSG", Event_PRIVMSG);
}

public Action:Command_Msg(const String:nick[], args) {
	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: msg <message>");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_Say(client, args) {
	g_isteam = false; // Ugly hack to get around player_chat event not working.
}

public Action:Command_SayTeam(client, args) {
	g_isteam = true; // Ugly hack to get around player_chat event not working.
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	decl String:result[IRC_MAXLEN], String:message[256];
	result[0] = '\0';
	GetEventString(event, "text", message, sizeof(message));
	if (!IsPlayerAlive(client))
		StrCat(result, sizeof(result), "*DEAD* ");
	if (g_isteam)
		StrCat(result, sizeof(result), "(TEAM) ");
		
	new team
	if (client != 0)
		team = IRC_GetTeamColor(GetClientTeam(client));
	else
		team = 0;
	if (team == -1)
		Format(result, sizeof(result), "%s%N: %s", result, client, message);
	else
		Format(result, sizeof(result), "%s\x03%02d%N\x03: %s", result, team, client, message);

	IRC_MsgFlaggedChannels("relay", result);
}


public OnClientAuthorized(client, const String:auth[]) { // We are hooking this instead of the player_connect event as we want the steamid
	new userid = GetClientUserId(client);
	if (userid <= g_userid) // Ugly hack to get around mass connects on map change
		return true;
	g_userid = userid;
	decl String:playername[MAX_NAME_LENGTH], String:result[IRC_MAXLEN];
	GetClientName(client, playername, sizeof(playername));
	Format(result, sizeof(result), "%t", "Player Connected", playername, auth, userid);
	if (!StrEqual(result, ""))
		IRC_MsgFlaggedChannels("relay", result);
	return true;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client != 0) {
		decl String:reason[128], String:playername[MAX_NAME_LENGTH], String:auth[64], String:result[IRC_MAXLEN];
		GetEventString(event, "reason", reason, sizeof(reason));
		GetClientName(client, playername, sizeof(playername));
		GetClientAuthString(client, auth, sizeof(auth));
		for (new i = 0; i <= strlen(reason); i++) { // For some reason, certain disconnect reasons have \n in them, so i'm stripping them. Silly valve.
			if (reason[i] == '\n')
				RemoveChar(reason, sizeof(reason), i);
		}
		Format(result, sizeof(result), "%t", "Player Disconnected", playername, auth, userid, reason);
		if (!StrEqual(result, ""))
			IRC_MsgFlaggedChannels("relay", result);
	}
}

public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client != 0) {
		decl String:oldname[128], String:newname[MAX_NAME_LENGTH], String:auth[64], String:result[IRC_MAXLEN];
		GetEventString(event, "oldname", oldname, sizeof(oldname));
		GetEventString(event, "newname", newname, sizeof(newname));
		GetClientAuthString(client, auth, sizeof(auth));
		Format(result, sizeof(result), "%t", "Changed Name", oldname, auth, userid, newname);
		if (!StrEqual(result, ""))
			IRC_MsgFlaggedChannels("relay", result);
	}
}

public OnMapEnd() {
	IRC_MsgFlaggedChannels("relay", "%t", "Map Changing");
}

public OnMapStart() {
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	IRC_MsgFlaggedChannels("relay", "%t", "Map Changed", map);
}

public Action:Command_Me(client, args) {
	decl String:Args[256], String:name[64], String:auth[64], String:text[512];
	GetCmdArgString(Args, sizeof(Args));
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, auth, sizeof(auth));
	new team = IRC_GetTeamColor(GetClientTeam(client));
	if (team == -1)
		IRC_MsgFlaggedChannels("relay", "* %s %s", name, Args);
	else
		IRC_MsgFlaggedChannels("relay", "* \x03%02d%s\x03 %s", team, name, Args);
	Format(text, sizeof(text), "\x01* \x03%s\x01 %s", name, Args);
	SayText2All(client, text);
	return Plugin_Handled;
}

public Action:Event_PRIVMSG(const String:hostmask[], args) {
	decl String:channel[64];
	IRC_GetEventArg(1, channel, sizeof(channel));
	if (IRC_ChannelHasFlag(channel, "relay")) {
		decl String:nick[IRC_NICK_MAXLEN], String:text[IRC_MAXLEN];
		IRC_GetNickFromHostMask(hostmask, nick, sizeof(nick));
		IRC_GetEventArg(2, text, sizeof(text));
		if (StrContains(text, "!msg", false) == 0) {
			ReplaceStringEx(text, sizeof(text), "!msg", "", -1, -1, false);
			if (!strncmp(text, "\x01ACTION ", 8) && text[strlen(text)-1] == '\x01') {
				text[strlen(text)-1] = '\x00';
				IRC_Strip(text, sizeof(text)); // Strip IRC Color Codes
				IRC_StripGame(text, sizeof(text)); // Strip Game color codes
				PrintToChatAll("\x01[\x04IRC\x01] * %s %s", nick, text[7]);
			}
			else {
				IRC_Strip(text, sizeof(text)); // Strip IRC Color Codes
				IRC_StripGame(text, sizeof(text)); // Strip Game color codes
				PrintToChatAll("\x01[\x04IRC\x01] %s:%s", nick, text);
			}
		}
	}
}

stock SayText2All(clientid4team, const String:message[])
{
	new Handle:hBf;
	hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, clientid4team); 
		BfWriteByte(hBf, 0); 
		BfWriteString(hBf, message);
		EndMessage();
	}
}

public OnPluginEnd() {
	IRC_CleanUp();
}

// http://bit.ly/defcon
