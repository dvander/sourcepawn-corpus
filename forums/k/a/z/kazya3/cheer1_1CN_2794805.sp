#include <sourcemod>
#include <sdktools>

ConVar	Cheer_Count, Cheer_CoolDown;
int		g_Cheer_Count;
float	g_Cheer_CoolDown;
int		p_Cheer_Count[MAXPLAYERS + 1]	= {0, ...};
float 	p_Cheer_LastTime[MAXPLAYERS+1] 	= {0.0, ...};//最后一次使用的时间节点
Handle	p_Cheer_CoolDown_Timer[MAXPLAYERS+1]	= {INVALID_HANDLE, ...};
static char sound_list[][] = {
	"player/survivor/voice/producer/laughter04.wav",
	"player/survivor/voice/producer/laughter12.wav",
	"player/survivor/voice/producer/laughter13.wav",
	"player/survivor/voice/producer/laughter15.wav"
};

public Plugin:myinfo =
{
	name = "Cheer - 嘲讽",
	author = "CD意识STEAM_1:0:211123334 (Alliedmods:kazya3)",
	description = "仿cs使用!cheer嘲讽",
	version = "1.1",
	url = ""
};

public OnPluginStart() {
	RegConsoleCmd("sm_cheer", Cheer_Cmd, "嘲笑");

	Cheer_Count     = CreateConVar("L4D2_Cheer_Count", 	    	"3", 		"欢呼次数",		FCVAR_NOTIFY, true, 0.0, true, 99.0);
	Cheer_CoolDown  = CreateConVar("L4D2_Cheer_CoolDown", 		"20.0", 	"欢呼冷却",		FCVAR_NOTIFY, true, 0.0, true, 9000.0);

	Cheer_Count.AddChangeHook(ConVarChanges);
	Cheer_CoolDown.AddChangeHook(ConVarChanges);

	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy); //對抗模式下會觸發兩次 (第一次人類滅團之時 第二次隊伍換邊之時)
	HookEvent("mission_lost", 			Event_RoundEnd, 	EventHookMode_PostNoCopy);
	HookEvent("map_transition",			Event_RoundEnd,		EventHookMode_PostNoCopy); //戰役模式下過關到下一關的時候 (沒有觸發round_end)
	HookEvent("finale_vehicle_leaving",	Event_RoundEnd,		EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)

	AutoExecConfig(true, "l4d2_cheer_v1.1");
}
//////////////////////////////////////////初始化相关//////////////////////////////////////////
public void OnConfigsExecuted(){
	GetCvars();
}
public void ConVarChanges(ConVar convar, const char[] oldValue, const char[] newValue){
	GetCvars();
}
void GetCvars(){
	g_Cheer_Count = GetConVarInt(Cheer_Count);
	g_Cheer_CoolDown	= GetConVarFloat(Cheer_CoolDown);
	reset();//每次改变都重置
}
//////////////////////////////////////////Main Func//////////////////////////////////////////
public Action Cheer_Cmd(int client, int args){
	if ( isSurvivor(client)){
		if(p_Cheer_Count[client] > 0){
			p_Cheer_Count[client]--;
			PrintToChatAll("\x03[!cheer] \x04%N \x03绷不住了! \x04(%d/%d)", client, p_Cheer_Count[client], g_Cheer_Count);
			int random = GetRandomInt(0, sizeof(sound_list) - 1);
			EmitSoundToSurvivor(random);
			p_Cheer_LastTime[client] = GetEngineTime();
			//cooldown
			if(p_Cheer_CoolDown_Timer[client] == INVALID_HANDLE){
				p_Cheer_CoolDown_Timer[client] = CreateTimer(g_Cheer_CoolDown, Timer_CoolDown, client, TIMER_REPEAT);
			}
		}
		else{
			float timeLeft = g_Cheer_CoolDown - GetEngineTime() + p_Cheer_LastTime[client];
			//cooldown
			PrintHintText(client, "次数已用完 (CD: %.1fs)", timeLeft);//cant use print
		}
	}
	return Plugin_Handled;
}

public Action Timer_CoolDown(Handle timer, int client){
	p_Cheer_Count[client] += 1;
	char text[64];
	FormatEx(text, sizeof(text), "cheer + 1 (CD: %.1fs)", g_Cheer_CoolDown)
	PrintHintText(client, text, p_Cheer_Count[client]);//times left print
	if(p_Cheer_Count[client] >= g_Cheer_Count){
		p_Cheer_Count[client] = g_Cheer_Count;
		p_Cheer_CoolDown_Timer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
//////////////////////////////////////////缓存与重置//////////////////////////////////////////
public void OnMapStart(){
	for( int i = 0; i < sizeof(sound_list); i++ ){
		PrecacheSound(sound_list[i]);
	}
}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	reset();
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
	reset();
}
public void OnClientDisconnect(int client){
	p_Cheer_Count[client] = g_Cheer_Count;
	p_Cheer_LastTime[client] = 0.0;
	delete p_Cheer_CoolDown_Timer[client];
}
void reset(){
	for(int i; i<= MaxClients; i++){
		p_Cheer_Count[i] = g_Cheer_Count;
		p_Cheer_LastTime[i] = 0.0;
		delete p_Cheer_CoolDown_Timer[i];
	}
}
//////////////////////////////////////////封装//////////////////////////////////////////
bool isClientValid(int client, bool NoBot = true){
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (NoBot){
		if (IsFakeClient(client)) return false;
	}
	return true;
}
bool isSurvivor(int client){
	return isClientValid(client) && GetClientTeam(client) == 2;
}
void EmitSoundToSurvivor(int random){
	for (int i = 1; i <= MaxClients; i++){
		if (isSurvivor(i)){
			EmitSoundToClient(i, sound_list[random]);
		}
	}
}
