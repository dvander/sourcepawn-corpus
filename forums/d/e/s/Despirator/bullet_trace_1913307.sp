#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.4"

new Handle:mp_bullet_trace, bool:bEnable;

new Handle:hRGB, String:sRGB[18],
	Handle:hSpeed, Float:fSpeed,
	Handle:hDelay, Float:fDelay,
	Handle:hStartWidth, Float:fStartWidth,
Handle:hEndWidth, Float:fEndWidth;
	
new Float:g_fClientDelay[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Bullet Trace",
	author = "FrozDark (HLModders LLC)",
	description = "Bullet trace effect on fire",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	CreateConVar("sm_bullet_trace_version", PLUGIN_VERSION, "The version of bullet trace", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	mp_bullet_trace = CreateConVar("mp_bullet_trace", "1", "Whether to enable bullet trace effect on fire", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	bEnable = GetConVarBool(mp_bullet_trace);
	HookConVarChange(mp_bullet_trace, OnConVarChanges);
	
	hDelay = CreateConVar("sm_bullet_trace_delay", "0.1", "Delay between next bullet trace", FCVAR_PLUGIN, true, 0.1);
	fDelay = GetConVarFloat(hDelay);
	HookConVarChange(hDelay, OnConVarChanges);
	
	hRGB = CreateConVar("sm_bullet_trace_color", "200 200 0", "RGB color of bullet trace", FCVAR_PLUGIN);
	GetConVarString(hRGB, sRGB, sizeof(sRGB));
	HookConVarChange(hRGB, OnConVarChanges);
	
	hSpeed = CreateConVar("sm_bullet_trace_speed", "10000.0", "The speed of bullet trace", FCVAR_PLUGIN, true, 1000.0);
	fSpeed = GetConVarFloat(hSpeed);
	HookConVarChange(hSpeed, OnConVarChanges);
	
	hStartWidth = CreateConVar("sm_bullet_trace_startwidth", "2.0", "The start width of bullet trace", FCVAR_PLUGIN, true, 0.1);
	fStartWidth = GetConVarFloat(hStartWidth);
	HookConVarChange(hStartWidth, OnConVarChanges);
	
	hEndWidth = CreateConVar("sm_bullet_trace_endwidth", "1.0", "The end width of bullet trace", FCVAR_PLUGIN, true, 0.1);
	fEndWidth = GetConVarFloat(hEndWidth);
	HookConVarChange(hEndWidth, OnConVarChanges);
	
	AutoExecConfig(true, "bullet_trace");
	
	HookEvent("bullet_impact", OnBulletImpact);
}

public OnConVarChanges(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if (convar == mp_bullet_trace)
	{
		bEnable = bool:StringToInt(newVal);
	}
	else if (convar == hDelay)
	{
		fDelay = StringToFloat(newVal);
	}
	else if (convar == hRGB)
	{
		strcopy(sRGB, sizeof(sRGB), newVal);
	}
	else if (convar == hSpeed)
	{
		fSpeed = StringToFloat(newVal);
	}
	else if (convar == hStartWidth)
	{
		fStartWidth = StringToFloat(newVal);
	}
	else if (convar == hEndWidth)
	{
		fEndWidth = StringToFloat(newVal);
	}
}

public OnMapStart()
{
	for (new i = 1; i < sizeof(g_fClientDelay); i++)
	{
		g_fClientDelay[i] = 0.0;		// Reset delay
	}
}

public OnClientDisconnect_Post(client)
{
	g_fClientDelay[client] = 0.0;		// Reset delay
}

public OnBulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bEnable)
	{
		// Disabled
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new Float:_game_time = GetGameTime();
	
	if (g_fClientDelay[client] > _game_time) return;	// Is delayed? stop

	decl Float:bulletDestination[3];
	bulletDestination[0] = GetEventFloat(event, "x");
	bulletDestination[1] = GetEventFloat(event, "y");
	bulletDestination[2] = GetEventFloat(event, "z");

	decl Float:bulletOrigin[3];
	GetClientEyePosition(client, bulletOrigin);

	new Float:distance = GetVectorDistance(bulletOrigin, bulletDestination);
	new Float:percentage = 0.4 / (distance / 100);
	
	decl Float:newBulletOrigin[3];
	newBulletOrigin[0] = bulletOrigin[0] + ((bulletDestination[0] - bulletOrigin[0]) * percentage);
	newBulletOrigin[1] = bulletOrigin[1] + ((bulletDestination[1] - bulletOrigin[1]) * percentage) - 0.08;
	newBulletOrigin[2] = bulletOrigin[2] + ((bulletDestination[2] - bulletOrigin[2]) * percentage);
	
	CreateBulletTrace(newBulletOrigin, bulletDestination, fSpeed, fStartWidth, fEndWidth, sRGB);
	
	/***	Make us ignore shotguns for the delay	***/
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon != -1)
	{
		decl String:g_szWeapon[32];
		GetEdictClassname(weapon, g_szWeapon, sizeof(g_szWeapon));
		if (StrEqual(g_szWeapon, "weapon_xm1014", false) || StrEqual(g_szWeapon, "weapon_m3", false))
		{
			return;
		}
	}
	/***	-------------------------------		***/
	
	g_fClientDelay[client] = _game_time + fDelay;	// Setting delay. To avoid lagging beacuse of entity spam
}

stock CreateBulletTrace(const Float:origin[3], const Float:dest[3], const Float:speed = 6000.0, const Float:startwidth = 0.5, const Float:endwidth = 0.2, const String:color[] = "200 200 0")
{
	new entity = CreateEntityByName("env_spritetrail");
	if (entity == -1)
	{
		LogError("Couldn't create entity 'bullet_trace'");
		return -1;
	}
	DispatchKeyValue(entity, "classname", "bullet_trace");
	DispatchKeyValue(entity, "spritename", "materials/sprites/laser.vmt");
	DispatchKeyValue(entity, "renderamt", "255");
	DispatchKeyValue(entity, "rendercolor", color);
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValueFloat(entity, "startwidth", startwidth);
	DispatchKeyValueFloat(entity, "endwidth", endwidth);
	DispatchKeyValueFloat(entity, "lifetime", 240.0 / speed);
	if (!DispatchSpawn(entity))
	{
		AcceptEntityInput(entity, "Kill");
		LogError("Couldn't create entity 'bullet_trace'");
		return -1;
	}
	
	SetEntPropFloat(entity, Prop_Send, "m_flTextureRes", 0.05);
	
	decl Float:vecVeloc[3], Float:angRotation[3];
	MakeVectorFromPoints(origin, dest, vecVeloc);
	GetVectorAngles(vecVeloc, angRotation);
	NormalizeVector(vecVeloc, vecVeloc);
	ScaleVector(vecVeloc, speed);
	
	TeleportEntity(entity, origin, angRotation, vecVeloc);
	
	decl String:_tmp[128];
	FormatEx(_tmp, sizeof(_tmp), "OnUser1 !self:kill::%f:-1", GetVectorDistance(origin, dest) / speed);
	SetVariantString(_tmp);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	return entity;
}