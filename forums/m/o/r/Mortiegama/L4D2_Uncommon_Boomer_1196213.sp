#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D2 Uncommon Boomer Bile
#define PLUGIN_VERSION "1.12"

new Handle:cvarUncommonBileSpawn;
new Handle:cvarUncommonBileTimeout;
new Handle:cvarUncommonBileChance;
new Handle:cvarFallenLimit;

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
	CreateConVar("l4d_ubb_version", PLUGIN_VERSION, "Uncommon Boomer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarUncommonBileSpawn = CreateConVar("l4d_ubb_uncommonbilespawn", "8", "Chooses which type of mob to summon when Boomer explodes (1-8)(Riot|Ceda|Clown|Mud|Roadcrew|Fallen|Jimmy|Random) (Def 8)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarUncommonBileTimeout = CreateConVar("l4d_ubb_uncommonbiletimeout", "60", "How many seconds must a Boomer wait before summoning another uncommon mob. (Def 60)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarUncommonBileChance = CreateConVar("l4d_ubb_uncommonbilechance", "100", "Chance that the Boomer Bile will summon an uncommon mob (100 = 100%). (Def 100)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarFallenLimit = CreateConVar("l4d_ubb_fallenlimit", "25", "Amount of Fallen that can spawn on a single map. (Def 25)", FCVAR_PLUGIN, true, 1.0, false, _);
	
	HookEvent("player_now_it", Event_PlayerNowIt);

	AutoExecConfig(true, "plugin.L4D2.UncommonBoomer");
	
	new Fallen = GetConVarInt(cvarFallenLimit);
	SetConVarInt(FindConVar("z_fallen_max_count"), Fallen, false, false);
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
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde fallen");
			}
			
			case 7:
			{
				CheatCommand(GetAnyClient(), "sm_spawnuncommonhorde jimmy");
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

CheatCommand(client, const String:command[], const String:arguments[]="")
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}