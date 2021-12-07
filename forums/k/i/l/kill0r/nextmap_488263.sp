/**
 * nextmap.sp
 *
 * Version: see Plugin:myinfo
 */

/*
Todo:
 - any ideas?
*/

#pragma semicolon 1

#include <sourcemod>



#define MRY_NONE		0		// Print nothing
#define MRY_LOG			1		// Log the message
#define MRY_SERVER		(1<<1)	// A copy of the message to the serverconsole/hlsw/rcon/etc., anyway if client=0
#define MRY_CONSOLE		(1<<2)	// Print to client's console
#define MRY_CHAT		(1<<3)	// Print to client's chat (ignored if client=0)
#define MRY_CSAY		(1<<4)	// Print to client via CenterText (ignored if client=0)
#define MRY_BROADCAST	(1<<15)	// Print to all clients, otherwise only to client
#define MRY_TEAM		(1<<16)	// Print to clients's Team only (ignored if broadcast flag is not set), (ignored if client=0)
#define MRY_DEADALIVE	(1<<17)	// If Client is alive => print to all, if Client is dead print only to dead Players(Can be combine with MRY_TEAM) (ignored if broadcast flag is not set)
/**
 * This is MultiReply, it'll reply to specific client or groups, and will print the messages to several outputs.
 *
 * @version 0.2.0.1
 * @param flags - see above
 * @param client - client
 * @param format - formatstr or text
 * @param any... - formatstr params
 * @noreturn
 */
stock MultiReply(flags, client, const String:format[], any:...) {
	if (!flags)
		return;

	new maxClients = GetMaxClients();
	decl String:message[192];
	VFormat(message, sizeof(message), format, 4);
	
	// Log the message.
	if (MRY_LOG&flags)
		LogMessage(message);
	
	// One copy to serverconsole/rcon/hlsw etc..
	if (MRY_SERVER&flags)
		PrintToConsole(0,message);
	
	// If client=serverconsole, and he didn't got a copy jet -> print to console
	if (!client && !(MRY_SERVER&flags)) {
		PrintToConsole(0,message);
	}
	
	// If Client/Singlemessage only
	if (!(MRY_BROADCAST&flags) && client) {
		if (MRY_CONSOLE&flags)
			PrintToConsole(client,message);
		if (MRY_CHAT&flags)
			PrintToChat(client,message);
		if (MRY_CSAY&flags)
			PrintCenterText(client,message);
		return;
	}
	
	// Broadcast section:
	if (MRY_BROADCAST&flags) {
		// Reply only to dead players if deadalive-flag is set and client is dead.
		// GetEntData(i,FindDataMapOffs(client,"m_lifeState"),1) 0 => alive, 1 => dead
		new bool:toDeadPlayersOnly = (client && MRY_DEADALIVE&flags && GetEntData(client,FindDataMapOffs(client,"m_lifeState"),1));
		new bool:toTeamOnly = (client && MRY_TEAM&flags);
		new team = toTeamOnly?GetClientTeam(client):0;
		
		// TEAM && DEADALIVE		Reply to dead players in client's team
		// DEADALIVE				Reply to dead players in client's team
		// TEAM					Reply to client's team
		// ELSE					Reply to all
		for (new i = 1; i <= maxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i) || (toTeamOnly&&GetClientTeam(i)!=team) || (toDeadPlayersOnly&&(GetEntData(i,FindDataMapOffs(client,"m_lifeState"),1)==0)))
				continue;
			if (MRY_CONSOLE&flags)
				PrintToConsole(client,message);
			if (MRY_CHAT&flags)
				PrintToChat(client,message);
			if (MRY_CSAY&flags)
				PrintCenterText(client,message);
		}
	}
}


/**
 * Removes quotes if the string is in quotes.
 *
 * @param text	The string to Trim.
 * @return		Startindex (0 if it was'n quotet else 1).
 */
stock TrimQuotes(String:text[]) {
	new startidx = 0;
	if (text[0] == '"') {
		new len = strlen(text);
		if (text[len-1] == '"') {
			startidx = 1;
			text[len-1] = '\0';
		}
	}
	return startidx;
}



public Plugin:myinfo = 
{
	name = "Nextmap",
	author = "kill0r",
	description = "This will show the next map in mapcycle and current map.",
	version = "0.3.1.5",
	url = ""
};

// Max Mapname Length
#define MMNLENGTH 255
new Handle:g_mapcyclefile;
new Handle:g_info_nextmap;
new String:g_currentmap[MMNLENGTH];


public OnPluginStart() {
	g_mapcyclefile = FindConVar("mapcyclefile");
	if (g_mapcyclefile==INVALID_HANDLE) {
		ThrowError("* FATAL ERROR: Failed to find ConVar 'mapcyclefile'");
	}

	g_info_nextmap = CreateConVar("info_nextmap", "0", "Show the next map in mapcycle.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY, false, 0.0, false, 0.0);
	// If the convar already exists
	if (g_info_nextmap==INVALID_HANDLE) {
		g_info_nextmap = FindConVar("info_nextmap");
	}

	LoadTranslations("plugin.nextmap.cfg");
		
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("currentmap", Command_Currentmap);
		
	//OnMapStart();
}

public OnPluginEnd() {
	// "" means nextmap is unknown or function is disabled
	SetConVarString(g_info_nextmap, "");
}

public OnMapStart() {
	GetCurrentMap(g_currentmap,MMNLENGTH);
	RefreshInfoNextmap();
}


/**
 * console nextmap:
 *    Silent/Reply only to the client.
 */
public Action:Command_Nextmap(client, args) {
	new String:nextmap[MMNLENGTH];
	GetConVarString(g_info_nextmap,nextmap,MMNLENGTH);

	if (strlen(nextmap)) {
		MultiReply(MRY_CONSOLE|MRY_CHAT,client,"%t","next map is",nextmap);
	} else {
		MultiReply(MRY_CONSOLE|MRY_CHAT,client,"%t","next map unknown");
	}

	return Plugin_Handled;
}
/**
 * console currentmap:
 *  Silent/Reply only to the client.
 */
public Action:Command_Currentmap(client, args) {
	MultiReply(MRY_CONSOLE|MRY_CHAT,client,"%t","current map is",g_currentmap);
	return Plugin_Handled;
}


public Action:Command_Say(client, args) {
	new String:text[30];
	GetCmdArgString(text, sizeof(text));
	new startidx = TrimQuotes(text);

	// broadcast reply to nextmap
	if (StrEqual(text[startidx], "nextmap")) {
		new Handle:pack = CreateDataPack();
		CreateDataTimer(0.1, DelayedNextmapReply,pack);
		WritePackCell(pack, client);
		// server can read say, so reply to server too.
		WritePackCell(pack, MRY_SERVER|MRY_CONSOLE|MRY_CHAT|MRY_BROADCAST|MRY_DEADALIVE);
		return Plugin_Continue;
	}
	
	// single reply to /nextmap
	if (StrEqual(text[startidx], "/nextmap")) {
		return Command_Nextmap(client,args);
	}
	
	// single reply to currentmap and /currentmap
	if (StrEqual(text[startidx], "currentmap") || StrEqual(text[startidx], "/currentmap")) {
		return Command_Currentmap(client,args);
	}
	
	return Plugin_Continue;
}


public Action:Command_SayTeam(client, args) {
	new String:text[30];
	GetCmdArgString(text, sizeof(text));
	new startidx = TrimQuotes(text);

	// broadcast reply to nextmap
	if (StrEqual(text[startidx], "nextmap")) {
		new Handle:pack = CreateDataPack();
		CreateDataTimer(0.1, DelayedNextmapReply,pack);
		WritePackCell(pack, client);
		// server can read say, so reply to server too.
		WritePackCell(pack, MRY_SERVER|MRY_CONSOLE|MRY_CHAT|MRY_BROADCAST|MRY_TEAM|MRY_DEADALIVE);
		return Plugin_Continue;
	}
	
	// single reply to /nextmap
	if (StrEqual(text[startidx], "/nextmap")) {
		return Command_Nextmap(client,args);
	}
	
	// single reply to currentmap and /currentmap
	if (StrEqual(text[startidx], "currentmap") || StrEqual(text[startidx], "/currentmap")) {
		return Command_Currentmap(client,args);
	}
	
	return Plugin_Continue;
}

public Action:DelayedNextmapReply(Handle:timer, Handle:pack) {
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new flags = ReadPackCell(pack);
	
	new String:nextmap[MMNLENGTH];
	GetConVarString(g_info_nextmap,nextmap,MMNLENGTH);
	if (strlen(nextmap)) {
		MultiReply(flags,client,"%t","next map is",nextmap);
	} else {
		MultiReply(flags,client,"%t","next map unknown");
	}
	
	return Plugin_Stop;
}

/*
@see
http://wiki.alliedmods.net/Menu_API_%28SourceMod%29
*/
stock RefreshInfoNextmap() {
	SetConVarString(g_info_nextmap,"");
	
	/* Open the file */
	new String:mapcyclefile[MMNLENGTH];
	GetConVarString(g_mapcyclefile,mapcyclefile,MMNLENGTH);
	new Handle:file = OpenFile(mapcyclefile, "rt");
	//new Handle:file = OpenFile("mapcycle.txt", "rt");
	if (file == INVALID_HANDLE) {
		return;
	}

	/* Create the menu Handle */
	new String:firstmapname[MMNLENGTH];
	firstmapname[0] = 0;
	new String:mapname[MMNLENGTH];
	new bool:foundCurrentMap = false;
	new bool:nextmapHasBeenSet = false;
	while (!IsEndOfFile(file) && ReadFileLine(file, mapname, sizeof(mapname))) {
		if (mapname[0] == ';' || !IsCharAlpha(mapname[0])) {
			continue;
		}
		/* Cut off the name at any whitespace */
		new len = strlen(mapname);
		for (new i=0; i<len; i++) {
			if (IsCharSpace(mapname[i])) {
				mapname[i] = '\0';
				break;
			}
		}
		/* Check if the map is valid */
		if (!IsMapValid(mapname)) {
			continue;
		}

		// If currentmap was found last loop.
		if (foundCurrentMap) {
			SetConVarString(g_info_nextmap,mapname);
			nextmapHasBeenSet = true;
			break;
		} 
		
		// if currentmap equals map of this line
		if (StrEqual(g_currentmap,mapname)) {
			foundCurrentMap = true;
			continue;
		}
		
		// if firstmapname has not been saved jet
		if (firstmapname[0]==0) {
			strcopy(firstmapname,MMNLENGTH,mapname);
			foundCurrentMap = false;
			continue;
		} 
	}
	
	if (!nextmapHasBeenSet) {
		// the currentmap was the last in mapcycle-file.
		if (firstmapname[0]!=0) {
			SetConVarString(g_info_nextmap,firstmapname);
		}
		// Only one map in mapcycle.
		else if (foundCurrentMap) {
			SetConVarString(g_info_nextmap,g_currentmap);
		}
	}
	/* Make sure we close the file! */
	CloseHandle(file);
}

