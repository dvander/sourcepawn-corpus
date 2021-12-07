#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1.1"

new Float:g_pos[3];

new g_iLetsChangeThisEvent = 0;

new Handle:v_BaseHP_Level2 = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;
new Handle:v_HP_Per_Level = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Monoculus Spawner",
	author = "DarthNinja",
	description = "Spawns a Monoculus where you're looking.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_monospawn_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_eyeboss", GreatBallRockets, ADMFLAG_CHEATS);

	v_BaseHP_Level2 = FindConVar("tf_eyeball_boss_health_at_level_2");
	v_HP_Per_Player = FindConVar("tf_eyeball_boss_health_per_player");
	v_HP_Per_Level = FindConVar("tf_eyeball_boss_health_per_level");
	
	HookEvent("eyeball_boss_summoned", BossSummoned, EventHookMode_Pre);
}

public Action:BossSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iLetsChangeThisEvent != 0)
	{
		new Handle:hEvent = CreateEvent(name);
		if (hEvent == INVALID_HANDLE)
			return Plugin_Handled;
		
		SetEventInt(hEvent, "level", g_iLetsChangeThisEvent);
		FireEvent(hEvent);
		g_iLetsChangeThisEvent = 0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	CacheEyeBossSounds();
	CacheEyeBossModels();
}

public Action:GreatBallRockets(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}

	new entity = CreateEntityByName("eyeball_boss");

	if (IsValidEntity(entity))
	{
		new iLevel = 0;
		if (args == 1)
		{
			decl String:buffer[15];
			GetCmdArg(1, buffer, sizeof(buffer));
			iLevel = StringToInt(buffer);
		}

		DispatchSpawn(entity);
		
		if (iLevel > 1)
		{
			new iBaseHP = GetConVarInt(v_BaseHP_Level2);		//def 17,000
			new iHPPerLevel = GetConVarInt(v_HP_Per_Level);		//def  3,000
			new iHPPerPlayer = GetConVarInt(v_HP_Per_Player);	//def    400
			new iNumPlayers = GetClientCount(true);

			new iHP = iBaseHP;
			iHP = (iHP + ((iLevel - 2) * iHPPerLevel));
			if (iNumPlayers > 10)
				iHP = (iHP + ((iNumPlayers - 10)*iHPPerPlayer));

			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHP);
			SetEntProp(entity, Prop_Data, "m_iHealth", iHP);
			
			g_iLetsChangeThisEvent = iLevel;
		}
		
		g_pos[2] -= 10.0;
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
CacheEyeBossModels()
{
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl");
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl");
}

CacheEyeBossSounds()
{
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball01.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball02.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball03.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball04.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball05.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball06.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball07.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball08.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball09.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball10.wav");
	PrecacheSound("vo/halloween_eyeball/eyeball11.wav");
	
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("ui/halloween_boss_chosen_it.wav");
	PrecacheSound("ui/halloween_boss_defeated_fx.wav");
	PrecacheSound("ui/halloween_boss_defeated.wav");
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav");
	PrecacheSound("ui/halloween_boss_summoned_fx.wav");
	PrecacheSound("ui/halloween_boss_summoned.wav");
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
	PrecacheSound("ui/halloween_boss_escape.wav");
	PrecacheSound("ui/halloween_boss_escape_sixty.wav");
	PrecacheSound("ui/halloween_boss_escape_ten.wav");
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
}