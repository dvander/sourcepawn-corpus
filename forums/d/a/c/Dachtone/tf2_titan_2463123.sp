#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

new bool:isTitan[MAXPLAYERS+1] = false;
new lastTeam[MAXPLAYERS+1] = 0;
new Handle:cSize = INVALID_HANDLE;
new Handle:cHealth = INVALID_HANDLE;
new Handle:cRange = INVALID_HANDLE;

new g_Lightning;
new g_Smoke;

#define PLUGIN_VERSION "0.1.8"

public Plugin:myinfo =
{
    name = "Be the Titan",
    author = "Dachtone",
    description = "Attack On Titan",
    version = PLUGIN_VERSION,
    url = "http://sourcegames.ru/"
}

public OnPluginStart()
{
	CreateConVar("titan_version", PLUGIN_VERSION, "Titan Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_titan", AdmTitan, ADMFLAG_ROOT, "Turn player into a Titan");
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	HookEvent("arena_round_start", RoundStart);
	HookEvent("teamplay_round_start", PreRoundStart);
	
	cSize = CreateConVar("titan_size", "3.0", "Titan's size", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cHealth = CreateConVar("titan_health", "3500", "Titan's health", FCVAR_PLUGIN);
	cRange = CreateConVar("titan_range", "1.5", "Titan's hit range", FCVAR_PLUGIN, true, 0.1, true, 10.0);
	
	LoadTranslations("common.phrases");
	
	for (new i = 1; i <= 32; i++)
	{
		if (IsValidClient(i))
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
	}
	
	g_Smoke = PrecacheModel("sprites/steam1.vmt", false);
	g_Lightning = PrecacheModel("sprites/lgtning.vmt", false);
}

public OnMapStart()
{
	g_Smoke = PrecacheModel("sprites/steam1.vmt");
	g_Lightning = PrecacheModel("sprites/lgtning.vmt");
}

public OnClientPostAdminCheck(client)
{
	isTitan[client] = false;
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public OnClientDisconnect(client)
{
	isTitan[client] = false;
}

public Action:PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (IsValidClient(client) && isTitan[client])
	{
		TF2Attrib_RemoveByName(client, "max health additive bonus");
		TF2Attrib_RemoveByName(client, "melee range multiplier");
		TF2Attrib_RemoveByName(client, "dmg taken from fire reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from crit reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from blast reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from bullets reduced");
		TF2Attrib_RemoveByName(client, "cannot be backstabbed");
		CreateSmoke(client, false);
		ChangeClientTeam(client, lastTeam[client]);
	}
	isTitan[client] = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	isTitan[client] = false;
}

public Action:TraceAttack(client, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (IsValidClient(client) && IsValidClient(attacker) && (client != attacker))
	{
		if (isTitan[attacker])
		{
			damage = 500.0;
			return Plugin_Changed;
		}
		if (isTitan[client])
		{
			if (hitbox == 5)
			{
				damage = 500.0;
				return Plugin_Changed;
			}
			else
			{
				damage = damage / 3;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsValidClient(client) && IsPlayerAlive(client))
	{
		decl String:sClassName[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, sClassName, sizeof(sClassName)))
		{
			FakeClientCommandEx(client, "use %s", sClassName);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

public PreRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= 32; i++)
	{
		if(IsValidClient(i) && isTitan[i])
		{
			TF2Attrib_RemoveByName(i, "max health additive bonus");
			TF2Attrib_RemoveByName(i, "melee range multiplier");
			TF2Attrib_RemoveByName(i, "dmg taken from fire reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from crit reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from blast reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from bullets reduced");
			TF2Attrib_RemoveByName(i, "cannot be backstabbed");
			ChangeClientTeam(i, lastTeam[i]);
			TF2_RespawnPlayer(i);
			isTitan[i] = false;
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= 32; i++)
	{
		if(IsValidClient(i) && isTitan[i])
		{
			TF2Attrib_RemoveByName(i, "max health additive bonus");
			TF2Attrib_RemoveByName(i, "melee range multiplier");
			TF2Attrib_RemoveByName(i, "dmg taken from fire reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from crit reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from blast reduced");
			TF2Attrib_RemoveByName(i, "dmg taken from bullets reduced");
			TF2Attrib_RemoveByName(i, "cannot be backstabbed");
			ChangeClientTeam(i, lastTeam[i]);
			TF2_RespawnPlayer(i);
			isTitan[i] = false;
		}
	}
}

public Action:AdmTitan(client, args)
{
	new target;
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] sm_titan <nick>");
		return Plugin_Handled;
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	target = FindTarget(client, arg);
	if (target == -1)
		return Plugin_Handled;

	if (IsValidClient(target))
	{
		if (!isTitan[target])
		{
			if (IsPlayerAlive(target))
			{
				CreateTimer(2.0, MakeTitan, target);
				Lightning(target);
				CreateSmoke(target, true);
				
				ReplyToCommand(client, "[SM] %N is a Titan now", target);
			}
			else
			{
				ReplyToCommand(client, "[SM] Player must be alive");
			}
		}
		else
		{
			if (IsPlayerAlive(target))
			{
				CreateTimer(2.0, UnMakeTitan, target);
				CreateSmoke(target, true);
			}
			else
			{
				TF2Attrib_RemoveByName(target, "max health additive bonus");
				TF2Attrib_RemoveByName(target, "melee range multiplier");
				TF2Attrib_RemoveByName(target, "dmg taken from fire reduced");
				TF2Attrib_RemoveByName(target, "dmg taken from crit reduced");
				TF2Attrib_RemoveByName(target, "dmg taken from blast reduced");
				TF2Attrib_RemoveByName(target, "dmg taken from bullets reduced");
				TF2Attrib_RemoveByName(target, "cannot be backstabbed");
				ChangeClientTeam(target, lastTeam[target]);
				isTitan[target] = false;
			}
			ReplyToCommand(client, "[SM] %N is no longer a Titan", target);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Player must be available");
	}
	return Plugin_Handled;
}

public Action:MakeTitan(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		lastTeam[client] = GetClientTeam(client);
		new Float:origin[3], Float:angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		ChangeClientTeam(client, 0);
		TF2_RespawnPlayer(client);
		TeleportEntity(client, origin, angles, NULL_VECTOR);
		new Float:size = GetConVarFloat(cSize);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
		UpdatePlayerHitbox(client, size);
		SetEntProp(client, Prop_Send, "m_nSkin", 0);
		new Float:Fhealth, health, Float:Frange;
		Fhealth = GetConVarFloat(cHealth);
		health = GetConVarInt(cHealth) + GetClientHealth(client);
		Frange = GetConVarFloat(cRange);
		TF2Attrib_SetByName(client, "max health additive bonus", Fhealth);
		TF2Attrib_SetByName(client, "melee range multiplier", Frange);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 1.0);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 1.0);
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 1.0);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 1.0);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		SetEntProp(client, Prop_Send, "m_iHealth", health);
		TF2_SwitchtoSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 3);
		TF2_RemoveWeaponSlot(client, 4);
		TF2_RemoveWeaponSlot(client, 5);
		CreateSmoke(client, true);
		Lightning(client);
		isTitan[client] = true;
	}
}

public Action:UnMakeTitan(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2Attrib_RemoveByName(client, "max health additive bonus");
		TF2Attrib_RemoveByName(client, "melee range multiplier");
		TF2Attrib_RemoveByName(client, "dmg taken from fire reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from crit reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from blast reduced");
		TF2Attrib_RemoveByName(client, "dmg taken from bullets reduced");
		TF2Attrib_RemoveByName(client, "cannot be backstabbed");
		new Float:origin[3], Float:angles[3];
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		ChangeClientTeam(client, lastTeam[client]);
		TF2_RespawnPlayer(client);
		TeleportEntity(client, origin, angles, NULL_VECTOR);
		isTitan[client] = false;
		CreateSmoke(client, false);
	}
}

stock UpdatePlayerHitbox(client, Float:fScale)
{ 
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	
	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock FindEntityByClassnameSafe(iStart, String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart))
	{
		iStart--;
	}
	return FindEntityByClassname(iStart, strClassname);
}

CreateSmoke(target, bool:follow)
{
	if(IsValidClient(target) && IsPlayerAlive(target))
	{
		new SmokeEnt = CreateEntityByName("env_smokestack");
		
		new Float:location[3];
		GetClientAbsOrigin(target, location);
	
		new String:originData[64];
		Format(originData, sizeof(originData), "%f %f %f", location[0], location[1], location[2]);
		
		new String:SmokeColor[128] = "255 255 255";
		new String:SmokeTransparency[32] = "255";
		new String:SmokeDensity[32] = "30";
		
		if(SmokeEnt)
		{
			new String:SName[128];
			Format(SName, sizeof(SName), "Smoke%i", target);
			DispatchKeyValue(SmokeEnt,"targetname", SName);
			DispatchKeyValue(SmokeEnt,"Origin", originData);
			DispatchKeyValue(SmokeEnt,"BaseSpread", "100");
			DispatchKeyValue(SmokeEnt,"SpreadSpeed", "70");
			DispatchKeyValue(SmokeEnt,"Speed", "180");
			DispatchKeyValue(SmokeEnt,"StartSize", "400");
			DispatchKeyValue(SmokeEnt,"EndSize", "2");
			DispatchKeyValue(SmokeEnt,"Rate", SmokeDensity);
			DispatchKeyValue(SmokeEnt,"JetLength", "1000");
			DispatchKeyValue(SmokeEnt,"Twist", "20"); 
			DispatchKeyValue(SmokeEnt,"RenderColor", SmokeColor);
			DispatchKeyValue(SmokeEnt,"RenderAmt", SmokeTransparency);
			DispatchKeyValue(SmokeEnt,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			
			DispatchSpawn(SmokeEnt);
			AcceptEntityInput(SmokeEnt, "TurnOn");
			
			if (follow)
			{
				SetVariantString("!activator");
				AcceptEntityInput(SmokeEnt, "SetParent", target, SmokeEnt);
			}
			
			new Handle:pack
			CreateDataTimer(5.0, Timer_KillSmoke, pack)
			WritePackCell(pack, SmokeEnt);
			
			new Float:longerdelay = 10.0;
			new Handle:pack2
			CreateDataTimer(longerdelay, Timer_StopSmoke, pack2)
			WritePackCell(pack2, SmokeEnt);
		}
	}
}

public Action:Timer_KillSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack);
	new SmokeEnt = ReadPackCell(pack);
	
	StopSmokeEnt(SmokeEnt);
}

StopSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "TurnOff");
	}
}

public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack);
	new SmokeEnt = ReadPackCell(pack);
	
	RemoveSmokeEnt(SmokeEnt);
}

RemoveSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}

Lightning(client)
{
	new Float:clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	clientpos[2] -= 26;
	
	new randomx = GetRandomInt(-500, 500);
	new randomy = GetRandomInt(-500, 500);
	
	new Float:startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + 800;
	
	new color[4] = {255, 255, 0, 255};
	new Float:dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, clientpos, g_Lightning, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(clientpos, g_Smoke, 5.0, 10);
	TE_SendToAll();
}

stock bool:IsValidClient(client)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientConnected(client) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}