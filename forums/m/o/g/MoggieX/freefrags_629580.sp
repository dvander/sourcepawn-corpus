#include <sourcemod>

#pragma semicolon 1

new FragCount[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Free Frags",
	author = "MoggieX",
	description = "Lets admins give out free frags",
	version = "1.0",
	url = "www.sourcemod.net"
}
public OnPluginStart()
{

	LoadTranslations("common.phrases");

	CreateConVar("sm_freefrag_version", "1.0", "Free Frags Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_fragadd", Command_AddFrags, ADMFLAG_CUSTOM1, "sm_fragadd <name or #userid or all/t/ct> <value> - ADD to target's Frag Count.");
	RegAdminCmd("sm_fragset", Command_SetFrags, ADMFLAG_CUSTOM1, "sm_fragset <name or #userid or all/t/ct> <value> - SET a target's Frag Count.");
	RegAdminCmd("sm_deathset", Command_SetDeaths, ADMFLAG_CUSTOM1, "sm_deathset <name or #userid or all/t/ct> <value> - SET a target's Death Count.");
	
}
public Action:Command_AddFrags(client, args)
{

	if (args < 1)
	{
		ReplyToCommand(client, "[Free Frags] Usage: sm_Addfrag <name or #userid or @all/t/ct> <value>");
		return Plugin_Handled;
	}


// Error check to see if the nubcakes haven't put letters in the frag count
	new InFrags = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, InFrags) == 0)
	{
		ReplyToCommand(client, "[Free Frags] %t", "Invalid Amount");
		return Plugin_Handled;
	}

	//PrintToChatAll("\x04[Free Frags]\x03 Invalid amount check PASSED");

// Target player(s)
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
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

//	loop for each target
	for (new i = 0; i < target_count; i++)
	{

	new Score = GetClientFrags(target_list[i]) + InFrags;
				
	SetEntProp(target_list[i], Prop_Data, "m_iFrags", Score);

	//ReplyToCommand(client, "[Free Frags] Added to Target: <%t> Score: <%i>",target_list[i],Score);
	PrintToChat(client,"\x04[Free Frags]\x03 Set Target: <%s> Score: <%i>",target_name,Score);

	}			
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) { new client = GetClientOfUserId(GetEventInt(event, "userid")); FragCount[client] = 0; }
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) FragCount[client] = 0;
public OnClientDisconnect(client) FragCount[client] = 0;

///////////////////////////////////////////////
//			Set Frags
///////////////////////////////////////////////

public Action:Command_SetFrags(client, args)
{

	if (args < 1)
	{
		ReplyToCommand(client, "\x04[Free Frags] Usage:\x03 sm_fragset <name or #userid or all/t/ct> <value> - SET a target's Frag Count.");
		return Plugin_Handled;
	}


// Error check to see if the nubcakes haven't put letters in the frag count
	new InFrags = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, InFrags) == 0)
	{
		ReplyToCommand(client, "[Free Frags] %t", "Invalid Amount");
		return Plugin_Handled;
	}

// Target player(s)
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
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

//	loop for each target
	for (new i = 0; i < target_count; i++)
	{
				
	SetEntProp(target_list[i], Prop_Data, "m_iFrags", InFrags);

	PrintToChat(client,"\x04[Free Frags]\x03 Set Target: <%s> Score: <%i>",target_name,InFrags);

	}			
	return Plugin_Handled;
}


///////////////////////////////////////////////
//			Set Deaths
///////////////////////////////////////////////

public Action:Command_SetDeaths(client, args)
{

	if (args < 1)
	{
		ReplyToCommand(client, "\x04[Free Frags] Usage:\x03 sm_deathset <name or #userid or all/t/ct> <value> - SET a target's death Count.");
		return Plugin_Handled;
	}


// Error check to see if the nubcakes haven't put letters in the frag count
	new InDeaths = 0;
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, InDeaths) == 0)
	{
		ReplyToCommand(client, "[Free Frags] %t", "Invalid Amount");
		return Plugin_Handled;
	}

// Target player(s)
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
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

//	loop for each target
	for (new i = 0; i < target_count; i++)
	{
				
	SetEntProp(target_list[i], Prop_Data, "m_iDeaths", InDeaths);

	PrintToChat(client,"\x04[Free Frags]\x03 Set Target: <%s> Deaths: <%i>",target_name,InDeaths);
	}			
	return Plugin_Handled;
}





