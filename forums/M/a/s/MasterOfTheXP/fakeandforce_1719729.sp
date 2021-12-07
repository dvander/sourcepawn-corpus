#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2.1"

public Plugin:myinfo =
{
	name = "Fake and Force",
	author = "MasterOfTheXP",
	description = "Lets you give fake TF2 items and force people to say stuff or use commands. Type /faf to learn more!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
}

new Handle:cvarLogging;
new bool:Logging = true;

new String:itemString[128];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_faf", Command_fakeandforce, ADMFLAG_CHAT, "sm_faf - Lists all Fake and Force commands.");
	RegAdminCmd("sm_fakeach", Command_fakeach, ADMFLAG_CHAT, "sm_fakeach <target> <achievement> - Fake getting an achievement, even fake ones.");
	RegAdminCmd("sm_fakeact", Command_fakeactivity, ADMFLAG_CHAT, "sm_fakeactivity <admin> <action> [target] - Fakes admin activity.");
	RegAdminCmd("sm_fakeactivity", Command_fakeactivity, ADMFLAG_CHAT, "sm_fakeactivity <admin> <action> [target] - Fakes admin activity.");
	RegAdminCmd("sm_fakeaddtime", Command_faketime, ADMFLAG_CHAT, "sm_faketime <seconds> - Fakes adding seconds to the round timer.");
	RegAdminCmd("sm_fakeandforce", Command_fakeandforce, ADMFLAG_CHAT, "sm_fakeandforce - Lists all Fake and Force commands.");
	RegAdminCmd("sm_fakeblock", Command_fakeblock, ADMFLAG_CHAT, "sm_fakeblock <target> [control point name] - Fakes the defense of a Control Point.");
	RegAdminCmd("sm_fakebuy", Command_fakebuy, ADMFLAG_CHAT, "sm_fakebuy <target> <item> - Fake someone buying something from the Mann. Co Store.");
	RegAdminCmd("sm_fakeconnect", Command_fakejoin, ADMFLAG_CHAT, "sm_fakejoin <username> [IP] [Steam ID, commas instead of colons] - Fakes a client connect. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakecraft", Command_fakecraft, ADMFLAG_CHAT, "sm_fakecraft <target> <item> - Fake someone crafting something.");
	RegAdminCmd("sm_fakedamage", Command_fakedamage, ADMFLAG_CHAT, "sm_fakedmg <victim> [amount] [attacker] - Fakes damage being dealt.");
	RegAdminCmd("sm_fakedmg", Command_fakedamage, ADMFLAG_CHAT, "sm_fakedmg <victim> [amount] [attacker] - Fakes damage being dealt.");
	RegAdminCmd("sm_fakedeath", Command_fakedeath, ADMFLAG_CHAT, "sm_fakedeath <victim> [killer] [assister] [weapon] - Fakes a death. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakedefend", Command_fakeblock, ADMFLAG_CHAT, "sm_fakeblock <target> [control point name] - Fakes the defense of a Control Point.");
	RegAdminCmd("sm_fakedisconnect", Command_fakequit, ADMFLAG_CHAT, "sm_fakequit <target> [reason] - Fake someone leaving the server.");
	RegAdminCmd("sm_fakeearn", Command_fakeearn, ADMFLAG_CHAT, "sm_fakeearn <target> <item> - Fake someone earning something from winning duels.");
	RegAdminCmd("sm_fakeeyeboss", Command_fakemono, ADMFLAG_CHAT, "sm_fakemono [defeat?] - Fakes a MONOCULUS! spawn.");
	RegAdminCmd("sm_fakefind", Command_fakefind, ADMFLAG_CHAT, "sm_fakefind <target> <item> - Fake someone finding something from an item drop.");
	RegAdminCmd("sm_fakefish", Command_fakefish, ADMFLAG_CHAT, "sm_fakefish <victim> [attacker] [assister] [weapon] - Fakes a Holy Mackerel/Unarmed Combat hit-notice. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakeheal", Command_fakeheal, ADMFLAG_CHAT, "sm_fakeheal <target> [amount] - Fakes a Crusader's Crossbow heal.");
	RegAdminCmd("sm_fakehhh", Command_fakehhh, ADMFLAG_CHAT, "sm_fakehhh [defeat?] - Fakes a Horsemann spawn.");
	RegAdminCmd("sm_fakehit", Command_fakefish, ADMFLAG_CHAT, "sm_fakefish <victim> [attacker] [assister] [weapon] - Fakes a Holy Mackerel/Unarmed Combat hit-notice. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakehorsemann", Command_fakehhh, ADMFLAG_CHAT, "sm_fakehhh [defeat?] - Fakes a Horsemann spawn.");
	RegAdminCmd("sm_fakejoin", Command_fakejoin, ADMFLAG_CHAT, "sm_fakejoin <username> [IP] [Steam ID, commas instead of colons] - Fakes a client connect. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakekill", Command_fakedeath, ADMFLAG_CHAT, "sm_fakedeath <victim> [killer] [assister] [weapon] - Fakes a death. Specify _ to skip arguments.");
	RegAdminCmd("sm_fakeleave", Command_fakequit, ADMFLAG_CHAT, "sm_fakequit <target> [reason] - Fake someone leaving the server.");
	RegAdminCmd("sm_fakemono", Command_fakemono, ADMFLAG_CHAT, "sm_fakemono [defeat?] - Fakes a MONOCULUS! spawn.");
	RegAdminCmd("sm_fakemonoculus", Command_fakemono, ADMFLAG_CHAT, "sm_fakemono [defeat?] - Fakes a MONOCULUS! spawn.");
	RegAdminCmd("sm_fakepart", Command_fakequit, ADMFLAG_CHAT, "sm_fakequit <target> [reason] - Fake someone leaving the server.");
	RegAdminCmd("sm_fakequit", Command_fakequit, ADMFLAG_CHAT, "sm_fakequit <target> [reason] - Fake someone leaving the server.");
	RegAdminCmd("sm_fakereceive", Command_fakereceive, ADMFLAG_CHAT, "sm_fakereceive <target> <item> - Fake someone receiving a gift.");
	RegAdminCmd("sm_faketime", Command_faketime, ADMFLAG_CHAT, "sm_faketime <seconds> - Fakes adding seconds to the round timer.");
	RegAdminCmd("sm_faketrade", Command_faketrade, ADMFLAG_CHAT, "sm_faketrade <target> <item> - Fake someone finishing a trade and receiving an item.");
	RegAdminCmd("sm_fakeunbox", Command_fakeunbox, ADMFLAG_CHAT, "sm_fakeunbox <target> <item> - Fake someone uncrating something.");
	RegAdminCmd("sm_forcecmd", Command_forcecmd, ADMFLAG_KICK, "sm_forcecmd <target> <command> - Force someone to execute a command. Game-changing commands like 'quit' or 'bind' do not work.");
	RegAdminCmd("sm_forcecmd2", Command_forcecmd2, ADMFLAG_KICK, "sm_forcecmd2 <target> <command> - Force someone to execute a command. Game-changing commands like 'quit' or 'bind' do not work.");
	RegAdminCmd("sm_forcesay", Command_forcesay, ADMFLAG_KICK, "sm_forcesay <target> <text> - Force someone to say something.");
	RegAdminCmd("sm_forcesay_team", Command_forcesayteam, ADMFLAG_KICK, "sm_forcesay_team <target> <text> - Force someone to say something to their team.");
	RegAdminCmd("sm_forcesayteam", Command_forcesayteam, ADMFLAG_KICK, "sm_forcesayteam <target> <text> - Force someone to say something to their team.");
	RegAdminCmd("sm_forcetaunt", Command_forcetaunt, ADMFLAG_KICK, "sm_forcetaunt <target> - Forces someone to taunt.");
	RegAdminCmd("sm_forcevoice", Command_forcevoice, ADMFLAG_KICK, "sm_forcevoice <target> <voice command id or name> - Force someone to use a voice command.");
	RegAdminCmd("sm_forcevoicecmd", Command_forcevoice, ADMFLAG_KICK, "sm_forcevoice <target> <voice command id or name> - Force someone to use a voice command.");
	RegAdminCmd("sm_forcevoicemenu", Command_forcevoice, ADMFLAG_KICK, "sm_forcevoice <target> <voice command id or name> - Force someone to use a voice command.");
	
	cvarLogging = CreateConVar("sm_faf_logging","1","If on, Fake and Force will print messages about its use to server console.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvarLogging, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarLogging) Logging = bool:StringToInt(newValue);
}

stock GenerateItemString(any:client, String:method[], String:item[], String:fakeUser[])
{
	if (StrEqual(fakeUser, "", false))
	{
		if (GetClientTeam(client) == 1) Format(itemString, 128, "\x07CCCCCC%N", client);
		if (GetClientTeam(client) == 2) Format(itemString, 128, "\x07FF4040%N", client);
		if (GetClientTeam(client) == 3) Format(itemString, 128, "\x0799CCFF%N", client);
	}
	else
	{
		new team = GetRandomInt(2,3);
		if (client != 0) team = GetClientTeam(client);
		if (team == 1) Format(itemString, 128, "\x07CCCCCC%s", fakeUser);
		else if (team == 2) Format(itemString, 128, "\x07FF4040%s", fakeUser);
		else if (team == 3) Format(itemString, 128, "\x0799CCFF%s", fakeUser);
	}
	Format(itemString, 128, "%s \x01%s\x03", itemString, method);
	if (StrEqual(method, "has earned the achievement")) Format(itemString, 128, "%s \x05%s\x01", itemString, item);
	
	else if (StrContains(item, "Vintage Tyrolean", false) == 0 || /* exclusion list */
			StrContains(item, "Vintage Merryweather", false) == 0 || 
			StrContains(item, "Strange Part", false) == 0)
	Format(itemString, 128, "%s \x07FFD700%s\x01", itemString, item);
	
	else if (StrContains(item, "Vintage", false) == 0) Format(itemString, 128, "%s \x07576291%s\x01", itemString, item);
	else if (StrContains(item, "Strange", false) == 0) Format(itemString, 128, "%s \x07CF6A32%s\x01", itemString, item);
	else if (StrContains(item, "Genuine", false) == 0) Format(itemString, 128, "%s \x074D7455%s\x01", itemString, item);
	else if (StrContains(item, "Unusual", false) == 0) Format(itemString, 128, "%s \x078650AC%s\x01", itemString, item);
	else if (StrContains(item, "Haunted", false) == 0) Format(itemString, 128, "%s \x078650AC%s\x01", itemString, item);
	else if (StrContains(item, "Valve", false) == 0) Format(itemString, 128, "%s \x07A50F79%s\x01", itemString, item);
	else if (StrContains(item, "Community", false) == 0) Format(itemString, 128, "%s \x0770B04A%s\x01", itemString, item);
	else if (StrContains(item, "Self-Made", false) == 0) Format(itemString, 128, "%s \x0770B04A%s\x01", itemString, item);
	else Format(itemString, 128, "%s \x07FFD700%s\x01", itemString, item);
	PrintToChatAll("%s", itemString);
}

public Action:Command_fakeandforce(client, args)
{
	ReplyToCommand(client, "[SM] Fake and Force %s by MasterOfTheXP", PLUGIN_VERSION);
	ReplyToCommand(client, "[SM] You can type most of these by themselves to find out more about them:");
	ReplyToCommand(client, "[SM] /fake...ach, buy, craft, receive, find, quit, trade, unbox, earn, death, heal, hhh, mono, fish, join, block, time, activity");
	ReplyToCommand(client, "[SM] /force...cmd, cmd2, say, say_team, taunt, voice");
	return Plugin_Handled;
}

public Action:Command_fakedeath(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakedeath <victim> [killer] [assister] [weapon] - Fakes a death. Specify _ to skip arguments.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	new String:arg3[64];
	new String:arg4[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new killer = -1;
		new assister = -1;
		if (!StrEqual(arg2,"") && !StrEqual(arg2,"_")) killer = FindTarget(client, arg2, false, false);
		if (!StrEqual(arg3,"") && !StrEqual(arg3,"_")) assister = FindTarget(client, arg3, false, false);
		new Handle:event = CreateEvent("player_death");
		SetEventInt(event, "userid", GetClientUserId(target_list[i]));
		if (killer != -1) SetEventInt(event, "attacker", GetClientUserId(killer));
		if (assister != -1) SetEventInt(event, "assister", GetClientUserId(assister));
		if (!StrEqual(arg4,"") && !StrEqual(arg4,"_")) SetEventString(event, "weapon", arg4);
		if (!StrEqual(arg4,"") && !StrEqual(arg4,"_")) SetEventString(event, "weapon_logclassname", arg4);
		FireEvent(event);
	}

	if (Logging) LogAction(client, -1, "%N used Fake Death on %s", client, target_name);
	return Plugin_Handled;
}

public Action:Command_fakeheal(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeheal <target> [amount] - Fakes a Crusader's Crossbow heal.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new amount = -1;
	if (!StrEqual(arg2,"")) amount = StringToInt(arg2);

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (amount == -1) amount = GetRandomInt(1,300);
	if (amount > 32767)
	{
		ReplyToCommand(client, "[SM] Overflow (max. 32767)");
		amount = 32767;
	}
	for (new i = 0; i < target_count; i++)
	{
		new Handle:event = CreateEvent("player_healonhit");
		SetEventInt(event, "entindex", target_list[i]);
		if (amount != -1) SetEventInt(event, "amount", amount);
		FireEvent(event);
	}

	if (Logging) LogAction(client, -1, "%N used Fake Heal on %s (amount: %i)", client, target_name, amount);
	return Plugin_Handled;
}

public Action:Command_fakehhh(client, args)
{
	new Handle:event;
	if (args == 0) event = CreateEvent("pumpkin_lord_summoned");
	if (args != 0) event = CreateEvent("pumpkin_lord_killed");
	FireEvent(event);

	if (Logging) LogAction(client, -1, "%N used Fake Horsemann", client);
	return Plugin_Handled;
}

public Action:Command_fakemono(client, args)
{
	new Handle:event;
	if (args == 0) event = CreateEvent("eyeball_boss_summoned");
	if (args != 0) event = CreateEvent("eyeball_boss_killed");
	FireEvent(event);
	
	if (Logging) LogAction(client, -1, "%N used Fake MONOCULUS!", client);
	return Plugin_Handled;
}

public Action:Command_fakefish(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakefish <victim> [attacker] [assister] [weapon] - Fakes a Holy Mackerel/Unarmed Combat hit-notice. Specify _ to skip arguments.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	new String:arg3[64];
	new String:arg4[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new killer = -1;
		new assister = -1;
		if (!StrEqual(arg2,"") && !StrEqual(arg2,"_")) killer = FindTarget(client, arg2, false, false);
		if (!StrEqual(arg3,"") && !StrEqual(arg3,"_")) assister = FindTarget(client, arg3, false, false);
		new Handle:event = CreateEvent("fish_notice");
		SetEventInt(event, "userid", GetClientUserId(target_list[i]));
		if (killer != -1) SetEventInt(event, "attacker", GetClientUserId(killer));
		if (assister != -1) SetEventInt(event, "assister", GetClientUserId(assister));
		if (!StrEqual(arg4,"") && !StrEqual(arg4,"_")) SetEventString(event, "weapon", arg4);
		if (!StrEqual(arg4,"") && !StrEqual(arg4,"_")) SetEventString(event, "weapon_logclassname", arg4);
		FireEvent(event);
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Fish on %s", client, target_name);
	return Plugin_Handled;
}

public Action:Command_fakejoin(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakejoin <username> [IP] [Steam ID, commas instead of colons] - Fakes a client connect. Specify _ to skip arguments.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	new String:arg3[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	ReplaceString(arg3, 192, ",", ":", false);
	
	if (StrEqual(arg2,"") || StrEqual(arg2,"_")) Format(arg2, 25, "%i.%i.%i.%i", GetRandomInt(1,255), GetRandomInt(1,255), GetRandomInt(1,255), GetRandomInt(1,255));
	if (StrEqual(arg3,"") || StrEqual(arg3,"_")) Format(arg3, 25, "STEAM_0:%i:%i", GetRandomInt(0,1), GetRandomInt(10000000,99999999));

	new Handle:event = CreateEvent("player_connect");
	SetEventString(event, "name", arg1);
	SetEventString(event, "address", arg2);
	SetEventString(event, "networkid", arg3);
	FireEvent(event);

	if (Logging) LogAction(client, -1, "%N used Fake Join: %s (%s) (%s)", client, arg1, arg2, arg3);
	return Plugin_Handled;
}

public Action:Command_fakeblock(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeblock <defender> [control point name] - Fakes the defense of a Control Point.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new Handle:event = CreateEvent("teamplay_capture_blocked");
		if (StrEqual(arg2,"") || StrEqual(arg2,"_")) SetEventString(event, "cpname", "the Control Point");
		if (!StrEqual(arg2,"") && !StrEqual(arg2,"_")) SetEventString(event, "cpname", arg2);
		SetEventInt(event, "blocker", target_list[i]);
		FireEvent(event);
	}

	if (Logging) LogAction(client, -1, "%N used Fake Block on %s (Control Point: %s)", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_faketime(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_faketime <seconds> - Fakes adding seconds to the round timer.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	new time = StringToInt(arg1);
	
	new Handle:event;
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		event	= CreateEvent("teamplay_timer_time_added");
		SetEventInt(event, "timer", entityTimer);
		SetEventInt(event, "seconds_added", time);
		FireEvent(event);
		PrecacheSound("vo/announcer_time_added.wav");
		if (time > 0) EmitSoundToAll("vo/announcer_time_added.wav");
		LogAction(client, -1, "%N used Fake Time: %i seconds", client, time);
	}
	else
	{
		ReplyToCommand(client, "[SM] You can't faketime if there's no timer!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:Command_fakedamage(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakedamage <target> [amount] [attacker] - Fakes damage being dealt.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	new String:arg3[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	new amount = -1;
	new attacker = -1;
	if (!StrEqual(arg2,"_") && !StrEqual(arg2,"")) amount = StringToInt(arg2);
	if (!StrEqual(arg3,"_") && !StrEqual(arg3,"")) attacker = FindTarget(client, arg3, false, false);
	else attacker = client;

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (amount == -1) amount = GetRandomInt(1,450);
	if (amount > 32767)
	{
		ReplyToCommand(client, "[SM] Overflow (max. 32767)");
		amount = 32767;
	}
	for (new i = 0; i < target_count; i++)
	{
		new Handle:event = CreateEvent("player_hurt");
		SetEventInt(event, "userid", GetClientUserId(target_list[i]));
		SetEventInt(event, "damageamount", amount);
		if (attacker != -1) SetEventInt(event, "attacker", GetClientUserId(attacker));
		FireEvent(event);
	}

	if (Logging) LogAction(client, -1, "%N used Fake Damage on %s (amount: %i)", client, target_name, amount);
	return Plugin_Handled;
}

public Action:Command_fakeach(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeach <target> <achievement> - Fake getting an achievement. Doesn't have to be real.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has earned the achievement", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has earned the achievement", arg2, "");
		PrecacheSound("misc/achievement_earned.wav");
		EmitSoundToAll("misc/achievement_earned.wav", target_list[i]);
		AttachParticle(target_list[i], "achieved");
		AttachParticle(target_list[i], "mini_fireworks");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Achievement on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakebuy(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakebuy <target> <item> - Fake someone buying something from the Mann Co. Store.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has purchased:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has purchased:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Buy on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakecraft(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakecraft <target> <item> - Fake someone crafting something.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has crafted:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has crafted:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Craft on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakereceive(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakereceive <target> <item> - Fake someone receiving a gift.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has received a gift:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has received a gift:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Gift on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakefind(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakefind <target> <item> - Fake someone finding something from an item drop.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has found:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has found:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Find on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_faketrade(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_faketrade <target> <item> - Fake someone finishing a trade and receiving an item.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has traded for:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has traded for:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Trade on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakeunbox(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeunbox <target> <item> - Fake someone uncrating something.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has unboxed:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has unboxed:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Unbox on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcecmd(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcecmd <target> <command> - Force someone to execute a command. Game-changing commands like 'quit' or 'bind' do not work.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], arg2);
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Command on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcecmd2(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcecmd2 <target> <command> - Force someone to execute a command. Game-changing commands like 'quit' or 'bind' do not work.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		ClientCommand(target_list[i], arg2);
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Command on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcesay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcesay <target> <text> - Force someone to say something.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], "say %s", arg2);
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Say on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcesayteam(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcesay_team <target> <text> - Force someone to say something to their team.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], "say_team %s", arg2);
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Say Team on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcevoice(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcevoice <target> <voice command id or name> - Force someone to use a voice command.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	new String:arg3[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	new vc1 = -1;
	new vc2 = -1;
	if (StrContains(arg2,"med",false) == 0) vc1 = 0;
	if (StrContains(arg2,"med",false) == 0) vc2 = 0;
	if (StrContains(arg2,"tha",false) == 0) vc1 = 0;
	if (StrContains(arg2,"tha",false) == 0) vc2 = 1;
	if (StrContains(arg2,"go",false) == 0) vc1 = 0;
	if (StrContains(arg2,"go",false) == 0) vc2 = 2;
	if (StrContains(arg2,"move",false) == 0) vc1 = 0;
	if (StrContains(arg2,"move",false) == 0) vc2 = 3;
	if (StrContains(arg2,"left",false) != -1 || StrContains(arg3,"left",false) != -1) vc1 = 0;
	if (StrContains(arg2,"left",false) != -1 || StrContains(arg3,"left",false) != -1) vc2 = 4;
	if (StrContains(arg2,"right",false) != -1 || StrContains(arg3,"right",false) != -1) vc1 = 0;
	if (StrContains(arg2,"right",false) != -1 || StrContains(arg3,"right",false) != -1) vc2 = 5;
	if (StrContains(arg2,"yes",false) == 0) vc1 = 0;
	if (StrContains(arg2,"yes",false) == 0) vc2 = 6;
	if (StrContains(arg2,"no",false) == 0) vc1 = 0;
	if (StrContains(arg2,"no",false) == 0) vc2 = 7;
	if (StrContains(arg2,"inc",false) == 0) vc1 = 1;
	if (StrContains(arg2,"inc",false) == 0) vc2 = 0;
	if (StrContains(arg2,"spy",false) == 0) vc1 = 1;
	if (StrContains(arg2,"spy",false) == 0) vc2 = 1;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"ahead",false) == 0) vc1 = 1;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"ahead",false) == 0) vc2 = 2;
	if (StrContains(arg2,"sentry ahead",false) == 0) vc1 = 1;
	if (StrContains(arg2,"sentry ahead",false) == 0) vc2 = 2;
	if (StrContains(arg2,"tele",false) == 0) vc1 = 1;
	if (StrContains(arg2,"tele",false) == 0) vc2 = 3;
	if (StrContains(arg2,"disp",false) == 0) vc1 = 1;
	if (StrContains(arg2,"disp",false) == 0) vc2 = 4;
	if (StrContains(arg2,"pootis",false) == 0) vc1 = 1;
	if (StrContains(arg2,"pootis",false) == 0) vc2 = 4;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"here",false) == 0) vc1 = 1;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"here",false) == 0) vc2 = 5;
	if (StrContains(arg2,"sentry here",false) == 0) vc1 = 1;
	if (StrContains(arg2,"sentry here",false) == 0) vc2 = 5;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"here",false) == 0) vc1 = 1;
	if (StrContains(arg2,"sentry",false) == 0 && StrContains(arg3,"here",false) == 0) vc2 = 5;
	if (StrContains(arg2,"activ",false) == 0) vc1 = 1;
	if (StrContains(arg2,"activ",false) == 0) vc2 = 6;
	if (StrContains(arg2,"uberc",false) == 0) vc1 = 1;
	if (StrContains(arg2,"uberc",false) == 0) vc2 = 7;
	if (StrContains(arg2,"i am",false) == 0) vc1 = 1;
	if (StrContains(arg2,"i am",false) == 0) vc2 = 7;
	if (StrContains(arg2,"ready",false) == 0) vc1 = 1;
	if (StrContains(arg2,"ready",false) == 0) vc2 = 7;
	if (StrContains(arg2,"help",false) == 0) vc1 = 2;
	if (StrContains(arg2,"help",false) == 0) vc2 = 0;
	if (StrContains(arg2,"battle",false) == 0) vc1 = 2;
	if (StrContains(arg2,"battle",false) == 0) vc2 = 1;
	if (StrContains(arg2,"cheer",false) == 0) vc1 = 2;
	if (StrContains(arg2,"cheer",false) == 0) vc2 = 2;
	if (StrContains(arg2,"jeer",false) == 0) vc1 = 2;
	if (StrContains(arg2,"jeer",false) == 0) vc2 = 3;
	if (StrContains(arg2,"pos",false) == 0) vc1 = 2;
	if (StrContains(arg2,"pos",false) == 0) vc2 = 4;
	if (StrContains(arg2,"neg",false) == 0) vc1 = 2;
	if (StrContains(arg2,"neg",false) == 0) vc2 = 5;
	if (StrContains(arg2,"nice",false) == 0) vc1 = 2;
	if (StrContains(arg2,"nice",false) == 0) vc2 = 6;
	if (StrContains(arg2,"good",false) == 0) vc1 = 2;
	if (StrContains(arg2,"good",false) == 0) vc2 = 7;
	if (vc1 == -1)
	{
		vc1 = StringToInt(arg2);
		vc2 = StringToInt(arg3);
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], "voicemenu %i %i", vc1, vc2);
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Voice Command on %s: %s %s", client, target_name, arg1, arg2);
	return Plugin_Handled;
}

public Action:Command_fakeearn(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeearn <target> <item> - Fake someone earning something from winning duels.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		GenerateItemString(client, "has earned:", arg2, arg1);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		GenerateItemString(target_list[i], "has earned:", arg2, "");
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Earn on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_forcetaunt(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forcetaunt <target> - Force someone to taunt.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], "taunt");
	}
	
	if (Logging) LogAction(client, -1, "%N used Force Taunt on %s", client, target_name);
	return Plugin_Handled;
}

public Action:Command_fakequit(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakequit <target> [reason] - Fake someone leaving the server.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_IMMUNITY,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (StrEqual(arg2, "") || StrEqual(arg2, "_")) Format(arg2, sizeof(arg2), "Disconnect by user.");
	for (new i = 0; i < target_count; i++)
	{
		new Handle:event = CreateEvent("player_disconnect");
		SetEventInt(event, "userid", GetClientUserId(target_list[i]));
		SetEventString(event, "reason", arg2);
		FireEvent(event);
	}
	
	if (Logging) LogAction(client, -1, "%N used Fake Quit on %s: '%s'", client, target_name, arg2);
	return Plugin_Handled;
}

public Action:Command_fakeactivity(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeactivity <admin> <action> [target] - Fakes admin action.");
		return Plugin_Handled;
	}
	new String:arg1[64];
	new String:arg2[128];
	new String:arg3[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	new admin = FindTarget(client, arg1, false, false);
	
	if (StrEqual(arg3, ""))
	{
		ShowActivity2(admin, "[SM] ", arg2);
		
		LogAction(client, -1, "%N used Fake Activity on %N: '%s'", client, admin, arg2);
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg3, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	ShowActivity2(admin, "[SM] ", "%s %s.", arg2, target_name);
	LogAction(client, -1, "%N used Fake Activity on %N: '%s %s.'", client, admin, arg2, target_name);
	return Plugin_Handled;
}

stock SayText2(author_index , const String:message[])
{
	new Handle:buffer = StartMessageAll("SayText2");
	if (buffer != INVALID_HANDLE)
	{
		BfWriteByte(buffer, author_index);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage();
	}
}

AttachParticle(ent, String:particleType[], bool:cache=false)
{
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		new String:tName[128];
		new Float:f_pos[3];

		if (cache) {
			f_pos[2] -= 3000;
		}
		else
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_pos);
			f_pos[2] += 60;
		}

		TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(10.0, DeleteParticle, particle);
	}
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
	}
}