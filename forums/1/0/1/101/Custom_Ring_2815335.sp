#include <sdktools>

#define C_SOUND_BLIP		"buttons/blip1.wav"

#define Hieght_Of_Ring 			 0.0
#define Red_Intensity			 255
#define Green_Intensity			 255
#define Blue_Intensity			 0
#define Alpha					 255

//-------Beam Ring SetUp-----------------------
#define B_Center		P_Pos
#define B_Start_Radius	0.0
#define B_End_Radius	120.0
#define B_Model			"sprites/laserbeam.vmt"
#define B_Halo			"sprites/glow01.vmt"
#define B_Start_Frame	1
#define B_Frame_Rate	1
#define B_Life_Time		0.5
#define B_Width			20.0
#define B_Amplitude		1.0
#define B_Color(%1)		P_Color[%1]
#define B_Speed			0
#define B_Flag			0
//--------------------------------------------

int g_Sprite,g_Sprite2;
int P_Color[MAXPLAYERS+1][4];
float P_Pos[3];

public void OnPluginStart()
{
    HookEvent("pills_used",HP_R);
	HookEvent("heal_success",HP_R);
}

public void OnMapStart()
{
	g_Sprite = PrecacheModel(B_Model, true);
	g_Sprite2 = PrecacheModel(B_Halo, true);
	if (!g_Sprite	||	!g_Sprite2)
		SetFailState("Unable to PrecacheModels");
}

public HP_R(Handle:event, const String:name[], bool:Broadcast) 
{
	Beacon_Player( GetClientOfUserId(GetEventInt(event,"subject")) );
}

Beacon_Player(int P)
{
	P_Color[P][0]=Red_Intensity;	
	P_Color[P][1]=Green_Intensity;	
	P_Color[P][2]=Blue_Intensity;	
	P_Color[P][3]=Alpha;
	GetClientAbsOrigin(P, P_Pos);
	P_Pos[2] += Hieght_Of_Ring;
	TE_SetupBeamRingPoint(B_Center , B_Start_Radius , B_End_Radius, g_Sprite, g_Sprite2, B_Start_Frame, B_Frame_Rate , B_Life_Time, B_Width, B_Amplitude, B_Color(P), B_Speed, B_Flag);
	TE_SendToAll();
	EmitSoundToAll(C_SOUND_BLIP,P);
}