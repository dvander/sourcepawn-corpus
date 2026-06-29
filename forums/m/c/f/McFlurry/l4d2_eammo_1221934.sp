#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		1

static Handle:IAtoEATransformCVAR = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Explosive Ammo Enable",
	author = "McFlurry",
	description = "Brings explosive ammo back in VS.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_eammo_version", PLUGIN_VERSION, " Version of Explosive Ammo Enable on this server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	IAtoEATransformCVAR = CreateConVar("l4d2_eammo_chance", "3", " Turns incendiary spawns into explosive spawns. Works as chance setting. 1 is FULL chance, 2 is half chance, 3 one third and so on ", DEFAULT_FLAGS);
	HookEvent("round_start", Event_Round_Start);	
	AutoExecConfig(true, "l4d2_eammo");
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(10.0, ReplaceIAWithEADelayed);
	if (!IsModelPrecached("models/w_models/weapons/w_eq_explosive_ammopack.mdl")) PrecacheModel("models/w_models/weapons/w_eq_explosive_ammopack.mdl");
	if (!IsModelPrecached("models/v_models/v_explosive_ammopack.mdl")) PrecacheModel("models/v_models/v_explosive_ammopack.mdl");
}

public Action:ReplaceIAWithEADelayed(Handle:timer)
{
	ReplaceIAWithEA(GetConVarInt(IAtoEATransformCVAR));
}

ReplaceIAWithEA(chance)
{
	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	if(StrEqual(GameMode, "versus") || StrEqual(GameMode, "teamversus"))
	{
		if (chance == 0) return;

		new ent = -1;
		new prev = 0;
		new replacement;
		decl Float:origin[3];
		decl Float:angles[3];
		while ((ent = FindEntityByClassname(ent, "weapon_upgradepack_incendiary_spawn")) != -1)
		{
			if (prev)
			{
				if (GetRandomInt(1, chance) == 1)
				{
					GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
					GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
				
					replacement = CreateEntityByName("weapon_upgradepack_explosive_spawn");
					DispatchSpawn(replacement);
					DebugPrintToAll("Replacing weapon_upgradepack_incendiary_spawn %i with weapon_upgradepack_explosive_spawn %i", prev, replacement);
					if (!IsValidEdict(replacement)) return;
					
					TeleportEntity(replacement, origin, angles, NULL_VECTOR);
					DebugPrintToAll("Teleported weapon_upgradepack_explosive_spawn %i into position, removing weapon_upgradepack_incendiary_spawn now", replacement);
				
					RemoveEdict(prev);
				}
			}
			prev = ent;
		}
		if (prev)
		{
			if (GetRandomInt(1, chance) == 1)
			{
				GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
				GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
			
				replacement = CreateEntityByName("weapon_upgradepack_explosive_spawn");
				DispatchSpawn(replacement);
				DebugPrintToAll("Replacing weapon_upgradepack_incendiary_spawn %i with weapon_upgradepack_explosive_spawn %i", prev, replacement);
				if (!IsValidEdict(replacement)) return;
			
				TeleportEntity(replacement, origin, angles, NULL_VECTOR);
				DebugPrintToAll("Teleported weapon_upgradepack_explosive_spawn %i into position, removing weapon_upgradepack_incendiary_spawn now", replacement);
			
				RemoveEdict(prev);
			}
		}
	}	
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("%s", buffer);
	PrintToConsole(0, "%s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}