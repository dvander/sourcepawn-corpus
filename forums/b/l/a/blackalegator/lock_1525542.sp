#include <sourcemod>
#include <sdktools>
//#include <sdkhooks> //No need
#pragma semicolon 1
// Do not forget to change the plugin version!!!
#define Admin Lock
#define PLUGIN_VERSION "1.2"
new lockedadmin[MAXPLAYERS+1] = 0;
new AdminId:adminid[MAXPLAYERS+1];
new mydebuglog = 0;
new tempcheck[MAXPLAYERS+1] = 0;
public Plugin:myinfo = 
{
    name = "Admin Lock",
    author = "blackalegator",
    description = "Lock them up!",
    version = PLUGIN_VERSION,
    url = ""
}
// Creating commands and a version convar...
public OnPluginStart()
{
	//Convars
	CreateConVar("sm_lock_version", PLUGIN_VERSION, "Admin lock version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Events
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Commands
	RegAdminCmd("sm_adminlock", Command_LOCK, ADMFLAG_SLAY, "sm_adminlock <userid/name>");
	RegAdminCmd("sm_adminunlock", Command_UNLOCK, ADMFLAG_SLAY, "sm_adminunlock <userid/name>");
	RegAdminCmd("sm_admintemp", Command_TEMPADMIN, ADMFLAG_SLAY, "sm_admintemp <userid/name> [flags]");
	RegAdminCmd("sm_locklog", Command_DEBUGLOGSWITCH, ADMFLAG_SLAY, "sm_locklog");

}


public Action:Command_TEMPADMIN(client, args)
{
	if (args<=1||args>2)
	{	
		ReplyToCommand(client, "[SM]Usage: sm_tempadmin <userid/name> [flags (abfjkn)]");
		ReplyToCommand(client, "eg: sm_tempadmin CoolGuy abfjk");
		ReplyToCommand(client, "a-Reserved slot;b-Generick,f-Slay,j-SuperChat,k-Votes,n-Cheats");
		return Plugin_Handled;
	}
	decl String:arg1[32], String:arg2[32], String:Caster[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	DebugLog(client, "Command_TEMPADMIN, args=2");
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED, /* Only allow connected players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToCommand(client, "No players found...");
		return Plugin_Handled;
	}
	GetClientName(client, Caster, sizeof(Caster));
	DebugLog(client, "Found some targets...");
	for (new i = 0; i < target_count; i++)
	{
		MakeTAdmin(Caster, target_list[i], arg2);
		tempcheck[i] = 1;
	}
	return Plugin_Handled;
}

public Action:Command_LOCK(client, args) 
{
	//Locks player's commands
	DebugLog(client, "Action:Command_LOCK");
	decl String:arg1[32];
	new String:tClientName[32]; //for Debug, player's name output
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args == 1)
	{
		DebugLog(client, "If statement, args=1");
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED, /* Only allow connected players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToCommand(client, "No players found...");
			return Plugin_Handled;
		}
		//else plugin continues...
		//This is plugin-specific
		DebugLog(client, "Command_Lock continues after ProcessTargetString");
		decl String:buffer[512];
//		decl AdminId:tadmin;
		for (new i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && lockedadmin[target_list[i]] == 0)
			{
				adminid[i]=GetUserAdmin(target_list[i]);
				if (client!=target_list[i])
				{
					SetUserAdmin(target_list[i], INVALID_ADMIN_ID, true);
					if(tempcheck[i]==0)
						lockedadmin[target_list[i]] = 1;
					GetClientName(target_list[i], tClientName, sizeof(tClientName));
					Format(buffer, sizeof(buffer), "Locking admin commands for %s", tClientName);
					DebugLog(client, buffer);
				}
				else
				{
					DebugLog(client,"Skipping yourself...");
				}
			}
			
			DebugLog(client, "Targeting and locking is finished...");
		}
	
	}
	else
	{
		ReplyToCommand(client, "Usage: sm_lock <player's name>");
	}
	return Plugin_Handled;
}
public Action:Command_UNLOCK(client, args) 
{
	//Locks player's commands
	DebugLog(client, "Action:Command_LOCK");
	decl String:arg1[32];
	new String:tClientName[32]; //for Debug, player's name output
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args == 1)
	{
		DebugLog(client, "If statement, args=1");
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
	
		if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED, /* Only allow connected players */
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			/* This function replies to the admin with a failure message */
			ReplyToCommand(client, "No players found...");
			return Plugin_Handled;
		}
		//else plugin continues...
		//This is plugin-specific
		DebugLog(client, "Command_Lock continues after ProcessTargetString");
		decl String:buffer[512];
		for (new i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && lockedadmin[target_list[i]] == 1)
			{
				SetUserAdmin(target_list[i], adminid[i], true);
				lockedadmin[target_list[i]] = 0;
				GetClientName(target_list[i], tClientName, sizeof(tClientName));
				Format(buffer, sizeof(buffer), "Unlocking admin commands for %s", tClientName);
				DebugLog(client, buffer);
			}
			
			DebugLog(client, "Targeting and unlocking is finished...");
		}
	
	}
	else
	{
		ReplyToCommand(client, "Usage: sm_unlock <player's name>");
	}
	return Plugin_Handled;
}

//Lets just forget about that player, dont bother even revoking hid AdminId from the array
public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerleft = GetEventInt(event, "index");
	lockedadmin[playerleft] = 0;
	tempcheck[playerleft] = 0;
}

MakeTAdmin(String:Caster[], target, String:flags[])
{
	PrintToChat(target, "%s gave you temporal admin powers!", Caster);
	new intFlags;
	
	if(StrContains(flags, "a", false))
		intFlags=intFlags|ADMFLAG_RESERVATION;
		
	if(StrContains(flags, "b", false))
		intFlags=intFlags|ADMFLAG_GENERIC;
		
	if(StrContains(flags, "f", false))
		intFlags=intFlags|ADMFLAG_SLAY;
		
	if(StrContains(flags, "j", false))
		intFlags=intFlags|ADMFLAG_CHAT;
		
	if(StrContains(flags, "k", false))
		intFlags=intFlags|ADMFLAG_VOTE;
		
	if(StrContains(flags, "n", false))
		intFlags=intFlags|ADMFLAG_CHEATS;
	
	SetUserFlagBits(target, intFlags);
	
	return;
}

public Action:Command_DEBUGLOGSWITCH(client, args)
{
	if (args>0)
	{
		ReplyToCommand(client, "There are no arguments for this command!");
	}
	if (mydebuglog==0)
	{
		ReplyToCommand(client, "Debugging log is now on...");
		mydebuglog=1;
	}
	else
	{
		ReplyToCommand(client, "Debugging log is now off...");
		mydebuglog=0;
	}
	return Plugin_Handled;
}
public DebugLog(client, String:outstring[])
{
	if(mydebuglog==0)
	{
		return false;
	}
	
	ReplyToCommand(client, outstring);
	return true;
}
//Checks for valid client, looks pretty
public IsValidClient(client)

{
    if (client == 0 || !IsClientConnected(client) || !IsClientInGame(client))
        return false;
//napalm's intepretation of my monstreous clients check function
    //if (IsFakeClient(client))
        //return false;

    return true;
}  

