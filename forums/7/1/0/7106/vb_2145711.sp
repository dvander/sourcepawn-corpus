#include <sourcemod>
#include <sdktools>
#define WIN_SOUND "win001.mp3"
#define WIN_SOUND_FILE "sound/win001.mp3"
#define WIN_SOUND_1 "win002.mp3"
#define WIN_SOUND_1_FILE "sound/win002.mp3"
#define WIN_SOUND_2 "win003.mp3"
#define WIN_SOUND_2_FILE "sound/win003.mp3"
#define WIN_SOUND_3 "win004.mp3"
#define WIN_SOUND_3_FILE "sound/win004.mp3"
#define WIN_SOUND_4 "win005.mp3"
#define WIN_SOUND_4_FILE "sound/win005.mp3"
#define LOSE_SOUND "lose001.mp3"
#define LOSE_SOUND_FILE "sound/lose001.mp3"
#define LOSE_SOUND_1 "lose002.mp3"
#define LOSE_SOUND_1_FILE "sound/lose002.mp3"
#define LOSE_SOUND_2 "lose003.mp3"
#define LOSE_SOUND_2_FILE "sound/lose003.mp3"
#define LOSE_SOUND_3 "lose004.mp3"
#define LOSE_SOUND_3_FILE "sound/lose004.mp3"
#define LOSE_SOUND_4 "lose005.mp3"
#define LOSE_SOUND_4_FILE "sound/lose005.mp3"
new k=0;
new m=0;
public OnPluginStart()
{
HookEvent("teamplay_broadcast_audio", Event_Audio, EventHookMode_Pre);
}
public OnMapStart()
{
PrecacheSound(WIN_SOUND);
PrecacheSound(WIN_SOUND_1);
PrecacheSound(WIN_SOUND_2);
PrecacheSound(WIN_SOUND_3);
PrecacheSound(WIN_SOUND_4);
PrecacheSound(LOSE_SOUND);
PrecacheSound(LOSE_SOUND_1);
PrecacheSound(LOSE_SOUND_2);
PrecacheSound(LOSE_SOUND_3);
PrecacheSound(LOSE_SOUND_4);
AddFileToDownloadsTable(WIN_SOUND_FILE);
AddFileToDownloadsTable(WIN_SOUND_1_FILE);
AddFileToDownloadsTable(WIN_SOUND_2_FILE);
AddFileToDownloadsTable(WIN_SOUND_3_FILE);
AddFileToDownloadsTable(WIN_SOUND_4_FILE);
AddFileToDownloadsTable(LOSE_SOUND_FILE);
AddFileToDownloadsTable(LOSE_SOUND_1_FILE);
AddFileToDownloadsTable(LOSE_SOUND_2_FILE);
AddFileToDownloadsTable(LOSE_SOUND_3_FILE);
AddFileToDownloadsTable(LOSE_SOUND_4_FILE);
}
public Action:Event_Audio(Handle:event, const String:name[], bool:dontBroadcast)
{
new String:strAudio[40];
GetEventString(event, "sound", strAudio, sizeof(strAudio));
new iTeam = GetEventInt(event, "team");
if(strcmp(strAudio, "Game.YourTeamWon") == 0)
{
if(k==0)
{
EmitSoundToTeam(iTeam, WIN_SOUND);
k++;
return Plugin_Handled;
}
if(k==1)
{
EmitSoundToTeam(iTeam, WIN_SOUND_1);
k++;
return Plugin_Handled;
} 
if(k==2)
{ 
EmitSoundToTeam(iTeam, WIN_SOUND_2);
k++;
return Plugin_Handled;
}
if(k==3)
{
EmitSoundToTeam(iTeam, WIN_SOUND_3);
k++;
return Plugin_Handled;
} 
else
{
EmitSoundToTeam(iTeam, WIN_SOUND_4);
k=0;
return Plugin_Handled;
} 
 
 
}
else if(strcmp(strAudio, "Game.YourTeamLost") == 0)
{
if(m==0)
{
EmitSoundToTeam(iTeam, LOSE_SOUND);
m++;
return Plugin_Handled;
}
if(m==1)
{
EmitSoundToTeam(iTeam, LOSE_SOUND_1);
m++;
return Plugin_Handled;
} 
if(m==2)
{
EmitSoundToTeam(iTeam, LOSE_SOUND_2);
m++;
return Plugin_Handled;
} 
if(m==3)
{
EmitSoundToTeam(iTeam, LOSE_SOUND_3);
m++;
return Plugin_Handled;
} 
else
{
EmitSoundToTeam(iTeam, LOSE_SOUND_4);
m=0;
return Plugin_Handled;
} 
 
 
 
}
 
return Plugin_Continue;
}
EmitSoundToTeam(iTeam, const String:strSound[])
{
for(new i=1; i<=MaxClients; i++)
if(IsClientInGame(i) && GetClientTeam(i) == iTeam)
EmitSoundToClient(i, strSound);
}