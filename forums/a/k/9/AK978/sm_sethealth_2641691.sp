#pragma semicolon 1
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.2.2"

new bbb;

public Plugin:myinfo =
{
	name = "Set Health",
	author = "Mr. Blip",
	description = "Sets a player or teams health to the specified amount.",
	version = PLUGIN_VERSION,
};


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sethealth.phrases");
	CreateConVar("sm_sethealth_version", PLUGIN_VERSION, "SetHealth Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sethealth", Command_SetHealth, ADMFLAG_SLAY, "sm_sethealth <#userid|name> <amount>");
	RegConsoleCmd("sm_sethealth", Command_SetHealth, "sm_sethealth <#userid|name> <amount>");
	RegConsoleCmd("sm_sethealthcheck", Command_SetHealth3, "sm_sethealth <#userid|name> <amount>");
	
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("round_start", RoundStart);
}

public void OnClientPostAdminCheck(client)
{
	CreateTimer(2.0, givehealth, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vip = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsSurvivor(vip) && !IsFakeClient(vip))
	{
		new flags = GetUserFlagBits(vip);
		if (flags & ADMFLAG_UNBAN)
		{
			SetEntityHealth(vip, 250);
		}
		else if (flags & ADMFLAG_CHAT)
		{
			SetEntityHealth(vip, 250);
		}
		else if (flags & ADMFLAG_CUSTOM6)
		{
			SetEntityHealth(vip, 250);
		}
		else if(flags & ADMFLAG_CUSTOM5)
		{
			SetEntityHealth(vip, 200);
		}
		else if(flags & ADMFLAG_CUSTOM4)
		{
			SetEntityHealth(vip, 190);
		}
		else if(flags & ADMFLAG_CUSTOM3)
		{
			SetEntityHealth(vip, 185);
		}
		else if(flags & ADMFLAG_CUSTOM1)
		{
			SetEntityHealth(vip, 170);
		}
		else if (flags & ADMFLAG_RESERVATION)
		{
			SetEntityHealth(vip, 150);
		}
		else if (flags & ADMFLAG_ROOT)
		{
			SetEntityHealth(vip, 110);
		}
	}
}

public Action:givehealth(Handle:timer, any:client)
{		
	if(IsSurvivor(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		new flags = GetUserFlagBits(client);

		if (flags & ADMFLAG_UNBAN)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if (flags & ADMFLAG_CHAT)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if (flags & ADMFLAG_CUSTOM6)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if(flags & ADMFLAG_CUSTOM5)
		{
			givehp(client);
			SetEntityHealth(client, 200);
		}
		else if(flags & ADMFLAG_CUSTOM4)
		{
			givehp(client);
			SetEntityHealth(client, 190);
		}
		else if(flags & ADMFLAG_CUSTOM3)
		{
			givehp(client);
			SetEntityHealth(client, 185);
		}
		else if(flags & ADMFLAG_CUSTOM1)
		{
			givehp(client);
			SetEntityHealth(client, 170);
		}
		else if (flags & ADMFLAG_RESERVATION)
		{
			givehp(client);
			SetEntityHealth(client, 150);
		}
		else if (flags & ADMFLAG_ROOT)
		{
			givehp(client);
			SetEntityHealth(client, 110);
		}
		else
		{
			givehp(client);
		}
	}
	else
	{
		CreateTimer(2.0, givehealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}	
}

public Action:Command_SetHealth3(client, args)
{
	if(IsSurvivor(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		new flags = GetUserFlagBits(client);
		if (flags & ADMFLAG_UNBAN)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if (flags & ADMFLAG_CHAT)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if (flags & ADMFLAG_CUSTOM6)
		{
			givehp(client);
			SetEntityHealth(client, 250);
		}
		else if(flags & ADMFLAG_CUSTOM5)
		{
			givehp(client);
			SetEntityHealth(client, 200);
		}
		else if(flags & ADMFLAG_CUSTOM4)
		{
			givehp(client);
			SetEntityHealth(client, 190);
		}
		else if(flags & ADMFLAG_CUSTOM3)
		{
			givehp(client);
			SetEntityHealth(client, 185);
		}
		else if(flags & ADMFLAG_CUSTOM1)
		{
			givehp(client);
			SetEntityHealth(client, 170);
		}
		else if (flags & ADMFLAG_RESERVATION)
		{
			givehp(client);
			SetEntityHealth(client, 150);
		}
		else if (flags & ADMFLAG_ROOT)
		{
			givehp(client);
			SetEntityHealth(client, 110);
		}
		else
		{
			givehp(client);
			SetEntityHealth(client, 100);
		}
	}
}

givehp(Client)
{
	new userflags = GetUserFlagBits(Client);
	SetUserFlagBits(Client, ADMFLAG_ROOT);
	FakeClientCommand(Client,"give health");
	SetUserFlagBits(Client, userflags);	
}
			
public Action:Command_SetHealth(client, args)
{
	decl String:target[32], String:mod[32], String:health[10];
	new nHealth;
	new maxHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

	GetGameFolderName(mod, sizeof(mod));

	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <#userid|name> <amount>");
		return Plugin_Handled;
	}
	else {
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, health, sizeof(health));
		nHealth = StringToInt(health);
	}

	if (nHealth < 0) {
		ReplyToCommand(client, "[SM] Health must be greater then zero.");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

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
		if (strcmp(mod, "tf") == 0) 
		{
			new class = GetEntProp(target_list[i], Prop_Send, "m_iClass");
			
			if (nHealth == 0)
				FakeClientCommand(target_list[i], "explode");
			else if (nHealth > maxHealth[class]) {
				SetEntProp(target_list[i], Prop_Data, "m_iMaxHealth", nHealth);
				SetEntityHealth(target_list[i], nHealth);
			}
		}

		else 
		{
			if (nHealth == 0)
				SetEntityHealth(target_list[i], 1);
			else
				SetEntityHealth(target_list[i], nHealth);
		}
		LogAction(client, target_list[i], "\"%L\" set \"%L\" health to  %i", client, target_list[i], nHealth);
	}
	return Plugin_Handled;
}

stock bool:IsSurvivor(client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}