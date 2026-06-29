#define PLUGIN_VERSION "1.0.2"
/*
		Pre-processor declarations
										*/
#include <sourcemod>
#include <sdktools>
new SpitterActive[MAXPLAYERS + 1];
new Tagged[MAXPLAYERS + 1];
new Connected[MAXPLAYERS + 1];
new Spitter_Connected[MAXPLAYERS + 1];
new Infected_Player[MAXPLAYERS + 1];
new Handle:fBoomerTime;
new Handle:fSpitterTime;
new Handle:fTwoWay;
new RoundHasStarted;
new RoundHasEnded;




public Plugin:myinfo = 
{
	name = "SnareSpeak",
	author = "Sky",
	description = "Can talk to your victim and vice-versa",
	version = PLUGIN_VERSION,
	url = "http://sky-gaming.org"
}

public OnPluginStart()
{
	CreateConVar("snarespeak_ver", PLUGIN_VERSION, "snarespeak_ver", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	fBoomerTime = CreateConVar("snarespeak_boomer_time","10.0","How long boomers can talk to biled players.");
	fSpitterTime = CreateConVar("snarespeak_spitter_time","10.0","How long spitters can talk to their victims.");
	fTwoWay = CreateConVar("snarespeak_twoway","1","If enabled allows attacker and victim to hear each other. Otherwise only the attacker can hear the victim.");
	AutoExecConfig(true, "snarespeak");

	HookEvent("lunge_pounce", Event_PlayerGrabbed);
	HookEvent("tongue_grab", Event_PlayerGrabbed);
	HookEvent("jockey_ride", Event_PlayerGrabbed);
	HookEvent("charger_pummel_start", Event_PlayerGrabbed);
	HookEvent("charger_carry_start", Event_PlayerGrabbed);
	HookEvent("jockey_ride_end", Event_PlayerRelease);
	HookEvent("charger_carry_end", Event_PlayerRelease);
	HookEvent("charger_pummel_end", Event_PlayerRelease);
	HookEvent("pounce_end", Event_PlayerRelease);
	HookEvent("tongue_release", Event_PlayerRelease);
	HookEvent("player_now_it", Event_PlayerTagged);
	HookEvent("player_no_longer_it", Event_PlayerUnTagged);
	HookEvent("round_start", Round_Start);
	HookEvent("round_end", Round_End);
	HookEvent("tank_spawn", Event_PlayerRelease);
	HookEvent("player_team", Event_PlayerTeamSwitch);
	HookEvent("player_hurt", Event_TaggedInSpit);
	HookEvent("ability_use", Event_CheckForSpitter);
	HookEvent("player_death", Event_ClearSpitter);
}

public OnMapStart()
{
	RoundHasStarted = 0;
	RoundHasEnded = 0;
	PrintToChatAll("\x04Snarespeak 1.0.2 \x05Loaded");
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundHasStarted++;
	if (RoundHasStarted == 1)
	{
		SetConVarInt(FindConVar("sv_alltalk"), false);
		PrintToChatAll("\x04Alltalk \x05Disabled");
	}
}

public Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundHasEnded++;
	decl other_player;

	if (RoundHasEnded == 1)
	{
		SetConVarInt(FindConVar("sv_alltalk"), true);
		PrintToChatAll("\x04Alltalk \x05Enabled");
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGameHuman(i)) continue;
		SpitterActive[i] = 0;
		Tagged[i] = 0;
		if (Connected[i] != 0)
		{
			other_player = Connected[i];
			SetListenOverride(i, other_player, Listen_No);
			SetListenOverride(other_player, i, Listen_No);
		}
		if (Spitter_Connected[i] != 0)
		{
			other_player = Spitter_Connected[i];
			SetListenOverride(i, other_player, Listen_No);
			SetListenOverride(other_player, i, Listen_No);
		}
	}
}

public Event_ClearSpitter(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGameHuman(victim) && SpitterActive[victim] == 1) SpitterActive[victim] = 0;
}

public Event_TaggedInSpit(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));
	if (!bAllTalk && IsClientInGameHuman(attacker) && IsClientInGameHuman(victim) && SpitterActive[attacker] == 1)
	{
		/*
		if (Connected[victim] != attacker)
		{
			decl old_attacker;
			old_attacker = Connected[victim];

			SetListenOverride(victim, old_attacker, Listen_No);
			SetListenOverride(old_attacker, victim, Listen_No);
			if (!bAllTalk)
			{
				if (GetConVarInt(fTwoWay) == 1)
				{
					PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", old_attacker);
					PrintToChat(old_attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
				}
				else PrintToChat(old_attacker, "\x05No Longer Listening to \x03%N", victim);
			}
		}
		*/
		if (Spitter_Connected[victim] == attacker) return;		// To prevent multiple channel openings with same player.
		Spitter_Connected[victim] = attacker;
		//Tagged[victim] = 1;
		CreateTimer(GetConVarFloat(fSpitterTime), SpitterTimer, victim);

		if (GetConVarInt(fTwoWay) == 1) SetListenOverride(victim, attacker, Listen_Yes);
		SetListenOverride(attacker, victim, Listen_Yes);

		if (GetConVarInt(fTwoWay) == 1) PrintToChat(victim, "\x05Voice Channel Created with \x03%N.", attacker);
		PrintToChat(attacker, "\x05Voice Channel Created with \x03%N.", victim);
	}
}

public Action:Event_CheckForSpitter(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:abilityused[128];
	GetEventString(event, "ability", abilityused, sizeof(abilityused));
	if (StrContains(abilityused, "spit", true) > -1) SpitterActive[client] = 1;
}

public Event_PlayerGrabbed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new bool:bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));


	if (!bAllTalk && IsClientInGameHuman(attacker) && IsClientInGameHuman(victim))
	{
		Connected[attacker] = victim;
		Infected_Player[victim] = attacker;
		if (GetConVarInt(fTwoWay) == 1) SetListenOverride(victim, attacker, Listen_Yes);
		SetListenOverride(attacker, victim, Listen_Yes);

		if (GetConVarInt(fTwoWay) == 1)
		{
			PrintToChat(victim, "\x05Voice Channel Created with \x03%N.", attacker);
			PrintToChat(attacker, "\x05Voice Channel Created with \x03%N.", victim);
		}
		else PrintToChat(attacker, "\x05Listening to \x03%N", victim);
	}
}

public Event_PlayerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = Infected_Player[victim];
	new bool:bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));

	if (IsClientInGameHuman(victim) && IsClientInGameHuman(attacker))
	{
		SetListenOverride(victim, attacker, Listen_No);
		SetListenOverride(attacker, victim, Listen_No);

		if (!bAllTalk)
		{
			if (GetConVarInt(fTwoWay) == 1)
			{
				PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", attacker);
				PrintToChat(attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
			}
			else PrintToChat(attacker, "\x05No Longer Listening to \x03%N", victim);
		}
	}
}

public Event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));
	if (IsClientInGameHuman(victim))
	{
		new bool:disconnect = GetEventBool(event, "disconnect");
		if (!disconnect && !bAllTalk)
		{
			new attacker;
			if (Infected_Player[victim] != 0) attacker = Infected_Player[victim];
			else if (Connected[victim] != 0) attacker = Connected[victim];

			SetListenOverride(victim, attacker, Listen_No);
			SetListenOverride(attacker, victim, Listen_No);

			if (!bAllTalk)
			{
				if (GetConVarInt(fTwoWay) == 1)
				{
					PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", attacker);
					PrintToChat(attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
				}
				else PrintToChat(attacker, "\x05No Longer Listening to \x03%N", victim);
			}
		}
	}
}

public Event_PlayerTagged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));

	if (!bAllTalk && IsClientInGameHuman(attacker) && IsClientInGameHuman(victim))
	{
		if (Connected[victim] != 0)
		{
			decl old_attacker;
			old_attacker = Connected[victim];

			SetListenOverride(victim, old_attacker, Listen_No);
			SetListenOverride(old_attacker, victim, Listen_No);
			if (!bAllTalk)
			{
				if (GetConVarInt(fTwoWay) == 1)
				{
					PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", old_attacker);
					PrintToChat(old_attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
				}
				else PrintToChat(old_attacker, "\x05No Longer Listening to \x03%N", victim);
			}
		}
		Connected[victim] = attacker;

		CreateTimer(GetConVarFloat(fBoomerTime), BoomerTimer, victim);

		if (GetConVarInt(fTwoWay) == 1) SetListenOverride(victim, attacker, Listen_Yes);
		SetListenOverride(attacker, victim, Listen_Yes);

		if (GetConVarInt(fTwoWay) == 1)
		{
			PrintToChat(victim, "\x05Voice Channel Created with \x03%N.", attacker);
			PrintToChat(attacker, "\x05Voice Channel Created with \x03%N.", victim);
		}
		else PrintToChat(attacker, "\x05Listening to \x03%N", victim);
	}
}

public Event_PlayerUnTagged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarFloat(fBoomerTime) == 0.0) CloseBoomerChannel(victim);
}

public Action:BoomerTimer(Handle:timer, any:victim)
{
	CloseBoomerChannel(victim);
}

public CloseBoomerChannel(victim)
{
	if (Connected[victim] != 0)
	{
		decl attacker;
		attacker = Connected[victim];
		decl bool:bAllTalk;
		bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));
		if (IsClientInGameHuman(attacker) && IsClientInGameHuman(victim))
		{
			SetListenOverride(victim, attacker, Listen_No);
			SetListenOverride(attacker, victim, Listen_No);

			Connected[victim] = 0;
			Tagged[victim] = 0;

			if (!bAllTalk)
			{
				if (GetConVarInt(fTwoWay) == 1)
				{
					PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", attacker);
					PrintToChat(attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
				}
				else PrintToChat(attacker, "\x05No Longer Listening to \x03%N", victim);
			}
		}
	}
}

public Action:SpitterTimer(Handle:timer, any:victim)
{
	CloseSpitterChannel(victim);
}

public CloseSpitterChannel(victim)
{
	if (Spitter_Connected[victim] != 0)
	{
		decl attacker;
		attacker = Spitter_Connected[victim];
		decl bool:bAllTalk;
		bAllTalk = GetConVarBool(FindConVar("sv_alltalk"));
		if (IsClientInGameHuman(attacker) && IsClientInGameHuman(victim))
		{
			SetListenOverride(victim, attacker, Listen_No);
			SetListenOverride(attacker, victim, Listen_No);

			Spitter_Connected[victim] = 0;
			Tagged[victim] = 0;

			if (!bAllTalk)
			{
				if (GetConVarInt(fTwoWay) == 1)
				{
					PrintToChat(victim, "\x05Voice Channel Destroyed with \x03%N.", attacker);
					PrintToChat(attacker, "\x05Voice Channel Destroyed with \x03%N.", victim);
				}
				else PrintToChat(attacker, "\x05No Longer Listening to \x03%N", victim);
			}
		}
	}
}

stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}