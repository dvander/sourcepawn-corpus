#include <sourcemod>
#include <sdktools>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2"

#define WILLSPIN	"/vo/halloween_merasmus/sf12_wheel_spin04.mp3" //I spin the wheel
#define SPINNING	"/misc/halloween/hwn_wheel_of_fate.wav"  //wheel spinning
#define GETREADY	"/custom/Get_Ready.mp3"  //Get ready for this song intro
#define LAUGH	"vo/halloween_merasmus/sf12_combat_idle02.mp3"  //Merasmus laugh
#define BIRTHDAY "misc/happy_birthday.wav" //Birthday sound

int iPickedPlayer;
int iAmount;

public Plugin myinfo = 
{
	name = "Random Player Selection",
	author = "PC Gamer",
	description = "Pick a Random Human Player",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_randomplayer", Command_pickplayer, ADMFLAG_SLAY, "Pick a Random Player");
	RegAdminCmd("sm_wheeloffate", Command_pickplayer, ADMFLAG_SLAY, "Pick a Random Player");
	RegAdminCmd("sm_wof", Command_pickplayer, ADMFLAG_SLAY, "Pick a Random Player");
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/custom/Get_Ready.mp3");
	PrecacheSound(GETREADY);
	PrecacheSound(WILLSPIN);
	PrecacheSound(SPINNING);
	PrecacheSound(LAUGH);
	PrecacheSound(BIRTHDAY);
	PrecacheSound("/vo/announcer_ends_1sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_2sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_3sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_4sec.mp3", true);
	PrecacheSound("/vo/announcer_ends_5sec.mp3", true);
	PrecacheSound("/player/taunt_bell.wav", true);	
	PrecacheSound("vo/announcer_attention.mp3", true);	
}

public Action Command_pickplayer(int client, int args)
{
	char arg1[32];
	if (args < 1 || args > 1)
	{
		CreateTimer(0.1, Command_getwait2);
		return Plugin_Handled;		
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_BOTS|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int i = 0; 	
	iPickedPlayer = (target_list[i]);
	CreateTimer(1.0, Command_getwait2);

	return Plugin_Handled;
}

public Action Command_getwait2(Handle timer)
{ 
	int AllPlayers;
	AllPlayers = MaxClients;
	for(int A = 1; A <= AllPlayers; A++)
	{
		if(IsClientConnected(A) && IsClientInGame(A))
		{
			SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
			ShowHudText(A, 0, "Fate will select a random player...");
		}
	}
	EmitSoundToAll(WILLSPIN);
	CreateTimer(5.0, Command_SpinWheel);
	
	CPrintToChatAll("{legendary}[Wheel of Fate]{darkturquoise} Selecting a random player...");
}

public Action Command_SpinWheel(Handle timer)
{
	EmitSoundToAll(SPINNING);
	CreateTimer(9.0, Command_GetRandom);
}
public Action Command_GetRandom(Handle timer)
{
	int[] iClients = new int[MaxClients+1]; 
	int iNumClients;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0)
		{
			iClients[iNumClients++] = i;
		}
	}
	int iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];

	if (iPickedPlayer > 0)
	{
		iRandomClient = iPickedPlayer;
	}

	int AllPlayers;
	AllPlayers = MaxClients;
	for(int A = 1; A <= AllPlayers; A++)
	{
		if(IsClientConnected(A) && IsClientInGame(A))
		{
			SetHudTextParams(-1.0, 0.3, 25.0, 255, 255, 255, 255, 0, 25.0, 4.0, 4.0);
			ShowHudText(A, 0, "Fate selected %N!",iRandomClient);
		}
	}

	CPrintToChatAll("{legendary}[Wheel of Fate]{darkturquoise} Fate selected{olive} %N!",iRandomClient);
	PrintToServer("Fate selected %N!",iRandomClient);

	EmitSoundToAll(LAUGH);
	EmitSoundToAll(BIRTHDAY, iRandomClient);
	GiveParty(iRandomClient);
	
	CreateTimer(5.0, Command_GetRandom2);	

	iPickedPlayer = 0;

	return Plugin_Handled;	
}
public Action Command_GetRandom2(Handle timer)
{
	EmitSoundToAll(GETREADY);
	CreateTimer(10.0, Command_GetRandom3);		
}
public Action Command_GetRandom3(Handle timer)
{
	PrintToServer("A 20 second countdown was started for the randomly selected player.");	
	CreateTimer(0.1, Prepare_CountDown);
	return Plugin_Handled;	
}	

void GiveParty(int client)
{
	CPrintToChat(client, "{legendary}[Wheel of Fate]{darkturquoise} Fate selected{olive} YOU!");
	
	EmitSoundToAll("misc/happy_birthday.wav", client);
	float fPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
	for (int i = 1; i < 10; i++)
	ClientParticle(client, "bday_confetti", fPos, 3.0);
	ClientParticle(client, "green_wof_sparks", fPos, 3.0);
}

void ClientParticle(int client, const char[] effect, float fPos[3], float time)
{
	int iParticle = CreateEntityByName("info_particle_system");
	char sName[16];
	if (iParticle != -1)
	{
		TeleportEntity(iParticle, fPos, NULL_VECTOR, NULL_VECTOR);
		FormatEx(sName, 16, "target%d", client);
		DispatchKeyValue(client, "targetname", sName);
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", sName);
		DispatchKeyValue(iParticle, "effect_name", effect);
		DispatchSpawn(iParticle);
		SetVariantString(sName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		CreateTimer(time, Timer_KillEntity, iParticle);
	}
}

public Action Timer_KillEntity(Handle timer, any prop)
{
	if (IsValidEntity(prop))
	AcceptEntityInput(prop, "Kill");
	return Plugin_Continue;
}

public Action Prepare_CountDown(Handle timer)
{
	EmitSoundToAll("vo/announcer_attention.mp3");
	iAmount = 20;
	CreateTimer(1.0, RPTimer_CountDown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action RPTimer_CountDown(Handle timer)
{
    switch (iAmount)
    {
        case 5: EmitSoundToAll("/vo/announcer_ends_5sec.mp3");
        case 4: EmitSoundToAll("/vo/announcer_ends_4sec.mp3");
        case 3: EmitSoundToAll("/vo/announcer_ends_3sec.mp3");
        case 2: EmitSoundToAll("/vo/announcer_ends_2sec.mp3");
        case 1: EmitSoundToAll("/vo/announcer_ends_1sec.mp3");
        case 0:
        {
            PrintCenterTextAll("Done!");
            EmitSoundToAll("/player/taunt_bell.wav");
            PrintToServer("Countdown complete.");
            return Plugin_Stop;
        }
    }

    if (iAmount > 0)
    {
        PrintCenterTextAll("Countdown: %i", iAmount);
        iAmount--;
    }

    return Plugin_Continue;
}