#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.3"

new g_WeaponParent;

new Handle:team, Handle:toggle, Handle:prim, Handle:sec, Handle:hegren, Handle:flash, Handle:smoke, Handle:armor, Handle:givesec, Handle:giveprim, Handle:bztoggle;

public Plugin:myinfo = 
{
	name = "ZRSpawn",
	author = "=(GrG)=",
	description = "Spawn with specific weapons and items.",
	version = PLUGIN_VERSION,
	url = "http://www.grgaming.com/"
}
public OnPluginStart()
{
	//Public Var
	CreateConVar("ZRSpawn_version", PLUGIN_VERSION, "Version of ZRSpawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	//Events
	HookEvent("player_spawn",Event_spawn);
	HookEvent("player_death",PlayerDeath);
	
	//ConVars
	team = CreateConVar("zrs_team", "1", "1 = Humans CT | 2 = Humans T", FCVAR_NONE, false, 0.0, true, 2.0);
	toggle = CreateConVar("zrs_toggle", "1")
	prim = CreateConVar("zrs_prim", "weapon_m3")
	sec = CreateConVar("zrs_sec", "weapon_deagle");
	giveprim = CreateConVar("zrs_giveprim", "1");
	givesec = CreateConVar("zrs_givesec", "1");
	hegren = CreateConVar("zrs_hegren", "1");
	flash = CreateConVar("zrs_flash", "0", "0 = No Flash | 1 = Give 1 Flash | 2 = Give 2 Flash", FCVAR_NONE, false, 0.0, true, 2.0);
	smoke = CreateConVar("zrs_smoke", "0");
	armor = CreateConVar("zrs_armor", "1");
	bztoggle = CreateConVar("zrs_bzrem", "1");
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	
}
public OnMapStart() 
{ 
	decl String:szClass[65];
	if( GetConVarInt( bztoggle ))
	{
		for (new i = MaxClients; i <= GetMaxEntities(); i++) 
		{ 
			if(IsValidEdict(i) && IsValidEntity(i)) 
			{ 
				GetEdictClassname(i, szClass, sizeof(szClass)); 
				if(StrEqual("func_buyzone", szClass)) 
				{ 
					RemoveEdict(i); 
				} 
			} 
		} 	
	}
}

public Action:Event_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	StripAndGive( client );
	CleanUp()
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	CleanUp()
}
StripAndGive( client )
{
	new wepIdx; 
	new team2 = GetConVarInt( team )
	new toggle2 = GetConVarInt( toggle )
	
	if( toggle2 )
	{
		
		
		for( new i = 0; i < 2; i++ )
		{
			while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 )
			{
				RemovePlayerItem( client, wepIdx );
			}
		}
		switch( team2 )
		{
			case 1:
			{
				TeamCheckCt( client )
			}
			case 2:
			{
				TeamCheckT( client )
			}
		}
	}
}
TeamCheckCt( client )
{
	if( GetClientTeam( client ) == CS_TEAM_CT )
	{
		wepspawn( client )
	}
}
TeamCheckT( client )
{
	if( GetClientTeam( client ) == CS_TEAM_T )
	{
		wepspawn( client )
	}
}
wepspawn( client )
{
	new flash2 = GetConVarInt( flash )
	decl String:primwep[32];
	decl String:secwep[32];
	
	GetConVarString( prim, primwep, sizeof(primwep));
	GetConVarString( sec, secwep, sizeof(secwep));
	
	if(GetConVarInt( giveprim ))
	{
		GivePlayerItem(client, primwep );
	}
	
	if(GetConVarInt( givesec ))
	{
		GivePlayerItem(client, secwep );
	}
	
	if(GetConVarInt( hegren ))
	{
		GivePlayerItem(client, "weapon_hegrenade");
	}
	
	if(GetConVarInt( smoke ))
	{
		GivePlayerItem(client, "weapon_smokegrenade")
	}
	if(GetConVarInt( armor ))
	{
		GivePlayerItem(client, "item_assaultsuit")
	}
	
	switch( flash2 )
	{
		case 1:
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
		case 2:
		{
			GivePlayerItem(client, "weapon_flashbang");
			GivePlayerItem(client, "weapon_flashbang");
		}
	}
}
CleanUp()
{  // By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:name[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, name, sizeof(name));
			if ( ( StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}
}
	