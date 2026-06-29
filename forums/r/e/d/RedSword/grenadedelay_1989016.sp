/**
	Credits : 
	blodia - he shared how to explode a grenade :
	https://forums.alliedmods.net/showthread.php?p=1985693#post1985693
	
	thetwistedpanda - his code in there :
	https://forums.alliedmods.net/showthread.php?p=1985598#post1985598
*/
#pragma semicolon 1

//#define DEBUG

#include <sdkhooks>

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo =
{
	name = "Grenade Delay",
	author = "RedSword (And blodia/Panda I guess D:)",
	description = "Explode the grenade after a certain delay, rather than the default one",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MINIMUM_FLOAT_DELAY 0.0

//Cvars
new Handle:g_hGrenadeDelay;
new Handle:g_hGrenadeDelay_random;
new Handle:g_hGrenadeDelay_string;

//Prevent re-running a function
//new String:g_szGrenadeDelay_string[ 32 ];

//Contains the projectile to apply logic to
new Handle:g_hTrieProjectileNames = INVALID_HANDLE;

public OnPluginStart()
{
	//CVARs
	CreateConVar( "grenadedelayversion", PLUGIN_VERSION, "Grenade Delay version", FCVAR_SPONLY | FCVAR_CHEAT | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hGrenadeDelay = CreateConVar( "grenadedelay", "5.0", "What is the average delay before the bomb explode ? (if grenadedelay=0, plugin is disabled)", 
		_, true, 0.0 );
	g_hGrenadeDelay_random = CreateConVar( "grenadedelay_random", "0.0", "The maximum time value added or substracted to 'grenadedelay' before the grenade can explode. Will be random. 0.0 = no random", 
		_, true, 0.0 );
	g_hGrenadeDelay_string = CreateConVar( "grenadedelay_string", "hegrenade_projectile flashbang_projectile", 
	"What are the projectile (put classnames) that will have their delay changed. Separate by a space different ones." );
	HookConVarChange( g_hGrenadeDelay_string, GrenadeDelayStringChanged );
	
	AutoExecConfig( true, "grenadedelay" );
	
	g_hTrieProjectileNames = CreateTrie();
	
	reloadTrieProjectileNames();
}
//Trigger logic on grenade creation (Panda D:)
public OnEntityCreated(ent, const String:classname[])
{
	decl useless;
	
	#if defined DEBUG
	PrintToChatAll("OnEntityCreated : '%s' ; in trie = %d", classname, GetTrieValue( g_hTrieProjectileNames, classname, useless ));
	#endif
	
	if ( GetConVarFloat( g_hGrenadeDelay ) == 0.0 || //plugin off
			ent <= MaxClients || //regular client
			!IsValidEntity( ent ) || //is invalid
			!GetTrieValue( g_hTrieProjectileNames, classname, useless ) ) //doesn't contain a sought classname
		return;
	
	SDKHook( ent, SDKHook_Spawn, OnEntitySpawned );
}
public OnEntitySpawned( ent )
{
	SDKUnhook( ent, SDKHook_Spawn, OnEntitySpawned );
	
	#if defined DEBUG
	new String:szBuffer[ 64 ];
	GetEntityClassname( ent, szBuffer, sizeof(szBuffer) );
	PrintToChatAll("Launching timers with %s", szBuffer);
	#endif
	
	new iRef = EntIndexToEntRef( ent );
	CreateTimer( MINIMUM_FLOAT_DELAY, Timer_OnGrenadeCreated, iRef );
	
	new Float:fRandom = GetConVarFloat( g_hGrenadeDelay_random ) / 2.0;
	fRandom = GetConVarFloat( g_hGrenadeDelay ) + GetRandomFloat( -fRandom, fRandom );
	if ( fRandom < MINIMUM_FLOAT_DELAY )
		fRandom = MINIMUM_FLOAT_DELAY;
		
	#if defined DEBUG
	PrintToChatAll( "Gren : %.4f", fRandom );
	#endif
	
	CreateTimer( fRandom, Timer_Detonate, iRef );
}
//Stop the grenade from thinking; by Panda
public Action:Timer_OnGrenadeCreated(Handle:timer, any:ref)
{
	#if defined DEBUG
	PrintToChatAll("Timer_OnGrenadeCreated");
	#endif
	
	new ent = EntRefToEntIndex( ref );
	if ( ent != INVALID_ENT_REFERENCE )
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", -1);
}
//Explode the grenade, <3 blodia
public Action:Timer_Detonate(Handle:timer, any:ref)
{
	#if defined DEBUG
	PrintToChatAll("Timer_OnStartDetonate");
	#endif
	
	new ent = EntRefToEntIndex( ref );
	if ( ent != INVALID_ENT_REFERENCE )
	{
		//This fucking awesome piece of code is brought to you by blodia
		//<3<3<3<3 blodia
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", 1); //for smoke
		SetEntProp( ent, Prop_Data, "m_takedamage", 2 );
		SetEntProp( ent, Prop_Data, "m_iHealth", 1 );
		//SetEntityHealth( ent, 1 ); Y U NO SUPPORTED U PIECE OF S*
		SDKHooks_TakeDamage(ent, 0, 0, 1.0);
	}
}

public GrenadeDelayStringChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	reloadTrieProjectileNames();
}

reloadTrieProjectileNames()
{
	//1- Resets
	ClearTrie( g_hTrieProjectileNames );
	
	decl String:szBuffer[ 32 ][ 32 ];
	new sizeofBuffer = sizeof(szBuffer);
	for ( new i; i < sizeofBuffer; ++i )
		szBuffer[ i ][ 0 ] = '\0';
	
	//2- Get ConVar values
	decl String:szBufferCvar[ 256 ];
	GetConVarString( g_hGrenadeDelay_string, szBufferCvar, sizeof(szBufferCvar) );
	
	ExplodeString( szBufferCvar, " ", szBuffer, sizeofBuffer, sizeof(szBuffer[]) );
	
	//3- Put them in the tries, and use them later
	for ( new i; szBuffer[ i ][ 0 ] != '\0' && i < sizeofBuffer; ++i )
	{
		SetTrieValue( g_hTrieProjectileNames, szBuffer[ i ], 0 );
		#if defined DEBUG
		PrintToServer( "Added '%s' to trie", szBuffer[ i ] );
		#endif
	}
}