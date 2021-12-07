/************************************************************************
  [L4D & L4D2] Graves (v1.0.1, 2018-12-27)

  DESCRIPTION: 
  
    When a survivor dies, a grave appears near his body, and this grave 
    glows through the objects on the map, allowing a quick location from 
    where the survivor died. 

    And when the survivor respawns, the grave associated with him disappears.

    In addition, there are six types of grave that are chosen randomly.

    Maybe can be useful for use with a defibrillator (L4D2), or even for 
    those who use the "Emergency Treatment With First Aid Kit Revive And 
    CPR" (L4D) plugin, for example.

    Anyway, I made this more for fun than for some utility.

    This plugin is also based on the Tuty plugin (CSS Graves), which can 
    be found here:

    https://forums.alliedmods.net/showthread.php?p=867275

    But I rewrote all the code to run on Left 4 Dead 1 & 2.

    This code can be found on my github page here:

    https://github.com/samuelviveiros/l4d_graves

    Have fun!

  CHANGELOG:

  2018-12-27 (v1.0.1)
    - Function RemoveEntity has been replaced by function AcceptEntityInput, 
	passing the "Kill" parameter, so that it work with the online compiler.

  2018-12-26 (v1.0.0)
    - Initial release.

 ************************************************************************/

#include <sourcemod>
#include <sdktools>


//#pragma semicolon 1
//#pragma newdecls   required

#define PLUGIN_VERSION	"1.0.0"

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Graves",
	author = "samuelviveiros a.k.a Dartz8901",
	description = "When a survivor die, on his body appear a grave.",
	version = PLUGIN_VERSION,
	url = "https://github.com/samuelviveiros/l4d_graves"
};

#define SOLID_BBOX_SM	2
#define DAMAGE_AIM_SM	2

Handle g_hGravesEnabled = INVALID_HANDLE;
Handle g_hGraveGlow = INVALID_HANDLE;
Handle g_hGraveGlowColor = INVALID_HANDLE; // L4D2 only
Handle g_hGraveHealth = INVALID_HANDLE;

char g_aGraveModels[][] = {
	// graves
	"models/props_cemetery/grave_01.mdl",
	"models/props_cemetery/grave_02.mdl",
	"models/props_cemetery/grave_03.mdl",
	"models/props_cemetery/grave_04.mdl",
	"models/props_cemetery/grave_06.mdl",
	"models/props_cemetery/grave_07.mdl",

	// avoiding the "Late precache" message on the client console.
	"models/props_cemetery/gibs/grave_02a_gibs.mdl",
	"models/props_cemetery/gibs/grave_02b_gibs.mdl",
	"models/props_cemetery/gibs/grave_02c_gibs.mdl",
	"models/props_cemetery/gibs/grave_02d_gibs.mdl",
	"models/props_cemetery/gibs/grave_02e_gibs.mdl",
	"models/props_cemetery/gibs/grave_02f_gibs.mdl",
	"models/props_cemetery/gibs/grave_02g_gibs.mdl",
	"models/props_cemetery/gibs/grave_02h_gibs.mdl",
	"models/props_cemetery/gibs/grave_02i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03a_gibs.mdl",
	"models/props_cemetery/gibs/grave_03b_gibs.mdl",
	"models/props_cemetery/gibs/grave_03c_gibs.mdl",
	"models/props_cemetery/gibs/grave_03d_gibs.mdl",
	"models/props_cemetery/gibs/grave_03e_gibs.mdl",
	"models/props_cemetery/gibs/grave_03f_gibs.mdl",
	"models/props_cemetery/gibs/grave_03g_gibs.mdl",
	"models/props_cemetery/gibs/grave_03h_gibs.mdl",
	"models/props_cemetery/gibs/grave_03i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03j_gibs.mdl",
	"models/props_cemetery/gibs/grave_06a_gibs.mdl",
	"models/props_cemetery/gibs/grave_06b_gibs.mdl",
	"models/props_cemetery/gibs/grave_06c_gibs.mdl",
	"models/props_cemetery/gibs/grave_06d_gibs.mdl",
	"models/props_cemetery/gibs/grave_06e_gibs.mdl",
	"models/props_cemetery/gibs/grave_06f_gibs.mdl",
	"models/props_cemetery/gibs/grave_06g_gibs.mdl",
	"models/props_cemetery/gibs/grave_06h_gibs.mdl",
	"models/props_cemetery/gibs/grave_06i_gibs.mdl",
	"models/props_cemetery/gibs/grave_07a_gibs.mdl",
	"models/props_cemetery/gibs/grave_07b_gibs.mdl",
	"models/props_cemetery/gibs/grave_07c_gibs.mdl",
	"models/props_cemetery/gibs/grave_07d_gibs.mdl",
	"models/props_cemetery/gibs/grave_07e_gibs.mdl",
	"models/props_cemetery/gibs/grave_07f_gibs.mdl"
};

//
// Ripped directly from the "[L4D & L4D2] Flashlight Package" plugin (by SilverShot)
// http://forums.alliedmods.net/showthread.php?t=173257
//
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_graves_version", PLUGIN_VERSION, "[L4D & L4D2] Graves version", FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hGravesEnabled 	= CreateConVar("l4d_graves_enable", "1", "Enable or disable this plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGraveGlow 		= CreateConVar("l4d_graves_glow", "1", "Turn glow On or Off.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGraveGlowColor 	= CreateConVar("l4d_graves_glowcolor", "255 255 255", "RGB Color - Change the render color of the glow. Values between 0-255. Note: Only for Left 4 Dead 2.", FCVAR_NOTIFY);
	g_hGraveHealth 		= CreateConVar("l4d_graves_health", "1500", "Number of points of damage to take before breaking. For Left 4 Dead 2, 0 means don't break.", FCVAR_NOTIFY);

	HookEvent("player_death", Event_PlayerDeath);

	AutoExecConfig(true, "l4d_graves");
}

public void OnMapStart()
{
	for ( int i = 0; i < sizeof(g_aGraveModels); i++ )
	{
		PrecacheModel(g_aGraveModels[i]);
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if( GetConVarInt(g_hGravesEnabled) == 1 )
	{
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(IsSurvivor(victim))
		{		
			float origin[3];
			GetClientAbsOrigin(victim, origin);
			
			DataPack pack;
			CreateDataTimer(5.0, Timer_SpawnGrave, pack);
			pack.WriteFloat(origin[0]);
			pack.WriteFloat(origin[1]);
			pack.WriteFloat(origin[2]);
			pack.WriteCell(victim);
		}
	}
	return Plugin_Handled;
}

public Action Timer_SpawnGrave(Handle timer, DataPack corpse)
{
	int grave = -1;
	int client;
	float origin[3];

	corpse.Reset();
	origin[0] = corpse.ReadFloat();
	origin[1] = corpse.ReadFloat();
	origin[2] = corpse.ReadFloat();
	client = corpse.ReadCell();

	if ( IsL4D1() )
	{
		grave = CreateEntityByName("prop_glowing_object");
		if( !IsValidEntity(grave) )
		{
			return Plugin_Stop;
		}

		DispatchKeyValue(grave, "StartGlowing", (GetConVarInt(g_hGraveGlow)!=0)?"1":"0");
		SetEntityModel(grave, g_aGraveModels[GetRandomInt(0, 5)]);
		DispatchSpawn(grave);
		TeleportEntity(grave, origin, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(grave, MOVETYPE_NONE);
		SetEntProp(grave, Prop_Data, "m_nSolidType", SOLID_BBOX_SM);
		SetEntProp(grave, Prop_Data, "m_takedamage", DAMAGE_AIM_SM);
		SetEntProp(grave, Prop_Data, "m_iHealth", GetConVarInt(g_hGraveHealth));
	}
	else
	{
		grave = CreateEntityByName("prop_dynamic_override");
		if( !IsValidEntity(grave) )
		{
			return Plugin_Stop;
		}

		char buffer[32];
		GetConVarString(g_hGraveHealth, buffer, sizeof(buffer));
		DispatchKeyValue(grave, "health", buffer);
		DispatchKeyValue(grave, "glowrange", "0");
		DispatchKeyValue(grave, "glowrangemin", "190");
		GetConVarString(g_hGraveGlowColor, buffer, sizeof(buffer));
		DispatchKeyValue(grave, "glowcolor", buffer);
		DispatchKeyValue(grave, "solid", "2"); // bbox
		SetEntityModel(grave, g_aGraveModels[GetRandomInt(0, 5)]);
		DispatchSpawn(grave);
		TeleportEntity(grave, origin, NULL_VECTOR, NULL_VECTOR);
		if ( GetConVarInt(g_hGraveGlow) != 0 )
		{
			AcceptEntityInput(grave, "StartGlowing");
		}
	}

	DataPack pack;
	CreateDataTimer(1.0, Timer_RemoveGrave, pack, TIMER_REPEAT);
	pack.WriteCell(client);
	pack.WriteCell(grave);

	return Plugin_Stop;
}

public Action Timer_RemoveGrave(Handle timer, DataPack entities)
{
	entities.Reset();
	int client = entities.ReadCell();
	int grave = entities.ReadCell();

	if ( !IsClientConnected(client) )
	{
		if ( IsValidEntity(grave) )
		{
			AcceptEntityInput(grave, "Kill");
		}
		return Plugin_Stop;
	}

	if ( !IsClientInGame(client) )
	{
		if ( IsValidEntity(grave) )
		{
			AcceptEntityInput(grave, "Kill");
		}
		return Plugin_Stop;
	}

	if ( IsPlayerAlive(client) )
	{
		if ( IsValidEntity(grave) )
		{
			AcceptEntityInput(grave, "Kill");
		}
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock bool IsL4D1()
{
	EngineVersion engine = GetEngineVersion();
	return ( engine == Engine_Left4Dead );
}

stock bool:IsSurvivor(client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}
