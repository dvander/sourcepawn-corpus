#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "announcement & upgrades",
	author = "gamemann",
	description = "when tank/witch is spawn it will give you random upgrades",
	version = "1.0",
	url = ""
};

new Handle:AllowUpgrades = INVALID_HANDLE;
new Handle:AllowWitchAnnounce = INVALID_HANDLE;
new Handle:AllowTankAnnounce = INVALID_HANDLE;

public OnPluginStart()
{
	//convars
	AllowUpgrades = CreateConVar("allow_upgrades", "1", "if 1 will allow survivors to get weapons and upgrades");
	AllowWitchAnnounce = CreateConVar("allow_witch_announcement", "1", "if 1 will allow witch spawn announcement");
	AllowTankAnnounce = CreateConVar("allow_tank_announcement", "1", "if 1 will allow tank spawn announcement");
	//events
	HookEvent("witch_spawn", WitchSpawn);
	HookEvent("tank_spawn", TankSpawn);
	AutoExecConfig(true, "l4d2_announcement");
}

public WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(AllowWitchAnnounce))
	{
		for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
		{
			PrintHintText(i, "a witch is spawned");
		}
		else
		{
			return 0;
		}
	}
	if (GetConVarInt(AllowUpgrades))
	{
		GiveUpgrades();
	}
	else
	{
		return 0;
	}
	return 1;
}

GiveUpgrades()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
	
		FakeClientCommand(i, "upgrade_add LASER_SIGHT");
		FakeClientCommand(i, "give autoshotgun");
		FakeClientCommand(i, "give first_aid_kit");
	}
}


public TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(AllowTankAnnounce))
	{
		for (new i = 1; i <= GetMaxClients(); i++)
		if (IsClientInGame(i))
		{
			PrintHintText(i, "a tank is spawned");
		}
		else
		{
			return 0;
		}
	}
	if (GetConVarInt(AllowUpgrades))
	{
		GiveUpgrades2();
	}
	else
	{
		return 0;
	}
	return 1;
}

public GiveUpgrades2()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	if (IsClientInGame(i))
	{
		FakeClientCommand(i, "upgrade_add EXPLOSIVE_AMMO");
		FakeClientCommand(i, "give autoshotgun");
		FakeClientCommand(i, "give pain_pills");
		FakeClientCommand(i, "give molotov");
	}
}

