#include <sourcemod>
#include <sdkhooks>
#include <morecolors>

new bool:BlockAllDamage[MAXPLAYERS+1] = false; //Just to be sure...

public Plugin:myinfo = 
{
	name = "Total Damage Blocker",
	author = "Arkarr",
	description = "Block all damage for a player, by ALL dammage I mean, he can't get damage AND he can't deal damage.",
	version = "-0.123456789",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	RegAdminCmd("sm_tdb", CMD_ManageDamage, ADMFLAG_GENERIC, "Block all damages");
	
	for(new i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    BlockAllDamage[client] = false;
}

public Action:CMD_ManageDamage(client, args)
{
	if(args == 0)
	{
		if(BlockAllDamage[client])
			BlockAllDamage[client] = false;
		else
			BlockAllDamage[client] = true;
		CPrintToChat(client, "{lightgreen}[TDG]{default} Done !");
	}
	else if(args > 1)
	{
		CPrintToChat(client, "{lightgreen}[TDB]{default} Usage : sm_tdg {green}OR{default} sm_tdg sm_tdg [TARGET]");
	}
	else
	{
		decl String:target_name[MAX_TARGET_LENGTH], String:target[100];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		GetCmdArg(1, target, sizeof(target));

		if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for (new i = 0; i < target_count; i++)
		{
			if(BlockAllDamage[target_list[i]])
				BlockAllDamage[target_list[i]] = false;
			else
				BlockAllDamage[target_list[i]] = true;
		}
		
		CPrintToChat(client, "{lightgreen}[TDG]{default} Done !");
	}
	
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{
	if(BlockAllDamage[victim] || BlockAllDamage[attacker])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}