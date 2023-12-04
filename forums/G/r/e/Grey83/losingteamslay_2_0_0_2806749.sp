#pragma semicolon 1

#include <sdktools_functions>

new const
	String:PL_NAME[]= "Losing Team Slayer",
	String:PL_VER[]	= "2.0.0",

	String:MSG[][] =
{
	"Target_Bombed",
	"Bomb_Defused",
	"All_Hostages_Rescued",
	"Target_Saved",
	"Hostages_Not_Rescued"
};

new iMin,
	bMsg,
	bSlay;

public Plugin:myinfo =
{
	name		= PL_NAME,
	author		= "Lindgren, Grey83",
	description	= "Losing team get slayed at the end of the round :: Aka. Autoslay",
	version		= PL_VER,
	url			= "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("losingteamslay_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	new Handle:cvar;
	cvar = CreateConVar("lts_enabled", "1", "Enable/Disable plugin", _, true, _, true, 1.0);
	CVarChange_Enable(cvar, "", "");
	HookConVarChange(cvar, CVarChange_Enable);

	cvar = CreateConVar("lts_minplayer", "3", "Sets the minimum number of players needed to start plugin", _, true, 1.0);
	iMin = GetConVarInt(cvar);
	HookConVarChange(cvar, CVarChange_Min);

	cvar = CreateConVar("lts_slaymsg", "1", "If slayed player get chat msg telling him why he got slayed", _, true, _, true, 1.0);
	bMsg = GetConVarBool(cvar);
	HookConVarChange(cvar, CVarChange_Msg);

	cvar = CreateConVar("lts_slay", "1", "Slay On/Off, Ie. warning only and no slay if lts_slaymsg = 1", _, true, _, true, 1.0);
	bSlay = GetConVarBool(cvar);
	HookConVarChange(cvar, CVarChange_Slay);

	AutoExecConfig(true, "losingteamslay");

	LoadTranslations("losingteamslay.phrases");
}

public CVarChange_Enable(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	static bool:hooked;
	if(hooked == GetConVarBool(cvar))
		return;

	if(!(hooked ^= true))
		UnhookEvent("round_end", Event_RoundEnd);
	else  HookEvent("round_end", Event_RoundEnd);
}

public CVarChange_Min(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iMin = GetConVarInt(cvar);
}

public CVarChange_Msg(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	bMsg = GetConVarBool(cvar);
}

public CVarChange_Slay(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	bSlay = GetConVarBool(cvar);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new loser, msg;
	switch(GetEventInt(event, "reason"))
	{
		case  1:	// #Target_Bombed
		{
			loser = 3;
			msg = 0;
		}
		case  7:	// #Bomb_Defused
		{
			loser = 2;
			msg = 1;
		}
		case 11:	// #All_Hostages_Rescued
		{
			loser = 2;
			msg = 2;
		}
		case 12:	// #Target_Saved
		{
			loser = 2;
			msg = 3;
		}
		case 13:	// #Hostages_Not_Rescued
		{
			loser = 3;
			msg = 4;
		}
		default:
			return;
	}

	new i = 1, y;
	for(; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) > 1) y++;
	if(y < iMin)
		return;

	for(i = 1; i <= MaxClients; ++i) if(IsClientInGame(i) && GetClientTeam(i) == loser)
	{
		if(bMsg  && !IsFakeClient(i)) PrintToChat(i, "%t %t", "Prefix", MSG[msg]);
		if(bSlay && IsPlayerAlive(i)) ForcePlayerSuicide(i);
	}
}