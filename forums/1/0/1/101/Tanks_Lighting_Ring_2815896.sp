#include <sdktools>

#define TIMER_CREATE_NEW_RING	 0.25
#define Hieght_Of_Ring 			 120.0
#define Red_Intensity			 GetRandomInt(0,5)*51
#define Green_Intensity			 GetRandomInt(0,5)*51
#define Blue_Intensity			 GetRandomInt(0,5)*51
#define Alpha					 255

//-------Beam Ring SetUp-----------------------
#define B_Center		P_Pos
#define B_Start_Radius	10.0
#define B_End_Radius	70.0
#define B_Model			"sprites/laserbeam.vmt"
#define B_Halo			"sprites/glow01.vmt"
#define B_Start_Frame	1
#define B_Frame_Rate	1
#define B_Life_Time		0.5
#define B_Width			5.0
#define B_Amplitude		1.0
#define B_Color(%1)		P_Color[%1]
#define B_Speed			0
#define B_Flag			0
//--------------------------------------------

int g_Sprite,g_Sprite2;
new Handle:h_timer[MAXPLAYERS+1];
int P_Color[MAXPLAYERS+1][4];
float P_Pos[3];

public void OnPluginStart()
{
    HookEvent("tank_spawn",E_Tank);
	HookEvent("tank_killed",E_Tank);
}

public void OnMapStart()
{
	g_Sprite = PrecacheModel(B_Model, true);
	g_Sprite2 = PrecacheModel(B_Halo, true);
	if (!g_Sprite	||	!g_Sprite2)
		SetFailState("Unable to PrecacheModels");
}

public E_Tank(Handle:event, const String:name[], bool:Broadcast) 
{
	new P = GetClientOfUserId(GetEventInt(event, "userid"));
	if (StrContains(name,"_spawn")!= -1)
	{
		//Colors Setting
		P_Color[P][0]=Red_Intensity;	
		P_Color[P][1]=Green_Intensity;	
		P_Color[P][2]=Blue_Intensity;	
		P_Color[P][3]=Alpha;
		if (P_Color[P][0]+P_Color[P][1]+P_Color[P][2]==0)
			P_Color[P][GetRandomInt(0,2)]=255;
			
		//Dynamic Light 
		int Light = CreateEntityByName("light_dynamic");
		DispatchKeyValue(Light, "brightness", "2");
		DispatchKeyValueFloat(Light, "spotlight_radius", B_End_Radius);
		DispatchKeyValue(Light, "style", "0");
		char Str_Color[16];
		Format(Str_Color,16,"%d %d %d %d",P_Color[P][0],P_Color[P][1],P_Color[P][2],P_Color[P][3])
		DispatchKeyValue(Light, "_light", Str_Color);
		DispatchKeyValueFloat(Light, "distance", B_End_Radius*3.0);
		DispatchSpawn(Light);
		GetClientAbsOrigin(P, P_Pos);
		P_Pos[2] += Hieght_Of_Ring;
		TeleportEntity(Light, P_Pos, NULL_VECTOR, NULL_VECTOR); 
		SetVariantString("!activator"); 
		AcceptEntityInput(Light, "SetParent", P, Light, 0);
		
		//Ring Timer
		h_timer[P]=CreateTimer(TIMER_CREATE_NEW_RING , Timer_Beacon,P, TIMER_REPEAT);
	}
	else
		delete h_timer[P];
}

public OnClientDisconnect(P)
{
	if (h_timer[P]!=null)
		delete h_timer[P];
}

public Action Timer_Beacon(Handle Timer,any P)
{
	GetClientAbsOrigin(P, P_Pos);
	P_Pos[2] += Hieght_Of_Ring;
	TE_SetupBeamRingPoint(B_Center , B_Start_Radius , B_End_Radius, g_Sprite, g_Sprite2, B_Start_Frame, B_Frame_Rate , B_Life_Time, B_Width, B_Amplitude, B_Color(P), B_Speed, B_Flag);
	TE_SendToAll();
	
	return Plugin_Continue;
}