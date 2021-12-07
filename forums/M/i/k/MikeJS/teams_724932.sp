#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"
#pragma semicolon 1
new Handle:g_TimeLimit = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "Team Switcher",
	author = "Mike",
	description = "Lets you swap a player's team.",
	version = PLUGIN_VERSION,
	url = "http://www.fragtastic.org.uk/"
};
public OnPluginStart() {
	LoadTranslations("common.phrases");
	g_TimeLimit = FindConVar("mp_timelimit");
	CreateConVar("sm_teams_version", PLUGIN_VERSION, "Team Switcher version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_KICK, "Respawn a player.");
	RegAdminCmd("sm_scramble", Command_ScrambleTeams, ADMFLAG_GENERIC, "Scramble the teams without breaking the timelimit.");
	RegAdminCmd("sm_ts", Command_TeamSwitch, ADMFLAG_GENERIC, "Move player to other team. (sm_ts <#userid|name> [team index])");
}
public Action:Command_Respawn(client, args) {
	decl String:argstr[64];
	GetCmdArgString(argstr, sizeof(argstr));
	new targ = FindTarget(0, argstr, false, false);
	if(targ!=-1) {
		PrintToChatAll("[SM] %N forced %N to respawn.", client, targ);
		TF2_RespawnPlayer(targ);
	}
	return Plugin_Handled;
}
public Action:Command_ScrambleTeams(client, args) {
	decl timeleft;
	GetMapTimeLeft(timeleft);
	ServerCommand("mp_scrambleteams");
	SetConVarInt(g_TimeLimit, (timeleft/60)+1);
	PrintToChatAll("[SM] %N is scrambling the teams.", client);
	return Plugin_Handled;
}
public Action:Command_TeamSwitch(client, args) {
	if(args<1||args>2) {
		ReplyToCommand(client, "[SM] Usage: sm_ts <#userid|name> [team index]");
		return Plugin_Handled;
	}
	decl String:name[256], String:index[4];
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, index, sizeof(index));
	new intindex = StringToInt(index);
	new targ = FindTarget(0, name, false, false);
	if(targ>-1 && IsClientInGame(targ)) {
		if(args==1) {
			if(GetClientTeam(targ)==1) {
				ReplyToCommand(client, "[SM] Cannot swap client's team as they are spectating.");
				return Plugin_Handled;
			} else {
				PrintToChatAll("[SM] %N was moved to the other team by %N.", targ, client);
				ChangeClientTeam(targ, GetClientTeam(targ)==2?3:2);
				return Plugin_Handled;
			}
		} else {
			if(intindex<1||intindex>3) {
				ReplyToCommand(client, "[SM] Invalid team index.");
				return Plugin_Handled;
			} else {
				ChangeClientTeam(targ, intindex);
				if(intindex==1) {
					PrintToChatAll("[SM] %N was made a spectator by %N.", targ, client);
				} else if(intindex==2) {
					PrintToChatAll("[SM] %N was moved to the red team by %N.", targ, client);
				} else {
					PrintToChatAll("[SM] %N was moved to the blue team by %N.", targ, client);
				}
			}
		}
	}
	return Plugin_Handled;
}