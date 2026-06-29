#include <sourcemod>

#define VERSION "1.0"

#define MAX_PLAYERS 32
#define NAME_LENGTH 32
#define STEAMID_LENGTH 32
#define IP_LENGTH 16

new Float:g_percent;
new Handle:VoteTimers[MAX_PLAYERS + 1] = INVALID_HANDLE;
new Handle:g_VoteMenu = INVALID_HANDLE;
new Handle:h_bantime = INVALID_HANDLE;
new Handle:h_bantype = INVALID_HANDLE;
new Handle:h_ifadmin = INVALID_HANDLE;
new Handle:h_minvotes = INVALID_HANDLE;
new Handle:h_percent = INVALID_HANDLE;
new Handle:h_timer = INVALID_HANDLE;
new Handle:h_votekick = INVALID_HANDLE;
new String:list_ip[MAX_PLAYERS + 1][IP_LENGTH];
new String:list_name[MAX_PLAYERS + 1][NAME_LENGTH];
new String:list_steamid[MAX_PLAYERS + 1][STEAMID_LENGTH];
new bool:already[MAX_PLAYERS + 1][MAX_PLAYERS];
new client_userid[MAX_PLAYERS + 1];
new counter_entry;
new counter_voter;
new g_bantime;
new list_userid[MAX_PLAYERS + 1];
new list_votereq[MAX_PLAYERS + 1];
new list_timers[MAX_PLAYERS + 1];
new maxplayers;
new votes[MAX_PLAYERS + 1];

public Plugin:myinfo =
{
	name = "User's initiated voteban",
	author = "Blood",
	description = "Allow user's initiated voteban",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_uvoteban", Command_VoteBan);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	LoadTranslations("plugin.uvoteban");
	CreateConVar("uvoteban_version", VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	h_percent = FindConVar("sm_uvoteban_percent");
	if (h_percent == INVALID_HANDLE)
		h_percent = CreateConVar("sm_uvoteban_percent", "0.60", "Percent needed to voteban",FCVAR_PLUGIN, true,0.0,true,1.0);
	h_bantime = FindConVar("sm_uvoteban_bantime");
	if (h_bantime == INVALID_HANDLE)
		h_bantime = CreateConVar("sm_uvoteban_bantime", "30", "Time in minutes target will be banned (0 = Permanent)",FCVAR_PLUGIN, true, 0.0);
	h_timer = FindConVar("sm_uvoteban_time_vote_last");
	if (h_timer == INVALID_HANDLE)
		h_timer = CreateConVar("sm_uvoteban_time_vote_last", "120", "Seconds until vote end",FCVAR_PLUGIN, true, 0.0);
	h_ifadmin = FindConVar("sm_uvoteban_enable_if_admin_is_present");
	if (h_ifadmin == INVALID_HANDLE)
		h_ifadmin = CreateConVar("sm_uvoteban_enable_if_admin_is_present", "0", "Can voteban even if admin is present(1: Yes, 0: No)",FCVAR_PLUGIN, true,0.0,true,1.0);
	h_minvotes = FindConVar("sm_uvoteban_minimum_votes");
	if (h_minvotes == INVALID_HANDLE)
		h_minvotes = CreateConVar("sm_uvoteban_minimum_votes", "3", "Minimum number of votes it take to ban",FCVAR_PLUGIN, true, 0.0);
	h_bantype = FindConVar("sm_uvoteban_bantype");
	if (h_bantype == INVALID_HANDLE)
		h_bantype = CreateConVar("sm_uvoteban_bantype", "0", "0 = ban by ID, 1 = ban by IP, 2 = both",FCVAR_PLUGIN, true,0.0,true,2.0);
	h_votekick = FindConVar("sm_uvoteban_votekick");
	if (h_votekick == INVALID_HANDLE)
		h_votekick = CreateConVar("sm_uvoteban_votekick", "0", "Allow 'votekick' to be an alias of the voteban command (1: Yes, 0: No)",FCVAR_PLUGIN, true,0.0,true,1.0);
}
 
public OnMapStart()
{
	maxplayers=GetMaxClients();
}
 
public OnMapEnd()
{
	if (g_VoteMenu != INVALID_HANDLE)
	{
		CloseHandle(g_VoteMenu);
		g_VoteMenu = INVALID_HANDLE;
	}
}
 
Handle:BuildVoteMenu(client)
{
        new Handle:menu = CreateMenu(Menu_VoteBan);
        new String:name[NAME_LENGTH];
        new String:name2[NAME_LENGTH + 6];
        new String:steamid[STEAMID_LENGTH];
        new String:t_name[64];
        new String:t_userid[4];
        new bool:atleastone;
        new userid;

	g_bantime = GetConVarInt(h_bantime);
	for (new i; i < counter_entry; i++) {
		if (GetClientOfUserId(list_userid[i]) == 0) {
			Format(t_userid, 4, "%d", list_userid[i]);
			Format(t_name, 64, "%s (%T) [%d]", list_name[i], "Offline", LANG_SERVER, votes[FindEntryByUserId(list_userid[i])]);
			AddMenuItem(menu, t_userid, t_name);
		}
	}
	for (new i=1; i<=maxplayers; i++)
	{
		if (IsClientInGame(i)) {

			GetClientAuthString(i, steamid, sizeof(steamid));
			if (i != client && GetUserAdmin(i) != INVALID_ADMIN_ID && strcmp(steamid, "BOT") != 0) {
				GetClientName(i, name, NAME_LENGTH);
				userid = GetClientUserId(i);
				Format(t_userid, 4, "%i", userid);
				if (FindEntryByUserId(userid) == -1)
					Format(name2, NAME_LENGTH + 6, "%s", name);
				else
					Format(name2, NAME_LENGTH + 6, "%s [%d]", name, votes[FindEntryByUserId(userid)]);
				AddMenuItem(menu, t_userid, name2);
				atleastone = true;
			}
		}
	}
	if (atleastone == false)
		return INVALID_HANDLE;
	SetMenuTitle(menu, "%t", "Select a player", LANG_SERVER);
	return menu;
}

public Menu_VoteBan(Handle:menu, MenuAction:action, client, choice)
{
	if (action == MenuAction_Select)
	{
		new String:m_userid[NAME_LENGTH];
		GetMenuItem(menu, choice, m_userid, sizeof(m_userid));
		new userid = StringToInt(m_userid);
                new c_userid = GetClientUserId(client);
		new target = GetClientOfUserId(userid);
                new entry = FindEntryByUserId(userid);
                new entry2 = -1;
		new found = -1;
                new String:clientname[NAME_LENGTH];
                new String:dp_steamid[STEAMID_LENGTH];
                new String:name[NAME_LENGTH];
                new String:steamid[NAME_LENGTH];

		if (target == 0 || entry != -1) {
			for (new i; i<counter_entry; i++)
				if (userid == list_userid[i])
					found = i;
			Format(name, NAME_LENGTH, "%s", list_name[found]);
			Format(steamid, NAME_LENGTH, "%s", list_steamid[found]);
		} else {
			new Handle:dp;
			new String:temp_steamid[STEAMID_LENGTH];
			new counter;
			new timerid = -1;

			GetClientName(target, name, NAME_LENGTH);
			GetClientAuthString(target, steamid, sizeof(steamid));
			GetClientIP(target, list_ip[counter_entry], IP_LENGTH);
			list_userid[counter_entry] = userid;
			votes[counter_entry] = 0;
			entry = counter_entry;
			
			
			PrintToChatAll("[SM] %T", "Initiated Vote Ban", LANG_SERVER, name);
			list_userid[counter_entry] = userid;
			Format(list_name[counter_entry], NAME_LENGTH, "%s", name);
			Format(list_steamid[counter_entry], STEAMID_LENGTH, "%s", steamid);
			Format(dp_steamid, STEAMID_LENGTH, "%s", steamid);
			
			new freetimer = -1;
			for (new i; i<maxplayers && freetimer == -1; i++) {
				if (VoteTimers[i] == INVALID_HANDLE) {
					timerid = i;
					freetimer = 0;
				}
			}
			list_timers[counter_entry] = timerid;
			VoteTimers[counter_entry] = CreateDataTimer(GetConVarFloat(h_timer), EndVote, dp);
			WritePackString(dp, dp_steamid);

			for (new i=1; i<=maxplayers; i++) {
				if (IsClientInGame(i)) {
					GetClientAuthString(i, temp_steamid, sizeof(temp_steamid));
					if (strcmp(temp_steamid, "BOT") != 0)
						counter++;
				}
			}
			
			g_percent = GetConVarFloat(h_percent);
			if (RoundToCeil(counter * g_percent) < GetConVarInt(h_minvotes))
				list_votereq[counter_entry] = 3;
			else
				list_votereq[counter_entry] = RoundToCeil(counter * g_percent);
			counter_entry++;
		}

		for (new i; i<counter_voter; i++)
			if (client_userid[i] == c_userid)
				entry2 = i;
		if (entry2 == -1) {
			client_userid[counter_voter] = c_userid;
			entry2 = counter_voter;
			counter_voter++;
		}

		if (already[entry][entry2] == false) {
			entry = FindEntryByUserId(userid);
			votes[entry] = votes[entry] + 1;
			already[entry][entry2] = true;
			
			GetClientName(client, clientname, NAME_LENGTH);
			PrintToChatAll("[SM] %T", "Vote Add", LANG_SERVER, clientname, name, votes[entry], list_votereq[entry]);
			if (votes[entry] >= list_votereq[entry]) {
				if (VoteTimers[list_timers[entry]] != INVALID_HANDLE) {
					KillTimer(VoteTimers[list_timers[entry]]);
					VoteTimers[list_timers[entry]] = INVALID_HANDLE;
				}
				new bantype = GetConVarInt(h_bantype);
				if (bantype != 1)
					ServerCommand("sm_addban %d \"%s\" Voteban", g_bantime, steamid);
				if (bantype != 0)
					ServerCommand("sm_banip %d %s Voteban", g_bantime, list_ip[entry]);
				if (target != 0)
					ServerCommand("sm_kick #%d \"%t\"", userid, "You are banned", LANG_SERVER);
				PrintToChatAll("[SM] %T", "Ban Successful", LANG_SERVER, name, g_bantime);
				reset_userid(userid);
			}
		} else
			PrintToChat(client, "[SM] %T", "Already voted", LANG_SERVER);
	}
}

public Action:EndVote(Handle:timer, Handle:dp)
{
        new String:name[NAME_LENGTH];
        new String:steamid[STEAMID_LENGTH];
        new found = -1;
        new userid;
	new entry;
	
	ResetPack(dp);
	ReadPackString(dp, steamid, sizeof(steamid));

	for (new i; i<counter_entry; i++)
		if (strcmp(list_steamid[i], steamid) == 0)
			found = i;
	
	if (found != -1) {
		Format(name, NAME_LENGTH, "%s", list_name[found]);
		userid = list_userid[found];
		entry = FindEntryByUserId(userid);
		VoteTimers[list_timers[entry]] = INVALID_HANDLE;
		PrintToChatAll("[SM] %T", "Ban Failed", LANG_SERVER, name, votes[entry], list_votereq[entry]);
		reset_userid(userid);
	}
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	new startidx;
	GetCmdArgString(text, sizeof(text));
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}	

	if (strcmp(text[startidx], "voteban", false) == 0 || (strcmp(text[startidx], "votekick", false) == 0 && GetConVarInt(h_votekick) == 1))
		Command_VoteBan(client, 0);
	return Plugin_Continue;
}

public Action:Command_VoteBan(client, args)
{
	new bool:adminpresent;
	if (GetConVarInt(h_ifadmin) == 0)
		for (new i=1; i<=maxplayers && adminpresent == false; i++)
			if (IsClientInGame(i) && GetAdminFlag(GetUserAdmin(i), Admin_Ban, Access_Effective) == true)
				adminpresent = true;
	if (adminpresent == false) {
		g_VoteMenu = BuildVoteMenu(client);
		if (g_VoteMenu != INVALID_HANDLE) {
			DisplayMenu(g_VoteMenu, client, MENU_TIME_FOREVER);
			return Plugin_Handled;
		} else
			PrintToChat(client, "[SM] %t", "No valid target", LANG_SERVER);
	} else
		PrintToChat(client, "[SM] %t", "Admin present", LANG_SERVER);
	return Plugin_Continue;
}

public reset_userid(userid)
{
	new entry = FindEntryByUserId(userid);
	new String:name[NAME_LENGTH];
	new String:steamid[STEAMID_LENGTH];
	new String:new_ip[IP_LENGTH];
	new found;
	new found2;
	for (new i; i<counter_voter; i++) {
		found = -1;
		found2 = 0;
		for (new j; j<maxplayers; j++) {
			if (already[j][i] == true) {
				found = i;
				found2++;
			}
		}
		if (found != -1 && found2 == 1) {
			for (new k=found; k<counter_voter; k++) {
				if (k + 1 < counter_voter)
					client_userid[k] = client_userid[k + 1];
				else
					client_userid[k] = 0;
			}
			i--;
			counter_voter--;
		}
	}
	
	if (entry != -1) {
		for (new i=entry; i<counter_entry;i++) {
			if (i + 1 < counter_entry) {
				Format(steamid, STEAMID_LENGTH, "%s", list_steamid[i + 1]);
				Format(name, NAME_LENGTH, "%s", list_name[i + 1]);
				list_userid[i] = list_userid[i + 1];
				Format(list_name[i], NAME_LENGTH, "%s", name);
				Format(list_steamid[i], STEAMID_LENGTH, "%s", steamid);
				Format(new_ip, IP_LENGTH, list_ip[i + 1]);
				Format(list_ip[i], IP_LENGTH, new_ip);
				votes[i] = votes[i + 1];
				list_timers[i] = list_timers[i + 1];
				list_votereq[i] = list_votereq[i + 1];
			} else {
				votes[i] = 0;
				list_votereq[i] = 0;
				list_userid[i] = 0;
			}

			for (new j; j<maxplayers; j++) {
				if (j + 1 < maxplayers)
					already[i][j] = already[i + 1][j];
				else
					already[i][j] = false;

			}
		}
	}
	counter_entry--;
}

public OnClientPutInServer(client)
{
	new String:steamid[STEAMID_LENGTH];
	new userid = GetClientUserId(client);
	GetClientAuthString(client, steamid, sizeof(steamid));
 	if (strcmp(steamid, "BOT") != 0)
		for (new i; i<counter_entry; i++)
			if (strcmp(list_steamid[i], steamid) == 0)
				list_userid[i] = userid;
}

public FindEntryByUserId(userid)
{
	for (new i; i<counter_entry; i++)
		if (list_userid[i] == userid)
			return i;
	return -1;
}
