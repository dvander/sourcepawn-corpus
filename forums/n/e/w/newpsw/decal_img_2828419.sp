#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <socket>
#include <autoexecconfig>

public Plugin myinfo = {
	name = "Decal image",
	author = "newpsw",
	description = "Socket chat and draw image with decals",
	version = "1.0.0"
};

Handle eSocket = INVALID_HANDLE;
static char Sip[18] = "";
static int Sport = 0;

static float DendPos[3];
static float EstartPos[3];
static int linei = 0;
static int icolor = 0;
static int DrawC = 0;
static int EntIndHit = -1;
static int BoxIndHit = 0;
static char Imgdata[8476][5];

ConVar con_server_ip;
ConVar con_server_port;

public void OnPluginStart()
{	
	AutoExecConfig_SetFile("decal_img");
	con_server_ip = AutoExecConfig_CreateConVar("sm_Imgserver_ip", "127.0.0.1", "Set ip info of server");
	con_server_port = AutoExecConfig_CreateConVar("sm_Imgserver_port", "8999", "Set port info of server");
	AutoExecConfig_ExecuteFile();
	
	con_server_ip.AddChangeHook(ConVarIpChanged);
	con_server_port.AddChangeHook(ConVarPortChanged);
	
	GetConVarString(con_server_ip, Sip, sizeof(Sip));
	Sport = GetConVarInt(con_server_port);
	
	Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Sip, Sport);
	
	HookEvent("nmrih_reset_map", Event_Resetm);
	
	RegConsoleCmd("say", Bcast_say);
}

void ConVarIpChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Format(Sip, sizeof(Sip), "%s", newValue);
	PrintToServer("[!]Ip changed: %s", Sip);
}

void ConVarPortChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Sport = StringToInt(newValue);
	PrintToServer("[!]Port changed: %d", Sport);
}

public void OnMapStart()
{
	DrawC = 0;
	return;
}

public Action Event_Resetm(Event event, const char[] name, bool dontBroadcast)
{
	DrawC = 0;
	return Plugin_Continue;
}

public void OnMapEnd()
{
	DrawC = 0;
}

public OnSocketConnected(Handle socket, int arg)
{
	if(socket != INVALID_HANDLE && SocketIsConnected(socket))
	{
		eSocket = socket;
	}
	else
	{
		delete socket;
		Handle Rsocket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketConnect(Rsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Sip, Sport);
	}
}

public OnSocketReceive(Handle socket, char[] RData, int dataSize, Handle hFile)
{
	if(socket != INVALID_HANDLE && SocketIsConnected(socket))
	{
		char Dchat[4];
		Format(Dchat, sizeof(Dchat), "%s", RData);
		if(StrContains(Dchat, "Dc_") != -1)
		{
			char Cexplode[47][5];
			ExplodeString(RData, "-", Cexplode, sizeof(Cexplode), sizeof(Cexplode[]));
			for(int i = 0; i < 45; i++)
			{
				if(!StrEqual(Cexplode[2+i], "", true))
				{
					//Format(Imgdata[StringToInt(Cexplode[1])+i], sizeof(Imgdata[]), "%s", Cexplode[2+i]);
					Imgdata[StringToInt(Cexplode[1])+i] = Cexplode[2+i];
					continue;
				}
				else
				{
					break;
				}
			}
			
			//PrintToChatAll("%s", Cexplode[1]);
			if(StringToInt(Cexplode[1]) > 8459)
			{
				//PrintToChatAll("마지막 값: %s", Imgdata[8475]);
				int client = StringToInt(Cexplode[0][3]);
				if(0 < client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
							continue;
						
						ClientCommand(i, "r_cleardecals");
						continue;
					}
					float EyeAng[3];
					EntIndHit = -1;
					GetClientEyePosition(client, EstartPos);
					GetClientEyeAngles(client, EyeAng);
					Handle Tray = TR_TraceRayFilterEx(EstartPos, EyeAng, MASK_ALL, RayType_Infinite, TraceFilter_DontHitSelf, client);
					
					TR_GetEndPosition(DendPos, Tray);
					if(TR_DidHit(Tray))
					{
						EntIndHit = TR_GetEntityIndex(Tray);
						BoxIndHit = TR_GetHitBoxIndex(Tray);
					}
					delete Tray;
					
					DendPos[1] -= 50.0;
					DendPos[2] += 40.0;
					
					if (EntIndHit > -1)
					{
						linei = 0;
						RequestFrame(Reqdraw, _);
					}
					else
					{
						DrawC = 0;
					}
				}
				else
				{
					DrawC = 0;
				}
			}
		}
		else if(StrContains(Dchat, "Re0") != -1)
		{
			DrawC = 0;
		}
		else
		{
			PrintToServer("%s", RData);
			PrintToChatAll("%s", RData);
		}
	}
	else
	{
		delete socket;
		Handle Rsocket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketConnect(Rsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Sip, Sport);
	}
	return;
}

public bool TraceFilter_DontHitSelf(int entity, int contentsmask, int client)
{
	return entity != client;
}

public void Reqdraw(any data)
{
	if(DrawC < 1)
	{
		icolor = 0;
		return;
	}
	
	int istamp = 13;
	if(linei > 7)
	{
		istamp = 9;
	}
	
	for(int i = 0; i < istamp; i++)
	{
		if(StrContains(Imgdata[icolor], "7") != -1) //검은색 픽셀은 생략
		{
			DendPos[1] += 1.0;
			icolor += 1;
			continue;
		}
		
		if(StrContains(Imgdata[icolor], "5") != -1 || StrContains(Imgdata[icolor], "6") != -1)
		{
			if(icolor < 113)
			{
				if(icolor+113 < 8475 && StrContains(Imgdata[icolor+113], Imgdata[icolor]) != -1)
				{
					if(i+1 < istamp && StrContains(Imgdata[icolor+1], Imgdata[icolor]) != -1 && StrContains(Imgdata[icolor+114], Imgdata[icolor]) != -1)
					{
						DendPos[1] += 0.5;
						DendPos[2] -= 0.5;
						char nfile[24];
						Format(nfile, sizeof(nfile), "paint/paint_%sx4.vmt", Imgdata[icolor]);
						
						TE_Start("Entity Decal");
						TE_WriteVector("m_vecOrigin", DendPos);
						TE_WriteVector("m_vecStart", EstartPos);
						TE_WriteNum("m_nEntity", EntIndHit);
						TE_WriteNum("m_nHitbox", BoxIndHit);
						TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
						TE_SendToAll();
						
						DendPos[1] += 1.5;
						DendPos[2] += 0.5;
						if(StrContains(Imgdata[icolor], "5") != -1)
						{
							Imgdata[icolor] = "!5";
							Imgdata[icolor+1] = "!5";
							Imgdata[icolor+113] = "!5";
							Imgdata[icolor+114] = "!5";
						}
						else if(StrContains(Imgdata[icolor], "6") != -1)
						{
							Imgdata[icolor] = "!6";
							Imgdata[icolor+1] = "!6";
							Imgdata[icolor+113] = "!6";
							Imgdata[icolor+114] = "!6";
						}
						icolor += 2;
						i += 1;
						continue;
					}
					else
					{
						DendPos[2] -= 0.5;
						char nfile[24];
						Format(nfile, sizeof(nfile), "paint/paint_%sx2.vmt", Imgdata[icolor]);
						
						TE_Start("Entity Decal");
						TE_WriteVector("m_vecOrigin", DendPos);
						TE_WriteVector("m_vecStart", EstartPos);
						TE_WriteNum("m_nEntity", EntIndHit);
						TE_WriteNum("m_nHitbox", BoxIndHit);
						TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
						TE_SendToAll();
						
						DendPos[2] += 0.5;
						DendPos[1] += 1.0;
						if(StrContains(Imgdata[icolor], "5") != -1)
						{
							Imgdata[icolor] = "!5";
							Imgdata[icolor+113] = "!5";
						}
						else if(StrContains(Imgdata[icolor], "6") != -1)
						{
							Imgdata[icolor] = "!6";
							Imgdata[icolor+113] = "!6";
						}
						icolor += 1;
						continue;
					}
				}
				else if(i+1 < istamp && StrContains(Imgdata[icolor+1], Imgdata[icolor]) != -1)
				{
					if(icolor+114 < 8475 && StrContains(Imgdata[icolor+114], Imgdata[icolor]) != -1)
					{
						char nfile[24];
						Format(nfile, sizeof(nfile), "paint/paint_%s.vmt", Imgdata[icolor]);
						
						TE_Start("Entity Decal");
						TE_WriteVector("m_vecOrigin", DendPos);
						TE_WriteVector("m_vecStart", EstartPos);
						TE_WriteNum("m_nEntity", EntIndHit);
						TE_WriteNum("m_nHitbox", BoxIndHit);
						TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
						TE_SendToAll();
						
						DendPos[1] += 1.0;
						icolor += 1;
						continue;
					}
					else
					{
						DendPos[1] += 0.5;
						char nfile[24];
						Format(nfile, sizeof(nfile), "paint/paint_%sxx.vmt", Imgdata[icolor]);
						
						TE_Start("Entity Decal");
						TE_WriteVector("m_vecOrigin", DendPos);
						TE_WriteVector("m_vecStart", EstartPos);
						TE_WriteNum("m_nEntity", EntIndHit);
						TE_WriteNum("m_nHitbox", BoxIndHit);
						TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
						TE_SendToAll();
						
						DendPos[1] += 1.5;
						icolor += 2;
						i += 1;
						continue;
					}
				}
				else
				{
					char nfile[24];
					Format(nfile, sizeof(nfile), "paint/paint_%s.vmt", Imgdata[icolor]);
					
					TE_Start("Entity Decal");
					TE_WriteVector("m_vecOrigin", DendPos);
					TE_WriteVector("m_vecStart", EstartPos);
					TE_WriteNum("m_nEntity", EntIndHit);
					TE_WriteNum("m_nHitbox", BoxIndHit);
					TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
					TE_SendToAll();
					
					DendPos[1] += 1.0;
					icolor += 1;
					continue;
				}
			}
			else
			{
				if(StrContains(Imgdata[icolor], "!") != -1)
				{
					DendPos[1] += 1.0;
					icolor += 1;
					continue;
				}
				else
				{
					if(icolor+113 < 8475 && StrContains(Imgdata[icolor+113], Imgdata[icolor]) != -1)
					{
						if(i+1 < istamp && StrContains(Imgdata[icolor+1], Imgdata[icolor]) != -1 && StrContains(Imgdata[icolor+114], Imgdata[icolor]) != -1)
						{
							DendPos[1] += 0.5;
							DendPos[2] -= 0.5;
							char nfile[24];
							Format(nfile, sizeof(nfile), "paint/paint_%sx4.vmt", Imgdata[icolor]);
							
							TE_Start("Entity Decal");
							TE_WriteVector("m_vecOrigin", DendPos);
							TE_WriteVector("m_vecStart", EstartPos);
							TE_WriteNum("m_nEntity", EntIndHit);
							TE_WriteNum("m_nHitbox", BoxIndHit);
							TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
							TE_SendToAll();
							
							DendPos[1] += 1.5;
							DendPos[2] += 0.5;
							if(StrContains(Imgdata[icolor], "5") != -1)
							{
								Imgdata[icolor] = "!5";
								Imgdata[icolor+1] = "!5";
								Imgdata[icolor+113] = "!5";
								Imgdata[icolor+114] = "!5";
							}
							else if(StrContains(Imgdata[icolor], "6") != -1)
							{
								Imgdata[icolor] = "!6";
								Imgdata[icolor+1] = "!6";
								Imgdata[icolor+113] = "!6";
								Imgdata[icolor+114] = "!6";
							}
							icolor += 2;
							i += 1;
							continue;
						}
						else
						{
							DendPos[2] -= 0.5;
							char nfile[24];
							Format(nfile, sizeof(nfile), "paint/paint_%sx2.vmt", Imgdata[icolor]);
							
							TE_Start("Entity Decal");
							TE_WriteVector("m_vecOrigin", DendPos);
							TE_WriteVector("m_vecStart", EstartPos);
							TE_WriteNum("m_nEntity", EntIndHit);
							TE_WriteNum("m_nHitbox", BoxIndHit);
							TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
							TE_SendToAll();
							
							DendPos[2] += 0.5;
							DendPos[1] += 1.0;
							if(StrContains(Imgdata[icolor], "5") != -1)
							{
								Imgdata[icolor] = "!5";
								Imgdata[icolor+113] = "!5";
							}
							else if(StrContains(Imgdata[icolor], "6") != -1)
							{
								Imgdata[icolor] = "!6";
								Imgdata[icolor+113] = "!6";
							}
							icolor += 1;
							continue;
						}
					}
					else if(i+1 < istamp && StrContains(Imgdata[icolor+1], Imgdata[icolor]) != -1)
					{
						if(icolor+114 < 8475 && StrContains(Imgdata[icolor+114], Imgdata[icolor]) != -1)
						{
							char nfile[24];
							Format(nfile, sizeof(nfile), "paint/paint_%s.vmt", Imgdata[icolor]);
							
							TE_Start("Entity Decal");
							TE_WriteVector("m_vecOrigin", DendPos);
							TE_WriteVector("m_vecStart", EstartPos);
							TE_WriteNum("m_nEntity", EntIndHit);
							TE_WriteNum("m_nHitbox", BoxIndHit);
							TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
							TE_SendToAll();
							
							DendPos[1] += 1.0;
							icolor += 1;
							continue;
						}
						else
						{
							DendPos[1] += 0.5;
							char nfile[24];
							Format(nfile, sizeof(nfile), "paint/paint_%sxx.vmt", Imgdata[icolor]);
							
							TE_Start("Entity Decal");
							TE_WriteVector("m_vecOrigin", DendPos);
							TE_WriteVector("m_vecStart", EstartPos);
							TE_WriteNum("m_nEntity", EntIndHit);
							TE_WriteNum("m_nHitbox", BoxIndHit);
							TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
							TE_SendToAll();
							
							DendPos[1] += 1.5;
							icolor += 2;
							i += 1;
							continue;
						}
					}
					else
					{
						char nfile[24];
						Format(nfile, sizeof(nfile), "paint/paint_%s.vmt", Imgdata[icolor]);
						
						TE_Start("Entity Decal");
						TE_WriteVector("m_vecOrigin", DendPos);
						TE_WriteVector("m_vecStart", EstartPos);
						TE_WriteNum("m_nEntity", EntIndHit);
						TE_WriteNum("m_nHitbox", BoxIndHit);
						TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
						TE_SendToAll();
						
						DendPos[1] += 1.0;
						icolor += 1;
						continue;
					}
				}
			}
		}
		else
		{
			char nfile[24];
			Format(nfile, sizeof(nfile), "paint/paint_%s.vmt", Imgdata[icolor]);
			
			TE_Start("Entity Decal");
			TE_WriteVector("m_vecOrigin", DendPos);
			TE_WriteVector("m_vecStart", EstartPos);
			TE_WriteNum("m_nEntity", EntIndHit);
			TE_WriteNum("m_nHitbox", BoxIndHit);
			TE_WriteNum("m_nIndex", PrecacheDecal(nfile, true));
			TE_SendToAll();
			
			DendPos[1] += 1.0;
			icolor += 1;
		}
		continue;
	}
	
	if(linei < 8)
	{
		linei += 1;
	}
	else
	{
		DendPos[1] -= 113.0;
		DendPos[2] -= 1.0;
		linei = 0;
	}
	
	DrawC -= 1;
	//PrintToChatAll("%d", DrawC);
	RequestFrame(Reqdraw, _);
	return;
}

public OnSocketDisconnected(Handle socket, Handle hFile)
{
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	PrintToServer(" ==Disconnected==\n");
	eSocket = INVALID_HANDLE;
	delete socket;
	DrawC = 0;
	Handle Rsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(Rsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Sip, Sport);
}

public OnSocketError(Handle socket, int errorType, int errorNum, int ary)
{
	// a socket error occured
	PrintToServer("socket error %d (errno %d)", errorType, errorNum);
	eSocket = INVALID_HANDLE;
	delete socket;
	DrawC = 0;
	Handle Rsocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(Rsocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, Sip, Sport);
}

public Action Bcast_say(int client, int args)
{
	if(client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	char text[132];
	if (!GetCmdArgString(text, sizeof(text)))
		return Plugin_Continue;
	
	if(eSocket != INVALID_HANDLE && SocketIsConnected(eSocket))
	{
		char sname[32], btext[96];
		GetClientName(client, sname, sizeof(sname));
		StripQuotes(text);
		Format(btext, sizeof(btext), "%s", text);
		char ctext[4];
		Format(ctext, sizeof(ctext), "%s", btext);
		if(StrContains(ctext, "!dp") != -1)
		{
			if(DrawC > 0)
			{
				PrintToChat(client, "Still in progress...");
				return Plugin_Continue;
			}
			else
			{
				if(GetEntityMoveType(client) != MOVETYPE_NOCLIP)
				{
					char Dexplode[2][125];
					ExplodeString(text, "!dp", Dexplode, sizeof(Dexplode), sizeof(Dexplode[]));
					DrawC = 675;
					char ccomm[136];
					Format(ccomm, sizeof(ccomm), "#!DP-%i%s", client, Dexplode[1]);
					SocketSend(eSocket, ccomm);
				}
			}
		}
		else
		{
			Format(text, sizeof(text), "%s : %s", sname, btext);
			SocketSend(eSocket, text);
		}
	}
	return Plugin_Continue;
}