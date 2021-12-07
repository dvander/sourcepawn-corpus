#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Log Created Entities",
	author = "RedSword",
	description = "View a projectile or thrown grenade's flight from the projectile's perspective",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new bool:g_bCanLog;

public OnPluginStart()
{
	CreateConVar("logcreatedentitiesversion", PLUGIN_VERSION, "Gives version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	//1st event
	
	new Handle:tmpHandle = CreateEvent("player_throw_explosive");
	
	if ( tmpHandle != INVALID_HANDLE )
	{
		HookEvent("player_throw_explosive", Event_PlayerThrow);
		LogMessage("Hooked player_throw_explosive");
		
		CancelCreatedEvent( tmpHandle );
		tmpHandle = INVALID_HANDLE;
	}
	
	//2nd event
	
	tmpHandle = CreateEvent("projectile_bounce");
	
	if ( tmpHandle != INVALID_HANDLE )
	{
		HookEvent("projectile_bounce", Event_ProjectileBounce);
		LogMessage("Hooked projectile_bounce");
		
		CancelCreatedEvent( tmpHandle );
		tmpHandle = INVALID_HANDLE;
	}
	
	//3rd event
	
	tmpHandle = CreateEvent("player_ranged_impact");
	
	if ( tmpHandle != INVALID_HANDLE )
	{
		HookEvent("player_ranged_impact", Event_PlayerRangedImpact);
		LogMessage("Hooked player_ranged_impact");
		
		CancelCreatedEvent( tmpHandle );
		tmpHandle = INVALID_HANDLE;
	}
	
	g_bCanLog = false;
}

public OnConfigsExecuted()
{
	g_bCanLog = true;
}

public OnMapEnd()
{
	g_bCanLog = false;
}

public OnEntityCreated(iEntity, const String:classname[]) 
{
	if ( !g_bCanLog )
		return;
	
	LogMessage("Created : '%s'", classname);
}

public Action:Event_PlayerThrow(Handle:event, String:name[], bool:db)
{
	if ( !g_bCanLog )
		return Plugin_Continue;
	
	decl String:szBuffer[ 64 ];
	
	GetEventString(event, "weapon", szBuffer, sizeof(szBuffer));
	
	LogMessage("Player threw : '%s'", szBuffer);
	
	return Plugin_Continue;
}

public Action:Event_ProjectileBounce(Handle:event, String:name[], bool:db)
{
	if ( !g_bCanLog )
		return Plugin_Continue;
	
	decl String:szBuffer[ 64 ];
	
	GetEventString(event, "weapon", szBuffer, sizeof(szBuffer));
	
	LogMessage("Projectile bounced : '%s'", szBuffer);
	
	return Plugin_Continue;
}

public Action:Event_PlayerRangedImpact(Handle:event, String:name[], bool:db)
{
	if ( !g_bCanLog )
		return Plugin_Continue;
	
	decl String:szBuffer[ 64 ];
	
	GetEventString(event, "weapon", szBuffer, sizeof(szBuffer));
	
	LogMessage("Player Ranged Impact : '%s'", szBuffer);
	
	return Plugin_Continue;
}