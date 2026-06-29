#pragma semicolon 1 

#include <sourcemod> 
#include <sdktools> 
#include <sdktools_functions>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

// 7 - Map (Alive) - SAFE - 2
// 8 - Map (No Incap) - NO TRIPPING - 2
// 9 - Map (No Damage) - ZOMBIE GOD - 2
// 14 - Vomited (No Damage) - NO PUKING - 5
// 15 - Explosive/Fire Kill - C4 BINGO - 10
// 18 - Witch Hunter - DOMESTIC VOILENCE - 5
// 21 - Hunter AntiJump - NO JUMPING - 10
// 22 - Melee Kill - BOXING CHAMP - 10
// 27 - Tongue Twister - NO SMOKING - 5
// 66 - Revive - TRUSTED HANDS - 5
// 67 - Protect Player - BACK 2 BACK - 10
// 68 - Give Pills - DRUG RAPE - 10
// 69 - Give Medkit - DOCTOR GAMES - 5
// 74 - Ledge Save - CLIFF HANGER - 5
// 75 - Protect From Hunter / Smoker - UNPINNED - 5
// 79 - Hero Closet - NEW FRIENDS - 10
// 80 - Tank Killed (No DMG) - ANNIHILATOR - 5
// 83 - Team Killer - MURDERER - 5
// 84 - Ally Incapacited - FALSE AIM - 10
// 85 - Ally Died No Help - LEFT 2 DIE - 5
// 86 - Friendly Fire - BLIND FIRE - 10
// 87 - Run Into Friendly Fire - TARGET - 10
// 93 - Witch Startled - HEARTBREAKER - 10
// 94 - Infected In Safe - ZOMBIEROOM - 10
// 97 - Ally Died - DEATH WARRENT - 5
// 98 - All Dead - LEFT 4 DEAD - 3

public Plugin:myinfo =
{
    name = "Custom Achievements",
    author = "Marcus101RR",
    description = "Announces Custom Achievements.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}

new iAwardID07[MAXPLAYERS + 1];
new iAwardID08[MAXPLAYERS + 1];
new iAwardID09[MAXPLAYERS + 1];
new iAwardID14[MAXPLAYERS + 1];
new iAwardID15[MAXPLAYERS + 1];
new iAwardID18[MAXPLAYERS + 1];
new iAwardID21[MAXPLAYERS + 1];
new iAwardID22[MAXPLAYERS + 1];
new iAwardID27[MAXPLAYERS + 1];
new iAwardID66[MAXPLAYERS + 1];
new iAwardID67[MAXPLAYERS + 1];
new iAwardID68[MAXPLAYERS + 1];
new iAwardID69[MAXPLAYERS + 1];
new iAwardID74[MAXPLAYERS + 1];
new iAwardID75[MAXPLAYERS + 1];
new iAwardID79[MAXPLAYERS + 1];
new iAwardID80[MAXPLAYERS + 1];
new iAwardID83[MAXPLAYERS + 1];
new iAwardID84[MAXPLAYERS + 1];
new iAwardID85[MAXPLAYERS + 1];
new iAwardID86[MAXPLAYERS + 1];
new iAwardID87[MAXPLAYERS + 1];
new iAwardID93[MAXPLAYERS + 1];
new iAwardID94[MAXPLAYERS + 1];
new iAwardID97[MAXPLAYERS + 1];
new iAwardID98[MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("award_earned", Achievement_Earned);
}

public Achievement_Earned(Handle:event, const String:name[], bool:Broadcast) 
{
	decl String:iName[MAX_NAME_LENGTH];
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new achievementid = GetEventInt(event,"award");
	GetClientName(client, iName, sizeof(iName));				

	CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}%d", iName, achievementid);	

	if(achievementid == 7)
	{
		iAwardID07[client] = iAwardID07[client] + 1;

		if(iAwardID07[client] > 2)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}SAFE", iName);
			iAwardID07[client] = 0;
		}
	}

	if(achievementid == 8)
	{
		iAwardID08[client] = iAwardID08[client] + 1;

		if(iAwardID08[client] > 2)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}NO TRIPPING", iName);
			iAwardID08[client] = 0;
		}
	}

	if(achievementid == 9)
	{
		iAwardID09[client] = iAwardID09[client] + 1;

		if(iAwardID09[client] > 2)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}ZOMBIE GOD", iName);
			iAwardID09[client] = 0;
		}
	}

	if(achievementid == 14)
	{
		iAwardID14[client] = iAwardID14[client] + 1;

		if(iAwardID14[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}NO PUKING", iName);
			iAwardID14[client] = 0;
		}
	}

	if(achievementid == 15)
	{
		iAwardID15[client] = iAwardID15[client] + 1;

		if(iAwardID15[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}C4 BINGO", iName);
			iAwardID15[client] = 0;
		}
	}

	if(achievementid == 18)
	{
		iAwardID18[client] = iAwardID18[client] + 1;

		if(iAwardID18[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}DOMESTIC VOILENCE", iName);
			iAwardID18[client] = 0;
		}
	}

	if(achievementid == 21)
	{
		iAwardID21[client] = iAwardID21[client] + 1;

		if(iAwardID21[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}NO JUMPING", iName);
			iAwardID21[client] = 0;
		}
	}

	if(achievementid == 22)
	{
		iAwardID22[client] = iAwardID22[client] + 1;

		if(iAwardID22[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}BOXING CHAMP", iName);
			iAwardID22[client] = 0;
		}
	}

	if(achievementid == 27)
	{
		iAwardID27[client] = iAwardID27[client] + 1;

		if(iAwardID27[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}NO SMOKING", iName);
			iAwardID27[client] = 0;
		}
	}

	if(achievementid == 66)
	{
		iAwardID66[client] = iAwardID66[client] + 1;

		if(iAwardID66[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}TRUSTED HANDS", iName);
			iAwardID66[client] = 0;
		}
	}

	if(achievementid == 67)
	{
		iAwardID67[client] = iAwardID67[client] + 1;

		if(iAwardID67[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}BACK 2 BACK", iName);
			iAwardID67[client] = 0;
		}
	}

	if(achievementid == 68)
	{
		iAwardID68[client] = iAwardID68[client] + 1;

		if(iAwardID68[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}DRUG RAPE", iName);
			iAwardID68[client] = 0;
		}
	}

	if(achievementid == 69)
	{
		iAwardID69[client] = iAwardID69[client] + 1;

		if(iAwardID69[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}DOCTOR GAMES", iName);
			iAwardID69[client] = 0;
		}
	}

	if(achievementid == 74)
	{
		iAwardID74[client] = iAwardID74[client] + 1;

		if(iAwardID74[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}CLIFF HANGER", iName);
			iAwardID74[client] = 0;
		}
	}

	if(achievementid == 75)
	{
		iAwardID75[client] = iAwardID75[client] + 1;

		if(iAwardID75[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}UNPINNED", iName);
			iAwardID75[client] = 0;
		}
	}

	if(achievementid == 79)
	{
		iAwardID79[client] = iAwardID79[client] + 1;

		if(iAwardID79[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}NEW FRIENDS", iName);
			iAwardID79[client] = 0;
		}
	}

	if(achievementid == 80)
	{
		iAwardID80[client] = iAwardID80[client] + 1;

		if(iAwardID80[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}ANNIHILATOR", iName);
			iAwardID80[client] = 0;
		}
	}

	if(achievementid == 83)
	{
		iAwardID83[client] = iAwardID83[client] + 1;

		if(iAwardID83[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}MURDERER", iName);
			iAwardID83[client] = 0;
		}
	}

	if(achievementid == 84)
	{
		iAwardID84[client] = iAwardID84[client] + 1;

		if(iAwardID84[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}FALSE AIM", iName);
			iAwardID84[client] = 0;
		}
	}

	if(achievementid == 85)
	{
		iAwardID85[client] = iAwardID85[client] + 1;

		if(iAwardID85[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}LEFT 2 DIE", iName);
			iAwardID85[client] = 0;
		}
	}

	if(achievementid == 86)
	{
		iAwardID86[client] = iAwardID86[client] + 1;

		if(iAwardID86[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}BLIND FIRE", iName);
			iAwardID86[client] = 0;
		}
	}

	if(achievementid == 87)
	{
		iAwardID87[client] = iAwardID87[client] + 1;

		if(iAwardID87[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}TARGET", iName);
			iAwardID87[client] = 0;
		}
	}

	if(achievementid == 93)
	{
		iAwardID93[client] = iAwardID93[client] + 1;

		if(iAwardID93[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}HEARTBREAKER", iName);
			iAwardID93[client] = 0;
		}
	}

	if(achievementid == 94)
	{
		iAwardID94[client] = iAwardID94[client] + 1;

		if(iAwardID94[client] > 10)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}ZOMBIEROOM", iName);
			iAwardID94[client] = 0;
		}
	}

	if(achievementid == 97)
	{
		iAwardID97[client] = iAwardID97[client] + 1;

		if(iAwardID97[client] > 5)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}DEATH WARRENT", iName);
			iAwardID97[client] = 0;
		}
	}

	if(achievementid == 98)
	{
		iAwardID98[client] = iAwardID98[client] + 1;

		if(iAwardID98[client] > 3)
		{
			CPrintToChatAll("{blue}%s {default}has earned the achievement {olive}LEFT 4 DEAD", iName);
			iAwardID98[client] = 0;
		}
	}
}