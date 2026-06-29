#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D2 Uncommon Boomer Bile
#define PLUGIN_VERSION "1.13"

new Handle:cvarUncommonBileSpawn;
new Handle:cvarUncommonBileTimeout;
new Handle:cvarUncommonBileChance;

new bool:isUncommonBileTimeout = false;

public Plugin:myinfo = 
{
    name = "[L4D2] Uncommon Boomer Bile",
    author = "Mortiegama",
    description = "Using Uncommon Infected plugin, this allows mobs to spawn when the Boomer vomits on a Survivor.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1196213#post1196213"
}

public OnPluginStart()
{
	cvarUncommonBileSpawn = CreateConVar("l4d_ubb_uncommonbilespawn", "8", "Chooses which type of mob to summon when Boomer explodes (1-8)(Riot|Ceda|Clown|Mud|Roadcrew|Jimmy|Fallen|Random) (Def 8)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarUncommonBileTimeout = CreateConVar("l4d_ubb_uncommonbiletimeout", "0", "How many seconds must a Boomer wait before summoning another uncommon mob. (Def 0)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarUncommonBileChance = CreateConVar("l4d_ubb_uncommonbilechance", "50", "Chance that the Boomer Bile will summon an uncommon mob (100 = 100%). (Def 50)", FCVAR_PLUGIN, true, 1.0, false, _);

	HookEvent("player_now_it", Event_PlayerNowIt);

	AutoExecConfig(true, "plugin.L4D2.UncommonBoomer");
}

stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}


public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new BileMobPercent = GetRandomInt(0, 99);
	new BileMobChance = (GetConVarInt(cvarUncommonBileChance));

	if (!isUncommonBileTimeout && BileMobPercent < BileMobChance)
	{
		new HordeSpawn = (GetConVarInt(cvarUncommonBileSpawn));

		switch (HordeSpawn) 
		{
			case 1:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde riot");
			}

			case 2:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde ceda");
			}

			case 3:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde clown");
			}

			case 4:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde mud");
			}

			case 5:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde roadcrew");
			}

			case 6:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde jimmy");
			}

			case 7:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde fallen");
			}

			case 8:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde random");
			}

		}

		isUncommonBileTimeout = true;
		CreateTimer(GetConVarFloat(cvarUncommonBileTimeout), UncommonBileTimeout);
	}
}

public Action:UncommonBileTimeout(Handle:timer)
{
	isUncommonBileTimeout = false;
}

GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			return i;

	return 0;
}