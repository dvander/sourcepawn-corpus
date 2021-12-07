#pragma semicolon 1
#include <sourcemod>
new Handle:hGlow = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "L4D Expert Realism Mode",
	author = "JNC",
	description = "ayyy lmao",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	// Trick
	hGlow = CreateConVar("sv_glowenable", "1", "Bye Glows", FCVAR_REPLICATED,true,0.0,true,1.0);
	
	// Optional
	RegAdminCmd( "sm_glowoff", Command_GlowOff, ADMFLAG_BAN, "Hide one client glow");
	RegAdminCmd( "sm_glowon", Command_GlowOn, ADMFLAG_BAN, "Show one client glow");

	HookConVarChange(hGlow, ConVarChange_GlowCvar);
}


// Player Id Hold 0 = You need to be really close to check his nickname
// Difficulty Impossible = You can't see the lifebar  
public OnMapStart()
{
	// This is just for nicknames
	SetConVarFloat(FindConVar("mp_playerid_hold"), 0.0, false,false);	// only supported on coop
	SetConVarString(FindConVar("z_difficulty"), "Impossible");	// only supported on coop
	
	SetConVarInt(hGlow, 0);			// you can change it in realtime, or just hide the glows in some clients using SetGlowClient
}



// -- Glow Stuff


// Nothing important, just avoiding 'warning' message on compile
public ConVarChange_GlowCvar(Handle:cvar, const String:oldValue[], const String:newValue[])   
{
	new value = StringToInt(newValue);
	if (value != 0)
		PrintToServer("[SM] Glow has been server enabled.");
	else
		PrintToServer("[SM] Glow has been server disabled.");
}

// :)))
public Action:Command_GlowOff(client, args)
{
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: !glowoff <name/#userid>");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new victim = target_list[i];
		if (!IsFakeClient(victim))
			SetGlowClient(victim, false);
	}
	
	return Plugin_Handled;
}

public Action:Command_GlowOn(client, args)
{
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: !glowon <name/#userid>");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new victim = target_list[i];
		if (!IsFakeClient(victim))
			SetGlowClient(victim, true);
	}
	
	return Plugin_Handled;
}

// Manual Trick, no matter if you server is on sv_glowenable 1 or 0, the client will have a different value, but you already know that
SetGlowClient(client, bool:enable)
{
	if (enable)
		SendConVarValue(client, FindConVar("sv_glowenable"), "1");
	else
		SendConVarValue(client, FindConVar("sv_glowenable"), "0");
}