#pragma semicolon 1

#include <sourcemod>

#define 		PLUGIN_VERSION 						"0.91"
static	const	Float:	fExtraTankTime				= 1.0;
new 			bool:	bEnabled 					= true;
new 			bool:	bAllowBot					= false;
new				Handle: hAllowTankBot;
new 			Handle:	hEnableCvar;
new				Handle:	hTankSelectionTimeCvar;

public Plugin:myinfo = 
{
	name = "No Infected Bots",
	author = "Mr. Zero",
	description = "Kick special infected bots.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=118798"
}

public OnPluginStart()
{
	HookEvent("tank_spawn", TankSpawn_Event);
	
	hEnableCvar = CreateConVar("l4d2_noinfectedbots_enabled","1","Blocks infected bots from joining the game");
	hAllowTankBot = CreateConVar("l4d2_noinfectedbots_allowtankbot","1","Allow 1 AI infected when tank spawns (not the tank itself, but the player can spawn a AI infected first before taking control of the tank)");
	CreateConVar("l4d2_noinfectedbots_version", PLUGIN_VERSION, "NoInfectedBots Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookConVarChange(hEnableCvar,ConVarChange);
	
	hTankSelectionTimeCvar = FindConVar("director_tank_lottery_selection_time");
	
	AutoExecConfig(true,"NoInfectedBots");
	RegAdminCmd("sm_infbots",ToogleInfectedBots_Command,ADMFLAG_BAN,"Toggles infected bots",_,FCVAR_PLUGIN);
}

public Action:ToogleInfectedBots_Command(client,args)
{
	if (bEnabled)
	{
		SetConVarInt(hEnableCvar,0);
		ReplyToCommand(client,"[SM] Infected bots are now allowed");
	}
	else
	{
		SetConVarInt(hEnableCvar,1);
		ReplyToCommand(client,"[SM] Infected bots are now disallowed");
	}
	return Plugin_Handled;
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bEnabled = GetConVarBool(hEnableCvar);
}

public TankSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hAllowTankBot)){return;}
	bAllowBot = true;
	CreateTimer((GetConVarFloat(hTankSelectionTimeCvar) + fExtraTankTime), TankSpawn_Timer);
}

public Action:TankSpawn_Timer(Handle:timer)
{
	bAllowBot = false;
}

public bool:OnClientConnect(client, String:rejectmsg[],maxlen)
{
	if(!IsFakeClient(client) || !bEnabled)
	{
		return true;
	}
	
	decl String:name[10];
	GetClientName(client, name, sizeof(name));
	
	if(StrContains(name, "smoker", false) == -1 && 
		StrContains(name, "boomer", false) == -1 && 
		StrContains(name, "hunter", false) == -1 && 
		StrContains(name, "spitter", false) == -1 && 
		StrContains(name, "jockey", false) == -1 && 
		StrContains(name, "charger", false) == -1)
	{
		return true;
	}
	
	if(bAllowBot)
	{
		bAllowBot = false;
		return true;
	}
	
	KickClient(client,"[NoInfectedBots] Kicking infected bot...");
	
	return false;
}