#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.7b"

public Plugin:myinfo = 
{
	name = "jb_teamlimit",
	author = "meng",
	version = PLUGIN_VERSION,
	description = "limits the terrorist team for jailbreak servers.",
	url = ""
};

new Handle:g_enabled;
new Handle:g_minplayers;
new Handle:g_ratio;

public OnPluginStart()
{
	CreateConVar("jb_teamlimit_version", PLUGIN_VERSION, "jb teamlimit version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_enabled = CreateConVar("jb_teamlimit_enabled", "1", "enable/disable plugin");
	g_minplayers = CreateConVar("jb_teamlimit_minplayers", "6.0", "minimun # of players needed before limiting");
	g_ratio = CreateConVar("jb_teamlimit_ratio", "3.0", "target t/ct ratio");

	RegConsoleCmd("jointeam", Command_JoinTeam);
}

public OnMapStart()
{
	PrecacheSound("buttons/weapon_cant_buy.wav");
}

public Action:Command_JoinTeam(client, args)
{
	if (GetConVarInt(g_enabled))
	{
		new String:info[7];
		GetCmdArg(1, info, sizeof(info));
		new c_team = StringToInt(info);
		if (!c_team || c_team == 3)
		{
			new team, Float:total_ts, Float:total_cts;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					team = GetClientTeam(i);
					if (team == 2)
						total_ts += 1.0;
					else if (team == 3)
						total_cts += 1.0;
				}
			}
			if (total_cts + total_ts >= GetConVarFloat(g_minplayers) && 
			total_cts > total_ts/GetConVarFloat(g_ratio))
			{
				ChangeClientTeam(client, 2);
				if (c_team)
				{
					EmitSoundToClient(client, "buttons/weapon_cant_buy.wav");
					PrintToChat(client, "\x04[SM] There are currently too many counter-terrorists.");
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}