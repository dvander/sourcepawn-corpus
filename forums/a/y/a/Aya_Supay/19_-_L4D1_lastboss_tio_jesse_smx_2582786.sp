/*
public PlVers:__version =
{
	version = 5,
	filevers = "1.7.0-manual",
	date = "02/25/2018",
	time = "12:46:31"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

Handle sm_lastboss_enable;
Handle sm_lastboss_enable_announce;
Handle sm_lastboss_enable_steel;
Handle sm_lastboss_enable_stealth;
Handle sm_lastboss_enable_gravity;
Handle sm_lastboss_enable_burn;
Handle sm_lastboss_enable_jump;
Handle sm_lastboss_enable_quake;
Handle sm_lastboss_enable_comet;
Handle sm_lastboss_enable_dread;
Handle sm_lastboss_enable_gush;
Handle sm_lastboss_enable_abyss;
Handle sm_lastboss_enable_warp;
Handle sm_lastboss_health_max;
Handle sm_lastboss_health_second;
Handle sm_lastboss_health_third;
Handle sm_lastboss_health_forth;
Handle sm_lastboss_color_first;
Handle sm_lastboss_color_second;
Handle sm_lastboss_color_third;
Handle sm_lastboss_color_forth;
Handle sm_lastboss_force_first;
Handle sm_lastboss_force_second;
Handle sm_lastboss_force_third;
Handle sm_lastboss_force_forth;
Handle sm_lastboss_speed_first;
Handle sm_lastboss_speed_second;
Handle sm_lastboss_speed_third;
Handle sm_lastboss_speed_forth;
Handle sm_lastboss_weight_second;
Handle sm_lastboss_stealth_third;
Handle sm_lastboss_jumpinterval_forth;
Handle sm_lastboss_jumpheight_forth;
Handle sm_lastboss_gravityinterval;
Handle sm_lastboss_quake_radius;
Handle sm_lastboss_quake_force;
Handle sm_lastboss_dreadinterval;
Handle sm_lastboss_dreadrate;
Handle sm_lastboss_forth_c5m5_bridge;
Handle sm_lastboss_warp_interval;
Handle TimerUpdate;
int alpharate;
int visibility;
int bossflag;
int lastflag;
int idBoss = -1;
int form_prev = -1;
int force_default;
int g_iVelocity = -1;
int wavecount;
float ftlPos[3];
bool g_l4d1;

////////////////////////////////////////////
//Descompilator = "By [†×Ą]AYA SUPAY[Ļ×Ø]"//
////////////////////////////////////////////

public Plugin myinfo =
{
	name = "[L4D] LAST BOSS",
	description = "Special Tank spawns during finale.",
	author = "ztar",
	version = "2.0",
	url = "http://ztar.blog7.fc2.com/"
};
/*
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEntity");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("BfWrite.WriteBool");
	MarkNativeAsOptional("BfWrite.WriteByte");
	MarkNativeAsOptional("BfWrite.WriteChar");
	MarkNativeAsOptional("BfWrite.WriteShort");
	MarkNativeAsOptional("BfWrite.WriteWord");
	MarkNativeAsOptional("BfWrite.WriteNum");
	MarkNativeAsOptional("BfWrite.WriteFloat");
	MarkNativeAsOptional("BfWrite.WriteString");
	MarkNativeAsOptional("BfWrite.WriteEntity");
	MarkNativeAsOptional("BfWrite.WriteAngle");
	MarkNativeAsOptional("BfWrite.WriteCoord");
	MarkNativeAsOptional("BfWrite.WriteVecCoord");
	MarkNativeAsOptional("BfWrite.WriteVecNormal");
	MarkNativeAsOptional("BfWrite.WriteAngles");
	MarkNativeAsOptional("BfRead.ReadBool");
	MarkNativeAsOptional("BfRead.ReadByte");
	MarkNativeAsOptional("BfRead.ReadChar");
	MarkNativeAsOptional("BfRead.ReadShort");
	MarkNativeAsOptional("BfRead.ReadWord");
	MarkNativeAsOptional("BfRead.ReadNum");
	MarkNativeAsOptional("BfRead.ReadFloat");
	MarkNativeAsOptional("BfRead.ReadString");
	MarkNativeAsOptional("BfRead.ReadEntity");
	MarkNativeAsOptional("BfRead.ReadAngle");
	MarkNativeAsOptional("BfRead.ReadCoord");
	MarkNativeAsOptional("BfRead.ReadVecCoord");
	MarkNativeAsOptional("BfRead.ReadVecNormal");
	MarkNativeAsOptional("BfRead.ReadAngles");
	MarkNativeAsOptional("BfRead.GetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	MarkNativeAsOptional("Protobuf.ReadInt");
	MarkNativeAsOptional("Protobuf.ReadFloat");
	MarkNativeAsOptional("Protobuf.ReadBool");
	MarkNativeAsOptional("Protobuf.ReadString");
	MarkNativeAsOptional("Protobuf.ReadColor");
	MarkNativeAsOptional("Protobuf.ReadAngle");
	MarkNativeAsOptional("Protobuf.ReadVector");
	MarkNativeAsOptional("Protobuf.ReadVector2D");
	MarkNativeAsOptional("Protobuf.GetRepeatedFieldCount");
	MarkNativeAsOptional("Protobuf.SetInt");
	MarkNativeAsOptional("Protobuf.SetFloat");
	MarkNativeAsOptional("Protobuf.SetBool");
	MarkNativeAsOptional("Protobuf.SetString");
	MarkNativeAsOptional("Protobuf.SetColor");
	MarkNativeAsOptional("Protobuf.SetAngle");
	MarkNativeAsOptional("Protobuf.SetVector");
	MarkNativeAsOptional("Protobuf.SetVector2D");
	MarkNativeAsOptional("Protobuf.AddInt");
	MarkNativeAsOptional("Protobuf.AddFloat");
	MarkNativeAsOptional("Protobuf.AddBool");
	MarkNativeAsOptional("Protobuf.AddString");
	MarkNativeAsOptional("Protobuf.AddColor");
	MarkNativeAsOptional("Protobuf.AddAngle");
	MarkNativeAsOptional("Protobuf.AddVector");
	MarkNativeAsOptional("Protobuf.AddVector2D");
	MarkNativeAsOptional("Protobuf.RemoveRepeatedFieldValue");
	MarkNativeAsOptional("Protobuf.ReadMessage");
	MarkNativeAsOptional("Protobuf.ReadRepeatedMessage");
	MarkNativeAsOptional("Protobuf.AddMessage");
	VerifyCoreVersion();
	return 0;
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
	return oper1 / float(oper2);
}

Float:DegToRad(Float:angle)
{
	return angle * 3.1415927 / 180;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

Handle:StartMessageOne(String:msgname[], client, flags)
{
	new players[1];
	players[0] = client;
	return StartMessage(msgname, players, 1, flags);
}

PrintToChatAll(String:format[])
{
	decl String:buffer[192];
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
		}
		i++;
	}
	return 0;
}

GetEntSendPropOffs(ent, String:prop[], bool:actual)
{
	decl String:cls[64];
	if (!GetEntityNetClass(ent, cls, 64))
	{
		return -1;
	}
	if (actual)
	{
		return FindSendPropInfo(cls, prop, 0, 0, 0);
	}
	return FindSendPropOffs(cls, prop);
}

SetEntityMoveType(entity, MoveType:mt)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_MoveType", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_MoveType");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:1, datamap, mt, 4, 0);
	return 0;
}

SetEntityRenderMode(entity, RenderMode:mode)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_nRenderMode", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_nRenderMode");
		}
		gotconfig = true;
	}
	SetEntProp(entity, PropType:0, prop, mode, 1, 0);
	return 0;
}

SetEntityRenderColor(entity, r, g, b, a)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_clrRender");
		}
		gotconfig = true;
	}
	new offset = GetEntSendPropOffs(entity, prop, false);
	if (0 >= offset)
	{
		ThrowError("SetEntityRenderColor not supported by this mod");
	}
	SetEntData(entity, offset, r, 1, true);
	SetEntData(entity, offset + 1, g, 1, true);
	SetEntData(entity, offset + 2, b, 1, true);
	SetEntData(entity, offset + 3, a, 1, true);
	return 0;
}

SetEntityGravity(entity, Float:amount)
{
	static bool:gotconfig;
	static String:datamap[32];
	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_flGravity", datamap, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(datamap, 32, "m_flGravity");
		}
		gotconfig = true;
	}
	SetEntPropFloat(entity, PropType:1, datamap, amount, 0);
	return 0;
}

SetEntityHealth(entity, amount)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_iHealth");
		}
		gotconfig = true;
	}
	decl String:cls[64];
	new PropFieldType:type;
	new offset;
	if (!GetEntityNetClass(entity, cls, 64))
	{
		ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
		return 0;
	}
	offset = FindSendPropInfo(cls, prop, type, 0, 0);
	if (0 >= offset)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return 0;
	}
	if (type == PropFieldType:2)
	{
		SetEntDataFloat(entity, offset, float(amount), false);
	}
	else
	{
		SetEntProp(entity, PropType:0, prop, amount, 4, 0);
	}
	return 0;
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[1];
	clients[0] = client;
	new var1;
	if (entity == -2)
	{
		var1 = client;
	}
	else
	{
		var1 = entity;
	}
	entity = var1;
	EmitSound(clients, 1, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}

EmitSoundToAll(String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
	new clients[MaxClients];
	new total;
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			total++;
			clients[total] = i;
		}
		i++;
	}
	if (!total)
	{
		return 0;
	}
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	return 0;
}
*/
public void OnPluginStart()
{
	char game[32];
	GetGameFolderName(game, 32);
	g_l4d1 = false;
	if (StrEqual(game, "left4-1", true))
	{
		g_l4d1 = true;
	}
	sm_lastboss_enable = CreateConVar("sm_lastboss_enable", "2", "Last Boss spawned in Finale.(0:OFF 1:ON(Finale Only) 2:ON(Always) 3:ON(Second Tank Only)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_announce = CreateConVar("sm_lastboss_enable_announce", "1", "Enable Announcement.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_steel = CreateConVar("sm_lastboss_enable_steel", "1", "Last Boss can use SteelSkin.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_stealth = CreateConVar("sm_lastboss_enable_stealth", "1", "Last Boss can use StealthSkin.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_gravity = CreateConVar("sm_lastboss_enable_gravity", "1", "Last Boss can use GravityClaw.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_burn = CreateConVar("sm_lastboss_enable_burn", "1", "Last Boss can use BurnClaw.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_quake = CreateConVar("sm_lastboss_enable_quake", "1", "Last Boss can use EarthQuake.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_jump = CreateConVar("sm_lastboss_enable_jump", "1", "Last Boss can use MadSpring.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_comet = CreateConVar("sm_lastboss_enable_comet", "1", "Last Boss can use BlastRock and CometStrike.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_dread = CreateConVar("sm_lastboss_enable_dread", "1", "Last Boss can use DreadClaw.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_gush = CreateConVar("sm_lastboss_enable_gush", "1", "Last Boss can use FlameGush.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_abyss = CreateConVar("sm_lastboss_enable_abyss", "1", "Last Boss can use CallOfAbyss.(0:OFF 1:ON(Forth form only) 2:ON(All forms))", 256, false, 0.0, false, 0.0);
	sm_lastboss_enable_warp = CreateConVar("sm_lastboss_enable_warp", "1", "Last Boss can use FatalMirror.(0:OFF 1:ON)", 256, false, 0.0, false, 0.0);
	sm_lastboss_health_max = CreateConVar("sm_lastboss_health_max", "40000", "LastBoss:MAX Health", 256, false, 0.0, false, 0.0);
	sm_lastboss_health_second = CreateConVar("sm_lastboss_health_second", "30000", "LastBoss:Health(second)", 256, false, 0.0, false, 0.0);
	sm_lastboss_health_third = CreateConVar("sm_lastboss_health_third", "20000", "LastBoss:Health(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_health_forth = CreateConVar("sm_lastboss_health_forth", "10000", "LastBoss:Health(forth)", 256, false, 0.0, false, 0.0);
	sm_lastboss_color_first = CreateConVar("sm_lastboss_color_first", "255 255 80", "RGB Value of First form(0-255)", 256, false, 0.0, false, 0.0);
	sm_lastboss_color_second = CreateConVar("sm_lastboss_color_second", "80 255 80", "RGB Value of Second form(0-255)", 256, false, 0.0, false, 0.0);
	sm_lastboss_color_third = CreateConVar("sm_lastboss_color_third", "80 80 255", "RGB Value of Third form(0-255)", 256, false, 0.0, false, 0.0);
	sm_lastboss_color_forth = CreateConVar("sm_lastboss_color_forth", "255 80 80", "RGB Value of Forth form(0-255)", 256, false, 0.0, false, 0.0);
	sm_lastboss_force_first = CreateConVar("sm_lastboss_force_first", "1000", "LastBoss:Force(first)", 256, false, 0.0, false, 0.0);
	sm_lastboss_force_second = CreateConVar("sm_lastboss_force_second", "1500", "LastBoss:Force(second)", 256, false, 0.0, false, 0.0);
	sm_lastboss_force_third = CreateConVar("sm_lastboss_force_third", "800", "LastBoss:Force(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_force_forth = CreateConVar("sm_lastboss_force_forth", "1800", "LastBoss:Force(forth)", 256, false, 0.0, false, 0.0);
	sm_lastboss_speed_first = CreateConVar("sm_lastboss_speed_first", "1.0", "LastBoss:Speed(first)", 256, false, 0.0, false, 0.0);
	sm_lastboss_speed_second = CreateConVar("sm_lastboss_speed_second", "1.0", "LastBoss:Speed(second)", 256, false, 0.0, false, 0.0);
	sm_lastboss_speed_third = CreateConVar("sm_lastboss_speed_third", "1.0", "LastBoss:Speed(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_speed_forth = CreateConVar("sm_lastboss_speed_forth", "1.1", "LastBoss:Speed(forth)", 256, false, 0.0, false, 0.0);
	sm_lastboss_weight_second = CreateConVar("sm_lastboss_weight_second", "8.0", "LastBoss:Weight(second)", 256, false, 0.0, false, 0.0);
	sm_lastboss_stealth_third = CreateConVar("sm_lastboss_stealth_third", "10.0", "Stealth skill:Interval(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_jumpinterval_forth = CreateConVar("sm_lastboss_jumpinterval_forth", "1.0", "Spring skill:Interval(forth)", 256, false, 0.0, false, 0.0);
	sm_lastboss_jumpheight_forth = CreateConVar("sm_lastboss_jumpheight_forth", "300.0", "Spring skill:Height(forth)", 256, false, 0.0, false, 0.0);
	sm_lastboss_gravityinterval = CreateConVar("sm_lastboss_gravityinterval", "6.0", "Gravity claw skill:Interval(second)", 256, false, 0.0, false, 0.0);
	sm_lastboss_quake_radius = CreateConVar("sm_lastboss_quake_radius", "600.0", "Earth Quake skill:Radius", 256, false, 0.0, false, 0.0);
	sm_lastboss_quake_force = CreateConVar("sm_lastboss_quake_force", "350.0", "Earth Quake skill:Force", 256, false, 0.0, false, 0.0);
	sm_lastboss_dreadinterval = CreateConVar("sm_lastboss_dreadinterval", "8.0", "Dread Claw skill:Interval(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_dreadrate = CreateConVar("sm_lastboss_dreadrate", "235", "Dread Claw skill:Blind rate(third)", 256, false, 0.0, false, 0.0);
	sm_lastboss_forth_c5m5_bridge = CreateConVar("sm_lastboss_forth_c5m5_bridge", "0", "Form is from the beginning to fourth in c5m5_bridge", 256, false, 0.0, false, 0.0);
	sm_lastboss_warp_interval = CreateConVar("sm_lastboss_warp_interval", "35.0", "Fatal Mirror skill:Interval(all form)", 256, false, 0.0, false, 0.0);
	CreateConVar("sm_lbex_lavadamage_type01", "150", "LastBoss:LavaDamage(third)", 256, false, 0.0, false, 0.0);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("finale_start", Event_Finale_Start);
	HookEvent("finale_escape_start", Event_Finale_Last);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_incapacitated", Event_Player_Hurt);
	HookEvent("round_end", Event_RoundEnd);
	if (!g_l4d1)
	{
		HookEvent("finale_bridge_lowering", Event_Finale_Start);
	}
	AutoExecConfig(true, "l4d_lastboss", "sourcemod");
	force_default = GetConVarInt(FindConVar("z_tank_throw_force"));
	if ((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
	{
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
	}
//	return void:0;
}

void InitPrecache()
{
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	PrecacheSound("animation/bombing_run_01.wav", true);
	PrecacheSound("music/pzattack/contusion.wav", true);
	PrecacheSound("weapons/grenade_launcher/grenadefire/grenade_launcher_1_1.wav", true);
	PrecacheSound("plats/churchbell_end.wav", true);
	PrecacheSound("ambient/random_amb_sounds/randbridgegroan_03.wav", true);
	PrecacheSound("player/charger/hit/charger_smash_02.wav", true);
	PrecacheSound("physics/metal/metal_solid_impact_hard5.wav", true);
	PrecacheSound("npc/infected/action/die/male/death_42.wav", true);
	PrecacheSound("items/suitchargeok1.wav", true);
	PrecacheSound("player/tank/voice/pain/Tank_Fire_06.wav", true);
	PrecacheSound("ambient/energy/zap9.wav", true);
	PrecacheParticle("electrical_arc_01_system");
	PrecacheParticle("gas_explosion_main");
	PrecacheParticle("apc_wheel_smoke1");
	PrecacheParticle("aircraft_destroy_fastFireTrail");
	PrecacheParticle("water_splash");
//	return 0;
}

void InitData()
{
	bossflag = 0;
	lastflag = 0;
	idBoss = -1;
	form_prev = -1;
	wavecount = 0;
	SetConVarInt(FindConVar("z_tank_throw_force"), force_default, true, true);
//	return 0;
}

public void OnMapStart()
{
	InitPrecache();
	InitData();
//	return void:0;
}

public void OnMapEnd()
{
	InitData();
//	return void:0;
}

public void OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(5.0, ChangeCVarDelay);
//	return void:0;
}

public Action ChangeCVarDelay(Handle timer)
{
	ServerCommand("sm_cvar z_tank_burning_lifetime 15000");
	ServerCommand("sm_cvar tank_burn_duration_expert 15000");
	ServerCommand("sm_cvar tank_burn_duration_hard 15000");
	ServerCommand("sm_cvar tank_burn_duration_normal 15000");
	ServerCommand("sm_cvar tank_burn_duration_easy 15000");
	ServerCommand("sm_cvar tank_stuck_time_suicide 500");
//	return Action:4;
}

public Action Event_Round_Start(Handle event, char[] name, bool dontBroadcast)
{
	InitData();
//	return Action:0;
}

public Action Event_Finale_Start(Handle event, char[] name, bool dontBroadcast)
{
	bossflag = 1;
	lastflag = 0;
	char CurrentMap[64];
	GetCurrentMap(CurrentMap, 64);
//	new var1;
	if (StrEqual(CurrentMap, "c1m4_atrium", true) || StrEqual(CurrentMap, "c5m5_bridge", true))
	{
		wavecount = 2;
	}
	else
	{
		wavecount = 1;
	}
//	return Action:0;
}

public Action Event_Finale_Last(Handle event, char[] name, bool dontBroadcast)
{
	lastflag = 1;
//	return Action:0;
}

public Action Event_Tank_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	
	if(StrEqual(CurrentMap, "c1m4_atrium") || StrEqual(CurrentMap, "c5m5_bridge"))
		bossflag = 1;
	
	
	if(idBoss != -1)
		return;
	
	
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			
			CreateTimer(0.3, SetTankHealth, client);
			if(TimerUpdate != INVALID_HANDLE)
			{
				CloseHandle(TimerUpdate);
				TimerUpdate = INVALID_HANDLE;
			}
			TimerUpdate = CreateTimer(1.0, TankUpdate, _, TIMER_REPEAT);
			
			for(int j = 1; j <= MaxClients; j++)
			{
				if(IsClientInGame(j) && !IsFakeClient(j))
				{
					EmitSoundToClient(j, "music/pzattack/contusion.wav");
				}
			}
			if(GetConVarInt(sm_lastboss_enable_announce))
			{
				PrintToChatAll("\x05¡¡¡PREPARATE, EL SUPERTANK ESTA CERCA!!! \x04TIPO\x01[JEFE FINAL]");
				PrintToChatAll("VIDA: 40000hp  VELOCIDAD: 1.0\n");
			}
		}
	}
}

public Action Event_Player_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client <= 0 || client > GetMaxClients())
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 5)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
	{
		wavecount++;
		return;
	}
	
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		idBoss = client;
		float Pos[3];
		GetClientAbsOrigin(idBoss, Pos);
		EmitSoundToAll("animation/bombing_run_01.wav", idBoss);
		ShowParticle(Pos, "gas_explosion_main", 5.0);
		LittleFlower(Pos, 0);
		LittleFlower(Pos, 1);
		idBoss = -1;
		form_prev = -1;
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		char model[128];
            	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, "models/props_vehicles/tire001c_car.mdl"))
		{
			int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
			if (owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	
	for (int target=1; target<=MaxClients; target++)
	{
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
		{
			SetEntityGravity(target, 1.0);
		}
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int target=1; target<=MaxClients; target++)
	{
		if (IsClientInGame(target) && GetClientTeam(target) == 2)
		{
			SetEntityGravity(target, 1.0);
		}
	}
}

public Action SetTankHealth(Handle timer, any client)
{
	
	idBoss = client;
	char CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss))
	{
		
		if(lastflag || (StrEqual(CurrentMap, "c5m5_bridge") && GetConVarInt(sm_lastboss_forth_c5m5_bridge)))
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_forth));
		else
			SetEntityHealth(idBoss, GetConVarInt(sm_lastboss_health_max));
	}
}

public Action Event_Player_Hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == -1)
		return;
	
	
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	
	
	if( (bossflag && GetConVarInt(sm_lastboss_enable) == 1) ||
					(GetConVarInt(sm_lastboss_enable) == 2) ||
		(bossflag && GetConVarInt(sm_lastboss_enable) == 3))
	{
		if(StrEqual(weapon, "tank_claw") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_quake))
			{
				
				SkillEarthQuake(target);
			}
			if(GetConVarInt(sm_lastboss_enable_gravity))
			{
				if(form_prev == 2)
				{
					
					SkillGravityClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_dread))
			{
				if(form_prev == 3)
				{
					
					SkillDreadClaw(target);
				}
			}
			if(GetConVarInt(sm_lastboss_enable_burn))
			{
				if(form_prev == 4)
				{
					
					SkillBurnClaw(target);
				}
			}
		}
		if(StrEqual(weapon, "tank_rock") && attacker == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_comet))
			{
				if(form_prev == 4)
				{
					
					SkillCometStrike(target, 0);
				}
				else
				{
					
					SkillCometStrike(target, 1);
				}
			}
		}
		if(StrEqual(weapon, "melee") && target == idBoss)
		{
			if(GetConVarInt(sm_lastboss_enable_steel))
			{
				if(form_prev == 2)
				{
					
					EmitSoundToClient(attacker, "physics/metal/metal_solid_impact_hard5.wav");
					SetEntityHealth(idBoss, (GetEventInt(event,"dmg_health") + GetEventInt(event,"health")));
				}
			}
			if(form_prev == 3)
			{
				int random = GetRandomInt(1,4);
				if (random == 1)
				{
					ForceWeaponDrop(attacker);
					EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav");
				}
			}
			if(GetConVarInt(sm_lastboss_enable_gush))
			{
				if(form_prev == 4)
				{
					
					SkillFlameGush(attacker);
				}
			}
		}
	}
}

public void SkillEarthQuake(int target)
{
	float Pos[3], tPos[3];
	
	if(IsPlayerIncapped(target))
	{
		for(int i = 1; i <= GetMaxClients(); i++)
		{
			if(i == idBoss)
				continue;
			if(!IsClientInGame(i) || GetClientTeam(i) != 2)
				continue;
			
			GetClientAbsOrigin(idBoss, Pos);
			GetClientAbsOrigin(i, tPos);
			if(GetVectorDistance(tPos, Pos) < GetConVarFloat(sm_lastboss_quake_radius))
			{
				EmitSoundToClient(i, "player/charger/hit/charger_smash_02.wav");
				ScreenShake(i, 60.0);
				Smash(idBoss, i, GetConVarFloat(sm_lastboss_quake_force), 1.0, 1.5);
			}
		}
	}
}

public void SkillDreadClaw(int target)
{
	visibility = GetConVarInt(sm_lastboss_dreadrate);
	CreateTimer(GetConVarFloat(sm_lastboss_dreadinterval), DreadTimer, target);
	EmitSoundToAll("ambient/random_amb_sounds/randbridgegroan_03.wav", target);
	ScreenFade(target, 0, 0, 0, visibility, 0, 0);
}

public void SkillGravityClaw(int target)
{
	SetEntityGravity(target, 0.3);
	CreateTimer(GetConVarFloat(sm_lastboss_gravityinterval), GravityTimer, target);
	EmitSoundToAll("plats/churchbell_end.wav", target);
	ScreenFade(target, 0, 0, 100, 80, 4000, 1);
	ScreenShake(target, 30.0);
}

public void SkillBurnClaw(int target)
{
	EmitSoundToAll("weapons/grenade_launcher/grenadefire/grenade_launcher_1_1.wav", target);
	ScreenFade(target, 200, 0, 0, 150, 80, 1);
	ScreenShake(target, 50.0);
}

public void SkillCometStrike(int target, int type)
{	
	float pos[3];
	GetClientAbsOrigin(target, pos);
	
	if(type == 0)
	{
		LittleFlower(pos, 1);
		LittleFlower(pos, 0);
	}
	else if(type == 1)
	{
		LittleFlower(pos, 1);
	}
}

public void SkillFlameGush(int target)
{
	float pos[3];
	
	SkillBurnClaw(target);
	LavaDamage(target);
	GetClientAbsOrigin(idBoss, pos);
	LittleFlower(pos, 0);
}

public void SkillCallOfAbyss()
{
	
	SetEntityMoveType(idBoss, MOVETYPE_NONE);
	SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
	
	for(int i = 1; i <= GetMaxClients(); i++)
	{
		if(!IsValidEntity(i) || !IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;
		EmitSoundToClient(i, "player/tank/voice/pain/tank_fire_08.wav");
		ScreenShake(i, 20.0);
	}
	
	if((form_prev == 4 && GetConVarInt(sm_lastboss_enable_abyss) == 1) ||
		GetConVarInt(sm_lastboss_enable_abyss) == 2)
	{
		TriggerPanicEvent();
	}
	
	
	CreateTimer(5.0, HowlTimer);
}

public Action TankUpdate(Handle timer)
{
	if(!IsValidEntity(idBoss) || !IsClientInGame(idBoss) || idBoss == -1)
		return;
	if(wavecount < 2 && GetConVarInt(sm_lastboss_enable) == 3)
		return;
	int health = GetClientHealth(idBoss);
	
	
	if(health > GetConVarInt(sm_lastboss_health_second))
	{
		if(form_prev != 1)
			SetPrameter(1);
	}
	
	else if(GetConVarInt(sm_lastboss_health_second) >= health &&
			health > GetConVarInt(sm_lastboss_health_third))
	{
		if(form_prev != 2)
			SetPrameter(2);
	}
	
	else if(GetConVarInt(sm_lastboss_health_third) >= health &&
			health > GetConVarInt(sm_lastboss_health_forth))
	{
		
		ExtinguishEntity(idBoss);
		if(form_prev != 3)
			SetPrameter(3);
	}
	
	else if(GetConVarInt(sm_lastboss_health_forth) >= health &&
			health > 0)
	{
		if(form_prev != 4)
			SetPrameter(4);
	}
}

public void SetPrameter(int form_next)
{
	int force;
	float speed;
	char color[32];
	
	form_prev = form_next;
	
	if(form_next != 1)
	{
		if(GetConVarInt(sm_lastboss_enable_abyss))
		{
			
			SkillCallOfAbyss();
		}
		
		
		ExtinguishEntity(idBoss);
		
		
		AttachParticle(idBoss, "electrical_arc_01_system");
		for(int j = 1; j <= GetMaxClients(); j++)
		{
			if(!IsClientInGame(j) || GetClientTeam(j) != 2)
				continue;
			EmitSoundToClient(j, "items/suitchargeok1.wav");
			ScreenFade(j, 200, 200, 255, 255, 100, 1);
		}
	}
	
	
	if(form_next == 1)
	{
		force = GetConVarInt(sm_lastboss_force_first);
		speed = GetConVarFloat(sm_lastboss_speed_first);
		GetConVarString(sm_lastboss_color_first, color, sizeof(color));
		
		
		if(GetConVarInt(sm_lastboss_enable_warp))
		{
			CreateTimer(3.0, Get2Position, _, TIMER_REPEAT);
			CreateTimer(GetConVarFloat(sm_lastboss_warp_interval), FatalMirror, _, TIMER_REPEAT);
		}
	}
	else if(form_next == 2)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll("\x05FASE 2 -> \x01[PODER DE HULK]");
		force = GetConVarInt(sm_lastboss_force_second);
		speed = GetConVarFloat(sm_lastboss_speed_second);
		GetConVarString(sm_lastboss_color_second, color, sizeof(color));
		
		
		SetEntityGravity(idBoss, GetConVarFloat(sm_lastboss_weight_second));
	}
	else if(form_next == 3)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll("\x05FASE 3 -> \x01[INVISIBLE]");
		force = GetConVarInt(sm_lastboss_force_third);
		speed = GetConVarFloat(sm_lastboss_speed_third);
		GetConVarString(sm_lastboss_color_third, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		
		CreateTimer(0.8, ParticleTimer, _, TIMER_REPEAT);
		
		
		if(GetConVarInt(sm_lastboss_enable_stealth))
			CreateTimer(GetConVarFloat(sm_lastboss_stealth_third), StealthTimer);
	}
	else if(form_next == 4)
	{
		if(GetConVarInt(sm_lastboss_enable_announce))
			PrintToChatAll("\x05FASE 4 -> \x01[ESCUDO DE FUEGO]");
		SetEntityRenderMode(idBoss, RENDER_TRANSCOLOR);
		SetEntityRenderColor(idBoss, _, _, _, 255);
		
		force = GetConVarInt(sm_lastboss_force_forth);
		speed = GetConVarFloat(sm_lastboss_speed_forth);
		GetConVarString(sm_lastboss_color_forth, color, sizeof(color));
		SetEntityGravity(idBoss, 1.0);
		
		
		IgniteEntity(idBoss, 9999.9);
		
		
		if(GetConVarInt(sm_lastboss_enable_jump))
			CreateTimer(GetConVarFloat(sm_lastboss_jumpinterval_forth), JumpingTimer, _, TIMER_REPEAT);
			
		float Origin[3], Angles[3];
		GetEntPropVector(idBoss, Prop_Send, "m_vecOrigin", Origin);
		GetEntPropVector(idBoss, Prop_Send, "m_angRotation", Angles);
		Angles[0] += 90.0;
		int ent[3];
		for (int count=1; count<=2; count++)
		{
			ent[count] = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(ent[count]))
			{
				char tName[64];
				Format(tName, sizeof(tName), "Tank%d", idBoss);
				DispatchKeyValue(idBoss, "targetname", tName);
				GetEntPropString(idBoss, Prop_Data, "m_iName", tName, sizeof(tName));

				DispatchKeyValue(ent[count], "model", "models/props_vehicles/tire001c_car.mdl");
				DispatchKeyValue(ent[count], "targetname", "TireEntity");
				DispatchKeyValue(ent[count], "parentname", tName);
				GetConVarString(sm_lastboss_color_forth, color, sizeof(color));
				DispatchKeyValue(ent[count], "rendercolor", color);
				DispatchKeyValueVector(ent[count], "origin", Origin);
				DispatchKeyValueVector(ent[count], "angles", Angles);
				DispatchSpawn(ent[count]);
				SetVariantString(tName);
				AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
				switch(count)
				{
					case 1:SetVariantString("rfoot");
					case 2:SetVariantString("lfoot");
				}
				AcceptEntityInput(ent[count], "SetParentAttachment");
				AcceptEntityInput(ent[count], "Enable");
				AcceptEntityInput(ent[count], "DisableCollision");
				SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", idBoss);
				TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
			}
		}
	}
	
	
	SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
	
	
	SetEntPropFloat(idBoss, Prop_Send, "m_flLaggedMovementValue", speed);
	
	
	SetEntityRenderMode(idBoss, RenderMode);
	DispatchKeyValue(idBoss, "rendercolor", color);
}

public Action ParticleTimer(Handle timer)
{
	if(form_prev == 3 && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
		AttachParticle(idBoss, "apc_wheel_smoke1");
	else if(form_prev == 4 && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
		AttachParticle(idBoss, "aircraft_destroy_fastFireTrail");
	else
		KillTimer(timer);
}

public Action GravityTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		SetEntityGravity(target, 1.0);
	}
}

public Action JumpingTimer(Handle timer)
{
	if(form_prev == 4 && IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
	{
		AddVelocity(idBoss, GetConVarFloat(sm_lastboss_jumpheight_forth));
	}
	
	else
	{
		KillTimer(timer);
	}
}

public Action StealthTimer(Handle timer)
{
	if(form_prev == 3 && idBoss)
	{
		alpharate = 255;
		Remove(idBoss);
	}
}

public Action DreadTimer(Handle timer, any target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)
	{
		visibility -= 8;
		if(visibility < 0)  visibility = 0;
		ScreenFade(target, 0, 0, 0, visibility, 0, 1);
		if(visibility <= 0)
		{
			visibility = 0;
			KillTimer(timer);
		}
	}
}

public Action HowlTimer(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
	{
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action WarpTimer(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
	{
		float pos[3];
		
		for(int i = 1; i <= GetMaxClients(); i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
			EmitSoundToClient(i, "ambient/energy/zap9.wav");
		}
		GetClientAbsOrigin(idBoss, pos);
		ShowParticle(pos, "water_splash", 2.0);
		TeleportEntity(idBoss, ftlPos, NULL_VECTOR, NULL_VECTOR);
		ShowParticle(ftlPos, "water_splash", 2.0);
		SetEntityMoveType(idBoss, MOVETYPE_WALK);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 2, 1);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action Get2Position(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
	{
		int count = 0;
		int idAlive[MAXPLAYERS+1];
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
				continue;
			idAlive[count] = i;
			count++;
		}
		if(count == 0) return;
		int clientNum = GetRandomInt(0, count-1);
		GetClientAbsOrigin(idAlive[clientNum], ftlPos);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action FatalMirror(Handle timer)
{
	if(IsValidEntity(idBoss) && IsClientInGame(idBoss) && idBoss != -1)
	{
	
		SetEntityMoveType(idBoss, MOVETYPE_NONE);
		SetEntProp(idBoss, Prop_Data, "m_takedamage", 0, 1);
		
		
		CreateTimer(1.5, WarpTimer);
	}
	else
	{
		KillTimer(timer);
	}
}

public Action Remove(int ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action fadeout(Handle Timer, any ent)
{
	if(!IsValidEntity(ent) || form_prev != 3)
	{
		KillTimer(Timer);
		return;
	}
	alpharate -= 2;
	if (alpharate < 0)  alpharate = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 80, 80, 255, alpharate);
	if(alpharate <= 0)
	{
		KillTimer(Timer);
	}
}

public void AddVelocity(int client, float zSpeed)
{
	if(g_iVelocity == -1) return;
	
	float vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

public void LittleFlower(float pos[3], int type)
{
	
	int entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			
			DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
		else
			
			DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public void Smash(int client, int target, float power, float powHor, float powVec)
{
	
	float HeadingVector[3], AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	float resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public void ScreenShake(int target, float intensity)
{
	Handle msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public void TriggerPanicEvent()
{
	int flager = GetAnyClient();
	if(flager == -1)  return;
	int flag = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
	FakeClientCommand(flager, "director_force_panic_event");
}

public void ShowParticle(float pos[3], char[] particlename, float time)
{
	
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}  
}

public void AttachParticle(int ent, char[] particleType)
{
	char tName[64];
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}
}

public void PrecacheParticle(char[] particlename)
{
	
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

public int IsValidClient(int client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
	{
		return false;
	}
	
	return true;
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

int GetAnyClient()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
			return i;
	}
	return -1;
}

stock void ForceWeaponDrop(int client)
{
	if (GetPlayerWeaponSlot(client, 1) > 0)
	{
		int weapon = GetPlayerWeaponSlot(client, 1);
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	}
}

stock void LavaDamage(int target)
{
	char dmg_lava[16];
	char dmg_type_lava[16];
	IntToString((1 << 17),dmg_lava,sizeof(dmg_type_lava));
	GetConVarString(FindConVar("sm_lbex_lavadamage_type01"), dmg_lava, sizeof(dmg_lava));
	int pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(target,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_lava);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_lava);
	DispatchKeyValue(pointHurt,"classname","point_hurt");
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt",-1,(target>0)?target:-1);
	DispatchKeyValue(target,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

