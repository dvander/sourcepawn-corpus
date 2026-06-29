#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "infected and player incapps and more!",
	author = "gamemann",
	description = "when a infected is killed it tells you all the info",
	version = "1.0",
	url = "sourcemod.net",
};

public OnPluginstart()
{
	HookEvent("infected_death", InfectedDeath);
	HookEvent("player_incapacitated", PlayerIncapp);
	HookEvent("friendly_fire", FriendlyFire);
	HookEvent("hunter_headshot", Headshot);
}

public Action:InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[64]
 	new victimId = GetEventInt(event, "attacker") 
	new attackerId = GetEventInt(event, "infected_id")
 	new GenterId = GetEventInt(event, "gender") 
	new weaponId = GetEventInt(event, "weapon") 
	new bool:headshot = GetEventBool(event, "headshot") 
	new bool:minigun = GetEventBool(event, "minigun") 
	GetEventString(event, "weapon", weapon, sizeof(weapon))

	decl String:name[64]
	new victim = GetClientOfUserId(victimId) 
	new attacker = GetClientOfUserId(attackerId) 
	GetClientName(attacker, name, sizeof(name)) 
	
PrintHintText(victim, "(victimId \"%s\") has killed a (attackerId \"%s\") (GenterId \"%s\") with a (weapon \"%d\") (weaponId \"%s\") (headshot \"%d\")",name,GenterId,weaponId,victimId,attackerId,weapon,headshot,minigun)

PrintToConsole(victim, "(victimId \"%s\") has killed a (attackerId \"%s\") (GenterId \"%s\") with a (weapon \"%d\") (weaponId \"%s\") (headshot \"%d\")",name,GenterId,weaponId,victimId,attackerId,weapon,headshot,minigun)
}

public PlayerIncapp(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapons[70]
	new victimId2 = GetEventInt(event, "userid")
	new attackerId2 = GetEventInt(event, "attacker")
	GetEventString(event, "weapons", weapons, sizeof(weapons))

	decl String:nameId[70]
	new victim2 = GetClientOfUserId(victimId2)
	new attacker2 = GetClientOfUserId(attackerId2)
	GetClientName(attacker2, nameId, sizeof(nameId))

	PrintHintText(victim2, "(victimId2 \"%s\") was killed by (attackerId2 \"%s\")",nameId,weapons,victim2,attacker2,attackerId2,victimId2)
}

public FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon3[80]
	new victimId3 = GetEventInt(event, "userid")
	new attackerId3 = GetEventInt(event, "attacker")
	new guiltyId = GetEventInt(event, "guilty")
	GetEventString(event, "weapon3", weapon3, sizeof(weapon3))

	decl String:name3[80]
	new victim3 = GetClientOfUserId(victimId3)
	new attacker3 = GetClientOfUserId(attackerId3)
	GetClientName(attacker3, name3, sizeof(name3))

	PrintHintText(victim3, "(attackerId3 \"%s\") has just shot and friendly fired (victimId3 \"%s\") and (guiltyId \"%s\") is guilty",victimId3,attackerId3,guiltyId,name3,weapon3)

PrintToConsole(victim3, "(attackerId3 \"%s\") has just shot and friendly fired (victimId3 \"%s\") and (guiltyId \"%s\") is guilty",victimId3,attackerId3,guiltyId,name3,weapon3)
}

public Headshot(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon4[100]
	new victimId4 = GetEventInt(event, "userid")
	GetEventString(event, "weapon4", weapon4, sizeof(weapon4))

	decl String:name4[100]
	new victim4 = GetClientOfUserId(victimId4)
	GetClientName(victimId4, name4, sizeof(name4))

	PrintHintText(victim4, "(victim4 \"%s\") did a headshot to a hunter!",victimId4,name4,weapon4)
}

	




