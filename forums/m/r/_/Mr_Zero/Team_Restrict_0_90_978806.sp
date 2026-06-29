#include <sourcemod>

#define PLUGIN_VERSION	"0.90"
#define MAXTEAMS 		4
#define TEAM_AUTO		0
#define TEAM_SPEC		1

new g_iTeamForced[MAXPLAYERS+1];
new bool:g_bTeamRestricted[MAXPLAYERS+1][MAXTEAMS];
new Handle:g_hCommandAccess;
new Handle:g_hMsgForced;
new Handle:g_hMsgRestricted;

public Plugin:myinfo = 
{
	name = "Team Restrict",
	author = "Mr. Zero",
	description = "Restrict players from joining or force a certain team.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=108165"
}

public OnPluginStart()
{
	RegConsoleCmd("jointeam",cmd_Jointeam);
	RegConsoleCmd("spectate",cmd_Spectate);
	RegConsoleCmd("sm_restrictteam",cmd_RestrictTeam);
	RegConsoleCmd("sm_forceteam",cmd_ForceTeam);
	
	g_hCommandAccess 	= CreateConVar("sm_teamrestrict_access","d","Required admin flag to be able to use the restrict commands",FCVAR_PLUGIN);
	g_hMsgForced 		= CreateConVar("sm_teamrestrict_msg_forced","Sorry you have been forced to be on this team.","The message to display when a player tries to change team but is forced to stay on the team",FCVAR_PLUGIN);
	g_hMsgRestricted 	= CreateConVar("sm_teamrestrict_msg_restricted","Sorry you have been restricted from joining that team.","The message to display when a player tries to change team but is restricted from joining that team",FCVAR_PLUGIN);
	CreateConVar("sm_teamrestrict_version",PLUGIN_VERSION,"Team Restrict Version",FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	AutoExecConfig(true,"TeamRestrict");
}

public OnAllPluginsLoaded()
{
	// These commands are first setup after all other plugins is loaded
	// encase other plugins uses these commands
	RegConsoleCmdEx("sm_rt",cmd_RestrictTeam);
	RegConsoleCmdEx("sm_ft",cmd_ForceTeam);
}

public OnClientConnected(client)
{
	for(new i;i<MAXTEAMS;i++)
	{
		g_bTeamRestricted[client][i] = false;
	}
	g_iTeamForced[client] = -1;
}

public Action:cmd_Jointeam(client,args)
{
	decl String:buffer[10]
	GetCmdArg(1,buffer,sizeof(buffer));
	StripQuotes(buffer);
	TrimString(buffer);
	
	// To prevent an exploit, for exampel: jointeam "      3"
	// Player will join team 3 but the StringToInt would return 0, due to buffer being empty
	// So buffer empty, block the command
	if(strlen(buffer) == 0){return Plugin_Handled;}
	
	new team = StringToInt(buffer);
	
	if(g_iTeamForced[client] != -1)
	{
		new curteam = GetClientTeam(client);
		if(team != curteam)
		{
			new String:msg[256];
			GetConVarString(g_hMsgForced,msg,256);
			PrintToChat(client,msg);
			return Plugin_Handled;
		}
	}
	
	if(g_bTeamRestricted[client][team])
	{
		new String:msg[256];
		GetConVarString(g_hMsgRestricted,msg,256);
		PrintToChat(client,msg);
		return Plugin_Handled;
	}
	
	if(team == TEAM_AUTO)
	{
		AutoAssign(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:cmd_Spectate(client,args)
{
	// Redirect the spec command to the jointeam command
	FakeClientCommandEx(client,"jointeam %i",TEAM_SPEC);
	return Plugin_Handled;
}

public Action:cmd_RestrictTeam(client,args)
{
	decl String:accessflag[128]
	GetConVarString(g_hCommandAccess,accessflag,sizeof(accessflag))
	if(GetUserFlagBits(client) - ReadFlagString(accessflag) < 0){ReplyToCommand(client, "[SM] No access");return Plugin_Handled;}
	
	if (args != 2) {ReplyToCommand(client, "[SM] Usage: sm_restrictteam <#userid|name> <team number>");return Plugin_Handled;}
	
	decl String:buffer[128];
	GetCmdArg(2,buffer,sizeof(buffer));
	new team = StringToInt(buffer);
	
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client,buffer);
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	if(g_bTeamRestricted[target][team])
	{
		g_bTeamRestricted[target][team] = false;
		ShowActivity(client, "Player %s is no longer restricted from joining team %i", name,team);
	}
	else
	{
		g_bTeamRestricted[target][team] = true;
		ShowActivity(client, "Player %s have been restricted from joining team %i", name,team);
	}
	
	return Plugin_Handled;
}

public Action:cmd_ForceTeam(client,args)
{
	decl String:accessflag[128]
	GetConVarString(g_hCommandAccess,accessflag,sizeof(accessflag))
	if(GetUserFlagBits(client) - ReadFlagString(accessflag) < 0){ReplyToCommand(client, "[SM] No access");return Plugin_Handled;}
	
	if (args < 1 || args > 2) {ReplyToCommand(client, "[SM] Usage: sm_forceteam <#userid|name> <team number|nothing to disable forced team>");return Plugin_Handled;}
	
	new team = -1;
	decl String:buffer[128];
	if(args == 2)
	{
		GetCmdArg(2,buffer,sizeof(buffer));
		team = StringToInt(buffer);
	}
	
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client,buffer);
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	if(team == -1)
	{
		ShowActivity(client, "Player %s is no longer forced to be on team %i", name,g_iTeamForced[target]);
	}
	else
	{
		ChangeClientTeam(target,team);
		ShowActivity(client, "Player %s have been forced to join team %i", name,team);
	}
	g_iTeamForced[target] = team;
	
	return Plugin_Handled;
}

bool:AutoAssign(client)
{
	for(new team;team<MAXTEAMS;team++)
	{
		if(team == TEAM_AUTO || team == TEAM_SPEC || g_bTeamRestricted[client][team]){continue;}
		
		FakeClientCommandEx(client,"jointeam %i",team);
		return;
	}
}

RegConsoleCmdEx(const String:cmd[],ConCmd:callback,const String:description[]="",flags=0)
{
	new Handle:temp = FindConVar(cmd);
	if(temp == INVALID_HANDLE){RegConsoleCmd(cmd,callback,description,flags);}
}