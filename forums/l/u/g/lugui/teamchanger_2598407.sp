#include <sourcemod>
#include <sdktools>

#include <tf2_stocks>
#include <string>
 
public Plugin myinfo =
{
	name = "Team changer",
	author = "lugui",
	description = "change player team",
	version = "1.0",
	url = ""
}
 
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_move", Command_Team, ADMFLAG_ROOT);
 }
 
public Action Command_Team(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_move  <#userid|name> <red|blue|spec>");
		return Plugin_Handled;
	}
	else{
		char arg1[32], arg2[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		TFTeam team ;
		
		if(StrEqual(arg2, "red", false))
			team = TFTeam_Red;
		else{
			if(StrEqual(arg2, "blue", false) || StrEqual(arg2, "blu", false))
				team = TFTeam_Blue;
			else{
				if(StrEqual(arg2, "spec", false))
					team = TFTeam_Spectator;
				else{
					ReplyToCommand(client, "Invalid team.");
					return Plugin_Handled;
				}
			}
		}
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++)
		{
			if(!IsClientSourceTV(target_list[i]))
				TF2_ChangeClientTeam(target_list[i],team);
		}
	}
	return Plugin_Handled;
}