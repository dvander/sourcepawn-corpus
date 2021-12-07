#include <sourcemod>
#include <collisionhook>

#define VERSION "1.2.1"

#pragma semicolon 1


public Plugin:myinfo =
{
	name = "No-collide Team-mate",
	author = "Mirandor",
	description = "Players dont collide if there on the same team.",
	version = VERSION,
	url = ""
};

new Handle:g_NoCollide_Chat = INVALID_HANDLE;
new Handle:g_NoCollide_Time = INVALID_HANDLE;
new NoCollide_Chat = 0;
new Float:NoCollide_Time = 0.0;
new bool:NoCollide_Disabled = false;

public OnPluginStart()
{
	LoadTranslations("no_collide_teammate.phrases");
	
	CreateConVar( "SM_NoCollideTeammate_version", VERSION, "Version of the no-collide team-mate plugin", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	g_NoCollide_Chat = CreateConVar("SM_NoCollideTeammate_Chat", "1", "1 - Turn the plugin On\n0 - Turn the plugin OFF", _, true, 0.0, true, 1.0);
	g_NoCollide_Time = CreateConVar("SM_NoCollideTeammate_Time", "0.0", "Number of seconds after round_start with no-collision features.\n-1.0 = Collisions are always enabled\n0.0 = Collisions are always disabled (default setting)\n>0.0 = Collisions are disabled for x seconds)", FCVAR_NONE, true, -1.0);
	
	HookEvent("round_start", EventRoundStart);
	
	HookConVarChange(g_NoCollide_Chat, OnSettingsChanged);
	HookConVarChange(g_NoCollide_Time, OnSettingsChanged);
	
	AutoExecConfig(true, "no_collide_teammate");
}

public OnMapStart()
{
	NoCollide_Chat = GetConVarInt(g_NoCollide_Chat);
	NoCollide_Time = GetConVarFloat(g_NoCollide_Time);
	if (NoCollide_Time < 0)
		NoCollide_Disabled = true;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (NoCollide_Time < 0)
	{
		if (NoCollide_Chat)
			PrintToChatAll("[SM] %t", "NCTC_P_Enabled");
	}
	else
	{
		if (NoCollide_Time == 0)
		{
			if (NoCollide_Chat)
				PrintToChatAll("\x01[SM] %t", "NCTC_P_Disabled");
		}
		else
		{
			if (NoCollide_Chat)
				PrintToChatAll("\x01[SM] %t", "NCTC_Disabled", "\x04", NoCollide_Time, "\x01");
			NoCollide_Disabled = false;
			CreateTimer(NoCollide_Time, Timer_Disable_Collision, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Disable_Collision(Handle:timer)
{
	if (NoCollide_Chat)
		PrintToChatAll("[SM] %t", "NCTC_Enabled");
	NoCollide_Disabled = true;
}

public Action:CH_PassFilter(ent1, ent2, &bool:result)
{	
	if (NoCollide_Disabled)
		return Plugin_Continue;
		
	if (IsValidClient(ent1) && IsValidClient(ent2))
        {
		if (GetClientTeam(ent1) != GetClientTeam(ent2))
		{
			result = true;
			return Plugin_Handled;
		}
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client) 
{
    if (0 < client <= MaxClients && IsClientInGame(client)) 
        return true; 
     
    return false; 
}

public OnSettingsChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_NoCollide_Chat)
	{
		NoCollide_Chat = StringToInt(newvalue);
	}
	
	if(cvar == g_NoCollide_Time)
	{
		NoCollide_Time = StringToFloat(newvalue);
		if (NoCollide_Time < 0)
		{
			NoCollide_Time = -1.0;
			NoCollide_Disabled = true;
		}
		else
			NoCollide_Disabled = false;
	}
}