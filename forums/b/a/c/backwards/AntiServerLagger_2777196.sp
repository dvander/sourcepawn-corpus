#include <sourcemod>
#include <dhooks>
#include <profiler>

public Plugin:myinfo =
{
	name = "[TF2] Anti Server Lagger",
	author = "backwards",
	description = "Adds the net_chan_limit_msec functionality from csgo to tf2 to prevent server lag exploits.",
	version = "1.0",
	url = "http://www.steamcommunity.com/id/mypassword"
}

Handle hProcessPacketDetour, PP, hPlayerSlot;
ConVar net_chan_limit_msec;
float TotalProcessingTime[MAXPLAYERS+1] = 0.0;
Address m_MessageHandlerAddress = 0x0;

public OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile("AntiServerLagger");
	
	if (!hGameData)
		SetFailState("Failed to load AntiServerLagger gamedata.");

	int OperatingSystem = GameConfGetOffset(hGameData, "OperatingSystem");

	if(OperatingSystem == 1) //windows
		m_MessageHandlerAddress = 0x22E4;
	else if(OperatingSystem == 2) // linux
		m_MessageHandlerAddress = 0x22DC;
	
	hProcessPacketDetour = DHookCreateFromConf(hGameData, "ProcessPacket");
	
	if (!hProcessPacketDetour)
		SetFailState("Failed to setup detour for ProcessPacket");
	
	if (!DHookEnableDetour(hProcessPacketDetour, false, Detour_ProcessPacket))
		SetFailState("Failed to detour ProcessPacket.");
	
	if (!DHookEnableDetour(hProcessPacketDetour, true, Detour_ProcessPacketPost))
		SetFailState("Failed to detour ProcessPacketPost.");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hPlayerSlot = EndPrepSDKCall();
	
	if(hPlayerSlot == INVALID_HANDLE)
		SetFailState("Failed to setup sdkcall for CBaseClient::GetPlayerSlot.");
	
	delete hGameData;
	
	net_chan_limit_msec = CreateConVar("net_chan_limit_msec", "20", "max limit packets processing time in ms.", FCVAR_NONE);
	PP = CreateProfiler();
	CreateTimer(1.0, ShowInfoToPlayersAndPunish, _, TIMER_REPEAT);
} 

public MRESReturn Detour_ProcessPacket(Address pThis, Handle hReturn, Handle hParams)
{
    StartProfiling(PP);
    return MRES_Ignored;
}

public MRESReturn Detour_ProcessPacketPost(Address pThis, Handle hReturn, Handle hParams)
{
	StopProfiling(PP);

	Address IClient = LoadFromAddress(pThis + m_MessageHandlerAddress, NumberType_Int32);

	//IClient Not Accessible.
	if(IClient == view_as<Address>(0x0))
		return MRES_Ignored;
	
	int client = view_as<int>(SDKCall(hPlayerSlot, IClient)) + 1;
	TotalProcessingTime[client] += GetProfilerTime(PP);
	
	//Kick instantly for really affective exploits.
	if(GetProfilerTime(PP) > net_chan_limit_msec.FloatValue / 1000)
	{
		if(net_chan_limit_msec.FloatValue == 0.0)
			return MRES_Ignored;
		
		PrintToServer("[Anti-Server-Lagger]: Kicked '%N' for having a packet processing time of %f ms.", client, TotalProcessingTime[client]);
		KickClientEx(client, "[Anti-Server-Lagger]: Abuser.");
	} 
	
	return MRES_Ignored;
}

public Action:ShowInfoToPlayersAndPunish(Handle:timer, any:unused)
{
	for(int i = 1;i<MaxClients+1;i++)
	{
		if(net_chan_limit_msec.FloatValue == 0.0)
			break;
					
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if(TotalProcessingTime[i] > net_chan_limit_msec.FloatValue / 1000)
			{
				PrintToServer("[Anti-Server-Lagger]: Kicked '%N' for having a packet processing time of %f ms.", i, TotalProcessingTime[i]);
				KickClientEx(i, "[Anti-Server-Lagger]: Abuser.");
			}
			
			/////debug
			//if(IsClientInGame(i))
			//	PrintToChat(i, "Packet Processing Time = %f.", TotalProcessingTime[i]);
		}
		
		TotalProcessingTime[i] = 0.0;
	}
	
	return Plugin_Continue;
}
