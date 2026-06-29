/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.2.3.9";

public Plugin:myinfo = {
	
	name = "RealisticBulletSound",
	author = "javalia",
	description = "make u scary",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
//#include <cstrike>
//#include "sdkhooks"
//#include "vphysics"
//#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

#define MINBULLETLTORSOUND 0
#define MAXBULLETLTORSOUND 10
#define MINBULLETRICSOUND 11
#define MAXBULLETRICSOUND 15
#define TOTALSOUND 16

#define RADRIGHTANGLE (FLOAT_PI / 2)//this value will be genarated on runtime, so it can hope always work correctly.

new const String:sounddata[][] = {

	"weapons/fx/nearmiss/bulletltor03.wav",
	"weapons/fx/nearmiss/bulletltor04.wav",
	"weapons/fx/nearmiss/bulletltor05.wav",
	"weapons/fx/nearmiss/bulletltor06.wav",
	"weapons/fx/nearmiss/bulletltor07.wav",
	"weapons/fx/nearmiss/bulletltor09.wav",
	"weapons/fx/nearmiss/bulletltor10.wav",
	"weapons/fx/nearmiss/bulletltor11.wav",
	"weapons/fx/nearmiss/bulletltor12.wav",
	"weapons/fx/nearmiss/bulletltor13.wav",
	"weapons/fx/nearmiss/bulletltor14.wav",
	"weapons/fx/rics/ric1.wav",
	"weapons/fx/rics/ric2.wav",
	"weapons/fx/rics/ric3.wav",
	"weapons/fx/rics/ric4.wav",
	"weapons/fx/rics/ric5.wav"

};

new Handle:cvar_enablenearmisssound = INVALID_HANDLE;
new Handle:cvar_enablericochetsound = INVALID_HANDLE;
new Handle:cvar_nearmissdistance = INVALID_HANDLE;
new Handle:cvar_bulletmakesound = INVALID_HANDLE;

public OnPluginStart(){

	CreateConVar("RealisticBulletSound_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	cvar_enablenearmisssound = CreateConVar("RealisticBulletSound_enablenearmisssound", "1", "1 for enable, 0 for disable");
	cvar_enablericochetsound = CreateConVar("RealisticBulletSound_enablericochetsound", "1", "1 for enable, 0 for disable");
	cvar_nearmissdistance = CreateConVar("RealisticBulletSound_nearmissdistance", "64.0", "distance to client from bullet line that let u hear the nearmiss sound");
	cvar_bulletmakesound = CreateConVar("RealisticBulletSound_bulletmakesound", "256.0", "bullet will make nearmiss sound if bullet has flied longer than this");
	HookEvent("bullet_impact", event_bullet);
	
}

public OnMapStart(){
	
	AutoExecConfig();
	
	for(new i = 0; i < TOTALSOUND; i++){
		
		PrecacheSound(sounddata[i], true);
		
	}

}

public Action:event_bullet(Handle:Event, const String:Name[], bool:Broadcast){

	decl client, Float:bulletposition[3];

	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	bulletposition[0] = GetEventFloat(Event, "x");
	bulletposition[1] = GetEventFloat(Event, "y");
	bulletposition[2] = GetEventFloat(Event, "z");
	
	new contents, ent;
	contents = TR_GetPointContents(bulletposition, ent);
	
	if((ent == 0 || ent > MaxClients) && !(contents & (MASK_WATER | CONTENTS_WINDOW)) && GetConVarBool(cvar_enablericochetsound)){
	
		//make ric sound on here
		EmitSoundToAll(sounddata[GetRandomInt(MINBULLETRICSOUND, MAXBULLETRICSOUND)], 0, SNDCHAN_STATIC, 80, SND_NOFLAGS, GetRandomFloat(0.5, 0.6), GetRandomInt(90, 110), -1, bulletposition, NULL_VECTOR, true, 0.0);
	
	}
	
	decl Float:clienteyepos[3], Float:targetpos[3];
	decl Float:cltotargetvec[3], Float:cltobulletvec[3], Float:cltobulletdistance, Float:cltotargetdistance;
	decl Float:targetnbulletangle, Float:heardistance;//i hate these symbolname.
	
	GetClientEyePosition(client, clienteyepos);
	MakeVectorFromPoints(clienteyepos, bulletposition, cltobulletvec);
	cltobulletdistance = GetVectorDistance(clienteyepos, bulletposition);
	NormalizeVector(cltobulletvec, cltobulletvec);
	
	if(GetConVarBool(cvar_enablenearmisssound)){
	
		for(new i = 1; i <= MaxClients; i++){
		
			if(i != client && IsClientInGame(i)){
				
				GetClientEyePosition(i, targetpos);
				MakeVectorFromPoints(clienteyepos, targetpos, cltotargetvec);
				cltotargetdistance = GetVectorDistance(clienteyepos, targetpos);
				NormalizeVector(cltotargetvec, cltotargetvec);
				
				targetnbulletangle = ArcCosine(GetVectorDotProduct(cltotargetvec, cltobulletvec));//this is radian angle;
				
				if(targetnbulletangle < RADRIGHTANGLE){
				
					//bulletlinelength = Cosine(targetnbulletangle) * cltotargetdistance;
					heardistance = Sine(targetnbulletangle) * cltotargetdistance;
					
					if(heardistance <= GetConVarFloat(cvar_nearmissdistance)){
					
						//lets not make bullet sound if bullet didnt flyed long enough distance
						if(cltobulletdistance >= GetConVarFloat(cvar_bulletmakesound)){
							
							//PrintToServer("%f %f %f", cltotargetdistance, RadToDeg(targetnbulletangle), heardistance);
							EmitSoundToClient(i, sounddata[GetRandomInt(MINBULLETLTORSOUND, MAXBULLETLTORSOUND)], 0, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE, SND_NOFLAGS, 0.7, SNDPITCH_NORMAL, -1, clienteyepos, cltobulletvec, false);
						
						}
					
					}
					
				}
				
				//old version of code, not deleting cuz i loved this a bit. k?
				/* GetClientEyePosition(i, targetpos);
				MakeVectorFromPoints(clienteyepos, targetpos, cltotargetvec);
				cltotargetdistance = GetVectorDistance(clienteyepos, targetpos);
				NormalizeVector(cltotargetvec, cltotargetvec);
				
				targetnbulletangle = RadToDeg(ArcCosine(GetVectorDotProduct(cltotargetvec, cltobulletvec)));
				
				decl Float:soundresultpos[3];
				
				if(targetnbulletangle < 89.0){//derp
					
					// is this right?
					bulletlinelength = FloatMul(Cosine(DegToRad(targetnbulletangle)), cltotargetdistance);
					
					// PrintToChatAll("%f %f %f", cltotargetdistance, targetnbulletangle, bulletlinelength);
					
					if(bulletlinelength >= 300.0 && bulletlinelength < cltobulletdistance){
					
						ScaleVector(cltobulletvec, bulletlinelength);
						AddVectors(clienteyepos, cltobulletvec, soundresultpos);
						NormalizeVector(cltobulletvec, cltobulletvec);
						EmitSoundToClient(i, sounddata[GetRandomInt(MINBULLETLTORSOUND, MAXBULLETLTORSOUND)], 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, soundresultpos);
					
					}
					
				}else if(cltobulletdistance >= 300.0){
				
					EmitSoundToClient(i, sounddata[GetRandomInt(MINBULLETLTORSOUND, MAXBULLETLTORSOUND)], 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyepos);
				
				} */
				
			}
		
		}
		
	}
	
}