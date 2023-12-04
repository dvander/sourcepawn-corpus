/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
PLUGIN DEFINES
******************************/

#define MAX_BUTTONS 25

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "Client Command Control",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "Client Command Control",
	PL_VERSION[]	 = "1.0.0";

/******************************
PLUGIN CONVARS
******************************/

enum struct _gConVar
{
	ConVar g_cEnabled;
	ConVar g_cJumpEnabled;
	ConVar g_cUseEnabled;
	ConVar g_cJumpThreshold;
	ConVar g_cTimeReset;
	ConVar g_cUseThreshold;
	ConVar g_cUseTimeReset;
}

_gConVar gConVar;

/******************************
PLUGIN HANDLE
******************************/

Handle	 g_hTimerJump[MAXPLAYERS + 1];
Handle	 g_hTimerUse[MAXPLAYERS + 1];

/******************************
PLUGIN BOOLEANS
******************************/

bool	 g_bPlayerJump[MAXPLAYERS + 1] = { false, ... };
bool	 g_bPlayerUse[MAXPLAYERS + 1]  = { false, ... };

/******************************
PLUGIN INTEGERS
******************************/

int		 g_iPlayerJump[MAXPLAYERS + 1];
int		 g_iPlayerUse[MAXPLAYERS + 1];
int		 g_iLastButtons[MAXPLAYERS + 1];

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
INITIATE THE PLUGIN
******************************/
public void OnPluginStart()
{
	/*GAME CHECK*/
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_HL2DM)
	{
		SetFailState("[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
	}

	/*ConVar*/

	gConVar.g_cEnabled		 = CreateConVar("sm_keybind_spam_enable", "1", "Enable/Disable Plugin", 0, true, 0.0, true, 1.0);
	gConVar.g_cJumpEnabled	 = CreateConVar("sm_jump_spam_protection", "1", "Enable/Disable Jump Spam Protection", 0, true, 0.0, true, 1.0);
	gConVar.g_cUseEnabled	 = CreateConVar("sm_use_spam_protection", "0", "Enable/Disable Use Spam Protection", 0, true, 0.0, true, 1.0);
	gConVar.g_cJumpThreshold = CreateConVar("sm_jump_threshold", "100", "Threshold at which it will kick players for +jump spam");
	gConVar.g_cTimeReset	 = CreateConVar("sm_jump_threshold_reset", "10.0", "Time at which the threshold will reset");
	gConVar.g_cUseThreshold	 = CreateConVar("sm_use_threshold", "20", "Threshold at which it will kick players for +use spam");
	gConVar.g_cUseTimeReset	 = CreateConVar("sm_use_threshold_reset", "10.0", "Threshold at which the threshold will reset");

	/*Admin Commands*/

	RegAdminCmd("sm_spam_reset", spamreset, ADMFLAG_ROOT, "Resets all thresholds");

	AutoExecConfig(true);
}

/******************************
PLUGIN FUNCTIONS
******************************/
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) return;
	g_iPlayerJump[client] = 0;
	g_bPlayerJump[client] = false;
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client)) return;
	delete g_hTimerJump[client];
	delete g_hTimerUse[client];
	g_bPlayerJump[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Handled;

	if (GetConVarInt(gConVar.g_cEnabled) == 0) return Plugin_Continue;

	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);

		if ((buttons & button))
		{
			if (!(g_iLastButtons[client] & button))
			{
				OnButtonPress(client, button);
			}
		}
	}

	g_iLastButtons[client] = buttons;

	return Plugin_Continue;
}

void OnButtonPress(int client, int button)
{
	if (GetConVarInt(gConVar.g_cJumpEnabled) == 1)
	{
		if ((button & IN_JUMP))
		{
			g_iPlayerJump[client]++;
			if (g_iPlayerJump[client] >= GetConVarInt(gConVar.g_cJumpThreshold))
			{
				KickClient(client, "Auto-kick - Spamming +jump");
				return;
			}

			if (g_iPlayerJump[client] >= GetConVarInt(gConVar.g_cJumpThreshold) - 5)
			{
				PrintToChat(client, "[SM] LAST WARNING: Stop spamming +jump or you will be kicked.");
				return;
			}

			if (g_iPlayerJump[client] >= GetConVarInt(gConVar.g_cJumpThreshold) - 10)
			{
				PrintToChat(client, "[SM] Stop spamming +jump or you will be kicked.");
				return;
			}

			if (g_iPlayerJump[client] >= GetConVarInt(gConVar.g_cJumpThreshold) - 20)
			{
				PrintToChat(client, "[SM] Stop spamming +jump.");
				return;
			}

			if (g_iPlayerJump[client] > 0)
			{
				if (g_bPlayerJump[client]) return;
				DataPack pack;
				g_hTimerJump[client] = CreateDataTimer(GetConVarFloat(gConVar.g_cTimeReset), t_JumpThreshold, pack);
				pack.WriteCell(client);
				g_bPlayerJump[client] = true;
				return;
			}
		}
	}

	if (GetConVarInt(gConVar.g_cUseEnabled) == 1)
	{
		if (button & IN_USE)
		{
			g_iPlayerUse[client]++;
			if (g_iPlayerUse[client] >= GetConVarInt(gConVar.g_cUseThreshold))
			{
				KickClient(client, "Auto-kick - Spamming +use");
				return;
			}

			if (g_iPlayerUse[client] >= GetConVarInt(gConVar.g_cUseThreshold) - 2)
			{
				PrintToChat(client, "[SM] LAST WARNING: Stop spamming +use or you will be kicked.");
				return;
			}

			if (g_iPlayerUse[client] >= GetConVarInt(gConVar.g_cUseThreshold) - 5)
			{
				PrintToChat(client, "[SM] Stop spamming +use or you will be kicked.");
				return;
			}

			if (g_iPlayerUse[client] >= GetConVarInt(gConVar.g_cUseThreshold) - 10)
			{
				PrintToChat(client, "[SM] Stop spamming +use.");
				return;
			}

			if (g_iPlayerUse[client] > 0)
			{
				if (g_bPlayerUse[client]) return;
				DataPack pack;
				g_hTimerUse[client] = CreateDataTimer(GetConVarFloat(gConVar.g_cUseTimeReset), t_UseThreshold, pack);
				pack.WriteCell(client);
				g_bPlayerUse[client] = true;
				return;
			}
		}
	}
	return;
}

public Action t_JumpThreshold(Handle timer, DataPack pack)
{
	pack.Reset();
	int client;
	client				  = pack.ReadCell();

	g_iPlayerJump[client] = 0;
	g_bPlayerJump[client] = false;
	g_hTimerJump[client]  = null;
	return Plugin_Stop;
}

public Action t_UseThreshold(Handle timer, DataPack pack)
{
	pack.Reset();
	int client;
	client				 = pack.ReadCell();

	g_iPlayerUse[client] = 0;
	g_bPlayerUse[client] = false;
	g_hTimerUse[client]	 = null;
	return Plugin_Stop;
}

public Action spamreset(int client, int args)
{
	if (GetConVarInt(gConVar.g_cEnabled) == 0)
	{
		ReplyToCommand(client, "[SM] This plugin is disabled.");
		return Plugin_Handled;
	}

	if (!args)
	{
		if (g_iPlayerUse[client] == 0 && g_iPlayerJump[client] == 0)
		{
			ReplyToCommand(client, "[SM] No active cooldown.");
			return Plugin_Handled;
		}
		g_iPlayerUse[client] = 0;
		g_bPlayerUse[client] = false;
		delete g_hTimerUse[client];
		g_iPlayerJump[client] = 0;
		g_bPlayerJump[client] = false;
		delete g_hTimerJump[client];
		ReplyToCommand(client, "[SM] Reset threshold.");
		LogMessage("Reset +jump and +use spam threshold for %L.", client);
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArgString(arg, sizeof(arg));

	int Target = FindTarget(client, arg, true, false);

	if (Target == -1)
	{
		return Plugin_Handled;
	}

	if (g_iPlayerUse[Target] == 0 && g_iPlayerJump[Target] == 0)
	{
		ReplyToCommand(client, "[SM] No active cooldown for %N.", Target);
		return Plugin_Handled;
	}
	g_iPlayerUse[Target] = 0;
	g_bPlayerUse[Target] = false;
	delete g_hTimerUse[Target];
	g_iPlayerJump[Target] = 0;
	g_bPlayerJump[Target] = false;
	delete g_hTimerJump[Target];
	ReplyToCommand(client, "[SM] Reset threshold on %N.", Target);
	LogAction(client, Target, "Reset +jump and +use spam threshold for %L.", Target);
	return Plugin_Handled;
}

public void OnMapEnd()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (i < 1 || i > MaxClients || !IsClientInGame(i) || IsFakeClient(i)) return;

		g_iPlayerUse[i] = 0;
		g_bPlayerUse[i] = false;
		delete g_hTimerUse[i];
		g_iPlayerJump[i] = 0;
		g_bPlayerJump[i] = false;
		delete g_hTimerJump[i];
	}
}