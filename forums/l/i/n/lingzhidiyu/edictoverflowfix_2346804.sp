/****************************************************************************************************
[ANY] EDICT OVERFLOW FIX v2.3
*****************************************************************************************************/

/****************************************************************************************************
CHANGELOG
*****************************************************************************************************
* 
* 2.0 	     - 
* 				Started Development again.
* 2.1 (Beta) - 
* 				Use Percentages.
* 2.2 (Beta) - 
* 				Remove func_ check as its not the only thing that will cause crashes.
* 				Ignore Edicts when there is more than 256 available.
* 2.3 - 
* 				Small fixes, cleanup etc.
* 2.4 - 
* 				Improved Logic, removed messages.
* 2.5 - 
* 				Faster, Safer & More Efficient Code.
* 2.6 - 
* 				Fix error spam.
*/

/****************************************************************************************************
DEFINES & INCLUDES
*****************************************************************************************************/
#pragma semicolon 1
#define PLUGIN_VERSION "2.6"
#include <sourcemod>
#include <sdktools>

new 
/****************************************************************************************************
HANDLES
*****************************************************************************************************/
Handle: hCvarEntPercent = INVALID_HANDLE,
Handle: hCvarEntCritical = INVALID_HANDLE,
/****************************************************************************************************
INTS
*****************************************************************************************************/
iEntPercent,
iEntCritical,
iEnt,
/****************************************************************************************************
STRINGS
*****************************************************************************************************/
String: sClassName[64];
/****************************************************************************************************
PLUGIN INFO
*****************************************************************************************************/
public Plugin:myinfo = {
	name = "Edict Overflow Fix",
	author = "xCoderx",
	version = PLUGIN_VERSION,
}

/****************************************************************************************************
PLUGIN INIT
*****************************************************************************************************/
public OnPluginStart() {
	hCvarEntPercent = CreateConVar("eof_entpercent", "15", "Percentage Limit for an Edict");
	hCvarEntCritical = CreateConVar("eof_entcritical", "2044", "Critical Entity Limit");
	
	CreateConVar("eof_version", PLUGIN_VERSION, "EOF", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	HookConVarChange(hCvarEntPercent, OnCvarChanged);
	HookConVarChange(hCvarEntCritical, OnCvarChanged);
	
	UpdateInts();
}

/****************************************************************************************************
PUBLIC FUNCTIONS
*****************************************************************************************************/
public OnCvarChanged(Handle: hConvar, const String: sOldValue[], const String: sNewValue[])
	UpdateInts();

public UpdateInts() 
{
	iEntPercent = GetConVarInt(hCvarEntPercent);
	iEntCritical = GetConVarInt(hCvarEntCritical);
}

public OnGameFrame() 
{
	if(IsValidEntity(iEnt))
	{
		GetEntityClassname(iEnt, sClassName, sizeof(sClassName));
		new iTempEnt = -1;
		
		while ((iTempEnt = FindEntityByClassname(iTempEnt, sClassName)) != -1)
		{
			if(GetPercentage(sClassName) < iEntPercent || !IsValidEntity(iTempEnt))
				break;
			
			if(iTempEnt == iEnt) 
				continue;
			
			if (!Entity_IsPlayer(iTempEnt))
				AcceptEntityInput(iTempEnt, "Kill");
		}
	}
}

public OnEntityCreated(entity) 
{
	iEnt = entity;
	
	if(entity  > iEntCritical)
		if (!Entity_IsPlayer(entity))
			AcceptEntityInput(entity, "Kill");
}


/****************************************************************************************************
STOCKS
*****************************************************************************************************/
stock GetPercentage(const String: sCName[]) 
{
	new iClassCount = 0;
	new iTempEnt = -1;
	
	while ((iTempEnt = FindEntityByClassname(iTempEnt, sClassName)) != INVALID_ENT_REFERENCE)
		iClassCount++;
	
	return RoundToNearest((float(iClassCount) / float(iEnt)) * 100.0);
}

/**
 * Checks if an entity is a player or not.
 * No checks are done if the entity is actually valid,
 * the player is connected or ingame.
 *
 * @param entity			Entity index.
 * @return 				True if the entity is a player, false otherwise.
 */
stock bool:Entity_IsPlayer(entity)
{
	if (entity < 1 || entity > MaxClients) {
		return false;
	}
	
	return true;
}