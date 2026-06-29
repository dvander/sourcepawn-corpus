#include <sourcemod>
new Handle:mp_gamemode;
new String:current_map[36];
new repeats;
new round_end_repeats;

public Plugin:myinfo = 
{
	name = "[L4D] Next Campaign",
	author = "Jonny",
	description = "",
	version = "1.5",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	mp_gamemode = FindConVar("mp_gamemode");
	HookEvent("finale_win", Event_FinalWin);
	HookEvent("round_start_post_nav", Event_RoundStart);	
	HookEvent("round_end", Event_RoundEnd);
}

//public OnPluginEnd()
//{
//	UnhookEvent("finale_win", Event_FinalWin);
//}

public OnMapStart()
{
	GetCurrentMap(current_map, 35);
	decl String:GameMode[16];
	GetConVarString(mp_gamemode, GameMode, sizeof(GameMode));

	if (StrEqual(GameMode, "coop", false) || StrEqual(GameMode, "realism", false))
		repeats = 1;
	if (StrEqual(GameMode, "versus", false) || StrEqual(GameMode, "teamversus", false))
		repeats = 2;

	round_end_repeats = 0;
}

public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(current_map, "l4d_airport05_runway", false) || StrEqual(current_map, "l4d_farm05_cornfield", false) || StrEqual(current_map, "l4d_garage02_lots", false) || StrEqual(current_map, "l4d_hospital05_rooftop", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false))
	{
		repeats--;
		if (repeats < 1)
		{
			PrintNextCampaign();
			CreateTimer(10.0, ChangeCampaign);
		}
	}
}

public Action:TimedVote(Handle:timer, any:client)
{
	if (StrEqual(current_map, "l4d_hospital05_rooftop", false))
		ServerCommand("sm_votemap l4d_farm01_hilltop");
	if (StrEqual(current_map, "l4d_farm05_cornfield", false))
		ServerCommand("sm_votemap l4d_smalltown01_caves");
	if (StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		ServerCommand("sm_votemap l4d_airport01_greenhouse");
	if (StrEqual(current_map, "l4d_airport05_runway", false))
		ServerCommand("sm_votemap l4d_garage01_alleys");
	if (StrEqual(current_map, "l4d_garage02_lots", false))
		ServerCommand("sm_votemap l4d_hospital01_apartment");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(current_map, "l4d_airport05_runway", false) || StrEqual(current_map, "l4d_farm05_cornfield", false) || StrEqual(current_map, "l4d_garage02_lots", false) || StrEqual(current_map, "l4d_hospital05_rooftop", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false))
	{
		if (round_end_repeats > 0)
			PrintToChatAll("\x05Mission failed \x01%d\x05 time(s)", round_end_repeats);
		if (round_end_repeats > 2)
		{	
			CreateTimer(10.0, TimedVote);
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(current_map, "l4d_airport05_runway", false) || StrEqual(current_map, "l4d_farm05_cornfield", false) || StrEqual(current_map, "l4d_garage02_lots", false) || StrEqual(current_map, "l4d_hospital05_rooftop", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false))
	{
		round_end_repeats++;
	}
}

public Action:ChangeCampaign(Handle:timer, any:client)
{
	if (StrEqual(current_map, "l4d_hospital05_rooftop", false))
		ServerCommand("changelevel l4d_farm01_hilltop");
	if (StrEqual(current_map, "l4d_farm05_cornfield", false))
		ServerCommand("changelevel l4d_smalltown01_caves");
	if (StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		ServerCommand("changelevel l4d_airport01_greenhouse");
	if (StrEqual(current_map, "l4d_airport05_runway", false))
		ServerCommand("changelevel l4d_garage01_alleys");
	if (StrEqual(current_map, "l4d_garage02_lots", false))
		ServerCommand("changelevel l4d_hospital01_apartment");
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (strcmp(text[startidx], "!next", false) == 0)
	{
		PrintNextCampaign();
	}

	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

PrintNextCampaign()
{
	decl String:NextCampaign[24];

	if (StrEqual(current_map, "l4d_hospital01_apartment", false) || StrEqual(current_map, "l4d_hospital02_subway", false) || StrEqual(current_map, "l4d_hospital03_sewers", false) || StrEqual(current_map, "l4d_hospital04_interior", false) || StrEqual(current_map, "l4d_hospital05_rooftop", false))
		NextCampaign = "Blood Harvest";
	if (StrEqual(current_map, "l4d_farm01_hilltop", false) || StrEqual(current_map, "l4d_farm02_traintunnel", false) || StrEqual(current_map, "l4d_farm03_bridge", false) || StrEqual(current_map, "l4d_farm04_barn", false) || StrEqual(current_map, "l4d_farm05_cornfield", false))
		NextCampaign = "Death Toll";
	if (StrEqual(current_map, "l4d_smalltown01_caves", false) || StrEqual(current_map, "l4d_smalltown02_drainage", false) || StrEqual(current_map, "l4d_smalltown03_ranchhouse", false) || StrEqual(current_map, "l4d_smalltown04_mainstreet", false) || StrEqual(current_map, "l4d_smalltown05_houseboat", false))
		NextCampaign = "Dead Air";
	if (StrEqual(current_map, "l4d_airport01_greenhouse", false) || StrEqual(current_map, "l4d_airport02_offices", false) || StrEqual(current_map, "l4d_airport03_garage", false) || StrEqual(current_map, "l4d_airport04_terminal", false) || StrEqual(current_map, "l4d_airport05_runway", false))
		NextCampaign = "Crash Course";
	if (StrEqual(current_map, "l4d_garage01_alleys", false) || StrEqual(current_map, "l4d_garage02_lots", false))
		NextCampaign = "No mercy";

//	if (StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false))
//		NextCampaign = "";

	PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
}