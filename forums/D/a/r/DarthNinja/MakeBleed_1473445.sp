#include <sourcemod>
#include <tf2>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "[TF2] Cut 'Em",
	author = "DarthNinja",
	description = "I'm gonnah cut yah!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_bleed_version",PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	RegAdminCmd("sm_cut", MakeBleed, ADMFLAG_SLAY, "Makes a player bleed. Usage: sm_bleed <target> [duration] [attacker]");
	RegAdminCmd("sm_bleed", MakeBleed, ADMFLAG_SLAY, "Makes a player bleed. Usage: sm_bleed <target> [duration] [attacker]");
	
	LoadTranslations("common.phrases");
}


public Action:MakeBleed(client, args)
{
	if (args < 1 || args > 3)
	{
		ReplyToCommand(client, "Usage: sm_bleed <target> [duration] [attacker]");
		return Plugin_Handled;
	}
	
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
		target,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	
	new Float:f_Duration = 5.0;
	if (args > 1)
	{
		new String:time[32];
		GetCmdArg(2, time, sizeof(time));
		f_Duration = StringToFloat(time);
	}
	
	new iAttacker = -1;
	if (args == 3)
	{
		new String:attacker[32];
		GetCmdArg(3, attacker, sizeof(attacker));
		iAttacker = FindTarget(client, attacker);
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (args < 3)
		{
			iAttacker = target_list[i];
		}
		LogAction(client, target_list[i], "%L made %L bleed for %i seconds, crediting %L for any kills", client, target_list[i], RoundToNearest(f_Duration), iAttacker);
		TF2_MakeBleed(target_list[i], iAttacker, f_Duration);
	}
	ShowActivity2(client, "\x04[SM] ","\x01Made \x05%s\x01 bleed for \x04%i\x01 seconds.", target_name, RoundToNearest(f_Duration));
	
	return Plugin_Handled;
}