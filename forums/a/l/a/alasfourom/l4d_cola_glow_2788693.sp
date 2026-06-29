#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

bool g_bLeft4DeadEngine;
bool g_bColaGlowToggler;

public Plugin myinfo =
{
	name = "L4D Cola Glow",
	author = "alasfourom",
	description = "Toggle Cola Glow On/Off",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2788693#post2788693"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead || Engine_Left4Dead2) g_bLeft4DeadEngine = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_cola", Command_FindCola, "Toggle Cola Gow On/Off");
	HookEvent("round_start", Event_OnRoundStart);
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bColaGlowToggler = false;
}

public Action Command_FindCola(int client, int args)
{
	int entity = -1;
	entity = FindEntityByClassname(entity, "weapon_cola_bottles");
	
	if(g_bLeft4DeadEngine)
	{
		if (IsValidEntity(entity) && !g_bColaGlowToggler)
		{
			AcceptEntityInput(entity, "StartGlowing");
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", 10000);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (255 * 65536));
			SetEntProp(entity, Prop_Send, "m_bFlashing", true);
			ReplyToCommand(client, "\x04[Cola Finder] \x01Cola glow toggled: \x05On");
			g_bColaGlowToggler = true;
		}
		else if (IsValidEntity(entity) && g_bColaGlowToggler)
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(entity, Prop_Send, "m_bFlashing", false);
			ReplyToCommand(client, "\x04[Cola Finder] \x01Cola glow toggled: \x05Off");
			g_bColaGlowToggler = false;
		}
		else ReplyToCommand(client, "\x04[Cola Finder] \x03Error: \x01Cola was not found!");
	}
	return Plugin_Handled;
}