/* REQUEST
* 	URL = http://forums.alliedmods.net/showthread.php?t=174230
* 	By Skalp (http://forums.alliedmods.net/member.php?u=164686)
*
* This plugin will restrict the AK47 and M4A1 for players when they reach/exceed a set KDR
* 
*/
#pragma semicolon 1
// ===================================================================================================================================
// Includes
// ===================================================================================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
// ===================================================================================================================================
// Defines
// ===================================================================================================================================
#define 	PLUGIN_VERSION		"0.0.1.0"
#define 	MAX_WEAPON_NAME 	80
#define 	SOUND_FILE 			"buttons/weapon_cant_buy.wav" // cstrike\sound\buttons
// ===================================================================================================================================
// Global Variables and Handles
// ===================================================================================================================================
new Handle:h_Trie;
new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:Restricted[MAXPLAYERS+1] = false;
new bool:MaintainRestrictions = true;

new Float:RatioLimit = 0.0;

new DefuseBombPoints[MAXPLAYERS+1] = 0;
new BombExplodePoints[MAXPLAYERS+1] = 0;

// Enum for maintaining KDR restriction
enum RestrictedAttributes
{
RESTRICTION,
DEFUSE,
EXPLODE,
FRAGS,
DEATHS
};
// ===================================================================================================================================
// Plugin Info
// ===================================================================================================================================
public Plugin:myinfo = 
{
	name = "KDR Weapon Limit",
	author = "TnTSCS aka ClarkKent",
	description = "This plugin will not allow a player to buy/use an M4A1 or AK47 if their KDR is too high",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

//========================================================================================

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_version", PLUGIN_VERSION, 
	"Version of 'KDR Weapon Limit'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio", "3", 
	"KDR Ratio a plaer must meet before weapon limit is enforced against them", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)), OnKDRChanged);
	RatioLimit = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_maintain", "1", 
	"Maintain restrictions until map changes?\nIf set to no (0) then players can just reconnect to be able to purchase restricted weapons again.", _, true, 0.0, true, 1.0)), MaintainRestrictionsChanged);
	MaintainRestrictions = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("bomb_exploded", Event_BombExploded);
	
	h_Trie = CreateTrie();
	
	LoadTranslations("kdr_weapon_limit.phrases");
}

//========================================================================================

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart().
 *
 * @noreturn
 */
public OnConfigsExecuted()
{
	// For the restriction sound that plays to the player
	PrecacheSound(SOUND_FILE, true);
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

//========================================================================================

/**
 * Called when the map is loaded.
 *
 * @note This used to be OnServerLoad(), which is now deprecated.
 * Plugins still using the old forward will work.
 */
public OnMapStart()
{
	ResetEverything();
}

//========================================================================================

/**
 * Called right before a map ends.
 */
public OnMapEnd()
{
	ResetEverything();
}

//========================================================================================

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		if(MaintainRestrictions)
		{
			// Get and store the client's SteamID
			decl String:authString[20];
			authString[0] = '\0';
			
			GetClientAuthString(client, authString, 20);
			
			new GetRestrictedInfo[RestrictedAttributes];
			
			if(GetTrieArray(h_Trie, authString, GetRestrictedInfo[0], 5))
			{
				new pRestriction = GetRestrictedInfo[RESTRICTION];
				
				if(pRestriction == 1)
				{
					Restricted[client] = true;
					
					BombExplodePoints[client] = GetRestrictedInfo[EXPLODE];
					DefuseBombPoints[client] = GetRestrictedInfo[DEFUSE];
					
					SetEntProp(client, Prop_Data, "m_iFrags", GetRestrictedInfo[FRAGS]);
					SetEntProp(client, Prop_Data, "m_iDeaths", GetRestrictedInfo[DEATHS]);
					
					RestrictWeapons(client, 1);
				}
			}
		}
	}
}

//========================================================================================

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * @note	Must use IsClientInGame(client) if you want to do client specific things
 */
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		// Unhook player since they're leaving the server
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		if(MaintainRestrictions)
		{
			// Get and store the client's SteamID
			decl String:authString[20];
			authString[0] = '\0';
			
			GetClientAuthString(client, authString, 20);
			
			new RestrictedInfo[RestrictedAttributes];
			
			RestrictedInfo[RESTRICTION] = Restricted[client];
			RestrictedInfo[DEFUSE] = DefuseBombPoints[client];
			RestrictedInfo[EXPLODE] = BombExplodePoints[client];
			
			RestrictedInfo[FRAGS] = GetClientFrags(client);
			RestrictedInfo[DEATHS] = GetClientDeaths(client);
			
			SetTrieArray(h_Trie, authString, RestrictedInfo[0], 5, true);
		}
		
		Restricted[client] = false;
		
		BombExplodePoints[client] = 0;
		DefuseBombPoints[client] = 0;
		
		ClearTimer(ClientTimer[client]);
	}
}

//========================================================================================

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if(IsClientInGame(client) && Restricted[client] && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		// If item being bought is an m4a1 or ak47
		if(StrEqual(weapon, "m4a1", false) || StrEqual(weapon, "ak47", false))
		{
			PrintToChat(client, "\x04[\x03SM\x04] %t", "Weapon", weapon);
			
			EmitSoundToClient(client, SOUND_FILE);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

//========================================================================================

/**
 *	"bomb_defused"
 *	{
 *		"userid"	"short"		// player who defused the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DefuseBombPoints[client] += 3;
}

//========================================================================================

/**
 *	"bomb_exploded"
 *	{
 *		"userid"	"short"		// player who planted the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	BombExplodePoints[client] += 3;
}

//========================================================================================

/**
 * 	"player_death"
 *	{
 *		// this extents the original player_death by a new fields
 *		"userid"	"short"   	// user ID who died				
 *		"attacker"	"short"	// user ID who killed
 *		"weapon"	"string" 	// weapon name killer used 
 *		"headshot"	"bool"		// singals a headshot
 *		"dominated"	"short"	// did killer dominate victim with this kill
 *		"revenge"	"short"	// did killer get revenge on victim with this kill
 * 	}
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClearTimer(ClientTimer[victim]);
	ClientTimer[victim] = CreateTimer(0.1, Timer_ProcessKDR, victim);
	
	if(killer <= 0 || killer > MaxClients)
	{
		return;
	}
	
	ClearTimer(ClientTimer[killer]);
	ClientTimer[killer] = CreateTimer(0.1, Timer_ProcessKDR, killer);
}

//========================================================================================

public Action:Timer_ProcessKDR(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE; // Always set timer handles to INVALID_HANDLE when they're done
	
	new Float:KDR;
	
	new frags = GetClientFrags(client);
	new deaths = GetClientDeaths(client);
	
	new bonus_points = (DefuseBombPoints[client] + BombExplodePoints[client]);
	
	frags -= bonus_points;
	
	if(frags <= 0 && deaths <= 0)
	{
		return;
	}	
	else if(frags > 0 && deaths <= 0)
	{
		KDR = float(frags) - float(deaths);
	}
	else if(frags > 0 && deaths > 0)
	{
		KDR = float(frags) / float(deaths);
	}
	
	if(KDR >= RatioLimit)
	{
		if(!Restricted[client])
		{
			RestrictWeapons(client, 0);
			PrintToChat(client, "\x04[\x03SM\x04] %t", "On", KDR, RatioLimit);
		}
	}
	else
	{
		if(Restricted[client])
		{
			Restricted[client] = false;
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			PrintToChat(client, "\x04[\x03SM\x04] %t", "Off");
		}
	}
}

//========================================================================================

stock RestrictWeapons(client, msg)
{
	if(IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		Restricted[client] = true;
		
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		
		if(weapon != -1)
		{
			decl String:WeaponName[MAX_WEAPON_NAME];
			WeaponName[0] = '\0';
			
			GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
			
			if(StrContains(WeaponName, "m4a1", false) != -1 || StrContains(WeaponName, "ak47", false) != -1)
			{
				CS_DropWeapon(client, weapon, true);
				
				EmitSoundToClient(client, SOUND_FILE);
			}
		}
		
		if(msg)
		{
			PrintToChat(client, "\x04[\x03SM\x04] %t", "On2", RatioLimit);
		}
	}
}

//========================================================================================

// Taken from http://forums.alliedmods.net/showthread.php?t=167160 - thanks Antithasys
public ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

//========================================================================================

public ResetEverything()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Restricted[i] = false;
			SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			BombExplodePoints[i] = 0;
			DefuseBombPoints[i] = 0;
			
			ClearTimer(ClientTimer[i]);
		}
	}
}

//========================================================================================
// SDKHooks Function to restrict the use of the restricted weapon(s)
//========================================================================================

/**
* SDKHooks Function SDKHook_WeaponCanUse
*
* @param client		Client index
* @param weapon	weapon entity index
* @return		Plugin_Continue to allow, else Handled to disallow
*/
public Action:OnWeaponCanUse(client, weapon)
{
	if(!Restricted[client])
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[MAX_WEAPON_NAME];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, "weapon_m4a1", false) || StrEqual(sWeapon, "weapon_ak47", false))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnKDRChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RatioLimit = GetConVarFloat(cvar);
}

public MaintainRestrictionsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaintainRestrictions = GetConVarBool(cvar);
}