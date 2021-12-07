#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.4";

new bool:g_bCheckedEngine = false;
new bool:g_bNeedsFakePrecache = false;

public Plugin:myinfo = 
{
	name = "Knife Headshot",
	author = "Eyal282",
	description = "Doubles inflicted damage with knife on a successful headshot",
	version = PLUGIN_VERSION,
	url = "None."
}

new LastHitGroup[MAXPLAYERS+1][MAXPLAYERS+1]; // First is victim, second is attacker.

new Handle:hcv_Enabled = INVALID_HANDLE;
new Handle:hcv_Multiplier = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	hcv_Enabled = CreateConVar("knife_headshot_enabled", "1", "Determines if to allow knife headshots", FCVAR_NOTIFY);
	hcv_Multiplier = CreateConVar("knife_headshot_multiplier", "2.0", "Determines how much to multiply knife headshot damage", FCVAR_NOTIFY);
	
	SetConVarString(CreateConVar("knife_headshot_version", PLUGIN_VERSION, "", FCVAR_NOTIFY), PLUGIN_VERSION);
	
	for(new i=1;i <= MaxClients;i++) // If plugin gets reloaded...
	{
		if(!IsClientInGame(i))
			continue;
			
		SDKHook(i, SDKHook_TraceAttack, Event_TraceAttack);
	}
}

public OnMapStart()
{				
	PrecacheSoundAny("*player/bhit_helmet-1.wav");
	PrecacheSoundAny("*player/headshot1.wav");
	PrecacheSoundAny("*player/headshot2.wav");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, Event_TraceAttack);
}

// https://forums.alliedmods.net/showpost.php?p=2565252&postcount=6

// https://forums.alliedmods.net/showpost.php?p=2565443&postcount=10

// His code is broken so don't use it but I gotta give credit for it :). Also trace to only hit victim is safer than don't hit self.

// The second guy is the fix for the broken code.

public Action:Event_PlayerHurt(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == 0)
		return Plugin_Continue;
		
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(victim == attacker)
		return Plugin_Continue;
		
	new String:WeaponName[50];
	
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!IsKnifeClass(WeaponName))
		return Plugin_Continue;
	
	new Float:Position[3], Float:Angles[3];
	
	GetClientEyePosition(attacker, Position); 
	GetClientEyeAngles(attacker, Angles); 
	
	TR_TraceRayFilter(Position, Angles, MASK_SHOT, RayType_Infinite, Trace_HitVictimOnly, victim); //Start the trace 
     
	new HitGroup = TR_GetHitGroup(); //Get the hit group 
	
	SetEventInt(hEvent, "hitgroup", HitGroup); // Would be nice to have Chest and legs instead of just Body.
	
	if(HitGroup == 1)
	{
		new Float:Origin[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", Origin);
		SetEventBool(hEvent, "headshot", true);
		
		if(GetClientHelmet(victim))
		{
			EmitSoundToAllAny("*player/bhit_helmet-1.wav", victim, SNDCHAN_AUTO, 60, _, 1.0, 100, _, Origin, _, _, _);
		}
		else
		{
			if(GetRandomBool())
				EmitSoundToAllAny("*player/headshot1.wav", victim, SNDCHAN_AUTO, 60, _, 1.0, 100, _, Origin, _, _, _);
				
			else
				EmitSoundToAllAny("*player/headshot2.wav", victim, SNDCHAN_AUTO, 60, _, 1.0, 100, _, Origin, _, _, _);
		}
			
	}
		
	LastHitGroup[victim][attacker] = HitGroup;
		
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(attacker == 0)
		return Plugin_Continue;
		
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(victim == attacker)
		return Plugin_Continue;
		
	new String:WeaponName[50];
	
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!IsKnifeClass(WeaponName))
		return Plugin_Continue;
	
	
	if(LastHitGroup[victim][attacker] == 1)
	{
		new Float:Origin[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", Origin);
		SetEventBool(hEvent, "headshot", true);
		
		if(GetRandomBool())
			EmitSoundToAllAny("*player/headshot1.wav", victim, SNDCHAN_AUTO, 60, _, 1.0, 100, _, Origin, _, _, _);
			
		else
			EmitSoundToAllAny("*player/headshot2.wav", victim, SNDCHAN_AUTO, 60, _, 1.0, 100, _, Origin, _, _, _);
	}
		
	return Plugin_Continue;
}

public Action:Event_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!GetConVarBool(hcv_Enabled))
		return Plugin_Continue;
		
	else if(attacker == victim)
		return Plugin_Continue;
		
	if(!IsPlayer(attacker))
		return Plugin_Continue;
	
	new Float:Position[3], Float:Angles[3];
	GetClientEyePosition(attacker, Position); 
	GetClientEyeAngles(attacker, Angles); 
	
	TR_TraceRayFilter(Position, Angles, MASK_SHOT, RayType_Infinite, Trace_HitVictimOnly, victim); //Start the trace 

	new HitGroup = TR_GetHitGroup(); //Get the hit group 
	
	new bool:headshot = false;
	
	if (HitGroup == 1)
	{ 
		headshot = true;
	}

	new String:Classname[13];
	
	new weapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
	
	if(weapon == -1)
		return Plugin_Continue;
		
	GetEdictClassname(weapon, Classname, sizeof(Classname)); // weapon_knifegg will also be taken into consideration.

	if(!IsKnifeClass(Classname))
		return Plugin_Continue;
	
	if(headshot)
	{
		damage *= GetConVarFloat(hcv_Multiplier);
		return Plugin_Changed;
	}
		
	return Plugin_Continue;
}

public bool:Trace_HitVictimOnly(entity, contentsMask, victim) 
{ 
	return entity == victim; 
}  

stock bool:GetClientHelmet(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_bHasHelmet");
}

stock bool:IsPlayer(client)
{
	return (client > 0 && client <= MaxClients);
}

stock bool:GetRandomBool()
{
	return (GetRandomInt(0, 1) == 1);
}

stock bool:IsKnifeClass(const String:classname[])
{
	if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") > -1)
		return true;
		
	return false;
}

// Emit sound any.

stock EmitSoundToAllAny(const String:sample[], 
                 entity = SOUND_FROM_PLAYER, 
                 channel = SNDCHAN_AUTO, 
                 level = SNDLEVEL_NORMAL, 
                 flags = SND_NOFLAGS, 
                 Float:volume = SNDVOL_NORMAL, 
                 pitch = SNDPITCH_NORMAL, 
                 speakerentity = -1, 
                 const Float:origin[3] = NULL_VECTOR, 
                 const Float:dir[3] = NULL_VECTOR, 
                 bool:updatePos = true, 
                 Float:soundtime = 0.0)
{
	new clients[MaxClients];
	new total = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[total++] = i;
		}
	}
	
	if (!total)
	{
		return;
	}
	
	EmitSoundAny(clients, total, sample, entity, channel, 
	level, flags, volume, pitch, speakerentity,
	origin, dir, updatePos, soundtime);
}

stock bool:PrecacheSoundAny( const String:szPath[], bool:preload=false)
{
	EmitSoundCheckEngineVersion();
	
	if (g_bNeedsFakePrecache)
	{
		return FakePrecacheSoundEx(szPath);
	}
	else
	{
		return PrecacheSound(szPath, preload);
	}
}

stock static EmitSoundCheckEngineVersion()
{
	if (g_bCheckedEngine)
	{
		return;
	}

	new EngineVersion:engVersion = GetEngineVersion();
	
	if (engVersion == Engine_CSGO || engVersion == Engine_DOTA)
	{
		g_bNeedsFakePrecache = true;
	}
	g_bCheckedEngine = true;
}

stock static bool:FakePrecacheSoundEx( const String:szPath[] )
{
	decl String:szPathStar[PLATFORM_MAX_PATH];
	Format(szPathStar, sizeof(szPathStar), "*%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), szPathStar );
	return true;
}

stock EmitSoundAny(const clients[], 
                 numClients, 
                 const String:sample[], 
                 entity = SOUND_FROM_PLAYER, 
                 channel = SNDCHAN_AUTO, 
                 level = SNDLEVEL_NORMAL, 
                 flags = SND_NOFLAGS, 
                 Float:volume = SNDVOL_NORMAL, 
                 pitch = SNDPITCH_NORMAL, 
                 speakerentity = -1, 
                 const Float:origin[3] = NULL_VECTOR, 
                 const Float:dir[3] = NULL_VECTOR, 
                 bool:updatePos = true, 
                 Float:soundtime = 0.0)
{
	EmitSoundCheckEngineVersion();

	decl String:szSound[PLATFORM_MAX_PATH];
	
	if (g_bNeedsFakePrecache)
	{
		Format(szSound, sizeof(szSound), "*%s", sample);
	}
	else
	{
		strcopy(szSound, sizeof(szSound), sample);
	}
	
	EmitSound(clients, numClients, szSound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);	
}

