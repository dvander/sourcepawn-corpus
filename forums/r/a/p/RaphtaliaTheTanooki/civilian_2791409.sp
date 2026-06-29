#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>

#define PLUGIN_VERSION "1.7"
public Plugin myinfo = 
{
    name = "[TF2] Civilian",
    author = "Peanut",
    description = "Adiciona o comando que te torna um civil",
    version = PLUGIN_VERSION,
    url = "https://discord.gg/7sRn8Bt"
}
/*
Changelog
1.6
Added always respawn as Civilian command
1.5
Rewrote some codes
Also made it more compact
Added colored messages
1.4
Added Version ConVar
1.3
Added Console Check
Added IsDead Check
1.2
Fixed 4th ,5th and 6th slot not having weapons removed
1.1
my edit starts here
1.0
original plugin
*/
bool g_bCivAlways[MAXPLAYERS + 1] = { false, ... };

public APLRes AskPluginLoad2() // responsavel por verificar qual o jogo
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion == Engine_Unknown)
	{
		PrintToServer("What the fuck are you running? Unknown game this plugin might not work...");
		return APLRes_Success;
	}
	
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("Server Not Running TF2! Run TF2 You Dum-Dum!");
	}
	return APLRes_Success;
}

public void OnPluginStart() // responsavel por criar cvar da versão e comandos, tbm responsavel pelo arquivo de tradução
{
	CreateConVar("sm_civiver", PLUGIN_VERSION, "Plugin Version...", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_civ", Command_Civil)
	RegConsoleCmd("sm_tpose", Command_Civil)
	RegConsoleCmd("sm_civilian", Command_Civil)
	RegConsoleCmd("sm_apose", Command_Civil)
	RegConsoleCmd("sm_aciv", Command_ChangeStatus)
	RegConsoleCmd("sm_atpose", Command_ChangeStatus)
	RegConsoleCmd("sm_alwayscivilian", Command_ChangeStatus)
	RegConsoleCmd("sm_aapose", Command_ChangeStatus)
	LoadTranslations("civ.phrases.txt")
	HookEvent("post_inventory_application", Event_InventoryApplication);
}

public Action Command_Civil(int client, int args) // codigo dos comandos
{
	if(client == 0)
		{
			CReplyToCommand(client, "{unique}[Civ]{default} %t", "IsConsole");
			return Plugin_Handled;
		}
	if(!IsPlayerAlive(client))
		{
		CReplyToCommand(client, "{unique}[Civ]{default} %t", "IsDead")
		return Plugin_Handled
		}
	CReplyToCommand(client, "{unique}[Civ]{default} %t", "BecameCiv");
	TF2_RemoveAllWeapons(client)
	return Plugin_Handled;
}

public Action Command_ChangeStatus(int client, int args)
{
	g_bCivAlways[client] = !g_bCivAlways[client];

	if(g_bCivAlways[client])
	{
		Command_Civil(client, args);
		CReplyToCommand(client, "{unique}[Civ]{default} %t", "AlwaysCivE");
	}
	else
	{
		CReplyToCommand(client, "{unique}[Civ]{default} %t", "AlwaysCivD");
	}
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	g_bCivAlways[client] = false;
}

public void Event_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (g_bCivAlways[client])
    {
        TF2_RemoveAllWeapons(client);
    }
}