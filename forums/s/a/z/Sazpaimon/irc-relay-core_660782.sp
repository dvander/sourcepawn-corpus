/*==================================================\
 * IRC relay, and admin tool			
 *
 * Web: www.steamfiends.com
 * Author: Olly
 * License: GPL
 * 
 * Changelog
 * 1.0.x 	First version of the IRC Relay. The less said about this, the better
 * 
 * 2.0.0	Initial release, of the all-new re-written relay :D
 * 
 * 2.0.1	Made IRC Relay work with sfPlayer's socket extension, as its more stable, and has more features (That is no required, instead of mine)
 * 		Fixed OnRelayPm/OnRelayMessage only triggering if the trigger was used (should be fired for any message)
 * 		Added IRC_ReplyMsg native which will reply to same destination that the triggering message was sent from
 * 		Added IRC_ReplyNotice native which is same as above, but a notice (duh)
 * 		Added IRC_Action native so you can send ./me commands to IRC
 * 		Added a die command, this is hardcoded to only allow level 300 to 'kill' the relay (for obvious reasons)
 * 		Merged irc-access.sp into irc-relay-core.smx (seperate sources) but should solve problems with late-loading because each plugin relyed on the other one to start ><
 * 		Added a new module (Steam-Community) which will convert steamid's to steam community URL's, and URL's to SteamID's  (2 new commands, steam [community url], and profile [steamid]
 * 		Fixed some minor bugs with the queue, and added better error handling
 * 		Added a new essential module - Bacon module, with a new added command 'baconize' - Use for all your porky needs
 * 		Added new command (act) to make the relay perform an action (/me) same syntax as say
 * 		Added new cvar irc_xs_act to set the required access level to run the act command
 * 		Added OnWhoisHost forward, that will be called once the relay recieves a reply from a WHOIS command sent to the server, use IRC_GetWhoisHost() to get the host value retrieved
 * 		Added IRC_GetWhoisHost Read above -^
 * 		Added IRC_Whois native which will check the hostname of nickname supplied
 * 		Fixed missing confirmation when adding a new user to the relay
 * 
 * 2.1.0	Added ability to specify the location of the config files
 * 		Added new plugin to redirect chat
 * 			* Mode 1: server -> irc
 * 			* Mode 2: server <- irc
 * 			* Mode 3: server <> irc
 * 		Reversed the player list output (we dont need to see unconnected/spectate first)
 * 		Added code to auto reload all registered plugins
 \==================================================*/
#pragma semicolon 1
#pragma dynamic 65536

#include <sourcemod>
#include <socket>
#include <irc-relay>

#include "irc-access.sp"

#define REQUIRE_PLUGIN
#define FLOOD_PROTECT_TIME 5

// Message Queue
new Handle:g_MessageQueue = INVALID_HANDLE;

// Forward Stuff
new bool:g_Connected = false;	// Are we connected to the IRC server yet?
new Handle:g_Forward_OnConnected = INVALID_HANDLE;
new Handle:g_Forward_OnRelayNotice = INVALID_HANDLE;
new Handle:g_Forward_OnRelayPm = INVALID_HANDLE;
new Handle:g_Forward_OnRelayMessage = INVALID_HANDLE;
new Handle:g_Forward_OnUserQuit = INVALID_HANDLE;
new Handle:g_Forward_OnWhoisHost = INVALID_HANDLE;

// Variables for Forwards to call
new String:g_MessageSender[64];
new String:g_MessageSenderHost[64];
new String:g_MessageDestination[64];
new String:g_MessageText[1024];
// Same as above but for WHOIS data
new String:g_Whois_Host[64];

// IRC Connection Handles
new Handle:g_Socket;

// CVAR Handles
new Handle:g_Cvar_ircServer = INVALID_HANDLE;
new Handle:g_Cvar_ircPort = INVALID_HANDLE;
new Handle:g_Cvar_ircPassword = INVALID_HANDLE;
new Handle:g_Cvar_ircNickname = INVALID_HANDLE;
new Handle:g_Cvar_ircName = INVALID_HANDLE;
new Handle:g_Cvar_ircGroups = INVALID_HANDLE;
new Handle:g_Cvar_ircFloodLimit = INVALID_HANDLE;
new Handle:g_Cvar_GameIp = INVALID_HANDLE;
new Handle:g_Cvar_EnableColour = INVALID_HANDLE;
new Handle:g_Cvar_Debug = INVALID_HANDLE;
new Handle:g_Cvar_JoinLvl = INVALID_HANDLE;
new Handle:g_Cvar_PartLvl = INVALID_HANDLE;
new Handle:g_Cvar_ConfigDir = INVALID_HANDLE;

// Global CVAR Values
new String:g_ircServer[64]; 
new g_ircPort = 0;
new String:g_ircPassword[64];
new String:g_ircNickname[32];
new String:g_ircName[32];
new String:g_ircGroups[1024];
new Float:g_ircFloodLimit = 0.0;
new bool:g_ircColor = true;
new String:g_configDir[256];

// Modules
new Handle:g_loadedModules[50] = {INVALID_HANDLE, ...};
new String:g_ModuleNames[50][64];
new g_ModuleIdx = 0;

// Commands
new Handle:g_CommandForwards[50] = {INVALID_HANDLE, ...};
new String:g_CommandName[50][64];
new bool:g_CommandActive[50] = {false, ...};
new g_CommandLevel[50] = {0, ...};

// Temp argv/c sutff
new g_argc =0;
new String:g_argv[15][512];
new String:g_argstr[4096];

// Trigger group stuff
new String:g_Groups[10][64];

// Channel stuff
new Handle:g_ChannelNames = INVALID_HANDLE;
new Handle:g_ChannelTypes = INVALID_HANDLE;

// Mod Config
new Handle:g_KVModCfg = INVALID_HANDLE;
new String:g_ModCfgLoc[128];
// -- Team Colours
new g_TeamColors[10];

// Have we registered our commands?
new bool:registered = false;

new String:g_CorePlugins[][] = {"admin", "auth", "bacon", "basecommands", "chat-relay", "game-players", "game-relay", "gameinfo", "steam-community"};

public Plugin:myinfo = 
{
	name = "IRC Relay - Core Plugin",
	author = "Olly",
	description = "IRC Relay",
	version = IRC_VERSION,
	url = "http://www.steamfriends.com/"
};

 /*****************************************************************
 * AskPluginLoad
 *
 * @breif Called when SourceMod queries the plugin
 * @noreturn
 *****************************************************************/
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("irc-relay-core");
	
	CreateNative("IRC_SendRaw", Native_IRC_SendRaw);
	CreateNative("IRC_PrivMsg", Native_IRC_PrivMsg);
	CreateNative("IRC_Notice", Native_IRC_Notice);
	CreateNative("IRC_Broadcast", Native_IRC_Broadcast);
	CreateNative("IRC_IsReady", Native_IRC_IsReady);
	CreateNative("IRC_RegisterCommand", Native_IRC_RegisterCommand);
	CreateNative("IRC_ReplyMsg", Native_IRC_ReplyMsg);
	CreateNative("IRC_ReplyNotice", Native_IRC_ReplyNotice);
	CreateNative("IRC_Action", Native_IRC_Action);
	CreateNative("IRC_Whois", Native_IRC_Whois);
	
	// Getters
	CreateNative("IRC_GetCmdArgc", Native_IRC_GetCmdArgc);
	CreateNative("IRC_GetCmdArgv", Native_IRC_GetCmdArgv);
	CreateNative("IRC_GetCmdArgString", Native_IRC_GetCmdArgString);
	CreateNative("IRC_GetMsgSender", Native_IRC_GetMsgSender);
	CreateNative("IRC_GetSenderHost", Native_IRC_GetSenderHost);
	CreateNative("IRC_GetMsgDestination", Native_IRC_GetMsgDestination);
	CreateNative("IRC_GetMessage", Native_IRC_GetMessage);
	CreateNative("IRC_GetColorName", Native_IRC_GetColorName);
	CreateNative("IRC_GetRelayNickName", Native_IRC_GetRelayNickName);
	CreateNative("IRC_GetWhoisHost", Native_IRC_GetWhoisHost);
	
	// Access
	CreateNative("IRC_GetAccessLevelByHost", Native_IRC_GetAccessLevelByHost);
	
	if( late )
	{
		for(new i=0; i < sizeof(g_CorePlugins); i++)
		{
			ServerCommand("sm plugins reload irc-%s", g_CorePlugins[i]);
		}
	}
	return true;
}


/*********************************************************
 *  Gets the nickname of the user who sent the message.
 * 
 * @param  String:buffer	The buffer to save the sender nickname into in
 * @param  size			The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetMsgSender(Handle:plugin, numParams)
{
	SetNativeString(1, g_MessageSender, GetNativeCell(2));
}


/*********************************************************
 *  Gets the host of the user who sent the message. (ident@host)
 * 
 * @param  String:buffer	The buffer to save the senders host into
 * @param  size			The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetSenderHost(Handle:plugin, numParams)
{
	SetNativeString(1, g_MessageSenderHost, GetNativeCell(2));
}


/*********************************************************
 *  Gets destination of the message, so we can send a message back to where it came from
 * 
 * @param  String:buffer	The buffer to save the destination into
 * @param  size			The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetMsgDestination(Handle:plugin, numParams)
{
	SetNativeString(1, g_MessageDestination, GetNativeCell(2));
}


/*********************************************************
 *  Gets the message, that was sent with the server response
 * 
 * @param  String:buffer	The buffer to save the message into
 * @param  size			The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetMessage(Handle:plugin, numParams)
{
	SetNativeString(1, g_MessageText, GetNativeCell(2));
}

/*********************************************************
 *  This native will allow external plugins to send RAW 
 *  data to the server
 *
 * @param	Handle:module	  	The handle of the module plugin
 * @param	String:name[]		The real name of the module, 
 * 					* Spaces will be removed *
 * @noreturn		
 *********************************************************/
public Native_IRC_RegisterModule(Handle:plugin, numParams)
{
	new String:name[64];
	GetNativeString(2, name, 64);
	ReplaceString(name, 64, " ", "");
	g_loadedModules[g_ModuleIdx] = GetNativeCell(1);
	strcopy(g_ModuleNames[g_ModuleIdx], 64, name);
	g_ModuleIdx++;
}

/*********************************************************
 *  Allows you to register your own irc command, and have
 *  it callback to a function in your plugin when it gets called
 *
 * @param	String:name[]	  	The name of the command to register
 * @param	function		The callback function in your plugin (IRC_Tag_CommandCallback)
 * @noreturn		
 *********************************************************/
public Native_IRC_RegisterCommand(Handle:plugin, numParams)
{
	for(new i=0;i<50;i++)
	{
		if(g_CommandActive[i] == false)
		{
			g_CommandForwards[i] = CreateForward(ET_Ignore, Param_Cell);
			AddToForward(g_CommandForwards[i], plugin, Function:GetNativeCell(2));
			GetNativeString(1, g_CommandName[i], 64);
			g_CommandActive[i] = true;
			g_CommandLevel[i] = GetNativeCell(3);
			break;
		}
	}
}

/*********************************************************
 *  This native will allow external plugins to send RAW 
 *  data to the server
 *
 * @param	String:command[]  	The raw data to 
 * 					send to the IRC 
 * 					server.
 * @param 	any:...			format stuff
 * @noreturn		
 *********************************************************/
public Native_IRC_SendRaw(Handle:plugin, numParams)
{
	decl String:buffer[512];
	FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	
	SendData(buffer);
}


/*********************************************************
 *  This will send a simple message to a user (pm) or 
 *  to a channel
 *
 * @param	String:destination[]  	Can either be a channel name (#olly)
 * 					Or a nickname to send a PM
 * @param	String:message[]	The message to send out.
 * @noreturn		
 *********************************************************/
public Native_IRC_PrivMsg(Handle:plugin, numParams)
{
	decl String:dest[64], String:msg[512];
	
	GetNativeString(1, dest, sizeof(dest));
	FormatNativeString(0, 2, 3, sizeof(msg), _, msg);
	
	new len = strlen(msg) + strlen(dest) + 24;
	new String:buffer[len];
	
	Format(buffer, len, "PRIVMSG %s :%s", dest, msg);
	SendData(buffer);
}


/*********************************************************
 *  This will simply send a message to the same place that the triggering 
 *  command/message was sent from.
 *
 * @param	String:message[]	The message to send out.
 * @param 	any:...			Formatter stuffs
 * @noreturn		
 *********************************************************/
public Native_IRC_ReplyMsg(Handle:plugin, numParams)
{
	decl String:msg[512];
	FormatNativeString(0, 1, 2, sizeof(msg), _, msg);

	new len = strlen(msg) + strlen(g_MessageDestination) + 24;
	new String:buffer[len];
	
	Format(buffer, len, "PRIVMSG %s :%s", g_MessageDestination, msg);
	SendData(buffer);
}


/*********************************************************
 *  This will send a notice back to the origin of the triggering message
 *
 * @param	String:message[]	The message to send out.
 * @param 	any:...			Formatter stuffs
 * @noreturn		
 *********************************************************/
public Native_IRC_ReplyNotice(Handle:plugin, numParams)
{
	decl String:msg[512];
	FormatNativeString(0, 1, 2, sizeof(msg), _, msg);

	new len = strlen(msg) + strlen(g_MessageDestination) + 24;
	new String:buffer[len];
	
	Format(buffer, len, "NOTICE %s :%s", g_MessageDestination, msg);
	SendData(buffer);
}

/*********************************************************
 *  This will show an 'action' in the specified channel, like /me [message]
 *
 * @param	String:destination[]  	Can either be a channel name (#olly)
 * 					Or a nickname to send a PM
 * @param	String:message[]	The message to send out.
 * @param 	any:...			Formatter stuffs
 * @noreturn		
 *********************************************************/
public Native_IRC_Action(Handle:plugin, numParams)
{
	decl String:msg[512];
	FormatNativeString(0, 2, 3, sizeof(msg), _, msg);

	new len = strlen(msg) + strlen(g_MessageDestination) + 24;
	new String:buffer[len];
	
	Format(buffer, len, "PRIVMSG %s :\x01ACTION %s\x01", g_MessageDestination, msg);
	SendData(buffer);
}


/*********************************************************
 *  This will start a WHOIS command on a nickname that is connected to the server
 *  
 *  Note: add OnWhoisHost() forward, so you know when the result returns to the relay
 *
 * @param	nickname 	Nick of the person to whois
 * @noreturn		
 *********************************************************/
public Native_IRC_Whois(Handle:plugin, numParams)
{
	decl String:nickname[64];
	GetNativeString(1, nickname, sizeof(nickname));
	IRC_SendRaw("WHOIS %s", nickname);
}


/*********************************************************
 *  This will send a simple notice to a user (pm) or 
 *  to a channel
 *
 * @param	String:destination[]  	Can either be a channel name (#olly)
 * 					Or a nickname to send a PM
 * @param	String:message[]	The message to send out.
 * @noreturn		
 *********************************************************/
public Native_IRC_Notice(Handle:plugin, numParams)
{
	decl String:dest[64], String:msg[512];
	
	GetNativeString(1, dest, sizeof(dest));
	FormatNativeString(0, 2, 3, sizeof(msg), _, msg);

	new len = strlen(msg) + strlen(dest) + 24;
	new String:buffer[len];
	
	Format(buffer, len, "NOTICE %s :%s", dest, msg);
	SendData(buffer);
}


/*********************************************************
 *  This will send a message to all of the channels of the type specified
 *
 * @param	ChannelType:ctype  	The type of channel to send the message to
 * @param	String:message[]	The message to send out.
 * @param 	any:...			Formatter stuffs
 * @noreturn		
 *********************************************************/
public Native_IRC_Broadcast(Handle:plugin, numParams)
{
	decl String:message[512], String:buffer[714];
	new ChannelType:bcastType = GetNativeCell(1);
	FormatNativeString(0, 2, 3, sizeof(message), _, message);
	
	for(new i=0;i<GetArraySize(g_ChannelNames);i++)
	{
		if(bcastType == GetArrayCell(g_ChannelTypes, i) || bcastType == IRC_CHANNEL_BOTH) // If the channel matches the type, or message is to all
		{
			decl String:channelName[64];
			GetArrayString(g_ChannelNames, i, channelName, sizeof(channelName));
			Format(buffer, sizeof(buffer), "PRIVMSG %s :%s", channelName, message);
			SendData(buffer);
			
		}
	}
	
}


/*********************************************************
 *  This will get the current nickname of the relay
 *
 * @param output	The buffer to store the name
 * @param size		The length of the buffer
 *********************************************************/
public Native_IRC_GetRelayNickName(Handle:plugin, numParams)
{
	SetNativeString(1, g_ircNickname, GetNativeCell(2), true);
}


/*********************************************************
 *  Gets the hostname of the nickname that you whois'd this should be used inside the OnWhoisHost forward
 * 
 * @param  String:buffer	The buffer to save the host into
 * @param  size			The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetWhoisHost(Handle:plugin, numParams)
{
	SetNativeString(1, g_Whois_Host, GetNativeCell(2), true);
}

/*********************************************************
 *  This will check if the core is correctly connected, and ready
 *
 * @param bool	True if the core is connected, and ready for commands		
 *********************************************************/
public Native_IRC_IsReady(Handle:plugin, numParams)
{
	return g_Connected;
}

/*********************************************************
 *  Count the arguments sent along with our message
 *
 * @return count of arguments	
 *********************************************************/
public Native_IRC_GetCmdArgc(Handle:plugin, numParams)
{
	return g_argc;
}


/*********************************************************
 *  Get the argument number specified
 * 
 * @param  num		The arguemnt number to store
 * @param  String:arg	The buffer to save the argument in
 * @param  size		The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetCmdArgv(Handle:plugin, numParams)
{
	new argnum = GetNativeCell(1);
	new len = GetNativeCell(3);
	// We want to skip the relay trigger, and command, as this is already passed
	SetNativeString(2, g_argv[argnum+1], len, true);	
}


/*********************************************************
 *  Will concatonate arguments starting at the specified argument
 *  and create a string. This is usefull for lazy people who
 *  dont put stuff in " "'s
 * 
 * @param  num		The arguemnt number to store
 * @param  String:arg	The buffer to save the argument in
 * @param  size		The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetCmdArgString(Handle:plugin, numParams)
{
	SetNativeString(1, g_argstr, GetNativeCell(2));
}

/*********************************************************
 *  Will return an IRC coloured version of the clients name
 * 
 * @param  client	The client index to get name for
 * @param  String:arg	The buffer to save the argument in
 * @param  size		The size of the buffer
 * @noreturn
 *********************************************************/
public Native_IRC_GetColorName(Handle:plugin, numParams)
{
	decl String:buff[GetNativeCell(3)+2], String:name[64];
	new client = GetNativeCell(1);
	
	GetClientName(client, name, sizeof(name));
	new teamid = GetClientTeam(client);
	if(g_ircColor)
		Format(buff, GetNativeCell(3)+3, "\x03%d%s\x03", g_TeamColors[teamid], name);
	else
		Format(buff, GetNativeCell(3)+3, "%s", name);
	SetNativeString(2, buff, GetNativeCell(3));
}


 /*****************************************************************
 * OnPluginStart
 *
 * @breif This function is called when the plugin starts up
 * @noreturn
 *****************************************************************/
public OnPluginStart()
{	
	// Setup our forwards
	g_Forward_OnConnected = CreateGlobalForward("OnIrcConnected", ET_Ignore);
	g_Forward_OnRelayPm = CreateGlobalForward("OnRelayPm", ET_Ignore);
	g_Forward_OnRelayNotice = CreateGlobalForward("OnRelayNotice", ET_Ignore);
	g_Forward_OnRelayMessage = CreateGlobalForward("OnRelayMessage", ET_Ignore);
	g_Forward_OnUserQuit = CreateGlobalForward("OnUserQuit", ET_Ignore);
	g_Forward_OnWhoisHost = CreateGlobalForward("OnWhoisHost", ET_Ignore);
	
	// Add some simple public cvars to show the version
	CreateConVar("irc_version",IRC_VERSION,"Current version of IRC Relay",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	CreateConVar("sm_irc_version",IRC_VERSION,"Current version of IRC Relay",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	// Some important cvars we need to set, before the bot can connect to the server
	g_Cvar_ircServer = CreateConVar("irc_server","","The IRC server address to connect to.",FCVAR_PLUGIN);
	g_Cvar_ircPort = CreateConVar("irc_port", "6667","IRC server port",FCVAR_PLUGIN);
	g_Cvar_ircPassword = CreateConVar("irc_password","","The password of the server.",FCVAR_PLUGIN);
	g_Cvar_ircNickname = CreateConVar("irc_nickname","","The nickname of the relay.",FCVAR_PLUGIN);
	g_Cvar_ircName = CreateConVar("irc_name","","The trigger name of the relay.",FCVAR_PLUGIN);
	g_Cvar_ircGroups = CreateConVar("irc_trigger_groups","","The trigger groups this bot should respond to.",FCVAR_PLUGIN);
	g_Cvar_ircFloodLimit = CreateConVar("irc_flood_limit","0.5","The time (seconds) to delay messages to stop message flood.",FCVAR_PLUGIN);
	g_Cvar_EnableColour = CreateConVar("irc_color","1","Enable colour codes.",FCVAR_PLUGIN);
	g_Cvar_Debug = CreateConVar("irc_debug","0","Outputs RAW IRC data to console (1=on, 0=off)",FCVAR_PLUGIN);
	g_Cvar_JoinLvl = CreateConVar("irc_xs_join","300","Level needed to make the relay join a channel.",FCVAR_PLUGIN);
	g_Cvar_PartLvl = CreateConVar("irc_xs_part","300","Level needed to make the relay part a channel.",FCVAR_PLUGIN);
	g_Cvar_GameIp = FindConVar("hostip");
	g_Cvar_ConfigDir = CreateConVar("irc_config_dir","configs/ircrelay/","Location to the config file.",FCVAR_PLUGIN);
	
	// IRC Access Stuff
	g_Cvar_AddUserLvl = CreateConVar("irc_xs_adduser","300","The access level needed to add users.",FCVAR_PLUGIN);
	g_Cvar_RconPassword = FindConVar("rcon_password");
	g_Fwd_GotAccess = CreateGlobalForward("OnGotAccessLvl", ET_Ignore, Param_String, Param_Cell, Param_Cell, Param_Cell);
	
	// Init our channel array's
	g_ChannelNames = CreateArray(64); // Enough space for String:gaben[64]
	g_ChannelTypes = CreateArray();
}

 /*****************************************************************
 * OnConfigsExecuted
 *
 * @breif Called when all config files have been executed
 * @noreturn
 *****************************************************************/
public OnConfigsExecuted()
{	
	// Get the connection settings
	GetConVarString(g_Cvar_ircServer, g_ircServer, sizeof(g_ircServer));
	GetConVarString(g_Cvar_ircPassword, g_ircPassword, sizeof(g_ircPassword));
	GetConVarString(g_Cvar_ircNickname, g_ircNickname, sizeof(g_ircNickname));
	GetConVarString(g_Cvar_ircName, g_ircName, sizeof(g_ircName));
	GetConVarString(g_Cvar_ircGroups, g_ircGroups, sizeof(g_ircGroups));
	GetConVarString(g_Cvar_ConfigDir, g_configDir, sizeof(g_configDir));
	
	g_ircPort = GetConVarInt(g_Cvar_ircPort);
	g_ircFloodLimit = GetConVarFloat(g_Cvar_ircFloodLimit);
	g_ircColor = GetConVarBool(g_Cvar_EnableColour);
	
	// Register the some core commands
	if(!registered){
		IRC_RegisterCommand("join", IRC_Tag_CommandCallback:command_Join, GetConVarInt(g_Cvar_JoinLvl));
		IRC_RegisterCommand("part", IRC_Tag_CommandCallback:command_Part, GetConVarInt(g_Cvar_PartLvl));
		IRC_RegisterCommand("commands", IRC_Tag_CommandCallback:command_Commands, 0);
		IRC_RegisterCommand("die", IRC_Tag_CommandCallback:command_Die, 300);
		IRC_RegisterCommand("raw", IRC_Tag_CommandCallback:command_raw, 0);
		
		RegServerCmd("irc_addroot", con_addroot);
		
		// IRC Access Stuff
		IRC_RegisterCommand("a", IRC_Tag_CommandCallback:command_access, 0);	
		IRC_RegisterCommand("adduser", IRC_Tag_CommandCallback:command_adduser, GetConVarInt(g_Cvar_AddUserLvl));
		IRC_RegisterCommand("auth", IRC_Tag_CommandCallback:command_auth, 0);
		IRC_RegisterCommand("users", IRC_Tag_CommandCallback:command_users, 0);
		
		registered = true;
	}
	
	// Connect to our database
	SQL_TConnect(GotDatabase, "irc_relay");	
	
	decl pieces[4], String:ServerIp[64];
	new longip = GetConVarInt(g_Cvar_GameIp);
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	FormatEx(ServerIp, sizeof(ServerIp), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	
	// Setup the flood timer, and message queue
	g_MessageQueue = CreateArray(1024); // Enough for String:gaben[][1024]
	CreateTimer(g_ircFloodLimit, ProcessMessageQueue, 0, TIMER_REPEAT);
	
	// Split up the groups from the convar string
	new idx =0, a=0, length=0;
	while(length != -1)
	{
		if(a > 9) break;
		length = BreakString(g_ircGroups[idx], g_Groups[a], 64);
		idx += length;
		a++;
	}

 	// Create our socket (Not connecting here!)
	if(g_Socket == INVALID_HANDLE)  // Only if its not been made already
	{
		//g_Socket = CreateSocket(SOCKET_TCP, SocketRecieve:SocketReceive, SocketError:SocketError);
		g_Socket = SocketCreate(SOCKET_TCP, OnSocketError);
	}
 	
	if(g_Socket == INVALID_HANDLE) // If its still invalid, something is b0rked
	{
		ThrowError("Error Connecting to socket - Socket was invalid handle");
	}
	else if(g_Socket != INVALID_HANDLE && g_Connected == false)
	{
		SocketBind(g_Socket, ServerIp, 0);
		//ConnectSocket(g_Socket, g_ircServer, g_ircPort);
		//ConnectSocket(g_Socket, "192.168.0.8", 9998);
		SocketConnect(g_Socket, SocketConnected, SocketReceive, OnSocketDisconnected, g_ircServer, g_ircPort);
	}
	
	// Load our channels from the config file
	LoadChannels();
	
	// Load our mod independant config files
	LoadModConfig();
}


public SocketConnected(Handle:socket, any:arg) 
{
	decl String:registationCmd[64];
	if(strlen(g_ircPassword) > 0)
	{
		decl String:passwordStr[64];
		Format(passwordStr, sizeof(passwordStr), "PASS %s", g_ircPassword);
		SendData(passwordStr);
	}
	// Register with the server
	Format(registationCmd, sizeof(registationCmd), "USER %s %s %s :IRC Relay\n\rNICK %s", g_ircName, g_ircName, g_ircName, g_ircNickname);
	SendData(registationCmd);
}


public OnSocketDisconnected(Handle:socket, any:hFile) 
{
	CloseHandle(g_Socket);
}
 
 /*****************************************************************
 * SocketReceive
 *
 * @breif This is the callback from the sockets extension when
 *        new data is received
 * 
 * Message in a channel:
 * 	:Olly!~Olly@Olly.agent.support PRIVMSG #sf.staff :!msg.eu.css
 * 
 * @params size The size of the data that is received
 * @return none
 *****************************************************************/
public SocketReceive(Handle:socket, const String:receiveData[], const dataSize, any:hFile)
{
	decl String:ircDataLines[20][1024], Action:result;
	new lineCount = 0;
	
	new bool:idebug=false;
	idebug = GetConVarBool(g_Cvar_Debug);
	lineCount = ExplodeString(receiveData, "\r", ircDataLines, 20, 1024);
	
	// Loop through all of our data lines
	for(new i=0;i<lineCount;i++)
	{
		// Message Stuff
		new partCount=0, String:messageParts[8][256], bool:isPm=false, triggered;
		
		if(idebug)
		{
			PrintToServer("%s\n", ircDataLines[i]);
			LogToGame("%s\n", ircDataLines[i]);
		}
		
		decl String:trigger[64];
		triggered = CheckForTrigger(ircDataLines[i], trigger, sizeof(trigger));  // Find the trigger that triggered us		
		
		partCount = ExplodeString(ircDataLines[i], " ", messageParts, 8, 256); // Split up the different parts of the IRC message
		for(new tmp=0;tmp<partCount;tmp++)
		{
			ReplaceString(messageParts[tmp], 256, "\r", "");
			ReplaceString(messageParts[tmp], 256, "\n", "");
		}
		if(strlen(messageParts[0]) < 2 && strlen(messageParts[0]) <2 )
			continue; // No data for us :(

		/******************************************************************
		 * Do Process all of the messages, and server responses here....
		 ******************************************************************/
		// PING
		if(!strcmp(messageParts[0], "PING", false))
		{
			decl String:pingResponse[128];
			messageParts[0][1] = 'O'; // Replace the I for an O = PONG
			Format(pingResponse, sizeof(pingResponse), "%s %s", messageParts[0], messageParts[1]);
			SendData(pingResponse);
		}
		else if(!strcmp(messageParts[0], "ERROR", false))
		{
			CreateTimer(360.0, RestartPlugin);
		}
		else if(messageParts[0][0] == ':') // Means a real message was sent, and we need to format it, and extract the stuff
		{
			new msgPtr=0;
			
			if(StrContains(messageParts[0], "!", false) == -1)
				strcopy(g_MessageSenderHost, sizeof(g_MessageSenderHost), messageParts[0][1]);
			else
			{
				decl String:hostParts[2][128];
				ExplodeString(messageParts[0][1], "!", hostParts, 2, 128);
				strcopy(g_MessageSender, sizeof(g_MessageSender), hostParts[0]);
				strcopy(g_MessageSenderHost, sizeof(g_MessageSenderHost), hostParts[1]);
			}
			
			// Check if the incoming message was a PM or not
			if(!strcmp(messageParts[2], g_ircNickname, false)) {
				// If we were sent a PM, then the destination needs to be set to the sender so we can message them back
				strcopy(g_MessageDestination, sizeof(g_MessageDestination), g_MessageSender);
				isPm=true;
			}else{
				// If its a channel message, then continue will using the main destication
				strcopy(g_MessageDestination, sizeof(g_MessageDestination), messageParts[2]);
				isPm=false;
			}
			
			// Find the start of the message, and then offset by 1 to skip the ':'
			msgPtr = (StrContains(ircDataLines[i], messageParts[3], false) + 1); 
			strcopy(g_MessageText, sizeof(g_MessageText), ircDataLines[i][msgPtr]);
		}
		
		ClearArgs();
		
		/********************************************************************************
		 * Find what type of server response it was, and call the appropriate forward....
		 ********************************************************************************/
		 // Someone sent a NOTICE, OHNOES
		if(!strcmp(messageParts[1], "NOTICE", false))
		{
			Call_StartForward(g_Forward_OnRelayNotice);
			Call_Finish(_:result);
		}
		else if(!strcmp(messageParts[1], "PRIVMSG", false))
		{
			
			new String:args[10][512];
			
			if(isPm)
			{
				Call_StartForward(g_Forward_OnRelayPm);
				Call_Finish(_:result);
			}else{
				msgPtr += strlen(trigger)+2;
				Call_StartForward(g_Forward_OnRelayMessage);
				Call_Finish(_:result);
			}
			
			if(!triggered)
				continue;
			
			// Now split the arguments in the message up
			
			new idx =msgPtr, a=0, length=0;
			while(length != -1)
			{
				if(a > 9) break;
				length = BreakString(g_MessageText[idx], args[a], 512);
				strcopy(g_argv[a], 512, args[a]);
				idx += length;
				a++;
			}
			// We need to keep the whole string, just in-case they need it :o
			new argPtr = StrContains(g_MessageText, " ", false);
			if(argPtr == -1) argPtr = 0;
			
			strcopy(g_argstr, sizeof(g_argstr), g_MessageText[argPtr]);
			g_argc = (a-1);
			
			
			// Now check all registered plugins, maybe they want a slice of the action :o
			for(new p=0;p<50;p++)
			{
				if(!strcmp(g_CommandName[p], g_argv[0], false) && g_CommandActive[p] == true)  // Check if their command was run
				{
					IRC_GetAccessLevelByHost(g_MessageSenderHost, g_MessageSender, p, g_argc);
				}
			}
		}
		else if(!strcmp(messageParts[1], "QUIT", false))
		{
			Call_StartForward(g_Forward_OnUserQuit);
			Call_Finish(_:result);
		}
		else if(StringToInt(messageParts[1]) == 422) // MOTD Missing 
		{
			// Call our forward so other plugins know we are connected
			if(!g_Connected){
				Call_StartForward(g_Forward_OnConnected);
				Call_Finish(_:result);
				g_Connected = true;
				InitChannels(); // Join our channels ONLY ONCE!
			}
		}
		else if(StringToInt(messageParts[1]) == 376) // End of MOTD
		{
			// Call our forward so other plugins know we are connected
			if(!g_Connected){
				Call_StartForward(g_Forward_OnConnected);
				Call_Finish(_:result);
				g_Connected = true;
				InitChannels(); // Join our channels ONLY ONCE!
			}
		}
		else if(StringToInt(messageParts[1]) == 311) // Start of WHOIS
		{
			strcopy(g_Whois_Host, sizeof(g_Whois_Host), messageParts[5]);
			Call_StartForward(g_Forward_OnWhoisHost);
			Call_Finish(_:result);
		}
		else if(StringToInt(messageParts[1]) == 401) // Invalid nickname from WHOIS call
		{
			strcopy(g_Whois_Host, sizeof(g_Whois_Host), "");
			Call_StartForward(g_Forward_OnWhoisHost);
			Call_Finish(_:result);
		}
	}
}

public OnGotAccessLvl(const String:dest[], p, a, lvl)
{
	PrintToServer("OnGotAccessLvl");
	if(lvl >= g_CommandLevel[p])
	{
		Call_StartForward(g_CommandForwards[p]); // Poke their callback into action
		Call_PushCell(a);
		Call_Finish();
	}else{
		IRC_Notice(dest, "You don't have the required access level for this command.");
	}
}
 
 /*****************************************************************
 * JoinAllChannels
 *
 * @breif The bot should join all channels that are specified in the
 * 	  config file
 * @return none
 ****************************************************************/
 public InitChannels()
 {
	for(new i=0;i<GetArraySize(g_ChannelNames);i++)
	{
		decl String:channelName[64];
		GetArrayString(g_ChannelNames, i, channelName, sizeof(channelName));
		JoinChannel(channelName);
	}
 }
 
 
 /*****************************************************************
 * Join
 *
 * @breif Sends a JOIN command to the server
 * @params String:channel the channel to join
 * @return none
 *****************************************************************/
public JoinChannel(const String:channel[])
{
	decl String:command[128];
	// Add the command syntax
	Format(command, sizeof(command), "JOIN %s", channel);
	// send the command to the socket
	SendData(command);
}

 /*****************************************************************
 * Part
 *
 * @breif Sends a PART command to the server
 * @params String:channel the channel to part
 * @return none
 *****************************************************************/
public PartChannel(const String:channel[])
{
	decl String:command[128];
	// Add the command syntax
	Format(command, sizeof(command), "PART %s", channel);
	// send the command to the socket
	SendData(command);
}
 
 
 /*****************************************************************
 * SendData
 *
 * @breif This is a wrapper for the ExtSocket's SocketSend
 * 	  We can use this to do stuff when sending data, 
 * 	  Maybe impliment a queue?
 * 
 * @param data This is the data that was sent in the PING packet
 * @return none
 *****************************************************************/
 public SendData(const String:data[])
 {
	PrintToServer("Added to MSGQueue: %s", data);
	PushArrayString(g_MessageQueue, data);
 }
 
 public Action:ProcessMessageQueue(Handle:timer)
 {
 	if(GetArraySize(g_MessageQueue) == 0)
		return;
	
	decl String:packet[1036], String:data[1024];
	GetArrayString(g_MessageQueue, 0, data, sizeof(data));
	Format(packet, sizeof(packet), "%s\n\r\n\r", data);
	RemoveFromArray(g_MessageQueue, 0);
	
	if (SocketIsConnected(g_Socket)) {
		SocketSend(g_Socket, packet);
		PrintToServer("Sent: %s", packet);
	}else{
		PrintToServer("NOT CONNECTED");
	}
 }
 
 public ClearArgs()
 {
	for(new i=0;i<15;i++)
	{
		g_argv[i][0] = '\0';
	}
 }
 
 
 /*****************************************************************
 * CheckForTrigger
 *
 * @breif Check the input string for the relay's trigger, or a trigger
 * 	  group that this relay appears in.
 * 
 * @param input		The input string to check for
 * @param trigger	The output buffer to store the trigger found
 * @param size		The size of the trigger buffer
 * @return 1 if trigger is found, 0 if not found, return 2 if its a PM
 *****************************************************************/
 public CheckForTrigger(const String:input[], String:trigger[], size)
 {
 	decl String:buffer[strlen(input)+6];
	
	Format(buffer, strlen(buffer)+strlen(g_ircNickname)+1, "PRIVMSG %s", g_ircNickname);
	if(StrContains(input, buffer, false) != -1)
	{
		strcopy(trigger, size, "");
		return 2;
	}
	
	Format(buffer, strlen(input)+8, " :!%s", g_ircName); // Add some extra stuff, so it doesnt return true when people talk about how cool the relay is ^^
 	if(StrContains(input, buffer, false) != -1) // Check if the input contains the trigger
	{
		strcopy(trigger, size, g_ircName);
		return 1;
	}
	else if(StrContains(input, " :!@all", false) != -1) // Check for the #all trigger
	{
		strcopy(trigger, size, "@all");
		return 1;
	}
	
	
	for(new i=0;i<10;i++) // Loop all of our groups
	{
		if(strlen(g_Groups[i]) < 1) continue;
		Format(buffer, strlen(input)+8, " :!@%s", g_Groups[i]); // Need to check for '#' infront of the group
		if(StrContains(input, buffer, false) != -1) 	// Check if it contains our group trigger
		{
			strcopy(trigger, size, buffer[3]); // copy the string, but without the irc protocol stuff
			return 1;
		}
	}
	
	return 0; // if we got here, they didnt speak to us :(
 }
 
 /*****************************************************************
 * LoadModConfig
 *
 * @breif Reads the data from the mod configs, and places them into the.
 * 
 * @noreturn
 *****************************************************************/
 public LoadModConfig()
 {
	// Get the mod name, and load the config
	decl String:modFolder[64];
	
	GetGameFolderName(modFolder, sizeof(modFolder));
	BuildPath(Path_SM,g_ModCfgLoc,sizeof(g_ModCfgLoc), "%s%s.txt", g_configDir, modFolder);
	
	g_KVModCfg = CreateKeyValues("ModConfig");
	
	if(FileExists(g_ModCfgLoc) && g_KVModCfg != INVALID_HANDLE)
	{
		FileToKeyValues(g_KVModCfg,g_ModCfgLoc);
	}else{
		// We dont have a mod config for this mod yet!
		BuildPath(Path_SM,g_ModCfgLoc,sizeof(g_ModCfgLoc), "%s%s.txt", g_configDir, modFolder);
		if(!FileExists(g_ModCfgLoc))
			return;
		
		FileToKeyValues(g_KVModCfg,g_ModCfgLoc);
	}
	
	KvJumpToKey(g_KVModCfg, "TeamColors");
	for(new i=0;i<9;i++)
	{
		decl String:teamNo[8];
		IntToString(i, teamNo, sizeof(teamNo));
		g_TeamColors[i] = KvGetNum(g_KVModCfg, teamNo, 15); // Default to grey
	}
 }
 
 /*****************************************************************
 * LoadChannels
 *
 * @breif Reads the channels from the config file into the ADT_array.
 * 
 * @noreturn
 *****************************************************************/
 public LoadChannels()
 {
	decl String:channelConfigLoc[128];
	new Handle:channelKV = INVALID_HANDLE, bool:moreKeys;
	moreKeys = true;
	
	BuildPath(Path_SM,channelConfigLoc,sizeof(channelConfigLoc),"%s/channels.txt", g_configDir);
	
	channelKV = CreateKeyValues("Channels");
	if(FileExists(channelConfigLoc))
	{
		FileToKeyValues(channelKV,channelConfigLoc);
	}
	if(channelKV == INVALID_HANDLE)
		return;
	
	KvRewind(channelKV);
	KvGotoFirstSubKey(channelKV);
	
	while(moreKeys)
	{
		new String:channelName[64], String:channelType[32], ChannelType:channelTypenum;
		
		KvGetSectionName(channelKV, channelName, sizeof(channelName));
		KvGetString(channelKV, "type", channelType, sizeof(channelType), "IRC_CHANNEL_PUBLIC");
		
		if(FindStringInArray(g_ChannelNames, channelName) != -1)
		{
			moreKeys = KvGotoNextKey(channelKV);
			continue;
		}
		
		if(!strcmp(channelType, "IRC_CHANNEL_PUBLIC"))
			channelTypenum = IRC_CHANNEL_PUBLIC; // 1
		else if(!strcmp(channelType, "IRC_CHANNEL_PRIVATE"))
			channelTypenum = IRC_CHANNEL_PRIVATE; // 2
			
		PushArrayString(g_ChannelNames, channelName);
		PushArrayCell(g_ChannelTypes, channelTypenum);
		
		moreKeys = KvGotoNextKey(channelKV);
	}
 }
 
public IRC_Tag_CommandCallback:command_Join(const argc)
{
	new String:destination[64];
	IRC_GetMsgDestination(destination, sizeof(destination));
	
	decl String:senderName[64];
	IRC_GetMsgSender(senderName, sizeof(senderName));
	
	if(argc < 1)
	{
		IRC_Notice(senderName, "Usage: !<trigger>.join #channel");
		return;
	}
	new String:channel[64];
	IRC_GetCmdArgv(0, channel, sizeof(channel));
	JoinChannel(channel);
	IRC_Notice(senderName, "Joined channel");
}

public IRC_Tag_CommandCallback:command_Part(const argc)
{
	new String:destination[64];
	IRC_GetMsgDestination(destination, sizeof(destination));
	
	decl String:senderName[64];
	IRC_GetMsgSender(senderName, sizeof(senderName));
	
	if(argc < 1)
	{
		IRC_Notice(senderName, "Usage: !<trigger>.part #channel");
		return;
	}
	new String:channel[64];
	IRC_GetCmdArgString(channel, sizeof(channel));
	PartChannel(channel);
	IRC_Notice(senderName, "Parted channel");
}


public IRC_Tag_CommandCallback:command_raw(const argc)
{
	new String:destination[64];
	IRC_GetMsgDestination(destination, sizeof(destination));
	
	decl String:senderName[64];
	IRC_GetMsgSender(senderName, sizeof(senderName));
	
	if(argc < 1)
	{
		IRC_Notice(senderName, "Usage: !<trigger>.raw [some infoz plsz]");
		return;
	}
	new String:channel[128];
	IRC_GetCmdArgString(channel, sizeof(channel));
	IRC_SendRaw(channel);
	IRC_Notice(senderName, "Parted channel");
}


public IRC_Tag_CommandCallback:command_Die(const argc)
{
	new String:destination[64];
	IRC_GetMsgDestination(destination, sizeof(destination));
		
	IRC_Action(destination, "Doesn't feel so good :S");
	IRC_SendRaw("QUIT :OHNOES!");
}


public IRC_Tag_CommandCallback:command_Commands(const argc)
{
	new String:destination[64];
	IRC_GetMsgDestination(destination, sizeof(destination));
	new String:cmdList[512];
	
	decl String:senderName[64];
	IRC_GetMsgSender(senderName, sizeof(senderName));
	
	for(new i=0;i<50;i++)
	{
		if(!g_CommandActive[i]) continue;
		
		StrCat(cmdList, sizeof(cmdList), ", ");
		StrCat(cmdList, sizeof(cmdList), g_CommandName[i]);
	}
	IRC_Notice(senderName, cmdList[2]); // Skip the first ", " from the command list
}


 
 /*****************************************************************
 * SocketError
 *
 * @breif This is the callback from the sockets extension when
 *        a socket error occurs
 * @params id the function id the error occured in
 * @params detail the error number from winsock or sockets
 * @return none
 *****************************************************************/
public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	PrintToServer("socket error %d (errno %d)", errorType, errorNum);
	LogError("socket error %d (errno %d)", errorType, errorNum);

	CloseHandle(socket);

}

public Action:RestartPlugin(Handle:timer)
{
	OnPluginStart();
	OnConfigsExecuted();
}

 //Yarr!
