#include <sourcemod>
#include <sdktools>
#include "SHSource/SHSource_Interface.inc"

new Handle:rubbulletdmg,Handle:rubbulletsT,Handle:totalrubbullets;
new heroID;
new countbullets[MAXPLAYERS+1];
new ctotalbullets[MAXPLAYERS+1];
new bulletlist[MAXPLAYERS+1][20];
new Float:rbullorig[MAXPLAYERS+1][20][3];
new maxpclients;

//Load Hero
public OnSHPluginReady()
{
      heroID=SH_CreateHero("Rubber Man","rubberman","Bullets Bounce of Walls.","16","0");
	rubbulletdmg = CreateConVar("rubberman_dmg", "5");
	rubbulletsT = CreateConVar("rubberman_bullets", "5"); //Rubber bullets per clip
	totalrubbullets = CreateConVar("rubberman_Tbullets", "20"); // Total Rubber bullets (MAX 20)

	HookEvent("weapon_fire",firerubberb);
	HookEvent("weapon_reload",reloadrubberb);
	HookEvent("player_spawn",PlayerSpawnrubberm);
	HookEvent("round_end",roundendrubman);
}

public OnMapStart()
{
	maxpclients = GetMaxClients();
}

public PlayerSpawnrubberm(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(SH_GetHasHero(client,heroID)) {
		ctotalbullets[client]=0;
		countbullets[client]=0;
	}
}

public firerubberb(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	
	new String:weapon[30];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	new numbullets = GetConVarInt(rubbulletsT);
	new totalbullets = GetConVarInt(totalrubbullets);
	
	if (ctotalbullets[client]>=totalbullets || countbullets[client]>=numbullets || StrEqual(weapon,"knife") || StrEqual(weapon,"flashbang") || StrEqual(weapon,"hegrenade") || StrEqual(weapon,"smokegrenade") || !SH_IsAlive(client) || !SH_GetHasHero(client,heroID)) {
		return;
	}
	
	//Shoot Rubber Bullet
	shootrbullet(client);


	ctotalbullets[client]+=1;
	countbullets[client]+=1;
	
	if(countbullets[client]==numbullets) {
		PrintToChat(client,"[SHSource] (Rubber Man) You are out of RUBBER bullets. Reload your gun!!");
	}
}

public reloadrubberb(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(SH_GetHasHero(client,heroID)) {
		new numbullets = GetConVarInt(rubbulletsT);
		if(countbullets[client]>=numbullets) {
			countbullets[client]=0;
		} else {
		 	countbullets[client] += (numbullets-countbullets[client]);
		}
	}
}

shootrbullet(client) {
	new Float:vAngles[3], Float:vReturn[3], Float:vPos[3];
	new Float:speed = 800.0;
	new ent = CreateEntityByName("prop_physics_multiplayer"); //info_target
	if(IsValidEntity(ent))
	{
		GetClientEyePosition(client, vPos);
		TeleportEntity(ent,vPos,NULL_VECTOR,NULL_VECTOR);
		SetEntityModel(ent,"shells/shell_338mag.mdl");
		DispatchSpawn(ent);
	
		GetClientEyeAngles(client, vAngles)
		vReturn[0] = FloatMul( Cosine( DegToRad(vAngles[1])  ) , speed);
		vReturn[1] = FloatMul( Sine( DegToRad(vAngles[1])  ) , speed);
		vReturn[2] = FloatMul( Sine( DegToRad(vAngles[0])  ) , speed);
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, vReturn);
		bulletlist[client][ctotalbullets[client]] = ent;
	}
}

public OnGameFrame()
{	
	new damage = GetConVarInt(rubbulletdmg);
	for (new i=1; i<=maxpclients; i++)
	{
	  if(IsClientInGame(i)) {
		new cteam = GetClientTeam(i);
		for (new b=0; b<=20; b++)
		{
			if(bulletlist[i][b]>0&&IsValidEntity(bulletlist[i][b])) {
			    new Float:oldorig[3];
				oldorig[0] = rbullorig[i][b][0];
				oldorig[1] =  rbullorig[i][b][1];
				oldorig[2] = rbullorig[i][b][2];
		            SH_GetOrigin(bulletlist[i][b],rbullorig[i][b]);
				if(GetVectorDistance(rbullorig[i][b],oldorig)<=5.0) {
					RemoveEdict(bulletlist[i][b]);		
					bulletlist[i][b] = 0;
				} else {
					for (new j=0; j<=maxpclients; j++)
					{
						new Float:corigin[3];
			  			GetClientAbsOrigin(j, corigin);
		  				if(GetVectorDistance(rbullorig[i][b],corigin)<=40.0&&cteam!=GetClientTeam(j))
						{
							new yhealth=GetClientHealth(j);
							if(damage>yhealth) {
							 SH_GiveKillXP(i);
							 SH_CommitSuicide(j);
							} else {
							 SH_SetHealth(j,(yhealth-damage));
							}
							RemoveEdict(bulletlist[i][b]);
							bulletlist[i][b] = 0;
						}
					}
				}
			}
		}
	  }
	}
}

public roundendrubman(Handle:event,const String:name[],bool:dontBroadcast)
{
 removerbull();
}
public OnMapEnd()
{
 removerbull();
}
removerbull() {
	for (new i=1; i<=maxpclients; i++)
	{
		for (new b=0; b<=20; b++)
		{
			if(bulletlist[i][b]>0&&IsValidEntity(bulletlist[i][b])) {
				RemoveEdict(bulletlist[i][b]);		
				bulletlist[i][b] = 0;
			}
		}
	}
}