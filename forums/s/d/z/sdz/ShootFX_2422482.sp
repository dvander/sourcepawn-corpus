#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//Why do I use enums? Idk I like organization. SM Knowitalls will probably scream at me for this lmao
enum Cvars
{
	Handle:Enabled,
	Handle:Fire,
	Handle:FireDMG,
	Handle:Lasers,
	Handle:Lightning,
	Handle:LaserColor,
	Handle:LightningColor,
	Handle:Version
};
new g_Cvars[Cvars];

enum Data
{
	LaserColor[4],
	LightningColor[4]
};
new g_Data[Data];

enum Status
{
	bool:Enabled,
	bool:Fire,
	bool:Lasers,
	bool:Lightning,
	String:FireDMG[16]
};
new g_Status[Status];

new laserSprite;


public Plugin:myinfo =
{
	name = "ShootFX",
	author = "Sidezz",
	description = "Trails and fire and all sorts of shit when you shoot guns",
	version = "1.1",
	url = "www.coldcommunity.com"
};

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_FireBulletsPost, onFireBullets);
}

public OnMapStart()
{
	laserSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(!StrEqual(game, "csgo", false))
	{
		SetFailState("ShootFX is currently only available to Counter-Strike: Global Offense.");
	}

	new bool:hook = HookEventEx("weapon_fire", weaponFire);
	if(!hook)
	{
		SetFailState("ShootFX reports invalid hook: weapon_fire (wtf?)");
	}

	g_Cvars[Version] = CreateConVar("sm_shootfx_version", "1.1", "Version of the plugin. Does this even do anything anymore?");
	g_Cvars[Enabled] = CreateConVar("sm_shootfx_enabled", "1", "Should guns shoot colorful stuff everywhere?", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[Fire] = CreateConVar("sm_shootfx_fire", "1", "Should guns shoot fire?", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[FireDMG] = CreateConVar("sm_shootfx_fire_dmg", "0.0", "How much damage should the fire do?", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[Lasers] = CreateConVar("sm_shootfx_lasers", "1", "Should guns shoot colorful lasers?", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[Lightning] = CreateConVar("sm_shootfx_lightning", "1", "Should guns shoot lightning beams?", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[LaserColor] = CreateConVar("sm_shootfx_lasers_color", "0 255 0 255", "What color should the lasers be? (RGBA)", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvars[LightningColor] = CreateConVar("sm_shootfx_lightning_color", "255 0 0 255", "What color should the lasers be? (RGBA)", FCVAR_NOTIFY | FCVAR_REPLICATED);

	HookConVarChange(g_Cvars[Enabled], onConfigChanged);
	HookConVarChange(g_Cvars[Fire], onConfigChanged);
	HookConVarChange(g_Cvars[FireDMG], onConfigChanged);
	HookConVarChange(g_Cvars[Lasers], onConfigChanged);
	HookConVarChange(g_Cvars[Lightning], onConfigChanged);
	HookConVarChange(g_Cvars[LaserColor], onConfigChanged);
	HookConVarChange(g_Cvars[LightningColor], onConfigChanged);

	AutoExecConfig(true, "shootfx_config");
	cvarConfig();
}

public weaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Status[Enabled])
	{
		decl String:szWeapon[64];
		if(StrContains(szWeapon, "knife", false) == -1)
		{
			GetEventString(event, "weapon", szWeapon, sizeof(szWeapon));
			onFireBullets(GetClientOfUserId(GetEventInt(event, "userid")), 0, szWeapon);
		}
		GetEventString(event, "weapon", szWeapon, sizeof(szWeapon));
		onFireBullets(GetClientOfUserId(GetEventInt(event, "userid")), 0, szWeapon);
	}
}

public onFireBullets(client, shots, const String:weaponname[])
{
	decl Float:cOrigin[3], Float:cEyes[3], Float:fEnd[3];
	GetClientAbsOrigin(client, cOrigin);
	GetClientEyeAngles(client, cEyes);

	cOrigin[2] += 58; //Sets about arms or upper tummy area

	if(!StrEqual(weaponname, "weapon_knife", false))
	{
		new Handle:trace = TR_TraceRayFilterEx(cOrigin, cEyes, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(fEnd, trace);
			if(g_Status[Lasers])
			{
				new aColor[4];
				arrayCopy(g_Data[LaserColor], aColor, sizeof(aColor));
				drawBeamToAll(cOrigin, fEnd, 0.2, 0.05, 0.1, aColor);
			}

			if(g_Status[Lightning])
			{
				new aColor[4];
				arrayCopy(g_Data[LightningColor], aColor, sizeof(aColor));
				drawBeamToAll(cOrigin, fEnd, 0.2, 0.05, 3.0, aColor);
			}

			if(g_Status[Fire])
				createFire(fEnd, client);

			CloseHandle(trace);
		}
	}
}

public createFire(Float:end[3], client)
{
	new fire = CreateEntityByName("env_fire");
	DispatchKeyValue(fire, "damagescale", g_Status[FireDMG]);
	DispatchKeyValue(fire, "firesize", "64");
	DispatchKeyValue(fire, "firetype", "0");
	DispatchKeyValue(fire, "fireattack", "2");
	DispatchKeyValue(fire, "health", "15");
	DispatchKeyValue(fire, "ignitionpoint", "1");
	DispatchSpawn(fire);
	TeleportEntity(fire, end, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(fire, "Enable");
	AcceptEntityInput(fire, "StartFire");
	SetEntPropEnt(fire, Prop_Send, "m_hOwnerEntity", client);
}

public drawBeamToAll(Float:origin[3], Float:end[3], Float:life, Float:width, Float:ampli, color[4])
{
	TE_SetupBeamPoints(origin, end, laserSprite, 0, 0, 66, life, width, 3.0, 0, ampli, color, 0);
	TE_SendToAll();
}

//Don't know who made this originally but I used it as a reference at some point in my life
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{	
	if(entity == data)
	{
		return false
	}
	

	return true
}

public onConfigChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	cvarConfig();
}

cvarConfig()
{
	g_Status[Enabled] = GetConVarBool(g_Cvars[Enabled]);
	g_Status[Fire] = GetConVarBool(g_Cvars[Fire]);
	g_Status[Lasers] = GetConVarBool(g_Cvars[Lasers]);
	GetConVarString(g_Cvars[FireDMG], g_Status[FireDMG], 16);
	g_Status[Lightning] = GetConVarBool(g_Cvars[Lightning]);

	decl String:laserColor[32], String:lightningColor[32];
	GetConVarString(g_Cvars[LaserColor], laserColor, sizeof(laserColor));
	GetConVarString(g_Cvars[LightningColor], lightningColor, sizeof(lightningColor));

	g_Data[LaserColor] = StringToColor(laserColor, true);
	g_Data[LightningColor] = StringToColor(lightningColor, true);
}

stock arrayCopy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) 
	{
		newArray[i] = array[i];
	}
}

stock StringToColor(const String:sColor[], bool:alpha = true)
{
	new aColor[4];
	decl String:RGBA[4][8];
	if(alpha)
	{
		ExplodeString(sColor, " ", RGBA, 4, 8);
		aColor[3] = StringToInt(RGBA[3]);
	}
	else
	{
		ExplodeString(sColor, " ", RGBA, 3, 8);
		aColor[3] = 255;
	}

	aColor[0] = StringToInt(RGBA[0]); //Red
	aColor[1] = StringToInt(RGBA[1]); //Green
	aColor[2] = StringToInt(RGBA[2]); //Blue
	return aColor;
}