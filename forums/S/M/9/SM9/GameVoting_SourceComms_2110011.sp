#pragma semicolon 1
#include <sourcemod>
#include <sourcecomms>
#include <clientprefs>
#include <morecolors>
#define GAMEVOTING_VERSION "1.4"
public Plugin:myinfo = {
	name = "GameVoting",
	author = "Neatek",
	description = "Simple votekick and voteban",
	version = GAMEVOTING_VERSION,
	url = "http://www.neatek.ru/"
};
// ConVars
new Handle:g_PluginVersion = INVALID_HANDLE;
new Handle:g_GameVotingNeeded = INVALID_HANDLE;
new Handle:g_VotekickEnable = INVALID_HANDLE;
new Handle:g_VotebanEnable = INVALID_HANDLE;
new Handle:g_VotesilenceEnable = INVALID_HANDLE;
new Handle:g_VotemuteEnable = INVALID_HANDLE;
new Handle:g_VotebanPercent = INVALID_HANDLE;
new Handle:g_VotekickPercent = INVALID_HANDLE;
new Handle:g_VotemutePercent = INVALID_HANDLE;
new Handle:g_VotesilencePercent = INVALID_HANDLE;
new Handle:g_VotebanReason = INVALID_HANDLE;
new Handle:g_VotebanTime = INVALID_HANDLE;
new Handle:g_Deactivate = INVALID_HANDLE;
new Handle:g_HideAdmins = INVALID_HANDLE;
new Handle:g_VotesilenceTime = INVALID_HANDLE;
new Handle:g_VotemuteTime = INVALID_HANDLE;
// Enable disable plugin
new bool:g_Enabled = true;
// Storage
new pVotebanOption[MAXPLAYERS+1];
new pCountVoteban[MAXPLAYERS+1];
new pVotekickOption[MAXPLAYERS+1];
new pCountVotekick[MAXPLAYERS+1];
new pVotemuteOption[MAXPLAYERS+1];
new pCountVotemute[MAXPLAYERS+1];
new pVotesilenceOption[MAXPLAYERS+1];
new pCountVotesilence[MAXPLAYERS+1];
new bool:gSilenced[MAXPLAYERS+1];
new bool:gMuted[MAXPLAYERS+1];
// Cookies
new Handle:gCookieVotesilence;
new Handle:gCookieVotemute;

public OnPluginStart()
{
	LoadConVars();
	g_Enabled = true;
	AddCommandListener(Listener, "say");
	AddCommandListener(Listener, "say_team");
}

public OnMapStart()
{
	g_Enabled = true;
	// clear counts
	for(new i = 1; i <= MaxClients; i++)
	{
		pVotebanOption[i] = 0;
		pCountVoteban[i] = 0;
		pVotekickOption[i] = 0;
		pCountVotekick[i] = 0;
		pVotemuteOption[i] = 0;
		pCountVotemute[i] = 0;
		pVotesilenceOption[i] = 0;
		pCountVotesilence[i] = 0;
	}
}

// Reset options on disconnect
public OnClientDisconnect(client)
{
	ResetOptions(client);
	CheckAdminOption();
}

// Enable disable plugin when admins on server
public CheckAdminOption()
{
	if(GetConVarInt(g_Deactivate) > 0) 
	{
		if(cAdmins() < 1) g_Enabled = true;
		else g_Enabled = false;
	}
}

// Function for reset all options
public ResetOptions(client)
{
	VoteResetFor(client);
	VoteResetOption(client, 1);
	VoteResetOption(client, 2);
	VoteResetOption(client, 3);
	VoteResetOption(client, 4);
}

// Vote for votekick or voteban
public VoteClient(client, violator, is_what)
{
	switch(is_what)  // voteban 1
	{
		case 1:
		{
			if(pVotebanOption[client] < 1)
			{
				pVotebanOption[client] = violator;
				pCountVoteban[violator]++;
			}
		}
		case 2: // votekick 2
		{
			if(pVotekickOption[client] < 1)
			{
				pVotekickOption[client] = violator;
				pCountVotekick[violator]++;
			}
		}
		case 3: // votesilence 3
		{
			if(pVotesilenceOption[client] < 1)
			{
				pVotesilenceOption[client] = violator;
				pCountVotesilence[violator]++;
			}
		}
		case 4:// votemute 4
		{
			if(pVotemuteOption[client] < 1)
			{
				pVotemuteOption[client] = violator;
				pCountVotemute[violator]++;
			}
		}
	}
}

public VoteResetFor(client)
{
	pCountVotekick[client] = 0;
	pCountVoteban[client] = 0;
	pCountVotemute[client] = 0;
	pCountVotesilence[client] = 0;
	// reset other people choice for that player
	for(new i = 1; i <= MaxClients; i++)
	{
		if(pVotebanOption[i] == client) pVotebanOption[i] = 0;
		if(pVotekickOption[i] == client) pVotekickOption[i] = 0;
		if(pVotesilenceOption[i] == client) pVotesilenceOption[i] = 0;
		if(pVotemuteOption[i] == client) pVotemuteOption[i] = 0;
	}
}

// Reset own choice
public VoteResetOption(client, is_what)
{
	switch(is_what)
	{
		case 1: // voteban 1
		{
			if(pVotebanOption[client] > 0)
			{
				pCountVoteban[pVotebanOption[client]]--;
				pVotebanOption[client] = 0;
			}
		}
		case 2: // votekick 2
		{
			if(pVotekickOption[client] > 0)
			{
				pCountVotekick[pVotekickOption[client]]--;
				pVotekickOption[client] = 0;
			}
		}
		case 3: // votesilence 3
		{
			if(pVotesilenceOption[client] > 0)
			{
				pCountVotesilence[pVotesilenceOption[client]]--;
				pVotesilenceOption[client] = 0;
			}
		}
		case 4: // votemute 4
		{
			if(pVotemuteOption[client] > 0)
			{
				pCountVotemute[pVotemuteOption[client]]--;
				pVotemuteOption[client] = 0;
			}
		}
	}
}

// Generate percent for a ban or kick
public genPercent(is_what)
{
	new output = 0;
	// count players
	for(new i = 1; i <= MaxClients; i++) if(ValidClient(i)) output++;
	// get percent
	if(is_what == 1) return output * GetConVarInt(g_VotebanPercent) / 100;
	if(is_what == 2) return output * GetConVarInt(g_VotekickPercent) / 100;
	if(is_what == 3) return output * GetConVarInt(g_VotesilencePercent) / 100;
	if(is_what == 4) return output * GetConVarInt(g_VotemutePercent) / 100;
	return -1;
}

public cPlayers()
{
	new output = 0;
	
	for(new i = 1; i <= MaxClients; i++) 
		if(ValidClient(i)) output++;
	
	return output;
}

// Get admin count
public cAdmins()
{
	new i = 0;
	new AdminId:admin;
	
	for(new x = 1; x <= MaxClients; x++)
		if(ValidClient(x) && admin != INVALID_ADMIN_ID) i++;
	
	return i;
}

public Action:Listener(client, const String:command[], argc)
{
	if(ValidClient(client) == false || g_Enabled == false) 
		return Plugin_Continue;
	
	new String:word[64];
	GetCmdArgString(word, sizeof(word));
	StripQuotes(word);
	
	if(strcmp(word, "voteban") == 0) 
	{ 
		VoteInit(client, 1);
		return Plugin_Handled;
	}
	else if(strcmp(word, "votekick") == 0) 
	{
		VoteInit(client, 2);
		return Plugin_Handled;
	}
	else if(strcmp(word, "votemute") == 0) 
	{
		VoteInit(client, 4);
		return Plugin_Handled;
	}
	else if(strcmp(word, "votesilence") == 0) 
	{
		VoteInit(client, 3);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public VoteInit(client, is_what)
{
	// Previous checks
	if(cPlayers() >= GetConVarInt(g_GameVotingNeeded))
	{
		switch(is_what)
		{
			case 1:
			{
				if(GetConVarInt(g_VotebanEnable) < 1)
				{
					CPrintToChat(client, "{default}%T", "GameVoting_Voteban_Disabled", client);
					return;
				}
			}
			case 2:
			{
				if(GetConVarInt(g_VotekickEnable) < 1)
				{
					CPrintToChat(client, "{default}%T", "GameVoting_Votekick_Disabled", client);
					return;
				}
			}
			case 3:
			{
				if(GetConVarInt(g_VotesilenceEnable) < 1)
				{
					CPrintToChat(client, "{default}%T", "GameVoting_Votesilence_Disabled", client);
					return;
				}
			}
			case 4:
			{
				if(GetConVarInt(g_VotemuteEnable) < 1)
				{
					CPrintToChat(client, "{default}%T", "GameVoting_Votemute_Disabled", client);
					return;
				}
			}
		}
	}
	else
	{
		CPrintToChat(client, "{default}%T", "GameVoting_NeedMorePlayers", client);
		return;
	}
	
	// Functional
	new Handle:menu;
	decl String:translate_buffer[128];
	new percent = 0;
	
	switch(is_what)
	{
		case 1:
		{
			menu = CreateMenu(MenuHandler_VoteBan, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "Voteban_Menu_Title", client);
			SetMenuTitle(menu, translate_buffer);
			percent = genPercent(1);
		}
		case 2:
		{
			menu = CreateMenu(MenuHandler_VoteKick, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "Votekick_Menu_Title", client);
			SetMenuTitle(menu, translate_buffer);
			percent = genPercent(2);
		}	
		case 3:
		{
			menu = CreateMenu(MenuHandler_VoteSilence, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "Votesilence_Menu_Title", client);
			SetMenuTitle(menu, translate_buffer);
			percent = genPercent(3);
		}	
		case 4:
		{
			menu = CreateMenu(MenuHandler_VoteMute, MenuAction:MENU_NO_PAGINATION);
			Format(translate_buffer, sizeof(translate_buffer), "%T", "Votemute_Menu_Title", client);
			SetMenuTitle(menu, translate_buffer);
			percent = genPercent(4);
		}	
	}
	
	// Reset choice
	Format(translate_buffer, sizeof(translate_buffer), "%T", "GameVoting_Reset_Vote", client);
	AddMenuItem(menu, "0", translate_buffer, ITEMDRAW_DEFAULT);
	
	// Add players
	decl String:showString[86];
	new String:ClientID[16];
	new AdminId:admin;
	
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidClient(x) && x != client)
		{
			IntToString(x, ClientID, sizeof(ClientID)); // ClientID of player
			//GetClientName(x, ClientName, sizeof(ClientName)); // Name of player
			
			if(GetConVarInt(g_HideAdmins) > 0) // Hide admins?!
			{
				admin = GetUserAdmin(x);
				if(admin == INVALID_ADMIN_ID) 
				{
					switch(is_what)
					{
						case 1: // its bans
						{
							Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVoteban[x], percent);
							AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
						}
						case 2: // its kicks
						{
							Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotekick[x], percent);
							AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
						}
						case 3:  // its silence
						{
							Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotesilence[x], percent);
							AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
						}
						case 4:  // its mutes
						{
							Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotemute[x], percent);
							AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
						}
					}
				}
			}
			else 
			{
				switch(is_what)
				{
					case 1: // its bans
					{
						Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVoteban[x], percent);
						AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
					}
					case 2: // its kicks
					{
						Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotekick[x], percent);
						AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
					}
					case 3:  // its silence
					{
						Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotesilence[x], percent);
						AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
					}
					case 4:  // its mutes
					{
						Format(showString, sizeof(showString), "%N [%d/%d]", x, pCountVotemute[x], percent);
						AddMenuItem(menu, ClientID, showString, ITEMDRAW_DEFAULT);
					}
				}
			}
		}
	}
	
	// Display menu
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 12); // with timeout 12sec
}

public MenuHandler_VoteKick(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) 
		CloseHandle(menu);
	
	else if(action == MenuAction_Select) 
	{
		// Get clientID
		decl String:ClientID[16];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		new violator = StringToInt(ClientID);
		
		// Functional
		if(violator == 0)
		{
			VoteResetOption(client, 2);
			CPrintToChat(client, "{default}%T", "GameVoting_Vote_Reseted", client);
		}
		else if(ValidClient(violator) && violator != pVotekickOption[client])
		{
			// Do vote
			VoteResetOption(client, 2);
			VoteClient(client, violator, 2);
			
			// Get names for translation
			decl String:ClientName[64], String:ViolatorName[64];
			GetClientName(client, ClientName, sizeof(ClientName));
			GetClientName(violator, ViolatorName, sizeof(ViolatorName));
			
			// Get percent
			new percent = genPercent(2);
			
			// Show message on different languages
			for(new x = 1; x <= MaxClients; x++)
				if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_Votekick", x, ClientName, ViolatorName, pCountVotekick[violator], percent);
			
			if(pCountVotekick[violator] >= percent) 
			{
				LogMessage("{GV} Player %s kicked by votekick.", violator);
				KickClient(violator, "Votekicked");
				ResetOptions(violator);
			}
		}
	}
}

public MenuHandler_VoteBan(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) 
		CloseHandle(menu);
	
	else if(action == MenuAction_Select) 
	{
		// Get clientID
		decl String:ClientID[16];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		new violator = StringToInt(ClientID);
		
		// Functional
		if(violator == 0)
		{
			VoteResetOption(client, 1);
			CPrintToChat(client, "{default}%T", "GameVoting_Vote_Reseted", client);
		}
		else if(ValidClient(violator) && violator != pVotebanOption[client] )
		{
			// Do vote
			VoteResetOption(client, 1);
			VoteClient(client, violator, 1);
			
			// Get names for translation
			decl String:ClientName[64], String:ViolatorName[64];
			GetClientName(client, ClientName, sizeof(ClientName));
			GetClientName(violator, ViolatorName, sizeof(ViolatorName));
			
			// Get percent
			new percent = genPercent(1);
			
			// Show message on different languages
			for(new x = 1; x <= MaxClients; x++)
				if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_Voteban", x, ClientName, ViolatorName, pCountVoteban[violator], percent);
			
			if(pCountVoteban[violator] >= percent)
			{
				decl String:reason[64];
				GetConVarString(g_VotebanReason, reason, sizeof(reason));
				LogMessage("{GV} Player %s banned. (%s)", ViolatorName, reason);
				ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(violator), GetConVarInt(g_VotebanTime), reason);
				ResetOptions(violator);
			}
		}
	}
}

public MenuHandler_VoteSilence(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) 
		CloseHandle(menu);
	
	else if(action == MenuAction_Select) 
	{
		// Get clientID
		decl String:ClientID[16];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		new violator = StringToInt(ClientID);
		
		// Functional
		if(violator == 0)
		{
			VoteResetOption(client, 3);
			CPrintToChat(client, "{default}%T", "GameVoting_Vote_Reseted", client);
		}
		else if(ValidClient(violator) && violator != pVotesilenceOption[client] && gSilenced[violator] == false)
		{
			// Do vote
			VoteResetOption(client, 3);
			VoteClient(client, violator, 3);
			
			// Get names for translation
			decl String:ClientName[64], String:ViolatorName[64];
			GetClientName(client, ClientName, sizeof(ClientName));
			GetClientName(violator, ViolatorName, sizeof(ViolatorName));
			
			// Get percent
			new percent = genPercent(3);
			
			// Show message on different languages
			for(new x = 1; x <= MaxClients; x++)
				if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_Votesilence", x, ClientName, ViolatorName, pCountVotesilence[violator], percent);
			
			if(pCountVotesilence[violator] >= percent)
			{
				new String:AuthID[64];
				GetClientAuthString(violator, AuthID, sizeof(AuthID));
				new timeto = (GetTime()+(GetConVarInt(g_VotesilenceTime)*60));
				new String:timetostr[11];
				IntToString(timeto, timetostr, sizeof(timetostr));
				SetAuthIdCookie(AuthID, gCookieVotesilence, timetostr);
				
				new TypeMute = SourceComms_GetClientMuteType(client);
				new TypeGag = SourceComms_GetClientGagType(client);
				
				if(TypeMute == (bNot, 0))
					SourceComms_SetClientMute(violator, true, GetConVarInt(g_VotemuteTime), true, "Silenced By Vote");
				
				if(TypeGag == (bNot, 0))
					SourceComms_SetClientGag(violator, true, GetConVarInt(g_VotemuteTime), true, "Silenced By Vote");
				
				LogMessage("{GV} Player %s silenced.", ViolatorName);
				gSilenced[violator] = true;
				for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_silence", x, ViolatorName);
				ResetOptions(violator);
			}
		}
	}
}

public MenuHandler_VoteMute(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) 
		CloseHandle(menu);
	
	else if(action == MenuAction_Select) 
	{
		// Get clientID
		decl String:ClientID[16];
		GetMenuItem(menu, param2, ClientID, sizeof(ClientID));
		new violator = StringToInt(ClientID);
		
		// Functional
		if(violator == 0)
		{
			VoteResetOption(client, 4);
			CPrintToChat(client, "{default}%T", "GameVoting_Vote_Reseted", client);
		}
		else if(ValidClient(violator) && violator != pVotemuteOption[client] && gMuted[violator] == false)
		{
			// Do vote
			VoteResetOption(client, 4);
			VoteClient(client, violator, 4);
			
			// Get names for translation
			decl String:ClientName[64], String:ViolatorName[64];
			GetClientName(client, ClientName, sizeof(ClientName));
			GetClientName(violator, ViolatorName, sizeof(ViolatorName));
			
			// Get percent
			new percent = genPercent(4);
			
			// Show message on different languages
			for(new x = 1; x <= MaxClients; x++)
				if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_Votemute", x, ClientName, ViolatorName, pCountVotemute[violator], percent);
			
			if(pCountVotemute[violator] >= percent)
			{
				new String:AuthID[64];
				GetClientAuthString(violator, AuthID, sizeof(AuthID));
				new timeto = (GetTime()+(GetConVarInt(g_VotemuteTime)*60));
				new String:timetostr[11];
				IntToString(timeto, timetostr, sizeof(timetostr));
				SetAuthIdCookie(AuthID, gCookieVotemute, timetostr);
				
				new TypeMute = SourceComms_GetClientMuteType(client);
				
				if(TypeMute == (bNot, 0))
					SourceComms_SetClientMute(violator, true, GetConVarInt(g_VotemuteTime), true, "Muted By Vote");
				
				LogMessage("{GV} Player %s muted.", ViolatorName);
				gMuted[violator] = true;
				for(new x = 1; x <= MaxClients; x++) if(ValidClient(x)) CPrintToChat(x, "%T", "GameVoting_muted", x, ViolatorName);
				ResetOptions(violator);
			}
		}
	}
}

// Load ConVars
public LoadConVars()
{
	LoadTranslations("phrases.GameVoting");
	g_PluginVersion = CreateConVar("sm_gamevoting_version", GAMEVOTING_VERSION, "Version of GameVoting plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_GameVotingNeeded = CreateConVar("gv_need_players", "2", "Needed count of players for enable plugin");
	g_Deactivate = CreateConVar("gv_deactivate_admin_on_server", "1", "Disable plugin when admin on server v1.3");
	g_VotekickEnable = CreateConVar("gv_votekick_enable", "1", "Enable or disable votekick");
	g_VotebanEnable = CreateConVar("gv_voteban_enable", "1", "Enable or disable voteban");
	g_VotemuteEnable = CreateConVar("gv_votemute_enable", "1", "Enable or disable votemute v1.4");
	g_VotesilenceEnable = CreateConVar("gv_votesilence_enable", "1", "Enable or disable votesilence v1.4");
	g_VotekickPercent = CreateConVar("gv_votekick_percent", "50", "How much percent of players needed for kick");
	g_VotebanPercent = CreateConVar("gv_voteban_percent", "50", "How much percent of players needed for ban");
	g_VotemutePercent = CreateConVar("gv_votemute_percent", "50", "How much percent of players needed for mute v1.4");
	g_VotesilencePercent = CreateConVar("gv_votesilence_percent", "50", "How much percent of players needed for silence v1.4");
	g_VotebanReason = CreateConVar("gv_voteban_reason", "Banned by Vote", "Reason of ban for voteban");
	g_VotebanTime = CreateConVar("gv_voteban_time", "120", "Time of ban (minutes)");
	g_VotesilenceTime = CreateConVar("gv_votesilence_time", "10", "Time of silence  (minutes) v1.4");
	g_VotemuteTime = CreateConVar("gv_votemute_time", "15", "Time of mute (minutes) v1.4");
	g_HideAdmins = CreateConVar("gv_hide_admins", "1", "Hide admins from votekick and voteban v1.3");
	gCookieVotemute = RegClientCookie("GVotemute", "[GV] Votemute state", CookieAccess_Protected);
	gCookieVotesilence = RegClientCookie("GVotesilence", "[GV] Votesilence state", CookieAccess_Protected);
	HookConVarChange(g_PluginVersion, UpdateConVarVersion);
	AutoExecConfig(true);
}

// Check valid client or not
bool:ValidClient(client)
{
	if(0 < client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client)) return true;
	return false;
}

public UpdateConVarVersion(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(g_PluginVersion, GAMEVOTING_VERSION, true, true);
}