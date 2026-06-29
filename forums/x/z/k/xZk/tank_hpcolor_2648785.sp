#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required


#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define IS_SURVIVOR_DEAD(%1) (IS_VALID_SURVIVOR(%1) && !IsPlayerAlive(%1))
#define IS_INFECTED_DEAD(%1) (IS_VALID_INFECTED(%1) && !IsPlayerAlive(%1))

#define RGB_MAX 255
#define R 0
#define G 1
#define B 2
#define A 3

int ColorReset[MAXPLAYERS + 1][4]; 
int ColorDamage[MAXPLAYERS + 1][4];
Handle Delay[MAXPLAYERS + 1];

ConVar	cvar_hpcolor_on;
ConVar	cvar_hpcolor_reset;
ConVar	cvar_hpcolor_reset_delay;
ConVar cvar_hpcolor_full;
ConVar cvar_hpcolor_half;
ConVar cvar_hpcolor_critic;

bool hpcolor_on;
int hpcolor_reset;
float hpcolor_reset_delay;
int hpcolor_full[3];
int hpcolor_half[3];
int hpcolor_critic[3];


public Plugin myinfo =
{
	name = "Tank HP Color",
	author = "xZk",
	description = "change color Tank depending on your health percentage",
	version = "1.2.0",
	url = ""
};

public void OnPluginStart()
{
	cvar_hpcolor_on          = CreateConVar("tank_hpcolor_on", "1", "0: Disable, 1: Enable plugin", FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_hpcolor_reset       = CreateConVar("tank_hpcolor_reset", "1", "0: Disable restore color, 1: Activated for each delay interval, 2: Reset the delay for each damage", FCVAR_NONE);
	cvar_hpcolor_reset_delay = CreateConVar("tank_hpcolor_reset_delay", "0.5", "Set time in seconds to restore its color if it does not suffer damage", FCVAR_NONE, true, 0.1);
	cvar_hpcolor_full        = CreateConVar("tank_hpcolor_full", "255,255,255", "Set color full hp");
	cvar_hpcolor_half        = CreateConVar("tank_hpcolor_half", "255,255,0", "Set color half hp");
	cvar_hpcolor_critic      = CreateConVar("tank_hpcolor_critic", "255,0,0", "Set color critic hp");
	AutoExecConfig(true,"tank_hpcolor");
	
	HookConVarChange(cvar_hpcolor_on,CvarsChanged);
	HookConVarChange(cvar_hpcolor_reset,CvarsChanged);
	HookConVarChange(cvar_hpcolor_reset_delay,CvarsChanged);
	HookConVarChange(cvar_hpcolor_full,CvarsChanged);
	HookConVarChange(cvar_hpcolor_half,CvarsChanged);
	HookConVarChange(cvar_hpcolor_critic,CvarsChanged);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvar_hpcolor_on){
		hpcolor_on=cvar_hpcolor_on.BoolValue;
	}else if(convar==cvar_hpcolor_reset){
		hpcolor_reset=cvar_hpcolor_reset.IntValue;
	}else if(convar==cvar_hpcolor_reset_delay){
		hpcolor_reset_delay=cvar_hpcolor_reset_delay.FloatValue;
	}else if(convar==cvar_hpcolor_full){
		hpcolor_full = StringRGBToIntRGB(newValue);
	}else if(convar==cvar_hpcolor_half){
		hpcolor_half = StringRGBToIntRGB(newValue);
	}else if(convar==cvar_hpcolor_critic){
		hpcolor_critic = StringRGBToIntRGB(newValue);
	}
	
}

public void OnMapStart(){
	hpcolor_on=cvar_hpcolor_on.BoolValue;
	hpcolor_reset=cvar_hpcolor_reset.IntValue;
	hpcolor_reset_delay=cvar_hpcolor_reset_delay.FloatValue;
	char full[16],half[16],critic[16];
	cvar_hpcolor_full.GetString(full,sizeof(full));
	hpcolor_full = StringRGBToIntRGB(full);
	cvar_hpcolor_half.GetString(half,sizeof(half));
	hpcolor_half = StringRGBToIntRGB(half);
	cvar_hpcolor_critic.GetString(critic,sizeof(critic));
	hpcolor_critic = StringRGBToIntRGB(critic);
	
}

public void OnClientConnected(int client)
{
	ClearTimer(client);
	ClearColors(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!hpcolor_on)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IS_VALID_INFECTED(client) ){
		ClearTimer(client);
		ClearColors(client);
	}	
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{	
	if(!hpcolor_on)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!IS_VALID_INFECTED(client))
		return;
	
	if(IS_INFECTED_ALIVE(client) && IsTank(client) )
	{		
		if(IsDying(client))
			return;
		
		if(hpcolor_reset){
			CheckColorReset(client);
			if(hpcolor_reset == 2)
				ClearTimer(client);
			if(Delay[client]==INVALID_HANDLE)
				Delay[client] = CreateTimer(hpcolor_reset_delay, ResetColor, client);
		}
		GetMaxHeal(client);	
		SetHealColor(client);
	}	
}

public Action ResetColor(Handle timer, any client)
{
	Delay[client] = INVALID_HANDLE;
	if(IS_INFECTED_ALIVE(client))
		SetEntityRenderColor(client,ColorReset[client][R],ColorReset[client][G],ColorReset[client][B],ColorReset[client][A]);
}

void GetMaxHeal(int client){
	int hpmax = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	int hp=GetClientHealth(client);			
	if(hp > 0 && hp > hpmax){
		SetEntProp(client, Prop_Data, "m_iMaxHealth",hp);
	}
}

int[] GetColorHP(float percent){
	
	int color_hp[4];
	//color_hp=hpcolor_full;
	if(percent > 50){
		color_hp = GetGradientColorRGB(hpcolor_full, hpcolor_half, 50.0, (percent -50.0));
	}else{
		color_hp = GetGradientColorRGB(hpcolor_half, hpcolor_critic, 50.0, percent);
	}
	// PrintToChatAll("hpp : %f",percent);
	// PrintToChatAll("rgb%: %d ,%d ,%d ",color_hp[0],color_hp[1],color_hp[2]);
	return color_hp;
	
}

stock int[] GetGradientColorRGB(int color_start[3], int color_end[3], float step_max, float step){
	
	int color_rgb[3],rgb_lower[3];
	float rgb_factor[3],rgb_percent[3];
	
	for(int i=0; i<3; i++){
		rgb_factor[i]  = float(color_start[i] - color_end[i]) / step_max;
		rgb_percent[i] = rgb_factor[i] > 0 ? step : step_max - step;
		rgb_lower[i]   = color_start[i] > color_end[i] ? color_end[i] : color_start[i];
		color_rgb[i]   = RoundFloat( FloatAbs(rgb_factor[i]) * rgb_percent[i] ) + rgb_lower[i];
	}
	return color_rgb;
}

void SetHealColor(int client)
{	
	int hp=GetClientHealth(client);
	int hpmax=GetEntProp(client, Prop_Data, "m_iMaxHealth");
	float hpp=(float(hp) / float(hpmax))*100.0;
	if(IsDying(client))
	{
		return;
	}
	//PrintToChatAll("HP: %d",hp);
	if(hpp>=0.0 && hpp <=100.0){
		ColorDamage[client]=GetColorHP(hpp);
		//SetEntityRenderMode(client,RENDER_TRANSCOLOR);
		SetEntityRenderColor(client,ColorDamage[client][R],ColorDamage[client][G],ColorDamage[client][B],ColorDamage[client][A]);
	}
}

void CheckColorReset(int client){
	int color_check[4];
	GetEntityRenderColor(client,color_check[R],color_check[G],color_check[B],color_check[A]);
	//PrintToChatAll("rgba%: %d ,%d ,%d, %d ",color_check[0],color_check[1],color_check[2],color_check[3]);
	for(int i;i<sizeof(color_check);i++){
		if(color_check[i]!=ColorDamage[client][i]){
			ColorReset[client]=color_check;
			return;
		}
	}
}

stock bool IsTank(int client)
{
	if(IS_VALID_INFECTED(client) )
	{
		char classname[32];
		GetEntityNetClass(client, classname, sizeof(classname));
		if(StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

stock bool IsDying(int client) {
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated")==1)
		return true;
	return false;
}

stock int[] StringRGBToIntRGB(const char[] str_rgb) {
	int colorRGB[3];
	char str_color[16][3];
	char color_string[16];
	strcopy(color_string,sizeof(color_string),str_rgb);
	TrimString(color_string);
	ExplodeString(color_string, ",", str_color, sizeof(str_color), 16);
	colorRGB[0] = StringToInt(str_color[0]);
	colorRGB[1] = StringToInt(str_color[1]);
	colorRGB[2] = StringToInt(str_color[2]);
	
	return colorRGB;
}

stock void ClearTimer(int client)
{
	if (Delay[client] != INVALID_HANDLE)
	{
		KillTimer(Delay[client]);
	}
	Delay[client] = INVALID_HANDLE;
}

stock void ClearColors(int client){
	ColorDamage[client]={-1,-1,-1,-1};
	ColorReset[client]={-1,-1,-1,-1};
} 
