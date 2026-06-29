#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Vote All Criticals",
	author = "Tylerst",
	description = "Description",
	version = PLUGIN_VERSION,
	url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new bool:g_allcrits = false;

public OnPluginStart()
{	
	RegAdminCmd("sm_votecrits", Command_VoteCrits, ADMFLAG_GENERIC, "Start vote for all criticals");	
	LoadTranslations("common.phrases");
}

public Action:Command_VoteCrits(client, args)
{
	if (IsVoteInProgress()) return;
	new Handle:Critsmenu = CreateMenu(Handle_CritVote);
	SetMenuTitle(Critsmenu, "All Criticals?");
	AddMenuItem(Critsmenu, "yes", "Yes");
	AddMenuItem(Critsmenu, "no", "No");
	SetMenuExitButton(Critsmenu, false);
	VoteMenuToAll(Critsmenu, 20);
}
 
public Handle_CritVote(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_VoteEnd) 
	{
		if (param1 == 0)
		{
			g_allcrits = true;
			PrintToChatAll("\x04[SM] All Criticals Enabled");	
		}
		else 
		{
			g_allcrits = false;
			PrintToChatAll("\x04[SM] All Criticals Disabled");
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(g_allcrits)
	{
		result = true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}