#include <sourcemod>
#include <gungame>

public Plugin:myinfo =
{
	name = "GunGame:SM Map Vote Starter",
	author = AUTHOR,
	description = "Start the map voting for next map [fixed by ifx]",
	version = GG_VERSION,
	url = "http://www.hat-city.net/"
};

public GG_OnStartMapVote()
{
	InsertServerCommand("exec gungame//gungame.mapvote.cfg");
}