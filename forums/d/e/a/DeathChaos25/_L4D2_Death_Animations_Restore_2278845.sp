/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* [L4D2] Special Infected Warnings Vocalize Fix
* 
* About : This plugin restores the Survivor Death Animations while
* also fixing the bug where the animations would endlessly loop and
* the survivors would never actually die
* 
* =============================
* ===      Change Log       ===
* =============================
* Version 1.0    2014-09-02  (48 views)
* - Initial Release
* =============================
* Version 1.1    2014-09-05
* - Semi Major code re-write, moved from using a "player_hurt" event hook
*   to SDK_Tools OnTakeDamagePost (Huge thanks to Mr.Zero for that, as he did most of it)
* 
* - Hopefully, there should no longer be any cases were survivors
*   endlessly loop through their death animations and never die
* =============================
* Version 1.3	 2014-09-09
* - Survivors are no longer able to perform any actions while
*   in the middle of their death animations  (except vocalizing under certain circumstances).
* =============================
* Version 1.4    03-25-2015
* - Complete Plugin Rewrite, this plugin no longer uses shitty damage detection!
* - This plugin will now ALWAYS 100% Guarantee work as intended, this is done by the new check
* - The plugin now instead of predicting when you die, it will instead check for clients
*   to see if they are in the dying animation instead, this means now players will only
*   die when the game decides it and this thus removes any and all faulty damage detections
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#include <sourcemod> 
#include <sdkhooks> 
#include <l4d_stocks>
#include <defibfix>

#define DEBUG 0

#define PLUGIN_VERSION "1.4" 
#define PLUGIN_NAME "[L4D2] Restore Survivor Death Animations" 

static const String:MODEL_NICK[] 		= "models/survivors/survivor_gambler.mdl";
static const String:MODEL_ROCHELLE[] 		= "models/survivors/survivor_producer.mdl";
static const String:MODEL_COACH[] 		= "models/survivors/survivor_coach.mdl";
static const String:MODEL_ELLIS[] 		= "models/survivors/survivor_mechanic.mdl";
static const String:MODEL_BILL[] 		= "models/survivors/survivor_namvet.mdl";
static const String:MODEL_ZOEY[] 		= "models/survivors/survivor_teenangst.mdl";
static const String:MODEL_FRANCIS[] 		= "models/survivors/survivor_biker.mdl";
static const String:MODEL_LOUIS[] 		= "models/survivors/survivor_manager.mdl";

static bool:g_bIsRagdollDeathEnabled 
static bool:g_bIsSurvivorInDeathAnimation[MAXPLAYERS+1] = false 

public Plugin:myinfo =  
{ 
	name        = PLUGIN_NAME, 
	author        = "DeathChaos25", 
	description    = "Restores the Death Animations for survivors while fixing the bug where the animation would loop endlessly and the survivors would never die.", 
	version        = PLUGIN_VERSION, 
	url        = "https://forums.alliedmods.net/showthread.php?t=247488", 
} 

public OnPluginStart() 
{ 
	SetConVarInt(FindConVar("survivor_death_anims"), 1) 
	
	CreateTimer(0.1, TimerUpdate, _, TIMER_REPEAT);
	new Handle:RagdollDeathEnabled = CreateConVar("enable_ragdoll_death", "1", "Enable Ragdolls upon Death? 0 = Disable Ragdoll Death, 1 = Enable Ragdoll Death", FCVAR_PLUGIN, true, 0.0, true, 1.0)  
	HookConVarChange(RagdollDeathEnabled, ConVarRagdollDeathEnabled)  
	g_bIsRagdollDeathEnabled = GetConVarBool(RagdollDeathEnabled)  
	HookEvent("defibrillator_begin", DefibStart_Event);
	AutoExecConfig(true, "l4d2_death_animations_restore")  ;
	HookEvent("weapon_fire", Event_WeaponFire);
} 

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnAllPluginsLoaded()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
	}
}  

public Action:TimerUpdate(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i) && !g_bIsSurvivorInDeathAnimation[i])
		{
			new i_CurrentAnimation = GetEntProp(i, Prop_Send, "m_nSequence");
			decl String:model[PLATFORM_MAX_PATH];
			GetClientModel(i, model, sizeof(model));
			
			// Zoey & Francis Death Animation is 555
			// Louis & Bill Death Animation is 552
	
			// Nick Death Animation is 644
			// Ellis Death Animation is 649
			// Coach Death Animation is 638
			// Rochelle Death Animation is 652
			
			if(i_CurrentAnimation == 555 && StrEqual(model, MODEL_FRANCIS, false)
			|| i_CurrentAnimation == 555 && StrEqual(model, MODEL_ZOEY, false)
			|| i_CurrentAnimation == 552 && StrEqual(model, MODEL_BILL, false) 
			|| i_CurrentAnimation == 552 && StrEqual(model, MODEL_LOUIS, false)
			|| i_CurrentAnimation == 644 && StrEqual(model, MODEL_NICK, false)
			|| i_CurrentAnimation == 649 && StrEqual(model, MODEL_ELLIS, false)
			|| i_CurrentAnimation == 638 && StrEqual(model, MODEL_COACH, false)
			|| i_CurrentAnimation ==  652 && StrEqual(model, MODEL_ROCHELLE, false))
			{
				g_bIsSurvivorInDeathAnimation[i] = true
				CreateTimer(3.03, ForcePlayerSuicideTimer, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE) 
				return Plugin_Continue
			}
		}
	}
	return Plugin_Continue;
}

public Action:ForcePlayerSuicideTimer(Handle:timer, any:userid) 
{ 
	new client = GetClientOfUserId(userid) 
	if (client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Continue
	
	if (g_bIsRagdollDeathEnabled == true) { 
		
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) 
		
		new weapon = GetPlayerWeaponSlot(client, 1) 
		if (weapon > 0 && IsValidEntity(weapon)) { 
			SDKHooks_DropWeapon(client, weapon) // Drop their secondary weapon since they cannot be defibed 
		} 
		// This section will be re-enabled later if/when spummer
		// publicly releases the new defibfix
		
		// Now we create a static death model for this person
		// this is simply compatibility
		// with mournfix
		
		// EDIT : Spummer compiled a new defibfix, THIS PLUGINS
		// DEATHMODELS ARE NOW LEGIT, THEY WORK CORRECTLY WOOT
		
		new entity;
		new String:modelname[128];
		GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
		
		entity = CreateEntityByName("survivor_death_model");
		SetEntityModel(entity, modelname);
		
		new Float:g_Origin[3];
		new Float:g_Angle[3];
		
		GetClientAbsOrigin(client, g_Origin);
		GetClientAbsAngles(client, g_Angle);
		
		TeleportEntity(entity, g_Origin, g_Angle, NULL_VECTOR);
		DispatchSpawn(entity);
		SetEntityRenderMode(entity, RENDER_NONE);
		DefibFix_AssignPlayerDeathModel(client, entity);
		new character_type = GetEntProp(client, Prop_Send, "m_survivorCharacter")
		SetEntProp(entity, Prop_Send, "m_nCharacterType", character_type);
		#if DEBUG
		{
			decl String:message[PLATFORM_MAX_PATH]="";
			Format(message, sizeof(message), "Client %N has been slain because he was in Dying Animation!", client);
			PrintToChatAll(message);
		}
		#endif
	} 
	
	ForcePlayerSuicide(client) 
	g_bIsSurvivorInDeathAnimation[client] = false 
	
	return Plugin_Continue 
} 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (!IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client) || !g_bIsSurvivorInDeathAnimation[client]) 
		return Plugin_Continue
	return Plugin_Handled
}  

public ConVarRagdollDeathEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) 
{ 
	g_bIsRagdollDeathEnabled = GetConVarBool(convar)  
}

stock bool:IsSurvivor(client)
{
	new maxclients = GetMaxClients();
	if (client > 0 && client < maxclients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

// blocks weapon change when in dying animation
public Action:OnWeaponSwitch(client, weapon)
{
	if (IsSurvivor(client) && IsPlayerAlive(client))
	{
		if (g_bIsSurvivorInDeathAnimation[client])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public DefibStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	#if DEBUG
	{
		//SetEntProp(client, Prop_Send, "m_reviveTarget", subject);
		decl String:message[PLATFORM_MAX_PATH]="";
		Format(message, sizeof(message), "Player %N is reviving Player %N with a Defib!", client, subject);
		PrintToChatAll(message);
	}
	#endif
}

// Even with all the checks and action blocks, survivors are still able to attempt to use
// medkits while in the death animation, and while they can't heal they can still
// interrupt the death animation, so we use weapon_fire to (hopefully) stop that
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client))
	{
		return Plugin_Continue
	}
	
	if (g_bIsSurvivorInDeathAnimation[client])
	{
		#if DEBUG
		{
			decl String:message[PLATFORM_MAX_PATH]="";
			Format(message, sizeof(message), "Player %N is trying to use a weapon while in Death Animation!", client);
			PrintToChatAll(message);
		}
		#endif
		return Plugin_Handled
	}	
	return Plugin_Continue
}
