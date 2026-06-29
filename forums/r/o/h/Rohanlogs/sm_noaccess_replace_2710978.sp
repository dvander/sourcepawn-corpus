#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required because its nice

//This message will be displayed
#define NO_ACCESS " {gold}[{yellow}SM{gold}] {grey}You do not have access to this command."

//Here are some colors
char sColors[][] = 
{ 
	"{default}", "{darkred}", "{violet}",
	"{darkgreen}", "{olive}", "{lightgreen}", 
	"{lightred}", "{yellow}", "{lightblue}", 
	"{darkblue}", "{grey}", "{purple}", "{gold}"  
};

//Ignore
char sColorCodes[][] = 
{
	"\x01", "\x02", "\x03", "\x04", 
	"\x05", "\x06", "\x07", "\x09", 
	"\x0B", "\x0C", "\x0D", "\x0E", "\x10"
};


public Plugin myinfo =
{
	name = "txt replace",
	author = "alliedmodders",
	version = "0.0.1"
};


public void OnPluginStart()
{
	HookUserMessage( GetUserMessageId("TextMsg"), fw_TextMsg, true );
}


public Action fw_TextMsg( UserMsg msg_id, Handle hBf, const iClients[], int iNum, bool bReliable, bool bInitialize )
{
	if(bReliable)
	{
		char sBuffer[256];
		PbReadString( hBf, "params", sBuffer, sizeof(sBuffer), 0 );
		
		if(StrContains(sBuffer, "[SM] You do not have access") == 0) 
		{
			Handle hData;
			CreateDataTimer(0.0, fw_Timer, hData);
			WritePackCell(hData, iNum);
			for(int i = 0; i < iNum; i++) WritePackCell( hData, iClients[i] );
			ResetPack(hData);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action fw_Timer(Handle hTimer, Handle hData)
{
	int iClient, iCount;
	int iClients[MAXPLAYERS];
	int iNum = ReadPackCell(hData);

	for(int i = 0; i < iNum; i++)
	{
		iClient = ReadPackCell(hData);
		if( IsClientInGame(iClient) ) iClients[iCount++] = iClient;
	}

	if(iCount < 1) return;
	
	char sMsg[264];
	FormatEx( sMsg, sizeof(sMsg), ""...NO_ACCESS..."" );
	
	for(int i = 0; i < sizeof(sColorCodes); i++) 
		ReplaceString( sMsg, sizeof(sMsg), sColors[i], sColorCodes[i] );
	
	Handle bf = StartMessage("SayText2", iClients, iNum, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	PbSetInt(bf, "ent_idx", -1);
	PbSetBool(bf, "chat", true);
	PbSetString(bf, "msg_name", sMsg);
	PbAddString(bf, "params", "");
	PbAddString(bf, "params", "");
	PbAddString(bf, "params", "");
	PbAddString(bf, "params", "");
	EndMessage();
}

