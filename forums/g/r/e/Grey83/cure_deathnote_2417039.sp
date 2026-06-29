#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"[CURE] Death Notifications"

float last;

public Plugin myinfo =
{
	name		=PLUGIN_NAME,
	author		= "Grey83",
	description	= "Shows a message when the player dies or gets damaged by another player",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=282396"
};

public OnPluginStart()
{
	CreateConVar("cure_deathnote_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_death", Event_PD);
	HookEvent( "player_hurt", Event_PH );
}

public OnMapStart() last=0.0;

public Event_PD(Event event, const char[] name, bool dontBroadcast)
{

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attaker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	ReplaceString(weapon, sizeof(weapon), "_projectile", "");
	ReplaceString(weapon, sizeof(weapon), "crowbar", "fists");

	if (0 < victim <= MaxClients)
	{
		if(!attaker)
		{
			if (StrContains(weapon, "zombine") == 0)
			{
				PrintToChatAll("\x04%N \x03killed by zombie", victim);
				PrintToServer("%N killed by zombie", victim);
			}
			else
			{
				PrintToChatAll("\x04%N \x03crushed to death", victim);
				PrintToServer("%N crushed to death", victim);
			}
		}
		else if(0 < attaker <= MaxClients)
		{
			if(victim != attaker)
			{
				PrintToChatAll("\x04%N \x03killed by \x04%N \x03with \x04%s", victim, attaker, weapon);
				PrintToServer("%N killed by %N with %s", victim, attaker, weapon);
			}
			else
			{
				PrintToChatAll("\x04%N \x03killed himself with \x04%s", victim, weapon);
				PrintToServer("%N killed himself with %s", victim, weapon);
			}
		}
	}
}

public Event_PH(Event event, const char[] name, bool dontBroadcast)
{

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attaker = GetClientOfUserId(event.GetInt("attacker"));
	float time = GetGameTime();

	if(victim != attaker && 0 < victim <= MaxClients && 0 < attaker <= MaxClients && IsClientInGame(attaker) && (time - last) > 3.0)
	{
		last = time;
		PrintToChatAll("\x04%N \x03has attacked \x04%N", attaker, victim);
	}
}