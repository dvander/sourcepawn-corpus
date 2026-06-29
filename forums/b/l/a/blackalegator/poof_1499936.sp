#include <sourcemod>
#include <sdktools>
#include <sdkhooks> //No need
#pragma semicolon 1
// Do not forget to change the plugin version!!!
#define L4D2 Poof
#define PLUGIN_VERSION "1.35"
new poofcheck[MAXPLAYERS+1] = 0;
public Plugin:myinfo = 
{
    name = "[L4D2] Poof",
    author = "blackalegator",
    description = "Just Poof!",
    version = PLUGIN_VERSION,
    url = ""
}
// Creating commands and a version convar...
public OnPluginStart()
{
	CreateConVar("sm_poof_version", PLUGIN_VERSION, "Poof version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_poof", Command_Poof, ADMFLAG_SLAY, "sm_poof");
	RegAdminCmd("poof", Command_Poof, ADMFLAG_SLAY, "poof");

}
//sm_poof and poof point here
public Action:Command_Poof(client, args) 
{
	decl String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args == 1)
	{//This is all about dealing with someone else except yourself...
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
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
			ReplyToCommand(client, "Couldn't find player with that name");
			return Plugin_Handled;
		}
		//else plugin continues...
		//This is plugin-specific
		for (new i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && poofcheck[target_list[i]] == 0)
			{
				SDKHook(target_list[i], SDKHook_SetTransmit, Hook_SetTransmit);
				poofcheck[target_list[i]] = 1;
				//ReplyToCommand(client, "In the poofcheck 0 state");
			}
			else if (IsValidClient(target_list[i]) && poofcheck[target_list[i]] == 1)
			{
				SDKUnhook(target_list[i], SDKHook_SetTransmit, Hook_SetTransmit);
				poofcheck[target_list[i]] = 0;
				//ReplyToCommand(client, "In the poofcheck 1 state");
			}
			
		}
		//If at least 1 client is targeted this 2 lines execute
		ReplyToCommand(client, "Target(s) invisibility state changed...");
		return Plugin_Handled;
	}
	if (args >= 2)
	//Only if admin has some problems whith reading a documentation
	{
		ReplyToCommand(client, "Command usage:");
		ReplyToCommand(client, "sm_poof or poof for making urself invisible,");
		ReplyToCommand(client, "sm_poof <username/userid> and poof <username/userid> for making someone else");
		return Plugin_Handled;
	}
	if (args == 0 && IsValidClient(client) && poofcheck[client] == 0)
	//Thats only when you want to do it for yourself, dont wanna change that, its a good example
	{
		poofcheck[client] = 1;
		PrintHintText(client, "You are now invisible!!!");
		
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Handled;
	}
	else if (args == 0 && IsValidClient(client) && poofcheck[client] == 1)
	{
		poofcheck[client] = 0;
		PrintHintText(client, "You are no longer invisible");
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
 //Wow! Thank you Silvers!
 //I dunno how this is hooked. Dont think ill touch any of the sdkhooks sourcecode in a few close months
public Action:Hook_SetTransmit(client, entity)
{
	if( client == entity )
		return Plugin_Continue;
	return Plugin_Handled;
}
//Checks for valid client, looks pretty
public IsValidClient(client)
{
    if (client == 0 || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
        return false;
    //if (IsFakeClient(client))
        //return false;

    return true;
}  