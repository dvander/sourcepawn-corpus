#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo = {
	name = "Bots Movement",
	author = "alasfourom",
	description = "Allowing Players To Control Bots Movement and Restarting Rounds",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
}

public void OnPluginStart() 
{
	RegAdminCmd("sm_slay_witch", Command_SlayWitch, ADMFLAG_SLAY, "Slay All Witches");
	RegAdminCmd("sm_slay_common", Command_SlayCommon, ADMFLAG_SLAY, "Slay All Commons");
	RegAdminCmd("sm_stop", Command_NbStop, ADMFLAG_SLAY, "Force Survivor and SI Bots To Stop");
	RegAdminCmd("sm_move", Command_NbMove, ADMFLAG_SLAY, "Force Survivor and SI Bots To Stop");
	RegAdminCmd("sm_hold", Command_Hold, ADMFLAG_SLAY, "Force Director To Stop All Bots");
	RegAdminCmd("sm_unhold", Command_UnHold, ADMFLAG_SLAY, "Force Director To Move All Bots");
	RegAdminCmd("sm_restart", Command_RestartRound, ADMFLAG_SLAY, "Force Restarting Round");
	RegAdminCmd("sm_rr", Command_RestartRound, ADMFLAG_SLAY, "Force Restarting Round");

	HookEvent("round_end", OnRoundEnd);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy);
}

Action Command_SlayWitch(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "witch")) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(i_EdictIndex);
		count++;
	}
	return Plugin_Handled;
}

Action Command_SlayCommon(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "infected")) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(i_EdictIndex);
		count++;
	}
	return Plugin_Handled;
}

public void Command_SlaySpecial(int client)
{
	int count;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 )
		{
			RemoveEntity(i);
			count++;
		}
	}
}

public Action Command_NbStop(int client, int args)
{
	Command_SlayWitch(client, 0);
	Command_SlayCommon(client, 0);
	Command_SlaySpecial(client);
	SetConVarInt(FindConVar("nb_player_stop"), 1);
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("director_no_mobs"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	SetConVarInt(FindConVar("z_boomer_limit"), 0);
	SetConVarInt(FindConVar("z_charger_limit"), 0);
	SetConVarInt(FindConVar("z_hunter_limit"), 0);
	SetConVarInt(FindConVar("z_jockey_limit"), 0);
	SetConVarInt(FindConVar("z_smoker_limit"), 0);
	SetConVarInt(FindConVar("z_spitter_limit"), 0);
	SetConVarInt(FindConVar("z_versus_boomer_limit"), 0);
	SetConVarInt(FindConVar("z_versus_charger_limit"), 0);
	SetConVarInt(FindConVar("z_versus_hunter_limit"), 0);
	SetConVarInt(FindConVar("z_versus_jockey_limit"), 0);
	SetConVarInt(FindConVar("z_versus_smoker_limit"), 0);
	SetConVarInt(FindConVar("z_versus_spitter_limit"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);		
	PrintToChatAll("\x04[SM] \x01Admin \x03%N\x01, has forced the bots to \x05STOP\x01.", client);
	return Plugin_Handled;
}

public Action Command_NbMove(int client, int args)
{
	SetConVarInt(FindConVar("nb_player_stop"), 0);
	ResetConVar(FindConVar("director_no_bosses"));
	ResetConVar(FindConVar("director_no_mobs"));
	ResetConVar(FindConVar("director_no_specials"));
	ResetConVar(FindConVar("z_boomer_limit"));
	ResetConVar(FindConVar("z_charger_limit"));
	ResetConVar(FindConVar("z_hunter_limit"));
	ResetConVar(FindConVar("z_jockey_limit"));
	ResetConVar(FindConVar("z_smoker_limit"));
	ResetConVar(FindConVar("z_spitter_limit"));
	ResetConVar(FindConVar("z_versus_boomer_limit"));
	ResetConVar(FindConVar("z_versus_charger_limit"));
	ResetConVar(FindConVar("z_versus_hunter_limit"));
	ResetConVar(FindConVar("z_versus_jockey_limit"));
	ResetConVar(FindConVar("z_versus_smoker_limit"));
	ResetConVar(FindConVar("z_versus_spitter_limit"));
	ResetConVar(FindConVar("z_common_limit"));	
	PrintToChatAll("\x04[SM] \x01Admin \x03%N\x01, has forced the bots to \x05MOVE\x01.", client);
	return Plugin_Handled;
}

public Action Command_Hold(int client, int args)
{
	SetConVarInt(FindConVar("nb_stop"), 1);
	PrintToChatAll("\x04[SM] \x01Admin \x03%N\x01, has forced the director to \x05Hold\x01.", client);
	return Plugin_Handled;
}

public Action Command_UnHold(int client, int args)
{
	SetConVarInt(FindConVar("nb_stop"), 0);
	PrintToChatAll("\x04[SM] \x01Admin \x03%N\x01, has forced the director to \x05UnHold\x01.", client);
	return Plugin_Handled;
}

public Action Command_RestartRound(int client, int args)
{
	SetConVarInt(FindConVar("mp_restartgame"), 1);
	PrintToChatAll("\x04[SM] \x01Admin \x03%N\x01, has \x05Restarted\x01 the round.", client);
	return Plugin_Handled;
}

public Action OnRoundStart(Handle event, const char[] event_name, bool dontBroadcast)
{
	SetConVarInt(FindConVar("sb_unstick"), 0);
	return Plugin_Handled;
}

public Action OnRoundEnd(Handle event, const char[] event_name, bool dontBroadcast)
{
	SetConVarInt(FindConVar("sb_unstick"), 0);
	return Plugin_Handled;
}

public LeftStartAreaEvent(Handle event, const char[] event_name, bool dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && !IsFakeClient(client))
			SetConVarInt(FindConVar("sb_unstick"), 1);
}