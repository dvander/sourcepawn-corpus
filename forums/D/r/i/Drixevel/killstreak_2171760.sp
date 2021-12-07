//Original by Dr. Knuckles, updates/fixes by Jack of Designs

#include <sourcemod>

#define PLUGIN_VERSION 			"1.2 fixed"
#define PLUGIN_TAG 			"[KS]"

public Plugin:myinfo =
{
	name = "[TF2] Killstreak",
	author = "Dr_Knuckles",
	description = "Enables Killstreaks on players.",
	version = PLUGIN_VERSION,
	url = "http://www.the-vaticancity.com"
};

new Handle:sm_killstreak_amount;
new Handle:sm_killstreak_save;
new g_iLastKillStreak[MAXPLAYERS+1] = {0,...};
new g_bKSToggle[MAXPLAYERS+1] = {false,...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_ks_version", PLUGIN_VERSION, "Killstreak modifier.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_killstreak_amount = CreateConVar("sm_killstreak_amount", "10", "Default Killstreak Amount", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_killstreak_save = CreateConVar("sm_killstreak_save", "1", "1 = Save between lives, 0 = Reset between lives", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_ks", Killstreak, ADMFLAG_GENERIC);

	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_Death);
	
	AutoExecConfig();
}

public OnClientPutInServer(client)
{
	g_iLastKillStreak[client] = 0;
	g_bKSToggle[client] = false;
}

public Action:Killstreak(client, args)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		new iKS = 0;
		
		if (!g_bKSToggle[client])
		{
			if (args < 1)
			{
				iKS = GetConVarInt(sm_killstreak_amount);
				
				if (g_iLastKillStreak[client] == iKS)
				{
					iKS = 0;
				}
			}
			else
			{
				decl String:sArg[4];
				GetCmdArg(1, sArg, sizeof(sArg));
				iKS = StringToInt(sArg);
			}
		}
		
		g_bKSToggle[client] = !g_bKSToggle[client];
	
		if (iKS >= 0)
		{
			switch (iKS)
			{
				case 0: ReplyToCommand(client, "%s Killstreak disabled.", PLUGIN_TAG);
				default: ReplyToCommand(client, "%s Killstreak set to: %i", PLUGIN_TAG, iKS);
			}
			
			SetEntProp( client, Prop_Send, "m_iKillStreak",  iKS);
		}
		else ReplyToCommand(client, "%s Killstreak must be a positive number.", PLUGIN_TAG);
	}
	else ReplyToCommand(client, "%s %t", PLUGIN_TAG, "Command is in-game only");
	
	return Plugin_Handled;
}

public Event_Spawn(Handle:hEvent, const String:sName[], bool:bNoBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (g_iLastKillStreak[client] > 0)
		{
			SetEntProp(client, Prop_Send, "m_iKillStreak",  g_iLastKillStreak[client]);
		}
	}
}

public Event_Death(Handle:hEvent, const String:sName[], bool:bNoBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!IsFakeClient(client) && IsClientInGame(client))
	{
		if (!GetConVarBool(sm_killstreak_save))
		{
			g_iLastKillStreak[client] = 0;
			return;
		}
		
		new streak = GetEntProp(client, Prop_Send, "m_iKillStreak");
		if (streak <= 0)
		{
			g_iLastKillStreak[client] = streak;
		}
		else g_iLastKillStreak[client] = 0;
	}
}