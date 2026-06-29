#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define MeetChester_MDL "models/workshop/player/items/all_class/taunt_burstchester/taunt_burstchester_heavy.mdl"
int iChester[MAXPLAYERS+1] = -1;
int g_iClientDroppedKit[MAXPLAYERS+1] = 0;
bool MoveUp[1500] = false;
int MoveUpFloat[1500] = 0;
int g_LightningSprite;
ConVar g_hKitSpawned;
public Plugin myinfo =
{
	name = "BurstChester taunt",
	author = "TonyBaretta",
	description = "surprise!",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
}
public void OnMapStart() {
	PrecacheModel(MeetChester_MDL, true);
	PrecacheSound("misc/halloween/spell_skeleton_horde_rise.wav", true);
	PrecacheSound("ambient_mp3/medieval_thunder2.mp3", true);
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
}
public void OnPluginStart()
{
	g_hKitSpawned = CreateConVar("kit_max", "2.0", "max number of kit x client", FCVAR_NONE);
	CreateConVar("burstchester_taunt_version", PLUGIN_VERSION, "Current burstchester_taunt version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
	SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
	
}

public Action OnSceneSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"); 
	char scenefile[128];
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
	if ((StrEqual(scenefile, "scenes/workshop/player/scout/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/soldier/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/pyro/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/demoman/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/heavy/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/engineer/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/medic/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/sniper/low/taunt_burstchester.vcd")) ||
		(StrEqual(scenefile, "scenes/workshop/player/spy/low/taunt_burstchester.vcd"))){
		if ((GetEntityFlags(client) & FL_ONGROUND) ) 
		{ 
			{
				if (!IsValidClient(client)) return Plugin_Continue;
				if (!IsPlayerAlive(client)) return Plugin_Continue;
				CreateTimer(1.5, StartSpawn, client);
			}
		}
	}
	return Plugin_Continue;
}
public Action StartSpawn(Handle timer, any client){
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Handled;
	int iMaxKit = g_hKitSpawned.IntValue;	
	if (g_iClientDroppedKit[client] < iMaxKit)
	{
		float vPosition[3];
		float vAngles[3];
		float pos[3];
		float clientpos[3];
		float dir[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client, clientpos);
		clientpos[2] += 60.0;
		GetClientEyePosition(client, vPosition);
		GetClientEyeAngles(client, vAngles);
		int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		float WOrigin[3];
		GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", WOrigin);
		int indextaunt = GetEntProp(client, Prop_Send, "m_iTauntItemDefIndex");
		if(indextaunt == 30621)
		{
			Handle trace = TR_TraceRayFilterEx(vPosition, vAngles, MASK_SOLID, RayType_Infinite, TraceFilterSelf, client);
				
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(pos, trace);
				pos[2] += 25.0;
				int color[4] = {255, 255, 255, 255};
				EmitSoundToClient(client,"ambient_mp3/medieval_thunder2.mp3");
				TE_SetupBeamPoints(clientpos, pos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.5, color, 3);
				TE_SendToAll();
				TE_SetupSparks(pos, dir, 5000, 1000);
				TE_SendToAll();
				TE_SetupEnergySplash(pos, dir, false);
				TE_SendToAll();
				int Ent_Fake_Kit = CreateEntityByName("item_healthkit_medium");
				if(IsValidEntity(Ent_Fake_Kit)){
					SetEntPropEnt(Ent_Fake_Kit, Prop_Send, "m_hOwnerEntity", client); 
					DispatchSpawn(Ent_Fake_Kit); 
					TeleportEntity(Ent_Fake_Kit, pos, NULL_VECTOR, NULL_VECTOR);
					ChesterParticle(Ent_Fake_Kit, "ghost_appearation", 2.0);
					SDKHook(Ent_Fake_Kit, SDKHook_Touch, OnTouch);
					g_iClientDroppedKit[client]++;
					CreateTimer(60.0, KitKillTimer, EntIndexToEntRef(Ent_Fake_Kit));
				}
				delete trace;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Handled;
}
public Action KitKillTimer(Handle timer, int iRef)
{
	int iKit = EntRefToEntIndex(iRef);
	if(iKit > MaxClients)
	{
		int iClient = GetEntPropEnt(iKit, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(iClient))
		{
			g_iClientDroppedKit[iClient]--;
			if (g_iClientDroppedKit[iClient] < 0) g_iClientDroppedKit[iClient] = 0;
		}
		if(IsValidEntity(iKit)){
			AcceptEntityInput(iKit, "Kill");
		}
	}
}
public Action OnTouch(int iEnt, int client){
	char classname[64];
	GetEdictClassname(iEnt, classname, sizeof(classname));
	int owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	int team = GetClientTeam(owner);
	if (IsValidClient(owner))
	{
		g_iClientDroppedKit[owner]--;
		if (g_iClientDroppedKit[owner] < 0) g_iClientDroppedKit[owner] = 0;
		if (StrEqual(classname, "item_healthkit_medium")) {
			if(client <0 || client > MAXPLAYERS)return Plugin_Changed;
			if(IsValidClient(client) && (GetClientTeam(client) != GetClientTeam(owner))){
				AcceptEntityInput(iEnt, "Kill");
				SpawnChester(owner, client, team);
				EmitSoundToAll("misc/halloween/spell_skeleton_horde_rise.wav");
			}
		}
	}
	return Plugin_Continue;
}
public Action SpawnChester(int owner, int Target, int team) {
	float posg[3];
	if (IsValidClient(Target) && IsPlayerAlive(Target) && IsValidClient(owner)) {
		GetClientGroundPosition(Target, posg);
		float ang[3];
		ang[0] = -90.0;
		ang[1] = GetRandomFloat(-180.0 , 180.0);
		iChester[Target] = CreateEntityByName("prop_dynamic");
		if(IsValidEntity(iChester[Target])){
			SetEntPropEnt(iChester[Target], Prop_Send, "m_hOwnerEntity", owner);
			DispatchKeyValue(iChester[Target], "modelscale", "9.0");
			DispatchKeyValue(iChester[Target], "model", MeetChester_MDL);
			SetEntProp(iChester[Target], Prop_Send, "m_nSolidType", 2);
			SetEntProp(iChester[Target], Prop_Send, "m_iTeamNum", team);
			DispatchKeyValue(iChester[Target], "targetname", "chester_ent"); 
			DispatchSpawn(iChester[Target]);
			char addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 5.0);
			SetVariantString(addoutput);
			AcceptEntityInput(iChester[Target], "AddOutput");
			AcceptEntityInput(iChester[Target], "FireUser1");
			posg[2] = (posg[2] - 80.0);
			TeleportEntity(iChester[Target], posg, ang, NULL_VECTOR);
			int Rent = EntRefToEntIndex(iChester[Target]);
			CreateTimer(2.0, Timer_RemoveTarget, Rent );
			MoveUp[iChester[Target]] = true;
			ChesterParticle(iChester[Target], "ghost_appearation", 2.0);
			SDKHook(iChester[Target], SDKHook_StartTouch, OnTouchChester);
		}
	}
}
public void OnGameFrame(){
	for (int i=0; i<sizeof(iChester); i++)
	{
		if(IsValidEntity(iChester[i])){
			char classname[64];
			GetEdictClassname(iChester[i], classname, sizeof(classname));
			if (StrEqual(classname, "prop_dynamic")) {
				if (MoveUp[iChester[i]] && MoveUpFloat[iChester[i]] < 32) {
					MoveUpFloat[iChester[i]] += 5;
					ChesterBig_Pos(iChester[i]);
				}
				if (MoveUp[iChester[i]] == false && MoveUpFloat[iChester[i]] > 0) {
					MoveUpFloat[iChester[i]] -= 5;
					ChesterBig_Pos(iChester[i]);
				}
			}
		}
	}
	CheckForRoomsPos();
	CheckForIntelPos();
	CheckForCPPos();
	CheckForPLPos();
}
public Action CheckForRoomsPos()
{
	int iTrap = -1;
	while ((iTrap = FindEntityByClassname(iTrap, "item_healthkit_medium")) != -1)
	{
		float projloc[3];
		GetEntPropVector(iTrap, Prop_Send, "m_vecOrigin", projloc);

		int iRoom = -1;
		while ((iRoom  = FindEntityByClassname(iRoom, "func_respawnroomvisualizer")) != -1)
		{
			float spawnloc[3];
			GetEntPropVector(iRoom , Prop_Send, "m_vecOrigin", spawnloc);
			if (GetVectorDistance(projloc, spawnloc) < 500.0)
			{
				int iClient = GetEntPropEnt(iTrap, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(iClient))
				{
					g_iClientDroppedKit[iClient]--;
					if (g_iClientDroppedKit[iClient] < 0) g_iClientDroppedKit[iClient] = 0;
					PrintToChat(iClient, "Do not spawn traps near spawnrooms");
				}
				AcceptEntityInput(iTrap, "Kill");
				break;
			}
		}
	}
	return Plugin_Continue;
}
public Action CheckForIntelPos()
{
	int iTrap = -1;
	while ((iTrap = FindEntityByClassname(iTrap, "item_healthkit_medium")) != -1)
	{
		float projloc[3];
		GetEntPropVector(iTrap, Prop_Send, "m_vecOrigin", projloc);

		int iFlag = -1;
		while ((iFlag  = FindEntityByClassname(iFlag, "item_teamflag")) != -1)
		{
			float spawnloc[3];
			GetEntPropVector(iFlag , Prop_Send, "m_vecOrigin", spawnloc);
			if (GetVectorDistance(projloc, spawnloc) < 500.0)
			{
				int iClient = GetEntPropEnt(iTrap, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(iClient))
				{
					g_iClientDroppedKit[iClient]--;
					if (g_iClientDroppedKit[iClient] < 0) g_iClientDroppedKit[iClient] = 0;
					PrintToChat(iClient, "Do not spawn traps near Intel");
				}
				AcceptEntityInput(iTrap, "Kill");
				break;
			}
		}
	}
	return Plugin_Continue;
}
public Action CheckForCPPos()
{
	int iTrap = -1;
	while ((iTrap = FindEntityByClassname(iTrap, "item_healthkit_medium")) != -1)
	{
		float projloc[3];
		GetEntPropVector(iTrap, Prop_Send, "m_vecOrigin", projloc);

		int iCP = -1;
		while ((iCP  = FindEntityByClassname(iCP, "team_control_point")) != -1)
		{
			float spawnloc[3];
			GetEntPropVector(iCP , Prop_Send, "m_vecOrigin", spawnloc);
			if (GetVectorDistance(projloc, spawnloc) < 500.0)
			{
				int iClient = GetEntPropEnt(iTrap, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(iClient))
				{
					g_iClientDroppedKit[iClient]--;
					if (g_iClientDroppedKit[iClient] < 0) g_iClientDroppedKit[iClient] = 0;
					PrintToChat(iClient, "Do not spawn traps near Control Points");
				}
				AcceptEntityInput(iTrap, "Kill");
				break;
			}
		}
	}
	return Plugin_Continue;
}
public Action CheckForPLPos()
{
	int iTrap = -1;
	while ((iTrap = FindEntityByClassname(iTrap, "item_healthkit_medium")) != -1)
	{
		float projloc[3];
		GetEntPropVector(iTrap, Prop_Send, "m_vecOrigin", projloc);

		int watcherEnt = FindEntityByClassname(-1, "team_train_watcher");
		if (IsValidEntity(watcherEnt)) // Depending on where this is you could just do "if (!IsValidEntity(watcherEnt)) return;"...I prefer not to indent an entire block
		{
			char trainName[64];
			GetEntPropString(watcherEnt, Prop_Data, "m_iszTrain", trainName, sizeof(trainName));
			int i = MaxClients+1, trainEnt;
			while ((i = FindEntityByClassname(i, "*")) != -1)
			{
				char iName[64];
				GetEntPropString(i, Prop_Data, "m_iName", iName, sizeof(iName));
				if (!StrEqual(iName, trainName)) continue; // Next one
				trainEnt = i;
				break; // Stahp this whole loop, we found it.
			}
			if (trainEnt) // not zero, so we found it.
			{
				float spawnloc[3];
				GetEntPropVector(i , Prop_Send, "m_vecOrigin", spawnloc);
				if (GetVectorDistance(projloc, spawnloc) < 400.0)
				{
					int iClient = GetEntPropEnt(iTrap, Prop_Send, "m_hOwnerEntity");
					if (IsValidClient(iClient))
					{
						g_iClientDroppedKit[iClient]--;
						if (g_iClientDroppedKit[iClient] < 0) g_iClientDroppedKit[iClient] = 0;
						PrintToChat(iClient, "Do not spawn traps near Cart");
					}
					AcceptEntityInput(iTrap, "Kill");
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}
int ChesterBig_Pos(int iEntity){
	float pos[3];
	if(IsValidEntity(iEntity)){
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", pos);
		if (MoveUp[iEntity]){
			pos[2] = pos[2] + float(MoveUpFloat[iEntity]);
		}
		if (!MoveUp[iEntity]){
			pos[2] = pos[2] - float(MoveUpFloat[iEntity]);
		}
		TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	}
}
public Action Timer_RemoveTarget(Handle timer, any iEntity) {
	if(IsValidEntity(iEntity)){
		MoveUp[iEntity] = false;
		MoveUp[iEntity] = false;
	}
}
public Action OnTouchChester(int iEnt, int client){
	char classname[64];
	GetEdictClassname(iEnt, classname, sizeof(classname));
	int owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	if (StrEqual(classname, "prop_dynamic")) {
		if(client <0 || client > MAXPLAYERS)return Plugin_Changed;
		if(IsValidClient(client) && (GetClientTeam(client) != GetClientTeam(owner))){
			FakeClientCommand(client,"explode");
		}
	}
	return Plugin_Continue;
}
public bool GetClientGroundPosition(int iClient, float fGround[3]){
	float fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	
	float fAngles[3] = {90.0, 0.0, 0.0};
	TR_TraceRayFilter(fOrigin, fAngles, MASK_SOLID, RayType_Infinite, TraceRay_DontHitSelf, iClient);
	if(TR_DidHit()){
		TR_GetEndPosition(fGround);
		return true;
	}	
	return false;
}

public bool TraceRay_DontHitSelf (int iTarget, int iMask, int iClient) { return (iTarget != iClient); }
public bool TraceFilterSelf(int entity, int contentsMask, any iPumpking)
{
	if(entity == iPumpking || entity > MaxClients || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
stock int ChesterParticle(int iEntity, char effect[128], float time)
{
	
	int strIParticle = CreateEntityByName("info_particle_system");
	char strName[128];
	if (IsValidEdict(strIParticle))
	{
		float strflPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", strflPos);
		strflPos[2] = strflPos[2] + 80.0;
		TeleportEntity(strIParticle, strflPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", strName);
		
		DispatchKeyValue(strIParticle, "targetname", "tf2particle");
		DispatchKeyValue(strIParticle, "parentname", strName);
		DispatchKeyValue(strIParticle, "effect_name", effect);
		DispatchSpawn(strIParticle);
		char addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", 5.0);
		SetVariantString(addoutput);
		AcceptEntityInput(strIParticle, "AddOutput");
		AcceptEntityInput(strIParticle, "FireUser1"); 
		SetVariantString(strName);
		//AcceptEntityInput(strIParticle, "SetParent", strIParticle, strIParticle, 0);
		ActivateEntity(strIParticle);
		AcceptEntityInput(strIParticle, "start");
	}
}
