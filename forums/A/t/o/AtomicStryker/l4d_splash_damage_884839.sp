#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.8"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY


static const Float:TRACE_TOLERANCE 			= 25.0;

static Handle:SplashEnabled = INVALID_HANDLE;
static Handle:SplashRadius = INVALID_HANDLE;
static Handle:SplashDamage = INVALID_HANDLE;
static Handle:DisplayDamageMessage = INVALID_HANDLE;
static bool:IsSwappingTeam[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "L4D_Splash_Damage",
	author = " AtomicStryker",
	description = "Left 4 Dead Boomer Splash Damage",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=98794"
}

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", PlayerTeam);
	
	CreateConVar("l4d_splash_damage_version", PLUGIN_VERSION, " Version of L4D Boomer Splash Damage on this server ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	SplashEnabled = CreateConVar("l4d_splash_damage_enabled", "1", " Enable/Disable the Splash Damage plugin ", CVAR_FLAGS);
	SplashDamage = CreateConVar("l4d_splash_damage_damage", "10.0", " Amount of damage the Boomer Explosion deals ", CVAR_FLAGS);
	SplashRadius = CreateConVar("l4d_splash_damage_radius", "200", " Radius of Splash damage ", CVAR_FLAGS);
	DisplayDamageMessage = CreateConVar("l4d_splash_damage_notification", "1", " 0 - Disabled; 1 - small HUD Hint; 2 - big HUD Hint; 3 - Chat Notification ", CVAR_FLAGS);
	
	AutoExecConfig(true, "L4D_Splash_Damage");
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client)) return;
	
	IsSwappingTeam[client] = true;
	CreateTimer(2.0, EraseGhostExploit, client);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client)) return;
	
	if (GetClientTeam(client)!=3) return;
	if (IsSwappingTeam[client]) return;

	CreateTimer(0.1, Splashdamage, client);
}

public Action:Splashdamage(Handle:timer, any:client)
{
	if (!IsClientInGame(client)) return Plugin_Stop;

	decl String:class[100];
	GetClientModel(client, class, sizeof(class));
	
	if (StrContains(class, "boome", false) != -1)
	{
		if (GetConVarInt(SplashEnabled))
		{
			//PrintToChatAll("Boomerdeath caught, Plugin running");
			decl Float:g_pos[3];
			GetClientEyePosition(client,g_pos);
			
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target))
				{
					if (IsPlayerAlive(target))
					{
						if (GetClientTeam(client) != GetClientTeam(target))
						{
							decl Float:targetVector[3];
							GetClientEyePosition(target, targetVector);
							
							new Float:distance = GetVectorDistance(targetVector, g_pos);
							
							if (distance < GetConVarFloat(SplashRadius) && IsVisibleTo(g_pos, targetVector))
							{							
								switch (GetConVarInt(DisplayDamageMessage))
								{
									case 1:
									PrintCenterText(target, "You've taken Damage from a Boomer Splash!");
									
									case 2:
									PrintHintText(target, "You've taken Damage from a Boomer Splash!");
									
									case 3:
									PrintToChat(target, "You've taken Damage from a Boomer Splash!");
								}
								
								applyDamage(GetConVarInt(SplashDamage), target, client);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Stop;
}

// timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684
// added some L4D specific checks
static applyDamage(damage, victim, attacker)
{ 
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.10, timer_stock_applyDamage, dataPack);
}

public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
	ResetPack(dataPack);
	new damage = ReadPackCell(dataPack);  
	new victim = ReadPackCell(dataPack);
	new attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);
	
	decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
	
	if (!IsClientInGame(victim)) return;
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	new entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;
	
	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "65536");
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}

static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	
	return isVisible;
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}

public Action:EraseGhostExploit(Handle:timer, Handle:client)
{	
	IsSwappingTeam[client] = false;
	return Plugin_Handled;
}