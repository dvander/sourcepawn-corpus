#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

public Plugin:myinfo = 
{
	name = "AwesomeWeps",
	author = "Upholder of the [BFG]",
	description = "Gives you awesome weapons.",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};



public OnPluginStart()
{
	RegAdminCmd("sm_awesomeweps", Command_Awesomeweps, ADMFLAG_CHEATS);
}

public Action:Command_Awesomeweps(client, args)
{

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_awesomeweps <#userid|name>");
		return Plugin_Handled;
	}

	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	new len = BreakString(Arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		/* Safely null terminate */
		len = 0;
		Arguments[0] = '\0';
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{		
		for (new i = 0; i < target_count; i++)
		{
			GiveWeps(client, target_list[i]);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	
	return Plugin_Handled;
}

GiveWeps(client, target)
{
	TF2_RemoveAllWeapons(target);
	
	TF2_GivePlayerWeapon(target, "tf_weapon_wrench");
	TF2_GivePlayerWeapon(target, "tf_weapon_smg");
	TF2_GivePlayerWeapon(target, "tf_weapon_rocketlauncher");
	TF2_GivePlayerWeapon(target, "tf_weapon_grenadelauncher");
	TF2_GivePlayerWeapon(target, "tf_weapon_minigun");
	
	ReplyToCommand(client, "You have given awesome weapons.");	
}