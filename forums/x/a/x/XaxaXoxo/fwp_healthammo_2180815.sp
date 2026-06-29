
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <fortwars>


public Plugin:myinfo = 
{
	name = "[FWP] Health And Ammo",
	author = "VoiDeD",
	description = "",
	version = "1.0",
	url = "http://saxtonhell.com"
}


new Handle:g_ItemTrie = INVALID_HANDLE;


public OnPluginStart()
{
	g_ItemTrie = CreateTrie();
	
	if ( LibraryExists( "fortwars" ) )
	{
		Setup();
	}
}

public OnPluginEnd()
{
	CloseHandle( g_ItemTrie );
	g_ItemTrie = INVALID_HANDLE;
}

public OnLibraryAdded( const String:name[] )
{
	if ( StrEqual( name, "fortwars" ) )
	{
		Setup();
	}
}

public Setup()
{
	AddItem( "Small Health Kit", "item_healthkit_small", "models/items/medkit_small.mdl", 3, 200 );
	AddItem( "Medium Health Kit", "item_healthkit_medium", "models/items/medkit_medium.mdl", 6, 200 * 2 );
	AddItem( "Large Health Kit", "item_healthkit_full", "models/items/medkit_large.mdl", 9, 200 * 4 );
	
	AddItem( "Small Ammo Pack", "item_ammopack_small", "models/items/ammopack_small.mdl", 3, 20 );
	AddItem( "Medium Ammo Pack", "item_ammopack_medium", "models/items/ammopack_medium.mdl", 3, 20 * 2 );
	AddItem( "Large Ammo Pack", "item_ammopack_full", "models/items/ammopack_large.mdl", 3, 20 * 3 );
}

public FW_OnPropBuilt( client, ent, FWProp:prop, FWAProp:propId, const Float:pos[ 3 ], const Float:ang[ 3 ] )
{
	decl String:keyName[ 20 ];
	IntToString( _:propId, keyName, sizeof( keyName ) );
	
	decl String:itemClass[ 128 ];
	if ( GetTrieString( g_ItemTrie, keyName, itemClass, sizeof( itemClass ) ) )
	{
		new itemEnt = SpawnItem( itemClass, pos, TFTeam:GetClientTeam( client ) );
		
		FW_SetPropEntity( prop, itemEnt );
		
		AcceptEntityInput( ent, "Kill" );
	}
}

stock SpawnItem( const String:className[], const Float:pos[ 3 ], TFTeam:team = TFTeam_Unassigned )
{
	new ent = CreateEntityByName( className );
	
	if ( IsValidEntity( ent ) )
	{
		HookSingleEntityOutput( ent, "OnPlayerTouch", OnTouchItem );
		
		DispatchSpawn( ent );
		TeleportEntity( ent, pos, NULL_VECTOR, NULL_VECTOR );
		
		SetEntProp( ent, Prop_Send, "m_iTeamNum", team );
	}
	
	return ent;
}

public OnTouchItem( const String:output[], caller, activator, Float:delay )
{
	new FWProp:prop = FW_GetEntityProp( caller );
	
	if ( prop == INVALID_PROP )
		return;
		
	FW_PropDestroyed( prop );
	AcceptEntityInput( caller, "Kill" );
}

stock AddItem( const String:name[], const String:className[], const String:model[], health, cost )
{
	PrecacheModel( model );
	
	new FWAProp:propId = FW_AddProp( name, model, health, cost );
	
	decl String:keyName[ 20 ];
	IntToString( _:propId, keyName, sizeof( keyName ) );
	
	SetTrieString( g_ItemTrie, keyName, className );
}
