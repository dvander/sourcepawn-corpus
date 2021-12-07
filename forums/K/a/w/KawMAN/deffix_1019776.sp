#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.2.2"
#define DEFDIST 150.0
#define DEBUG 0


public Plugin:myinfo = {
	name = "[CS:S] Defuse Fix",
	author = "KawMAN",
	description = "Fix some bugs related with Bomb defusing",
	version = PLUGIN_VERSION,
	url = "http://www.wsciekle.pl/"
};

new bombent = -1;
new Float:bomb_pos[3];
new cooldown[MAXPLAYERS+1] = {0, ...};

new Handle:cDefFixDefuser, bool:DefFixDefuser = true;
new Handle:cDefFixPropPhys, DefFixPropPhys = 0;
new Handle:cDefFixWall, bool:DefFixWall = true;
new Handle:gCvar_Version = INVALID_HANDLE;

public OnPluginStart() 
{
	
	gCvar_Version = CreateConVar("sm_deffix", PLUGIN_VERSION, "Defuse Fix Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDefFixWall = CreateConVar("sm_deffix_anti_walldef", "1", "Prevent defusing bomb through walls",
	FCVAR_PLUGIN,true,0.0,true,1.0);
	cDefFixDefuser = CreateConVar("sm_deffix_anti_defblock", "1", "What to do with idle defusers around bomb 0=Off, 1=Push away",
	FCVAR_PLUGIN,true,0.0,true,1.0);
	cDefFixPropPhys = CreateConVar("sm_deffix_anti_propblock", "1", "What to do with Props (prop_physics*) around bomb 0=Off, 1=Push away, 2=Remove",
	FCVAR_PLUGIN,true,0.0,true,2.0);

	HookConVarChange(cDefFixDefuser, MyCVARChange);
	HookConVarChange(cDefFixPropPhys, MyCVARChange);
	
	HookEvent("bomb_planted", EventBombPlanted);
	HookEvent("bomb_defused", EventReset);
	HookEvent("bomb_exploded", EventReset);
	HookEvent("round_start", EventReset);
	HookEvent("round_end", EventReset);
	
	UpdateState();
}

public MyCVARChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

UpdateState() {
	DefFixDefuser = GetConVarBool(cDefFixDefuser);
	DefFixPropPhys = GetConVarInt(cDefFixPropPhys);
	DefFixWall = GetConVarBool(cDefFixWall);
}
public OnMapStart() {
	UpdateState();
	CreateTimer(5.0, DelayedVersionRefresh);
}
public Action:DelayedVersionRefresh(Handle:timer, any:client)
{
	SetConVarString(gCvar_Version, "0.0", false, false);
	SetConVarString(gCvar_Version, PLUGIN_VERSION, false, false);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(DefFixWall&&bombent!=-1)
	{
		if(buttons & IN_USE)
		{
			if(cooldown[client] == 0)
			{
				decl Float:client_pos[3];
				GetClientEyePosition( client, client_pos);
				//GetEntPropVector(client, Prop_Send, "m_vecOrigin", client_pos);
				new Float:ClientBombDist = GetVectorDistance(client_pos, bomb_pos);
				if(ClientBombDist<=DEFDIST)
				{
					#if DEBUG>0
					PrintToServer("[DEFFIX]%d In Range BPos: %f-%f-%f CPos: %f-%f-%f R:%f",client,
					bomb_pos[0],bomb_pos[1],bomb_pos[2], client_pos[0],client_pos[1],client_pos[2],
					ClientBombDist);
					#endif
					if(!CanDefuse(client))
					{
						#if DEBUG>1
						PrintToServer("[DEFFIX] Block Use for %d",client;
						#endif
						buttons &= ~IN_USE;
						cooldown[client] = 2 ;
					} else {
						cooldown[client] = 1;
					}
					CreateTimer(1.0,Timer_cooldown,client);
				}
				#if DEBUG>0
				else
				{
					PrintToServer("[DEFFIX] Out of Range %f",ClientBombDist );
					cooldown[client] = 2 ;
					CreateTimer(1.0,Timer_cooldown,client);
				}
				#endif
			}
			else if(cooldown[client] == 2)
			{
				buttons &= ~IN_USE;
			}
		}
	}
	return Plugin_Continue;
}


bool:CanDefuse(client)
{
	decl Float:client_pos[3],Float:vec[3],Float:vec2[3];
	decl Float:ClientBombDist, Float:ClientREndDist;
	
	GetClientEyePosition( client, client_pos);

	MakeVectorFromPoints(client_pos,bomb_pos,vec2);
	GetVectorAngles(vec2, vec);
	
	TR_TraceRayFilter(client_pos, vec, MASK_ALL, RayType_Infinite, TraceFilter, client);
	TR_GetEndPosition(vec, INVALID_HANDLE);

	ClientBombDist = GetVectorDistance(client_pos, bomb_pos);
	ClientREndDist = GetVectorDistance(client_pos, vec);
	
	#if DEBUG>0
	if(ClientREndDist>ClientBombDist) PrintToServer("[DEFFIX] Ray OverShot C:%d",client);
	if(ClientREndDist==ClientBombDist) PrintToServer("[DEFFIX] Dist(Ray) Equal C:%d",client);
	if(ClientREndDist<ClientBombDist) PrintToServer("[DEFFIX] Dist(Ray) Smaller Breaking !!! C:%d",client);
	if(TR_DidHit(INVALID_HANDLE))
	{
		new hitent = TR_GetEntityIndex(INVALID_HANDLE);
		new String:classname[64];
		GetEdictClassname(hitent, classname, sizeof(classname));
		PrintToServer("[DEFFIX] Ray Hit Ent %d %s", hitent,classname);
	}
	#endif
	if(ClientREndDist<ClientBombDist) return false;

	return true;

}

public bool:TraceFilter(ent, mask, any:data)
{
	//return true;
	//Ignore Clients
	if(ent>=0&&ent<=MaxClients) return false;
	
	decl String:classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	for(new i=0; i<sizeof(classname); i++)
	{
		if(classname[i]=='e' && classname[i+2]=='v') //env_
		{
			return false;
		}
		if(classname[i]=='p' && classname[i+9]=='e') //projectile
		{
			return false;
		}
		if(classname[i]=='w' && classname[i+6]=='_') //weapon_
		{
			return false;
		}
		if(classname[i]=='i' && classname[i+5]=='_') //item_
		{
			return false;
		}
		if(classname[i]=='\0')
		{
			break;
		}
	}
	/* This commands ade to expensive (StrContains mostly) and filter dont work with them
	if(StrContains(classname, "projectile")) return false;
	if(StrEqual(classname, "env_sprite")) return false;
	if(StrContains(classname, "projectile")) return false;
	if(StrContains(classname, "prop_physics", false)) return false;
	if(StrContains(classname, "item_", false)) return false;
	if(StrContains(classname, "func_breakable", false)) return true;
	*/
	return true;
}

public Action:EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bombent = FindEntityByClassname(-1,"planted_c4");
	GetEntPropVector(bombent, Prop_Send, "m_vecOrigin", bomb_pos);
	if(!CanDefuse(client))
	{
		bombent=-1;
	}
	CreateTimer(0.2,tPushThings);
}
public Action:EventReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	bombent = -1;
	for(new i = 1; i<=MaxClients; i++ ) cooldown[i] = 0;
}



public Action:tPushThings(Handle:timer, any:data)
{
	
	new bool:hited = false;
	decl Float:vObjPos[3] = {0.0, 0.0, 0.0},Float:vMidAngle[3] = {0.0, 90.0, 0.0};
	if(DefFixDefuser||DefFixPropPhys) {
		new maxentities = GetMaxEntities(); 
		for (new i = 1; i <= maxentities; i++)
		{
			if (!IsValidEdict(i)) continue; 
			
			decl String:classname[64];
			GetEdictClassname(i, classname, sizeof(classname));
			
			if(DefFixDefuser && (StrContains(classname, "item_", false)!=-1||StrContains(classname, "weapon_", false)!=-1)) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vObjPos);

				if (GetVectorDistance(bomb_pos, vObjPos) <= 30.0)
				{ 
					MakeVectorFromPoints(bomb_pos, vObjPos, vMidAngle);
					NormalizeVector(vMidAngle, vMidAngle);
					ScaleVector(vMidAngle, 300.0);
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vMidAngle);
					hited = true;
				} 
			}
			
			if(DefFixPropPhys && StrContains(classname, "prop_physics", false)!=-1) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vObjPos);
				if (GetVectorDistance(bomb_pos, vObjPos) <= 90.0)
				{
					if(DefFixPropPhys==1) { //Push
						MakeVectorFromPoints(bomb_pos, vObjPos, vMidAngle);
						NormalizeVector(vMidAngle, vMidAngle);
						ScaleVector(vMidAngle, 300.0);
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vMidAngle);
						hited = true;
					} else if (DefFixPropPhys==2) { //Remove 
						RemoveEdict(i);
						hited = true;
					}
				} 
			}
		}
	} 
	if(bombent!=-1) {
		if(hited) {	//We hited something in this loop so do another check quicker
			CreateTimer(0.2,tPushThings);
		} else { //Nothing was hitted in this loop so another loop will be later
			CreateTimer(1.5,tPushThings);
		}
	}
}

public Action:Timer_cooldown(Handle:timer, any:client)
{
	cooldown[client]=0;
}