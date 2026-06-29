
// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <sdktools>

// ---- Defines ----------------------------------------------------------------
#define CPN_VERSION "0.1.0"
#define MAX_ANNOTATION_DIST 500.0
#define MAX_ANNOTATION_ANGLE 50.0
#define MAX_ANNOTATION_LENGTH 256
#define UPDATE_RATE 0.2
#define MAX_CP 20

#define NONE 0
#define RED 2
#define BLUE 3

#define PI 3.14

// ---- Variables ---------------------------------------------------------------
new String:cp_text[MAX_CP][MAX_ANNOTATION_LENGTH];
new bool:cp_show[MAX_CP];
new Float:cp_pos[MAX_CP][3];
new cp_entity[MAX_CP];
new bool:cp_watching[MAX_CP][MAXPLAYERS];

// ---- Plugin's Information ----------------------------------------------------
public Plugin:myinfo =
{
	name	= "[TF2] Control Point's Name",
	author	= "Classic",
	description	= "Set control point's name based on who capped it.",
	version	= CPN_VERSION,
	url	= "http://www.clangs.com.ar"
};


public OnPluginStart()
{	
	HookEvent("teamplay_point_captured", OnPointCaptured);
	HookEvent("teamplay_round_start", OnRoundStart); 
	CleanCPs();
}

public OnMapStart()
{
	CreateTimer(UPDATE_RATE, Timer_UpdateCPN, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public OnRoundStart(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	CleanCPs();
}

public OnPointCaptured(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new String:strCappers[64];
	new validCappers[MaxClients];
	new validCount=0;
	GetEventString(hEvent, "cappers", strCappers, sizeof(strCappers));
	new cp_index = GetEventInt(hEvent, "cp");
	
	new cp_ent = -1, aux_ent = -1;
	aux_ent = FindEntityByClassname(aux_ent, "team_control_point");
	while(aux_ent != -1)
	{		
		if(cp_index == GetEntProp(aux_ent, Prop_Data,"m_iPointIndex"))
			cp_ent = aux_ent;
		
		aux_ent = FindEntityByClassname(aux_ent, "team_control_point");
	}
	if(!IsValidEntity(cp_ent))
	{
		return;
	}
	new String:strTest[256];
	GetEntPropString(cp_ent, Prop_Data, "m_iszPrintName", strTest, sizeof(strTest));
	
	new iLength = strlen(strCappers);
	
	for(new i=0; i<iLength; i++)
	{
		new client = strCappers[i];
		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			validCappers[validCount] = client;
			validCount++;			
		}
	}
	new String:strCPName[256];
	if(validCount == 0)
		return;
	else if(validCount == 1)
		Format(strCPName,sizeof(strCPName),"%N's lonely place",validCappers[0]);
	else if(validCount == 2)
		Format(strCPName,sizeof(strCPName),"%N & %N's love nest",validCappers[0],validCappers[1]);
	else if(validCount == 3)
		Format(strCPName,sizeof(strCPName),"%N, %N & %N's lovely place",validCappers[0],validCappers[1],validCappers[2]);
	else if(validCount == 4)
		Format(strCPName,sizeof(strCPName),"Place where %N, %N %N & %N had an orgy",validCappers[0],validCappers[1],validCappers[2],validCappers[3]);
	else if(validCount >= 5)
	{
		new iCappingTeam = GetEventInt(hEvent, "team");
		Format(strCPName,sizeof(strCPName),"Place where team %s had an orgy",iCappingTeam==3?"Blue":"Red");
	}
	
	DispatchKeyValue(cp_ent, "point_printname", strCPName);
	
	
	cp_text[cp_index] = strCPName;
	cp_show[cp_index] = true;
	cp_entity[cp_index] = cp_ent;
	GetEntPropVector(cp_ent, Prop_Send, "m_vecOrigin", cp_pos[cp_index]);
	
	
	GetEntPropString(cp_ent, Prop_Data, "m_iszPrintName", strTest, sizeof(strTest));
}


public Action:Timer_UpdateCPN(Handle:timer)
{
	for(new i=0; i< MAX_CP;i++)
	{
		if(!cp_show[i])
			continue;
		for(new j = 1; j <= MaxClients; j++)
		if(cp_watching[i][j] == true)
		{
			if(!IsWithinRange(i, j))
			{
				HideAnnotation(i,j);
			}
		}
		else
		{
			if(IsClientInGame(j) && IsPlayerAlive(j) && IsWithinRange(i, j))
			{
				new Handle:event = CreateEvent("show_annotation");
				if(event == INVALID_HANDLE) return;
				SetEventInt(event, "follow_entindex", cp_entity[i]);		
				SetEventFloat(event, "lifetime", 99999.0);
				SetEventInt(event, "id", (i*MAX_CP) + j);
				SetEventString(event, "text", cp_text[i]);
				SetEventString(event, "play_sound", "vo/null.wav");
				SetEventInt(event, "visibilityBitfield",1 << j );
				FireEvent(event);
				cp_watching[i][j]=true;
			}
		}
	}
}
bool:IsWithinRange(index, viewer)
{
	new Float:viewerpos[3];
	GetClientAbsOrigin(viewer, viewerpos);
	if(GetVectorDistance(cp_pos[index], viewerpos) <= MAX_ANNOTATION_DIST) 
	{
		new Float:xDiff = cp_pos[index][0] - viewerpos[0]; 
		new Float:yDiff = cp_pos[index][1] - viewerpos[1]; 
		new Float:AngBetween = ArcTangent2(yDiff, xDiff) * (180 / PI); 
		new Float:viewerang[3];
		GetClientAbsAngles(viewer,viewerang);
		if(AngBetween > (viewerang[1] - MAX_ANNOTATION_ANGLE) && AngBetween < (viewerang[1] + MAX_ANNOTATION_ANGLE))
			return true;
	}
	return false;
}  


stock HideAnnotationAll(index) 
{ 
	for(new i = 1; i<=MaxClients; i++)
	HideAnnotation(index,i);
}  

stock HideAnnotation(index,client)
{ 
	new Handle:event = CreateEvent("hide_annotation"); 
	if(event == INVALID_HANDLE) return; 
	SetEventInt(event, "id", (index*MAX_CP)+client ); 
	FireEvent(event); 
	cp_watching[index][client] = false;	
}  

stock CleanCPs()
{
	for(new i=0; i< MAX_CP;i++)
	{
		if(cp_show[i] == true)
			HideAnnotationAll(i);
		cp_text[i] = "";
		cp_show[i] = false;
		cp_pos[i][0] = 0.0;
		cp_pos[i][1] = 0.0;
		cp_pos[i][2] = 0.0;
		cp_entity[i] = -1;
	}
}	