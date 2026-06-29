#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define EXPLODE_SOUND 			"weapons/hegrenade/explode3.wav"
#define EXPLODE_VOLUME			0.1
#define BULLET_SPEED			1000.0
#define MAX_DISTANCE			160.0
#define JUMP_FORCE_UP			8.0
#define JUMP_FORCE_FORW			1.20
#define JUMP_FORCE_BACK			1.25
#define JUMP_FORCE_MAIN			270.0
#define RUN_FORCE_MAIN			0.8


#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1))

int g_ExplosionSprite;
ConVar g_cvModelPath;
char ModelPath[128];

bool g_SoundOff[MAXPLAYERS + 1] = false;
bool g_bStopSound[MAXPLAYERS + 1] = false;
bool g_bHidePlayers[MAXPLAYERS + 1] = false;
bool g_bThirdPerson[MAXPLAYERS + 1] = false;

static g_iUtils_EffectDispatchTable;
static g_iUtils_DecalPrecacheTable;

public Plugin myinfo = 
{
	name = "Rocket jump beta",
	author = PLUGIN_AUTHOR,
	description = "Rocket jump beta",
	version = PLUGIN_VERSION,
	url = "http://burst.lv"
};

public void OnPluginStart()
{
	HookEvent("weapon_fire", 	RJ_WeaponFire);
	HookEvent("player_spawn", 	RJ_PlayerSpawn);
	
	LoopAllPlayers(i) {
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	
	
	RegConsoleCmd("sm_rjsettings", 	CMD_Settings, "Settings");
	RegConsoleCmd("sm_rj", 			CMD_Settings, "Settings");
	

	AddTempEntHook("EffectDispatch", 	TE_OnEffectDispatch);
	AddTempEntHook("World Decal", 		TE_OnDecal);
	AddTempEntHook("Entity Decal", 		TE_OnDecal);
	AddTempEntHook("Shotgun Shot", 		CSS_Hook_ShotgunShot);
	
	g_cvModelPath = CreateConVar("rj_model", "models/props_junk/watermelon01.mdl", "Rocket jump bullet model");
	g_cvModelPath.GetString(ModelPath, 128);
	
	if (g_cvModelPath != null)
		g_cvModelPath.AddChangeHook(OnModelChange);
	
}

public void OnModelChange(ConVar convar, char[] oldValue, char[] newValue)
{
	char NewModel[128];
	Format(NewModel, sizeof(NewModel), "%s", newValue);
	
	ModelPath = NewModel;
}

public Action CMD_Settings(int client, int args)
{
	ShowSettingMenu(client);
}

void ShowSettingMenu(int client)
{
	Menu menu = new Menu(MenuHandler_RJSettings);
	SetMenuTitle(menu, "RJ settings");
	
	if(g_SoundOff[client])
		menu.AddItem("ExplodeON", 	"Show explode [0]");
	else
		menu.AddItem("ExplodeOFF", 	"Show explode [1]");
		
		
	if(g_bHidePlayers[client])
		menu.AddItem("HidePlayersON", 		"Hide players [0]");
	else
		menu.AddItem("HidePlayersOFF", 		"Hide players [1]");
		
	
	if(g_bStopSound[client])
		menu.AddItem("DisableSounds", 		"Shooting sounds [0]");
	else
		menu.AddItem("EnableSounds", 		"Shooting sounds [1]");
	
	
	if(g_bThirdPerson[client])
		menu.AddItem("DisableThirdP", 		"Thirdperson [0]");
	else
		menu.AddItem("EnableThirdP", 		"Thirdperson [1]");
		
	menu.Display(client, 30);	
}

public int MenuHandler_RJSettings(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, sizeof(info));
			
			if(StrEqual(info, "ExplodeON"))
				g_SoundOff[client] = false;
			
			if(StrEqual(info, "ExplodeOFF"))
				g_SoundOff[client] = true;
				
				
			//
			if(StrEqual(info, "DisableSounds"))
				g_bStopSound[client] = false;
			
			if(StrEqual(info, "EnableSounds"))
				g_bStopSound[client] = true;
				
				
			if(StrEqual(info, "HidePlayersON"))
				g_bHidePlayers[client] = false;
				
			if(StrEqual(info, "HidePlayersOFF"))
				g_bHidePlayers[client] = true;
				
			if(StrEqual(info, "DisableThirdP"))
				SetPlayerThirdPerson(client, false);
				
			if(StrEqual(info, "EnableThirdP"))
				SetPlayerThirdPerson(client, true);
			
				
			ShowSettingMenu(client);
			
		}
	}
}

public Action RJ_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon <= 0 || !IsValidEdict(weapon))
		GivePlayerItem(client, "weapon_nova");
		
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnMapStart()
{
	g_ExplosionSprite = PrecacheModel( "sprites/sprite_fire01.vmt" );
	g_iUtils_EffectDispatchTable = FindStringTable("EffectDispatch");
	g_iUtils_DecalPrecacheTable  = FindStringTable("decalprecache");	
}

public void OnConfigsExecuted()
{
	
	//Precache
	PrecacheSound(EXPLODE_SOUND, true);
	PrecacheModel(ModelPath);
	
	//Cvars
	SetCvar("sv_airaccelerate", 		"1000");
	SetCvar("mp_ct_default_primary", 	"weapon_nova");
	SetCvar("mp_ct_default_secondary", 	"");
	SetCvar("mp_t_default_primary", 	"weapon_nova");
	SetCvar("mp_t_default_secondary", 	"");
	SetCvar("bot_quota", 				"0");
	SetCvar("sv_infinite_ammo", 		"1");
	SetCvar("sv_maxvelocity", 			"1500");
	SetCvar("mp_maxrounds", 			"1");
	SetCvar("sv_allow_thirdperson", 	"1");
	
	BhopOn();
	
}

public Action RJ_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	//Get client who is shooting
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Get shooting weapon
	char weapon[50];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	//If weapon is nova
	if(StrEqual(weapon, "weapon_nova"))
	{
		
		//Get ORG from where to shoot bullet
		float bulletSpawnORG[3], eyeposition[3], eyeangles[3];
		GetClientEyePosition(client, eyeposition);
		GetClientEyeAngles(client, eyeangles);
		AddInFrontOf(eyeposition, eyeangles, 10.0, bulletSpawnORG);
		
		//Get player velocity
		float clientVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVelocity);
		
		//Create velocity for bullet
		float bulletVelocity[3], bullenAngle[3];
		GetAngleVectors(eyeangles, bulletVelocity, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, bullenAngle);
		NormalizeVector(bulletVelocity, bulletVelocity);
		ScaleVector(bulletVelocity, BULLET_SPEED);
		
		//Add player velocity to bullet velocity
		AddVectors(bulletVelocity, clientVelocity, bulletVelocity);
		
		//Shoot bullet
		ShootBullet(client, bulletSpawnORG, bulletVelocity, bullenAngle);

	}

}

public void ShootBullet(int client, float bulletSpawnORG[3], float bulletVelocity[3], float bulletAngle[3])
{
	
	//Create bullet
	int bullet = CreateEntityByName("decoy_projectile");
	DispatchSpawn(bullet);
	
	//Set bullet owner
	SetEntPropEnt(bullet, Prop_Send, "m_hOwnerEntity", client);
	
	//Make bullet go thru other players
	SetEntProp(bullet, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS 
	SetEntProp(bullet, Prop_Send, "m_CollisionGroup", 1); // COLLISION_GROUP_DEBRIS  
	
	//Change bullet model
	if(!IsModelPrecached(ModelPath))
		PrecacheModel(ModelPath);
		
	SetEntityModel(bullet, ModelPath);
	
	//Give bullet gravity (dont fall down)
	SetEntityGravity(bullet, 0.001);
	
	//Shoot bullet
	TeleportEntity(bullet, bulletSpawnORG, bulletAngle, bulletVelocity);
	
	//SDK hook 
	SDKHook(bullet, SDKHook_StartTouch, OnBulletTouchWall);
	SDKHook(bullet, SDKHook_SetTransmit, Hook_BulletSetTransmit);
	
}

public void SetPlayerThirdPerson(int client, bool enable)
{

	if(enable) {
		ClientCommand(client, "thirdperson");
		g_bThirdPerson[client] = true;
	}
	else {
		ClientCommand(client, "firstperson");
		g_bThirdPerson[client] = false;
	}

}

public void OnBulletTouchWall(int bullet, int client) 
{
	//Check if bullet is valid
	if (!IsValidEntity(bullet))
		return;
		
	//Get shooter
	int shooter = GetEntPropEnt(bullet, Prop_Send, "m_hOwnerEntity");	
	
	if(IsValidClient(client) && client != shooter)
		return;
	
	//Remove SDK hook
	SDKUnhook(bullet, SDKHook_StartTouch, OnBulletTouchWall);
	SDKUnhook(bullet, SDKHook_SetTransmit, Hook_BulletSetTransmit);
	
	
	//GetClientAbsOrigin(shooter, ShooterORG);
	
	if(IsClientInGame(shooter) && IsPlayerAlive(shooter))
	{
		//Get player and bullet ORG
		float ShooterORG[3], bulletORG[3];
		GetClientEyePosition(shooter, ShooterORG);
		GetEntPropVector(bullet, Prop_Send, "m_vecOrigin", bulletORG);
		
		//Create explodition
		TE_SetupExplosion(bulletORG, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
		int AllPlayers[MAXPLAYERS + 1], count = 0;
		LoopAllPlayers(i)
		{
			if(i > 0) 
			{
				if(IsClientInGame(i)) 
				{
					if(!g_SoundOff[i]) 
					{
						AllPlayers[count] = i;
						count++;
					}	
				}
			}
		}
		
		TE_Send(AllPlayers, count);
		
		//Uncomment if you want loud explode sounds :D
		//EmitSoundToAll(EXPLODE_SOUND, bullet, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, EXPLODE_VOLUME);
			
		//Get distance between bullet and player
		float distance = GetVectorDistance(bulletORG, ShooterORG);
		
		//Kill bullet entity
		AcceptEntityInput(bullet, "kill");
		
		//Make client jump
		RJ_Jump(shooter, distance, bulletORG, ShooterORG);
		
	}
}

public void RJ_Jump(int shooter, float distance, float clientORG[3], float explodeORG[3])
{

	//Check, how far is player from bullet
	if(distance < MAX_DISTANCE)
	{
		bool down = false;
		
		//Create velocity
		float velocity[3];
		MakeVectorFromPoints(clientORG, explodeORG, velocity);
		
		if(velocity[2] < 0)
			down = true;
		
		NormalizeVector(velocity, velocity);
		
		float clientVelocity[3];
		GetEntPropVector(shooter, Prop_Data, "m_vecVelocity", clientVelocity);
		
		ScaleVector(velocity, JUMP_FORCE_MAIN);
		AddVectors(velocity, clientVelocity, velocity);
			
		clientVelocity[2] = 0.0;
		velocity[2] = 0.0;
		
		if (clientVelocity[0] < 0) {
		    if (explodeORG[0] > clientORG[0]) {
				ScaleVector(velocity, JUMP_FORCE_FORW);
				
		    } else {
				ScaleVector(velocity, JUMP_FORCE_BACK);
		    }
		} else {
		    if (explodeORG[0] < clientORG[0]) {
				ScaleVector(velocity, JUMP_FORCE_FORW);
				
		    } else {
				ScaleVector(velocity, JUMP_FORCE_BACK);
		    }
		}
		
		
		if (clientVelocity[1] < 0) {
			
		    if (explodeORG[1] > clientORG[1])
				ScaleVector(velocity, JUMP_FORCE_FORW);
		    else
				ScaleVector(velocity, JUMP_FORCE_BACK);
				
		} else {
			
		    if (explodeORG[1] < clientORG[1])
				ScaleVector(velocity, JUMP_FORCE_FORW);
		    else
				ScaleVector(velocity, JUMP_FORCE_BACK);
				
		}
		
		if((GetEntityFlags(shooter) & FL_ONGROUND))
			ScaleVector(velocity, RUN_FORCE_MAIN);


		if(distance > 37.0)
		{
			if(velocity[2] > 0.0)
				velocity[2] = 1000.0 + (JUMP_FORCE_UP * (MAX_DISTANCE - distance));
			else
				velocity[2] = velocity[2] + (JUMP_FORCE_UP * (MAX_DISTANCE - distance));	
		} else {
			
			velocity[2] = velocity[2] + (JUMP_FORCE_UP * (MAX_DISTANCE - distance)) / 1.37;	
		}
		
		if(down)
			velocity[2] *= -1;
		
		TeleportEntity(shooter, NULL_VECTOR, NULL_VECTOR, velocity);

	}

}

public Action Hook_SetTransmit(int entity, int client) 
{ 
    if (client != entity && (0 < entity <= MaxClients) && IsClientInGame(client) && g_bHidePlayers[client]) 
        return Plugin_Handled; 
 
    return Plugin_Continue; 
}  

public Action Hook_BulletSetTransmit(int entity, int client) 
{ 
	if(IsValidEntity(entity))
	{
		int shooter = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");	
		if(shooter != client && g_bHidePlayers[client])
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

//Fall damage

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	return Plugin_Handled;
}

public Action SoundHook(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &Ent, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (StrEqual(sound, "player/damage1.wav", false)) return Plugin_Stop;
    if (StrEqual(sound, "player/damage2.wav", false)) return Plugin_Stop;
    if (StrEqual(sound, "player/damage3.wav", false)) return Plugin_Stop;
    
    return Plugin_Continue;
}


//Functions , functions and more functions!!!

void AddInFrontOf(float vecOrigin[3], float vecAngle[3], float units, float output[3])
{
	float vecAngVectors[3];
	vecAngVectors = vecAngle;
	GetAngleVectors(vecAngVectors, vecAngVectors, NULL_VECTOR, NULL_VECTOR);
	for (int i; i < 3; i++)
	output[i] = vecOrigin[i] + (vecAngVectors[i] * units);
}

void SetCvar(char[] scvar, char[] svalue)
{
	Handle cvar = FindConVar(scvar);
	SetConVarString(cvar, svalue, true);
}

//Abners bhop plugin


public Action PreThink(int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0); 
	}
}

void BhopOn()
{
	SetCvar("sv_enablebunnyhopping", "1"); 
	SetCvar("sv_staminamax", "0");
	SetCvar("sv_airaccelerate", "2000");
	SetCvar("sv_staminajumpcost", "0");
	SetCvar("sv_staminalandcost", "0");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsPlayerAlive(client) && buttons & IN_JUMP) //Check if player is alive and is in pressing space
		if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND)) //Check if is not in ladder and is in air
			if(waterCheck(client) < 2)
				buttons &= ~IN_JUMP; 
	return Plugin_Continue;
}

int waterCheck(int client)
{
	return GetEntProp(client, Prop_Data, "m_nWaterLevel");
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}



public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
    int iEffectIndex = TE_ReadNum("m_iEffectName");
    char sEffectName[9];
    
    ReadStringTable(g_iUtils_EffectDispatchTable, iEffectIndex, sEffectName, sizeof(sEffectName));
    
    if(StrEqual(sEffectName, "csblood"))
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action TE_OnDecal(const char[] te_name, const Players[], int numClients, float delay)
{
    int nIndex = TE_ReadNum("m_nIndex");
    char sDecalName[13];

    ReadStringTable(g_iUtils_DecalPrecacheTable, nIndex, sDecalName, sizeof(sDecalName));
        
    if(StrEqual(sDecalName, "decals/blood"))
        return Plugin_Handled;
    
    return Plugin_Continue;
}  

public Action CSS_Hook_ShotgunShot(const char[] te_name, const Players[], int numClients, float delay)
{
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	int newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	float vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Stop;
}
