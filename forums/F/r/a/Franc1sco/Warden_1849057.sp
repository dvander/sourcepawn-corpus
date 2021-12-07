#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <colors>

#define Commander_VERSION   "1.6.1"

new Warden = 0;

public OnPluginStart() 
{
	RegAdminCmd("sm_rc", command_removewarden, ADMFLAG_GENERIC);
	RegConsoleCmd("sm_w", CommandBeWarden);
	RegConsoleCmd("sm_warden", CommandBeWarden);
	RegConsoleCmd("sm_uw", CommandLeaveWarden);
	RegConsoleCmd("sm_unwarden", CommandLeaveWarden);
	HookEvent("round_start", roundStart);
	HookEvent("player_death", playerDeath);
	AddCommandListener(HookPlayerChat, "say");
	
	CreateConVar("sm_warden_version", Commander_VERSION,  "The version of the SourceMod plugin JailBreak Warden, by ecca", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
}

public Plugin:myinfo = {
	name = "JailBreak Warden",
	author = "ecca",
	description = "Jailbreak Warden script",
	version = Commander_VERSION,
	url = "ecca@hotmail.se"
};

public Action:CommandBeWarden(client, args) 
{
	if(Warden == 0)
	{
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				CPrintToChatAll("{lightgreen}[Warden] {default}%N is now warden", client);
				CPrintToChatAll("{lightgreen}[Warden] {default}%N is now warden", client);
				Warden = client;
				SetEntityRenderColor(client, 0, 0, 255, 255);
				SetClientListeningFlags(client, VOICE_NORMAL);
			}
			else
			{
				CPrintToChat(client, "{lightgreen}[Warden] {default}You must be alive to become warden");
			}
		}
		else
		{
			CPrintToChat(client, "{lightgreen}[Warden] {default}Prisoners can't be warden");
		}
	}
	else
	{
		CPrintToChat(client, "{lightgreen}[Warden] {default}%N is already the warden", Warden);
	}
}

public Action:CommandLeaveWarden(client, args) 
{
	if(client == Warden) 
	{
		CPrintToChatAll("{lightgreen}[Warden] {default}%s has decided to retire from the warden position. You can now choose a new one.", client);
		Warden = 0;
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	else
	{
		CPrintToChat(client, "{lightgreen}[Warden] {default}You're not the warden and can't retire.");
	}
}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	Warden = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
}

public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == Warden) 
	{
		CPrintToChatAll("{lightgreen}[Warden] {default}Warden is dead. You can now choose a new one.", Warden);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		Warden = 0;
	}
}

public OnClientDisconnect(client)
{
	if(client == Warden) 
	{
		CPrintToChatAll("{lightgreen}[Warden] {default}Warden disconnected. You can now choose a new one.", Warden);
		Warden = 0;
	}
}

public Action:command_removewarden(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Warden] Usage: sm_rw <player>");
		return Plugin_Handled;
	}
	
		
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if( target > 0 && target <= MaxClients )
	{
		CPrintToChatAll("{lightgreen}[Warden] {default}Warden has been removed by an administrator. You can now choose a new one.");
		Warden = 0;
	}
	return Plugin_Handled;
}

public Action:HookPlayerChat(client, const String:command[], args)
{
	if(Warden == client && client != 0) 
	{
		decl String:szText[256];
		GetCmdArg(1, szText, sizeof(szText));
		
		if(szText[0] == '/')
		{
			return Plugin_Handled;
		}
		
		if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT) 
		{
			CPrintToChatAll("{lightgreen}[Warden] {green}%N:{default} %s",client, szText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}