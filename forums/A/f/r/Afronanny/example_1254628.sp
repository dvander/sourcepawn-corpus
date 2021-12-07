
#include <sourcemod>


forward OnGetPlayer(client);
forward OnCalculateTeamBalanceScore(client, score);

public Extension:__ext_teambalanceimmunity =
{
	name = "Team Balance Immunity",
	file = "teambalanceimmunity.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

public Plugin:myinfo = 
{
	name = "Team Balance Immunity",
	author = "Afronanny",
	description = "Autobalance Immunity",
	version = "1.3.1",
	url = "http://code.google.com/p/tf2balanceimmunity/"
}

public OnGetPlayer(client)
{
	if (IsClientInGame(client))
	{
		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
		{
			return false;
		}
	}
	return true;
}

public OnCalculateTeamBalanceScore(client, score)
{
	if (IsClientInGame(client))
	{
		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
		{
			return -2147473547;
		} else {
			return score;
		}
	}
}
