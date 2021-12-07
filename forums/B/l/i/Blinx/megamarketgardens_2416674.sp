#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

new Handle:cvarDamageMult = INVALID_HANDLE;
new Handle:cvarCritAnnounce = INVALID_HANDLE;
new Handle:cvarSoundAnnounce = INVALID_HANDLE;
new Handle:cvarSoundPath = INVALID_HANDLE;
new Handle:cvarIndexList = INVALID_HANDLE;
new Handle:cvarAllWeaponsMG = INVALID_HANDLE;
new Handle:cvarAllMGWillCrit = INVALID_HANDLE;
new Handle:cvarExplosiveMMG = INVALID_HANDLE;
new Handle:cvarExplosionMagnitude = INVALID_HANDLE;
new Handle:cvarExplosionForce = INVALID_HANDLE;
new Handle:cvarExplosionRadius = INVALID_HANDLE;
new Handle:cvarEarRapeMode = INVALID_HANDLE;

new bool:InExplosiveJump[MAXPLAYERS+1]=false;
new Float:DamageMult = 2.0;
new bool:CritAnnounce = true;
new bool:SoundAnnounce = true;
new bool:AllWeaponsMG = false;
new bool:AllMGWillCrit = false;
new bool:ExplosiveMMG = true;
new Float:ExplosionForce = 100.0;
new ExplosionMagnitude = 150;
new ExplosionRadius = 200;
new bool:EarRapeMode = false;
new String:SoundPath[PLATFORM_MAX_PATH] = "misc/ks_tier_04_kill_01.wav";
new IndexList[16];

public Plugin:myinfo = {
   name = "Mega Market Gardens",
   author = "Blinx",
   description = "Play a sound, announce with crit text and sound, and create an explosion on successful Market Gardens.",
   version = "1.1.0"
}

public OnPluginStart()
{
	IndexList[0] = 416;
	
	for (new i = 1; i<15; i++)
	{
		IndexList[i] = -1;
	}
	
	cvarDamageMult = CreateConVar("mmg_damagemult", "3.5", "How much to multiply Market Garden damage by", FCVAR_NONE);
	cvarCritAnnounce = CreateConVar("mmg_critannounce", "1", "Places the crit text above the victim of a Market Garden's head to everyone", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSoundAnnounce = CreateConVar("mmg_soundannounce", "1", "Play a sound with a successful Market Garden?", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarSoundPath = CreateConVar("mmg_soundpath", "misc/ks_tier_04_kill_01.wav", "Full file path to what sound to play on a succesful Market Garden", FCVAR_NONE);
	cvarIndexList = CreateConVar("mmg_indexlist", "416 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1", "List of weapon indexes to allow for Market Garden modification, indexes are seperated by spaces, supports up to 16 indexes", FCVAR_NONE);
	cvarAllWeaponsMG = CreateConVar("mmg_allweaponsmg", "0", "Modifies all melee weapons to behave like a Market Gardener in terms of this plugin's capabilities", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarAllMGWillCrit = CreateConVar("mmg_allmgwillcrit", "0", "Forces all melee weapons considered a Market Gardener (See: mmg_allweaponsmg and mmg_indexlist) to crit if the player is in an explosive jump", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarExplosiveMMG = CreateConVar("mmg_explosivemmg", "1", "Creates an explosion at the victims location on a successful Market Garden", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarExplosionForce = CreateConVar("mmg_explosionforce", "100.0", "The force of an explosion if mmg_explosivemmg is set to 1", FCVAR_NONE, true, 0.0);
	cvarExplosionMagnitude = CreateConVar("mmg_explosiondamage", "200", "The damage of an explosion if mmg_explosivemmg is set to 1", FCVAR_NONE, true, 0.0);
	cvarExplosionRadius = CreateConVar("mmg_explosionradius", "200", "The radius of an explosion if mmg_explosivemmg is set to 1", FCVAR_NONE, true, 0.0);
	cvarEarRapeMode = CreateConVar("mmg_earrapemode", "0", "Makes the explosion of an explosive Market Garden happen instantly, but will rip your ears off and might crash your server, only relevant for masochists", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookConVarChange(cvarDamageMult, CvarChange);
	HookConVarChange(cvarCritAnnounce, CvarChange);
	HookConVarChange(cvarSoundAnnounce, CvarChange);
	HookConVarChange(cvarSoundPath, CvarChange);
	HookConVarChange(cvarIndexList, CvarChange);
	HookConVarChange(cvarAllWeaponsMG, CvarChange);
	HookConVarChange(cvarAllMGWillCrit, CvarChange);
	HookConVarChange(cvarExplosiveMMG, CvarChange);
	HookConVarChange(cvarExplosionForce, CvarChange);
	HookConVarChange(cvarExplosionMagnitude, CvarChange);
	HookConVarChange(cvarExplosionRadius, CvarChange);
	HookConVarChange(cvarEarRapeMode, CvarChange);
	
	HookEvent("rocket_jump", RocketJumped, EventHookMode_Pre);
	HookEvent("sticky_jump", RocketJumped, EventHookMode_Pre);
	
	HookEvent("rocket_jump_landed", RocketJumpLanded, EventHookMode_Pre);
	HookEvent("sticky_jump_landed", RocketJumpLanded, EventHookMode_Pre);
	
	PrecacheSound(SoundPath, true);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarDamageMult)
		DamageMult = StringToFloat(newValue);
	if (convar == cvarCritAnnounce)
		CritAnnounce = bool:StringToInt(newValue);
	if (convar == cvarSoundAnnounce)
		SoundAnnounce = bool:StringToInt(newValue);
	if (convar == cvarSoundPath)
	{
		strcopy(SoundPath, sizeof(SoundPath), newValue);
		PrecacheSound(SoundPath, false);
	}
	if (convar == cvarIndexList)
	{
		decl String:buffer[16][16];
		ExplodeString(newValue, " ", buffer, 16, 8, true);
		for (new i = 0; i<16; i++)
			IndexList[i]=StringToInt(buffer[i]);
	}
	if (convar == cvarAllWeaponsMG)
		AllWeaponsMG = bool:StringToInt(newValue);
	if (convar == cvarAllMGWillCrit)
		AllMGWillCrit = bool:StringToInt(newValue);
	if (convar == cvarExplosiveMMG)
		ExplosiveMMG = bool:StringToInt(newValue);
	if (convar == cvarExplosionForce)
		ExplosionForce = StringToFloat(newValue);
	if (convar == cvarExplosionMagnitude)
		ExplosionMagnitude = StringToInt(newValue);
	if (convar == cvarExplosionRadius)
		ExplosionRadius = StringToInt(newValue);
	if (convar == cvarEarRapeMode)
		EarRapeMode = bool:StringToInt(newValue);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	if (!IsSoundPrecached(SoundPath))
		PrecacheSound(SoundPath, true);
}

public OnConfigsExecuted()
{
	DamageMult = GetConVarFloat(cvarDamageMult);
	CritAnnounce = bool:GetConVarInt(cvarCritAnnounce);
	SoundAnnounce = bool:GetConVarInt(cvarSoundAnnounce);
	AllWeaponsMG = bool:GetConVarInt(cvarAllWeaponsMG);
	AllMGWillCrit = bool:GetConVarInt(cvarAllMGWillCrit);
	ExplosiveMMG = bool:GetConVarInt(cvarExplosiveMMG);
	ExplosionForce = GetConVarFloat(cvarExplosionForce);
	ExplosionMagnitude = GetConVarInt(cvarExplosionMagnitude);
	ExplosionRadius = GetConVarInt(cvarExplosionRadius);
	EarRapeMode = bool:GetConVarInt(cvarEarRapeMode);
	
	GetConVarString(cvarSoundPath, SoundPath, sizeof(SoundPath));
	PrecacheSound(SoundPath, false);
	
	
	decl String:buffer[16][16];
	decl String:buffer2[100];
	GetConVarString(cvarIndexList, buffer2, sizeof(buffer2));
	ExplodeString(buffer2, " ", buffer, 16, 8, true);
	for (new i = 0; i<16; i++)
		IndexList[i]=StringToInt(buffer[i]);
}

public Action:RocketJumped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	InExplosiveJump[client]=true;
	
	return Plugin_Continue;
}

public Action:RocketJumpLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	InExplosiveJump[client]=false;
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (InExplosiveJump[attacker])
	{
		new wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		for (new i = 0; i<16; i++)
		if ((AllWeaponsMG && GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee)) || (IndexList[i] > -1 && wepindex == IndexList[i]))
		{
			damage *= DamageMult;

			if (SoundAnnounce)
			{
				new Float:pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);

				EmitSoundToAll(SoundPath, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToAll(SoundPath, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
			}
					
			if (CritAnnounce)
			{
				new Handle:MegaGardener = CreateEvent("player_hurt", true);
				SetEventInt(MegaGardener, "userid", GetClientUserId(client));
				SetEventInt(MegaGardener, "attacker", GetClientUserId(attacker));
				SetEventBool(MegaGardener, "crit", true);
				SetEventBool(MegaGardener, "allseecrit", true);
				FireEvent(MegaGardener);
			}
			
			if (ExplosiveMMG)
			{
				if (EarRapeMode)
				{
					new explosion = CreateEntityByName("env_explosion");
					DispatchKeyValueFloat(explosion, "DamageForce", ExplosionForce);
				
					SetEntProp(explosion, Prop_Data, "m_iMagnitude", ExplosionMagnitude, 4);
					SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", ExplosionRadius, 4);
					SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
				
					DispatchSpawn(explosion);
				
					new Float:pos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				
					TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
					AcceptEntityInput(explosion, "Explode");
					AcceptEntityInput(explosion, "kill");
				}
				else
				{
					new Handle:data;
					CreateDataTimer(0.1, t_CreateExplosion, data);
					WritePackCell(data, attacker);
					WritePackCell(data, client);
				}
			}
			return Plugin_Changed;
		}
	}
	
	decl String:classname[32];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	if (StrEqual("env_explosion", classname, false))
	{
		new clientteam = GetClientTeam(client);
		new explosionOwnerTeam = GetClientTeam(attacker);

		if (clientteam == explosionOwnerTeam)
			return Plugin_Handled;
			
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action:t_CreateExplosion(Handle:timer, Handle:data)
{
	ResetPack(data);
	new attacker = ReadPackCell(data);
	new client = ReadPackCell(data);

	new explosion = CreateEntityByName("env_explosion");
	DispatchKeyValueFloat(explosion, "DamageForce", ExplosionForce);
				
	SetEntProp(explosion, Prop_Data, "m_iMagnitude", ExplosionMagnitude, 4);
	SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", ExplosionRadius, 4);
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
				
	DispatchSpawn(explosion);
				
	new Float:pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				
	TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(explosion, "kill");
}
	

public Action:TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (InExplosiveJump[client] && GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)==weapon && AllMGWillCrit)
	{
		if (AllWeaponsMG)
		{
			result = true;
			
			return Plugin_Changed;
		}
		else 
		{
			new wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			for (new i = 0; i<16; i++)
			if (IndexList[i] > -1 && wepindex == IndexList[i])
			{
				result = true;
				
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}