#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Disable ConTracker idle animation",
	author = "Mikusch",
	description = "Prevents exploits by disabling the ConTracker's idle animation.",
	version = "1.0.0",
	url = "https://github.com/Mikusch"
}

public void OnPluginStart()
{
	AddCommandListener(CommandListener_OpenCYOAPDA, "cyoa_pda_open");
}

Action CommandListener_OpenCYOAPDA(int client, const char[] command, int argc)
{
	// Blocks cyoa_pda_open, which prevents m_bViewingCYOAPDA from being set,
	// and the sequence ACT_MP_CYOA_PDA_IDLE from ever playing.
	return Plugin_Handled;
}
