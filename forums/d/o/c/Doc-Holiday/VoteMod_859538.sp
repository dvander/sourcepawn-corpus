#define VOTEMOD_VERSION "1.0"

#define ADMINVOTEMOD	ADMFLAG_VOTE
#define ADMINVOTEMENU	ADMFLAG_CUSTOM1

#include <sourcemod>
#include <cstrike>

#define MAXMENUS		9
#define STRINGSIZE		32
#define STRINGLENGTH	STRINGSIZE - 1

new menuNumber = 0;
new String:menuBody[MAXMENUS][STRINGSIZE];
new minPlayers[MAXMENUS];
new String:menuCmd1[MAXMENUS][STRINGSIZE];
new String:menuCmd2[MAXMENUS][STRINGSIZE];
new String:defaultCfgFile[STRINGSIZE];

new moded = 0;

new loaded = -1;
new Handle:sm_numplayers, Handle:sm_sethostname, Handle:version, Handle:sm_nomod;
new Handle:vote

new String:hostname[75]

public Plugin:myinfo =
{
	name = "Vote Mod",
	author = "Soloist",
	description = "Vote mod starts a vote on the beginning of each map",
	version = VOTEMOD_VERSION,
	url = "http://www.soloistsmodcentral.com"
};

public OnPluginStart()
{
	version = CreateConVar("VoteMod_Version", VOTEMOD_VERSION, "", FCVAR_SPONLY);
	SetConVarString(version, VOTEMOD_VERSION);

	RegAdminCmd("sm_votemod", ShowVote, ADMINVOTEMOD, "- starts a vote for a minimod");
	RegAdminCmd("sm_votemenu", ShowVoteAdmin, ADMINVOTEMENU, "- displays a menu to choose a mod");

	RegConsoleCmd("sm_showmods", ShowMods, " - shows the mods on the server");

	RegServerCmd("sm_addvotemenu", AddVoteMenu, "<menu text> <CVAR/On Command> <Off Command> - Add a menu item to the Vote Mod Plugin");
	RegServerCmd("sm_defaultcfg", DefaultCfg, "<Default cfg - Default CFG file");

	sm_numplayers = CreateConVar("sm_numplayers", "1");
	sm_sethostname = CreateConVar("sm_sethostname", "0");
	sm_nomod = CreateConVar("sm_nomod", "0");
	
	// Add menu items
	AutoExecConfig(true, "votemod", "VoteMod");
}

public OnMapStart()
{	
	if(GetConVarInt(sm_sethostname) == 1)
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		
	menuNumber = 0;
	
	CreateTimer(80.0, LoadHUD, _, TIMER_REPEAT);
	CreateTimer(5.0, SetDefaults);
	CreateTimer(25.0, ShowVoteTimer);
}

public OnMapEnd()
{
	if(GetConVarInt(sm_sethostname) == 1)
		SetConVarString(FindConVar("hostname"), hostname);
	
	moded = 0
}

public OnClientPutInServer(id)
{
	if(GetClientCount(true) == GetConVarInt(sm_numplayers) && loaded == -1 && moded == 0)
		CreateTimer(25.0, ShowVoteTimer);

	#if defined DEBUG
		PrintToServer("[Vote Mod] playerNum: %i", GetClientCount(true));
	#endif
}

public Action:LoadHUD(Handle:timer)
{
	if(loaded == -1)
		return Plugin_Handled;

	new String:hudmessage[76]
	Format(hudmessage, sizeof(hudmessage), "%s is currently running", menuBody[loaded]);
	PrintHintTextToAll(hudmessage);

	return Plugin_Continue;
}

public Action:SetDefaults(Handle:timer)
{
	if(!StrEqual(String:defaultCfgFile, ""))
	{
		ServerCommand("exec VoteMod/%s", defaultCfgFile);
		#if defined DEBUG
			PrintToServer("[Vote Mod] Exec %s", defaultCfgFile);
		#endif
	}

	for(new i = 0; i < menuNumber; i++)
	{
		if(StrEqual(menuCmd2[i], ""))
		{
			if(StrContains(menuCmd1[i], ".cfg") == -1)
			{
				if(FindConVar(menuCmd1[i]) != INVALID_HANDLE)
					SetConVarInt(FindConVar(menuCmd1[i]), 0);

				#if defined DEBUG
					PrintToServer("[Vote Mod] Setting %s", menuCmd1[i]);
				#endif
			}
		}
		else
		{
			ServerCommand(menuCmd2[i]);

			#if defined DEBUG
				PrintToServer("[Vote Mod] Setting %s", menuCmd2[i]);
			#endif
		}
	}
	#if defined DEBUG
		PrintToServer("[Vote Mod] Defaults Set");
	#endif
}

public Action:AddVoteMenu(args)
{
	if(args < 3)
		return Plugin_Handled;

	//AddMenu(const sMenuBody[], const sMinPlayers[], const sMenuCmd1[], const sMenuCmd2[])
	new String:sMenuBody[STRINGSIZE], String:sMinPlayers[STRINGSIZE], String:sMenuCmd1[STRINGSIZE], String:sMenuCmd2[STRINGSIZE];
	GetCmdArg(1, sMenuBody, sizeof(sMenuBody));
	GetCmdArg(2, sMinPlayers, 1);
	GetCmdArg(3, sMenuCmd1, sizeof(sMenuCmd1));
	GetCmdArg(4, sMenuCmd2, sizeof(sMenuCmd2));

	#if defined DEBUG
		PrintToServer("[Vote Mod] Adding to menu: %s", sMenuBody);
	#endif
	AddMenu(sMenuBody, sMinPlayers,  sMenuCmd1, sMenuCmd2);

	return Plugin_Continue;
}

public AddMenu(const String:sMenuBody[], const String:sMinPlayers[], const String:sMenuCmd1[], const String:sMenuCmd2[])
{
	strcopy(menuBody[menuNumber], STRINGLENGTH, sMenuBody);
	minPlayers[menuNumber] = StringToInt(sMinPlayers);
	strcopy(menuCmd1[menuNumber], STRINGLENGTH, sMenuCmd1);
	strcopy(menuCmd2[menuNumber], STRINGLENGTH, sMenuCmd2);

	if(StrEqual(sMenuCmd2, ""))
		PrintToServer("[Vote Mod] Menu item %d added to Vote Mod: \"%s\" - Min Players: %d - CVAR: %s", menuNumber, menuBody[menuNumber], minPlayers[menuNumber], menuCmd1[menuNumber]);
	else
		PrintToServer("[Vote Mod] Menu item %d added to Vote Mod: \"%s\" - Min Players: %d - On: %s - Off: %s", menuNumber, menuBody[menuNumber], minPlayers[menuNumber], menuCmd1[menuNumber], menuCmd2[menuNumber]);
	
	menuNumber++;
}

public Action:DefaultCfg(args)
{
	new String:defaultCfg[STRINGSIZE];
	GetCmdArg(1, defaultCfg, sizeof(defaultCfg));

	strcopy(defaultCfgFile, sizeof(defaultCfgFile), defaultCfg);

	#if defined DEBUG
		PrintToServer("[Vote Mod] Default cfg = %s", defaultCfg);
	#endif
}

public Action:ShowVoteAdmin(id, args)
{
	if(IsVoteInProgress())
		return Plugin_Handled;

	new String:menuitem[64], String:numStr[5];
	new Handle:voteAdmin = CreateMenu(VoteAdmin);
	RemoveAllMenuItems(voteAdmin);
	SetMenuTitle(voteAdmin, "Vote Mod Admin Menu");
	for(new i = 0; i < menuNumber; i++)
	{
		Format(menuitem, sizeof(menuitem), "Change to %s", menuBody[i]);
		IntToString(i, numStr, sizeof(numStr))
		AddMenuItem(voteAdmin, numStr, menuitem);
	}

	SetMenuExitButton(voteAdmin, true);
	DisplayMenu(voteAdmin, id, 15);

	return Plugin_Handled;
}

public VoteAdmin(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:name[24], String:winner[5];

		GetMenuItem(menu, param2, winner, sizeof(winner));
		GetClientName(param1, name, sizeof(name));
		PrintToChatAll("[Vote Mod] %s changed mod to %s", name, menuBody[StringToInt(winner)]);
		PrintToServer("[Vote Mod] %s changed mod to %s", name, menuBody[StringToInt(winner)]);
		SetCvars(StringToInt(winner));
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Action:ShowVoteTimer(Handle:timer)
{
		ShowVote(0, 0)
		moded++
}

public Action:ShowVote(id, args)
{
	if(IsVoteInProgress())
		return Plugin_Handled;

	new String:menuitem[64], String:numStr[5];
	vote = CreateMenu(Vote);
	RemoveAllMenuItems(vote);
	SetMenuTitle(vote, "Vote For Which Mod You Want");

	for(new i = 0; i < menuNumber; i++)
	{
		if(minPlayers[i] <= GetClientCount())
		{
			Format(menuitem, sizeof(menuitem), "%s", menuBody[i]);
			Format(numStr, sizeof(numStr), "%i", i);
			AddMenuItem(vote, numStr, menuitem);
			#if defined DEBUG
				PrintToServer("[Vote Mod] Added \"%s\" to menu", menuBody[i]);
			#endif
		}
	}

	if(GetConVarInt(sm_nomod))
		AddMenuItem(vote, "None", "None");

	SetMenuExitButton(vote, false);
	VoteMenuToAll(vote, 15);

	return Plugin_Handled;
}

public Vote(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32], String:name[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		GetClientName(param1, name, sizeof(name));
		if(StrEqual(info, "None"))
			PrintToChatAll("[Vote Mod] %s voted for no mod", name);
		else
			PrintToChatAll("[Vote Mod] %s voted for %s", name, menuBody[param2]);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_VoteEnd)
	{
		new String:winner[64];
		new winningVotes, totalVotes;
		GetMenuVoteInfo(param2, winningVotes, totalVotes);
		
		#if defined DEBUG
			PrintToServer("[Vote Mod] param1: %i - param2: %i - winningVotes: %i - totalVotes: %i", param1, param2, winningVotes, totalVotes);
		#endif
		
		if(totalVotes < 1)
		{
			PrintToChatAll("[Vote Mod] Nothing Chosen");
			winner[0] = GetRandomInt(0, menuNumber);
		}
		else
		{
			GetMenuItem(menu, param1, winner, sizeof(winner));
			if(StrEqual(winner, "None"))
				PrintToChatAll("[Vote Mod] Winner: No Mod");
			else
			{
				PrintToChatAll("[Vote Mod] Winner: %s", menuBody[StringToInt(winner)]);
				SetCvars(StringToInt(winner));
			}
		}
	}
}

public SetCvars(num)
{
	new Handle:null = INVALID_HANDLE;
	SetDefaults(null);

	new String:sethostname[75];

	if(num != 9)
	{
		if(GetConVarInt(sm_sethostname) == 1)
		{
			Format(sethostname, sizeof(sethostname), "%s *%s*", hostname, menuBody[num]);
			SetConVarString(FindConVar("hostname"), sethostname);
		}

		if(StrEqual(menuCmd2[num], ""))
		{
			if(StrContains(menuCmd1[num], ".cfg") == -1 && FindConVar(menuCmd1[num]) != INVALID_HANDLE)
				SetConVarInt(FindConVar(menuCmd1[num]), 1);
			else
				ServerCommand("exec VoteMod/%s", menuCmd1[num]);
		}
		else
			ServerCommand(menuCmd1[num]);

		SetConVarInt(FindConVar("mp_restartgame"), 1);
		CreateTimer(2.0, PlayerSpawn);

		#if defined DEBUG
		PrintToServer("[Vote Mod] %s Loaded", menuBody[num]);
		#endif
	}
	else if(num == 9)
	{
		if(GetConVarInt(sm_sethostname) == 1)
		{
			Format(sethostname, sizeof(sethostname), "%s *%s*", hostname, "No Mod");
			SetConVarString(FindConVar("hostname"), sethostname);
		}

		#if defined DEBUG
		PrintToServer("[Vote Mod] %s Loaded", "No Mod");
		#endif
	}

	loaded = num;
}

public Action:PlayerSpawn(Handle: timer)
{
	ServerCommand("bot_kill");
}


public Action:ShowMods(id, args)
{
	PrintToConsole(id, "Current Mods On The Server:");

	for(new i = 0; i < menuNumber; i++)
		PrintToConsole(id, "%d. %s - Min Players: %d", (i+1), menuBody[i], minPlayers);

	return Plugin_Handled;
}