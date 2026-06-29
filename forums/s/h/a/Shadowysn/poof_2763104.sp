#define PLUGIN_NAME "[ANY] Poof"
#define PLUGIN_AUTHOR "blackalegator, Shadowysn (new syntax)"
#define PLUGIN_DESC "Make you or other players invisible by disabling transmitting to other players."
#define PLUGIN_VERSION "1.36"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2763104#post2763104"
#define PLUGIN_NAME_SHORT "Poof"
#define PLUGIN_NAME_TECH "poof"

#include <sourcemod>
//#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

int poofcheck[MAXPLAYERS+1] = {0};

// Creating commands and a version convar...
public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	RegAdminCmd("sm_poof", Command_Poof, ADMFLAG_SLAY, "sm_poof");
	RegAdminCmd("poof", Command_Poof, ADMFLAG_SLAY, "poof");
}

//sm_poof and poof point here
Action Command_Poof(int client, int args) 
{
	if (args > 1) //Only if admin has some problems with reading a documentation
	{
		ReplyToCommand(client, "\x05[POOF]\x01 Command usage:");
		ReplyToCommand(client, "\x04sm_poof or poof to target yourself for invisibility,");
		ReplyToCommand(client, "\x04sm_poof <username/userid> and poof <username/userid> to target someone else");
		return Plugin_Handled;
	}
	
	static char arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args == 1)
	{
		//This is all about dealing with someone else except yourself...
		static char target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		//Look at http://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins#Implementation for multitargeting
		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE, /* Only allow alive players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			//Only if target_count <= 0, which means no clients were found...
			/* This function replies to the admin with a failure message (well, thats obvious) */
			ReplyToCommand(client, "\x05[POOF]\x01 Couldn't find any target with that name.");
			return Plugin_Handled;
		}
		//else plugin continues...
		//This is plugin-specific
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && poofcheck[target_list[i]] == 0)
			{
				SDKHook(target_list[i], SDKHook_SetTransmit, Hook_SetTransmit);
				poofcheck[target_list[i]] = 1;
				ReplyToCommand(client, "\x05[POOF]\x01 %N is now invisible.", target_list[i]);
			}
			else if (IsValidClient(target_list[i]) && poofcheck[target_list[i]] == 1)
			{
				SDKUnhook(target_list[i], SDKHook_SetTransmit, Hook_SetTransmit);
				poofcheck[target_list[i]] = 0;
				ReplyToCommand(client, "\x05[POOF]\x01 %N is no longer invisible.", target_list[i]);
			}
		}
		//If at least 1 client is targeted this 2 lines execute
		return Plugin_Handled;
	}
	if (args == 0 && IsValidClient(client) && poofcheck[client] == 0)
	//Thats only when you want to do it for yourself, dont wanna change that, its a good example
	{
		poofcheck[client] = 1;
		PrintHintText(client, "You are now invisible.");
		
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Handled;
	}
	else if (args == 0 && IsValidClient(client) && poofcheck[client] == 1)
	{
		poofcheck[client] = 0;
		PrintHintText(client, "You are no longer invisible.");
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
 //Wow! Thank you Silvers!
 //I dunno how this is hooked. Dont think ill touch any of the sdkhooks sourcecode in a few close months
Action Hook_SetTransmit(int client, int entity)
{
	if ( client == entity )
		return Plugin_Continue;
	return Plugin_Handled;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}