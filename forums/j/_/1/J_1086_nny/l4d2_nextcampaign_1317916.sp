#include <sourcemod>

#define DEBUG false
#define CUSTOM_MAPS false

new Handle:mp_gamemode;
new String:current_map[24];
new IsRoundStarted = false;
new repeats;
new round_end_repeats;

public Plugin:myinfo = 
{
	name = "[L4D2] Next Campaign",
	author = "Jonny",
	description = "",
	version = "1.8",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	mp_gamemode = FindConVar("mp_gamemode");
	HookEvent("finale_win", Event_FinalWin);
//	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

stock GetGameMode()
{
	new String:GameMode[13];
	new Handle:gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamecvar_mp_gamemode, GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "coop", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "realism", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "survival", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "versus", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "teamversus", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "scavenge", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "teamscavenge", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "mutation3", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "mutation12", false) == true)
	{
		return 2;
	}
	return 0;
}

stock IsFinalMap()
{
	if (StrEqual(current_map, "c1m4_atrium", false)
	|| StrEqual(current_map, "c2m5_concert", false)
	|| StrEqual(current_map, "c3m4_plantation", false)
	|| StrEqual(current_map, "c4m5_milltown_escape", false)
	|| StrEqual(current_map, "c5m5_bridge", false)
	|| StrEqual(current_map, "c6m3_port", false)
	|| StrEqual(current_map, "c7m3_port", false)
	|| StrEqual(current_map, "c8m5_rooftop", false)
	|| StrEqual(current_map, "2ee_06_deadend", false)
	|| StrEqual(current_map, "cdta_05finalroad", false)
	|| StrEqual(current_map, "cwm4_building", false)
	|| StrEqual(current_map, "l4d_deathaboard05_light", false)
	|| StrEqual(current_map, "l4d_orange05_fifth", false)
	|| StrEqual(current_map, "l4d2_city17_05", false)
	|| StrEqual(current_map, "l4d2_deadcity06_station", false)
	|| StrEqual(current_map, "indiana_adventure3", false)
	|| StrEqual(current_map, "hf03_escape", false))
	{
		return true;
	}
	return false;
}

public OnMapStart()
{
#if DEBUG
	PrintToChatAll("\x05Event: \x04%s", "OnMapStart()");
#endif
	
	GetCurrentMap(current_map, 24);
	decl String:GameMode[16];
	GetConVarString(mp_gamemode, GameMode, sizeof(GameMode));

	if (GetGameMode() == 1)
		repeats = 1;
	if (GetGameMode() == 2)
		repeats = 3;
	
	round_end_repeats = 0;
}

public Action:Event_FinalWin(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG
	PrintToChatAll("\x05Event: \x04%s", "OnFinalWin()");
#endif
	if (IsFinalMap() && GetGameMode() == 1)
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
{ // Порядок следования: Blood Orange -> 2 Evil Eyes -> Detour Ahead -> Death Aboard 2 -> Carried Off -> Haunted Forest -> Blood Orange
	ChangeCampaignEx(2);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG
	PrintToChatAll("\x05Event: \x04%s", "RoundStart()");
#endif
	IsRoundStarted = true;
	if (IsFinalMap())
	{
		if (round_end_repeats > 0 && GetGameMode() == 1)
			PrintToChatAll("\x05Mission failed \x01%d\x05 time(s)", round_end_repeats);
		if (round_end_repeats > 2)
		{	
			CreateTimer(10.0, TimedVote);
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG
	PrintToChatAll("\x05Event: \x04%s", "RoundEnd()");
#endif
	if (!IsRoundStarted)
	{
		return;
	}
	if (IsFinalMap())
	{
		round_end_repeats++;
	}
	if (GetGameMode() == 2)
	{
		if (IsFinalMap())
		{
			repeats--;
			if (repeats < 1)
			{
				PrintNextCampaign();
				CreateTimer(8.5, ChangeCampaign);
			}
		}	
	}
}

public Action:ChangeCampaign(Handle:timer, any:client)
{
	ChangeCampaignEx(1);
}

#if CUSTOM_MAPS
	public ChangeCampaignEx(mode)
	{ // Порядок следования: Blood Orange -> 2 Evil Eyes -> City 17 -> Detour Ahead -> Death Aboard 2 -> Carried Off -> Haunted Forest -> DeadCity II -> Blood Orange
	// cdta_* : detour ahead
	// hf* : haunted forest
		decl String:Command[24];
		switch(mode)
		{
			case 1: Command = "changelevel";
			case 2: Command = "sm_votemap";
		}
		if (StrEqual(current_map, "l4d_orange05_fifth", false))
		{
			ServerCommand("%s 2ee_01_deadlybeggining", Command);
			return;
		}
		if (StrEqual(current_map, "2ee_06_deadend", false))
		{
			ServerCommand("%s l4d2_city17_01", Command);
			return;
		}
		if (StrEqual(current_map, "l4d2_city17_05", false))
		{
			ServerCommand("%s cdta_01detour", Command);
			return;
		}
		if (StrEqual(current_map, "cdta_05finalroad", false))
		{
			ServerCommand("%s l4d_deathaboard01_prison", Command);
			return;
		}
		if (StrEqual(current_map, "l4d_deathaboard05_light", false))
		{
			ServerCommand("%s  cwm1_intro", Command);
			return;
		}	
		if (StrEqual(current_map, "cwm4_building", false))
		{
			ServerCommand("%s hf01_theforest", Command);
			return;
		}	
		if (StrEqual(current_map, "hf03_escape", false))
		{
			ServerCommand("%s l4d2_deadcity01_riverside", Command);
			return;
		}	
		if (StrEqual(current_map, "l4d2_deadcity06_station", false))
		{
			ServerCommand("%s l4d_orange01_first", Command);
			return;
		}	

		ServerCommand("%s l4d_orange01_first", Command);
	}
	
	PrintNextCampaign()
	{ // Порядок следования: Blood Orange -> 2 Evil Eyes -> City 17 -> Detour Ahead -> Death Aboard 2 -> Carried Off -> Haunted Forest -> DeadCity II -> Blood Orange
		decl String:NextCampaign[40];
		
		NextCampaign = "Blood Orange";

		if (StrEqual(current_map, "l4d_orange01_first", false) || StrEqual(current_map, "l4d_orange02_second", false) || StrEqual(current_map, "l4d_orange03_third", false) || StrEqual(current_map, "l4d_orange04_fourth", false) || StrEqual(current_map, "l4d_orange05_fifth", false))
			NextCampaign = "2 Evil Eyes"; // "Detour Ahead";
		if (StrEqual(current_map, "2ee_01_deadlybeggining", false) || StrEqual(current_map, "2ee_02_bridgefinal", false) || StrEqual(current_map, "2ee_03_deadstop", false) || StrEqual(current_map, "2ee_04_deadtrain", false) || StrEqual(current_map, "2ee_05_deadstorm", false) || StrEqual(current_map, "2ee_06_deadend", false))
			NextCampaign = "City 17"; // "Blood Orange";
		if (StrEqual(current_map, "l4d2_city17_01", false) || StrEqual(current_map, "l4d2_city17_02", false) || StrEqual(current_map, "l4d2_city17_03", false) || StrEqual(current_map, "l4d2_city17_04", false) || StrEqual(current_map, "l4d2_city17_05", false))
			NextCampaign = "Detour Ahead";
		if (StrEqual(current_map, "cdta_01detour", false) || StrEqual(current_map, "cdta_02road", false) || StrEqual(current_map, "cdta_03warehouse", false) || StrEqual(current_map, "cdta_04onarail", false) || StrEqual(current_map, "cdta_05finalroad", false))
			NextCampaign = "Death Aboard 2";
		if (StrEqual(current_map, "l4d_deathaboard01_prison", false) || StrEqual(current_map, "l4d_deathaboard02_yard", false) || StrEqual(current_map, "l4d_deathaboard03_docks", false) || StrEqual(current_map, "l4d_deathaboard04_ship", false) || StrEqual(current_map, "l4d_deathaboard05_light", false))
			NextCampaign = "Carried Off";
		if (StrEqual(current_map, "cwm1_intro", false) || StrEqual(current_map, "cwm2_warehouse", false) || StrEqual(current_map, "cwm3_drain", false) || StrEqual(current_map, "cwm4_building", false))
			NextCampaign = "Haunted Forest";
		if (StrEqual(current_map, "hf01_theforest", false) || StrEqual(current_map, "hf02_themansion", false) || StrEqual(current_map, "hf03_escape", false))
			NextCampaign = "DeadCity II";

		PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
	}
#else
	public ChangeCampaignEx(mode)
	{ // Порядок следования: 
	// cdta_* : detour ahead
	// hf* : haunted forest
		decl String:Command[24];
		switch(mode)
		{
			case 1: Command = "changelevel";
			case 2: Command = "sm_votemap";
		}
		if (StrEqual(current_map, "c7m3_port", false))
		{
			ServerCommand("%s c8m1_apartment", Command);
			return;
		}
		if (StrEqual(current_map, "c8m5_rooftop", false))
		{
			ServerCommand("%s c1m1_hotel", Command);
			return;
		}
		if (StrEqual(current_map, "c1m4_atrium", false))
		{
			ServerCommand("%s c6m1_riverbank", Command);
			return;
		}
		if (StrEqual(current_map, "c6m3_port", false))
		{
			ServerCommand("%s c2m1_highway", Command);
			return;
		}
		if (StrEqual(current_map, "c2m5_concert", false))
		{
			ServerCommand("%s  c3m1_plankcountry", Command);
			return;
		}	
		if (StrEqual(current_map, "c3m4_plantation", false))
		{
			ServerCommand("%s c4m1_milltown_a", Command);
			return;
		}	
		if (StrEqual(current_map, "c4m5_milltown_escape", false))
		{
			ServerCommand("%s c5m1_waterfront", Command);
			return;
		}	
		if (StrEqual(current_map, "c5m5_bridge", false))
		{
			ServerCommand("%s c7m1_docks", Command);
			return;
		}	

		ServerCommand("%s c8m1_apartment", Command);
	}
	
	PrintNextCampaign()
	{ // Порядок следования: Blood Orange -> 2 Evil Eyes -> City 17 -> Detour Ahead -> Death Aboard 2 -> Carried Off -> Haunted Forest -> DeadCity II -> Blood Orange
		decl String:NextCampaign[40];
		
		NextCampaign = "No Mercy";

		if (StrEqual(current_map, "c8m1_apartment", false) || StrEqual(current_map, "c8m2_subway", false) || StrEqual(current_map, "c8m3_sewers", false) || StrEqual(current_map, "c8m4_interior", false) || StrEqual(current_map, "c8m5_rooftop", false))
			NextCampaign = "Dead Center";
		if (StrEqual(current_map, "c1m1_hotel", false) || StrEqual(current_map, "c1m2_streets", false) || StrEqual(current_map, "c1m3_mall", false) || StrEqual(current_map, "c1m4_atrium", false))
			NextCampaign = "The Passing";
		if (StrEqual(current_map, "c6m1_riverbank", false) || StrEqual(current_map, "c6m2_bedlam", false) || StrEqual(current_map, "c6m3_port", false))
			NextCampaign = "Dark Carnival";
		if (StrEqual(current_map, "c2m1_highway", false) || StrEqual(current_map, "c2m2_fairgrounds", false) || StrEqual(current_map, "c2m3_coaster", false) || StrEqual(current_map, "c2m4_barns", false) || StrEqual(current_map, "c2m5_concert", false))
			NextCampaign = "Swamp Fever";
		if (StrEqual(current_map, "c3m1_plankcountry", false) || StrEqual(current_map, "c3m2_swamp", false) || StrEqual(current_map, "c3m3_shantytown", false) || StrEqual(current_map, "c3m4_plantation", false))
			NextCampaign = "Hard Rain";
		if (StrEqual(current_map, "c4m1_milltown_a", false) || StrEqual(current_map, "c4m2_sugarmill_a", false) || StrEqual(current_map, "c4m3_sugarmill_b", false) || StrEqual(current_map, "c4m4_milltown_b", false) || StrEqual(current_map, "c4m5_milltown_escape", false))
			NextCampaign = "The Parish";
		if (StrEqual(current_map, "c5m1_waterfront", false) || StrEqual(current_map, "c5m2_park", false) || StrEqual(current_map, "c5m3_cemetery", false) || StrEqual(current_map, "c5m4_quarter", false) || StrEqual(current_map, "c5m5_bridge", false))
			NextCampaign = "The Sacrifice";
		if (StrEqual(current_map, "c7m1_docks", false) || StrEqual(current_map, "c7m2_barge", false) || StrEqual(current_map, "c7m3_port", false))
			NextCampaign = "No Mercy";

		PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
	}	
#endif

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