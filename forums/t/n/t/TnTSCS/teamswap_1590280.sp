#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.1b"

#define PLUGIN_PREFIX "\x03[ONLYFRIENDS]\x01"

public Plugin:myinfo =  
{ 
	name = "Swap My Team",
	description = "Allows Donators to swap teams",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net/"
};

new bool:SwitchPlayer[MAXPLAYERS+1] = false;

//------------------------------------------------------------------------------------------------------------------------------------
// Teams - thanks xaider
//------------------------------------------------------------------------------------------------------------------------------------
new String:t_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};
//------------------------------------------------------------------------------------------------------------------------------------
new String:ct_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};


public OnPluginStart() 
{ 
	CreateConVar("sm_swapmyteam_version", PLUGIN_VERSION, "Plugin version number", FCVAR_NOTIFY|FCVAR_REPLICATED); 
	
	HookEvent("round_start", OnRoundStart);
	
	RegConsoleCmd("sm_swapteam", cmdSwap); // Changed from sm_teamswap because it conflicts with AdvCommands plugin's sm_teamswap command
	
	RegConsoleCmd("sm_stopteamswap", cmdStopSwap);
}

public OnClientPostAdminCheck(client)
{
	SwitchPlayer[client] = false;
	if (CheckCommandAccess(client, "allow_teamswap", ADMFLAG_CUSTOM6) && !IsFakeClient(client))
		PrintToChat(client, "%s You have access to the \x03sm_swapteam\x01 command.", PLUGIN_PREFIX);
}

public Action:cmdSwap(client, args)
{
	// CheckCommandAccess Info: http://docs.sourcemod.net/api/index.php?fastload=show&id=497&	
	// Either just use CUSTOM6, or enter whatever flag you want in the adminoverride using "allow_teamswap"
	
	if (CheckCommandAccess(client, "allow_teamswap", ADMFLAG_CUSTOM6))
	{
		if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		{
		MessageClient(client, 1);
		return Plugin_Continue;
		}
	
		if(SwitchPlayer[client])
		{
			MessageClient(client, 2);
			return Plugin_Continue;
		}

		SwitchPlayer[client] = true;
		MessageClient(client, 3);

		return Plugin_Continue;
	}
	
	MessageClient(client, 4);
	return Plugin_Continue;
}

public Action:cmdStopSwap(client, args)
{
	if(CheckCommandAccess(client, "allow_teamswap", ADMFLAG_CUSTOM6))
	{
		if(SwitchPlayer[client])
		{
			SwitchPlayer[client] = false;
			MessageClient(client, 6);
			return Plugin_Continue;
		}
		else
		{
			MessageClient(client, 7);
			return Plugin_Continue;
		}
	}
	MessageClient(client, 4);
	return Plugin_Continue;	
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{			
		if(IsClientInGame(i) && SwitchPlayer[i] && !IsFakeClient(i))
		{
			SwitchPlayer[i] = false;
			
			if(GetClientTeam(i) <= CS_TEAM_SPECTATOR)
			{
				MessageClient(i, 5);
				return Plugin_Continue;
			}
			
			SwapTeam(i, GetClientTeam(i));
		}
	}
	return Plugin_Continue;
}

SwapTeam(client, curTeam)// Credit to xaider for his team change code on his Advanced Command plugin which was sampled a bit here
{
	if(curTeam <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client))
		return;
	
	decl String:model[PLATFORM_MAX_PATH],String:newmodel[PLATFORM_MAX_PATH];
	GetClientModel(client,model,sizeof(model));
	newmodel = model;

	if (curTeam == CS_TEAM_T)
	{
		CS_SwitchTeam(client, CS_TEAM_CT);
		new c4 = GetPlayerWeaponSlot(client,CS_SLOT_C4);
		if (c4 != -1) CS_DropWeapon(client, c4, true);

		if (StrContains(model,t_models[0],false)) newmodel = ct_models[0];
		if (StrContains(model,t_models[1],false)) newmodel = ct_models[1];
		if (StrContains(model,t_models[2],false)) newmodel = ct_models[2];
		if (StrContains(model,t_models[3],false)) newmodel = ct_models[3];		
	} else
	if (curTeam == CS_TEAM_CT)
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0, 1);// Set the status of "has defuser" to false

		if (StrContains(model,ct_models[0],false)) newmodel = t_models[0];
		if (StrContains(model,ct_models[1],false)) newmodel = t_models[1];
		if (StrContains(model,ct_models[2],false)) newmodel = t_models[2];
		if (StrContains(model,ct_models[3],false)) newmodel = t_models[3];		
	}
	
	SetEntityModel(client, newmodel);

	if(IsPlayerAlive(client))
		CS_RespawnPlayer(client);

	MessageClient(client, 8);
}

MessageClient(client, msgnum)
{
	switch(msgnum)
	{
		case 1: PrintToChat(client, "%s You must be on a playable team to use the swap command", PLUGIN_PREFIX);
		case 2: PrintToChat(client, "%s You are already set to have your team swapped.  Type !stopteamswap to cancel this request.", PLUGIN_PREFIX);
		case 3: PrintToChat(client, "%s Your team will be switched at the start of the next round!", PLUGIN_PREFIX);
		case 4: PrintToChat(client, "%s Sorry this is for donators only, to donate please go to www.onlyfriends.be/donate", PLUGIN_PREFIX);
		case 5: PrintToChat(client, "%s You are no longer on a playable team.  Team switch request cancelled!", PLUGIN_PREFIX);
		case 6: PrintToChat(client, "%s Your team swap request has been cancelled.", PLUGIN_PREFIX);
		case 7: PrintToChat(client, "%s You are not currently set to have your team swapped, use !swapmyteam to swap teams.", PLUGIN_PREFIX);
		case 8: PrintToChat(client, "%s Your team has been switched!", PLUGIN_PREFIX);
	}
}