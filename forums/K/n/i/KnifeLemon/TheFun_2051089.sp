#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "The Fun Overlay!",
	author = "KnifeLemon",
	description = "Players on the screen and have fun!",
	version = PLUGIN_VERSION,
};

#define WindowsTimer	90.0
#define NyanCatTimer	221.0

#define WindowsVTF	"TheFun/windows_98.vtf"
#define WindowsVMT	"TheFun/windows_98.vmt"
#define WindowsSound	"TheFun/windows_98.mp3"
#define NyanCatVTF	"TheFun/nyan_cat.vtf"
#define NyanCatVMT	"TheFun/nyan_cat.vmt"
#define NyanCatSound	"TheFun/nyan_cat.mp3"

public OnPluginStart()
{
	HookEvent("player_death", EventDeath);
	
	RegAdminCmd("sm_fun", Command_Windows, ADMFLAG_SLAY, "sm_fun <#userid|name>");
	RegAdminCmd("sm_fun2", Command_NyanCat, ADMFLAG_SLAY, "sm_fun2 <#userid|name>");
	RegAdminCmd("sm_stop", Command_Stop, ADMFLAG_SLAY, "sm_stop <#userid|name>");
}

public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if ( IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) )
	{
		ClientCommand(client, "r_screenoverlay off");
		StopSound(client, SNDCHAN_AUTO, WindowsSound);
		StopSound(client, SNDCHAN_AUTO, NyanCatSound);
	}
}

public OnMapStart()
{
	PrecacheGeneric(WindowsVTF, true);
	PrecacheGeneric(NyanCatVTF, true);
	AddFileToDownloadsTable("materials/TheFun/windows_98.vtf");
	AddFileToDownloadsTable("materials/TheFun/nyan_cat.vtf");
	
	PrecacheGeneric(WindowsVMT, true);
	PrecacheGeneric(NyanCatVMT, true);
	AddFileToDownloadsTable("materials/TheFun/windows_98.vmt");
	AddFileToDownloadsTable("materials/TheFun/nyan_cat.vmt");
	
	PrecacheSound(WindowsSound, true);
	PrecacheSound(NyanCatSound, true);
	AddFileToDownloadsTable("sound/TheFun/windows_98.mp3");
	AddFileToDownloadsTable("sound/TheFun/nyan_cat.mp3");
}

public Action:Command_Windows(client, args)
{
	if ( args < 1 )
	{
		ReplyToCommand(client, "[SM] Using : sm_fun <client>");
		return Plugin_Handled;
	}

	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ( (target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
	{
		ReplyToCommand(client, "[SM] No matching client.");
		return Plugin_Handled;
	}
	
	for ( new i=0; i<target_count; i++ )
	{
		Windows(client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_NyanCat(client, args)
{
	if ( args < 1 )
	{
		ReplyToCommand(client, "[SM] Using : sm_fun2 <client>");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ( (target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
	{
		ReplyToCommand(client, "[SM] No matching client.");
		return Plugin_Handled;
	}
	
	for ( new i=0; i<target_count; i++ )
	{
		NyanCat(client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_Stop(client, args)
{
	if ( args < 1 )
	{
		ReplyToCommand(client, "[SM] Using : sm_stop <client>");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	if ( (target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
	{
		ReplyToCommand(client, "[SM] No matching client.");
		return Plugin_Handled;
	}
	
	for ( new i=0; i<target_count; i++ )
	{
		FunStop(client, target_list[i]);
	}
	
	return Plugin_Handled;
}

stock Windows(Client, target)
{
	if ( target > 0 && target <= MaxClients )
	{
		if ( IsClientConnected(target) && IsClientInGame(target) && !IsFakeClient(Client) )
		{
			EmitSoundToClient(target, WindowsSound);
			ClientCommand(target, "r_screenoverlay \"%s\"", WindowsVMT);
			
			CreateTimer(WindowsTimer, Timer_FunEnd, target, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

stock NyanCat(Client, target)
{
	if ( target > 0 && target <= MaxClients )
	{
		if ( IsClientConnected(target) && IsClientInGame(target) && !IsFakeClient(Client) )
		{
			EmitSoundToClient(target, NyanCatSound);
			ClientCommand(target, "r_screenoverlay \"%s\"", NyanCatVMT);
			
			CreateTimer(NyanCatTimer, Timer_FunEnd, target, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

stock FunStop(Client, target)
{
	if ( target > 0 && target <= MaxClients )
	{
		if ( IsClientConnected(target) && IsClientInGame(target) && !IsFakeClient(Client) )
		{
			ClientCommand(target, "r_screenoverlay off");
			StopSound(target, SNDCHAN_AUTO, WindowsSound);
			StopSound(target, SNDCHAN_AUTO, NyanCatSound);
		}
	}
}

public Action:Timer_FunEnd(Handle:timer, any:client)
{
	if ( IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) )
	{
		ClientCommand(client, "r_screenoverlay off");
	}
}