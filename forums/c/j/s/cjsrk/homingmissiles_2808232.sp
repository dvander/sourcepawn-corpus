#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// #include <WeaponAttachmentAPI>

#pragma semicolon 1

#define PLUGIN_VERSION "3.0"

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004
#define EF_NODRAW 32
#define EXPLODE_SOUND	"ambient/fire/mtov_flame2.wav"

new Handle:hDamage;
new Handle:hRadius;
new Handle:hSpeed;
new Handle:hType;
new Handle:hEnable;
new Handle:hReplace;
new Handle:hTeam;
new Handle:hArc;
new Handle:hAmmo;
new Handle:hPrice;
new Handle:hBuyZone;
new Handle:hBuyTime;
new Handle:hRPGName;

new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
new Float:MaxNadeHull[3] = {2.5, 2.5, 2.5};
new Float:MaxWorldLength;
new Float:SpinVel[3] = {0.0, 0.0, 200.0};
new Float:SmokeOrigin[3] = {-30.0,0.0,0.0};
new Float:SmokeAngle[3] = {0.0,-180.0,0.0};

new NadeDamage;
new NadeRadius;
new Float:NadeSpeed;
new NadeType;
new Float:NadeArc;
new String:ReplaceNade[50];
new NadeAllowTeam;
new IsEnabled;
new ArcEnabled;
new NadeAmmo;
new NadePrice;
new BuyZone;
new Float:BuyTime;
new Float:BuyTimer;
new String:RPGName[32];

new MissilesLeft[MAXPLAYERS+1];
int g_iSmoke = -1;
int g_sprite = 0;

public Plugin:myinfo =
{
	name = "Homing Missiles",
	author = "Blodia, cjsrk",
	description = "Turns projectile weapons into homing missiles",
	version = "3.0",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("missile_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hDamage = CreateConVar("missile_damage", "500", "Set the maximum damage that rockets (missiles) can do", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
	hRadius = CreateConVar("missile_radius", "600", "Set the blast radius of the rocket (missile)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
	hSpeed = CreateConVar("missile_speed", "1250.0", "Set the speed of the rocket (missile)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 300.0 ,true, 3000.0);
	hType = CreateConVar("missile_type", "0", "Type of rocket (missile) used, 0 = unguided missile, 1 = homing missile, 2 = crosshair guided", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hEnable = CreateConVar("missile_enable", "1", "1 = Enable plugin, 0 = Disable plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hReplace = CreateConVar("missile_replace", "0", "Weapons replaced by rockets (missiles), 0 = grenades, 1 = flash grenades, 2 = smoke grenades", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hTeam = CreateConVar("missile_team", "0", "Which team can use rockets (missiles), 0 = Any, 1 = Terrorists only, 2 = CT only", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hArc = CreateConVar("missile_arc", "1", "Opens (1) or closes (0) the missile steering arc. When disabled, missiles do not turn in an arc in the air, they turn immediately.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hAmmo = CreateConVar("missile_ammo", "0", "When missile_price is 0, the number of rockets players can acquire per game, and when missile_price is higher than 0, that is the maximum number of rockets they can buy. 0 is infinite. (Default is 0)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0);
	hPrice = CreateConVar("missile_price", "0", "Set the price to buy rockets (missiles). 0 Disable purchase to use picked up projectiles as ammunition. Values greater than 0 only allow you to buy ammunition and not pick it up, which is added to the current stockpile, so once your rocket (missile) ammunition runs out, you can keep the original projectile.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 16000.0);
	hBuyZone = CreateConVar("missile_buyzone", "0", "Enable (1) or disable (0) buyzone restricted purchases. (Default is 0)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hBuyTime = CreateConVar("missile_buytime", "90.0", "The number of seconds the player can buy rockets (missiles) after the start of the round, 0.0 is unlimited time. (Default 0.0)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0); 
	hRPGName = CreateConVar("missile_weaponname", "weapon_rpg", "Set the weapon that applies the rocket (missile) effect (default value is weapon_hegrenade), generally do not change it, just keep the default value. Only valid if missile_replace's value is 0, and the RPG is added through the add new gun plugin and the parent weapon is a grenade, can be modified).", FCVAR_PLUGIN);
	
	NadeDamage = GetConVarInt(hDamage);
	NadeRadius = GetConVarInt(hRadius);
	NadeSpeed = GetConVarFloat(hSpeed);
	NadeType = GetConVarInt(hType);
	NadeAllowTeam = GetConVarInt(hTeam) + 1;
	NadeArc = NadeSpeed / 1000.0;
	ArcEnabled = GetConVarInt(hArc);
	NadeAmmo = GetConVarInt(hAmmo);
	IsEnabled = GetConVarInt(hEnable);
	NadePrice = GetConVarInt(hPrice);
	BuyZone = GetConVarInt(hBuyZone);
	BuyTime = GetConVarFloat(hBuyTime);
	GetConVarString(hRPGName, RPGName, sizeof(RPGName));
	
	switch (GetConVarInt(hReplace))
	{
		case 0:
		{
			ReplaceNade = "hegrenade_projectile";
		}
		case 1:
		{
			ReplaceNade = "flashbang_projectile";
		}
		case 2:
		{
			ReplaceNade = "smokegrenade_projectile";
		}
	}
	
	HookConVarChange(hDamage, ConVarChange);
	HookConVarChange(hRadius, ConVarChange);
	HookConVarChange(hSpeed, ConVarChange);
	HookConVarChange(hType, ConVarChange);
	HookConVarChange(hEnable, ConVarChange);
	HookConVarChange(hReplace, ConVarChange);
	HookConVarChange(hTeam, ConVarChange);
	HookConVarChange(hArc, ConVarChange);
	HookConVarChange(hAmmo, ConVarChange);
	HookConVarChange(hPrice, ConVarChange);
	HookConVarChange(hBuyZone, ConVarChange);
	HookConVarChange(hBuyTime, ConVarChange);
	HookConVarChange(hRPGName, ConVarChange);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end",Event_RoundFreezeEnd);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public OnMapStart()
{
	new Float:WorldMinHull[3], Float:WorldMaxHull[3];
	GetEntPropVector(0, Prop_Send, "m_WorldMins", WorldMinHull);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", WorldMaxHull);
	MaxWorldLength = GetVectorDistance(WorldMinHull, WorldMaxHull);
	
	AddFileToDownloadsTable("sound/weapons/rpg/rocket1.wav");
	
	// AddFileToDownloadsTable("materials/models/weapons/w_missile/missile side.vmt");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/mi_1p_rpg_rocket.vmt");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/mi_1p_rpg.vmt");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_d.vtf");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_m.vtf");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_rocket_d.vtf");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_rocket_m.vtf");
	AddFileToDownloadsTable("materials/models/weapons/RPG7/t_1p_rpg_rocket_n.vtf");
	
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.mdl");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.phy");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.sw.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.vvd");
	
	PrecacheModel("models/weapons/w_missile_closed.mdl");
	
	PrecacheSound("weapons/rpg/rocket1.wav");
	PrecacheSound("weapons/hegrenade/explode5.wav");
	
	g_iSmoke = PrecacheDecal("materials/sprites/smoke.vmt"); 
	g_sprite = PrecacheGeneric("sprites/zerogxplode.spr", true);
	
	PrecacheSound(EXPLODE_SOUND, true);
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hDamage)
	{
		NadeDamage = StringToInt(newVal);
	}
	
	else if (cvar == hRadius)
	{
		NadeRadius = StringToInt(newVal);
	}
	
	else if (cvar == hSpeed)
	{
		NadeSpeed = StringToFloat(newVal);
		NadeArc = NadeSpeed / 1000.0;
	}
	
	else if (cvar == hType)
	{
		NadeType = StringToInt(newVal);
	}
	
	else if (cvar == hEnable)
	{
		IsEnabled = StringToInt(newVal);
	}
	
	else if (cvar == hReplace)
	{
		switch (StringToInt(newVal))
		{
			case 0:
			{
				ReplaceNade = "hegrenade_projectile";
			}
			case 1:
			{
				ReplaceNade = "flashbang_projectile";
			}
			case 2:
			{
				ReplaceNade = "smokegrenade_projectile";
			}
		}
	}
	
	else if (cvar == hTeam)
	{
		NadeAllowTeam = GetConVarInt(hTeam) + 1;
	}
	
	else if (cvar == hArc)
	{
		ArcEnabled = StringToInt(newVal);
	}
	
	else if (cvar == hAmmo)
	{
		NadeAmmo = StringToInt(newVal);
	}
	
	else if (cvar == hPrice)
	{
		NadePrice = StringToInt(newVal);
	}
	
	else if (cvar == hBuyZone)
	{
		BuyZone = StringToInt(newVal);
	}
	
	else if (cvar == hBuyTime)
	{
		BuyTime = StringToFloat(newVal);
	}
	else if(cvar == hRPGName)
	{
		if(strlen(newVal) > 0 && !StrEqual("", newVal))
		{
			strcopy(RPGName, strlen(newVal) + 1, newVal);	
		    TrimString(RPGName);	
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (client == 0)
	{
		return;
	}
	
	new ClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if ((NadeAllowTeam != 1) && (NadeAllowTeam != ClientTeam))
	{
		return;
	}
	
	if (IsEnabled)
	{
		if (!NadePrice)
		{
			MissilesLeft[client] = NadeAmmo;
			
			if (NadeAmmo)
			{
				PrintToChat(client, "\x04[Homing Missiles]\x05 Missiles left = %i", MissilesLeft[client]);
			}
		}
		else
		{
			MissilesLeft[client] = 0;
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (NadePrice && IsEnabled)
	{
		PrintToChatAll("\x04[Homing Missiles]\x05 Type !buymissile in chat to buy a missile for $%i.", NadePrice);
	}
	
	BuyTimer = GetGameTime() + BuyTime;
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	BuyTimer = GetGameTime() + BuyTime;
}

public Action:Command_Say(client, const String:command[], argc)
{
	new String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	if (!IsEnabled)
	{
		return Plugin_Continue;
	}
 
	if (StrEqual(text, "!buymissile", false))
	{
		if (!NadePrice)
		{
			return Plugin_Handled;
		}
			
		if ((!GetEntProp(client, Prop_Send, "m_bInBuyZone")) && (BuyZone))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 You aren't in a buyzone");
			return Plugin_Handled;
		}
		
		if ((GetGameTime() > BuyTimer) && (BuyTime != 0.0))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 Buy time is up");
			return Plugin_Handled;
		}
		
		new ClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
		if ((NadeAllowTeam != 1) && (NadeAllowTeam != ClientTeam))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 Your team can't buy missiles.");
			
			return Plugin_Handled;
		}
		
		if ((MissilesLeft[client] == NadeAmmo) && NadeAmmo)
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 You can't buy anymore, you have maximum ammo");
		}
		else
		{
			new Cash = GetEntProp(client, Prop_Send, "m_iAccount");
			
			if (Cash < NadePrice)
			{
				PrintToChat(client, "\x04[Homing Missiles]\x05 You don't have $%i to buy a missile", NadePrice);
			}
			else
			{
				Cash -= NadePrice;
				SetEntProp(client, Prop_Send, "m_iAccount", Cash);
				MissilesLeft[client]++;
				PrintToChat(client, "\x04[Homing Missiles]\x05 You bought a missile");
				
				new AmmoReserve;
				if (StrEqual("hegrenade_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 11);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, RPGName);
						// GivePlayerItem(client, "weapon_hegrenade");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 11);
					}
				}
				else if (StrEqual("flashbang_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, "weapon_flashbang");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 12);
					}
				}
				else if (StrEqual("smokegrenade_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 13);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, "weapon_smokegrenade");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 13);
					}
				}
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}


public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, ReplaceNade, false))
	{
		if (!IsEnabled)
		{
			return;
		}
		
		// if(StrEqual("hegrenade_projectile", ReplaceNade, false) && !StrEqual(RPGName, "weapon_hegrenade"))
		if(StrEqual("hegrenade_projectile", ReplaceNade, false))
		{			
			CreateTimer(0.02, Hegrenade_Throw3, entity);	
			SetEntityRenderMode(entity, RENDER_NONE);
			SetEntityMoveType(entity, MOVETYPE_FLY);
		}
		else
		{			
			HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
	
			new String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
			SetVariantString(OutputString);
			AcceptEntityInput(entity, "AddOutput");
			
			AcceptEntityInput(entity, "FireUser1");
		}			
	}
}


public Action:Hegrenade_Throw3(Handle timer, int entity)
{
	if(HasEntProp(entity, Prop_Send, "m_hThrower") == false)
	{
		return;
	}
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");	
	if(owner < 0 || owner > MaxClients)
	{
		return;
	}
	
	new currentWeapon = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
		    return;	
	decl String:sWeapon[32];
	GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, RPGName, false))
	{
		// int flEntEffects = GetEntProp(entity, Prop_Send, "m_fEffects");
		// flEntEffects |= EF_NODRAW; // 32
		// SetEntProp(entity, Prop_Send, "m_fEffects", flEntEffects);
		
		HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
		
		new String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(entity, "AddOutput");
		
		AcceptEntityInput(entity, "FireUser1");
		
		float EntityOrigin[3], ClientOrigin[3], ClientAngles[3];
		// WA_GetAttachmentPos(owner, "RPG_Projectile", EntityOrigin);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityOrigin); 
		GetClientEyePosition(owner, ClientOrigin);
		GetClientEyeAngles(owner, ClientAngles);
		EntityOrigin[0] = (EntityOrigin[0] + ClientOrigin[0])/2;
		EntityOrigin[1] = (EntityOrigin[1] + ClientOrigin[1])/2;
		EntityOrigin[2] = ClientOrigin[2];
		
		if(g_iSmoke != -1)   
		{
			TE_SetupSmoke(EntityOrigin, g_iSmoke, 5.0, 0);
			TE_SendToAll();
		}
		CreateTimer(0.1, Hegrenade_Throw4, entity);	
	}	
	else
	{
		SetEntityRenderMode(entity, RENDER_NORMAL);
		SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
	}
}


public Action:Hegrenade_Throw4(Handle timer, int entity)
{
	// int flEntEffects = GetEntProp(entity, Prop_Send, "m_fEffects");
	// flEntEffects &= ~EF_NODRAW; // 32
	// SetEntProp(entity, Prop_Send, "m_fEffects", flEntEffects);
	SetEntityRenderMode(entity, RENDER_NORMAL);
}


public InitMissile(const String:output[], caller, activator, Float:delay)
{
	new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
	
	// assume other plugins don't set this on any projectiles they create, this avoids conflicts.
	if (NadeOwner == -1)
	{
		return;
	}
	
	//ignore the projectile if this team can't use missiles.
	new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	if ((NadeAllowTeam != 1) && (NadeAllowTeam != NadeTeam))
	{
		return;
	}
	
	if (!MissilesLeft[NadeOwner] && NadeAmmo)
	{
		return;
	}
	else
	{
		MissilesLeft[NadeOwner]--;
		PrintToChat(NadeOwner, "\x04[Homing Missiles]\x05 Missiles left = %i", MissilesLeft[NadeOwner]);
	}
	
	// stop the projectile thinking so it doesn't detonate.
	SetEntProp(caller, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityMoveType(caller, MOVETYPE_FLY);
	SetEntityModel(caller, "models/weapons/w_missile_closed.mdl");
	
	// make it spin correctly.
	SetEntPropVector(caller, Prop_Data, "m_vecAngVelocity", SpinVel);
	// stop it bouncing when it hits something
	SetEntPropFloat(caller, Prop_Send, "m_flElasticity", 0.0);
	SetEntPropVector(caller, Prop_Send, "m_vecMins", MinNadeHull);
	SetEntPropVector(caller, Prop_Send, "m_vecMaxs", MaxNadeHull);
	
	// switch (NadeTeam)
	// {
		// case 2:
		// {
			// SetEntityRenderColor(caller, 255, 0, 0, 255);
		// }
		// case 3:
		// {
			// SetEntityRenderColor(caller, 0, 0, 255, 255);
		// }
	// }
	
	new SmokeIndex = CreateEntityByName("env_rockettrail");
	if (SmokeIndex != -1)
	{
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 0.5);
		new Float:SmokeRed[3] = {0.5, 0.25, 0.25};
		new Float:SmokeBlue[3] = {0.25, 0.25, 0.5};
		// switch (NadeTeam)
		// {
			// case 2:
			// {
				// SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeRed);
			// }
			// case 3:
			// {
				// SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeBlue);
			// }
		// }
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 5.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 30.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 10.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_flFlareScale", 1.0);
		
		DispatchSpawn(SmokeIndex);
		ActivateEntity(SmokeIndex);
		
		new String:NadeName[20];
		Format(NadeName, sizeof(NadeName), "Nade_%i", caller);
		DispatchKeyValue(caller, "targetname", NadeName);
		SetVariantString(NadeName);
		AcceptEntityInput(SmokeIndex, "SetParent");
		TeleportEntity(SmokeIndex, SmokeOrigin, SmokeAngle, NULL_VECTOR);
	}
	
	// make the missile go towards the coordinates the player is looking at.
	new Float:NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	new Float:OwnerAng[3];
	GetClientEyeAngles(NadeOwner, OwnerAng);
	new Float:OwnerPos[3];
	GetClientEyePosition(NadeOwner, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
	new Float:InitialPos[3];
	TR_GetEndPosition(InitialPos);
	new Float:InitialVec[3];
	MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, NadeSpeed);
	new Float:InitialAng[3];
	GetVectorAngles(InitialVec, InitialAng);
	TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", caller, 1, 90);
	
	HookSingleEntityOutput(caller, "OnUser2", MissileThink);
	
	new String:OutputString[50] = "OnUser1 !self:FireUser2::0.1:-1";
	SetVariantString(OutputString);
	AcceptEntityInput(caller, "AddOutput");
	
	AcceptEntityInput(caller, "FireUser1");
	
	SDKHook(caller, SDKHook_StartTouch, OnStartTouch);
}

public MissileThink(const String:output[], caller, activator, Float:delay)
{
	// detonate any missiles that stopped for any reason but didn't detonate.
	decl Float:CheckVec[3];
	GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
	if ((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0))
	{
		StopSound(caller, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(caller);
		return;
	}
	
	decl Float:NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	
	new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	
	if (NadeType > 0)
	{
		new Float:ClosestDistance = MaxWorldLength;
		decl Float:TargetVec[3];
		
		// find closest enemy in line of sight.
		if (NadeType == 1)
		{
			new ClosestEnemy;
			new Float:EnemyDistance;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) != NadeTeam))
				{
					decl Float:EnemyPos[3];
					GetClientEyePosition(i, EnemyPos);
					TR_TraceHullFilter(NadePos, EnemyPos, MinNadeHull, MaxNadeHull, MASK_SOLID, DontHitOwnerOrNade, caller);
					if (TR_GetEntityIndex() == i)
					{
						EnemyDistance = GetVectorDistance(NadePos, EnemyPos);
						if (EnemyDistance < ClosestDistance)
						{
							ClosestEnemy = i;
							ClosestDistance = EnemyDistance;
						}
					}
				}
			}
			// no target found, continue along current trajectory.
			if (!ClosestEnemy)
			{
				AcceptEntityInput(caller, "FireUser1");
				return;
			}
			else
			{
				decl Float:EnemyPos[3];
				GetClientEyePosition(ClosestEnemy, EnemyPos);
				MakeVectorFromPoints(NadePos, EnemyPos, TargetVec);
			}
		}
		
		// make the missile go towards the coordinates the player is looking at.
		else if (NadeType == 2)
		{
			new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
			decl Float:OwnerAng[3];
			GetClientEyeAngles(NadeOwner, OwnerAng);
			decl Float:OwnerPos[3];
			GetClientEyePosition(NadeOwner, OwnerPos);
			TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
			decl Float:TargetPos[3];
			TR_GetEndPosition(TargetPos);
			ClosestDistance = GetVectorDistance(NadePos, TargetPos);
			MakeVectorFromPoints(NadePos, TargetPos, TargetVec);
		}
		
		decl Float:CurrentVec[3];
		GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CurrentVec);
		decl Float:FinalVec[3];
		if (ArcEnabled && (ClosestDistance > 100.0))
		{
			NormalizeVector(TargetVec, TargetVec);
			NormalizeVector(CurrentVec, CurrentVec);
			ScaleVector(TargetVec, NadeArc);
			AddVectors(TargetVec, CurrentVec, FinalVec);
		}
		// ignore turning arc if the missile is close to the enemy to avoid it circling them.
		else
		{
			FinalVec = TargetVec;
		}
		
		NormalizeVector(FinalVec, FinalVec);
		ScaleVector(FinalVec, NadeSpeed);
		decl Float:FinalAng[3];
		GetVectorAngles(FinalVec, FinalAng);
		TeleportEntity(caller, NULL_VECTOR, FinalAng, FinalVec);
	}
	
	AcceptEntityInput(caller, "FireUser1");
}

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
	new NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hThrower");
	return ((entity != data) && (entity != NadeOwner));
}

public Action:OnStartTouch(entity, other) 
{
	if (other == 0)
	{
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	}
	// detonate if the missile hits something solid.
	else if((GetEntProp(other, Prop_Data, "m_nSolidType") != SOLID_NONE) && (!(GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID)))
	{
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	}
	return Plugin_Continue;
}

CreateExplosion(entity)
{
	UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
	
	int flEntEffects = GetEntProp(entity, Prop_Send, "m_fEffects");
	flEntEffects |= EF_NODRAW; // 32
	SetEntProp(entity, Prop_Send, "m_fEffects", flEntEffects);
	
	new Float:MissilePos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", MissilePos);
	new MissileOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	new MissileOwnerTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex,"classname",ReplaceNade);
		
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", NadeDamage);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", NadeRadius);
		
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", MissileOwner);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", MissileOwnerTeam);
		
		EmitSoundToAll("weapons/hegrenade/explode5.wav", ExplosionIndex, 1, 90);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		DataPack pack3 = new DataPack();
		pack3.WriteCell(MissileOwner);
		pack3.WriteFloat(MissilePos[0]);
		pack3.WriteFloat(MissilePos[1]);
		pack3.WriteFloat(MissilePos[2]);
		CreateTimer(0.75, Timer_NewExplosion, pack3);
		
		// DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
	
	AcceptEntityInput(entity, "Kill");
}


public Action:Timer_NewExplosion(Handle timer, DataPack pack3)
{
	new Float:NewMissilePos[3];
	pack3.Reset();	
	int Owner = pack3.ReadCell();
	NewMissilePos[0] = pack3.ReadFloat();
	NewMissilePos[1] = pack3.ReadFloat();
	NewMissilePos[2] = pack3.ReadFloat();
	CloseHandle(pack3);
	
	TE_SetupExplosion(NewMissilePos, g_sprite, 1.0, 20, TE_EXPLFLAG_NONE, NadeRadius, NadeDamage);
	TE_SendToAll();
	
	new fire = CreateEntityByName("env_fire");	
	SetEntPropEnt(fire, Prop_Send, "m_hOwnerEntity", Owner);
	DispatchKeyValue(fire, "firesize", "50");
	//DispatchKeyValue(fire, "fireattack", "5");
	DispatchKeyValue(fire, "health", "6");
	DispatchKeyValue(fire, "firetype", "Normal");

	DispatchKeyValueFloat(fire, "damagescale", 20.0);
	DispatchKeyValue(fire, "spawnflags", "256");  //Used to controll flags
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(fire, "DispatchEffect"); 
	DispatchSpawn(fire);
	TeleportEntity(fire, NewMissilePos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(fire, "StartFire");
	EmitAmbientSound( EXPLODE_SOUND, NewMissilePos, fire, SNDLEVEL_NORMAL, _ , 1.0 );
}