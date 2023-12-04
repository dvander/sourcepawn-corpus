#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define cheerCount 5	//times each player can laugh
#define cheerCD 20.0		//cd how many seconds that player can laugh times add 1

int p_cheer_count[MAXPLAYERS + 1] = {cheerCount, ...};//cheer count
Handle coolDown_Timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...}; //cooldown of cheer

static char sound_list[4][] =
{
	"player/survivor/voice/producer/laughter04.wav",
	"player/survivor/voice/producer/laughter12.wav",
	"player/survivor/voice/producer/laughter13.wav",
	"player/survivor/voice/producer/laughter15.wav"
};

public Plugin:myinfo = 
{
	name = "cheer",
	author = "CD意识.(kazya3)",
	description = "Smile to difficulties, type !cheer",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_cheer", Cheer_Cmd, "LMAO");
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy); //對抗模式下會觸發兩次 (第一次人類滅團之時 第二次隊伍換邊之時)
	HookEvent("map_transition",			Event_RoundEnd); //戰役模式下過關到下一關的時候 (沒有觸發round_end)
	HookEvent("finale_vehicle_leaving",	Event_RoundEnd); //救援載具離開之時  (沒有觸發round_end)
}

public void OnMapStart()
{
//声音缓存
	for( int i = 0; i < sizeof(sound_list); i++ )
	{
		PrecacheSound(sound_list[i]);
	}
	Reset();
}

public void OnMapEnd()
{
	Reset();
}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action LoadingTimer(Handle timer)
{
	Reset();
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	Reset();
}

bool isSurvivor(int client)
{
	return isClientValid(client) && GetClientTeam(client) == 2;
}

bool isClientValid(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}

public Action Cheer_Cmd(int client, int args)
{
	if ( isSurvivor(client))
	{
		if(p_cheer_count[client] > 0){
			p_cheer_count[client]--;
			PrintToChatAll("\x03[!cheer]\x04%N \x03LMAO! \x04(%d/%d)", client, p_cheer_count[client], cheerCount);// someone lmao print
			int random = GetRandomInt(0, sizeof(sound_list) - 1);//random noise
			//I dont know why in my local host lobby emitsoudtoall function doesnt work, so i foreach survivors to emitsound, its stupid but works...WHATEVER
			EmitSoundForSurvivor(random);
			//cooldown
			if(coolDown_Timer[client] == INVALID_HANDLE){
				coolDown_Timer[client] = CreateTimer(cheerCD, Timer_COOLDOWN, client, TIMER_REPEAT);
			}
		}
		else{
			PrintHintText(client, "no times left");//cant use print
		}
	}
	return Plugin_Handled;
}

public Action Timer_COOLDOWN(Handle timer, int client)
{
	p_cheer_count[client] += 1;
	PrintHintText(client, "cheer+1 (CD: 20s)", p_cheer_count[client]);//times left print
	if(p_cheer_count[client] >= cheerCount){
		p_cheer_count[client] = cheerCount;
		coolDown_Timer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	p_cheer_count[client] = cheerCount;
	delete coolDown_Timer[client];
}

void EmitSoundForSurvivor(random){
	for (int j = 1; j <= MaxClients; j++) 
	{
		if (isSurvivor(j))
		{
			EmitSoundCustom(j, sound_list[random]);
		}
	}
}

void EmitSoundCustom(int client, const char[] sound)
{
	EmitSoundToClient(client, sound, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, 1.0, _, _, _, _, _, _);
}

void Reset()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		p_cheer_count[i] = cheerCount;
		delete coolDown_Timer[i];
	}
}