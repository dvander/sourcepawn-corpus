#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "2.0.0"

ConVar g_cvFF; // Friendly fire cvar
ConVar g_cvEnable;
ConVar g_cvCenter;
ConVar g_cvHint;
ConVar g_cvChat;
EngineVersion g_EngineVersion;

public Plugin myinfo = {
	name 		= "[ANY] End of Round Friendly Fire",
	author 		= "Sgt. Gremulock",
	description = "Activates friendly fire at the end of the round and disabled it at the start of the next round.",
	version 	= PLUGIN_VERSION,
	url 		= "https://forums.alliedmods.net/showthread.php?t=301792"
};

public void OnPluginStart()
{
	g_cvFF = FindConVar("mp_friendlyfire");
	if (!g_cvFF) // mp_friendlyfire not found
	{
		SetFailState("ConVar mp_friendlyfire doesn't exist!");
	}

	g_EngineVersion = GetEngineVersion();
	switch (g_EngineVersion)
	{
		case Engine_DODS:
		{
			HookEvent("dod_round_start", Event_RoundStart);
			HookEvent("dod_round_win",   Event_RoundEnd);
		}

		case Engine_TF2:
		{
			HookEvent("teamplay_round_start", Event_RoundStart);
			HookEvent("teamplay_round_win",   Event_RoundEnd);
		}

		default:
		{
			HookEvent("round_start", Event_RoundStart);
			HookEvent("round_end",   Event_RoundEnd);
		}
	}

	CreateConVar("sm_endroundff_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvEnable = CreateConVar("sm_endroundff_enable",      "1", "Enable/disable the plugin\n1 = Enable, 0 = Disable",                 _, true, 0.0, true, 1.0);
	g_cvCenter = CreateConVar("sm_endroundff_center_text", "1", "Enable/disable the display of center text\n1 = Enable, 0 = Disable", _, true, 0.0, true, 1.0);
	g_cvHint   = CreateConVar("sm_endroundff_hint_text",   "1", "Enable/disable the display of hint text\n1 = Enable, 0 = Disable",   _, true, 0.0, true, 1.0);
	g_cvChat   = CreateConVar("sm_endroundff_chat_text",   "1", "Enable/disable the display of chat text\n1 = Enable, 0 = Disable",   _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "endroundff");

	LoadTranslations("endroundff.phrases");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvEnable.BoolValue)
	{
		g_cvFF.SetBool(false);
		if (g_cvCenter.BoolValue || g_cvHint.BoolValue)
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%t", "disabled");
			CRemoveTags(buffer, sizeof(buffer));
			if (g_cvCenter.BoolValue)
			{
				PrintCenterTextAll(buffer);
			}

			if (g_cvHint.BoolValue)
			{
				PrintHintTextToAll(buffer);
			}
		}

		if (g_cvChat.BoolValue)
		{
			CPrintToChatAll("%t %t", "chat tag", "disabled");
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_cvEnable.BoolValue)
	{
		g_cvFF.SetBool(true);
		if (g_cvCenter.BoolValue || g_cvHint.BoolValue)
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%t", "enabled");
			CRemoveTags(buffer, sizeof(buffer));
			if (g_cvCenter.BoolValue)
			{
				PrintCenterTextAll(buffer);
			}

			if (g_cvHint.BoolValue)
			{
				PrintHintTextToAll(buffer);
			}
		}

		if (g_cvChat.BoolValue)
		{
			CPrintToChatAll("%t %t", "chat tag", "enabled");
		}
	}
}
