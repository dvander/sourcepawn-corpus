#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
	
#pragma newdecls required
 
//Create ConVar handles
ConVar g_ConVar_Enabled;
ConVar g_ConVar_Debug;
ConVar g_ConVar_pDistance;
ConVar g_ConVar_vKnockback;
ConVar g_ConVar_hKnockback;
ConVar g_ConVar_StamPenalty;
ConVar g_ConVar_dmgCap;
ConVar g_ConVar_iTime;
ConVar g_ConVar_ringSize;
//Separate ConVar variables to prevent looping in hooks
bool g_Enabled = true;
bool g_Debug = false;
float g_pDistance = 1.0;
float g_vKnockback = 1.0;
float g_hKnockback = 1.0;
float g_StamPenalty = 0.0;
float g_dmgCap = 50.0;
float g_iTime = 0.0;
float g_ringSize = 0.0;
int g_StaminaOffset = -1;
int g_beamsprite = 0;
int g_halosprite = 0;
//Create our hash map handles
StringMap hMapDirection;
StringMap hMapOrigin;

public Plugin myinfo =  {
	name = "Nade_Kick",
	author = "AgentWesker",
	description = "Zombie knockback plugin.",
	version = "1.9",
	url = "http://steam-gamers.net"
};
 
public void OnPluginStart()
{

	//Get stamina offset
	g_StaminaOffset = FindSendPropInfo("CCSPlayer", "m_flStamina");
	if (g_StaminaOffset == -1) {  
		SetFailState("CCSPlayer::m_flStamina could not be found.");
	}
	
	//Stamina ConVar
	g_ConVar_StamPenalty = CreateConVar("sm_nadekick_stampenalty", "100.0", "How much to slow the player. Default = 100.0", _, true, 0.0, true, 100.0);
	g_StamPenalty = GetConVarFloat(g_ConVar_StamPenalty);
	HookConVarChange(g_ConVar_StamPenalty, OnConVarChanged);
	
	//Damage Cap ConVar
	g_ConVar_dmgCap = CreateConVar("sm_nadekick_dmgcap", "30.0", "How much damage can affect velocity. Default = 50.0", _, true, 1.0, true, 100.0);
	g_dmgCap = GetConVarFloat(g_ConVar_dmgCap);
	HookConVarChange(g_ConVar_dmgCap, OnConVarChanged);
	
	//Enabled ConVar
	g_ConVar_Enabled = CreateConVar("sm_nadekick_enabled", "1", "Enable/Disable the plugin. Enable = 1", _, true, 0.0, true, 1.0);
	g_Enabled = GetConVarBool(g_ConVar_Enabled);
	HookConVarChange(g_ConVar_Enabled, OnConVarChanged);
	
	//Debug ConVar
	g_ConVar_Debug = CreateConVar("sm_nadekick_debug", "0", "Print debug to chat. Enable = 1", _, true, 0.0, true, 1.0);
	g_Debug = GetConVarBool(g_ConVar_Debug);
	HookConVarChange(g_ConVar_Debug, OnConVarChanged);
	
	//Distance ConVars
	g_ConVar_pDistance = CreateConVar("sm_nadekick_pdistance", "115.0", "How far to measure in front of attacker. Default = 115.0", _, true, 0.1, true, 1500.0);
	g_pDistance = GetConVarFloat(g_ConVar_pDistance);
	HookConVarChange(g_ConVar_pDistance, OnConVarChanged);
	
	//Ignite ConVar
	g_ConVar_iTime = CreateConVar("sm_nadekick_itime", "5.0", "How long to ignite the victim. Disabled = 0", _, true, 0.0, true, 15.0);
	g_iTime = GetConVarFloat(g_ConVar_iTime);
	HookConVarChange(g_ConVar_iTime, OnConVarChanged);
	
	//Grenade Ring ConVar
	g_ConVar_ringSize = CreateConVar("sm_nadekick_ringSize", "375.0", "How large to make the ring effect. Disabled = 0", _, true, 0.0, true, 800.0);
	g_ringSize = GetConVarFloat(g_ConVar_ringSize);
	HookConVarChange(g_ConVar_ringSize, OnConVarChanged);
	
	//Knockback ConVars
	g_ConVar_vKnockback = CreateConVar("sm_nadekick_vknockback", "20.0", "Vertical knockback multiplier. Default = 20.0", _, true, 0.1, true, 1000.0);
	g_ConVar_hKnockback = CreateConVar("sm_nadekick_hknockback", "30.0", "Horizontal knockback multiplier. Default = 30.0", _, true, 0.1, true, 1000.0);
	g_vKnockback = GetConVarFloat(g_ConVar_vKnockback);
	g_hKnockback = GetConVarFloat(g_ConVar_hKnockback);
	HookConVarChange(g_ConVar_vKnockback, OnConVarChanged);
	HookConVarChange(g_ConVar_hKnockback, OnConVarChanged);
	
	//Hook events
	HookEvent("player_death", OnPlayerDeath);
	if (g_ringSize > 10.0) {
		HookEvent("hegrenade_detonate", OnHeDetonate);
	}
	
	//Create our hash maps
	hMapDirection = new StringMap();
	hMapOrigin = new StringMap();
	
	//Execute the config and create if not yet made
	AutoExecConfig(true, "nade_kick");
	
	//Late plugin load (or reload)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart() 
{
	g_beamsprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo.vmt");
}

public void OnConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if (convar == g_ConVar_Enabled) {
		if (StringToInt(newVal) == 1) {
			g_Enabled = true;
			HookClients();
		} else {
			g_Enabled = false;
			UnHookClients();
		}
	} else if (convar == g_ConVar_Debug) {
		if (StringToInt(newVal) == 1) {
			g_Debug = true;
		} else {
			g_Debug = false;
		}
	} else if (convar == g_ConVar_pDistance) {
		g_pDistance = StringToFloat(newVal);
	} else if (convar == g_ConVar_vKnockback) {
		g_vKnockback = StringToFloat(newVal);
	} else if (convar == g_ConVar_hKnockback) {
		g_hKnockback = StringToFloat(newVal);
	} else if (convar == g_ConVar_StamPenalty) {
		g_StamPenalty = StringToFloat(newVal);
	} else if (convar == g_ConVar_dmgCap) {
		g_dmgCap = StringToFloat(newVal);
	} else if (convar == g_ConVar_iTime) {
		g_iTime = StringToFloat(newVal);
	} else if (convar == g_ConVar_ringSize) {
		g_ringSize = StringToFloat(newVal);
		if (g_ringSize > 10.0) {
			HookEvent("hegrenade_detonate", OnHeDetonate);
		} else {
			UnhookEvent("hegrenade_detonate", OnHeDetonate);
		}
	}
}

public void HookClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		}
	}
}

public void UnHookClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		}
	}
}

public void OnClientPutInServer(int client)
{
	//dont hook stuff that isnt needed :)
	if(!g_Enabled)
		return;
	
	//Use an SDKHook for inflictor index
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void OnClientDisconnect(int client)
{
	//Get rid of this timer (?)
	if (IsClientInGame(client)) {
		ExtinguishEntity(client);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	OnClientDisconnect(GetClientOfUserId(GetEventInt(event, "userid")));
}

public void OnEntityCreated(int entity, const char[] classname)
{
	//Is the plugin enabled? Otherwise don't continue
	if (!g_Enabled) {
		return;
	}
	//Is this a valid entity?
	if (IsValidEdict(entity)) {
		char class_name[32];
		GetEdictClassname(entity, class_name, 32);
		//Only hook projectiles if they are valid
		if (StrContains(class_name, "hegrenade_projectile", false) != -1 && IsValidEntity(entity)) {
			if (g_Debug) {
				PrintToChatAll("[SM]Nade Kick: Hooked projectile %d", entity);
			}
			//Hook the entity, we must wait until post spawn
			SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
		}
	}
}

public void OnEntitySpawned(int entity)
{
	if (!g_Enabled) {
		return;
	}
	
	if (g_iTime > 0.0) {
		IgniteEntity(entity, 2.0);
	}
	
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"); //The client
   
	//Origin vectors define position (X, Y, Z)
	//Angle vectors define orientation (Pitch, Yaw, Roll)
	//Magnitude vectors define direction (X, Y, Z) anything from zero is distance
   
	//Create vector from player
	float pEyeOrigin[3], pEyeAngles[3];
	GetClientEyePosition(owner, pEyeOrigin); //Player origin
	GetClientEyeAngles(owner, pEyeAngles); //Player angles
	
	//Flatten player angles along Z axis
	pEyeAngles[0] = 0.0; //Set pitch
	pEyeAngles[2] = 0.0; //Set roll
	
	if (g_Debug) {
		PrintToChatAll("[SM]Nade Kick: %N angle is %f", owner, pEyeAngles[1]);
	}
	
	//Get direction
	GetAngleVectors(pEyeAngles, pEyeAngles, NULL_VECTOR, NULL_VECTOR); //Transform into vector
	NormalizeVector(pEyeAngles, pEyeAngles); //Clamp vector
	ScaleVector(pEyeAngles, g_pDistance); //How far ahead of player we go
	AddVectors(pEyeOrigin, pEyeAngles, pEyeOrigin); //Move origin along vector
	
	//Save pgVector to hash
	char entStr[12];
	IntToString(entity, entStr, 12);
	hMapDirection.SetArray(entStr, pEyeAngles, 3, true);
	hMapOrigin.SetArray(entStr, pEyeOrigin, 3, true);
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, 
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	//Stop if disabled
	if (!g_Enabled) {
		return;
	}

	//Validate players
	if (!IsValidClient(attacker) || !IsValidClient(victim)) {
		return;
	}
	
	char sWeapon[32];
	GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
	
	// If the player is a zombie and it is hurt with a grenade
	//if ((GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3) && StrContains("hegrenade_projectile", sWeapon, false) != -1 && damage >= 2.0) {
	if ((ZR_IsClientZombie(victim) && ZR_IsClientHuman(attacker)) && StrContains("hegrenade_projectile", sWeapon, false) != -1 && damage >= 2.0) {
	
		//Initialize vector handles, aForward and aVictim directions
		float victimOrigin[3], attackerOrigin[3], grenadeOrigin[3], afVector[3], avVector[3];
		
		if (g_Debug) {
			char nameentname[225];
			GetEdictClassname(inflictor, nameentname, sizeof(nameentname));
			PrintToChatAll("[SM]Nade Kick: Inflictor ent %d, %s", inflictor, nameentname);
		}
		
		//Use entity index as key and grab afVector from hash
		char inflictorStr[12];
		IntToString(inflictor, inflictorStr, 12);
		
		//Check that hash values return successfully otherwise call the cops
		if (!hMapDirection.GetArray(inflictorStr, afVector, 3, _)) {
			ThrowError("Attacker has no direction vector, inflictor not found!");
		}
		else if (!hMapOrigin.GetArray(inflictorStr, attackerOrigin, 3, _)) {
			ThrowError("Attacker has no origin vector, inflictor not found!");
		}
		
		//Get the origin vector for victim
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimOrigin);
		
		//Make new vector from player to victim
		MakeVectorFromPoints(attackerOrigin, victimOrigin, avVector);
		NormalizeVector(avVector, avVector);
		
		//Re-normalize the attacker forward vector
		NormalizeVector(afVector, afVector);
		
		//Get the angle between player forward view and player viewing victim
		float dot = GetVectorDotProduct(afVector, avVector); //Get initial dot product
		dot = (dot / FloatMul(GetVectorLength(avVector, true), GetVectorLength(afVector, true))); //Divide by vector magnitude
		float vectorAngle = RadToDeg(ArcCosine(dot)); //Get angle in radians, then convert to degrees


		if (g_Debug) {
			PrintToChatAll("[SM]Nade Kick: %N angle is %f", victim, vectorAngle);
			PrintToChatAll("[SM]Nade Kick: %N took %f damage", victim, damage);
		}
		
		float dmgMulti = damage;
		if (damage >= g_dmgCap) {
			dmgMulti = g_dmgCap;
		}
		
		//Check if victim is behind attacker
		if (vectorAngle <= 90.0) {
			GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", grenadeOrigin);
			
			MakeVectorFromPoints(grenadeOrigin, victimOrigin, avVector);
			NormalizeVector(avVector, avVector);
			
			dot = GetVectorDotProduct(afVector, avVector); //Get initial dot product
			dot = (dot / FloatMul(GetVectorLength(avVector, true), GetVectorLength(afVector, true))); //Divide by vector magnitude
			vectorAngle = RadToDeg(ArcCosine(dot)); //Get angle in radians, then convert to degrees
			
			if (vectorAngle <= 80.0) {
				afVector[0] = avVector[0];
				afVector[1] = avVector[1];
			}
			
			//Scale original values to maintain direction
			ScaleVector(afVector, g_hKnockback); //Scale by multiplier
			ScaleVector(afVector, dmgMulti); //Scale by damage
		} else {
			//Only go vertical
			afVector[0] = 0.0;
			afVector[1] = 0.0;
		}
		
		afVector[2] = FloatMul(g_vKnockback, dmgMulti); //Set vertical velocity

		//Only ignite if we have time
		if (g_iTime > 0.0) {
			//Don't double ignite
			ExtinguishEntity(victim);
			IgniteEntity(victim, g_iTime);
		}
		
		// Apply the directional push
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, afVector);
		//Slow the player
		if (g_StamPenalty > 0.0) {
			SetEntDataFloat(victim, g_StaminaOffset, g_StamPenalty, true);
		}
	}
}

public bool IsValidClient(int client) {
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	if (!IsPlayerAlive(client)) {
		return false;
	}
	return true;
}  

public void OnHeDetonate(Event event, const char[] name, bool dontBroadcast) {
	//Stop if disabled
	if ((!g_Enabled) || (g_ringSize <= 10.0)) {
		return;
	}
	
	//Get the origin for the ring
	float origin[3];
	origin[0] = GetEventFloat(event, "x");
	origin[1] = GetEventFloat(event, "y");
	origin[2] = GetEventFloat(event, "z");
	
	//Color the ring
	int fragColor[4] = {255,75,75,255};
	//Set the life time
	float ringLife = FloatDiv(g_ringSize, 1000.0);
	if (ringLife < 0.1) {
		ringLife = 0.1;
	}
	
	TE_SetupBeamRingPoint(origin, 10.0, g_ringSize, g_beamsprite, g_halosprite, 1, 1, ringLife, 5.0, 1.0, fragColor, 0, 0);
	TE_SendToAll();
}