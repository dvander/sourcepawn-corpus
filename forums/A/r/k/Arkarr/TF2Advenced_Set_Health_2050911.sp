#include <sourcemod>
#include <tf2attributes>
#include <morecolors>

new String:playerSTR[100];
new String:amountSTR[999];

new Float:health;
new String:plugintag[100] = "{yellow}[Set HP] {default}";

public Plugin:myinfo =  
{  
	name = "Set Health - No OverHeal version",  
	author = "Arkarr",  
	description = "Allow to set HP of player, this version SET and don't GIVE health.",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{		
	RegAdminCmd("sm_hp", Command_SetHP, ADMFLAG_CHEATS, "Allow to set HP");
	
	LoadTranslations("common.phrases");
}

public Action:Command_SetHP(client, args)
{
	if(GetCmdArgs() == 2)
	{		
		GetCmdArg(1, playerSTR, sizeof(playerSTR));
		GetCmdArg(2, amountSTR, sizeof(amountSTR));
		
		new target = FindTarget(client, playerSTR);
		
		if(target > 0 && IsClientInGame(target) && IsPlayerAlive(target))
		{
			health = StringToFloat(amountSTR);
			
			TF2Attrib_SetByName(target, "max health additive bonus", health)
			TF2Attrib_ClearCache(target);
			
			CPrintToChat(client, "%sHealth sucessfull set !", plugintag);
			
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		CPrintToChat(client, "%sUsage : sm_hp [PLAYER] [AMOUNT]", plugintag);
		return Plugin_Continue;
	}
}
