#pragma semicolon 1

#include <sourcemod>

#define VERSION "0.1"

public Plugin:myinfo = {
	name = "TF2: Random Bot Difficulty",
	author = "Nightgunner5",
	description = "Give TF2 bots random difficulty levels between an administrator-defined maximum and minimum",
	version = VERSION
};

new Handle:sm_tf_bot_difficulty_min = INVALID_HANDLE;
new Handle:sm_tf_bot_difficulty_max = INVALID_HANDLE;
new Handle:tf_bot_difficulty = INVALID_HANDLE;

public OnPluginStart() {
	sm_tf_bot_difficulty_min = CreateConVar("sm_tf_bot_difficulty_min", "0", "The minimum allowed difficulty for a TF2 bot", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	sm_tf_bot_difficulty_max = CreateConVar("sm_tf_bot_difficulty_max", "3", "The maximum allowed difficulty for a TF2 bot", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	CreateConVar("sm_tf_bot_difficulty_version", VERSION, "TF2: Random Bot Difficulty version", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	tf_bot_difficulty = FindConVar("tf_bot_difficulty");

	if ( GetConVarInt( sm_tf_bot_difficulty_min ) <= GetConVarInt( sm_tf_bot_difficulty_max ) )
		SetConVarInt( tf_bot_difficulty, GetURandomInt() %
			( GetConVarInt( sm_tf_bot_difficulty_max ) -
			GetConVarInt( sm_tf_bot_difficulty_min ) + 1 ) +
			GetConVarInt( sm_tf_bot_difficulty_min ) );
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	if ( GetConVarInt( sm_tf_bot_difficulty_min ) <= GetConVarInt( sm_tf_bot_difficulty_max ) )
		SetConVarInt( tf_bot_difficulty, GetURandomInt() %
			( GetConVarInt( sm_tf_bot_difficulty_max ) -
			GetConVarInt( sm_tf_bot_difficulty_min ) + 1 ) +
			GetConVarInt( sm_tf_bot_difficulty_min ) );

	return true;
}