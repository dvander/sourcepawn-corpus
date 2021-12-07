//TargetCrits: By Spazman0 and Arg!



#include <sourcemod>
#include <tf2>
#include <sdktools>
#define PLUGIN_VERSION "0.1"


/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Float:g_Crits[MAXPLAYERS+1] = {-1.00, ...};



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public Plugin:myinfo = 
{
	name = "Targeted Crits chance",
	author = "Spazman0",
	description = "Change a single player's chance to crit",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_targetcrits_version", PLUGIN_VERSION, "Change a single player's critical chance.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_crits", Command_Crits, ADMFLAG_SLAY, "sm_crits <#userid|name> <0.00-1.00> - Sets a players crit chance to the specified amount. Set to 0 to make the chances normal.");
	
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_Crits[client] = -1.00;
	
	return true;
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:Command_Crits(client,args)
{

	decl String:target[65];
	decl String:chancePct[32];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	new Float:chance = 1.00;
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_crits <#userid|name> <0.00 - 1.00> - Set to 0 for normal chance.");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	
	GetCmdArg(2, chancePct, sizeof(chancePct));
	if (StringToFloatEx(chancePct, chance) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Amount");
		return Plugin_Handled;
	}
	
	if (chance < 0)
	{
		chance = 0.00;
	}
		
		
	
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
	
	for (new i = 0; i < target_count; i++)
	{
		DoCrits(client, target_list[i], chance);
	}	

	ShowActivity2(client, "[SM] ", "Toggled crits chance on target '%s'", target_name);
	
	return Plugin_Handled; 
}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

DoCrits(client, target, Float:chance)
{
	if (chance > 0)
	{
		g_Crits[target] = chance;
		LogAction(client, target, "\"%L\" set \"%L\"'s crit chance to %f", client, target, chance);
	}
	else if (chance <= 0)
	{
		g_Crits[target] = -1.00;
		LogAction(client, target, "\"%L\" returned \"%L\"'s crit chance to normal", client, target);
	}
	
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (g_Crits[client] == -1.00)
	{
		return Plugin_Continue;
	}
	else
	{		
		if (g_Crits[client] > GetRandomFloat(0.0, 1.00))
		{
			result = true;
			return Plugin_Handled;	
		}
	}
	
	result = false;
	
	return Plugin_Handled;
}

