#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//#pragma semicolon 1;
#define MAX_BUTTONS 26
#define VERSION "1.0"
public Plugin:myinfo = 
{
	name = "Projectile Spycam",
	author = "GovTonyBaretta",
	description = "",
	version = "VERSION",
	url = ""
};
#define IN_ATTACK      (1 << 0)
#define IN_JUMP   (1 << 1)
#define IN_DUCK   (1 << 2)
#define IN_FORWARD    (1 << 3)
#define IN_BACK   (1 << 4)
#define IN_USE      (1 << 5)
#define IN_CANCEL      (1 << 6)
#define IN_LEFT   (1 << 7)
#define IN_RIGHT        (1 << 8)
#define IN_MOVELEFT  (1 << 9)
#define IN_MOVERIGHT        (1 << 10)
#define IN_ATTACK2    (1 << 11)
#define IN_RUN      (1 << 12)
#define IN_RELOAD      (1 << 13)
#define IN_ALT1   (1 << 14)
#define IN_ALT2   (1 << 15)
#define IN_SCORE        (1 << 16)       // Used by client.dll for when scoreboard is held down
#define IN_SPEED        (1 << 17)   // Player is holding the speed key
#define IN_WALK   (1 << 18)    // Player holding walk key
#define IN_ZOOM   (1 << 19)    // Zoom key for HUD zoom
#define IN_WEAPON1    (1 << 20) // weapon defines these bits
#define IN_WEAPON2    (1 << 21) // weapon defines these bits
#define IN_BULLRUSH  (1 << 22)
#define IN_GRENADE1  (1 << 23)    // grenade 1
#define IN_GRENADE2  (1 << 24)    // grenade 2 
//#define Camera_mdl "models/props_spytech/security_camera.mdl"
bool ClientCanUse[MAXPLAYERS+1] = false;
bool FPView[MAXPLAYERS+1] = false;
ConVar CvarFlyView;
ConVar CvarEnable;
ConVar CvarHideCam;
ConVar CvarProjType;
ConVar CvarProjOwner;
ConVar CvarCaneraModel;
float ClientAngles[MAXPLAYERS+1][3];
float ClientOrigins[MAXPLAYERS+1][3];

float SpycamPos[MAXPLAYERS+1][3];

int iFakeEnt;
int g_iPlayerLastButtons[MAXPLAYERS + 1];
public void OnMapStart() {
	char ModelCamera[512];
	GetConVarString(CvarCaneraModel, ModelCamera, sizeof(ModelCamera));
	PrecacheModel(ModelCamera, true);
}
public OnPluginStart()
{
	CreateConVar("spycam_version", VERSION, "spycam version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CvarEnable = CreateConVar("spycam_enable", "1", "spycam_enable?", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarFlyView = CreateConVar("flyview_enabled", "1", "Enable Fly View", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarHideCam = CreateConVar("hide_cam", "1", "hide cam model", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarProjType = CreateConVar("proj_type", "tf_projectile_stun_ball", "projectile type", FCVAR_NONE);
	CvarProjOwner = CreateConVar("detect_owner", "0", "0 to m_hOwnerEntity, 1 to m_hThrower", FCVAR_NONE, true, 0.0, true, 1.0);
	CvarCaneraModel = CreateConVar("cam_model", "models/props_spytech/security_camera.mdl", "camera model ", FCVAR_NONE);
	RegConsoleCmd("sm_fw", cmd_flyview,"use fly view");
	RegConsoleCmd("sm_camhelp", cmd_camhelp,"help");
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	AutoExecConfig(true, "proj_camera_cfg");
}
	
public Action cmd_flyview(int client, int args)
{
	if(CvarFlyView.BoolValue && CvarEnable.BoolValue){
		if (!FPView[client])
		{
			FPView[client] = true;
			PrintToChat(client, "\x04 [Spycam]\x01 Fly view camera On");
		}
		else{
			FPView[client] = false;
			PrintToChat(client, "\x04 [Spycam]\x01 Fly view camera Off");
		}
	}
}
public Action cmd_camhelp(int client, int args)
{
	if(CvarEnable.BoolValue){
		ShowHelpMenu(client);
	}
}
public ShowHelpMenu(client)
{
	new Handle:menu = CreateMenu(MenuHelp);
	SetMenuTitle(menu, "SpyCam Help");
	AddMenuItem(menu, "", "COMMANDS");
	AddMenuItem(menu, "", "!fw , enable first person view on baseball(1 time only)");
	AddMenuItem(menu, "", "!camhelp , enable this menu");
	AddMenuItem(menu, "", "INSTRUCTIONS");
	AddMenuItem(menu, "", "After beating the ball, holding RELOAD will enable the spycam ,releasing the button return to the player ");		
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,20);
}
public MenuHelp(Handle:menu,MenuAction:action,param1,param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(CvarEnable.BoolValue){
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		BackTolayer(client);
	}
}
public OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(CvarEnable.BoolValue){
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		BackTolayer(client);
	}
}
public SavePlayerPos(int client)
{
	GetClientEyeAngles(client, ClientAngles[client]);
	GetClientAbsOrigin(client, ClientOrigins[client]);
}
public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
	if(CvarEnable.BoolValue){
		for (int i = 0; i < MAX_BUTTONS; i++)
		{
			int button = (1 << i);

			if ((buttons & button))
			{
				if (!(g_iPlayerLastButtons[iClient] & button))
				{
					ClientOnButtonPress(iClient, button);
				}
			}
			else if ((g_iPlayerLastButtons[iClient] & button))
			{
				ClientOnButtonRelease(iClient, button);
			}
		}
		g_iPlayerLastButtons[iClient] = buttons;
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void ClientOnButtonPress(int iClient,int button)
{
	if (button == IN_RELOAD)
	{
		if(!ClientCanUse[iClient])
		CreateTimer(0.1, saveposAction, iClient);
	}
}
public void ClientOnButtonRelease(int iClient,int button)
{
	if (button == IN_RELOAD)
	{
		if(ClientCanUse[iClient])
		BackTolayer(iClient);
	}

}
int OwnerCheck(int iEntity){
	int iOwner;
	if(!CvarProjOwner.BoolValue){
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	}
	if(CvarProjOwner.BoolValue){
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
	}
	return iOwner;
}
public void OnGameFrame()
{
	if(CvarEnable.BoolValue){
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && ClientCanUse[i])
			{	int owner = OwnerCheck(iFakeEnt);
				if(owner == i){
					GetClientEyeAngles(i, ClientAngles[i]);
					ClientAngles[i][2] = 0.0;
					TeleportEntity(iFakeEnt, NULL_VECTOR, ClientAngles[i], NULL_VECTOR);
				}
			}
		}
	}
}
public int SaveCamPos(int client)
{
	int ent = -1;
	char buffer[512];
	GetConVarString(CvarProjType, buffer, sizeof(buffer));
	while ((ent = FindEntityByClassname(ent, buffer)) != -1){
		int owner = OwnerCheck(ent);
		SetEntPropString(ent, Prop_Data, "m_iName", "spycam_ball");
		if(owner == client && !ClientCanUse[client]){
			FPView[client] = false;
			ClientCanUse[client] = true;
			float position[3];
			GetEntityAbsOrigin(ent, position);
			SpycamPos[client] = position;
			iFakeEnt = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(iFakeEnt)){
				char ModelCamera[512];
				GetConVarString(CvarCaneraModel, ModelCamera, sizeof(ModelCamera));
				DispatchKeyValue(iFakeEnt, "model", ModelCamera);
				DispatchKeyValue(iFakeEnt,"skin", "0");
				DispatchKeyValue(iFakeEnt, "targetname", "spycam");
				SetEntPropEnt(iFakeEnt, Prop_Send, "m_hOwnerEntity", client);
				DispatchSpawn(iFakeEnt);
				SpycamPos[client][2] +=50.0;
				TeleportEntity(iFakeEnt, SpycamPos[client], ClientAngles[client], NULL_VECTOR);
				SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
				if(CvarHideCam.BoolValue){
					SetEntityRenderColor(iFakeEnt, 255, 255, 255, 0);
				}
				SetClientViewEntity(client, iFakeEnt);
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			}
		}
	}
}

public int BackTolayer(int client)
{
	if(ClientCanUse[client])
	{
		if(IsValidClient(client))
		{
			SetClientViewEntity(client, client);
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		}
		ClientCanUse[client] = false;
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1){
			int owner = OwnerCheck(entity);
			char strName[50];
			GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam") == 0 && owner == client)
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		int entity2 = -1;
		char buffer[512];
		GetConVarString(CvarProjType, buffer, sizeof(buffer));
		while ((entity2 = FindEntityByClassname(entity2, buffer)) != -1){
			int owner = OwnerCheck(entity2);
			char strName[50];
			GetEntPropString(entity2, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam_ball") == 0 && owner == client)
			{
				AcceptEntityInput(entity2, "Kill");
			}
		}
	}
}


public void OnClientDisconnect(int client)
{
	if(CvarEnable.BoolValue){
		BackTolayer(client);
	}
}


public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if(CvarEnable.BoolValue){
		char buffer[512];
		GetConVarString(CvarProjType, buffer, sizeof(buffer));
		if(StrEqual(classname, buffer)) SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public int OnEntitySpawned(int iGrenade)
{
	int client = OwnerCheck(iGrenade);
	SetEntPropString(iGrenade, Prop_Data, "m_iName", "spycam_ball");
	SavePlayerPos(client);
	if(FPView[client]){
		SetClientViewEntity(client, iGrenade);
	}
	CreateTimer(6.0, KillBall, client);
	//CreateTimer(4.6, BackTolayerAction, client);
}
public Action KillBall(Handle timer, any client)
{
	int entity2 = -1;
	char buffer[512];
	GetConVarString(CvarProjType, buffer, sizeof(buffer));
	while ((entity2 = FindEntityByClassname(entity2, buffer)) != -1){
		int owner = OwnerCheck(entity2);
		if(owner == client){
			char strName[50];
			GetEntPropString(entity2, Prop_Data, "m_iName", strName, sizeof(strName));

			if(strcmp(strName, "spycam_ball") == 0 && owner == client)
			{
				AcceptEntityInput(entity2, "Kill");
			}
		}
	}
}
public Action saveposAction(Handle timer, any client)
{
	SaveCamPos(client);
}

public Action BackTolayerAction(Handle timer, any client)
{
	BackTolayer(client);
}

GetEntityAbsOrigin(int entity,float origin[3]) {
    float mins[3]; float maxs[3];

    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
    GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
    GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);

    origin[0] += (mins[0] + maxs[0]) * 0.5;
    origin[1] += (mins[1] + maxs[1]) * 0.5;
    origin[2] += (mins[2] + maxs[2]) * 0.5;
}
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}