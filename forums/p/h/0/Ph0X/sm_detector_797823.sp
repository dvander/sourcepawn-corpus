#define VERSION	"1.0.0.0"

#include <sourcemod>
#include <sdktools>
#include <hooker>

new g_Targets[MAXPLAYERS + 1] = {0,...};
new bool:g_CanDetect[MAXPLAYERS + 1] = {false,...};

public Plugin:myinfo = {
	name = "Distance & Angle Detector",
	author = "Ehsan 'Ph0X' Kia",
	description = "This plugin will display on your screen at what angle and what distance the selected player is.",
	version = VERSION,
	url = "http://phox.tiger-rider.com/"
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	CreateConVar("change_version",VERSION,"changedesc",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	RegAdminCmd("sm_detect", Command_Detect, ADMFLAG_KICK, "sm_detect <#userid|name>");
	RegisterHook(HK_ClientPreThink,OnClientPreThink,true)
}

public OnClientPutInServer(client)
{
	HookEntity(HKE_CCSPlayer, client)
}
public OnClientDisconnect(client)
{
	UnHookPlayer(HKE_CCSPlayer, client)
}

public OnClientPreThink(client) {
	if (g_CanDetect[client]){
		//Variables
		decl Float:pos[2][3], Float:ang[3];
		new Float:fDistance, Float:fAngle, Float:fT_Angle;
		decl String:sDistance[8], String:sAngle[8];
		new bool:bDirection = false;
		
		//Get Positions and Angles
		GetClientAbsOrigin(client, pos[0]);
		GetClientEyeAngles(client, ang);
		GetClientAbsOrigin(g_Targets[client], pos[1]);
		
		//Calculate Distance and Target Angle
		fDistance = SquareRoot( Pow(pos[1][0]-pos[0][0], 2.0) + Pow(pos[1][1]-pos[0][1], 2.0) + Pow(pos[1][2]-pos[0][2], 2.0) );
		fT_Angle = RadToDeg(ArcSine(FloatAbs(pos[1][1]-pos[0][1])/fDistance))
		
		//Changes the Target Angle depending of it's position to the client
		if (pos[1][0] < pos[0][0]){
			fT_Angle = 180 - fT_Angle
			if (pos[1][1] < pos[0][1])
				fT_Angle = 360 - fT_Angle
		}
		else{
			if (pos[1][1] < pos[0][1])
				fT_Angle = 360 - fT_Angle
		}
		
		//Adds  the View Angle
		fAngle = fT_Angle - ang[1]
		
		//Direction Calculation
		if (fAngle < 0){
			bDirection = !bDirection;
			fAngle = FloatAbs(fAngle);
		}		
		if (fAngle > 180){
			bDirection = !bDirection;
			fAngle = 360 - fAngle
		}
		
		//Rounds Floats and Transforms to Integer
		new iDistance = RoundFloat(fDistance)
		new iAngle = RoundFloat(fAngle)
		
		//Transform Floats to Strings
		IntToString(iDistance, sDistance, sizeof(sDistance));
		IntToString(iAngle, sAngle, sizeof(sAngle));
		
		//Display Distance, Angle and Direction
		if (iAngle == 0)
			PrintCenterText(client, "( Distance: %s )", sDistance);
		else if (bDirection)
			PrintCenterText(client, "        ( Distance: %s ) %s -->", sDistance, sAngle);
		else
			PrintCenterText(client, "<-- %s ( Distance: %s )         ", sAngle, sDistance);
	}
}

public Action:Command_Detect(client,args) {
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new target = FindTarget(client, arg1);
		if( target != -1 ){
			g_Targets[client] = target;
			if (!g_CanDetect[client])
				g_CanDetect[client] = true;		
			else
				g_CanDetect[client] = false;
		}
		else
			g_CanDetect[client] = false;
			
		return Plugin_Handled;
}