#pragma semicolon 1

#include <sourcemod>
#include <basecomm>
#include <morecolors>

// Hello from Russia with love. Peace and mind.
// There is no place for war in our world!

// Hello from Russia with love. Peace and mind.
// There is no place for war in our world!

// Enable or disable DEBUG
#define PLUGIN_DEBUG
#define VOTEKICK_TYPE 		0
#define VOTEBAN_TYPE 		1
#define VOTESILENCE_TYPE 	2
#define VOTEMUTE_TYPE 		3
#define VOTE_ALL_TYPE 		4
#define MAX_PLAYERS_PER_MAP 100
#define logprefix "[GvLog]"
#define clogprefix "[GameVoting]"
#define GAMEVOTING_VERSION "1.5c"

/* Functions:
	gvRegisterID(client) - register GvID for someone (in-game identification).
	gvGetID(client) - get GvID.
	gvVotefor(type, voter, indicteec) - finished vote for someone with ban and other features.
	gvAddVote(type, voterID, indicteeID) - just add vote count for someone. (dont support VOTE_ALL_TYPE)
	gvResetVote(type, voterID) - reset votes for someone.
	gvNeedfor(type) - get count of players for finish vote. (dont support VOTE_ALL_TYPE)
	prepareVote(client, String:clientID[], type) - do actions on menu Callback, go to gvVotefor.
	VoteInit(client, type) - build menu with need type.
	gvClearData() - clear GvID store.
	gvKickPlayer(clientGvID, clientUserID) - kick player.
	gvBanPlayer(clientGvID, clientUserID) - ban player.
	gvMutePlayer(clientGvID, clientUserID) - mute player.
	bool:AdminsOnServer() - admins on server?!
	CheckConvars() - set right settings for variables from cvars.
	checkSourcebans() - we using sourcebans?!
*/

// Plugin info
public Plugin:myinfo = 
{
	name = "Gamevoting",
	author = "Neatek.ru ",
	description = "Simple voting plugin, hello from Russia with love. Peace and mind.",
	version = "1.5c",
	url = "http://www.neatek.ru/"
};

// GvID settings
// !i will not use timers, cuz they terrible!
// !only timestamp and some events!
enum gvstore
{
	votekick,
	voteban,
	votesilence,
	votemute,
	indictee,
	blacklist_timestamp,
	mute_timestamp,
	silence_timestamp,
	lasttype,
	antiflood
}

//cvars (i hate it)
new Handle:g_PluginVersion 		= INVALID_HANDLE;
new Handle:g_EnableLogs			= INVALID_HANDLE;
new Handle:g_EnableActions 		= INVALID_HANDLE;
new Handle:g_ImmunityFlag 		= INVALID_HANDLE;
new Handle:g_DeactivateAdmin	= INVALID_HANDLE;
new Handle:g_enableplugin		= INVALID_HANDLE;
new Handle:g_needplayers		= INVALID_HANDLE;

new Handle:g_banpercent			= INVALID_HANDLE;
new Handle:g_kickpercent		= INVALID_HANDLE;
new Handle:g_mutepercent		= INVALID_HANDLE;
new Handle:g_silencepercent		= INVALID_HANDLE;

new Handle:g_bantime			= INVALID_HANDLE;
new Handle:g_kicktime			= INVALID_HANDLE;
new Handle:g_silencetime		= INVALID_HANDLE;
new Handle:g_mutetime			= INVALID_HANDLE;

new Handle:g_banenable			= INVALID_HANDLE;
new Handle:g_kickenable			= INVALID_HANDLE;
new Handle:g_silenceenable		= INVALID_HANDLE;
new Handle:g_muteenable			= INVALID_HANDLE;

new Handle:g_morecolors			= INVALID_HANDLE;

new Handle:g_antiflood			= INVALID_HANDLE;

// logs
new String:gvlog[PLATFORM_MAX_PATH]; 			// path to GameVoting logs
new String:gvactions[PLATFORM_MAX_PATH]; 		// path to GameVoting successfully votes

//variables
new needplayers;
new Handle:gvID = INVALID_HANDLE; 				// GvID array
new gvVotes[MAX_PLAYERS_PER_MAP][gvstore];		// data for each player
new gvUseridGvID[MAXPLAYERS+1]; 				// optimize find of GvID, dont need to parse array with steamids
new bool:gsourcebans, bool:glogs, bool:gaclogs, bool:adplugin, bool:adminonserver, bool:enableplugin, bool:morecolors, bool:noimmunity;
new AdminFlag:ImmunityFlag;

public OnPluginStart()
{
	// version
	g_PluginVersion 	= 	CreateConVar("sm_gamevoting_version", GAMEVOTING_VERSION, "Version of GameVoting plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_enableplugin 		= 	CreateConVar("gv_enable_plugin", "1", "Enable or disable plugin. Of course not recommended :P");
	g_EnableLogs 		= 	CreateConVar("gv_enable_logs", "0", "Enable or disable logs (def: 0)(Not recommended)");
	g_EnableActions 	= 	CreateConVar("gv_enable_logs_actions", "1", "Enable or disable actions logs (def: 1)(Recommended)");
	g_DeactivateAdmin 	= 	CreateConVar("gv_deactivate_admin", "0", "Disable plugin when admin on server (def: 0)(Not recommended)");
	g_ImmunityFlag 		= 	CreateConVar("gv_immunity_flag", "b", "Prevent votes for client with this flag. (its doesnt works without b flag, you need to be Generic admin)"); // its doesnt works without "b" flag, you need to be "Generic admin"
	g_needplayers 		= 	CreateConVar("gv_need_players", "8", "Need players for enable plugin (def: 8)");
	// percent
	g_banpercent 		= 	CreateConVar("gv_ban_percent", "80", "How many percent of votes need to be got for ban player (def: 80%)");
	g_kickpercent 		= 	CreateConVar("gv_kick_percent", "80", "percent for kick player (def: 80%)");
	g_mutepercent 		= 	CreateConVar("gv_mute_percent", "70", "percent for mute player (def: 70%)");
	g_silencepercent	= 	CreateConVar("gv_silence_percent", "70", "percent for mute player (def: 70%)");
	// duration
	g_bantime 			= 	CreateConVar("gv_ban_duration", "60", "ban duration in minutes (Works with Sourcebans)");
	g_kicktime			=  	CreateConVar("gv_kick_duration", "120", "kick duration in seconds (reset on map start)");
	g_silencetime 		= 	CreateConVar("gv_silence_duration", "60", "silence duration in seconds (reset on map start)");
	g_mutetime 			= 	CreateConVar("gv_mute_duration", "60", "mute duration in seconds (reset on map start)");
	// enable disable
	g_banenable 		= 	CreateConVar("gv_ban_enable", "1", "Enable or disable ban function.");
	g_kickenable		=  	CreateConVar("gv_kick_enable", "1", "Enable or disable kick function.");
	g_silenceenable 	= 	CreateConVar("gv_silence_enable", "1", "Enable or disable silence function.");
	g_muteenable		= 	CreateConVar("gv_mute_enable", "1", "Enable or disable mute function.");
	// morecolors
	g_morecolors		=  	CreateConVar("gv_support_morecolors", "0", "Enable colors in chat.");
	
	g_antiflood			=  	CreateConVar("gv_delay_vote", "20", "Delay between each vote for 1 person (seconds).");
	
	// just add convar event
	HookConVarChange(g_PluginVersion, UpdateConVarVersion);
	HookConVarChange(g_EnableLogs, UpdateConVarVersion);
	HookConVarChange(g_EnableActions, UpdateConVarVersion);
	HookConVarChange(g_enableplugin, UpdateConVarVersion);
	HookConVarChange(g_DeactivateAdmin, UpdateConVarVersion);
	HookConVarChange(g_ImmunityFlag, UpdateConVarVersion);
	HookConVarChange(g_needplayers, UpdateConVarVersion);
	HookConVarChange(g_morecolors, UpdateConVarVersion);

	gvID = CreateArray(32);
	AddCommandListener(Listener, "say");
	AddCommandListener(Listener, "say_team");
	
	// logs
	new String:ftime[86];
	FormatTime(ftime, sizeof(ftime), "logs/gamevoting/logs%m-%d-%y.txt");
	BuildPath(Path_SM, gvlog, sizeof(gvlog), ftime);
	
	// actions logs
	FormatTime(ftime, sizeof(ftime), "logs/gamevoting/actions%m-%d-%y.txt");
	BuildPath(Path_SM, gvactions, sizeof(gvactions), ftime);
	
	// event for unmute and unsilence
	HookEvent("player_death", Event_PlayerDeath);
	
	// autoexec
	AutoExecConfig(true, "GameVoting");
	
	// translations
	LoadTranslations("phrases.GameVoting");
}

public OnConfigsExecuted()
{
	CheckConvars();

	// check sourcebans
	checkSourcebans();
}

public CheckConvars()
{
	// enable or disable logs
	if(GetConVarInt(g_EnableLogs) > 0) glogs = true; else glogs = false;
	// enable or disable actions logs
	if(GetConVarInt(g_EnableActions) > 0) gaclogs = true; else gaclogs = false;
	// deactivate plugin admin?
	if(GetConVarInt(g_DeactivateAdmin) > 0) adplugin = true; else adplugin = false;
	// enable plugin?
	if(GetConVarInt(g_enableplugin) > 0) enableplugin = true; else enableplugin = false;
	// morecolors?
	if(GetConVarInt(g_morecolors) > 0) morecolors = true; else morecolors = false;
	// get immunity flags
	
	new String:ichar[11];
	GetConVarString(g_ImmunityFlag, ichar, sizeof(ichar));
	if(StrEqual(ichar,"0") || StrEqual(ichar,"")) noimmunity = true;
	else 
	{ 
		BitToFlag(ReadFlagString(ichar), ImmunityFlag);
		noimmunity = false;
	}
	//
	SetConVarString(g_PluginVersion, GAMEVOTING_VERSION, true, true);
	needplayers = GetConVarInt(g_needplayers);
}

public checkSourcebans()
{
	new String:spath[PLATFORM_MAX_PATH];
	new String:pathf[86];
	FormatTime(pathf, sizeof(pathf), "plugins/sourcebans.smx");
	BuildPath(Path_SM, spath, sizeof(spath), pathf);
	if(FileExists(spath))
	{
		gsourcebans = true;
		if(glogs) LogToFileEx(gvlog, "%s::Sourcebans:: Sourcebans detected. Using version with it.",logprefix);
	}
	else
	{
		gsourcebans = false;
		if(glogs) LogToFileEx(gvlog, "%s::Sourcebans:: Can't find Sourcebans, using version without sourcebans.",logprefix);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!enableplugin) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new gvidd = gvGetID(client);
	if(gvidd > -1)
	{
		// Check mute
		if(gvVotes[gvidd][mute_timestamp] != 0 && gvVotes[gvidd][mute_timestamp] < GetTime()) 
		gvUnmutePlayer(client);
		
		// Check silence
		if(gvVotes[gvidd][silence_timestamp] != 0 && gvVotes[gvidd][silence_timestamp] < GetTime()) 
		gvUnsilencePlayer(client);
	}

	return Plugin_Continue;
}

public UpdateConVarVersion(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CheckConvars();
}

public OnMapStart()
{
	adminonserver = false;
	gvClearData();
}

public OnClientPostAdminCheck(client)
{
	gvUseridGvID[client] = -1; // reset GvID optimization
	gvRegisterID(client); // set GvID again

	AdminsEventCheck(); // disable plugin if admin on server
}

public OnClientDisconnect(client)
{
	if(!ValidClient(client)) return; // block bots and fakes;
	new voterID = gvGetID(client);
	gvUseridGvID[client] = -1;
	if(voterID > -1) gvResetVote(VOTE_ALL_TYPE, voterID);
}

public OnClientDisconnect_Post(client)
{
	AdminsEventCheck(); // disable plugin if admin on server
}

public AdminsEventCheck()
{
	if(adplugin) 
	{
		if(AdminsOnServer()) adminonserver = true; 
		else adminonserver = false;
	}
}

public bool:AdminsOnServer()
{
	new bool:admins = false;
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(ValidClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) 
		{
			admins = true; // found admin
			#if defined PLUGIN_DEBUG
			PrintToServer("::Debug:: Found admin: %N, plugin disabled.",i);
			LogToFileEx(gvlog, "%s::Debug:: Found admin: %N, plugin disabled.",logprefix,i);
			#endif
		}
	}

	return admins;
}

public VoteInit(client, type)
{
	// antiflood
	if(gvVotes[gvUseridGvID[client]][antiflood] > GetTime())
	{
		new waits = gvVotes[gvUseridGvID[client]][antiflood] - GetTime();
		if(morecolors) CPrintToChat(client, "%T", "GameVoting_antiflood", client, clogprefix, waits);
		else PrintToChat(client, "%T", "GameVoting_antiflood", client, clogprefix, waits);
		return;
	}
	
	// Check needed players for enable plugin
	if(countplayers() < needplayers)
	{
		//PrintToChat(client,"[gv] Need more than %d players on the server",needplayers);
		if(morecolors) CPrintToChat(client, "%T", "GameVoting_needplayers", client, clogprefix, needplayers);
		else PrintToChat(client, "%T", "GameVoting_needplayers", client, clogprefix, needplayers);
		return;
	}
	
	if(adplugin && adminonserver)
	{
		//PrintToChat(client,"[gv] Votes are disabled, because admin on server.");
		if(morecolors) CPrintToChat(client, "%T", "GameVoting_admin_on_server", client, clogprefix);
		else PrintToChat(client, "%T", "GameVoting_admin_on_server", client, clogprefix);
		return;
	}

	switch(type)
	{
		case VOTEKICK_TYPE:
		{
			if(GetConVarInt(g_kickenable) < 1)
			{
				if(morecolors) CPrintToChat(client, "%T", "GameVoting_kick_disabled", client, clogprefix);
				else PrintToChat(client, "%T", "GameVoting_kick_disabled", client, clogprefix);
				return;
			}
		}
		case VOTEBAN_TYPE:
		{
			if(GetConVarInt(g_banenable) < 1)
			{
				if(morecolors) CPrintToChat(client, "%T", "GameVoting_ban_disabled", client, clogprefix);
				else PrintToChat(client, "%T", "GameVoting_ban_disabled", client, clogprefix);
				return;
			}
		}
		case VOTEMUTE_TYPE:
		{
			if(GetConVarInt(g_muteenable) < 1)
			{
				if(morecolors) CPrintToChat(client, "%T", "GameVoting_mute_disabled", client, clogprefix);
				else PrintToChat(client, "%T", "GameVoting_mute_disabled", client, clogprefix);
				return;
			}
		}
		case VOTESILENCE_TYPE:
		{
			if(GetConVarInt(g_silenceenable) < 1)
			{
				if(morecolors) CPrintToChat(client, "%T", "GameVoting_silence_disabled", client, clogprefix);
				else PrintToChat(client, "%T", "GameVoting_silence_disabled", client, clogprefix);
				return;
			}
		}
	}
	
	// Create handle for dynamic menu
	new Handle:menu;
	
	// Get percent to get finish off vote
	// Depends on the type of voting 
	new percent = gvNeedfor(type);

	// Set special title and callback for menu
	// Depends on the type of voting
	decl String:translate_buffer[86];
	switch(type)
	{
		case VOTEKICK_TYPE:
		{
			menu = CreateMenu(MenuHandler_Votekick, MenuAction:MENU_NO_PAGINATION);
			//SetMenuTitle(menu, "Votekick");
			Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_menu_title_kick", client, clogprefix);
			SetMenuTitle(menu, translate_buffer);
		}
		case VOTEBAN_TYPE:
		{
			menu = CreateMenu(MenuHandler_Voteban, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_menu_title_ban", client, clogprefix);
			SetMenuTitle(menu, translate_buffer);
		}
		case VOTESILENCE_TYPE:
		{
			menu = CreateMenu(MenuHandler_Votesilence, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_menu_title_silence", client, clogprefix);
			SetMenuTitle(menu, translate_buffer);
		}
		case VOTEMUTE_TYPE:
		{
			menu = CreateMenu(MenuHandler_Votemute, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_menu_title_mute", client, clogprefix);
			SetMenuTitle(menu, translate_buffer);
		}
	}

	// Add reset vote in menu
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_reset_vote", client);
	AddMenuItem(menu, "-1", translate_buffer, ITEMDRAW_DEFAULT);

	// Add players in menu
	decl String:showString[86];
	new String:clientID[11];
	
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidClient(x) && x != client  ) // ADD & x != client 
		{
			new gvIdd = gvGetID(x); // get GvID for get info about votes
			IntToString(x, clientID, sizeof(clientID)); // set userid in string for callback
			// Format string
			switch(type)
			{
				// cases is more faster than if
				case VOTEKICK_TYPE: 	Format(showString, sizeof(showString), "%N (%d/%d)", x, gvVotes[gvIdd][votekick],percent);
				case VOTEBAN_TYPE: 		Format(showString, sizeof(showString), "%N (%d/%d)", x, gvVotes[gvIdd][voteban],percent);
				case VOTEMUTE_TYPE:  	{
					if(gvVotes[gvIdd][mute_timestamp] > GetTime())
						Format(showString, sizeof(showString), "%N (muted)", x);
					else 
						Format(showString, sizeof(showString), "%N (%d/%d)", x, gvVotes[gvIdd][votemute],percent);
				}
				case VOTESILENCE_TYPE: 	{
					if(gvVotes[gvIdd][silence_timestamp] > GetTime()) 
						Format(showString, sizeof(showString), "%N (silenced)", x);
					else 
						Format(showString, sizeof(showString), "%N (%d/%d)", x, gvVotes[gvIdd][votesilence],percent);
				}
			}

			// Add item
			if(!noimmunity)
			{
				new AdminId:adminclient = GetUserAdmin(x);
				if(adminclient != INVALID_ADMIN_ID) 
				{
					if(clientHaveFlag(adminclient) == false) 
					{
						AddMenuItem(menu, clientID, showString, ITEMDRAW_DEFAULT);
					}
					#if defined PLUGIN_DEBUG
					else
					{
						PrintToServer("::Debug:: Exclude player %N because admin with immunity flag.",x);
						LogToFileEx(gvlog, "%s::Debug:: Exclude player %N because admin with immunity flag.",logprefix,x);
					}
					#endif
				}
				else
				{
					AddMenuItem(menu, clientID, showString, ITEMDRAW_DEFAULT);
				}
			}
			else
			{
				AddMenuItem(menu, clientID, showString, ITEMDRAW_DEFAULT);
			}
		}
	}

	// Add exit button
	SetMenuExitBackButton(menu, true);
	
	// Display menu
	DisplayMenu(menu, client, 12); // with timeout 12sec
}

public MenuHandler_Votekick(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if(action == MenuAction_Select) 
	{
		// get client, votefor
		new String:ClientID[11];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		prepareVote(client, ClientID, VOTEKICK_TYPE);
	}
}

public MenuHandler_Voteban(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if(action == MenuAction_Select) 
	{
		// get client, votefor
		new String:ClientID[11];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		prepareVote(client, ClientID, VOTEBAN_TYPE);
	}
}

public MenuHandler_Votemute(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if(action == MenuAction_Select) 
	{
		// get client, votefor
		new String:ClientID[11];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		prepareVote(client, ClientID, VOTEMUTE_TYPE);
	}
}

public MenuHandler_Votesilence(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	else if(action == MenuAction_Select) 
	{
		// get client, votefor
		new String:ClientID[11];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		prepareVote(client, ClientID, VOTESILENCE_TYPE);
	}
}

public prepareVote(client, String:clientID[], type)
{
	new indicteec = StringToInt(clientID); // convert userid into integer
	if(indicteec == -1) 
	{
		new gvidd = gvGetID(client);
		gvResetVote(type, gvidd);
		if(morecolors) CPrintToChat(client, "%T", "GameVoting_reseted",client,clogprefix);
		else PrintToChat(client, "%T", "GameVoting_reseted",client,clogprefix);
	}
	else gvVotefor(type, client, indicteec);
	gvVotes[gvUseridGvID[client]][antiflood] = (GetTime()+GetConVarInt(g_antiflood));
}

public gvVotefor(type, voter, indicteec)
{
	// Get GvID for each player
	new voterID = gvGetID(voter);
	new indicteeID = gvGetID(indicteec);

	// If valid GvID
	if(voterID > -1 && indicteeID > -1) // if GvID found.
	{
		//Prevent vote for same client
		if(gvVotes[voterID][indictee] == indicteeID && gvVotes[voterID][lasttype] == type)
		{
			#if defined PLUGIN_DEBUG
				PrintToServer("::Debug:: Player (#%d) already voted for (#%d)",voterID,indicteeID);
				LogToFileEx(gvlog, "%s::Debug:: Player (#%d) already voted for (#%d)",logprefix, voterID,indicteeID);
			#endif
			// exit
			return;
		}
		
		// Reset old vote
		if(gvVotes[voterID][indictee] > -1) gvResetVote(type, voterID);

		// Do vote
		gvAddVote(type, voterID, indicteeID); // Add vote
		new gvneed = gvNeedfor(type);

		// Add text
		//decl String:translate_buffer[128];
		decl String:votername[64], String:indicteecname[64];
		GetClientName(voter, votername, sizeof(votername));
		GetClientName(indicteec, indicteecname, sizeof(indicteecname));
		switch(type)
		{
			case VOTEKICK_TYPE:
			{
				gvVotes[voterID][lasttype] = type;
				
				for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
					if(morecolors) CPrintToChat(x, "%T", "GameVoting_voted_for_kick",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votekick],gvneed);
					else PrintToChat(x, "%T", "GameVoting_voted_for_kick",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votekick],gvneed);
				}
				if(glogs) LogToFileEx(gvlog, "%s player %N voted for kick %N.(%d/%d)", logprefix,voter, indicteec, gvVotes[indicteeID][votekick], gvneed);
				if(gvVotes[indicteeID][votekick] >= gvneed) {
					gvVotes[indicteeID][votekick] = 0;
					gvKickPlayer(indicteeID, indicteec, indicteecname);
				}
				
			}
			case VOTEBAN_TYPE:
			{
				gvVotes[voterID][lasttype] = type;
				
				for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
					if(morecolors) CPrintToChat(x, "%T", "GameVoting_voted_for_ban",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][voteban],gvneed);
					else PrintToChat(x, "%T", "GameVoting_voted_for_ban",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][voteban],gvneed);
				}
				if(glogs) LogToFileEx(gvlog, "%s player %N voted for ban %N.(%d/%d)", logprefix, voter, indicteec, gvVotes[indicteeID][voteban], gvneed);
				if(gvVotes[indicteeID][voteban] >= gvneed) {
					gvVotes[indicteeID][voteban] = 0;
					gvBanPlayer(indicteeID, indicteec, indicteecname);
				}
			}
			case VOTESILENCE_TYPE:
			{
				gvVotes[voterID][lasttype] = type;
				
				if(gvVotes[indicteeID][silence_timestamp] < GetTime())
				{
					for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
						if(morecolors) CPrintToChat(x, "%T", "GameVoting_voted_for_silence",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votesilence],gvneed);
						else PrintToChat(x, "%T", "GameVoting_voted_for_silence",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votesilence],gvneed);
					}
					if(gvVotes[indicteeID][votesilence] >= gvneed) 
					{
						gvVotes[indicteeID][votesilence] = 0;
						//PrintToChatAll("[gv] Player %N was silenced by vote.",indicteec);
						for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
							if(morecolors) CPrintToChat(x, "%T", "GameVoting_was_silenced",x,clogprefix,indicteecname);
							else PrintToChat(x, "%T", "GameVoting_was_silenced",x,clogprefix,indicteecname);
						}
						gvVotes[indicteeID][silence_timestamp] = (GetTime()+GetConVarInt(g_silencetime));
						gvSilencePlayer(indicteec);
					}
				}
				#if defined PLUGIN_DEBUG
				else
				{
					PrintToServer("::Debug:: ERROR! player already silenced!gvid(#%d),%N",indicteeID,indicteec);
					LogToFileEx(gvlog, "%s::Debug:: ERROR! player already silenced!gvid(#%d),%N",logprefix,indicteeID,indicteec);
				}
				#endif
			}
			case VOTEMUTE_TYPE:
			{
				gvVotes[voterID][lasttype] = type;
	
				if(gvVotes[indicteeID][mute_timestamp] < GetTime())
				{
					//PrintToChatAll("[gv] Player %N voted for mute %N (%d/%d)",voter,indicteec,gvVotes[indicteeID][votemute],gvneed);
					for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
						if(morecolors) CPrintToChat(x, "%T", "GameVoting_voted_for_mute",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votemute],gvneed);
						else PrintToChat(x, "%T", "GameVoting_voted_for_mute",x,clogprefix,votername,indicteecname,gvVotes[indicteeID][votemute],gvneed);
					}
					if(gvVotes[indicteeID][votemute] >= gvneed) 
					{
						gvVotes[indicteeID][votemute] = 0;
						//PrintToChatAll("[gv] Player %N was muted by vote.",indicteec);
						for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
							if(morecolors) CPrintToChat(x, "%T", "GameVoting_was_muted",x,clogprefix,indicteecname);
							else PrintToChat(x, "%T", "GameVoting_was_muted",x,clogprefix,indicteecname);
						}
						gvVotes[indicteeID][mute_timestamp] = (GetTime()+GetConVarInt(g_mutetime));
						gvMutePlayer(indicteec);
					}

				}
				#if defined PLUGIN_DEBUG
				else
				{
					PrintToServer("::Debug:: ERROR! player already muted!gvid(#%d),%N",indicteeID,indicteec);
					LogToFileEx(gvlog, "%s::Debug:: ERROR! player already muted!gvid(#%d),%N",logprefix,indicteeID,indicteec);
				}
				#endif
			}
		}
		
	}
	#if defined PLUGIN_DEBUG
	else
	{
		PrintToServer("::Debug:: ERROR! voterID(#%d) or indicteeID(#%d) invalid!",voterID,indicteeID);
		LogToFileEx(gvlog, "%s::Debug:: ERROR! voterID(#%d) ~ indicteeID(#%d) invalid!",logprefix, voterID,indicteeID);
	}
	#endif
}

public gvMutePlayer(clientUserID)
{
	decl String:translate_buffer[86];
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_cant_voice_chat", clientUserID);
	PrintToChat(clientUserID,translate_buffer);
	PrintCenterText(clientUserID,translate_buffer);
	BaseComm_SetClientMute(clientUserID, true);
	if(gaclogs) LogToFileEx(gvactions, "%s Mute player [%N](gvid#%d)(userid#%d)",logprefix,clientUserID,gvGetID(clientUserID),clientUserID);
	#if defined PLUGIN_DEBUG
	PrintToServer("::Debug:: Mute player %N",clientUserID);
	LogToFileEx(gvlog, "%s::Debug:: Mute player %N",logprefix,clientUserID);
	#endif
}

public gvUnmutePlayer(clientUserID)
{
	decl String:translate_buffer[86];
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_can_voice_chat", clientUserID);
	new clientGvID = gvGetID(clientUserID);
	PrintToChat(clientUserID,translate_buffer);
	PrintCenterText(clientUserID,translate_buffer);
	gvVotes[clientGvID][mute_timestamp] = 0;
	BaseComm_SetClientMute(clientUserID, false);
	#if defined PLUGIN_DEBUG
	PrintToServer("::Debug:: Unmute player %N gvid(#%d)",clientUserID,clientGvID);
	LogToFileEx(gvlog, "%s::Debug:: Unmute player %N gvid(#%d)",logprefix,clientUserID,clientGvID);
	#endif
}

public gvSilencePlayer(clientUserID)
{
	decl String:translate_buffer[86];
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_cant_talk_chat", clientUserID);
	PrintToChat(clientUserID,translate_buffer);
	PrintCenterText(clientUserID,translate_buffer);
	BaseComm_SetClientMute(clientUserID, true);
	BaseComm_SetClientGag(clientUserID, true);
	if(gaclogs) LogToFileEx(gvactions, "%s Silenced player [%N](gvid#%d)(userid#%d)",logprefix,clientUserID,gvGetID(clientUserID),clientUserID);
	#if defined PLUGIN_DEBUG
	PrintToServer("::Debug:: Silence player %N",clientUserID);
	LogToFileEx(gvlog, "%s::Debug:: Silence player %N",logprefix,clientUserID);
	#endif
}

public gvUnsilencePlayer(clientUserID)
{
	new clientGvID = gvGetID(clientUserID);
	decl String:translate_buffer[86];
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_can_talk_chat", clientUserID);
	PrintToChat(clientUserID,translate_buffer);
	PrintCenterText(clientUserID,translate_buffer);
	gvVotes[clientGvID][silence_timestamp] = 0;
	BaseComm_SetClientMute(clientUserID, false);
	BaseComm_SetClientGag(clientUserID, false);
	#if defined PLUGIN_DEBUG
	PrintToServer("::Debug:: Unsilence player %N gvid(#%d)",clientUserID);
	LogToFileEx(gvlog, "%s::Debug:: Unsilence player %N gvid(#%d)" ,logprefix,clientUserID);
	#endif
}

public gvBanPlayer(clientGvID, clientUserID, String:ClientName[])
{
	// kick player by vote
	//PrintToChatAll("[gv] Player %N was banned by vote.",clientUserID);
	for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
		if(morecolors) CPrintToChat(x, "%T", "GameVoting_was_banned",x,clogprefix,ClientName);
		else PrintToChat(x, "%T", "GameVoting_was_banned",x,clogprefix,ClientName);
	}
	if(glogs) LogToFileEx(gvlog, "%s player %N banned by vote.", logprefix, clientUserID);
	
	if(gsourcebans)
	{
		ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(clientUserID), GetConVarInt(g_bantime), "Banned by GameVoting"); // sourcebans version
		if(glogs) LogToFileEx(gvlog, "sm_ban #%d %d \"%s\"", GetClientUserId(clientUserID), GetConVarInt(g_bantime), "Banned by GameVoting");
	}
	else 
		BanClient(clientUserID, GetConVarInt(g_bantime), BANFLAG_AUTHID, "Banned by GameVoting","Banned by GameVoting"); // without sourcebans
	
	//if(ValidClient(clientUserID)) KickClient(clientUserID, "You banned by GameVoting"); // kick player for true
	if(gaclogs) 
	{
		new String:steamid[32];
		GetClientAuthString(clientUserID, steamid, sizeof(steamid));
		LogToFileEx(gvactions, "%s Player got ban [%N](gvid#%d)(userid#%d)(%s)",logprefix,clientUserID,clientGvID,clientUserID,steamid);
	}
}

public gvKickPlayer(clientGvID, clientUserID, String:ClientName[])
{
	//PrintToChatAll("[gv] Player %N was kicked by vote.",clientUserID);
	for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) {
		if(morecolors) CPrintToChat(x, "%T", "GameVoting_was_kicked",x,clogprefix,ClientName);
		else PrintToChat(x, "%T", "GameVoting_was_kicked",x,clogprefix,ClientName);
	}
	if(glogs) LogToFileEx(gvlog, "%s player %N kicked by vote. And added to blacklist by GvID.", logprefix, clientUserID);
	gvVotes[clientGvID][blacklist_timestamp] = (GetTime()+GetConVarInt(g_kicktime));
	decl String:translate_buffer[86];
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_kick_wait_time", clientUserID, "Kicked by GameVoting", GetConVarInt(g_kicktime));
	KickClient(clientUserID,translate_buffer);
	if(gaclogs)
	{
		new String:steamid[32];
		GetClientAuthString(clientUserID, steamid, sizeof(steamid));
		LogToFileEx(gvactions, "%s Player kicked [%N](gvid#%d)(userid#%d)",logprefix,clientUserID,clientGvID,clientUserID,steamid);
	}
}

public gvNeedfor(type)
{
	new percent = 1;
	switch(type)
	{
		case VOTEKICK_TYPE: 	percent 	= 	GetConVarInt(g_kickpercent);
		case VOTEBAN_TYPE: 		percent 	= 	GetConVarInt(g_banpercent);
		case VOTEMUTE_TYPE: 	percent 	= 	GetConVarInt(g_mutepercent);
		case VOTESILENCE_TYPE: 	percent 	= 	GetConVarInt(g_silencepercent);
	}

	return ((countplayers()*percent)/100);
}

public gvAddVote(type, voterID, indicteeID)
{
	switch(type)
	{
		// Add vote for client
		case VOTEKICK_TYPE: 	gvVotes[indicteeID][votekick]++;
		case VOTEBAN_TYPE: 		gvVotes[indicteeID][voteban]++;
		case VOTESILENCE_TYPE: 	gvVotes[indicteeID][votesilence]++;
		case VOTEMUTE_TYPE: 	gvVotes[indicteeID][votemute]++;
	}
	gvVotes[voterID][indictee] = indicteeID;
	
	#if defined PLUGIN_DEBUG
		PrintToServer("::Debug:: Player (#%d) voted for (#%d)",voterID,indicteeID);
		LogToFileEx(gvlog, "%s::Debug:: Player (#%d) voted for (#%d)",logprefix ,voterID,indicteeID);
	#endif
}

public gvResetVote(type, voterID)
{
	if(gvVotes[voterID][indictee] > -1)
	{
		switch(type)
		{
			// Delete vote for someone with type
			case VOTEKICK_TYPE: 	if(gvVotes[gvVotes[voterID][indictee]][votekick] > 0) gvVotes[gvVotes[voterID][indictee]][votekick]--;
			case VOTEBAN_TYPE: 		if(gvVotes[gvVotes[voterID][indictee]][voteban] > 0) gvVotes[gvVotes[voterID][indictee]][voteban]--;
			case VOTESILENCE_TYPE: 	if(gvVotes[gvVotes[voterID][indictee]][votesilence] > 0) gvVotes[gvVotes[voterID][indictee]][votesilence]--;
			case VOTEMUTE_TYPE: 	if(gvVotes[gvVotes[voterID][indictee]][votemute] > 0) gvVotes[gvVotes[voterID][indictee]][votemute]--;
			case VOTE_ALL_TYPE:
			{
				if(gvVotes[gvVotes[voterID][indictee]][votemute] > 0) gvVotes[gvVotes[voterID][indictee]][votemute]--;
				if(gvVotes[gvVotes[voterID][indictee]][votesilence] > 0) gvVotes[gvVotes[voterID][indictee]][votesilence]--;
				if(gvVotes[gvVotes[voterID][indictee]][voteban] > 0) gvVotes[gvVotes[voterID][indictee]][voteban]--;
				if(gvVotes[gvVotes[voterID][indictee]][votekick] > 0) gvVotes[gvVotes[voterID][indictee]][votekick]--;
			}
		}
		
		// Delete indictee for voter
		gvVotes[voterID][indictee] = -1;

		#if defined PLUGIN_DEBUG
			PrintToServer("::Debug:: Player (#%d) reset vote.",voterID);
			LogToFileEx(gvlog, "%s::Debug:: Player (#%d) reset vote.",logprefix, voterID);
		#endif
	}
	#if defined PLUGIN_DEBUG
	else
	{
		PrintToServer("::Debug:: ERROR! gvResetVote() ~ invalid vote. NULL");
		LogToFileEx(gvlog, "%s::Debug:: ERROR! gvResetVote() ~ invalid vote. NULL",logprefix);
	}
	#endif
}

// Get GvID
public gvGetID(client)
{
	if(!ValidClient(client)) return -1;
	//new String:steamID[32];
	//GetClientAuthString(client, steamID, sizeof(steamID), true);

	#if defined PLUGIN_DEBUG
		PrintToServer("::Debug:: gvGetID(return #%d)",gvUseridGvID[client]);
		LogToFileEx(gvlog, "%s::Debug:: gvGetID(return #%d)",logprefix, gvUseridGvID[client]);
	#endif

	//return FindStringInArray(gvID, steamID);
	return gvUseridGvID[client];
}

// Register GvID for client
public gvRegisterID(client)
{
	if(!ValidClient(client)) return;  // block bots and fakes;
	new String:steamID[32];
	GetClientAuthString(client, steamID, sizeof(steamID), true);
	new gvidd = FindStringInArray(gvID, steamID);
	if(gvidd == -1)
	{
		// Register new client in GameVoting
		gvidd = PushArrayString(gvID,steamID);
		gvUseridGvID[client] = gvidd;
		gvVotes[gvidd][indictee] = -1;
		gvVotes[gvidd][votekick] = 0;
		gvVotes[gvidd][voteban] = 0;
		gvVotes[gvidd][votesilence] = 0;
		gvVotes[gvidd][votemute] = 0;
		//gvVotes[gvidd][blacklist] = false;

		#if defined PLUGIN_DEBUG
			PrintToServer("::Debug:: Registered %N new GvID(#%d) from %s", client, gvidd, steamID);
			LogToFileEx(gvlog, "%s::Debug:: Registered %N new GvID(#%d) from %s",logprefix ,client, gvidd, steamID);
		#endif
	}
	#if defined PLUGIN_DEBUG
	else
	{
		// We found our player
		gvUseridGvID[client] = gvidd;
		PrintToServer("::Debug:: Found GvID(#%d)! New player %N dont need in register.", gvidd, client);
		if(glogs) LogToFileEx(gvlog, "%s::Debug:: Found GvID(#%d)! New player %N dont need in register.",logprefix, gvidd, client);

		// Check kick
		if(gvVotes[gvidd][blacklist_timestamp] > GetTime())
		{
			new waitsec = gvVotes[gvidd][blacklist_timestamp]-GetTime();
			if(glogs) LogToFileEx(gvlog, "%s player %N kicked. Because was kicked.", logprefix, client);
			decl String:translate_buffer[86];
			Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_kick_wait_time", client, "Kicked by GameVoting", waitsec);
			KickClient(client,translate_buffer);
		} else gvVotes[gvidd][blacklist_timestamp] = 0; // reset kick

		// Check mute
		if(gvVotes[gvidd][mute_timestamp] > GetTime())
		{
			if(glogs) LogToFileEx(gvlog, "%s player %N muted.", logprefix, client);
			gvMutePlayer(client);
		} else gvVotes[gvidd][mute_timestamp] = 0; // reset mute
	}
	#endif
}

public gvClearData()
{
	ClearArray(gvID);
}

// Check valid client or not
bool:ValidClient(client)
{
	if(0 < client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client)) return true;
	return false;
}

public countplayers()
{
	new output = 0;
	for(new i = 1; i <= MaxClients; i++) if(ValidClient(i)) output++;
	return output;
}

public Action:Listener(client, const String:command[], argc)
{
	if(!enableplugin) return Plugin_Continue;
	if(!ValidClient(client)) return Plugin_Continue;
	// Format commands in chat
	decl String:word[24];
	GetCmdArgString(word, sizeof(word));
	StripQuotes(word);

	// detect vote commands
	// this code a piece of ****
	// if you know alternative, please tell me
	if(word[0] == '!' && word[1] == 'v') // optimize find of commands
	{
		// comparison for accuracy
		if(StrEqual(word, "!votekick")) // votekick 
		{ 
			VoteInit(client, VOTEKICK_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "!voteban"))  // voteban
		{ 
			VoteInit(client, VOTEBAN_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "!votemute")) // votemute
		{
			VoteInit(client, VOTEMUTE_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "!votesilence")) // votesilence
		{
			VoteInit(client, VOTESILENCE_TYPE);
			return Plugin_Handled;
		}
	}
	else if(word[0] == '/' && word[1] == 'v') // optimize find of commands
	{
		// comparison for accuracy
		if(StrEqual(word, "/votekick")) // votekick 
		{ 
			VoteInit(client, VOTEKICK_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "/voteban"))  // voteban
		{ 
			VoteInit(client, VOTEBAN_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "/votemute")) // votemute
		{
			VoteInit(client, VOTEMUTE_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "/votesilence")) // votesilence
		{
			VoteInit(client, VOTESILENCE_TYPE);
			return Plugin_Handled;
		}
	}
	else if(word[0] == 'v') // optimize find of commands
	{
		// comparison for accuracy
		if(StrEqual(word, "votekick")) // votekick
		{ 
			VoteInit(client, VOTEKICK_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "voteban")) // voteban
		{
			VoteInit(client, VOTEBAN_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "votemute")) // votemute
		{
			VoteInit(client, VOTEMUTE_TYPE);
			return Plugin_Handled;
		}
		else if(StrEqual(word, "votesilence")) // votesilence
		{
			VoteInit(client, VOTESILENCE_TYPE);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public bool:clientHaveFlag(AdminId:adminid)
{
	if(GetAdminFlag(adminid, ImmunityFlag)) return true;
	else return false;
}