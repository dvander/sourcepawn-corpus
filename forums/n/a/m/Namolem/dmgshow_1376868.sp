#include <sourcemod>
#include <sdkhooks>

new Handle:cVarMinDistanceShow;
new Handle:cVarMinDistanceKill;
new Float:MinDistanceShow;
new Float:MinDistanceKill;
new totalDamage[MAXPLAYERS+1];
new kills[MAXPLAYERS+1];
new Float:ClassDefence[] = {5.0,10.0,15.0,15.0,40.0,25.0,30.0,45.0,50.0 }
new Float:HitGroupKoeffitient[] = {
								1.0, 
								1.25, // Head
								1.0, // Chest
								1.0, 
								1.0, // LArm
								1.0, // RArm
								0.75, //LLeg
								0.75, // RLeg
								1.3 // Neck
							};
							
public Plugin:myinfo = {
        name = "Damage&Distance Show",
        author = "Namolem",
        description = "0",
        version = "1.0.0.0",
        url = "0"
};

public OnPluginStart()
{
	HookEvent("player_spawn",PlayerSpawnEvent);
	CreateTimer(0.75,ShowHud,_,TIMER_REPEAT);
	LoadTranslations("plugin.dmgshow.phrases");
	for (new client = 1; client <= MAXPLAYERS; client++)
	{
		if (ValidPlayer(client))
		{
			SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		}
	}
	cVarMinDistanceShow = CreateConVar("dmgshow_distance_show","15","Min distance to show on attack,meters",_,true,0.0);
	cVarMinDistanceKill = CreateConVar("dmgshow_distance_kill","40","Min distance to 100% kill,meters",_,true,0.0);
	CreateConVar("dmgshow_version","1.0","Damage&Distance show plugin version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	MinDistanceShow = GetConVarFloat(cVarMinDistanceShow)/0.03048;
	MinDistanceKill = GetConVarFloat(cVarMinDistanceKill)/0.03048;
	HookConVarChange(cVarMinDistanceKill,ConVarChange);
	HookConVarChange(cVarMinDistanceShow,ConVarChange);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MinDistanceShow = GetConVarFloat(cVarMinDistanceShow)/0.03048;
	MinDistanceKill = GetConVarFloat(cVarMinDistanceKill)/0.03048;
}
public OnPluginEnd()
{
	for (new client = 1;client <= MAXPLAYERS;client++)
	{
		if (ValidPlayer(client))
		{
			SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	decl Float:victimVec[3];
	decl Float:attackerVec[3];
	GetClientAbsOrigin(victim,victimVec);
	GetClientAbsOrigin(attacker,attackerVec);
	new Float:distance = GetVectorDistance(victimVec,attackerVec);
	if (distance >= MinDistanceKill)
		damage = 333.0;
	new Float:realDamage = (HitGroupKoeffitient[hitgroup]*damage*(100.0-ClassDefence[GetEntProp(victim, Prop_Send, "m_iClass")]))/100.0;	
	if (distance >= MinDistanceShow)
	{
		PrintCenterText(attacker,"%t","HP METERS",RoundFloat( realDamage ),distance*0.03048);
	}
	else
	{
		PrintCenterText(attacker,"%t","HP",RoundFloat( realDamage ));
	}
	totalDamage[attacker] += RoundFloat(realDamage);
	if (realDamage >= GetClientHealth(victim))
		kills[attacker]++;
	ShowHud(INVALID_HANDLE);
	return Plugin_Changed;
}
stock bool:ValidPlayer(client,bool:check_alive=false){
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		return true;
	}
	return false;
}
public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	totalDamage[client] = 0;
	kills[client] = 0;
	ShowHud(INVALID_HANDLE);
}
public Action:ShowHud(Handle:timer)
{
	for (new player=1;player<=MAXPLAYERS;player++)
	{
		if (!ValidPlayer(player) || IsFakeClient(player) || GetClientTeam(player) < 2) continue;
		if (IsPlayerAlive(player))
		{
			PrintHintText(player,"%T","HP KILLED DAMAGE",player,GetClientHealth(player),kills[player],totalDamage[player]);
		}
		else
		{
			PrintHintText(player,"%T","KILLED DAMAGE",player,kills[player],totalDamage[player]);
		}
	}
}