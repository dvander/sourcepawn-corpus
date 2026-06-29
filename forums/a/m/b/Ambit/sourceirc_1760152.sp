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

#pragma semicolon 1

#include <socket>
#include <sourceirc>

// Global socket handle for the IRC connection
new Handle:gsocket = INVALID_HANDLE;

// Global keyvalues handle for the config file
new Handle:kv;

// Command registry for plugins using IRC_Reg*Cmd
new Handle:CommandPlugins;
new Handle:Commands;
new Handle:CommandCallbacks;
new Handle:CommandDescriptions;
new Handle:CommandFlags;
new Handle:CommandPermissions;

// Event registry for plugins using IRC_HookEvent
new Handle:EventPlugins;
new Handle:Events;
new Handle:EventCallbacks;

// Queue for rate limiting
new Handle:messagequeue;
new Handle:messagetimer = INVALID_HANDLE;
new Float:messagerate = 0.0;

// Temporary storage for command and event arguments
new Handle:cmdargs;
new String:cmdargstring[IRC_MAXLEN];
new String:cmdhostmask[IRC_MAXLEN];

// Are we connected yet?
new bool:g_connected;

// My nickname
new String:g_nick[IRC_NICK_MAXLEN];

// IRC can break messages into more than one packet, so this is temporary storage for "Broken" packets
new String:brokenline[IRC_MAXLEN];

public Plugin:myinfo = {
	name = "SourceIRC",
	author = "Azelphur, modified by Ambit",
	description = "An easy to use API to the IRC protocol",
	version = IRC_VERSION,
	url = "http://Azelphur.com/project/sourceirc"
};

public OnPluginStart() {
	RegPluginLibrary("sourceirc");

	CreateConVar("sourceirc_version", IRC_VERSION, "Current version of SourceIRC", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	LoadTranslations("sourceirc.phrases");
	
	CommandPlugins = CreateArray();
	Commands = CreateArray(IRC_CMD_MAXLEN);
	CommandCallbacks = CreateArray();
	CommandDescriptions = CreateArray(256);
	CommandFlags = CreateArray();
	CommandPermissions = CreateArray();
	
	EventPlugins = CreateArray();
	Events = CreateArray(IRC_MAXLEN);
	EventCallbacks = CreateArray();
	
	messagequeue = CreateArray(IRC_MAXLEN);
	
	cmdargs = CreateArray(IRC_MAXLEN);

	g_connected = false;
	RegAdminCmd("irc_send", Command_Send, ADMFLAG_RCON, "irc_send <message>");
}

public OnAllPluginsLoaded() {
	IRC_RegCmd("help", Command_Help, "help - Shows a list of commands available to you");
	IRC_HookEvent("433", Event_RAW433);
	IRC_HookEvent("NICK", Event_NICK);
}

public Action:Event_RAW433(const String:hostmask[], args) {
	if (!g_connected) {
		decl String:nick[IRC_NICK_MAXLEN];
		IRC_GetNick(nick, sizeof(nick));
		LogError("Nickname %s is already in use, trying %s_", nick, nick);
		StrCat(nick, sizeof(nick), "_");
		IRC_Send("NICK %s", nick);
		strcopy(g_nick, sizeof(g_nick), nick);
	}
}

public Action:Event_NICK(const String:hostmask[], args) {
	decl String:newnick[64], String:oldnick[IRC_NICK_MAXLEN];
	IRC_GetNickFromHostMask(hostmask, oldnick, sizeof(oldnick));
	if (StrEqual(oldnick, g_nick)) {
		IRC_GetEventArg(1, newnick, sizeof(newnick));
		strcopy(g_nick, sizeof(g_nick), newnick);
	}
}

public Action:Command_Help(const String:nick[], args) {
	decl String:description[256];
	decl String:hostmask[IRC_MAXLEN];
	IRC_GetHostMask(hostmask, sizeof(hostmask));
	for (new i = 0; i < GetArraySize(Commands); i++) {
		if (IRC_GetAdminFlag(hostmask, GetArrayCell(CommandPermissions, i))) {
			GetArrayString(CommandDescriptions, i, description, sizeof(description));
			IRC_ReplyToCommand(nick, "%s", description);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Send(client, args) {
	if (g_connected) {
		decl String:buffer[IRC_MAXLEN];
		GetCmdArgString(buffer, sizeof(buffer));
		IRC_Send(buffer);
	}
	else {
		ReplyToCommand(client, "%t", "Not Connected");
	}
}

public OnConfigsExecuted() {
	if (gsocket == INVALID_HANDLE) {
		LoadConfigs();
		Connect();
	}
}

LoadConfigs() {
	kv = CreateKeyValues("SourceIRC");
	decl String:file[512];
	BuildPath(Path_SM, file, sizeof(file), "configs/sourceirc.cfg");
	FileToKeyValues(kv, file);
	KvJumpToKey(kv, "Settings");
	messagerate = KvGetFloat(kv, "msg-rate", 2.0);
	KvRewind(kv);
}

Connect() {
	decl String:server[256];
	KvJumpToKey(kv, "Server");
	KvGetString(kv, "server", server, sizeof(server), "");
	if (StrEqual(server, ""))
		SetFailState("No server defined in sourceirc.cfg");
	new port = KvGetNum(kv, "port", 6667);
	KvRewind(kv);
	gsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(gsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, server, port);
}

public OnSocketConnected(Handle:socket, any:arg) {
	decl String:hostname[256], String:realname[64], String:ServerIp[16];
	KvJumpToKey(kv, "Server");
	KvGetString(kv, "nickname", g_nick, sizeof(g_nick), "SourceIRC");
	KvGetString(kv, "realname", realname, sizeof(realname), "SourceIRC - http://Azelphur.com/project/sourceirc");
	KvRewind(kv);
	SocketGetHostName(hostname, sizeof(hostname));

	new iIp = GetConVarInt(FindConVar("hostip"));
	Format(ServerIp, sizeof(ServerIp), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF,
                                                          (iIp >> 16) & 0x000000FF,
                                                          (iIp >>  8) & 0x000000FF,
                                                          iIp         & 0x000000FF);
	IRC_Send("NICK %s", g_nick);
	IRC_Send("USER %s %s %s :%s", g_nick, hostname, ServerIp, realname);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	new startpos = 0;
	decl String:line[IRC_MAXLEN];
	decl String:prefix[IRC_MAXLEN];
	decl String:trailing[IRC_MAXLEN];
	new Handle:args = CreateArray(IRC_MAXLEN);
	while (startpos < dataSize) {
		startpos += SplitString(receiveData[startpos], "\n", line, sizeof(line));
		if (receiveData[startpos-1] != '\n') { // is this the first part of a "Broken" packet?
			strcopy(brokenline, sizeof(brokenline), line);
			break;
		}
		if (!StrEqual(brokenline, "")) { // Is this the latter half of a "Broken" packet? Stick it back together again.
			decl String:originalline[IRC_MAXLEN];
			strcopy(originalline, sizeof(originalline), line);
			strcopy(line, sizeof(line), brokenline);
			StrCat(line, sizeof(line), originalline);
			brokenline[0] = '\x00';
		}
		if (line[strlen(line)-1] == '\r')
			line[strlen(line)-1] = '\x00';
		prefix[0] = '\x00';
		if (line[0] == ':')
			Split(line[1], " ", prefix, sizeof(prefix), line, sizeof(line));
		if (StrContains(line, " :") != -1) { 
			Split(line, " :", line, sizeof(line), trailing, sizeof(trailing));
			ExplodeString_Array(line, " ", args, IRC_MAXLEN);
			PushArrayString(args, trailing);
		}
		else {
			ExplodeString_Array(line, " ", args, IRC_MAXLEN);
		}
		HandleLine(prefix, args); // packet has been parsed, time to send it off to HandleLine.
		ClearArray(args);
	}
}

Split(const String:source[], const String:split[], String:dest1_[], dest1maxlen, String:dest2_[], dest2maxlen) {
	decl String:dest1[dest1maxlen];
	decl String:dest2[dest2maxlen];
	new bool:beforesplit = true;
	new strpos = 0;
	for (new i = 0; i <= strlen(source); i++) {
		if (beforesplit == true) {
			if (!strncmp(source[i], split, strlen(split))) {
				strpos = 0;
				dest1[i] = '\x00';
				beforesplit = false;
				i += strlen(split);
			}
		}
		if (beforesplit && strpos < dest1maxlen)
			dest1[strpos] = source[i];
		if (!beforesplit && strpos < dest2maxlen)
			dest2[strpos] = source[i];
		strpos++;
	}
	dest2[strpos] = '\x00';
	strcopy(dest1_, dest1maxlen, dest1);
	strcopy(dest2_, dest2maxlen, dest2);
}

HandleLine(String:prefix[], Handle:args) {
	decl String:command[IRC_MAXLEN], String:ev[IRC_MAXLEN];
	GetArrayString(args, 0, command, sizeof(command));
	if (StrEqual(command, "PRIVMSG")) { // Is it a privmsg? check if it's a command and then run the command.
		decl String:message[IRC_MAXLEN], String:channel[IRC_CHANNEL_MAXLEN];
		GetArrayString(args, 1, channel, sizeof(channel));
		GetArrayString(args, 2, message, sizeof(message));
		if ((message[0] == '\x01') && (message[strlen(message)-1] == '\x01')) { // CTCP Handling
			message[strlen(message)-1] = '\x00';
			decl String:nick[IRC_NICK_MAXLEN];
			IRC_GetNickFromHostMask(prefix, nick, sizeof(nick));
			if (StrEqual(message[1], "VERSION", false)) {
				IRC_Send("NOTICE %s :\x01VERSION SourceIRC v%s - IRC Relay for source engine servers. http://azelphur.com/project/sourceirc\x01", nick, IRC_VERSION);
			}
		}
		new argpos = IsTrigger(channel, message);
		if (argpos != -1) {
			RunCommand(prefix, message[argpos]);
			return;
		}
	}
	else if (StrEqual(command, "PING", false)) { // Reply to PING
		decl String:reply[IRC_MAXLEN];
		GetArrayString(args, 1, reply, sizeof(reply));
		IRC_Send("PONG %s", reply);
	}
	else if (!g_connected & (StrEqual(command, "004") || StrEqual(command, "376"))) { // Recieved RAW 004 or RAW 376? We're connected. Yay!
		g_connected = true;
		ServerCommand("exec sourcemod/irc-connected.cfg"); 
		new Handle:connected = CreateGlobalForward("IRC_Connected", ET_Ignore);
		Call_StartForward(connected);
		Call_Finish();
	}
	for (new i = 0; i < GetArraySize(Events); i++) { // Push events to plugins that have hooked them.
		GetArrayString(Events, i, ev, sizeof(ev));
		if (StrEqual(command, ev, false)) {	
			new Action:result;
			cmdargs = args;
			new Handle:f = CreateForward(ET_Event, Param_String, Param_Cell);
			AddToForward(f, GetArrayCell(EventPlugins, i), Function:GetArrayCell(EventCallbacks, i));
			Call_StartForward(f);
			Call_PushString(prefix);
			Call_PushCell(GetArraySize(cmdargs)-1);
			Call_Finish(_:result);
			if (result == Plugin_Stop)
				return;	
		}
	}
	ClearArray(cmdargs);
}

IsTrigger(const String:channel[], const String:message[]) {
	decl String:arg1[IRC_MAXLEN], String:cmd_prefix[64];
	if (!KvJumpToKey(kv, "Server") || !KvJumpToKey(kv, "channels") || !KvJumpToKey(kv, channel))
		cmd_prefix[0] = '\x00';
	else
		KvGetString(kv, "cmd_prefix", cmd_prefix, sizeof(cmd_prefix), "");
	KvRewind(kv);
	for (new i = 0; i <= strlen(message); i++) {
		if (message[i] == ' ') {
			arg1[i] = '\x00';
			break;
		}
		arg1[i] = message[i];
	}
	new startpos = -1;
	if (StrEqual(channel, g_nick, false))
		startpos = 0;
	if (!strncmp(arg1, g_nick, strlen(g_nick), false) && !(strlen(arg1)-strlen(g_nick) > 1))
		startpos = strlen(arg1);
	else if (!StrEqual(cmd_prefix, "") && !strncmp(arg1, cmd_prefix, strlen(cmd_prefix)))
		startpos = strlen(cmd_prefix);
	else {
		decl String:cmd[IRC_CMD_MAXLEN];
		for (new i = 0; i < GetArraySize(CommandFlags); i++) {
			if (GetArrayCell(CommandFlags, i) == IRC_CMDFLAG_NOPREFIX) {
				GetArrayString(Commands, i, cmd, sizeof(cmd));
				if (!strncmp(arg1, cmd, strlen(cmd), false)) {
					startpos = 0;
					break;
				}
			}
		}
	}
	if (startpos != -1) {
		for (new i = startpos; i <= strlen(message); i++) {
			if (message[i] != ' ')
				break;
			startpos++;
		}
	}
	return startpos;
}

RunCommand(const String:hostmask[], const String:message[]) {
	decl String:command[IRC_CMD_MAXLEN], String:savedcommand[IRC_CMD_MAXLEN], String:arg[IRC_MAXLEN];
	new newpos = 0;
	new pos = BreakString(message, command, sizeof(command));
	PushArrayString(cmdargs, command);
	strcopy(cmdargstring, sizeof(cmdargstring), message[pos]);
	strcopy(cmdhostmask, sizeof(cmdhostmask), hostmask);
	while (pos != -1) {
		pos = BreakString(message[newpos], arg, sizeof(arg));
		newpos += pos;
		PushArrayString(cmdargs, arg);
	}
	decl String:nick[IRC_NICK_MAXLEN];
	IRC_GetNickFromHostMask(hostmask, nick, sizeof(nick));
	new arraysize = GetArraySize(Commands);
	new bool:IsPlugin_Handled = false;
	for (new i = 0; i < arraysize; i++) {
		GetArrayString(Commands, i, savedcommand, sizeof(savedcommand));
		if (StrEqual(command, savedcommand, false)) {
			if (IRC_GetAdminFlag(hostmask, GetArrayCell(CommandPermissions, i))) {
				new Action:result;
				new Handle:f = CreateForward(ET_Event, Param_String, Param_Cell);
				AddToForward(f, GetArrayCell(CommandPlugins, i), Function:GetArrayCell(CommandCallbacks, i));
				Call_StartForward(f);
				Call_PushString(nick);
				Call_PushCell(GetArraySize(cmdargs)-1);
				Call_Finish(_:result);
				ClearArray(cmdargs);
				if (result == Plugin_Handled)
					IsPlugin_Handled = true;
				if (result == Plugin_Stop)
					return;	
			}
			else {
				IRC_ReplyToCommand(nick, "%t", "Access Denied", command);
				return;
			}
		}
	}
	if (!IsPlugin_Handled) 
		IRC_ReplyToCommand(nick, "%t", "Unknown Command", command);
}

public IRC_Connected() {
	if (!KvJumpToKey(kv, "Server") || !KvJumpToKey(kv, "channels") || !KvGotoFirstSubKey(kv)) {
		LogError("No channels defined in sourceirc.cfg");
	}
	else {
		decl String:channel[IRC_CHANNEL_MAXLEN];
		do
		{
			KvGetSectionName(kv, channel, sizeof(channel));
			IRC_Send("JOIN %s", channel);
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	g_connected = false;
	CreateTimer(5.0, ReConnect);
	CloseHandle(socket);
}

public Action:ReConnect(Handle:timer) {
	Connect();
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	g_connected = false;
	CreateTimer(5.0, ReConnect);
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	// Create all the magical natives
	CreateNative("IRC_RegCmd", N_IRC_RegCmd);
	CreateNative("IRC_RegAdminCmd", N_IRC_RegAdminCmd);
	CreateNative("IRC_ReplyToCommand", N_IRC_ReplyToCommand);
	CreateNative("IRC_GetCmdArgString", N_IRC_GetCmdArgString);
	CreateNative("IRC_GetCmdArg", N_IRC_GetCmdArg);
	CreateNative("IRC_GetEventArg", N_IRC_GetCmdArg); // Not a mistake, they both do the same thing for now.

	CreateNative("IRC_GetServerDomain", N_IRC_GetServerDomain);
	CreateNative("IRC_HookEvent", N_IRC_HookEvent);
	CreateNative("IRC_GetTeamColor", N_IRC_GetTeamColor);

	CreateNative("IRC_GetHostMask", N_IRC_GetHostMask);
	CreateNative("IRC_CleanUp", N_IRC_CleanUp);
	CreateNative("IRC_ChannelHasFlag", N_IRC_ChannelHasFlag);
	CreateNative("IRC_Send", N_IRC_Send);
	CreateNative("IRC_GetUserFlagBits", N_IRC_GetUserFlagBits);
	CreateNative("IRC_GetAdminFlag", N_IRC_GetAdminFlag);
	CreateNative("IRC_MsgFlaggedChannels", N_IRC_MsgFlaggedChannels);
	CreateNative("IRC_GetCommandArrays", N_IRC_GetCommandArrays);
	CreateNative("IRC_GetNick", N_IRC_GetNick);
	return APLRes_Success;
}

public N_IRC_GetServerDomain(Handle:plugin, numParams) {
	decl String:AutoIP[32], String:ServerDomain[128];
	new iIp = GetConVarInt(FindConVar("hostip"));
	Format(AutoIP, sizeof(AutoIP), "%i.%i.%i.%i:%d", (iIp >> 24) & 0x000000FF,
														  (iIp >> 16) & 0x000000FF,
														  (iIp >>  8) & 0x000000FF,
														  iIp         & 0x000000FF,
														  GetConVarInt(FindConVar("hostport")));
	if (!KvJumpToKey(kv, "Settings")) {
		SetNativeString(1, AutoIP, GetNativeCell(2));
		return;
	}
	KvGetString(kv, "server-domain", ServerDomain, sizeof(ServerDomain), "");
	if (StrEqual(ServerDomain, "")) {
		SetNativeString(1, AutoIP, GetNativeCell(2));
		return;
	}

	SetNativeString(1, ServerDomain, GetNativeCell(2));
	KvRewind(kv);
}

public N_IRC_GetTeamColor(Handle:plugin, numParams) {
	new team = GetNativeCell(1);
	if (!KvJumpToKey(kv, "Settings")) return -1;
	decl String:key[16];
	Format(key, sizeof(key), "teamcolor-%d", team);
	new color = KvGetNum(kv, key, -1);
	KvRewind(kv);
	return color;
}

public N_IRC_GetHostMask(Handle:plugin, numParams) {
	SetNativeString(1, cmdhostmask, GetNativeCell(2));
	return strlen(cmdhostmask);
}

public N_IRC_GetCmdArgString(Handle:plugin, numParams) {
	SetNativeString(1, cmdargstring, GetNativeCell(2));
	return strlen(cmdargstring);
}

public N_IRC_GetCmdArg(Handle:plugin, numParams) {
	decl String:str[IRC_MAXLEN];
	new argnum = GetNativeCell(1);
	if (argnum < 0)
		GetArrayString(cmdargs, 0, str, sizeof(str));
	else
		GetArrayString(cmdargs, argnum + 1, str, sizeof(str));
	SetNativeString(2, str, GetNativeCell(3));
	return strlen(str);
}

public N_IRC_ReplyToCommand(Handle:plugin, numParams) {
	decl String:buffer[512], String:nick[64], written;
	GetNativeString(1, nick, sizeof(nick));
	FormatNativeString(0, 2, 3, sizeof(buffer), written, buffer);
	IRC_Send("NOTICE %s :%s", nick, buffer);
}

public N_IRC_GetNick(Handle:plugin, numParams) {
	new maxlen = GetNativeCell(2);
	SetNativeString(1, g_nick, maxlen);
}

public N_IRC_GetCommandArrays(Handle:plugin, numParams) {
	new Handle:CommandsArg = GetNativeCell(1);
	new Handle:CommandPluginsArg = GetNativeCell(2);
	new Handle:CommandCallbacksArg = GetNativeCell(3);
	new Handle:CommandDescriptionsArg = GetNativeCell(4);
	decl String:command[64], String:description[256];
	for (new i = 0; i < GetArraySize(CommandPlugins); i++) {
		GetArrayString(Commands, i, command, sizeof(command));
		GetArrayString(CommandDescriptions, i, description, sizeof(description));
		
		PushArrayString(CommandsArg, command);
		PushArrayCell(CommandPluginsArg, GetArrayCell(CommandPlugins, i));
		PushArrayCell(CommandCallbacksArg, GetArrayCell(CommandCallbacks, i));
		PushArrayString(CommandDescriptionsArg, description);
	}
}

public N_IRC_HookEvent(Handle:plugin, numParams) {
	decl String:ev[IRC_MAXLEN];
	GetNativeString(1, ev, sizeof(ev));
	
	PushArrayCell(EventPlugins, plugin);
	PushArrayString(Events, ev);
	PushArrayCell(EventCallbacks, GetNativeCell(2));
}

public N_IRC_RegCmd(Handle:plugin, numParams) {
	decl String:command[IRC_CMD_MAXLEN], String:description[256];
	GetNativeString(1, command, sizeof(command));
	GetNativeString(3, description, sizeof(description));
	PushArrayCell(CommandPlugins, plugin);
	PushArrayString(Commands, command);
	PushArrayCell(CommandCallbacks, GetNativeCell(2));
	PushArrayCell(CommandPermissions, 0);
	PushArrayCell(CommandFlags, GetNativeCell(4));
	PushArrayString(CommandDescriptions, description);
}

public N_IRC_RegAdminCmd(Handle:plugin, numParams) {
	decl String:command[IRC_CMD_MAXLEN], String:description[256];
	GetNativeString(1, command, sizeof(command));
	GetNativeString(4, description, sizeof(description));
	PushArrayCell(CommandPlugins, plugin);
	PushArrayString(Commands, command);
	PushArrayCell(CommandCallbacks, GetNativeCell(2));
	PushArrayCell(CommandPermissions, GetNativeCell(3));
	PushArrayCell(CommandFlags, GetNativeCell(5));
	PushArrayString(CommandDescriptions, description);
}

public N_IRC_CleanUp(Handle:plugin, numParams) {
	for (new i = 0; i < GetArraySize(CommandPlugins); i++) {
		if (plugin == GetArrayCell(CommandPlugins, i)) {
			RemoveFromArray(CommandPlugins, i);
			RemoveFromArray(Commands, i);
			RemoveFromArray(CommandCallbacks, i);
			RemoveFromArray(CommandPermissions, i);
			RemoveFromArray(CommandDescriptions, i);
			RemoveFromArray(CommandFlags, i);
			i--;
		}
	}
	for (new i = 0; i < GetArraySize(EventPlugins); i++) {
		if (plugin == GetArrayCell(EventPlugins, i)) {
			RemoveFromArray(EventPlugins, i);
			RemoveFromArray(Events, i);
			RemoveFromArray(EventCallbacks, i);
			i--;
		}
	}
}

public N_IRC_ChannelHasFlag(Handle:plugin, numParams) {
	new String:flag[64], String:channel[IRC_CHANNEL_MAXLEN];
	GetNativeString(1, channel, sizeof(channel));
	GetNativeString(2, flag, sizeof(flag));
	if (!KvJumpToKey(kv, "Server") || !KvJumpToKey(kv, "channels") || !KvJumpToKey(kv, channel)) {
		KvRewind(kv);
		return 0;
	}
	new result = KvGetNum(kv, flag, 0);
	KvRewind(kv);
	return result;
}

public N_IRC_GetAdminFlag(Handle:plugin, numParams) {
	decl String:hostmask[512];
	new flag = GetNativeCell(2);
	if (flag == 0)
		return true;
	GetNativeString(1, hostmask, sizeof(hostmask));
	new userflag = IRC_GetUserFlagBits(hostmask);
	if (userflag & ADMFLAG_ROOT)
		return true;
	if (userflag & flag)
		return true;
	return false;
}

public N_IRC_GetUserFlagBits(Handle:plugin, numParams) {
	decl String:hostmask[512];
	GetNativeString(1, hostmask, sizeof(hostmask));
	new resultflag = 0;
	new Handle:f = CreateGlobalForward("IRC_RetrieveUserFlagBits", ET_Ignore, Param_String, Param_CellByRef);
	Call_StartForward(f);
	Call_PushString(hostmask);
	Call_PushCellRef(resultflag);
	Call_Finish();
	return _:resultflag;
}

public N_IRC_Send(Handle:plugin, numParams) {
	new String:buffer[IRC_MAXLEN], written;
	FormatNativeString(0, 1, 2, sizeof(buffer), written, buffer);
	if (StrContains(buffer, "\n") != -1 || StrContains(buffer, "\r") != -1) {
		ThrowNativeError(1, "String contains \n or \r");
		return;
	}
	
	if ((g_connected) && (messagerate != 0.0)) {
		if (messagetimer != INVALID_HANDLE) {
			PushArrayString(messagequeue, buffer);
			return;
		}
		messagetimer = CreateTimer(messagerate, MessageTimerCB);
	}
	Format(buffer, sizeof(buffer), "%s\r\n", buffer);
	SocketSend(gsocket, buffer);
}

public Action:MessageTimerCB(Handle:timer) {
	messagetimer = INVALID_HANDLE;
	decl String:buffer[IRC_MAXLEN];
	if (GetArraySize(messagequeue) > 0) {
		GetArrayString(messagequeue, 0, buffer, sizeof(buffer));
		IRC_Send(buffer);
		RemoveFromArray(messagequeue, 0);
	}
}

public N_IRC_MsgFlaggedChannels(Handle:plugin, numParams) {
	if (!g_connected)
		return false;
	decl String:flag[64], String:text[IRC_MAXLEN];
	new written;
	GetNativeString(1, flag, sizeof(flag));
	FormatNativeString(0, 2, 3, sizeof(text), written, text);
	if (!KvJumpToKey(kv, "Server") || !KvJumpToKey(kv, "channels") || !KvGotoFirstSubKey(kv)) {
		LogError("No channels defined in sourceirc.cfg");
	}
	else {
		decl String:channel[IRC_CHANNEL_MAXLEN];
		do
		{
			KvGetSectionName(kv, channel, sizeof(channel));
			if (KvGetNum(kv, flag, 0)) {
				IRC_Send("PRIVMSG %s :%s", channel, text);
			}
		} while (KvGotoNextKey(kv));		
	}
	KvRewind(kv);
	return true;
}

// http://bit.ly/defcon
