#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon		1

#define PLUGIN_VERSION		"1.0"

#define PLYR			MAXPLAYERS+1
#define IsClientValid(%1)	( 0 < %1 && %1 <= MaxClients )
#define CLIENTFLAG(%1)		( 1 << %1 )

// Credit to SasquatchTeaParty, random guy who thought up this idea

public Plugin myinfo = { // Registers plugin
	name = "Teleporter Filter",
	author = "Nergal / Nirgal / Ashurian / Assyrian",
	description = "Allows Engineers to filter who can use their teleporters or not",
	version = PLUGIN_VERSION,
	url = "google.com",
};

int TeleFlags[PLYR];

static const char strClassNames[10][] = {
	"unknown",
	"scout",
	"sniper",
	"soldier",
	"demo",
	"medic",
	"heavy",
	"pyro",
	"spy",
	"engi"
};

ConVar
	PluginEnabled = null,
	AllowBlockPcntge = null
;

public void OnPluginStart()
{
	PluginEnabled = CreateConVar("telefilter_enabled", "1", "Enable the Teleporter Filter plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	AllowBlockPcntge = CreateConVar("telefilter_blockpercentage", "0.5", "the percentage of one's team an engineer can actually filter and block", FCVAR_NONE, true, 0.0, true, 1.0);

	RegAdminCmd("sm_admin_telefilterreset", Command_AdminReset, ADMFLAG_SLAY, "Admin Command");
	RegAdminCmd("sm_admin_resettelefilter", Command_AdminReset, ADMFLAG_SLAY, "Admin Command");
	RegAdminCmd("sm_admintelefilter_reset", Command_AdminReset, ADMFLAG_SLAY, "Admin Command");
	RegConsoleCmd("sm_telefilter", Command_Filter);
	RegConsoleCmd("sm_tele_filter", Command_Filter);

	RegConsoleCmd("sm_telefilterreset", Command_ResetFilter);
	RegConsoleCmd("sm_resettelefilter", Command_ResetFilter);
	RegConsoleCmd("sm_telefilter_reset", Command_ResetFilter);
	RegConsoleCmd("sm_tele_filterreset", Command_ResetFilter);
	RegConsoleCmd("sm_resetfilter", Command_ResetFilter);
	
	RegConsoleCmd("sm_telefilterhelp", Command_FilterHelp);
	RegConsoleCmd("sm_telefilter_help", Command_FilterHelp);

	for ( int i = MaxClients ; i ; --i ) {
		if ( !IsValidClient(i) )
			continue;
		OnClientPutInServer(i);
	}
}
public void OnClientPutInServer(int client)
{
	TeleFlags[client] = 0;
}

public void HelpPanel(const int client)
{
	if ( IsVoteInProgress() )
		return ;
	char helpstr[270];
	//SetGlobalTransTarget(this.index);
	Format(helpstr, sizeof(helpstr), "[Teleporter Filter] Commands:\n!admin_telefilterreset: an Admin command, forcefully resets player's Teleporter Filter.\n!telefilter: let's you filter players by name or class from using your teleporters.\n!resettelefilter: Let's you reset your Teleporter Filter.");
	Panel panel = new Panel();
	panel.SetTitle (helpstr);
	panel.DrawItem( "Exit" );
	panel.Send(client, HintPanel, 12);
	delete (panel);
}

public int HintPanel(Menu menu, MenuAction action, int param1, int param2)
{
	return;
}
public Action Command_FilterHelp(int client, int args)
{
	if ( ! PluginEnabled.BoolValue )
		return Plugin_Continue;

	HelpPanel(client);
	return Plugin_Handled;
}

public Action Command_AdminReset(int client, int args)
{
	if ( ! PluginEnabled.BoolValue )
		return Plugin_Continue;

	if (args < 1) {
		ReplyToCommand(client, "[Teleporter Filter] Usage: !sm_admin_resettelefilter <name|@all|@team> ");
		return Plugin_Handled;
	}
	char szTargetname[64]; GetCmdArg(1, szTargetname, sizeof(szTargetname));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS+1], target_count;
	bool tn_is_ml;
	if ( (target_count = ProcessTargetString(szTargetname, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0 ) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		if ( IsValidClient(target_list[i]) )
		{
			TeleFlags[target_list[i]] = 0;
		}
	}
	return Plugin_Handled;
}

public Action Command_ResetFilter(int client, int args)
{
	if ( ! PluginEnabled.BoolValue )
		return Plugin_Continue;

	TeleFlags[client] = 0;
	ReplyToCommand(client, "[Teleporter Filter] Your Teleporter Filter has been Reset!");
	return Plugin_Handled;
}
public Action Command_Filter(int client, int args)
{
	if ( ! PluginEnabled.BoolValue )
		return Plugin_Continue;

	if (args < 1) {
		ReplyToCommand(client, "[Teleporter Filter] Usage: !sm_telefilter <player name or class name>");
		return Plugin_Handled;
	}
	else if (TF2_GetPlayerClass(client) != TFClass_Engineer) // Block non-Engineers from using command
	{
		ReplyToCommand(client, "[Teleporter Filter] You need to be an Engineer to use this command.");
		return Plugin_Handled;
	}
	else if ( IsHalfOfTeamBlocked(client) )
	{
		ReplyToCommand(client, "[Teleporter Filter] You cannot block %f or more of your Team!", AllowBlockPcntge.FloatValue);
		return Plugin_Handled;
	}

	TFClassType classnum;
	char szTargetname[64]; GetCmdArg(1, szTargetname, sizeof(szTargetname));

	// Check class names first then check if it's a player name

	for ( TFClassType i = TFClass_Scout; i <= TFClass_Engineer; ++i ) // Loop through all the class strings and find a match
	{
		if ( StrContains(szTargetname, strClassNames[ view_as<int>(i) ], false) != -1 )
		{
			classnum = i;
			break;
		}
	}

	if (classnum) { // We found a match and we will block players, on our team, by class
		for (int k = MaxClients; k; --k) {
			if ( ! IsValidClient(k) || client == k ) // Don't block ourselves by accident
				continue;

			if ( (GetClientTeam(client) != GetClientTeam(k)) || (TF2_GetPlayerClass(k) != classnum) )
			{
				TeleFlags[client] &= ~k; // player changed team or class, remove them
				continue;
			}
			if (IsTargetTeleBlocked(client, k) || IsHalfOfTeamBlocked(client)) // If already blocked, move on
				continue;

			TeleFlags[client] |= CLIENTFLAG(k); //1 << k;
		}
		ReplyToCommand(client, "[Teleporter Filter] Blocked %i Class from using your teleporter", view_as<int>(classnum));
	}
	else { /* Now we get the remaining argument by name of players, this may or may not glitch out if someone has the same name as a class */
		int target = FindTarget(client, szTargetname, false, false);
		if ( IsValidClient(target) && client != target && GetClientTeam(client) == GetClientTeam(target) )
		{
			TeleFlags[client] |= CLIENTFLAG(target); //1 << target;
			ReplyToCommand(client, "[Teleporter Filter] Blocked %N from using your teleporter", target);
		}
		/*else { // Check if player put userid!
			int userid = StringToInt(szTargetname);
			int player = GetClientOfUserId(userid);
			if ( IsValidClient(player) && client != player && GetClientTeam(client) == GetClientTeam(player) )
			{
				TeleFlags[client] |= CLIENTFLAG(player); //1 << player;
				ReplyToCommand(client, "[Teleporter Filter] Blocked %N from using your teleporter", player);
			}
		}*/
	}
	return Plugin_Handled;
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool& result)
{
	int owner = GetBuilder(teleporter);
	if ( IsTargetTeleBlocked(owner, client) ) {
		result = false;
		SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 255, 255);
		ShowHudText(client, -1, "%N has blocked you from using their Teleporter.", owner);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsTargetTeleBlocked(const int engie, const int target)
{
	if ( TeleFlags[engie] & CLIENTFLAG(target) )
		return true;
	return false;
}
stock bool IsHalfOfTeamBlocked(const int engie)
{
	float blockedcount, teamcount;
	for (int i = MaxClients; i; --i) {
		if ( ! IsValidClient(i) || engie == i )
			continue;
		if ( GetClientTeam(engie) == GetClientTeam(i) )
			++teamcount;
		if ( IsTargetTeleBlocked(engie, i) )
			++blockedcount;
	}
	if ( blockedcount / teamcount >= AllowBlockPcntge.FloatValue /*0.5*/ )
		return true;
	return false;
}

stock bool IsValidClient(const int client, bool replaycheck = true)
{
	if ( !IsClientValid(client) )
		return false;
	if ( !IsClientInGame(client) )
		return false;
	if ( GetEntProp(client, Prop_Send, "m_bIsCoaching") )
		return false;
	if ( replaycheck )
		if ( IsClientSourceTV(client) || IsClientReplay(client) )
			return false;
	return true;
}

stock int GetBuilder(const int tele)
{
	int owner = GetEntPropEnt(tele, Prop_Send, "m_hBuilder");
	if ( IsValidClient(owner) )
		return owner;
	return -1;
}
