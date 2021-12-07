#include <sourcemod>
new Handle:mp_gamemode;
new String:current_map[24];
new repeats;
new round_end_repeats;

public Plugin:myinfo = 
{
	name = "[L4D2] Next Campaign",
	author = "Jonny",
	description = "",
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
	GetCurrentMap(current_map, 24);
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
	if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false) || StrEqual(current_map, "c6m3_port", false))
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
		ServerCommand("sm_votemap c5m1_waterfront");
	if (StrEqual(current_map, "c5m5_bridge", false))
		ServerCommand("sm_votemap c6m1_riverbank");
	if (StrEqual(current_map, "c6m3_port", false))
		ServerCommand("sm_votemap c1m1_hotel");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false) || StrEqual(current_map, "c6m3_port", false))
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
	if (StrEqual(current_map, "c1m4_atrium", false) || StrEqual(current_map, "c2m5_concert", false) || StrEqual(current_map, "c3m4_plantation", false) || StrEqual(current_map, "c4m5_milltown_escape", false) || StrEqual(current_map, "c5m5_bridge", false))
	{
		round_end_repeats++;
	}
}

public Action:ChangeCampaign(Handle:timer, any:client)
{
//	UnhookEvent("finale_win", Event_FinalWin);
	if (StrEqual(current_map, "c1m4_atrium", false))
		ServerCommand("changelevel c2m1_highway");
	if (StrEqual(current_map, "c2m5_concert", false))
		ServerCommand("changelevel c3m1_plankcountry");
	if (StrEqual(current_map, "c3m4_plantation", false))
		ServerCommand("changelevel c4m1_milltown_a");
	if (StrEqual(current_map, "c4m5_milltown_escape", false))
		ServerCommand("changelevel c5m1_waterfront");
	if (StrEqual(current_map, "c5m5_bridge", false))
		ServerCommand("changelevel c6m1_riverbank");
	if (StrEqual(current_map, "c6m3_port", false))
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
	if (StrEqual(current_map, "c2m1_highway", false) || StrEqual(current_map, "c2m2_fairgrounds", false) || StrEqual(current_map, "c2m3_coaster", false) || StrEqual(current_map, "c2m4_barns", false) || StrEqual(current_map, "c2m5_concert", false))
		NextCampaign = "Swamp Fever";
	if (StrEqual(current_map, "c3m1_plankcountry", false) || StrEqual(current_map, "c3m2_swamp", false) || StrEqual(current_map, "c3m3_shantytown", false) || StrEqual(current_map, "c3m4_plantation", false))
		NextCampaign = "Hard Rain";
	if (StrEqual(current_map, "c4m1_milltown_a", false) || StrEqual(current_map, "c4m2_sugarmill_a", false) || StrEqual(current_map, "c4m3_sugarmill_b", false) || StrEqual(current_map, "c4m4_milltown_b", false) || StrEqual(current_map, "c4m5_milltown_escape", false))
		NextCampaign = "The Paris";
	if (StrEqual(current_map, "c5m1_waterfront", false) || StrEqual(current_map, "c5m2_park", false) || StrEqual(current_map, "c5m3_cemetery", false) || StrEqual(current_map, "c5m4_quarter", false) || StrEqual(current_map, "c5m5_bridge", false))
		NextCampaign = "The Passing";
	if (StrEqual(current_map, "c6m1_riverbank", false) || StrEqual(current_map, "c6m2_bedlam", false) || StrEqual(current_map, "c6m3_port", false))
		NextCampaign = "Dead Center";

//	if (StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false) || StrEqual(current_map, "", false))
//		NextCampaign = "";

	PrintToChatAll("\x05Next campaign: \x04%s", NextCampaign);
}