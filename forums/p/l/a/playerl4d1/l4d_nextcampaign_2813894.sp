#include <sourcemod>
new Handle:mp_gamemode;
new String:current_map[36];
new repeats;
new round_end_repeats;

public Plugin:myinfo = 
{
	name = "[L4D] Next Campaign",
	author = "gregori135",
	description = "Witam wszystkich nowa wersja. Już dostępna",
	version = "1.6",
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
	if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false) || StrEqual(current_map, "c7m3_port", false) || StrEqual(current_map, "c8m5_rooftop", false) || StrEqual(current_map, "c6m3_port", false) || StrEqual(current_map, "c9m2_lots", false) || StrEqual(current_map, "c10m5_houseboat", false) || StrEqual(current_map, "c11m5_runway", false) || StrEqual(current_map, "c12m5_cornfield", false) || StrEqual(current_map, "c13m4_cutthroatcreek", false) || StrEqual(current_map, "c14m2_lighthouse", false))
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
	if (StrEqual(current_map, "c1m4_atrium", false))
		ServerCommand("sm_votemap c2m1_highway");
	if (StrEqual(current_map, "c2m5_concert", false))
		ServerCommand("sm_votemap c3m1_plankcountry");
	if (StrEqual(current_map, "c3m4_plantation", false))
		ServerCommand("sm_votemap c4m1_milltown_a");
	if (StrEqual(current_map, "c4m5_milltown_escape", false))
		ServerCommand("sm_votemap 	c5m1_waterfront");
	if (StrEqual(current_map, "c5m5_bridge", false))
		ServerCommand("sm_votemap c6m1_riverbank");
	if (StrEqual(current_map, "c6m3_port", false))
		ServerCommand("sm_votemap c7m1_docks");
	if (StrEqual(current_map, "c7m3_port", false))
		ServerCommand("sm_votemap c8m1_apartment");
	if (StrEqual(current_map, "c8m5_rooftop", false))
		ServerCommand("sm_votemap c9m1_alleys");
	if (StrEqual(current_map, "c9m2_lots", false))
		ServerCommand("sm_votemap c10m1_caves");
	if (StrEqual(current_map, "c10m5_houseboat", false))
		ServerCommand("sm_votemap c11m1_greenhouse");
	if (StrEqual(current_map, "c11m5_runway", false))
		ServerCommand("sm_votemap c12m1_hilltop");
	if (StrEqual(current_map, "c12m5_cornfield", false))
		ServerCommand("sm_votemap c13m1_alpinecreek");
	if (StrEqual(current_map, "c13m4_cutthroatcreek", false))
		ServerCommand("sm_votemap c14m1_junkyard");
	if (StrEqual(current_map, "c14m2_lighthouse", false))
		ServerCommand("sm_votemap c1m1_hotel");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false) || StrEqual(current_map, "c7m3_port", false) || StrEqual(current_map, "c8m5_rooftop", false) || StrEqual(current_map, "c6m3_port", false) || StrEqual(current_map, "c9m2_lots", false) || StrEqual(current_map, "c10m5_houseboat", false) || StrEqual(current_map, "c11m5_runway", false) || StrEqual(current_map, "c12m5_cornfield", false) || StrEqual(current_map, "c13m4_cutthroatcreek", false) || StrEqual(current_map, "c14m2_lighthouse", false))
	{
		if (round_end_repeats > 0)
			PrintToChatAll("Mission failed %d time(s)", round_end_repeats);
		if (round_end_repeats > 2)
		{	
			CreateTimer(10.0, TimedVote);
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false) || StrEqual(current_map, "c7m3_port", false) || StrEqual(current_map, "c8m5_rooftop", false) || StrEqual(current_map, "c6m3_port", false) || StrEqual(current_map, "c9m2_lots", false) || StrEqual(current_map, "c10m5_houseboat", false) || StrEqual(current_map, "c11m5_runway", false) || StrEqual(current_map, "c12m5_cornfield", false) || StrEqual(current_map, "c13m4_cutthroatcreek", false) || StrEqual(current_map, "c14m2_lighthouse", false))
	{
		round_end_repeats++;
	}
}

public Action:ChangeCampaign(Handle:timer, any:client)
{
	if (StrEqual(current_map, "c1m4_atrium", false))
		ServerCommand("changelevel c2m1_highway");
	if (StrEqual(current_map, "c2m5_concert", false))
		ServerCommand("changelevel c3m1_plankcountry");
	if (StrEqual(current_map, "c3m4_plantation", false))
		ServerCommand("changelevel c4m1_milltown_a");
	if (StrEqual(current_map, "c4m5_milltown_escape", false))
		ServerCommand("changelevel 	c5m1_waterfront");
	if (StrEqual(current_map, "c5m5_bridge", false))
		ServerCommand("changelevel c6m1_riverbank");
	if (StrEqual(current_map, "c6m3_port", false))
		ServerCommand("changelevel c7m1_docks");
	if (StrEqual(current_map, "c7m3_port", false))
		ServerCommand("changelevel c8m1_apartment");
	if (StrEqual(current_map, "c8m5_rooftop", false))
		ServerCommand("changelevel c9m1_alleys");
	if (StrEqual(current_map, "c9m2_lots", false))
		ServerCommand("changelevel c10m1_caves");
	if (StrEqual(current_map, "c10m5_houseboat", false))
		ServerCommand("changelevel c11m1_greenhouse");
	if (StrEqual(current_map, "c11m5_runway", false))
		ServerCommand("changelevel c12m1_hilltop");
	if (StrEqual(current_map, "c12m5_cornfield", false))
		ServerCommand("changelevel c13m1_alpinecreek");
	if (StrEqual(current_map, "c13m4_cutthroatcreek", false))
		ServerCommand("changelevel c14m1_junkyard");
	if (StrEqual(current_map, "c14m2_lighthouse", false))
		ServerCommand("changelevel c1m1_hotel");
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

	if (StrEqual(current_map, "c1m1_hotel", false) || StrEqual(current_map, "c1m2_streets", false) || StrEqual(current_map, "c1m3_mall", false) || StrEqual(current_map, "c1m4_atrium", false))
		NextCampaign = "Dark Carnival";
	if (StrEqual(current_map, "c2m1_highway", false) || StrEqual(current_map, "c2m2_fairgrounds", false) || StrEqual(current_map, "	c2m3_coaster", false) || StrEqual(current_map, "c2m4_barns", false) || StrEqual(current_map, "c2m5_concert", false))
		NextCampaign = "Swamp Fever";
	if (StrEqual(current_map, "c3m1_plankcountry", false) || StrEqual(current_map, "c3m2_swamp", false) || StrEqual(current_map, "c3m3_shantytown", false) || StrEqual(current_map, "c3m4_plantation", false))
		NextCampaign = "Hard Rain";
	if (StrEqual(current_map, "c4m1_milltown_a", false) || StrEqual(current_map, "c4m2_sugarmill_a", false) || StrEqual(current_map, "c4m3_sugarmill_b", false) || StrEqual(current_map, "c4m4_milltown_b", false) || StrEqual(current_map, "c4m5_milltown_escape", false))
		NextCampaign = "The Parish";
	if (StrEqual(current_map, "c5m1_waterfront", false) || StrEqual(current_map, "c5m2_park", false) || StrEqual(current_map, "c5m3_cemetery", false) || StrEqual(current_map, "c5m4_quarter", false) || StrEqual(current_map, "c5m5_bridge", false))
	    NextCampaign = "The Passing";
	if (StrEqual(current_map, "c6m1_riverbank", false) || StrEqual(current_map, "c6m2_bedlam", false) || StrEqual(current_map, "c6m3_port", false))
	    NextCampaign = "The Sacrifice";
	if (StrEqual(current_map, "c7m1_docks", false) || StrEqual(current_map, "c7m2_barge", false) || StrEqual(current_map, "c7m3_port", false))
	    NextCampaign = "No Mercy";
	if (StrEqual(current_map, "c8m1_apartment", false) || StrEqual(current_map, "c8m2_subway", false) || StrEqual(current_map, "c8m3_sewers", false) || StrEqual(current_map, "c8m4_interior", false) || StrEqual(current_map, "c8m5_rooftop", false))
	    NextCampaign = "Crash Course";
	if (StrEqual(current_map, "c9m1_alleys", false) || StrEqual(current_map, "c9m2_lots", false))
	    NextCampaign = "Death Toll";
	if (StrEqual(current_map, "c10m1_caves", false) || StrEqual(current_map, "c10m2_drainage", false) || StrEqual(current_map, "c10m3_ranchhouse", false) || StrEqual(current_map, "c10m4_mainstreet", false) || StrEqual(current_map, "c10m5_houseboat", false))
	    NextCampaign = "Dead Air";
	if (StrEqual(current_map, "c11m1_greenhouse", false) || StrEqual(current_map, "c11m2_offices", false) || StrEqual(current_map, "c11m3_garage", false) || StrEqual(current_map, "c11m4_terminal", false) || StrEqual(current_map, "c11m5_runway", false))
	    NextCampaign = "Blood Harvest";
	if (StrEqual(current_map, "c12m1_hilltop", false) || StrEqual(current_map, "c12m2_traintunnel", false) || StrEqual(current_map, "c12m3_bridge", false) || StrEqual(current_map, "c12m4_barn", false) || StrEqual(current_map, "c12m5_cornfield", false))
	    NextCampaign = "Cold Stream";
	if (StrEqual(current_map, "c13m1_alpinecreek", false) || StrEqual(current_map, "c13m2_southpinestream", false) || StrEqual(current_map, "c13m3_memorialbridge", false) || StrEqual(current_map, "c13m4_cutthroatcreek", false))
	    NextCampaign = "The Last Stand";
	if (StrEqual(current_map, "c14m1_junkyard", false) || StrEqual(current_map, "c14m2_lighthouse", false))
	    NextCampaign = "Dead Center";

//	if (StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false))
//		NextCampaign = "";

	PrintToChatAll("Next campaign: %s", NextCampaign);
}