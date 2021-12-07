#include <sourcemod>
#include <sdktools>
#include <events>
#include <clients> 
#define PLUGIN_VERSION "1.9"
#define DONATOR ADMFLAG_CUSTOM1
#define ad "You can make a Repair Node by typing !nodeon. It will take effect on the next one you build. Type !nodeinfo for details."
#define info "Repair Nodes heal your buildings. They do not heal anyone else's buildings, or players."

new particleSG[MAXPLAYERS+1] = 0
new particleSG2[MAXPLAYERS+1] = 0
new particleTI[MAXPLAYERS+1] = 0
new particleTI2[MAXPLAYERS+1] = 0
new particleTO[MAXPLAYERS+1] = 0
new particleTO2[MAXPLAYERS+1] = 0
new attachDispenserSG[MAXPLAYERS+1] = 0
new attachDispenserTI[MAXPLAYERS+1] = 0
new attachDispenserTO[MAXPLAYERS+1] = 0
new T1[MAXPLAYERS+1] = 0
new T2[MAXPLAYERS+1] = 0
new RepairNodes[MAXPLAYERS+1] = 0
new SGs[MAXPLAYERS+1] = 0
new bool:enabled[MAXPLAYERS+1] = false
new bool:donatorRequired
new Float:adtime = 120.0
new Handle:adTimer = INVALID_HANDLE
new Handle:adCvar = INVALID_HANDLE
new Handle:cvar_donator = INVALID_HANDLE
new Handle:Damage_cvar_level1 = INVALID_HANDLE
new Handle:Damage_cvar_level2 = INVALID_HANDLE
new Handle:Damage_cvar_level3 = INVALID_HANDLE
new Handle:cvar_enabled = INVALID_HANDLE
new Handle:cvar_force = INVALID_HANDLE
new enabledAll = true
new force = false

// Plugin definitions
public Plugin:myinfo =
{
	name = "Repair node",
	author = "Geel9 and Benjamuffin",
	description = "Allows players to build repair nodes.",
	version = PLUGIN_VERSION,
	url = "http://www.google.com"
}
AttachParticleTO(client, ent, String:particleType[],controlpoint)
{
	//This is used to attach a particle that has two control points
	//such as the medic gun beam. One originates from the medic
	//and the other to its healer
	
	//This particle is attached to the source player
	//This will be visible
	particleTO[client]  = CreateEntityByName("info_particle_system");
	
	//This particle is attached to the destination player
	//This will not be visibile, we only need it so the source particle
	//is attached in the apropriate place
	particleTO2[client] = CreateEntityByName("info_particle_system");
	
	attachDispenserTO[client] = CreateEntityByName("prop_dynamic")
	
	
	if (IsValidEdict(particleTO[client]))
	{    
		//Name the originating source, usually the player
		new String:tName[128];
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		//Name the destination, usually another player
		new String:cpName[128];
		new Float:cpOrigin[3]
		Format(cpName, sizeof(cpName), "targetTO%i", controlpoint);
		DispatchKeyValue(controlpoint, "targetname", cpName);
		GetEntPropVector(controlpoint, Prop_Send, "m_vecOrigin", cpOrigin)
		
		//Name the dispenser.
		new String:dName[128];
		Format(dName, sizeof(dName), "dispenser%i", client)
		DispatchKeyValue(attachDispenserTO[client], "targetname", dName);
		DispatchKeyValueVector(attachDispenserTO[client], "origin", cpOrigin)
		DispatchKeyValue(attachDispenserTO[client], "parentname", cpName)
		DispatchKeyValue(attachDispenserTO[client], "rendermode", "10")
		DispatchKeyValue(attachDispenserTO[client], "model", "models/buildables/dispenser.mdl")
		DispatchSpawn(attachDispenserTO[client])
		SetVariantString(cpName);
		AcceptEntityInput(attachDispenserTO[client], "SetParent");
		
		//Name the particle (this particle is attached to the source player)
		new String:particleName[128];
		Format(particleName, sizeof(particleName), "tf2particle%i", particleTO[client]);
		DispatchKeyValue(particleTO[client], "targetname", particleName);
		
		//Tell it what effect name it is then spawn it so we can use it
		DispatchKeyValue(particleTO[client], "effect_name", particleType);
		DispatchSpawn(particleTO[client]);
		
		//--------------------------------------
		new String:cp2Name[128];
		
		//Give the destination particle a unique anme
		Format(cp2Name, sizeof(cp2Name), "tf2particle%i", particleTO2[client]);
		
		DispatchKeyValue(particleTO2[client], "targetname", cp2Name);
		DispatchKeyValueVector(particleTO2[client], "origin", cpOrigin)
		
		//Attach the destination particle to the destined player
		DispatchKeyValue(particleTO2[client], "parentname", dName);
		
		SetVariantString(dName);
		AcceptEntityInput(particleTO2[client], "SetParent");
		SetVariantString("build_point_0");
		AcceptEntityInput(particleTO2[client], "SetParentAttachment");
		
		//-----------------------------------------------
		
		//Here's where we "join" the two particles
		//Parent the source particle to the source player
		DispatchKeyValue(particleTO[client], "parentname", tName);
		SetVariantString(tName);
		AcceptEntityInput(particleTO[client], "SetParent");
		
		//Join the source particle to the destination particle
		DispatchKeyValue(particleTO[client], "cpoint1", cp2Name);
		
		//Attach the source particle to the "flag" (stomach area)
		SetVariantString("build_point_0");
		AcceptEntityInput(particleTO[client], "SetParentAttachment");
		
		ActivateEntity(particleTO[client]);
		AcceptEntityInput(particleTO[client], "start");
		//PrintToChat
	}
}  


AttachParticleTI(client, ent, String:particleType[],controlpoint)
{
	//This is used to attach a particle that has two control points
	//such as the medic gun beam. One originates from the medic
	//and the other to its healer
	
	//This particle is attached to the source player
	//This will be visible
	particleTI[client]  = CreateEntityByName("info_particle_system");
	
	//This particle is attached to the destination player
	//This will not be visibile, we only need it so the source particle
	//is attached in the apropriate place
	particleTI2[client] = CreateEntityByName("info_particle_system");
	
	attachDispenserTI[client] = CreateEntityByName("prop_dynamic")
	
	
	if (IsValidEdict(particleTI[client]))
	{    
		//Name the originating source, usually the player
		new String:tName[128];
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		//Name the destination, usually another player
		new String:cpName[128];
		new Float:cpOrigin[3]
		Format(cpName, sizeof(cpName), "target%i", controlpoint);
		DispatchKeyValue(controlpoint, "targetname", cpName);
		GetEntPropVector(controlpoint, Prop_Send, "m_vecOrigin", cpOrigin)
		
		//Name the dispenser.
		new String:dName[128];
		Format(dName, sizeof(dName), "dispenser%i", client)
		DispatchKeyValue(attachDispenserTI[client], "targetname", dName);
		DispatchKeyValueVector(attachDispenserTI[client], "origin", cpOrigin)
		DispatchKeyValue(attachDispenserTI[client], "parentname", cpName)
		DispatchKeyValue(attachDispenserTI[client], "rendermode", "10")
		DispatchKeyValue(attachDispenserTI[client], "model", "models/buildables/dispenser.mdl")
		DispatchSpawn(attachDispenserTI[client])
		SetVariantString(cpName);
		AcceptEntityInput(attachDispenserTI[client], "SetParent");
		
		//Name the particle (this particle is attached to the source player)
		new String:particleName[128];
		Format(particleName, sizeof(particleName), "tf2particle%i", particleTI[client]);
		DispatchKeyValue(particleTI[client], "targetname", particleName);
		
		//Tell it what effect name it is then spawn it so we can use it
		DispatchKeyValue(particleTI[client], "effect_name", particleType);
		DispatchSpawn(particleTI[client]);
		
		//--------------------------------------
		new String:cp2Name[128];
		
		//Give the destination particle a unique anme
		Format(cp2Name, sizeof(cp2Name), "tf2particle%i", particleTI2[client]);
		
		DispatchKeyValue(particleTI2[client], "targetname", cp2Name);
		DispatchKeyValueVector(particleTI2[client], "origin", cpOrigin)
		
		//Attach the destination particle to the destined player
		DispatchKeyValue(particleTI2[client], "parentname", dName);
		
		SetVariantString(dName);
		AcceptEntityInput(particleTI2[client], "SetParent");
		SetVariantString("build_point_0");
		AcceptEntityInput(particleTI2[client], "SetParentAttachment");
		
		//-----------------------------------------------
		
		//Here's where we "join" the two particles
		//Parent the source particle to the source player
		DispatchKeyValue(particleTI[client], "parentname", tName);
		SetVariantString(tName);
		AcceptEntityInput(particleTI[client], "SetParent");
		
		//Join the source particle to the destination particle
		DispatchKeyValue(particleTI[client], "cpoint1", cp2Name);
		
		//Attach the source particle to the "flag" (stomach area)
		SetVariantString("build_point_0");
		AcceptEntityInput(particleTI[client], "SetParentAttachment");
		
		ActivateEntity(particleTI[client]);
		AcceptEntityInput(particleTI[client], "start");
	}
}  
AttachParticleSG(client, ent, String:particleType[],controlpoint)
{
	//This is used to attach a particle that has two control points
	//such as the medic gun beam. One originates from the medic
	//and the other to its healer
	
	//This particle is attached to the source player
	//This will be visible
	particleSG[client]  = CreateEntityByName("info_particle_system");
	
	//This particle is attached to the destination player
	//This will not be visibile, we only need it so the source particle
	//is attached in the apropriate place
	particleSG2[client] = CreateEntityByName("info_particle_system");
	
	attachDispenserSG[client] = CreateEntityByName("prop_dynamic")
	
	
	if (IsValidEdict(particleSG[client]))
	{    
		//Name the originating source, usually the player
		new String:tName[128];
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		//Name the destination, usually another player
		new String:cpName[128];
		new Float:cpOrigin[3]
		Format(cpName, sizeof(cpName), "target%i", controlpoint);
		DispatchKeyValue(controlpoint, "targetname", cpName);
		GetEntPropVector(controlpoint, Prop_Send, "m_vecOrigin", cpOrigin)
		
		//Name the dispenser.
		new String:dName[128];
		Format(dName, sizeof(dName), "dispenser%i", client)
		if(attachDispenserSG[client] == 0){
		DispatchKeyValue(attachDispenserSG[client], "targetname", dName);
		DispatchKeyValueVector(attachDispenserSG[client], "origin", cpOrigin)
		DispatchKeyValue(attachDispenserSG[client], "parentname", cpName)
		DispatchKeyValue(attachDispenserSG[client], "rendermode", "10")
		DispatchKeyValue(attachDispenserSG[client], "model", "models/buildables/dispenser.mdl")
		DispatchSpawn(attachDispenserSG[client])
		SetVariantString(cpName);
		AcceptEntityInput(attachDispenserSG[client], "SetParent");
	}
		
		//Name the particle (this particle is attached to the source player)
		new String:particleName[128];
		Format(particleName, sizeof(particleName), "tf2particle%i", particleSG[client]);
		DispatchKeyValue(particleSG[client], "targetname", particleName);
		
		//Tell it what effect name it is then spawn it so we can use it
		DispatchKeyValue(particleSG[client], "effect_name", particleType);
		DispatchSpawn(particleSG[client]);
		
		//--------------------------------------
		new String:cp2Name[128];
		
		//Give the destination particle a unique anme
		Format(cp2Name, sizeof(cp2Name), "tf2particle%i", particleSG2[client]);
		
		DispatchKeyValue(particleSG2[client], "targetname", cp2Name);
		DispatchKeyValueVector(particleSG2[client], "origin", cpOrigin)
		
		//Attach the destination particle to the destined player
		DispatchKeyValue(particleSG2[client], "parentname", dName);
		
		SetVariantString(dName);
		AcceptEntityInput(particleSG2[client], "SetParent");
		SetVariantString("build_point_0");
		AcceptEntityInput(particleSG2[client], "SetParentAttachment");
		
		//-----------------------------------------------
		
		//Here's where we "join" the two particles
		//Parent the source particle to the source player
		DispatchKeyValue(particleSG[client], "parentname", tName);
		SetVariantString(tName);
		AcceptEntityInput(particleSG[client], "SetParent");
		
		//Join the source particle to the destination particle
		DispatchKeyValue(particleSG[client], "cpoint1", cp2Name);
		
		//Attach the source particle to the "flag" (stomach area)
		SetVariantString("build_point_0");
		AcceptEntityInput(particleSG[client], "SetParentAttachment");
		
		ActivateEntity(particleSG[client]);
		AcceptEntityInput(particleSG[client], "start");
	}
}  

public OnPluginStart()
{
	HookEvent("player_builtobject", Event_player_builtobject)
	HookEvent("object_destroyed", RemoveStuff)
	HookEvent("object_removed", RemoveStuff)
	HookEvent("player_disconnect", RemovePlayer)
	CreateConVar("repair_node_version", PLUGIN_VERSION, "Version of the Repair Node plugin", FCVAR_PLUGIN)
	Damage_cvar_level1 = CreateConVar("Repair_node_regen_amount_level1", "15", "How much the Repair Node will heal a building, per 2 seconds, at level 1.", FCVAR_NOTIFY)
	Damage_cvar_level2 = CreateConVar("Repair_node_regen_amount_level2", "20", "How much the Repair Node will heal a building, per 2 seconds, at level 2.", FCVAR_NOTIFY)
	Damage_cvar_level3 = CreateConVar("Repair_node_regen_amount_level3", "30", "How much the Repair Node will heal a building, per 2 seconds, at level 3.", FCVAR_NOTIFY)
	cvar_enabled = CreateConVar("Repair_node_enabled", "1", "If 1, players can use the repair node.", FCVAR_NOTIFY)
	cvar_force = CreateConVar("Repair_node_force", "0", "Force the repair node on players?", FCVAR_NOTIFY)
	cvar_donator = CreateConVar("Repair_node_donator", "0", "If 1, requires the custom admin flag #1 to be on a client to use the node", 0, true, 0.0, true, 1.0)
	adCvar = CreateConVar("repair_node_ad_time", "120", "If non-0, info about the Repair Node will show every X seconds.", 0, true, 0.0, true, 300.0)
	adTimer = CreateTimer(120.0, Ad, _, TIMER_REPEAT)
	HookConVarChange(adCvar, hook_ad)
	HookConVarChange(cvar_donator, hook_donator)
	HookConVarChange(cvar_force, hook_force)
	HookConVarChange(cvar_enabled, hook_enabled)
	RegConsoleCmd("nodeon", Nodeon)
	RegConsoleCmd("nodeinfo", Info)
	RegConsoleCmd("nodeoff", Nodeoff)
	CreateTimer(2.0, Heal, _, TIMER_REPEAT)
	CreateTimer(4.0, models, _, TIMER_REPEAT)
	DownloadTable()
}


public hook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]){
	enabledAll = GetConVarBool(cvar_enabled)
}

public hook_force(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	force = GetConVarBool(cvar_force)
}
public hook_donator(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	donatorRequired = GetConVarBool(cvar_donator)
}
public hook_ad(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(IsValidHandle(adTimer)){
		KillTimer(adTimer)
	}
	adtime = GetConVarFloat(adCvar)
	if(adtime > 0.0){
		adTimer = CreateTimer(adtime, Ad, _, TIMER_REPEAT)
	}
}





public DownloadTable(){
	AddFileToDownloadsTable("materials/models/buildables/repair/repair_blue.vmt")
	AddFileToDownloadsTable("materials/models/buildables/repair/repair_blue.vtf")
	AddFileToDownloadsTable("materials/models/buildables/repair/repair_red.vmt")
	AddFileToDownloadsTable("materials/models/buildables/repair/repair_red.vtf")
}
public SetModel(any:client, any:object){
	new level = GetEntProp(object, Prop_Send, "m_iUpgradeLevel") 
	new String:model2[255]
	Format(model2,255,"models/buildables/repair_level%i.mdl",level)
	SetEntityModel(object, model2)
	if(GetClientTeam(client) == 2){
		SetEntProp(object, Prop_Send, "m_nSkin", 0)
	}
	else{
		SetEntProp(object, Prop_Send, "m_nSkin", 1)
	}
}




public Action:RemovePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	enabled[client] = false
	SGs[client] = 0
	T1[client] = 0
	T2[client] = 0
	RepairNodes[client] = 0
	killParticle(0, client)
	killParticle(1, client)
	killParticle(2, client)
}
public Float:CheckVec(Float:vec1[3], Float:vec2[3]){
	new Float:vec3[3]
	new Float:result
	for(new i = 0; i < 2; i++){
		if(vec1[i] > vec2[i]){
			vec3[i] = vec1[i] - vec2[i]
		}
		else{
			vec3[i] = vec2[i] - vec1[i]
		}
	}
	result = (vec3[0] + vec3[1] + vec3[2])
	return result
}


public OnMapStart()
{
	PrecacheModel("models/buildables/repair_level1.mdl", true)
	PrecacheModel("models/buildables/repair_level2.mdl", true)
	PrecacheModel("models/buildables/repair_level3.mdl", true)
}

public Action:Nodeon(client, args){
	if(!enabled[client]){
		PrintToChat(client, "This will only take effect on your NEXT dispenser!")
		enabled[client] = true
	}
}
public Action:Nodeoff(client, args){
	if(enabled[client]){
		PrintToChat(client, "This will only take effect on your NEXT dispenser!")
		enabled[client] = false
	}
}

public Void:PerformLimits(entl, String:classname[64]){
	SetEntProp(entl, Prop_Send, "m_bDisabled", 1)
	SetEntProp(entl, Prop_Send, "m_iMaxHealth", 70)
	SetEntProp(entl, Prop_Send, "m_iHealth", 70)
}
public Void:SetHealthOfEnt(any:entl, String:classname[64], any:health){
	new Maxhealth = GetEntProp(entl, Prop_Send, "m_iMaxHealth")
	new entvalue=GetEntProp(entl, Prop_Send, "m_iHealth") 
	new newhealth = entvalue + health;
	if(entvalue < 200){
		if(newhealth < Maxhealth){
			SetEntityHealth(entl, newhealth)
		}
		else{
			SetEntityHealth(entl, Maxhealth)
		}
	}
}

public Action:models(Handle:timer){
	for(new x = 1; x < MAXPLAYERS; x++){
		if(RepairNodes[x] != 0 && RepairNodes[x] != -1){
			SetModel(x, RepairNodes[x])
		}
	}
}
public Action:Info(client, args){
	PrintToChat(client, "%s", info)
}
public Action:Heal(Handle:timer){
	new healing1 = GetConVarInt(Damage_cvar_level1)
	new healing2 = GetConVarInt(Damage_cvar_level2)
	new healing3 = GetConVarInt(Damage_cvar_level3)
	new Float:bPos[3]
	new Float:bPos2[3]
	for(new x = 1; x < MAXPLAYERS; x++){
		if(RepairNodes[x] != 0 && RepairNodes[x] != -1){
			new team = GetClientTeam(x)
			new level = GetEntProp(RepairNodes[x], Prop_Send, "m_iUpgradeLevel") 
			new Float:distance
			switch(level){
				case 1:
				distance = 300.0
				case 2:
				distance = 400.0
				case 3:
				distance = 500.0
			}
			
			if(SGs[x] != 0 && SGs[x] != -1 && IsValidEntity(SGs[x])){
				GetEntPropVector(SGs[x], Prop_Send, "m_vecOrigin", bPos)
				GetEntPropVector(RepairNodes[x], Prop_Send, "m_vecOrigin", bPos2)
				new Float:dist = CheckVec(bPos, bPos2)
				if(dist < distance){
					if(particleSG[x] == 0){
						if(team == 2){
							AttachParticleSG(x, SGs[x], "medicgun_beam_red", RepairNodes[x])
						}
						else{
							AttachParticleSG(x, SGs[x], "medicgun_beam_blue", RepairNodes[x])
						}
					}
					if(level == 1){
						SetHealthOfEnt(SGs[x], "CObjectSentrygun", healing1)
					}
					else if(level == 2){
						
						SetHealthOfEnt(SGs[x], "CObjectSentrygun", healing2)
					}
					else if(level == 3){
						
						SetHealthOfEnt(SGs[x], "CObjectSentrygun", healing3)
					}
				}
			}
			if(T1[x] != 0 && T1[x] != -1 && IsValidEntity(T1[x])){
				GetEntPropVector(T1[x], Prop_Send, "m_vecOrigin", bPos)
				GetEntPropVector(RepairNodes[x], Prop_Send, "m_vecOrigin", bPos2)
				new Float:dist = CheckVec(bPos, bPos2)
				if(dist < distance){
					if(particleTI[x] == 0){
						if(team == 2){
							AttachParticleTI(x, T1[x], "medicgun_beam_red", RepairNodes[x])
						}
						else{
							AttachParticleTI(x, T1[x], "medicgun_beam_blue", RepairNodes[x])
						}
					}
					if(level == 1){
						
						SetHealthOfEnt(T1[x], "CObjectTeleporter", healing1)
					}
					else if(level == 2){
						
						SetHealthOfEnt(T1[x], "CObjectTeleporter", healing2)
					}
					else if(level == 3){
						
						SetHealthOfEnt(T1[x], "CObjectTeleporter", healing3)
					}
				}
				
			}
			
			if(T2[x] != 0 && T2[x] != -1 && IsValidEntity(T2[x])){
				
				GetEntPropVector(T2[x], Prop_Send, "m_vecOrigin", bPos)
				GetEntPropVector(RepairNodes[x], Prop_Send, "m_vecOrigin", bPos2)
				new Float:dist = CheckVec(bPos, bPos2)
				if(dist < distance){
					
					if(particleTO[x] == 0){
						if(team == 2){
							AttachParticleTO(x, T2[x], "medicgun_beam_red", RepairNodes[x])
						}
						else{
							AttachParticleTO(x, T2[x], "medicgun_beam_blue", RepairNodes[x])
						}
					}
					if(level == 1){
						
						SetHealthOfEnt(T2[x], "CObjectTeleporter", healing1)
					}
					else if(level == 2){
						
						SetHealthOfEnt(T2[x], "CObjectTeleporter", healing2)
					}
					else if(level == 3){
						
						SetHealthOfEnt(T2[x], "CObjectTeleporter", healing3)
					}
				}
				
			}
		}
	}
}

public killParticle(id, i){
	if(id == 0 && particleSG[i] != 0){ // SGs
		AcceptEntityInput(particleSG[i], "kill")
		AcceptEntityInput(particleSG2[i], "kill")
		AcceptEntityInput(attachDispenserSG[i], "kill")
		particleSG[i] = 0
		particleSG2[i] = 0
		attachDispenserSG[i] = 0
	}
	else if(id == 1 && particleTI[i] != 0){ // TI
		AcceptEntityInput(particleTI[i], "kill")
		AcceptEntityInput(particleTI2[i], "kill")
		AcceptEntityInput(attachDispenserTI[i], "kill")
		particleTI[i] = 0
		particleTI2[i] = 0
		attachDispenserTI[i] = 0
	}
	else if(id == 2 && particleTO[i] != 0){ // TO
		AcceptEntityInput(particleTO[i], "kill")
		AcceptEntityInput(particleTO2[i], "kill")
		AcceptEntityInput(attachDispenserTO[i], "kill")
		particleTO[i] = 0
		particleTO2[i] = 0
		attachDispenserTO[i] = 0
	}
}
public Action:RemoveStuff(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index = GetEventInt(event, "index")
	for(new i = 0; i < MAXPLAYERS; i++){
		if(SGs[i] == index){
			SGs[i] = 0
			killParticle(0, i)
		}
		if(T1[i] == index){
			T1[i] = 0
			killParticle(1, i)
		}
		if(T2[i] == index){
			T2[i] = 0
			killParticle(2, i)
		}
		if(RepairNodes[i] == index){
			RepairNodes[i] = 0
			killParticle(0, i)
			killParticle(1, i)
			killParticle(2, i)
		}
	}
}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new strClassName[64]
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new object = GetEventInt(event, "index")
	new flags = GetUserFlagBits(client)
	new bool:Donator
	if(flags & DONATOR)
	{
		Donator = true
	}
	if(!donatorRequired){
		Donator = true
	}
	if(particleSG[client] != 0){
		killParticle(0, client)
	}
	if(particleTI[client] != 0){
		killParticle(1, client)
	}
	if(particleTO[client] != 0){
		killParticle(2, client)
	}
	if(enabled[client] == true || force == 1 && Donator){
		if(enabledAll == 1){
			GetEntityNetClass(object, String:strClassName, 64)
			if(strcmp(String:strClassName, "CObjectDispenser", true) == 0){
				SetModel(client, object)
				new array[2]
				array[0] = object
				array[1] = client
				RepairNodes[client] = object
				PerformLimits(object, "CObjectDispenser")
			}
		}
	}
	if(strcmp(String:strClassName, "CObjectSentrygun", true) == 0){
		SGs[client] = object
	}
	if(strcmp(String:strClassName, "CObjectTeleporter", true) == 0){
		if(T1[client] == -1 || T1[client] == 0){
			T1[client] = object
			return
		}
		if(T2[client] == -1 || T2[client] == 0){
			T2[client] = object
			return
		}
	}
}
public Action:Ad(Handle:timer){
	PrintToChatAll("%s", ad)
}
