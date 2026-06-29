#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

Handle mp_gamemode;
char current_map[36], GameMode[16], NextCampaign[40];
int repeats, round_end_repeats;
#define maps  StrEqual(current_map, "l4d_hospital05_rooftop", false) || StrEqual(current_map, "l4d_garage02_lots", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false) || StrEqual(current_map, "l4d_airport05_runway", false) || StrEqual(current_map, "l4d_farm05_cornfield", false) || StrEqual(current_map, "l4d_river03_port", false)

public Plugin myinfo = 
{
	name = "[L4D] Next Campaign (Update 18.06.2017)",
	author = "Jonny, AlexMy",
	description = "",
	version = "1.6",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	mp_gamemode = FindConVar("mp_gamemode");
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("round_start_post_nav", Event_RoundStart);	
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	GetCurrentMap(current_map, 35);
	GetConVarString(mp_gamemode, GameMode, sizeof(GameMode));

	if (StrEqual(GameMode, "coop", false) || StrEqual(GameMode, "realism", false))
		repeats = 1;
	if (StrEqual(GameMode, "versus", false) || StrEqual(GameMode, "teamversus", false))
		repeats = 2;

	round_end_repeats = 0;
}

public Action Event_FinalWin(Event event, const char [] name, bool dontBroadcast)
{
	if (maps)
	{
		repeats--;
		if (repeats < 1)
		{
			PrintNextCampaign();
			CreateTimer(10.0, ChangeCampaign);
		}
	}
}

public Action TimedVote(Handle timer, any client)
{
	if (StrEqual(current_map, "l4d_hospital05_rooftop", false))
		ServerCommand("sm_votemap l4d_garage01_alleys");
	if (StrEqual(current_map, "l4d_garage02_lots", false))
		ServerCommand("sm_votemap l4d_smalltown01_caves");
	if (StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		ServerCommand("sm_votemap l4d_airport01_greenhouse");
	if (StrEqual(current_map, "l4d_airport05_runway", false))
		ServerCommand("sm_votemap l4d_farm01_hilltop");
	if (StrEqual(current_map, "l4d_farm05_cornfield", false))
		ServerCommand("sm_votemap l4d_river01_docks");
	if (StrEqual(current_map, "l4d_river03_port", false))
		ServerCommand("sm_votemap l4d_hospital01_apartment");
}

public Action Event_RoundStart(Event event, const char [] name, bool dontBroadcast)
{
	if (maps)
	{
		if (round_end_repeats > 0)
			PrintToChatAll("\x05Mission failed \x01%d\x05 time(s)", round_end_repeats);
		if (round_end_repeats > 2)
		{	
			CreateTimer(10.0, TimedVote);
		}
	}
}

public Action Event_RoundEnd(Event event, const char [] name, bool dontBroadcast)
{
	if (maps)
	{
		round_end_repeats++;
	}
}

public Action ChangeCampaign(Handle timer, any client)
{
	if (StrEqual(current_map, "l4d_hospital05_rooftop", false))
		ServerCommand("changelevel l4d_garage01_alleys");
	if (StrEqual(current_map, "l4d_garage02_lots", false))
		ServerCommand("changelevel l4d_smalltown01_caves");
	if (StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		ServerCommand("changelevel l4d_airport01_greenhouse");
	if (StrEqual(current_map, "l4d_airport05_runway", false))
		ServerCommand("changelevel l4d_farm01_hilltop");
	if (StrEqual(current_map, "l4d_farm05_cornfield", false))
		ServerCommand("changelevel l4d_river01_docks");
	if (StrEqual(current_map, "l4d_river03_port", false))
		ServerCommand("changelevel l4d_hospital01_apartment");
}

public Action Command_Say(int client, int args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	char text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (strcmp(text[startidx], "!next", false) == 0)
	{
		PrintNextCampaign();
	}

	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

void PrintNextCampaign()
{
	if (StrEqual(current_map, "l4d_hospital01_apartment", false) || StrEqual(current_map, "l4d_hospital02_subway", false)    || StrEqual(current_map, "l4d_hospital03_sewers", false)      || StrEqual(current_map, "l4d_hospital04_interior", false)    || StrEqual(current_map, "l4d_hospital05_rooftop", false))
		NextCampaign = "Роковой Полёт.";
	if (StrEqual(current_map, "l4d_garage01_alleys", false)      || StrEqual(current_map, "l4d_garage02_lots", false))
		NextCampaign = "Похоронный Звон.";
	if (StrEqual(current_map, "l4d_smalltown01_caves", false)    || StrEqual(current_map, "l4d_smalltown02_drainage", false) || StrEqual(current_map, "l4d_smalltown03_ranchhouse", false) || StrEqual(current_map, "l4d_smalltown04_mainstreet", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		NextCampaign = "Смерть в Воздухе.";
	if (StrEqual(current_map, "l4d_airport01_greenhouse", false) || StrEqual(current_map, "l4d_airport02_offices", false)    || StrEqual(current_map, "l4d_airport03_garage", false)       || StrEqual(current_map, "l4d_airport04_terminal", false)     || StrEqual(current_map, "l4d_airport05_runway", false))
		NextCampaign = "Кровавая Жатва.";
	if (StrEqual(current_map, "l4d_farm01_hilltop", false)       || StrEqual(current_map, "l4d_farm02_traintunnel", false)   || StrEqual(current_map, "l4d_farm03_bridge", false)          || StrEqual(current_map, "l4d_farm04_barn", false)            || StrEqual(current_map, "l4d_farm05_cornfield", false))
		NextCampaign = "Жертва.";
	if (StrEqual(current_map, "l4d_river01_docks", false)        || StrEqual(current_map, "l4d_river02_barge", false)        || StrEqual(current_map, "l4d_river03_port", false))
		NextCampaign = "Нет Милосердию.";

	PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
}