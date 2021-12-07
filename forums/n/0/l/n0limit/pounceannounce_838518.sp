/* 
* Pounce Announce
*/

#include <sourcemod>

//globals
new Handle:hMaxPounceDistance;
new Handle:hMinPounceDistance;
new Handle:hMaxPounceDamage;
//hunter position store
new Float:infectedPosition[32][3]; //support up to 32 slots on a server
//cvars
new Handle:hMinPounceAnnounce;
new Handle:hCenterChat;
new Handle:hShowDistance;
new Handle:hCapDamage;
#define DEBUG 0

//For variable types of pounce display
enum PounceDistanceDisplay
{
	None = 0, 
	Units = 1, 
	UnitsAndFeet = 2,
	UnitsAndMeters = 3,
	Feet = 4,
	Meters = 5
}

public Plugin:myinfo = 
{
	name = "Pounce Announce",
	author = "n0limit",
	description = "Announces hunter pounces to the entire server",
	version = "1.5",
	url = "http://forums.alliedmods.net/showthread.php?t=93605"
}

public OnPluginStart()
{
	hMaxPounceDistance = FindConVar("z_pounce_damage_range_max");
	hMinPounceDistance = FindConVar("z_pounce_damage_range_min");
	hMaxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	hMinPounceAnnounce = CreateConVar("pounceannounce_minimum","0","The minimum amount of damage required to announce the pounce", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hCenterChat = CreateConVar("pounceannounce_centerchat","1","Announces the pounce to center chat. Use 0 for regular player chat.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hShowDistance = CreateConVar("pounceannounce_showdistance","2","Show the distance the hunter traveled for the pounce.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hCapDamage = CreateConVar("pounceannounce_capdamage","0","Caps the displayed pounce damage to the maximum able to be dealt.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true,"pounceannounce");
	
	HookEvent("lunge_pounce",Event_PlayerPounced);
	HookEvent("ability_use",Event_AbilityUse);
}
public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Save the location of the player who just used an infected ability
	GetClientAbsOrigin(user,infectedPosition[user]);
	
	#if DEBUG
	decl String:playerName[MAX_NAME_LENGTH];
	decl String:ability[256];
	GetClientName(user, playerName, sizeof(playerName));
	GetEventString(event, "ability", ability, sizeof(ability));
	PrintToChatAll("%s -> %s: %s (%.1f %.1f %.1f)", name, playerName, ability, infectedPosition[user][0], infectedPosition[user][1], infectedPosition[user][2]);
	#endif 
}
public Event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:pouncePosition[3];
	new attackerId = GetEventInt(event, "userid");
	new victimId = GetEventInt(event, "victim");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);
	new minAnnounce = GetConVarInt(hMinPounceAnnounce);
	new bool:centerChat = GetConVarBool(hCenterChat);
	
	decl String:attackerName[MAX_NAME_LENGTH];
	decl String:victimName[MAX_NAME_LENGTH];
	decl String:pounceLine[256];
	decl String:distanceBuffer[64];
	
	new PounceDistanceDisplay:showDistance;
	//distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
	//http://forums.alliedmods.net/showthread.php?t=93207
	//new eventDistance = GetEventInt(event, "distance");
	
	//get hunter-related pounce cvars
	new max = GetConVarInt(hMaxPounceDistance);
	new min = GetConVarInt(hMinPounceDistance);
	new maxDmg = GetConVarInt(hMaxPounceDamage);
	
	//Get current position while pounced
	GetClientAbsOrigin(attackerClient,pouncePosition);
	
	//Calculate 2d distance between previous position and pounce position
	new distance = RoundToNearest(GetVectorDistance(infectedPosition[attackerClient], pouncePosition));
	
	//Get damage using hunter damage formula
	//damage in this is expressed as a float because my server has competitive hunter pouncing where the decimal counts
	new Float:dmg = (((distance - float(min)) / float(max - min)) * float(maxDmg)) + 1;
	
	//Check if calculate damage is higher than max, and cap to max.
	if(GetConVarBool(hCapDamage) && dmg > maxDmg)
		dmg = float(maxDmg) + 1;
	
	if(distance >= min && dmg >= minAnnounce)
	{
		GetClientName(attackerClient,attackerName,sizeof(attackerName));
		GetClientName(victimClient,victimName,sizeof(victimName));
		#if DEBUG
		PrintToServer("Pounce: max: %d min: %d dmg: %d dist: %d dmg: %.01f",max,min,maxDmg,distance, dmg);
		#endif
		Format(pounceLine,sizeof(pounceLine),"\x04%s\x01 pounced \x04%s\x01 for \x03%.01f damage\x01 (max: %d)",attackerName,victimName,dmg,maxDmg + 1);
		
		showDistance = GetConVarInt(hShowDistance);
		if(showDistance != None)
		{
			switch(showDistance)
			{
				case Units:
				{
					Format(distanceBuffer,sizeof(distanceBuffer)," over %d units",distance);
				}
				case UnitsAndFeet:
				{ //units / 16 = feet in game
					Format(distanceBuffer,sizeof(distanceBuffer)," over %d units (%d feet)",distance, distance / 16);
				}
				case UnitsAndMeters:
				{	//0.0213 = conversion rate for units to meters
					Format(distanceBuffer,sizeof(distanceBuffer)," over %d units (%.0f meters)",distance, distance * 0.0213);
				}
				case Feet:
				{
					Format(distanceBuffer,sizeof(distanceBuffer)," over %d feet", distance / 16); 
				}
				case Meters:
				{
					Format(distanceBuffer,sizeof(distanceBuffer)," over %.0f meters", distance * 0.0213);
				}
			}
			StrCat(pounceLine,sizeof(pounceLine),distanceBuffer);
		}
		if(centerChat)
			PrintHintTextToAll(pounceLine);
		else
			PrintToChatAll(pounceLine);
			
	}
}