#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#undef REQUIRE_EXTENSIONS
#include <steamtools>

#pragma semicolon 1

#define BOW "tf_weapon_compound_bow"
#define ARROW "tf_projectile_arrow"

#define JUMPCHARGETIME 1
#define JUMPCHARGE (25 * JUMPCHARGETIME)

#define VERSION "1.4"

public Plugin:myinfo = 
{
	name = "[TF2] Huntsman Hell",
	author = "Powerlord",
	description = "All Snipers, all with Huntsman and Jarate, most likely firing arrows that explode and set you on fire.  What could go wrong?",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=214679"
}

new String:g_Sounds_Explode[][] = {"weapons/explode1.wav", "weapons/explode2.wav", "weapons/explode3.wav" };
new String:g_Sounds_Jump[][] = { "vo/sniper_specialcompleted02.wav", "vo/sniper_specialcompleted17.wav", "vo/sniper_specialcompleted19.wav", "vo/sniper_laughshort01.wav", "vo/sniper_laughshort04.wav" };

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Explode = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFire = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFireSelf = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeRadius = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeDamage = INVALID_HANDLE;
new Handle:g_Cvar_FireArrows = INVALID_HANDLE;
new Handle:g_Cvar_ArrowCount = INVALID_HANDLE;
new Handle:g_Cvar_StartingHealth = INVALID_HANDLE;
new Handle:g_Cvar_SuperJump = INVALID_HANDLE;
//new Handle:g_Cvar_DoubleJump = INVALID_HANDLE;
new Handle:g_Cvar_FallDamage = INVALID_HANDLE;

new Handle:jumpHUD;

new g_JumpCharge[MAXPLAYERS] = { 0, ... };

new bool:g_Enabled = false;

new bool:g_SteamTools = false;

new bool:g_LateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	g_LateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("huntsmanheaven_version", VERSION, "Huntsman Hell Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("huntsmanhell_enabled", "1.0", "Enable Huntsman Hell?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Explode = CreateConVar("huntsmanhell_explode", "1.0", "Should arrows explode when they hit something?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ExplodeRadius = CreateConVar("huntsmanhell_exploderadius", "200.0", "If arrows explode, the radius of explosion in hammer units.", FCVAR_PLUGIN, true, 1.0);
	g_Cvar_ExplodeDamage = CreateConVar("huntsmanhell_explodedamage", "50.0", "If arrows explode, the damage the explosion does.", FCVAR_PLUGIN, true, 1.0);
	g_Cvar_ExplodeFire = CreateConVar("huntsmanhell_explodefire", "1.0", "Should explosions catch players on fire?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ExplodeFireSelf = CreateConVar("huntsmanhell_explodefireself", "0.0", "Should explosions catch yourself on fire?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_FireArrows = CreateConVar("huntsmanhell_firearrows", "1.0", "Should all arrows catch on fire in Huntsman Hell?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ArrowCount = CreateConVar("huntsmanhell_arrowmultiplier", "4.0", "How many times the normal number of arrows should we have? Normal arrow count is 13", FCVAR_PLUGIN, true, 0.0, true, 8.0);
	g_Cvar_StartingHealth = CreateConVar("huntsmanhell_health", "400.0", "Amount of Health players to start with", FCVAR_PLUGIN, true, 65.0, true, 800.0);
	g_Cvar_SuperJump = CreateConVar("huntsmanhell_superjump", "1.0", "Should super jump be enabled in Huntsman Hell?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//g_Cvar_DoubleJump = CreateConVar("huntsmanhell_doublejump", "1.0", "Should double jump be enabled in Huntsman Hell?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_FallDamage = CreateConVar("huntsmanhell_falldamage", "0.0", "Should players take fall damage?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("post_inventory_application", Event_Inventory);
	//HookEvent("player_changeclass", Event_ChangeClass);
	
	jumpHUD = CreateHudSynchronizer();
	LoadTranslations("huntsmanhell.phrases");
	AutoExecConfig(true, "huntsmanhell");
}

public OnAllPluginsLoaded()
{
	g_SteamTools = LibraryExists("SteamTools");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = false;
	}
}

public OnMapStart()
{
	for (new i = 0; i < sizeof(g_Sounds_Explode); ++i)
	{
		PrecacheSound(g_Sounds_Explode[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_Jump); ++i)
	{
		PrecacheSound(g_Sounds_Jump[i]);
	}
}

public OnMapEnd()
{
	if (g_Enabled && g_SteamTools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
}

public OnConfigsExecuted()
{
	g_Enabled = GetConVarBool(g_Cvar_Enabled);
	
	if (g_Enabled)
	{
		if (g_LateLoad)
		{
			for (new i = 1; i <= MaxClients; ++i)
			{
				if (IsClientInGame(i))
				{
					SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				}
			}
			g_LateLoad = false;
		}
		
		UpdateGameDescription();
		CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientPutInServer(client)
{
	if (g_Enabled)
	{
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
	{
		return;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_JumpCharge[i] = 0;
	}
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	if (class != TFClass_Sniper)
	{
		TF2_SetPlayerClass(client, TFClass_Sniper);
		TF2_RespawnPlayer(client);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	if (class != TFClass_Sniper)
	{
		// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
		TF2_SetPlayerClass(client, TFClass_Sniper, false); 
		
		TF2_RespawnPlayer(client);
	}

	SetEntProp(client, Prop_Data, "m_iMaxHealth", GetConVarInt(g_Cvar_StartingHealth));
	SetEntProp(client, Prop_Send, "m_iHealth", GetConVarInt(g_Cvar_StartingHealth));
}

public Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (TF2_GetPlayerClass(client) != TFClass_Sniper)
	{
		return;
	}
	
	new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	
	if (secondary == -1)
	{
		new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(item, "tf_weapon_jar");
		TF2Items_SetItemIndex(item, 58);
		TF2Items_SetLevel(item, 5);
		TF2Items_SetQuality(item, 6);
		TF2Items_SetNumAttributes(item, 2);
		TF2Items_SetAttribute(item, 0, 56, 1.0);
		TF2Items_SetAttribute(item, 1, 292, 4.0);
		secondary = TF2Items_GiveNamedItem(client, item);
		CloseHandle(item);
		EquipPlayerWeapon(client, secondary);
	}

	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if (primary == -1)
	{
		new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(item, "tf_weapon_compound_bow");
		TF2Items_SetItemIndex(item, 56);
		TF2Items_SetLevel(item, 10);
		TF2Items_SetQuality(item, 6);
		TF2Items_SetNumAttributes(item, 1);
		//TF2Items_SetAttribute(item, 0, 37, 0.5);
		TF2Items_SetAttribute(item, 0, 328, 1.0);
		primary = TF2Items_GiveNamedItem(client, item);
		CloseHandle(item);
		EquipPlayerWeapon(client, primary);
	}
	
	TF2Attrib_SetByName(primary, "hidden primary max ammo bonus", GetConVarFloat(g_Cvar_ArrowCount) / 2.0);
	
	new healthDiff = (GetConVarInt(g_Cvar_StartingHealth) - 125);
	
	if (healthDiff > 0)
	{
		TF2Attrib_SetByName(client, "max health additive bonus", float(healthDiff));
	}
	else if (healthDiff < 0)
	{
		TF2Attrib_SetByName(client, "max health additive penalty", float(healthDiff));
	}
	
//	if (GetConVarBool(g_Cvar_DoubleJump))
//	{
//		TF2Attrib_SetByName(client, "increased jump height", 1.5);
//	}
	
	if (!GetConVarBool(g_Cvar_FallDamage))
	{
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	}
	
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	static Handle:item = INVALID_HANDLE;
	
	if (!g_Enabled)
	{
		return Plugin_Continue;
	}
	
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	
	// Block SMG, shields, and sniper rifles
	if (StrEqual(classname, "tf_weapon_smg") || iItemDefinitionIndex == 57 || iItemDefinitionIndex == 231 || iItemDefinitionIndex == 642|| StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!g_Enabled)
	{
		return;
	}
	
	if (StrEqual(classname, ARROW))
	{
		
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
	}

}

public Arrow_Explode(entity, other)
{
	new Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	new String:teamString[2];
	new String:magnitudeString[6];
	new String:radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	GetConVarString(g_Cvar_ExplodeDamage, magnitudeString, sizeof(magnitudeString));
	GetConVarString(g_Cvar_ExplodeRadius, radiusString, sizeof(radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");
	// Destroy it after a tenth of a second so it still exists during OnTakeDamagePost
	CreateTimer(0.1, Timer_DestroyExplosion, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	
	new random = GetRandomInt(0, sizeof(g_Sounds_Explode)-1);
	EmitSoundToAll(g_Sounds_Explode[random], entity, SNDCHAN_WEAPON, _, _, _, _, _, origin);
}

public Action:Timer_DestroyExplosion(Handle:timer, any:explosionRef)
{
	new explosion = EntRefToEntIndex(explosionRef);
	if (explosion != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(explosion, "Kill");
	}
	
	return Plugin_Continue;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!g_Enabled || !GetConVarBool(g_Cvar_ExplodeFire) || victim <= 0 || victim > MaxClients || !IsValidEntity(inflictor))
	{
		return;
	}
	
	new String:classname[64];
	if (GetEntityClassname(inflictor, classname, sizeof(classname)) && StrEqual(classname, "env_explosion"))
	{
		new owner = GetEntPropEnt(inflictor, Prop_Data, "m_hOwnerEntity");
		if (owner <= 0 || owner > MaxClients || (!GetConVarBool(g_Cvar_ExplodeFireSelf) && victim == owner) )
		{
			return;
		}
		TF2_IgnitePlayer(victim, owner);
	}
}

UpdateGameDescription()
{
	if (g_SteamTools && g_Enabled)
	{
		new String:gamemode[32];
		
		Format(gamemode, sizeof(gamemode), "%s v.%s", "Huntsman Hell", VERSION);
		Steam_SetGameDescription(gamemode);
	}
}

public Action:JumpTimer(Handle:hTimer)
{
	if (!g_Enabled)
	{
		return Plugin_Stop;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (GetConVarBool(g_Cvar_FireArrows))
		{
			new primary = GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
			new currentWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (primary == currentWeapon && GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 0)
			{
				SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
			}
		}
		
		if (!GetConVarBool(g_Cvar_SuperJump))
		{
			continue;
		}
		
		SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
		new buttons = GetClientButtons(i);
		if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (g_JumpCharge[i] >= 0) && !(buttons & IN_JUMP))
		{
			if (g_JumpCharge[i] + 5 < JUMPCHARGE)
			{
				g_JumpCharge[i] += 5;
			}
			else
			{
				g_JumpCharge[i] = JUMPCHARGE;
			}
			
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status", g_JumpCharge[i]*4);
		}
		else if (g_JumpCharge[i] < 0)
		{
			g_JumpCharge[i] += 5;
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status_2", -g_JumpCharge[i]/20);
		}
		else
		{
			decl Float:ang[3];
			GetClientEyeAngles(i, ang);
			if ((ang[0] < -45.0) && (g_JumpCharge[i] > 1))
			{
				decl Float:pos[3];
				decl Float:vel[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
				vel[2]=750 + g_JumpCharge[i] * 13.0;
				SetEntProp(i, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				vel[1] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
				g_JumpCharge[i]=-120;
				
				new random = GetRandomInt(0, sizeof(g_Sounds_Jump)-1);
				EmitSoundToAll(g_Sounds_Jump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
			}
			else
			{
				g_JumpCharge[i] = 0;
			}
		}
	}
	
	return Plugin_Continue;
}

