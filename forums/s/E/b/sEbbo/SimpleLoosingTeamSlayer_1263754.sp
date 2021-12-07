#include <sourcemod>

new Handle:target_bombed;
new Handle:target_saved;
new Handle:bomb_defused;
new Handle:all_hostages_rescued;
new Handle:hostages_not_rescued;

public Plugin:myinfo =
{
	name = "Simple Loosing Team Slayer",
	author = "Sebastian (sEbbo) Danielsson",
	description = "This plugin will slay the surviving players in the loosing team.",
	version = "1.0",
	url = "http://www.sebastian-danielsson.com/"
}

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
}

public OnMapStart()
{
	target_bombed = CreateConVar("target_bombed", "CT slayed for failing their objective.", "When the bomb detonate.");
	target_saved = CreateConVar("target_saved", "T slayed for failing their objective.", "When the bomb dont get planted");
	bomb_defused = CreateConVar("bomb_defused", "T slayed for failing their objective.!", "When the bomb is defused");
	all_hostages_rescued = CreateConVar("all_hostages_rescued", "T slayed for failing their objective.", "When all hostages are rescued");
	hostages_not_rescued = CreateConVar("hostages_not_rescued", "CT slayed for failing their objective.", "When hostages are NOT rescued");
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reason = GetEventInt(event, "reason");
	new y = 0;
	for(new x = 1; x <= GetMaxClients(); ++x)
	{
		if(IsClientInGame(x))
			y++;
	}
	CreateTimer(0.2, Delayed_Slay, any:reason);
}

public Action:Delayed_Slay(Handle:timer, any:param)
{
	new winner;
	new String:message[100];

	// Teamwinner:: 2 = T, 3 = CT
	if (param == 0)
	{
		winner = 2;     // #Target_Bombed
		GetConVarString(target_bombed, message, sizeof(message));
	}
	if (param == 11)
	{
		winner = 3;     // #Target_Saved
		GetConVarString(target_saved, message, sizeof(message));
	}
	if (param == 6)
	{
		winner = 3;     // #Bomb_Defused
		GetConVarString(bomb_defused, message, sizeof(message));
	}
	if (param == 10)
	{
		winner = 3;     // #All_Hostages_Rescued
		GetConVarString(all_hostages_rescued, message, sizeof(message));
	}
	if (param == 12)
	{
		winner = 2;     // #Hostages_Not_Rescued
		GetConVarString(hostages_not_rescued, message, sizeof(message));
	}
	if (param == 7)
		winner =0;      // #CT_Win (All Terrorists killed)
	if (param == 8)
		winner = 0;     // #Terrorist_win (All Counter-Terrorists killed)
	if (param == 9)
		winner = 0;     // #Round_Draw
	if (param == 15)
		winner = 0;     // #Game_Commensing

	for(new i = 1; i <= GetMaxClients(); ++i)
	{
		if(IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			new hp = GetEntData(i, FindSendPropOffs("CCSPlayer", "m_iHealth"));
			if ((team != winner) && (team != 1) && (hp >= 1) && (winner != 0))
			{
				PrintToChat(i, "%s", message);
				FakeClientCommand(i,"kill");								
			}
		}
	}
}