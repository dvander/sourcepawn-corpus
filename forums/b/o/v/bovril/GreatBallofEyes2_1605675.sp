#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1.1"

new Float:g_pos[3];

new g_iLetsChangeThisEvent = 0;

new Handle:v_BaseHP_Level2 = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;
new Handle:v_HP_Per_Level = INVALID_HANDLE;

new Handle:cvar_eyeboss_xcoord;
new Handle:cvar_eyeboss_ycoord;
new Handle:cvar_eyeboss_zcoord;

public Plugin:myinfo =
{
	name = "[TF2] Monoculus Spawner",
	author = "DarthNinja mod by Bovril",
	description = "Spawns a Monoculus at the centre of the map.",
	version = PLUGIN_VERSION,
	url = "ThisLD.com"
}

public OnPluginStart()
{
	CreateConVar("sm_monospawn_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_eyeboss_xcoord = CreateConVar("vip_eyeboss_xcoord", "0.0", "x coordinate at which eyeboss is summoned");
	cvar_eyeboss_ycoord = CreateConVar("vip_eyeboss_ycoord", "0.0", "y coordinate at which eyeboss is summoned");
	cvar_eyeboss_zcoord = CreateConVar("vip_eyeboss_zcoord", "-700.0", "z coordinate at which eyeboss is summoned");
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
		
		g_pos[0] = GetConVarFloat(cvar_eyeboss_xcoord);
		g_pos[1] = GetConVarFloat(cvar_eyeboss_ycoord);
		g_pos[2] = GetConVarFloat(cvar_eyeboss_zcoord);
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
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