/*==================================================\
 * GameConnect IRC relay, and admin tool			*
 *													*
 * Web: www.GameConnect.info						*
 * Author: Olly :D									*
 * Credits: Vipah: for testing, and putting up with *
 *			The Crashes :D							*
 *			BAILOPAN: for the help and SM			*
 *			cybermind: for help with registercmd	*
 *			FlyingMongoose, DaveB & DevNull - ideas	*
 *													*
 * License: GPL										*
 \==================================================*/
/*==================================================================================\
 *					~-ChangeLog-~													*
 *	1.0.1																			*
 *		- Only started changelog													*
 *	1.0.2																			*
 *		- Commented whole code, easier readability									*
 *		- Added !kickplayer [trigger] [playername] - Kicks the selected player		*
 *		- Added !banplayer [trigger] [playername] [time] - Bans the selected player	*
 *		- Added !relayversion - Shows the version info for each relay				*
 *		- All Channels except master get messaged when the map changes				*
 *		- All Channels get messaged when someone gets banned						*
 *		- Added limit of errors to show to stop spam								*
 *		- Added limit of Reconnects to stop server lag								*
 *		- Added irc_broadcast to send a message to ALL channels						*
 *		- Misc messages get send to all channels like mapchange						*
 *	1.0.3																			*
 *		- Removed sm_ prefix from all cvars											*
 *		- added irc_showbans - 1 to enable broadcasting of server bans				*
 *		- added irc_debug - 1 to enable debugging output from irc server			*
 *	1.0.4																			*
 *		- Fixed lots of small annoying bugs											*
 *		- Fixed not all irc data being read into plugin								*
 *		- Spamming server with JOIN every ping										*
 *		- Bots now use gcbot.bot.gamesurge.net										*
 *		- Fixed irc_showbans and irc_debug not working properly ><					*
 *		- Fixed irc_broadcast only showing first word in the string					*
 *		- Added !allchat [trigger] [on|off|1|0] to show all chat messages from server
 *		- Added !ask & !magic8 which is a BETTER version of chanserv's 8ball ;)		*
 *		- Added IrcMessage for external plugins to call. See ircrelay.inc			*
 *		- Added some basic logging to the errors, and first line of incoming data	*
 *		- Added format arguments for IrcMessage native								*
 *		- Added support for say_team												*
 *	1.0.5																			*
 *		- Added some more 8ball answers												*
 *		- Fixed 8ball needing 2 words to work										*
 *		- Changed !info to !serverinfo												*
 *		- Added !commands to list all of the commands that work with IRC Relay		*
 *		- Added basic descriptions for each command when they are types with 0 params
 *	1.0.6																			*
 *		- Added commands forplugins to register their own irc commands				*
 *		- Fixed bug where IrcMessage wouldnt send message to master on CHAN_ALL		*
 *		- Fixed bug with date and time wrong way round on relayversion				*
 *		- Added irc_groups cvar for servers to specify their own bot groups			*
 *		- Removed irc_region because addition of custom groups						*
 *		- Made FindPlayerName more accurate	for exact, and partial matches			*
 *		- Huge overhaul of the trigger system										*
 *		- !commands now shows third-party commands that have been registered		*
 *	1.0.7																			*
 *		- Fixed ban message in IRC not showing steam Or name						*
 *		- Fixed foobarness about player names										*
 *		- added irc_color cvar to enable/disable colored player names in IRC		*
 *		- Fixed some long player name problems										*
 *		- Added irc_notice to send relay replies to notice instead of channel		*
 *		- Removed ping from !playerinfo as its bugged :(							*
 *		- Fixed problems with running commands on player names						*
 *		- Fixed not getting invited by chanserv										*
 *	1.0.0																			*
 *		- Reset version number for release :D										*
 *	1.0.1																			*
 *		- Fixed un-assigned not showing name										*
 *		- Added irc_server, irc_port, irc_password for joining other servers		*
 *		- Fixed relays not always joining /me slaps ChanServ				 		*
 *		- Added irc_auth to manually set the authentication string			 		*
 *	1.0.2																			*
 *		- Fixed multiple bots spamming you with the welcome msg on JOIN				*
 *		- All commands run on a 'per-user' permission config. :D					*
 *		- Fixed broken version number in last release ><							*
 *		- Fixed relays not joining on late load										*
 *		- Fixed !relayversion not working in 1.0.1									*
 *		- New file for command permissions (/sourcemod/configs/ircrelay/permissions.txt
 *		- Updated IrcRegisterCommand native to use the new permission types			*
 *		- Stopped some excess flood messages with multiple channels					*
 *		- Fixed player names not being found :(	
 *	1.0.2b
 *		- Updated to work with version 1.2.0.0 of sockets							*
  *	1.0.2c
 *		- Updated to so its not required to run for other plugins using the api (thx ^BuGs^						*\==================================================================================*/
#pragma semicolon 1

#include <sourcemod>
#include <console>
#include <events>
#include <entity>
#include <string>
#include <clients>
#include <core>
#include <timers>
#include <functions>
#include <sockets>
#include <keyvalues>
#include <ircrelay>

#define VERSION "1.0.2b"
#define BUILDD __DATE__
#define BUILDT __TIME__
#pragma dynamic 65536

public Plugin:myinfo = 
{
	name = "IRC Relay",
	author = "Olly",
	description = "IRC Relay",
	version = VERSION,
	url = "http://www.gameconnect.info/"
};


new String:VersionString[128];

new errorCount;
new fatalError;
new Handle:socket;

//config stuff
new String:permFile[PLATFORM_MAX_PATH];
new Handle:permKV;

new Handle:nameTrigger;
new Handle:serverMaster;

new Handle:ircLogin;
new Handle:ircPass;
new Handle:ircChan;
new Handle:ircNick;
new Handle:ircMaster;

new Handle:ircShowBans;
new Handle:ircDebug;
new Handle:ircGroups;
new Handle:ircColor;
new Handle:ircNotice;
new Handle:ircName;

new Handle:ircServer;
new Handle:ircPort;
new Handle:ircPassword;
new Handle:ircAuth;

new String:login[64];
new String:pass[64];
new String:defchannel[64];
new String:chanarray[10][64];
new String:GroupArray[10][64];
new String:nickname[64];
new String:iAuth[128];
new String:iServer[64];
new iPort;
new String:iPassword[64];

new iColor;
new iNotice;

new Handle:gameIP;
new String:ip[32];
new String:tempChannel[64];

new master;
new showScore;
new queryName;
new hooked;
new showAllChat;

new String:command[256];
new String:NameTrig[128];
new String:Name[128];	
new String:MasterChan[64];
new String:IRCData[4096];

// Permission stuff
new level[100];
new String:relayFile[PLATFORM_MAX_PATH];
new Handle:relayKV;

// Stuff for plugin self registering...
new Handle:CmdForwards[100];
new bool:FwdEnabled[100];
new String:CmdText[100][128];
new String:argv[10][512];
new permissions[100];
new argc = 0;


new String:tempUser[64];

// Define some stupid phrases for the 8ball (because i can :D)
new String:EightBallResponse[][] = 
{ 
	"What are you, gay?", 
	"Stop fucking SHAKING ME!",
	"What the hell is wrong with you?",
	"I don't know, what do YOU think?",
	"Why don't you look at me while we make love?",
	"Come join the Church of the Fonz!",
	"42",
	"You're not just whistling Dixie...are you?",
	"If Morgan Freeman and Christopher Walken had a baby, what would it sound like?",
	"My foot, your ass, lets make a date.",
	"Pie",
	"...Dumbass...",
	"Only fools are slaves of time and space.",
	"What are you asking me for!?",
	"If I knew that, do you think I would tell YOU?",
	"Get out!",
	"Get to the chopper!",
	"It's not a tumor!",
	"Do not deny the Flying Spaghetti Monster!",
	"The increase in global temperature is a direct effect from the decrease in number of pirates.",
	"of course",
	"HELL NO",
	"Outlook not so good",
	"Are you kidding?",
	"Forget about it.",
	"Without a doubt. Nah, I’m just messing with you, you’re definitely going to die",
	"Outlook not so good. Especially since you’re so goddamn fat.",
	"How should I know?!",
	"Maybe....",
	"Are you mad?! Of course not!",
	"Are you insane?!",
	"Sure!",
	"Looks good to me!",
	"I have my doubts",
	"Your Kiddin` right?"
};



/*****************************************************************
 * IrcMessage
 *
 * @breif This native can be called by external plugins to send a
 *		  message to the irc server.
 * @param destination	Which channels to send the message to.
 *						CHAN_MASTER - Send message to master channel
 *						CHAN_NOT_MASTER - Send to all channels but master
 *						CHAN_ALL - Send message to all channels.
 * @param String:message[] The message to send
 * @param any			format args
 * @noreturn
 *****************************************************************/
public Native_IrcMessage(Handle:plugin, numParams)
{
	// Create a new string with the size of the paramater
	new String:message[1600];
	decl String:buffer[1600], written;
    // Get the string
	GetNativeString(2, message, 1600);
    // Get the destination
    
	new destination = GetNativeCell(1);
	
	FormatNativeString(0, 2, 3, 1600, written, buffer);
	
	if(destination == CHAN_ALL || destination == CHAN_NOT_MASTER)
	{
		for(new c=0;c<8;c++)
		{
			// if its not blank
			if(strlen(chanarray[c]) > 0)
			{
				// send the command to the channel
				PrivMsg(chanarray[c], buffer);
				if(destination == CHAN_ALL)
				{
					PrivMsg(MasterChan, buffer);
				}
			}
		}
	}
	if(destination == CHAN_MASTER)
	{
		if(strlen(MasterChan) > 0)
		{
			PrivMsg(MasterChan, buffer);
		}
	}
}

/*****************************************************************
 * RegisterIrcCommand
 *
 * @breif This native will allow external plugins to register theri
 *		  Own IRC command
 * @param String:cmd[]				The command to register
 * @param String:mode[]				The minimum user mode to run this cmd (@, %, +)
 * @param Function:calback			the callback
 * @noreturn
 *****************************************************************/
public Native_RegisterIrcCommand(Handle:plugin, numParams)
{
	for(new i=0;i<100;++i)
	{
		if(FwdEnabled[i] == false)
		{	
			CmdForwards[i] = CreateForward(ET_Ignore, Param_String);
			AddToForward(CmdForwards[i], plugin, Function:GetNativeCell(3));
			GetNativeString(1, CmdText[i], 127);
			FwdEnabled[i] = true;
			new String:temp[16];
			GetNativeString(2, CmdText[i], 16);
			if(!strcmp(temp, "@"))
				permissions[i] = 1;
			else if(!strcmp(temp, "%"))
				permissions[i] = 2;
			else if(!strcmp(temp, "+"))
				permissions[i] = 3;
			else
				permissions[i] = 4;
			break;
		}
	}
}

/*****************************************************************
 * IRC_GetCmdArgc
 *
 * @breif This native will get the arg count for the current cmd
 * @return		Returns the amount of arguments sent with the cmd
 *****************************************************************/
public Native_IRC_GetCmdArgc(Handle:plugin, numParams)
{
	return argc;
}

/*****************************************************************
 * IRC_GetCmdArgv
 *
 * @breif		This native will get the value of the arg
 * @param		argnum			The argument number to get
 * @param		String:strArg	The place to save the arg to
 * @noreturn
 *****************************************************************/
public Native_IRC_GetCmdArgv(Handle:plugin, numParams)
{
	new argnum = GetNativeCell(1);
	new len = GetNativeCell(2);
	PrintToServer("GetCmdArgv: %s", argv[argnum]);
	SetNativeString(3, argv[argnum], len, false);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IrcMessage", Native_IrcMessage);
	CreateNative("IrcGetCmdArgc", Native_IRC_GetCmdArgc);
	CreateNative("IrcGetCmdArgv", Native_IRC_GetCmdArgv);
	CreateNative("RegisterIrcCommand", Native_RegisterIrcCommand);
	return true;
}

/*****************************************************************
 * OnMapStart
 *
 * @breif This function is called when the a new map starts
 * @noreturn
 *****************************************************************/
public OnMapStart()
{
	new String:mapname[128];
	new String:hostname[128];
	new String:strMapcChange[256];
	// Get the current map name
	GetCurrentMap(mapname, 127);
	// Get the servername
	new Handle:gameName = FindConVar("hostname");
	GetConVarString(gameName, hostname, 127);
	Format(strMapcChange, 255, "%s's map changed to\x02 %s\x0F", hostname, mapname);
	// loop through all the channels
	for(new c=0;c<8;c++)
	{
	    // if it isnt blank
		if(strlen(chanarray[c]) > 0)
		{
			// join the channel
			//PrivMsg(chanarray[c], strMapcChange);
		}
	}
}

/*****************************************************************
 * OnPluginStart
 *
 * @breif This function is called when the plugin starts up
 * @noreturn
 *****************************************************************/
public OnPluginStart()
{	
	Format(VersionString, 127, "Current version:\x02 %s\x0F. Build Date:\x02 %s\x0F. Build Time:\x02 %s\x0F.", VERSION, BUILDD, BUILDT);
	// Create the convar for the trigger that will activate the bot
	nameTrigger = CreateConVar("irc_name_trigger","","Sets the name trigger in the irc server.",FCVAR_PLUGIN);
	
	CreateConVar("irc_version",VERSION,"Current version of IRC Relay",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	CreateConVar("sm_irc_version",VERSION,"Current version of IRC Relay",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	// Create the convar that sets if the bot should answer to general commands, like !relayhelp
	serverMaster = CreateConVar("irc_master","","Which region is the server in.",FCVAR_PLUGIN);
	// Create the convar for the trigger that will activate the bot
	ircMaster = CreateConVar("irc_master_channel","","Which region is the server in.",FCVAR_PLUGIN);
	// Create the convar for the groups the bot belongs to.
	ircGroups = CreateConVar("irc_groups","","Define which groups the bot belongs to",FCVAR_PLUGIN);
	// Create the convar that will enable debugging
	ircDebug = CreateConVar("irc_debug","0","Enable Debugging output",FCVAR_PLUGIN);
	// Create the convar for the trigger enable banning messages (turn off for remote plugins)
	ircShowBans = CreateConVar("irc_showbans","1","Show server ban messages",FCVAR_PLUGIN);
	// Allows user to enable/disable colored names in IRC
	ircColor = CreateConVar("irc_color","1","Should use colors. 1=yes 0=no",FCVAR_PLUGIN);
	// Chooses the command response type
	ircNotice = CreateConVar("irc_notice","0","Should send notice instead of privmsg. 1=yes 0=no",FCVAR_PLUGIN);
	// The ident of the relay
	ircName = CreateConVar("irc_name","Gaben","Set the name of the bot.",FCVAR_PLUGIN);
	// server
	ircServer = CreateConVar("irc_server","","The IRC server address to connect to.",FCVAR_PLUGIN);
	// Chooses the command response type
	ircPort = CreateConVar("irc_port", "6667","IRC server port",FCVAR_PLUGIN);
	// Chooses the command response type
	ircPassword = CreateConVar("irc_password","","The password of the server.",FCVAR_PLUGIN);
	// The IRC auth string
	ircAuth = CreateConVar("irc_auth","","The password of the server.",FCVAR_PLUGIN);
	// Set the random seed for the 8ball
	SetRandomSeed(31337);
	// Find the server cvar for the game server's IP
	gameIP = FindConVar("ip");
	// Find the server cvar for the game server's port
	//gamePort = FindConVar("hostport");
	
	// Create convars for relay settings
	ircLogin = CreateConVar("irc_login","","Sets the AuthServ login",FCVAR_PLUGIN);
	ircPass = CreateConVar("irc_pass","","Sets the AuthServ password",FCVAR_PLUGIN);
	ircChan = CreateConVar("irc_channel","","Sets the AuthServ channel",FCVAR_PLUGIN);
	ircNick = CreateConVar("irc_nickname","","Sets the AuthServ nickname",FCVAR_PLUGIN);
	
	if(hooked != 1)
	{
		// Hook the player say messages
		RegConsoleCmd("say", Command_Say);
		RegConsoleCmd("say_team", Command_Say);
		
		// Create server commands to control the bot
		RegServerCmd("irc_relay", Command_relay);
		
		RegServerCmd("irc_broadcast", Command_broadcast);
		
		RegServerCmd("irc_join", Command_join);
		RegServerCmd("irc_leave", Command_leave);
		
		// Hook the banid command
		RegServerCmd("banid", Command_Banid);
		
		// Hook the exit command
		RegServerCmd("exit", Command_exit);
		
		// Key Values for IRC user permissions
		BuildPath(Path_SM,relayFile,sizeof(relayFile),"data/relay_perms.txt");
		relayKV = CreateKeyValues("ircrelay");
		if(FileExists(relayFile))
		{
			DeleteFile(relayFile);
			FileToKeyValues(relayKV,relayFile);
		}
		// Key Values for configuration
		BuildPath(Path_SM,permFile,sizeof(permFile),"configs/ircrelay/permissions.txt");
		permKV = CreateKeyValues("ircrelay-perms");
		if(FileExists(permFile))
		{
				FileToKeyValues(permKV,permFile);
		}	
		hooked = 1;
	}
	
	
	// Create socket and assign to socket
	socket = CreateSocket(SOCKET_TCP);
	// set callbacks
	SetErrorCallback(socket, SocketError);
	SetReceiveCallback(socket, SocketReceive);
	SetDataString(socket, IRCData);
	CreateTimer(3.0, ServerCfg);
}

public OnPluginEnd()
{
	CloseHandle(permKV);
	CloseHandle(relayKV);
	PrintToServer("[IRC RELAY] Unloaded and closed sockets");
	LogToGame("[IRC RELAY] Unloaded and closed sockets");
	SocketClose(socket);
}

/*****************************************************************
 * OnPluginStart_Delay
 *
 * @breif This function is called 3 seconds after PluginStart so
 *        that the cvars can be loaded by the server
 * @params Handle:timer the handle of the timer that called it
 * @noreturn
 *****************************************************************/
 	new String:botGroup[2048];
public Action:ServerCfg(Handle:timer)
{
	// Get the values of the cvars
	GetConVarString(ircLogin, login, 63);
	GetConVarString(ircPass, pass, 63);
	GetConVarString(ircChan, defchannel, 63);
	GetConVarString(ircNick, nickname, 63);
	GetConVarString(ircMaster, MasterChan, 63);
	GetConVarString(nameTrigger, NameTrig, 128);
	iNotice = GetConVarInt(ircNotice);
	GetConVarString(ircName, Name, 64);
	GetConVarString(ircServer, iServer, 64);
	GetConVarString(ircPassword, iPassword, 64);
	GetConVarString(ircAuth, iAuth, 128);
	
	iPort = GetConVarInt(ircPort);
	// Get the value of the gameip, and port
	GetConVarString(gameIP, ip, 32);
	// Split the channels in the config, and put them in channelarray
	explode(chanarray, 9, defchannel, 63, ' ');
	GetConVarString(ircGroups, botGroup, 2048);
	explode(GroupArray, 10, botGroup, 1023, ' ');
		
	// Bind the ip to the same ip the server is on
	SocketBind(socket, ip, 0);
	// Connect to gamesurge
	ConnectSocket(socket, iServer, iPort);
	if(strlen(iPassword) > 1)
	{
		Format(command, 127, "PASS %s\n\r\n\r", iPassword);
		SocketSend(socket, command);
	}
	// format the user and nick commands
	Format(command, 127, "USER %s %s %s :%s\n\rNICK %s\n\r\n\r", Name, Name, Name, Name, nickname);
	// send them to the server
	SocketSend(socket, command);		
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
public SocketError(id, detail, Handle:arg)
{
	if(fatalError >= 5)
	{
		PrintToServer("[IRC RELAY] Shutting down plugin, due to multiple Fatal errors :(");
		LogToGame("[IRC RELAY] Shutting down plugin, due to multiple Fatal errors :(");
		//SocketClose(socket);
		CloseHandle(GetMyHandle());
		fatalError = 0;
		return;
	}
	if(errorCount >= 5)
	{	
		++fatalError;
		PrintToServer("[IRC RELAY] Restarting plugin due to multiple errors...");
		LogToGame("[IRC RELAY] Restarting plugin due to multiple errors...");
		SocketClose(socket);
		OnPluginStart();
		errorCount = 0;
		return;
	}
	// OOps we forgot to type a hostname when connecting the socket
	if(id == EMPTY_HOST)
	{
		PrintToServer("[IRC RELAY] Error: Missing Host");
		LogToGame("[IRC RELAY] Error: Missing Host");
	}
	// Host doesnt exist, or cant resolve using dns
	else if(id == NO_HOST)
	{
		PrintToServer("[IRC RELAY] Error: Could not resolve domain name");
		LogToGame("[IRC RELAY] Error: Could not resolve domain name");
	}
	// Something went wrong while connecting
	else if(id == CONNECT_ERROR)
	{
		PrintToServer("[IRC RELAY] Error during connection. Error ID: %d", detail);
		LogToGame("[IRC RELAY] Error during connection. Error ID: %d", detail);
	}
	// Something went wrong while sending
	else if(id == SEND_ERROR)
	{
		PrintToServer("[IRC RELAY] Error sending data. Error ID: %d", detail);
		LogToGame("[IRC RELAY] Error sending data. Error ID: %d", detail);
	}
	// Something went wrong while binding the ip/port
	else if(id == BIND_ERROR)
	{
		PrintToServer("[IRC RELAY] Error: Missing Host");
		LogToGame("[IRC RELAY] Error: Missing Host");
	}
	// something went wrong while receivng data
	else if(id == RECV_ERROR)
	{
		LogToGame("[IRC RELAY] Error receiving data. Error ID: %d", detail);
		PrintToServer("[IRC RELAY] Error receiving data. Error ID: %d", detail);
	}
	++errorCount;
}
 new bool:joined = false;
 new chanid = 0;
public Action:JoinChannels(Handle:timer)
{
	if(chanid >= 7)
	{
		CloseHandle(timer);
		return;
	}
	if(strlen(chanarray[chanid]) > 2)
	{
		Join(chanarray[chanid]);	
	}
	chanid++;
	CreateTimer(1.0, JoinChannels);		
	if(joined == false)
	{
		Join(MasterChan);
		if(master == 1)
			PrivMsg(MasterChan, "\x02IRC Relay\x0F v%s. Type \x1F!commands\x1F for a list of commands.", VERSION);
	}
	joined = true;	
}
/*****************************************************************
 * SocketReceive
 *
 * @breif This is the callback from the sockets extension when
 *        new data is received
 * @params size The size of the data that is received
 * @return none
 *****************************************************************/

public SocketReceive(size, Handle:arg)
{	
	// Get the current map
	new String:lines[21][1024];
	// Split up the incoming data into lines to manage easier
	new count = explode(lines, 19, IRCData, 1024,  '\n');
	// loop though the 4 'buffer' lines

	for(new i=0;i<count;i++)
	{
		new String:IrcArguments[10][512];
		// debug to show incomming data from IRC
		if(GetConVarInt(ircDebug) == 1)
		{
			PrintToServer("Line %d: %s", i, lines[i]);
			LogToGame("[IRC RELAY] Debug: %s", lines[i]);
		}
		new ArgLen = GetIrcArgs(lines[i], IrcArguments);
		new IrcArgCount = GetArgCount(IrcArguments, ArgLen);
		/*****************************************************************
		 * Received names list
		 *
		 *****************************************************************/
		if(GetNumeric(lines[i]) == 353)
		{
			new String:temp[100][512];
			new max = explode(temp, 99, lines[i], 4096, ' ');
			for(new l=6;l<max;l++)
			{
				if(l > 100)
					break;
				new String:lvl[16];
				new String:name[128];
				Format(lvl, 2, temp[l]);
				
				if(StrContains(temp[l], "@") !=-1 || StrContains(temp[l], "+") !=-1 || StrContains(temp[l], "%") !=-1)
				{
					if(l==max-1)
						Format(name, strlen(temp[l][1]), "%s\0", temp[l][1]);
					else
						Format(name, strlen(temp[l][1])+1, "%s\0", temp[l][1]);
				}
				else
				{
					if(l==max-1)
						Format(name, strlen(temp[l]), "%s\0", temp[l]);	
					else	
						Format(name, strlen(temp[l])+1, "%s\0", temp[l]);
				}
				
				if(!strcmp(lvl, "@"))
					level[l-6] = 1;
				else if(!strcmp(lvl, "%"))
					level[l-6] = 2;
				else if(!strcmp(lvl, "+"))
					level[l-6] = 3;
				else 
					level[l-6] = 4;
				
				KvRewind(relayKV);
				if(!KvJumpToKey(relayKV,name,false))
				{
					KvJumpToKey(relayKV,name,true);
					KvSetNum(relayKV,temp[4],level[l-6]);
					PrintToServer("Added: %s Level: %d", name, level[l-6]);
				}
				else
				{
					KvJumpToKey(relayKV,name);
					KvSetNum(relayKV,temp[4],level[l-6]);
					PrintToServer("Updated: %s Level: %d", name, level[l-6]);
				}
			}
			KvRewind(relayKV);
		}
		/*****************************************************************
		 * End of MOTD
		 *
		 *****************************************************************/
		if(GetNumeric(lines[i]) == 376 || GetNumeric(lines[i]) == 422 || (StrContains(lines[i], "END OF M", false) > -1))
		{
			new String:authstring[128];	
			// Format and msg AuthServ to auth our accoutn
			//Format(authstring, 127, "AUTH %s %s", login, pass);
			//PrivMsg("AuthServ@Services.GameSurge.net", authstring);
			Format(authstring, 128, iAuth, login, pass);
			Format(authstring, 128, "%s\n\r", authstring);
			SocketSend(socket, authstring);
			// Format and send the string to add masks
			//Format(authstring, 127, "addmask *@*");
			//PrivMsg("AuthServ", authstring);
			// Get our custom title :D
			Format(authstring, 127, "title bot", login);
			PrivMsg("hostserv", authstring);
			
			// Dont know what this is, remove maybe?
			//SocketSend(socket, command);
			// Set mode +x so we hide ip
			//SetMode("x");
			
			// For all channels in the channel array
			CreateTimer(5.0, JoinChannels);	
		}
		
		/*****************************************************************
		 * PING - Ping command from irc
		 *
		 *****************************************************************/
		// If the irc server requests a ping
		if(strncmp(lines[i], "PING", 4, false) == 0)
		{
			new String:pingid[40][40];
			// Split up the string to check what the ping host is, so we can send it back
			explode(pingid, strlen(lines[i]), lines[i], strlen(lines[i]), ':'); 
			new String:pong[40];
			// Format the pong command
			Format(pong, 40, "PONG :%s\n\r", pingid[1]);
			// Send the pong command
			SocketSend(socket, pong);
			
		}
//<=================================================================>
		new String:args[6][512];
		new String:subarg[7][512];
		new String:sender[2][64];
		new String:Trigger[64];
		
		GetIRCSender(lines[i], sender);
		// Get the  irc settings
		master = GetConVarInt(serverMaster);
		// strip the crap from the start of the message, we dont need it now
		GetIRCMessage(lines[i], args);
		new String:CurChan[4][128];
		// Extract the channel that the mesage was sent from
		GetIRCChannel(lines[i], CurChan);
		// extract the trigger that was sent with the command
		GetBotTrigger(args[2], subarg, Trigger);
		
		// if the some noob kicked the bot
		if(StrContains(CurChan[1], "KICK", false) > -1)
		{
		    // for each channel in array	
			for(new c=0;c<8;c++)
			{
				// if its not blank
				if(strlen(chanarray[c]) > 0)
				{
					// join the channel
					Join(chanarray[c]);
					
				}
			}
			// join the master channel
			Join(MasterChan);
		}
		
		if(StrContains(args[1], "Closing", false) > -1)
		{
			// Something went bad, server closed our connection for flood, or alike
			// So reconnect.
			SocketClose(socket);
			OnPluginStart();
		}
		
		if(StrContains(args[1], "JOIN", false) > -1)
		{
			// New player joined so lets send them our notice
			if(master == 1)
				Notice(sender[0][1], "\x02IRC Relay\x0F v%s. Type \x1F!commands\x1F for a list of commands.", VERSION);
		}
		
		if(StrContains(args[1], "MODE", false) > -1)
		{
			if(joined == true)
			{
			//	FileToKeyValues(relayKV,relayFile);
			//	IrcArguments[1][strlen(IrcArguments[1])-1] = '\0';
			//	new ulevel;
			//	if(!KvJumpToKey(relayKV,IrcArguments[1],false))
			//	{
			//		KvJumpToKey(relayKV,IrcArguments[1],true);
			//	}
			//	if(!strcmp(IrcArguments[0], "o"))
			//		ulevel = 1;
			//	else if(!strcmp(IrcArguments[0], "h"))
			//		ulevel = 2;
			//	else if(!strcmp(IrcArguments[0], "v"))
			//		ulevel = 3;
			//	else
			//		ulevel = 4;
						
			//	KvSetNum(relayKV,CurChan[2],ulevel);
			//	KvRewind(relayKV);
				IrcArguments[1][strlen(IrcArguments[1])-1] = '\0';
				if(strcmp(IrcArguments[1], nickname))
				{
					Format(command, 128, "NAMES %s\r\n", CurChan[2]);
					SocketSend(socket, command);
				}
			}
		}
		
		if(StrContains(args[1], "NICK", false) > -1)
		{
			if(joined == true)
			{
				args[2][strlen(args[2])-1] = '\0';
				KvRewind(relayKV);
				KvJumpToKey(relayKV,sender[0][1]);
				KvGetSectionName(relayKV, command, 128);
				KvSetSectionName(relayKV, args[2]);
				KvRewind(relayKV);
			}
		}
		
		// if the user sent !msg command
		/*****************************************************************
		 * !msg - Message all players in the server
		 *
		 * Useage !msg [trigger] [message to send]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!msg", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'msg' command will send a public message to the server specified by the trigger.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No message specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !msg [trigger] [message]\x0F");
				continue;
			}
			// if the command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// Get the text to send in the message
				Format(command, 127, "%s", args[2][strlen(subarg[1])+5]);
				
				// if i'm allowed to exec this command in this channel
				if(CheckPerms(CurChan[2], sender[0][1], "msg"))
				{
					// send the message to the user
					SendMsg_SayText2(0, "\x03[IRC]\x04 %s:\x01 %s", sender[0][1], command);
					// send message to channel saying it worked
					SendMessage(sender[0][1], CurChan[2], "Message Sent.");
				}
			}
		}
		
		/*****************************************************************
		 * !allchat - Enables sending all chat messages to irc channel
		 *
		 * Useage !allchat [trigger] [1|0]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		
		if(StrContains(IrcArguments[0], "!allchat", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'allchat' command will enable you to see all chat messages in the server");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !allchat [trigger] [1|0|on|off]\x0F");
			}
			// if the command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// Get the bool value
				Format(command, 127, "%s", IrcArguments[2]);
				// are we allowed ot do it?
				if(CheckPerms(CurChan[2], sender[0][1], "allchat"))
				{
					if(StrToBool(IrcArguments[2]) == 1)
					{
						PrivMsg(CurChan[2], "All Chat messages\x02 enabled\x0F");
						showAllChat = 1;
					}
					else
					{
						PrivMsg(CurChan[2], "All Chat messages\x02 disabled\x0F");
						showAllChat = 2;
					}
				}
			}
		}
		
		/*****************************************************************
		 * !auth - Re auths all bots with AuthServ
		 *
		 * Useage !auth
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !auth command
		if(StrContains(IrcArguments[0], "!auth", false) != -1)
		{	
			// if the command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// get the irc user that sent the command
				GetIRCSender(lines[i], sender);
				// if im allowed to run this command here
				if(CheckPerms(CurChan[2], sender[0][1], "auth"))
				{
					// get the irc login stuff from the config
					GetConVarString(ircLogin, login, 63);
					GetConVarString(ircPass, pass, 63);
					new String:authstring2[128];
					// format the string to send
					Format(authstring2, 127, "AUTH %s %s", login, pass);
					// send it to authserv
					PrivMsg("AuthServ@Services.GameSurge.net", authstring2);
					// send message to current channel saying it worked
					PrivMsg(CurChan[2], "Re authed.");
				}
			}
		}
		
		/*****************************************************************
		 * !ask - Displays some crazy message :P
		 *
		 * Useage !ask|!magic8 [message]
		 * Permissions - None
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!ask", false) != -1 || StrContains(IrcArguments[0], "!magic8", false) != -1)
		{
			// am i the master bot
			if(master == 1)
			{
				if(!CheckPerms(CurChan[2], sender[0][1], "ask") && !CheckPerms(CurChan[2], sender[0][1], "magic8"))
					continue;
			
				// Make sure they typed a question
				if(IrcArgCount < 1 && master == 1)
				{				
					SendMessage(sender[0][1], CurChan[2], "The 'ask' or 'magic8' commands answer ANY question you specify.");
					SendMessage(sender[0][1], CurChan[2], "Error:\x02 You didnt ask a question\x0F");
					SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !ask|!magic8 [question]\x0F");
					continue;
				}
				// Get the name of whoever sent the message
				GetIRCSender(lines[i], sender);
				new String:ballOutput[256];
				// Add the formatting
				Format(ballOutput, 255, "\x02 %s\x0F: %s", sender[0][1], EightBallResponse[GetRandomInt(1, 35)]);
				// Send the string to the channel
				PrivMsg(CurChan[2], ballOutput);
				continue;
			}
		}
		
		/*****************************************************************
		 * !as - Sends a private message to AuthServ
		 *
		 * Useage !as [trigger] [message]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !as command (msg AuthServ)
		if(StrContains(IrcArguments[0], "!as", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'as' command will send a private message to AuthServ.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No message specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !as [trigger] [message]\x0F");
				continue;
			}
			if(!CheckPerms(CurChan[2], sender[0][1], "as"))
					continue;
			// if command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// format the rest of the message
				Format(command, 127, "%s", args[2][strlen(subarg[1])+5]);
				// send the message to authserv
				PrivMsg("AuthServ@Services.GameSurge.net", command);
				// show the current channel that it worked
				PrivMsg(CurChan[2], "Sent:\x02 %s \x0F", command);
			}
		}
		
		/*****************************************************************
		 * !pmsg - Sends a private message to a player in the server
		 *
		 * Useage !pmsg [trigger] [playername] [message]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !pmsg command
		if(StrContains(IrcArguments[0], "!pmsg", false) != -1)
		{	
			if(IrcArgCount < 3 && master == 1)
			{		
				SendMessage(sender[0][1], CurChan[2], "The 'pmsg' command will send a private message to the player in the specified server.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No message specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !pmsg [trigger] [playername] [message]\x0F");
			}
			// get the text to pmsg
			Format(command, 127, "%s", args[2][strlen(subarg[1])+strlen(subarg[2])+7]);
			// get the irc user who ran the command
			GetIRCSender(lines[i], sender);
			
			// if the message is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// if i'm allowed to run this command here
				if(CheckPerms(CurChan[2], sender[0][1], "pmsg"))
				{
					new String:name[64];
					// get the partial plyer name to search for
					Format(name, strlen(IrcArguments[2]), "%s", IrcArguments[2]);
					// Search through all the players till i find a match
					new plrName = FindPlayerName(name);
					// cant find player
					if(plrName == -1)
					{	
						// show channel that i cant find that user
						SendMessage(sender[0][1], CurChan[2], "Cannot find that player in the server.");
					}
					// multiple players with that name
					else if(plrName == -2)
					{
						// show message that they need to be more specific					
						SendMessage(sender[0][1], CurChan[2], "There are multiple players with that name, please be more specific.");
						
					}
					// yay, we found the user
					else 
					{
						new String:npame[64];
						// get their full name
						GetClientName(plrName, npame, 63);
						// format the string to send to the channel
						Format(subarg[3], 64, "Message sent to \x02%s\x0F.", npame);
						// send the message to the user ingame
						SendMsg_SayText2(plrName, "\x03[IRC]\x04 %s\x01 (Private): %s", sender[0][1], command);
						// send the message to the channel that the command worked					
						SendMessage(sender[0][1], CurChan[2], subarg[3]);	
						
					}
				}
			}
			
		}
		
		/*****************************************************************
		 * !relayhelp - Shows the help message to using the bot
		 *
		 * Useage !relayhelp
		 * Permissions - None
		 *****************************************************************/
		// if they ran !relayhelp
		if(StrContains(IrcArguments[0], "!relayhelp", false) != -1)
		{
			// if i am the master bot
			if(master == 1){
				if(!CheckPerms(CurChan[2], sender[0][1], "relayhelp"))
					continue;
				// copy the current channel name to tempChannel
				strcopy(tempChannel,  63, CurChan[2]);
				strcopy(tempUser, 63, sender[0][1]);
				// start a timer to spew the help stuff
				CreateTimer(1.0, PrintHelp);
			}
		}
		
		/*****************************************************************
		 * !triggers - Displays the current server trigger
		 *
		 * Useage !triggers
		 * Permissions - None
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!triggers", false) != -1)
		{
			if(!CheckPerms(CurChan[2], sender[0][1], "triggers"))
					continue;
			new String:buffer[1024];
			new String:buffer2[1024]; 
			new String:buffer3[1024]; 
			GetConVarString(nameTrigger, NameTrig, 128);
			GetConVarString(ircGroups, botGroup, 2048);
			explode(GroupArray, 10, botGroup, 1023, ' ');
			
			Format(buffer, 1023, "\x02Trigger:\x0F %s - \x02Groups:\x0F #all ", NameTrig);
			
			for(new a=0;a<10;++a)
			{
				if(strlen(GroupArray[a]) > 0)
				{
					Format(buffer2, 1023, "%s#%s ", buffer,  GroupArray[a]);	
				}		
			}
			Format(buffer3, 1023, "%s%s", buffer, buffer2);	
			
			SendMessage(sender[0][1], CurChan[2], buffer);
			
		}
		
		/*****************************************************************
		 * !relayversion - Displays the current relay version
		 *
		 * Useage !relayversion
		 * Permissions - None
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!relayversion", false) != -1)
		{
			if(!CheckPerms(CurChan[2], sender[0][1], "relayversion"))
					continue;
			// message the current channel my version info
			SendMessage(sender[0][1], CurChan[2], VersionString);	
		}
		
		/*****************************************************************
		 * !commands - Displays a full list of commands that will work with the relay
		 *
		 * Useage !commands
		 * Permissions - None
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!commands", false) != -1)
		{
			if(!CheckPerms(CurChan[2], sender[0][1], "commands"))
					continue;
			if(master == 1)
			{
				new String:buffer[1024];				
				// message the current channel my version info			
				SendMessage(sender[0][1], CurChan[2], "\x02 Core Commands:\x0F");
				SendMessage(sender[0][1], CurChan[2], "\x95 !msg !allchat !auth !ask !magic8 !as !pmsg !relayhelp !triggers !relayversion !players !scores !playerinfo !serverinfo !join !rcon !kickplayer !banplayer !nick !masterchannel");
				SendMessage(sender[0][1], CurChan[2], " Type a command in on its own, to see useage info");
				SendMessage(sender[0][1], CurChan[2], "\x02 Third-Party Commands (external plugins):\x0F");
				
				new tmpcount=0;
				for(new a=0;a<10;++a)
				{
					if(strlen(GroupArray[a]) > 0)
					{
						Format(buffer, 1023, "%s%s ",buffer, CmdText[a]);
						tmpcount++;	
					}		
				}
				if(tmpcount == 0)
				{	
					SendMessage(sender[0][1], CurChan[2], "\x95 None");
					
				}
				else
				{
					Format(buffer, 1023, "\x95 %s", buffer);
					SendMessage(sender[0][1], CurChan[2], buffer);
				}
			}
		}
					
		/*****************************************************************
		 * !players - Lists all players that are in the server
		 *
		 * Useage !players [trigger]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !players
		if(StrContains(IrcArguments[0], "!players", false) != -1)
		{	
			if(!CheckPerms(CurChan[2], sender[0][1], "players"))
					continue;
			if(IrcArgCount < 1 && master == 1)
			{				
				SendMessage(sender[0][1], CurChan[2], "The 'players' command will list all of the players in the specified server.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No trigger specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !players [trigger]\x0F");
			}	
			// if this is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// copy current channel name to var
				strcopy(tempChannel,  63, CurChan[2]);
				strcopy(tempUser, 63, sender[0][1]);
				// player loop count 0
				showScore = 0;
				// start anti-flood timer to show players
				CreateTimer(1.0, PrintPlayers);
			}
		}
		
		/*****************************************************************
		 * !playerinfo - Shows detailed info about a player in the server
		 *
		 * Useage !playerinfo [trigger] [playername]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !playerinfo
		if(StrContains(IrcArguments[0], "!playerinfo", false) != -1)
		{	
			if(GetNumArgs(lines[i]) < 2 && master == 1)
			{		
				SendMessage(sender[0][1], CurChan[2], "The 'playerinfo' command will show some detailed info on the specified player.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No name specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !playerinfo [trigger] [playername]\x0F");
			}	
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// if i'm allowed to run that here
				if(CheckPerms(CurChan[2], sender[0][1], "playerinfo"))
				{
					new String:name[64];
					// get the name of the player to search for
					Format(name, strlen(subarg[2]), "%s", IrcArguments[2]);
					// search though players until i find the user
					new plrName = FindPlayerName(name);
					// player isnt there
					if(plrName == -1)
					{
						// send error to channel
						SendMessage(sender[0][1], CurChan[2], "Cannot find that player in the server.");
						
					}
					// player found multple times
					else if(plrName == -2)
					{
						// send the error to the chanel
						SendMessage(sender[0][1], CurChan[2], "There are multiple players with that name, please be more specific.");				
					}
					// yay, we found them
					else 
					{
						// put the found id into the global
						queryName = plrName;
						//copy the current channel to global
						strcopy(tempChannel,  63, CurChan[2]);
						strcopy(tempUser, 63, sender[0][1]);
						// start anti-flood timer
						CreateTimer(1.0, PlayerDetail);
					}
				}
			}
		}
		
		/*****************************************************************
		 * !scores - Lists all the players in the server, with scores
		 *
		 * Useage !scores [trigger]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !scores
		if(StrContains(IrcArguments[0], "!scores", false) != -1)
		{	
			if(!CheckPerms(CurChan[2], sender[0][1], "scores"))
					continue;
			if(IrcArgCount < 1 && master == 1)
			{				
				SendMessage(sender[0][1], CurChan[2], "The 'scores' command will list all of the players and their scores from the specified server");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No trigger specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !scores [trigger]\x0F");
			}		
			//if its for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// copy the current channel to global
				strcopy(tempChannel,  63, CurChan[2]);
				strcopy(tempUser, 63, sender[0][1]);
				// enable showing of scores
				showScore = 1;
				// start anti-flood timer
				CreateTimer(1.0, PrintPlayers);
			}
		}
		
		/*****************************************************************
		 * !serverinfo - Shows some basic info about the server
		 *
		 * Useage !serverinfo [trigger]
		 *****************************************************************/
		if(StrContains(IrcArguments[0], "!serverinfo", false) != -1)
		{	
			if(!CheckPerms(CurChan[2], sender[0][1], "serverinfo"))
					continue;
			if(IrcArgCount < 1 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'serverinfo' command will show some basic info on the server status.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No trigger specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !info [trigger]\x0F");
				
			}		
			//if its for me
			if(CheckTrigger(IrcArguments[1]))
			{				
				new String:mapname[128];
				new String:hostname[128];
				new String:strServInfo[256];
				new currentplayers = GetClientCount(true);
				
				// Get the current map name
				GetCurrentMap(mapname, 127);
				// Get the servername
				new Handle:gameName = FindConVar("hostname");

				GetConVarString(gameName, hostname, 127);
			
				
			//	new Float:engineTime = GetEngineTime();
				
				Format(strServInfo, 255, "Hostname:\x02 %s\x0F", hostname);
				SendMessage(sender[0][1], CurChan[2], strServInfo);
				Format(strServInfo, 255, "Map:\x02 %s\x0F", mapname);
				SendMessage(sender[0][1], CurChan[2], strServInfo);
				Format(strServInfo, 255, "Players:\x02 (%d/%d)\x0F", currentplayers, GetMaxClients());
				SendMessage(sender[0][1], CurChan[2], strServInfo);
				//Format(strServInfo, 255, "Timeleft:\x02 (%d)\x0F", engineTime);
				//PrivMsg(CurChan[2], strServInfo);
			}
		}
		
		/*****************************************************************
		 * !join - Forces a bot to join a channel
		 *
		 * Useage !join [trigger] #[channel]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !join
		if(StrContains(IrcArguments[0], "!join", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{			
				SendMessage(sender[0][1], CurChan[2], "The 'join' command will force the relay to join a new channel.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No channel specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !join [trigger] #[channel]\x0F");
			}	
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				// if i;m allowed ot run that here
				if(CheckPerms(CurChan[2], sender[0][1], "join"))
				{
					// join the channel
					Join(IrcArguments[2]);
					// format the string to show to the channel
					Format(command, 64, "Joined channel \x02%s\x0F.", IrcArguments[2]);
					// send to chanenl
					SendMessage(sender[0][1], CurChan[2], command);
				}
			}
		}
		
		/*****************************************************************
		 * !rcon - Executes an rcon command on the server
		 *
		 * Useage !rcon [trigger] [command]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !rcon
		if(StrContains(IrcArguments[0], "!rcon", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'rcon' command will send an rcon command to the specified server.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No command specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !rcon [trigger] [command]\x0F");
			}	
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{
				new String:rcon[4][512];
				// get the rcon command to run
				explode(rcon, 4, lines[i], 511, ':'); 
				// if i'm allowed to run that in this channel
				if(CheckPerms(CurChan[2], sender[0][1], "rcon"))
				{
					// get the user that ran the command
					GetIRCSender(lines[i], sender);
					// format the irc message
					Format(rcon[3], 64, "\x02%s\x0F has been executed. ", rcon[2][strlen(subarg[1])+7]);
					// send the message to the current irc channel
					SendMessage(sender[0][1], CurChan[2], rcon[3]);
					// exec the command on the server
					ServerCommand(rcon[2][strlen(subarg[1])+7]);
				}
			}
		}
		
		/*****************************************************************
		 * !kickplayer - Kicks the specified player from the server
		 *
		 * Useage !kickplayer [trigger] [playername]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !kickplayer
		if(StrContains(IrcArguments[0], "!kickplayer", false) != -1)
		{	
			if(GetNumArgs(lines[i]) < 2 && master == 1)
			{				
				SendMessage(sender[0][1], CurChan[2], "The 'kickplayer' command will kick a specific player from the server.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No name specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !kickplayer [trigger] [playername]\x0F");
			}	
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{

				// if i'm allowed to run that in this channel
				if(CheckPerms(CurChan[2], sender[0][1], "kickplayer"))
				{
					// get the user that ran the command
					GetIRCSender(lines[i], sender);
					new String:name[64];
					// get the partial plyer name to search for
					Format(name, strlen(IrcArguments[2]), "%s", IrcArguments[2]);
					
					// Search through all the players till i find a match
					new plrName = FindPlayerName(name);
					if(plrName == -1)
					{
						// send error to channel
						SendMessage(sender[0][1], CurChan[2], "Cannot find that player in the server.");
						
					}
					// player found multple times
					else if(plrName == -2)
					{
						// send the error to the chanel
						SendMessage(sender[0][1], CurChan[2], "There are multiple players with that name, please be more specific.");
					}
					// yay, we found them
					else 
					{
						new String:kicksteam[64];
						GetClientAuthString(plrName, kicksteam, 64);
						GetClientName(plrName, command, 64);
						// format the irc message
						Format(command, 64, "%s kicked: \x02%s\x0F (%s).", sender[0][1], command, kicksteam);
						// send the message to the current irc channel
						PrivMsg(CurChan[2], command);
						Format(command, 64, "kickid %s You were kicked by an admin", kicksteam);
						// exec the command on the server
						ServerCommand(command);
					}
				}
			}
		}
		
		/*****************************************************************
		 * !banplayer - Bans a player from the server
		 *
		 * Useage !banplayer [trigger] [time] [playername]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if user ran !banplayer
		if(StrContains(IrcArguments[0], "!banplayer", false) != -1)
		{	
			if(IrcArgCount < 3 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'banplayer' command will kickban the specified player for the specified time.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No name specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !banplayer [trigger] [time] [playername]\x0F");
				
			}
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{	

				// if i'm allowed to run that in this channel
				if(CheckPerms(CurChan[2], sender[0][1], "banplayer"))
				{
					// get the user that ran the command
					GetIRCSender(lines[i], sender);
					new String:name[64];
					// get the partial plyer name to search for
					Format(name, strlen(IrcArguments[2]), "%s", IrcArguments[3]);
					
					// Search through all the players till i find a match
					new plrName = FindPlayerName(name);
					if(plrName == -1)
					{
						// send error to channel
						SendMessage(sender[0][1], CurChan[2], "Cannot find that player in the server.");
					}
					// player found multple times
					else if(plrName == -2)
					{
						// send the error to the chanel
						SendMessage(sender[0][1], CurChan[2], "There are multiple players with that name, please be more specific.");
						
					}
					// yay, we found them
					else 
					{
						new String:kicksteam[64];
						GetClientAuthString(plrName, kicksteam, 64);
						GetClientName(plrName, command, 64);
						// format the irc message
						Format(command, 64, "%s banned: \x02%s\x0F (%s) for %s minutes.", sender[0][1], command, kicksteam, subarg[2]);			
						// send the message to the current irc channel
						PrivMsg(CurChan[2], command);
						
						Format(command, 64, "banid %s %s kick", IrcArguments[2], kicksteam);
						
						// exec the command on the server
						ServerCommand(command);
						ServerCommand("writeid");
					}
				}
			}
		}
		/*****************************************************************
		 * !nick - Forces bot to change its nickname
		 *
		 * Useage !nick [trigger] [new nick]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !nick
		if(StrContains(IrcArguments[0], "!nick", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{
				SendMessage(sender[0][1], CurChan[2], "The 'nick' command will force the relay to change its nickname.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No nickname specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !nick [trigger] [nickname]\x0F");
				
			}
			// if its a command for me
			if(CheckTrigger(IrcArguments[1]))
			{					
				// if i'm allowed to run that here
				if(CheckPerms(CurChan[2], sender[0][1], "nick"))
				{
					// change the nickname
					Nick(IrcArguments[2]);
					// sent the new nickname
					strcopy(nickname, 63, IrcArguments[2]);
				}
			}
			
		}
		
		/*****************************************************************
		 * !masterchannel - Sets the new master channel for the bot
		 *
		 * Useage !masterchannel [trigger] #[channel]
		 * Permissions - Must be run from #gc.staff
		 *****************************************************************/
		// if ran !masterchannel
		if(StrContains(IrcArguments[0], "!masterchannel", false) != -1)
		{	
			if(IrcArgCount < 2 && master == 1)
			{			
				SendMessage(sender[0][1], CurChan[2], "The 'masterchannel' command will set the specified channel as the master channel.");
				SendMessage(sender[0][1], CurChan[2], "Error:\x02 No channel specified\x0F");
				SendMessage(sender[0][1], CurChan[2], "Useage:\x02 !masterchannel [trigger] #[channel]\x0F");	
			}
			
			// if this command is for me
			if(CheckTrigger(IrcArguments[1]))
			{		
				// if i'm allowed to run here		
				if(CheckPerms(CurChan[2], sender[0][1], "masterchannel"))
				{	
					new String:fmt[64];
					// format the message to send
					Format(fmt, 63, "Master channel changed to \x02%s\x0F.", IrcArguments[2]);
					// copy the new channel to global
					strcopy(MasterChan, strlen(IrcArguments[2]), IrcArguments[2]);
					// send to the new master channel
					SendMessage(sender[0][1], CurChan[2], fmt);
					
					// join the new master channel if not already
					Join(MasterChan);
				}
				// not allowed to exec here
			}
		}
		/*****************************************************************
		 * All the custom external plugin commands
		 *****************************************************************/
		for(new a=0;a<100;++a)
		{
			if(StrContains(IrcArguments[0], CmdText[a], false) != -1 && strlen(CmdText[a]) > 2)
			{
				argc = IrcArgCount;
				for(new v=1;v<10;++v)
				{
					strcopy(argv[v-1], 512, IrcArguments[v]);
				}
			
				if(CheckTrigger(IrcArguments[1]))
				{	
					if(FetchUserLevel( CurChan[2], sender[0][1]) < permissions[a])
					{
						Call_StartForward(CmdForwards[a]);
						new result;
						Call_Finish(_:result);		
					}
					else
					{
						new String:temp1[128];
						if(permissions[a] == 1)
							Format(temp1, 128, "Operator (+o)");
						else if(permissions[a] == 2)
							Format(temp1, 128, "Half-Op (+h)");
						else if(permissions[a] == 3)
							Format(temp1, 128, "Voice (+v)");
							
						Format(command, 128, "\x02 %s\x02: You need at least %s status to run this command", sender[0][1], temp1);
						PrivMsg(CurChan[2], command);	
					}
				}
					
				
				
			/*	if(permissions[a] == CHAN_ALL)
				{
					Call_StartForward(CmdForwards[a]);
					new result;
					Call_Finish(_:result);
				}
				else if(permissions[a] == CHAN_NOT_MASTER)
				{
					if(master != 1)
					{
						Call_StartForward(CmdForwards[a]);
						new result;
						Call_Finish(_:result);
					}
				}
				else if(permissions[a] == CHAN_MASTER)
				{
					if(master == 1)
					{
						Call_StartForward(CmdForwards[a]);
						new result;
						Call_Finish(_:result);
					}
				}*/
			}
		}		
//<=================================================================>
	}
}

/*****************************************************************
 * PrintHelp
 *
 * @breif This will print the help message for the bot
 * @params timer The handle of the timer that called it
 * @return none
 *****************************************************************/
// set the flood counter 
new Sent = 0;
public Action:PrintHelp(Handle:timer)
{
	// if its the first pass
	if(Sent == 0)
	{
		// send this stuff
		
		SendMessage(tempUser, tempChannel, "----\x02 Relay Commands\x0F ----");
		SendMessage(tempUser, tempChannel, "Below is a list of commands you can use with this IRC Relay.");
		SendMessage(tempUser, tempChannel, "\x02\x21msg [relay trigger] [message]\x0F - Send a public message to everyone currently in the server. EG: \x21msg eu.css1 hello");
		SendMessage(tempUser, tempChannel, "\x02\x21pmsg [relay trigger] [player name or partial name] [message]\x0F - This will send a private message to the specified player in the server. EG: \x21pmsg eu.css1 steve hello");
		SendMessage(tempUser, tempChannel, "\x02\x21players [relay trigger]\x0F - This will list all of the players in the server. EG: \x21players eu.css1");
				
		// increment counter
		++Sent;
		// start timer again for anothr pass
		CreateTimer(1.0, PrintHelp);
	}
	// if second pass
	else if(Sent == 1)
	{
		// send a new set of stuff
		SendMessage(tempUser, tempChannel, "\x02!join [relay trigger] [channel]\x0F - This will join the bot into the specified channel");
		SendMessage(tempUser, tempChannel, "\x02\x21triggers\x0F - This will force each bot to display its trigger");
		SendMessage(tempUser, tempChannel, "\x02\x21relayhelp\x0F - Shows this message");
		SendMessage(tempUser, tempChannel, "\x02!scores [relay trigger]\x0F - This will show all players and their scores");
		SendMessage(tempUser, tempChannel, "\x02!playerinfo [relay trigger] [player name or partial name]\x0F - This will show detailed info about the player");
		
		// increment counter
		++Sent;
		// start timer for 3rd pass
		CreateTimer(1.0, PrintHelp);
	}
	// if third pass
	else if(Sent == 2)
	{
		// send more stuff

		SendMessage(tempUser, tempChannel, "----\x02 Examples\x0F ----");
		SendMessage(tempUser, tempChannel, "To send a public message to all servers:");
		SendMessage(tempUser, tempChannel, "--\x02 \x21msg #all hello\x0F");
		SendMessage(tempUser, tempChannel, "To view all players in all european servers:");
		SendMessage(tempUser, tempChannel, "--\x02 \x21players #eu\x0F");
		// reset the counter
		Sent = 0;
		// cant remember what this is :
		tempChannel[0] = 0;
	}
}

/*****************************************************************
 * FindPlayerName
 *
 * @breif Find the userid from name or partial name
 * @params String:name name of the player to search for
 * @return -1 on not found
 *		   -2 on multiple matches
 *		   id User id of the player
 *****************************************************************/
public FindPlayerName(String:name[])
{
	// Get the current player count in the server
	new maxPlayers = GetMaxClients();
	new count = 0;
	new ID = -1;
	// loop through all of the player indexs
	for(new i=1;i<=maxPlayers;++i)
	{ 
	    //make sure they are in the game
		if(IsClientConnected(i))
		{
			new String:PlayerName[32];
			// Get the player name
			GetClientName(i, PlayerName, 31);
			if(!strcmp(PlayerName, name, false))
			{
				++count; ID = i;
			}
			// Check for a match, non case sensative
			else if(StrContains(PlayerName, name, false) != -1)
			{
				// increment count, and save the id
				++count; ID = i;
			}	
		}
	}
	// no one found
	if(count == 0)
	{	
		return -1;
	}
	// found more than 1
	else if(count > 1)
	{
		return -2;
	}
	// we found our guy
	else
	{
		return ID;
	}
}

/*****************************************************************
 * PlayerDetail
 *
 * @breif Prints detailed info for a player
 * @params timer Handle of the timer that called it
 * @return none
 *****************************************************************/
new detailCount = 0;
// print details of a player
public Action:PlayerDetail(Handle:timer)
{
	new String:temp[512];
	new String:temp2[512];
	// if on first pass
	if(detailCount == 0)
	{
		// Get the client name
		GetClientName(queryName, temp, 32);
		// Send the player naem we are showing details for
		SendMessage(tempUser, tempChannel, "Detailed player info for: %s", temp);
		// Get ip of the player, and port
		GetClientIP(queryName, temp2, 31, false);
		Format(temp, 512, "IP: \x02%s\x0F", temp2);
		// Print the ip:port
		SendMessage(tempUser, tempChannel,  temp);
		
		// Get steamid
		GetClientAuthString(queryName, temp2, 64);
		Format(temp, 512, "SteamID: \x02%s\x0F", temp2);
		// send steamid
		SendMessage(tempUser, tempChannel, temp);
		
		// get team id
		new teamid = GetClientTeam(queryName);
		// if terrorist
		if(teamid == 2)
		{
			// send the team
			SendMessage(tempUser, tempChannel, "Team:\x02 Terrorists\x0F");
		}
		// if ct
		else if(teamid == 3)
		{
			// send team
			SendMessage(tempUser, tempChannel, "Team:\x02 Counter-Terrorists\x0F");
		}
		// if Spectator or 'connecting'
		else if(teamid == 0 || teamid == 1)
		{
			// send as spectator
			SendMessage(tempUser, tempChannel, "Team:\x02 Spectator\x0F");
		}
		// increment the pass counter
		++detailCount;
		// start the timer again
		CreateTimer(1.0, PlayerDetail);
	}
	// second pass
	else if(detailCount == 1)
	{
		new String:health[128];
		new String:armor[128];
		// render a new bar for health
		RenderBar(GetClientHealth(queryName), health);
		Format(temp, 512, "Player Health:%s", health);
		// send the bar
		SendMessage(tempUser, tempChannel, temp);
		
		// render a new bar for armor
		RenderBar(GetClientArmor(queryName), armor);
		Format(temp, 512, "Player Armor: %s", armor);
		// send the armor bar
		SendMessage(tempUser, tempChannel, temp);
		
		// increment the pass couter
		++detailCount;
		// start the timer again
		CreateTimer(1.0, PlayerDetail);
	}
	// third pass
	else if(detailCount == 2)
	{
		// get score
		new score = GetClientFrags(queryName);
		// send score
		//PrivMsg(tempChannel, "Score: \x02%d\x0F", score);
		SendMessage(tempUser, tempChannel, "Score: \x02%d\x0F", score);
		// get deaths
		new death = GetClientDeaths(queryName);
		// send deaths
		SendMessage(tempUser, tempChannel, "Deaths: \x02%d\x0F", death);
		
		// get the time that the player has been connected
		new Float:time = GetClientTime(queryName);
		new String:strTime[128];
		// remove the accuracy of the time (not needed :P)
		new secs = FloatRound(time);
		//new secs = time;
		// format the seconds into hours mins and seconds
		FormatTime(secs, strTime);
		// send time in server
		SendMessage(tempUser, tempChannel, "Time in server: \x02%s\x0F", strTime);
		
		// get the ping of player with outgoing flow (BUG: seems broken)
		//new Float:ping = GetClientAvgLatency(queryName, NetFlow_Outgoing);
		// send the ping
		//SendMessage(tempUser, tempChannel, "Average ping: \x02%f\x0F", ping);
		
		// increment pass counter
		++detailCount;
		// start the timer again
		CreateTimer(1.0, PlayerDetail);
	}
	//4th pass
	else if(detailCount == 3)
	{
		new String:model[64];
		// get the player modle
		GetClientModel(queryName, model, 64);
		// send modle
		SendMessage(tempUser, tempChannel, "Model: \x02%s\x0F", model);
		
		new String:weapon[64];
		// Get the player weapon (removed till fixed in SM BUG)
		GetClientWeapon(queryName, weapon, 64);
		// send the message
		SendMessage(tempUser, tempChannel, "Weapon:\x02 %s\x0F", weapon);
		// reset the pass counter
		detailCount = 0;
	}
		
}

/*****************************************************************
 * FormatTime
 *
 * @breif Will format seconds into a string of hours, mins, and secs
 * @params secs secons to format
 * @params String:output the place to save the formated time to
 * @return none
 *****************************************************************/
// Formats a time
// converts seconds into a string of Hours, mins, and seconds
public FormatTime(secs, String:output[])
{
	new hours, minutes, seconds;
	// do the maths
	hours = secs / 3600;
	secs -= hours * 3600;
	minutes = secs / 60;
	seconds = secs - minutes * 60;
	// save the output to the output location
	Format(output, 128, "%d Hours, %d Minutes, %d Seconds", hours, minutes, seconds);
}


/*****************************************************************
 * CheckTrigger
 *
 * @breif This function will check if a trigger matches this bot
 * @params String:trigger		The trigger requested
 * @return bool					True if its for me else False 
 *****************************************************************/
bool:CheckTrigger(String:trigger[])
{
	new String:buffer[128];
	if(StrContains(trigger, "#all", false) != -1)
	{
		return true;
	}
	else if(StrContains(trigger, NameTrig, false) != -1)
	{
		return true;
	}
	else
	{
		for(new i=0;i<10;++i)
		{
			if(strlen(GroupArray[i]) < 1)
			{
				continue;
			}
			Format(buffer, 127, "#%s", GroupArray[i]);
			if(StrContains(trigger, buffer, false) != -1)
			{
				return true;
			}
		}
		return false;
	}
}


/*****************************************************************
 * GetIrcArgs
 *
 * @breif Will split the command string, and put it into an array
 * @params String:input The input string to split
 * @params String:output the place to save the command arguments to
 * @return the argument count - the actual command
 *****************************************************************/
public GetIrcArgs(String:input[], String:output[][])
{
	new String:temp[13][512];
	new arrsize = explode(temp, 9, input, strlen(input), ' ');
	
	new ret = 0;
	for(new i=3;i<=arrsize;++i)
	{
		if((i-3) == 0)
		{
			strcopy(output[i-3], strlen(temp[i])+1, temp[i][1]);
		}
		else
		{
			strcopy(output[i-3], strlen(temp[i])+1, temp[i]);
		}
		++ret;
	}
	return ret;
}

/*****************************************************************
 * RenderBar
 *
 * @breif Render a 'progressbar' like string of ascii
 * @params health a percentage to set the bar to
 * @params String:output the place to store the string to
 * @return none
 *****************************************************************/
// Renders a 'progress bar' like thing
// Takes in int (% of 100) outputs a string containg the ascii bar
public RenderBar(health, String:output[])
{
	new bars = 0;
	new space = 0;
	// if health isnt 0
	if(health != 0)
	{
		// scale down the bar
		bars = (health / 10) *2;
	}
	// if health is 0
	else
	{
		// set bars to 0
		bars = 0;
	}
		
	// set the spaces in relation to bars	
	space = 20 - bars; 	
			
	new String:strBar[128];
	new String:strSpace[128];
	// if helth is 0
	if(health == 0)
	{	
		// fill the block with space
		strcopy(strBar, 127, "........................................");
		Format(output, 128, "[%s] \x02(%d%%)\x0F", strBar, health);
	}
	// if health > 0
	else
	{	
		// loop through adding the required amount of bars
		for(new i=0;i<bars;++i)
		{	
			// add the bars to the string
			Format(strBar, 128, "%s%s", strBar, "#");
		}
		// loop through addng the spaces to fill the block
		for(new s=0;s<space;++s)
		{
			// add the spaces to the string
			Format(strSpace, 128, "%s%s", strSpace, "..");
		}
		// output the progress bar, adding helath % on the end
		Format(output, 128, "[%s%s] \x02(%d%%)\x0F", strBar, strSpace, health);
	}
}

/*****************************************************************
 * PrintPlayers
 *
 * @breif lists the players in the server
 * @params timer the handle of the timer that called it
 * @return none
 *****************************************************************/
new playerDelay = 0;
// Prints the players in the server
public Action:PrintPlayers(Handle:timer)
{
	new String:ct[512];
	new String:t[512];
	new String:spec[512];
	
	new tcount = 0;
	new ctcount = 0;
	new speccount = 0;
	
	// get the player count in the server
	new maxPlayers = GetMaxClients();
	// place team name at start of string
	strcopy(t, 512, "\x02 Terrorists\x0F: ");
	// loop though all players in the server
	for(new i=1;i<=maxPlayers;++i)
	{
		// if they are playing
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				// get their team
				new team = GetClientTeam(i);
				// if terrorists
				if(team == 2)
				{
					new String:name[32];
					new String:player[128];
					// get player name
					GetClientName(i, name, 31);
					// if we need to show the score
					if(showScore == 1)
						// output the name with the score
						Format(player, 127, "%s \x02(\x0F%d:%d\x02)\x0F, ", name,  GetClientFrags(i), GetClientDeaths(i));
					else
						// output the name without the score
						Format(player, 127, "%s, ", name,  GetClientFrags(i), GetClientDeaths(i));
					// put the string together
					Format(t, 512, "%s%s", t, player);
					// increment the amount of terrorists
					++tcount;
				}
			}
		}
	}
	
	// comments for CT and Spec are same as T
	
	strcopy(ct, 512, "\x02 Counter-Terrorists\x0F: ");
	for(new i=1;i<=maxPlayers;++i)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				new team = GetClientTeam(i);
				if(team == 3)
				{
					new String:name[32];
					new String:player[128];
					GetClientName(i, name, 31);
					if(showScore == 1)
						Format(player, 127, "%s \x02(\x0F%d:%d\x02)\x0F, ", name,  GetClientFrags(i), GetClientDeaths(i));
					else
						Format(player, 127, "%s, ", name,  GetClientFrags(i), GetClientDeaths(i));
					Format(ct, 512, "%s%s", ct, player);
					++ctcount;
				}
			}
		}
	}
	
	strcopy(spec, 512, "\x02 Spectators\x0F: ");
	for(new i=1;i<=maxPlayers;++i)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				new team = GetClientTeam(i);
				if(team == 1 || team == 0)
				{
					new String:name[32];
					new String:player[128];
				
					GetClientName(i, name, 31);
					if(showScore == 1)
						Format(player, 127, "%s \x02(\x0F%d:%d\x02)\x0F, ", name,  GetClientFrags(i), GetClientDeaths(i));
					else
						Format(player, 127, "%s, ", name,  GetClientFrags(i), GetClientDeaths(i));
					Format(spec, 512, "%s%s", spec, player);
					++speccount;
				}
			}
		}
	}
	
	if((ctcount + tcount + speccount) == 0)
	{
		SendMessage(tempUser, tempChannel, "No players are currently in the server.");
		return;
	}
	// if pass 1
	if(playerDelay == 0)
	{
		// if there is players in the server
		if(tcount > 0)
		{
			// print the player list for terrorists
			SendMessage(tempUser, tempChannel, t);
		}
		// increment the passs counter
		++playerDelay;
		// start the timer again
		CreateTimer(1.0, PrintPlayers);
	}
	// pass 2
	else if(playerDelay == 1)
	{
		// if any players on ct
		if(ctcount > 0)
		{	
			// send the player list
			SendMessage(tempUser, tempChannel, ct);
		}
		// incrememnt counter
		++playerDelay;
		// start timer again
		CreateTimer(1.0, PrintPlayers);
	}
	// pass 3
	else if(playerDelay == 2)
	{
		// if any players on spectate
		if(speccount > 0)
		{
			// send the spectator list
			SendMessage(tempUser, tempChannel, spec);
		}
		// reset the player count
		playerDelay = 0;
	}	
}

/*****************************************************************
 * FetchUserLevel
 *
 * @breif Check the user level in a given channel
 * @params String:channel 	channel to check
 * @params String:user 		the user running the command
 * @return the users level
 *****************************************************************/
public FetchUserLevel(String:channel[], String:user[])
{
	new uPerm = 0;
	KvRewind(relayKV);
	if(KvJumpToKey(relayKV,user,false))
	{
		uPerm = KvGetNum(relayKV,channel, 0);
	}

	KvRewind(relayKV);
	return uPerm;	
}
/*****************************************************************
 * CheckPerms
 *
 * @breif Checks if it can run commands in this channel
 * @params String:channel 	channel to check
 * @params String:user 		the user running the command
 * @params String:cmd 		the command they are running
 * @return 1 if can exec, or 0 if not
 *****************************************************************/
// Checks the current channel to see if we can run certain commands here
public CheckPerms(String:channel[], String:user[], String:cmd[])	
{
	new uPerm = 0;
	new cLvl = 0;
	new String:cPerm[16];
	FileToKeyValues(permKV,permFile);
	KvRewind(permKV);
	KvRewind(relayKV);
	
	if(KvJumpToKey(relayKV,user,false))
	{
		uPerm = KvGetNum(relayKV,channel, 0);
	}
	if(KvJumpToKey(permKV,cmd,false))
	{
		KvGetString(permKV, "level", cPerm, 16, "@");
	}
	
	if(!strcmp(cPerm, "@"))
		cLvl = 1;
	else if(!strcmp(cPerm, "%"))
		cLvl = 2;
	else if(!strcmp(cPerm, "+"))
		cLvl = 3;
	else if(!strcmp(cPerm, "x"))
		cLvl = 4;	
	else 
		cLvl = -1;
		
	KvRewind(permKV);
	KvRewind(relayKV);
	if(uPerm == 1 || cLvl == 4)
	{
		return true;	
	}
	else if(uPerm == 2 && cLvl >= 2)
	{
		return true;
	}
	else if(uPerm == 3 && cLvl >= 3)
	{
		return true;
	}
	else if(uPerm == 4 && (cLvl >= 4 || cLvl == -1))
	{
		return true;
	}
	else
	{
		if(master == 1)
		{
			new String:temp[128];
			if(cLvl == 1)
				Format(temp, 128, "Operator (+o)");
			else if(cLvl == 2)
				Format(temp, 128, "Half-Op (+h)");
			else if(cLvl == 3)
				Format(temp, 128, "Voice (+v)");
				
			Format(command, 128, "\x02 %s\x02: You need at least %s status to run this command", user, temp);
			PrivMsg(channel, command);
		}
		return false;
	}
}

/*****************************************************************
 * GetIRCMessage
 *
 * @breif splits the actual text sent from the irc server
 * @params String:line the IRC line to split
 * @params String:output the place to store the output
 * @return 1
 *****************************************************************/
public GetIRCMessage(String:line[], String:output[][])	
{
	// do the split
	explode(output, 6, line, strlen(line), ':');
	return 1;
}

/*****************************************************************
 * GetIRCChannel
 *
 * @breif Get the current channel that the message was sent from
 * @params String:line the IRC line to split
 * @params String:output the place to store the output
 * @return 1
 *****************************************************************/
public GetIRCChannel(String:line[], String:output[][])	
{
	// do the split
	explode(output, 3, line, 127, ' ');
	return 1;
}

//  Not used yet
public RequestLevel(String:channel[], String:name[])	
{
	Format(command, 255, "NAMES %s\r\n", channel);
	SocketSend(socket, command);	
	return 1;
}

/*****************************************************************
 * GetIRCSender
 *
 * @breif Splits the line to expose the sender that send the message in irc
 * @params String:line the IRC line to split
 * @params String:output the place to store the output
 * @return 1
 *****************************************************************/
public GetIRCSender(String:line[], String:output[][])	
{
	explode(output, 1, line, 63, '!');
	return 1;
}

/*****************************************************************
 * GetBotTrigger
 *
 * @breif Gets the trigger the user called from the channel
 * @params String:line the IRC line to split
 * @params String:output the place to store the output
 * @params String:res place to store the single trigger
 * @return 1
 *****************************************************************/
public GetBotTrigger(String:line[], String:output[][], String:res[])	
{
	// do the split
	explode(output, 4, line, strlen(line), ' ');
	// Copy's the trigger to the result
	strcopy(res, strlen(output[1]), output[1]);
	return 1;
}

/*****************************************************************
 * GetNumeric
 *
 * @breif Gets the irc reply numeric
 * @params String:line the IRC line to split
 * @return the numeric found
 *****************************************************************/
public GetNumeric(String:line[])	
{
	new String:output[5][128];
	// do the split
	explode(output, 4, line, 128, ' ');
	return StringToInt(output[1]);
}

/*****************************************************************
 * GetArgCount
 *
 * @breif returns the amount of arguments in the input string
 * @params String:line the IRC line to check
 * @return the amount of arguments found
 *****************************************************************/
public GetArgCount(String:input[][], arguments)	
{
	new finalcount = 0;
	for(new i=1;i<arguments+1;++i)
	{
		if(strlen(input[i]) > 0)
		{
			++finalcount;
		}
	}
	return finalcount;
}

/*****************************************************************
 * GetNumArgs
 *
 * @breif returns the amount of arguments in the input string
 * @params String:line the IRC line to check
 * @return the amount of arguments found
 *****************************************************************/
public GetNumArgs(String:line[])	
{
	new String:output[8][256];
	new temp = explode(output, 7, line, 255, ' ');
	return (temp-4);
}

/*****************************************************************
 * PrivMsg
 *
 * @breif Send a privmsg command to the irc server, and channel
 * @params String:channel the channel to msg to
 * @params String:text the text to send
 * @params any:...
 * @return none
 *****************************************************************/
public PrivMsg(String:channel[], String:text[], any:...)
{
	decl String:buffer[512];
	// Get the extra formatting params
	VFormat(buffer, sizeof(buffer), text, 3);
	// Add the command syntax
	Format(command, 4093, "PRIVMSG %s :%s\r\n", channel, buffer);
	// Send the command through the socket
	SocketSend(socket, command);
}

/*****************************************************************
 * SetMode
 *
 * @breif Sends a MODE command to the server
 * @params String:mode the mode to set the bot to
 * @return none
 *****************************************************************/
public SetMode(String:mode[])
{
	// add the MODE syntax
	Format(command, 255, "MODE %s +%s\r\n", nickname, mode);
	// Send the command through the socket
	SocketSend(socket, command);
}


/*****************************************************************
 * SendMessage
 *
 * @breif Sends a notice to the user
 * @params String:user the user to send the Notice
 * @params String:text the text to send
 * @params any:...
 * @return none
 *****************************************************************/
public SendMessage(String:user[], String:channel[], String:text[], any:...)
{
	decl String:buffer[512];
	// Get the extra formatting params
	VFormat(buffer, sizeof(buffer), text, 4);
	// Add the command syntax
	if(iNotice == 1)
	{
		Format(command, 4093, "NOTICE %s :%s\r\n", user, buffer);
	}
	else
	{
		Format(command, 4093, "PRIVMSG %s :%s\r\n", channel, buffer);
	}
	// Send the command through the socket
	SocketSend(socket, command);
}


/*****************************************************************
 * Notice
 *
 * @breif Sends a notice to the user
 * @params String:user the user to send the Notice
 * @params String:text the text to send
 * @params any:...
 * @return none
 *****************************************************************/
public Notice(String:user[], String:text[], any:...)
{
	decl String:buffer[512];
	// Get the extra formatting params
	VFormat(buffer, sizeof(buffer), text, 3);
	// Add the command syntax
	Format(command, 4093, "NOTICE %s :%s\r\n", user, buffer);
	// Send the command through the socket
	SocketSend(socket, command);
}

/*****************************************************************
 * Join
 *
 * @breif Sends a JOIN command to the server
 * @params String:channel the channel to join
 * @return none
 *****************************************************************/
public Join(String:channel[])
{
	// Add the command syntax
	Format(command, 127, "JOIN %s\n\r", channel);
	// send the command to the socket
	SocketSend(socket, command);
}

/*****************************************************************
 * Part
 *
 * @breif Sends a PART command to the server
 * @params String:channel the channel to part
 * @return none
 *****************************************************************/
public Part(String:channel[])
{
	// add the syntax
	Format(command, 127, "PART %s\n\r", channel);
	// send the command to the socket
	SocketSend(socket, command);
}

/*****************************************************************
 * Nick
 *
 * @breif Sends a NICK command to the server
 * @params String:channel new nickname
 * @return none
 *****************************************************************/
public Nick(String:channel[])
{
	// add the syntax
	Format(command, 127, "NICK %s\n\r", channel);
	// send to the socket
	SocketSend(socket, command);
}

/*****************************************************************
 * StrToBool
 *
 * @breif Converts a string (1|0|on|off) to bool
 * @params String:input string bool
 * @return true|false
 *****************************************************************/
public StrToBool(String:input[])
{
	if(StrContains(input, "1") != -1 || StrContains(input, "on") != -1)
	{
		return 1;
	}
	else if(StrContains(input, "0") != -1 || StrContains(input, "off") != -1)
	{
		return 0;
	}
	else
	{
		return -1;
	}
}

/*****************************************************************
 * Nick
 *
 * @breif Hook for when server calls banid command
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_Banid(args)
{
	new String:banstring[128];
	new String:banArgs[3][64];
	new String:temp[128];
	// Get the string that comes with the command
	GetCmdArgString(banstring, 127);
	// Split the command into its arguments
	explode(banArgs, 3, banstring, 64, ' '); 
	// get the max players in the server
	new maxPlayers = GetClientCount();
	new String:ban_name[32];
	// loop through all of the players
	for(new i=1;i<=maxPlayers;++i)
	{
		// if they are connected
		if(IsClientConnected(i))
		{
			new String:sid[32];
			// get their Steam id
			GetClientAuthString(i, sid, 31);
			// if their steam id, matches the banned one
			if(StrContains(banArgs[1], sid, false) > -1)
			{
				// get their name
				GetClientName(i, ban_name, 31);
			}	
		}
	}
	if(strlen(banArgs[1]) < 6)
	{
		GetClientName(StringToInt(banArgs[1]), ban_name, 31);
	}
	// if we found a player name
	if(strlen(ban_name) > 2)
	{
		// Send the ban message to the channel along with the name of the player that was banned
		Format(temp, 127, "\x02%s\x0F \x02(%s)\x0F was banned for \x02%s\x0F minutes.\n\n",ban_name, banArgs[1], banArgs[0]);
	}
	// if we couldnt get a name
	else
	{
		// Send the ban message with just the steam id and time banned
		Format(temp, 127, "\x02 %s\x0F was banned for \x02%s\x0F minutes.\n\n", banArgs[1], banArgs[0]);
	}
	// send the final string
	PrintToServer("ShowBans: %d", GetConVarInt(ircShowBans));
	if(GetConVarInt(ircShowBans) == 1)
	{
		PrivMsg(MasterChan, temp);
		// also send to other channels
		for(new c=0;c<8;c++)
		{
			// if it isnt blank
			if(strlen(chanarray[c]) > 0)
			{
				// join the channel
				PrivMsg(chanarray[c], temp);
			}
				
		}
	}
}

/*****************************************************************
 * Command_join
 *
 * @breif function for irc_join server command
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_join(args)
{
	new String:text[192];
	// Get the channel to join
	GetCmdArgString(text, sizeof(text));
	// join it
	Join(text);
}

/*****************************************************************
 * Command_leave
 *
 * @breif function for irc_leave server command
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_leave(args)
{
	new String:text[192];
	// get the channel to leave
	GetCmdArgString(text, sizeof(text));
	// leave it
	Part(text);
}

/*****************************************************************
 * Command_relay
 *
 * @breif function for irc_relay server command
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_relay(args)
{
	new String:text[192];
	// get the string to say
	GetCmdArgString(text, sizeof(text));
	// send the string to say though the bot
	PrivMsg(MasterChan, text);
}

/*****************************************************************
 * Command_broadcast
 *
 * @breif function for irc_relay server command
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_broadcast(args)
{
	// Get the string that comes with the command
	new String:broadString[256];
	new String:bcstMaster[16];
	
	GetCmdArg(1, bcstMaster, 16);
	
	GetCmdArgString(broadString, 255);


	for(new c=0;c<8;c++)
	{
		// if its not blank
		if(strlen(chanarray[c]) > 0)
		{
			// join the channel
			PrivMsg(chanarray[c], broadString[2]);
		}
	}
	if(!strcmp(bcstMaster, "1"))
	{
		PrivMsg(MasterChan, broadString[2]);
	}
}

public Action:Command_exit(args)
{
	PrivMsg(MasterChan, "Quitting, Server restarting...");
}
/*****************************************************************
 * Command_Say
 *
 * @breif hook for player say from game
 * @params client the id of the client that said somethng
 * @params args the arguments of the command
 * @return none
 *****************************************************************/
public Action:Command_Say(client, args)
{
	new String:text[192];
	// get what they said
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	// remove " from theri chat
	if (text[0] == '"')
	{
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	// if they said /irc
	if(!StrContains(text[startidx], "/irc", false))
	{
		// get theri name, and add team prefix
		FormatName(client, text[6], command, 1);
		// Send a confirmation to the player ingame that theri message was sent
		SendMsg_SayText2(client, "\x03[IRC]\x01 Your message was sent!");
		// Send the players message to the master irc chanenl
		PrivMsg(MasterChan, command);
		// hide the chat from server 
		return Plugin_Handled;
	}
	else if(showAllChat == 1)
	{
		// get theri name, and add team prefix
		FormatName(client, text, command, 1);
		// Send the players message to the master irc chanenl
		PrivMsg(MasterChan, command);
		return Plugin_Continue;
	}
	// show their message to the server
	return Plugin_Continue;
}		

/*****************************************************************
 * FormatName
 *
 * @breif get the name of the player and maybe add the team prefix at the start
 * @params client the id of the client
 * @params output the output
 * @params prefix add scores or not
 * @return none
 *****************************************************************/
public FormatName(client, String:text[], String:output[], prefix)
{
	new String:name[64];
	// get the player name
	GetClientName(client, name, 64);
	// get the team name
	new team = GetClientTeam(client);
	new String:clrTeam[256];
	new String:bold[8];
	new String:normal[8];
	new String:CTclr[16];
	new String:Tclr[16];
	new String:SPECclr[16];
	// setup the irc chars for formatting	
	Format(bold, 8, "%c", '\x02');
	Format(normal, 8, "%c", '\x0F');
	Format(CTclr, 16, "%c15,1", '\x03');
	Format(Tclr, 16, "%c4,1", '\x03');
	Format(SPECclr, 16, "%c0,1", '\x03');
	
	iColor = GetConVarInt(ircColor);
	// if terrorist
	if(team == 2)
	{
		// if add prefix
		if(prefix == 1)
		{
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c(T) %s%c%c:%c", Tclr, bold, name,  normal, bold, normal);
			else
				Format(clrTeam, 256, "%c(T) %s%c%c:%c", bold, name,  normal, bold, normal);
		}
		else
		{	
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c%s%c", Tclr, bold, name,  normal);
			else
				Format(clrTeam, 256, "%c%s%c", bold, name,  normal);
		}
	}
	// if ct
	else if(team == 3)
	{
		// if add prefix
		if(prefix == 1)
		{
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c(CT) %s%c%c:%c", CTclr, bold, name,  normal, bold, normal);
			else
				Format(clrTeam, 256, "%c(CT) %s%c%c:%c", bold, name,  normal, bold, normal);
		}
		else
		{	
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c%s%c", CTclr, bold, name,  normal);
			else
				Format(clrTeam, 256, "%c%s%c", bold, name,  normal);
		}
	}
	// if spec
	else if(team == 1 || team == 0)
	{
		// if add prefix
		if(prefix == 1)
		{
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c(SPEC) %s%c%c:%c", SPECclr, bold, name,  normal, bold, normal);
			else
				Format(clrTeam, 256, "%c(SPEC) %s%c%c:%c", bold, name,  normal, bold, normal);
		}
		else
		{	
			if(iColor == 1)
				Format(clrTeam, 256, "%s%c%s%c", SPECclr, bold, name,  normal);
			else
				Format(clrTeam, 256, "%c%s%c", bold, name,  normal);
		}
	}
	// output the name
	Format(output, 255, "%s %s", clrTeam, text);
}

/*****************************************************************
 * SendMsg_SayText2
 *
 * @breif This function will send a SayText usermessage to a client ingame
 * @params target the id of the client
 * @params szMsg test to send
 * @params any:...
 * @return none
 *****************************************************************/
stock SendMsg_SayText2(target, const String:szMsg[], any:...)
{
	// if chat message is too long and will crash server
   if (strlen(szMsg) > 191){
      LogError("Disallow string len(%d) > 191", strlen(szMsg));
      return;
   }

   decl String:buffer[192];
   // apply the string formatters
   VFormat(buffer, sizeof(buffer), szMsg, 3);

   new Handle:hBf;
   // if 0 send to all players, else send to specified id
   if (target == 0)
      hBf = StartMessageAll("SayText");
   else hBf = StartMessageOne("SayText", target);
	
	// if we have a handle
   if (hBf != INVALID_HANDLE)
   {
      //BfWriteByte(hBf, color);
      // write the byte
      BfWriteByte(hBf, 0); 
      // write the message
      BfWriteString(hBf, buffer);
      // send the message
      EndMessage();
   }
}

/*****************************************************************
 * explode
 *
 * @breif this function will explode a string into an array. Splitting the string by delimiter
 * @params output the 2dimensional array to save to
 * @params p_iMax max entries
 * @params p_szInput input string
 * @params p_iSize leingth of strings
 * @params p_szDelimiter the deliminator to split by
 * @return the size of the array created
 *****************************************************************/
stock explode( String:p_szOutput[][], p_iMax, String:p_szInput[], p_iSize, p_szDelimiter )
{
    new iIdx = 0;
    // get the leingth of string
    new l = strlen(p_szInput);
    // copy the string to ouput upto the delimiter
    new iLen = copyc( p_szOutput[iIdx], p_iSize, p_szInput, p_szDelimiter) + 1;
    // loop through the second dimension
    while( (iLen < l) && (++iIdx < p_iMax+1) )
    {	
		//copy any folowing text to the array, incremenitn the count each time
		iLen += (1 + copyc( p_szOutput[iIdx], p_iSize, p_szInput[iLen], p_szDelimiter));
    }
    return iIdx+1;
}

/*****************************************************************
 * copyc
 *
 * @breif this function will copy a string upto a defined character
 * @params dest the place to save to
 * @params len leingth of the string
 * @params src input string
 * @params ch character to stop copying at
 * @return the leingh of new string
 *****************************************************************/
stock copyc(String:dest[], len, String:src[], ch)
{
	for(new i=0;i<len-1;++i)
	{
		if(src[i] != ch && src[i] != '\0')
		{	
			dest[i] = src[i]; 
		}
		else
		{
			return i;
		}
	}
	return -1;
}

//Yarr!